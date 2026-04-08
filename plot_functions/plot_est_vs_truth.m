function plot_est_vs_truth(model, settings, truth, fused_agents, varargin)
    % Plot estimates versus ground truth using OSPA2 to match colors of estimates to colors of ground truth

    % --- Input Parser ---
    p = inputParser;
    addParameter(p, 'K', truth.K, @isnumeric);
    addParameter(p, 'Transparency', 1, @isnumeric);
    addParameter(p, 'sel_agent', 1, @isnumeric);
    addParameter(p, 'colorarray', []);
    parse(p, varargin{:});
    
    % --- Retrieve Parameters ---
    Transparency = p.Results.Transparency;
    sel_agent = p.Results.sel_agent;
    colorarray = p.Results.colorarray;
    if isempty(colorarray)
       colorarray = makecolorarray(10000); 
    end
    show_time_labels = settings.plot_flags.show_time_labels; % Extract flag for time step labels

    LineWidth = 1;
    text_offset = 50;
    font_name = model.font_name;
    font_size = 14;
    source_info = settings.source_info;
    K = p.Results.K;
    est = fused_agents{sel_agent}.est;
    fused_strategy = fused_agents{sel_agent}.fused_strategy;
    
    % --- Plot Truth ---
    color_list = color_vector(10000)';
    [X_track, k_birth, k_death] = extract_tracks(truth.X, truth.track_list, truth.total_tracks);
    ntarget = truth.total_tracks;
    for i = 1:ntarget
        assigncolor(truth.L{k_birth(i)}(i));
    end
    
    figure();
    set(gcf, 'Position', [1100, 630, 648, 263]); % Set figure position
    xlim([-331.1, 2509.8]);  % Set X-axis limits
    ylim([0, 848.2465]);  % Set Y-axis limits
    hold on; 
    plot_fov(source_info, model.fov_range, model.rD_max);
    
    % --- Plot Ground Truth Trajectories ---
    htruth = cell(ntarget,1);
    for i = 1:ntarget
        k_b_temp = k_birth(i); 
        k_b_temp = k_b_temp(k_b_temp <= K);  
        k_d_temp = min(k_death(i), K);
        life_temp = k_b_temp:k_d_temp;
        pos_temp = X_track(model.pos_idx, :, i);
        cur_color = 'k';
        Transparency_temp = Transparency;
        
        if ~isempty(k_b_temp)
            htruth{i} = plot(pos_temp(1, life_temp), pos_temp(2, life_temp), ...
                'LineWidth', LineWidth, 'LineStyle', '-', 'Color', cur_color);
            htruth{i}.Color(4) = Transparency_temp;
            
            % Start Marker (Circle)
            scatter(pos_temp(1, k_b_temp), pos_temp(2, k_b_temp), 100, ...
                'LineWidth', 1, 'Marker', 'o', 'MarkerFaceColor', cur_color, 'MarkerEdgeColor', 'black');

            % End Marker (Square)
            scatter(pos_temp(1, k_d_temp), pos_temp(2, k_d_temp), 100, ...
                'LineWidth', 1, 'Marker', 's', 'MarkerFaceColor', cur_color, 'MarkerEdgeColor', 'black');

            % --- Add Time Step Labels if Enabled ---
            if show_time_labels
                for k_idx = 1:length(life_temp)
                    k = life_temp(k_idx);
                    text(pos_temp(1, k), pos_temp(2, k), num2str(k), ...
                        'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k', ...
                        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
                end
            end
        end
    end
    
    % --- Plot Sensor Nodes ---
    for i = 1:length(source_info)
        plot(source_info{i}.source_pos(1), source_info{i}.source_pos(2), 'pr', 'MarkerSize', 10); 
        text(source_info{i}.source_pos(1), source_info{i}.source_pos(2) + 3 * text_offset, ...
            ['Node ', num2str(i)], 'FontName', model.font_name, 'FontSize', model.font_size); 
    end
    
    % --- Plot Estimates ---
    [Y_track, l_list, ke_birth, ke_death] = extract_tracks_with_labels(est, 1, K);
    n_est = size(l_list, 2);

    % Compute OSPA2 matching for color consistency
    [~, allcostm] = compute_ospa2(X_track([1 3], :, :), Y_track([1 3], :, :), model.ospa.c, model.ospa.p, K);
    if size(allcostm, 2) ~= n_est
        allcostm = allcostm';
    end
    Matching = Hungarian(allcostm);
    cost_check = allcostm < model.ospa.c;
    Matching = Matching .* cost_check;
    
    l1_idx = (1:ntarget)';
    l2_idx = (1:n_est)';
    L1_idx = Matching * l2_idx;
    Q = [l1_idx, L1_idx];
    Q_check = prod(Q > 0, 2) > 0;
    Q = Q(Q_check, :);  % Matched track list

    hest = cell(n_est, 1);
    for i = 1:n_est
        pos_temp = Y_track(model.pos_idx, :, i);
        k_b_temp = ke_birth(i); 
        k_b_temp = k_b_temp(k_b_temp <= K);
        k_d_temp = min(ke_death(i), K);
        life_temp = k_b_temp:k_d_temp;
        
        if ismember(i, Q(:, 2))
            truth_idx = Q(i == Q(:, 2), 1);
            cur_color = colorarray.rgb(assigncolor(truth.L{k_birth(truth_idx)}(truth_idx)), :)';
        else
            cur_color = color_list(:, i + n_est);
        end
        
        Transparency_temp = (K > k_d_temp) * Transparency + (K <= k_d_temp) * 1;
        
        if ~isempty(k_b_temp)
            hest{i} = plot(pos_temp(1, life_temp), pos_temp(2, life_temp), '.', ...
                'Color', cur_color, 'LineWidth', 2, 'MarkerSize', 15);
            hest{i}.Color(4) = Transparency_temp;

            % --- Add Time Step Labels if Enabled ---
            if show_time_labels
                for k_idx = 1:length(life_temp)
                    k = life_temp(k_idx);
                    text(pos_temp(1, k), pos_temp(2, k), num2str(k), ...
                        'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k', ...
                        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
                end
            end
        end
    end
    
    % --- Format Plot ---
    title(['Estimated vs Truth using ', fused_strategy, ' at Node ', num2str(sel_agent)]);
    xlabel('x-coordinate (m)', 'FontSize', font_size);
    ylabel('y-coordinate (m)', 'FontSize', font_size);
    set(gcf, 'color', 'w');
    set(gca, 'FontSize', font_size, 'FontName', font_name);
    grid on;

    function idx = assigncolor(label)
        str = sprintf('%i*', label);
        tmp = strcmp(str, colorarray.lab);
        if any(tmp)
            idx = find(tmp);
        else
            colorarray.cnt = colorarray.cnt + 1;
            colorarray.lab{colorarray.cnt} = str;
            idx = colorarray.cnt;
        end
    end
end
