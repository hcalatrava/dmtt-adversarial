function handler = plot_measurements(settings, model, meas, truth)
    % Plots measurements from all sensors at all time steps, including sensors & FoV

    handler = figure();
    hold on;
    
    % Define measurement colors
    detection_color = [0 0.4470 0.7410]; % Blue for real detections
    clutter_color = [0.8 0.8 0.8]; % Light gray for clutter
    sensor_color = 'k'; % Black for sensor locations

    % Set figure properties
    set(gcf, 'Position', [1100, 630, 648, 263]); % Adjust window size
    xlim([-331.1, 2509.8]); % Adjust based on truth plots
    ylim([0, 848.2465]);
    grid on;
    xlabel('x-coordinate (m)');
    ylabel('y-coordinate (m)');
    title('Sensor Measurements');

    % --- Plot Field of View (FoV) as in `plot_truth` ---
    plot_fov(settings.source_info, model.fov_range, model.rD_max);

    % Iterate over sensors
    n_s = length(settings.source_info);
    for s = 1:n_s
        sensor_info = settings.source_info{s};
        sensor_pos = sensor_info.source_pos;

        % --- Plot Sensor Location ---
        scatter(sensor_pos(1), sensor_pos(2), 120, sensor_color, 'filled', 'd'); % Diamond marker for sensors

        % Iterate over time steps
        for k = 1:length(meas{s}.Z)
            if isempty(meas{s}.Z{k}), continue; end % Skip empty measurements
            
            % Extract measurement positions
            meas_positions = meas{s}.Z{k}; % Measurement points
            
            % Identify the number of real detections and total measurements
            N_real = size(truth.X{k}, 2); % Number of real detections
            N_total = size(meas_positions, 2); % Total detections (real + clutter)
            
            % Ensure N_real does not exceed available measurements
            N_real = min(N_real, N_total); 
            
            % Extract real detections
            if N_real > 0
                scatter(meas_positions(1, 1:N_real), meas_positions(2, 1:N_real), 50, ...
                        'MarkerEdgeColor', 'k', 'MarkerFaceColor', detection_color);
            end
            
            % Extract and plot clutter
            if N_total > N_real
                clutter_points = meas_positions(:, N_real+1:end);
                scatter(clutter_points(1,:), clutter_points(2,:), 40, ...
                        'MarkerEdgeColor', 'none', 'MarkerFaceColor', clutter_color);
            end
        end
    end

    hold off;
end
