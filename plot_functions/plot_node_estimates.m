function plot_node_estimates(model, settings, truth, agents, varargin)
    % Plot individual estimates for ALL nodes vs. ground truth

    % --- Input Parser ---
    p = inputParser;
    addParameter(p, 'K', truth.K, @isnumeric);
    addParameter(p, 'Transparency', 1, @isnumeric);
    addParameter(p, 'show_truth', true, @islogical); % Flag to show ground truth
    parse(p, varargin{:});
    
    % --- Retrieve Parameters ---
    K = p.Results.K;
    Transparency = p.Results.Transparency;
    show_truth = p.Results.show_truth;
    show_time_labels = settings.plot_flags.show_time_labels; % Extract flag for time step labels
        font_name = model.font_name;
            LineWidth = 2;
    font_size = 14; 

    n_sensors = length(agents); % Total number of nodes

    % --- Define Colors for Different Nodes ---
    color_list = lines(n_sensors); % Get distinct colors for each node

    % --- Set up figure ---
    figure();
    set(gcf, 'Position', [1100, 630, 648, 263]); % Consistent figure size
    xlim([-331.1, 2509.8]);
    ylim([0, 848.2465]);
    hold on;
    
    % --- Plot FoV and Sensor Nodes ---
    plot_fov(settings.source_info, model.fov_range, model.rD_max);

    % --- Sensor Node Positions (Honest vs. Malicious) ---
    for i = 1:n_sensors
        node_pos = settings.source_info{i}.source_pos;
        
        % Check if the node is malicious
        if settings.source_info{i}.malicious_flag == 1
            % Red circle for malicious nodes
            plot(node_pos(1), node_pos(2), 'or', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
            node_status = '(Byzantine)';
        else
            % Black circle for normal (honest) nodes
            plot(node_pos(1), node_pos(2), 'ok', 'MarkerSize', 10);
            node_status = '(Honest)';
        end

        % % Display text label above the node
        % text_label = sprintf('Node %d\n%s', i, node_status);
        % text(node_pos(1), node_pos(2) + 50, text_label, 'FontName', model.font_name, ...
        %     'FontSize', model.font_size + 2, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end

    % --- Plot Ground Truth (if enabled) ---
    if show_truth
        [X_track, k_birth, k_death] = extract_tracks(truth.X, truth.track_list, truth.total_tracks);
        ntarget = truth.total_tracks;
        
        for i = 1:ntarget
            k_b_temp = k_birth(i);
            k_d_temp = min(k_death(i), K);
            life_temp = k_b_temp:k_d_temp;
            pos_temp = X_track([1 3], :, i);
            
            plot(pos_temp(1, life_temp), pos_temp(2, life_temp), 'k-', 'LineWidth', 1.5, 'Color', [0.5 0.5 0.5 0.6]);
        end
    end
    
    % --- Extract and Plot Estimates for ALL Nodes ---
    legends = {}; % Store labels for legend
    h_legend = []; % Store plot handles for legend
    for s = 1:n_sensors
        est = agents{s}.est_no_fused;  % Node-specific estimates
        [Y_track, l_list, ke_birth, ke_death] = extract_tracks_with_labels(est, 1, K);
        n_est = size(l_list, 2);
        
        node_color = color_list(s, :); % Assign color based on node ID
        
        for i = 1:n_est
            k_b_temp = ke_birth(i);
            k_d_temp = min(ke_death(i), K);
            life_temp = k_b_temp:k_d_temp;
            pos_temp = Y_track([1 3], :, i);
            
            if s ==2
                h_plot = scatter(pos_temp(1, life_temp), pos_temp(2, life_temp), 20, 'o', ...
                    'MarkerEdgeColor', node_color, 'MarkerFaceAlpha', Transparency, 'LineWidth', 1.7);
            elseif s==3
                h_plot = scatter(pos_temp(1, life_temp), pos_temp(2, life_temp), 20, 'x', ...
                    'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', Transparency, 'LineWidth', 1.7);
            else
                h_plot = scatter(pos_temp(1, life_temp), pos_temp(2, life_temp), 20, 'd', ...
                    'MarkerEdgeColor', node_color, 'MarkerFaceAlpha', Transparency, 'LineWidth', 1.7);
            end
            
            % --- Only add one entry per node for the legend ---
            if i == 1
                h_legend = [h_legend, h_plot]; % Store handle
                legends{end+1} = sprintf('Node %d', s);
            end
            
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

    % --- Labels and Formatting ---
    % title('Estimates from All Nodes');
    xlabel('x-coordinate (m)');
    ylabel('y-coordinate (m)');
    set(gca, 'FontSize', font_size, 'FontName', font_name);
    grid on;
    
    % --- Add legend with only estimates (FoV excluded) ---
    legend(h_legend, legends, 'Location', 'northwest');
    
    hold off;
end
