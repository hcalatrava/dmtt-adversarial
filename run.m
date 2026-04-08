clearvars;
close all;
restoredefaultpath; matlabrc;
add_paths;

%% --- Monte Carlo settings
N_mc   = 1;   % number of trials
seeds  = 1:N_mc;
% Set plot_seed to the seed of the trial you want to visualize.
% Set to [] to skip all plots and just run/save MC results.
plot_seed = 1;  % e.g. rng(2) gives the representative trial shown in the paper

%% --- fixed simulation settings
attack_type  = "stealthy"; % "stealthy" | "hardswitch" 
lambda_c = 1;
settings = gen_settings('case_id', attack_type, 'sel_pd', 0.98);
model    = gen_model(settings, 'meas_sigma', 2, 'sigma_v', 5, 'lambda_c', lambda_c, ...
                     'track_threshold', 0.001, 'metric_type', 'ospa_union');
%Detections are forced within each sensor's FoV to focus the evaluation on the attack's impact on label consistency, independent of missed detection effects.
model.force_detections = 1; % force detections within FoV (no missed detections)
model.filter.run_flag  = 'silence';  % suppress console output

%% --- MPC settings
dt = 1;
mpc_settings.horizon_steps  = 20;
mpc_settings.gamma          = 0.99;
mpc_settings.dim_x          = model.x_dim;
mpc_settings.dim_u          = 2;  % 2D acceleration input (x, y)
% Note: A and B are redefined here in [x;y;vx;vy] format for the MPC,
% whereas the tracker uses [x;vx;y;vy]. Reordering handled via r below.
mpc_settings.A = [1 0 dt 0;
                  0 1 0  dt;
                  0 0 1  0;
                  0 0 0  1];
mpc_settings.B = [0.5*dt^2 0;
                  0        0.5*dt^2;
                  dt       0;
                  0        dt];
mpc_settings.ACC_MAX       = 30;
mpc_settings.VEL_MAX       = 30;
mpc_settings.VEL_WEIGHT    = 0.1; % velocity matching weight (alpha_v)
mpc_settings.PEN_WEIGHT    = 0.1; % separation penalty weight (alpha_c)
% mpc_settings.POS_WEIGHT = 1;  % alpha_p, implicit (not passed to solve_MPC)
mpc_settings.SAFE_DISTANCE = model.ospa.c;

%% --- Attack timeline
% Scenario-specific values for the event-driven conditions in Sec. III.
% In practice these could be determined adaptively: k_p1 when the matching
% condition tilde_d(t_v, t_*) < c is confirmed; k_p2 as the earliest time
% the impostor enters a non-compromised region (attacker prescribes the
% drone to arrive at the rendezvous point at this time, see Remark 3);
% k_snap when non-compromised nodes report the impostor under the victim
% label, confirming successful injection.
k_0    = 18; % time at which the attacker starts transmitting t_*
k_p1   = 46; % time at which the MPC switches from mimicry (ref = t_v) to
%          pull-off (ref = rendezvous point)
k_p2   = 60; % the MPC aims for the impostor's position at
%          this time step during pull-off, and switches to following the
%          current impostor state from k_p2 onwards (injection stage)
k_snap = 68; % time at which the attacker stops solving the MPC and directly
%            copies the impostor state
k_3    = model.K; % end of simulation

%% --- preallocate results
K         = model.K;
ospa2_all = nan(N_mc, K);   % OSPA2 at Node 3 per trial
card_all  = nan(N_mc, K);   % cardinality at Node 3 per trial
r = [1 3 2 4]; % reordering index to convert between the tracker's state format [x; vx; y; vy] and the MPC's expected format [x; y; vx; vy]

%% --- Monte Carlo loop
for mc = 1:N_mc
    fprintf('MC trial %d/%d\n', mc, N_mc);
    rng(seeds(mc));

    % generate truth
    truth = gen_truth(model, settings);

    % MPC loop: generate spoofed trajectory (stealthy only)
    if strcmp(attack_type, 'stealthy')

        % rendezvous point: attacker prescribes impostor position at k_p2
        rendezvous_state = truth.X{k_p2}(:, 2);
    
        % initialise spoofed state near victim with small offset to avoid zero-norm gradient
        spoof_state = truth.X{k_0}(:, 1) + [5; 0; 5; 0];
    
        % clear hardcoded attack trajectory from gen_truth
        for k = 1:K
            truth.attack.X{k} = [];
            truth.attack.N(k)  = 0;
        end
    
        % MPC loop: generate spoofed trajectory
        U0 = zeros(mpc_settings.dim_u, mpc_settings.horizon_steps);
        for k = k_0:k_3
    
            victim_state = truth.X{k}(:, 1);
    
            % snap stage: directly copy impostor state
            if k >= k_snap
                if size(truth.X{k}, 2) >= 2
                    spoof_state = truth.X{k}(:, 2);
                end
                truth.attack.X{k}          = spoof_state;
                truth.attack.N(k)          = 1;
                truth.attack.track_list{k} = size(settings.xstart, 2) + 1;
                continue;
            end
    
            % select MPC reference based on attack phase
            if k < k_p1
                ref_state = victim_state;                  % mimicry
            elseif k < k_p2
                ref_state = rendezvous_state;              % pull-off
            else
                if size(truth.X{k}, 2) >= 2
                    ref_state = truth.X{k}(:, 2);         % injection: follow impostor
                else
                    ref_state = rendezvous_state;          % impostor not yet born
                end
            end
    
            % solve MPC and apply first control input
            [U_opt, ~]      = solve_MPC(spoof_state(r), ref_state(r), victim_state(r), mpc_settings, U0);
            u               = U_opt(:, 1);
            spoof_reordered = mpc_settings.A * spoof_state(r) + mpc_settings.B * u;
            spoof_state     = spoof_reordered(r);
            U0              = [U_opt(:, 2:end), zeros(mpc_settings.dim_u, 1)];
    
            % store spoofed state
            truth.attack.X{k}          = spoof_state;
            truth.attack.N(k)          = 1;
            truth.attack.track_list{k} = size(settings.xstart, 2) + 1;
        end
        % finalise attack track metadata (used by plotting functions)
        truth.attack.total_tracks = 1;  % one spoofed track
        truth.attack.L            = truth.attack.track_list;
    end % end stealthy MPC block

    % generate measurements and run filter
    meas         = gen_all_meas(settings, model, truth);
    fused_agents = run_fused_filter(settings, model, truth, meas);

    % store results at Node 3
    ospa2_all(mc, :) = fused_agents{3}.ospa2(2, :);  % row 2 = OSPA(2) evaluation metric
    card_all(mc, :)  = fused_agents{3}.est_fused.N';

    % plots for selected trial
    if ~isempty(plot_seed) && seeds(mc) == plot_seed
        model.filter.run_flag = 'disp';
        if strcmp(attack_type, 'stealthy')
            plot_attack_results(settings, model, truth, fused_agents, k_0, k_3, k_p1, k_p2, rendezvous_state);
        else
            plot_attack_results(settings, model, truth, fused_agents, k_0, k_3, k_p1, k_p2, []);
        end
        % plot_measurements(settings, model, meas, truth);
        model.filter.run_flag = 'silence';
    end

end


%% --- Save results
fname = sprintf('mc_results_%s.mat', attack_type);  % filename adapts to attack_type
ospa2_out = ospa2_all;
card_out  = card_all;
save(fname, 'ospa2_out', 'card_out', 'N_mc', 'K', 'attack_type');
fprintf('Saved to %s\n', fname);
fprintf('Mean OSPA(2) full window: %.2f m\n', mean(ospa2_out(:), 'omitnan'));