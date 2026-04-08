function plot_fov(source_info, fov_range, rD_max)
    % Plot the field of view (FoV) of each sensor based on its FoV range and detection range

    n_s = length(source_info);
    
    % Ensure rD_max is a vector (one value per sensor)
    if numel(rD_max) == 1
        rD_max = repmat(rD_max, n_s, 1); % Convert scalar to vector if necessary
    end

    if size(fov_range,1) == 1  % Single FoV range applied to all sensors
        a1 = deg2rad(fov_range(1));
        a2 = deg2rad(fov_range(2));
        t = linspace(a1, a2);
        for s = 1 : n_s
            x0 = source_info{s}.source_pos(1);
            y0 = source_info{s}.source_pos(2);
            x = x0 + rD_max(s) * cos(t);  % Use sensor-specific rD_max
            y = y0 + rD_max(s) * sin(t);
            if source_info{s}.malicious_flag
                plot([x0, x, x0], [y0, y, y0], 'r:', 'LineWidth', 1.5); hold on;
            else
                plot([x0, x, x0], [y0, y, y0], 'k:', 'LineWidth', 1.5); hold on;
            end
        end
    else  % Each sensor has a different FoV range
        for s = 1 : n_s
            a1 = deg2rad(fov_range(s,1));
            a2 = deg2rad(fov_range(s,2));
            t = linspace(a1, a2);
            x0 = source_info{s}.source_pos(1);
            y0 = source_info{s}.source_pos(2);
            x = x0 + rD_max(s) * cos(t);  % Use sensor-specific rD_max
            y = y0 + rD_max(s) * sin(t);
            if source_info{s}.malicious_flag
                plot([x0, x, x0], [y0, y, y0], 'r:', 'LineWidth', 1.5); hold on;
            else
                plot([x0, x, x0], [y0, y, y0], 'k:', 'LineWidth', 1.5); hold on;
            end
        end
    end

%axis equal;
end
