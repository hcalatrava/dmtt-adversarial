function [U_opt, cost_val] = solve_MPC(cur_agent_state, cur_ref_state, cur_avoider_state, settings, U0)
%SOLVE_MPC Solve MPC for one time step
import casadi.*

%% extract constants
dim_x         = settings.dim_x;
dim_u         = settings.dim_u;
N             = settings.horizon_steps;
gamma         = settings.gamma;
A             = settings.A;
B             = settings.B;
ACC_MAX       = settings.ACC_MAX;
VEL_MAX       = settings.VEL_MAX;
SAFE_DISTANCE = settings.SAFE_DISTANCE;
VEL_WEIGHT    = settings.VEL_WEIGHT;
PEN_WEIGHT    = settings.PEN_WEIGHT;

%% define the solver
opti = casadi.Opti();

% define system variables
X = opti.variable(dim_x, N+1);  % states
U = opti.variable(dim_u, N);    % control inputs

%% compute cost and define constraints in MPC horizons
cost = 0;

% constraint 1: initial condition
opti.subject_to(X(:, 1) == cur_agent_state);

for n = 1:N
    cur_ref_state     = A * cur_ref_state;
    cur_avoider_state = A * cur_avoider_state;

    % constraint 2: system dynamics
    opti.subject_to(X(:, n+1) == A * X(:, n) + B * U(:, n));

    % constraint 3: acceleration limit
    opti.subject_to(norm_2(U(:, n) + 1e-6) <= ACC_MAX);

    % constraint 4: velocity limit
    opti.subject_to(norm_2(X(3:4, n+1)) <= VEL_MAX);

    % cost 1: match position to reference
    cost = cost + gamma^(n-1) * norm_2(X(1:2, n+1) - cur_ref_state(1:2))^2;

    % cost 2: match velocity to reference
    cost = cost + VEL_WEIGHT * gamma^(n-1) * norm_2(X(3:4, n+1) - cur_ref_state(3:4))^2;

    % cost 3: safe distance (soft penalty)
    cost = cost + PEN_WEIGHT * max(SAFE_DISTANCE - norm_2(X(1:2, n+1) - cur_avoider_state(1:2)), 0)^2;
end

opti.minimize(cost);

%% initialize the solver
opti.set_initial(X, repmat(cur_agent_state, 1, N+1));
opti.set_initial(U, U0);
opts                    = struct;
opts.ipopt.print_level  = 0;
opts.print_time         = false;
opts.ipopt.tol          = 1e-4;
opti.solver('ipopt', opts);

%% solve the optimization
try
    sol      = opti.solve();
    U_opt    = opti.value(U);
    cost_val = sol.value(opti.f);
catch ME
    disp(['Solver failed: ', ME.message]);
    U_opt    = zeros(dim_u, N);
    cost_val = nan;
end