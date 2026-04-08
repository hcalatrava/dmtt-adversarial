function [handler,colorarray] = plot_truth(source_info, model, truth, plot_flags)
    % Plot object ground truth with fov shapes of all sensors
    
    % --- Define Fixed Colors for Targets & Attacks ---
    predefined_colors = [ 
        0, 0.4470, 0.7410;   % Blue (Target 1)
        %1, 0.5, 0; % Orange (Target 2)
        0.4660, 0.6740, 0.1880;   % Green (Target 3 or extra)
        1, 0, 0;   % Red (Attack 1)
        0.5, 0, 0.5; % Purple (Attack 2)
    ];


    % --- Make code look nicer
    text_offset = model.text_offset;
    K = truth.K;
    LineWidth = 2;
    font_size = 14; 
    Transparency = 1;
    font_name = model.font_name;
    
    [X_track,k_birth,k_death]= extract_tracks(truth.X,truth.track_list,truth.total_tracks);
    if  exist('colorarray','var') == 0 || exist('colorarray','var') == 1 &&  isempty(colorarray)
        try
            colorarray = load('colorarray.mat'); colorarray = colorarray.colorarray;
        catch
            labelcount= countestlabels(truth)+1;
            colorarray= makecolorarray(labelcount);
        end
    end
    ntarget = truth.total_tracks;
    
    handler = figure();

    % TODO: adjust for figure appearance
    % --- Set figure position (ensures same window size & location)
    set(gcf, 'Position', [ 1100,         630 ,        648,         263]); % 3 sensors
    % set(gcf, 'Position', [ -665,    98,   514,   218]); % 3 sensors
    % --- Set axis limits (ensures consistent zoom level)
    xlim([-331.1, 2509.8]);  % Corrected X-axis limits
    ylim([0, 848.2465]);  % Corrected Y-axis limits
    %axis square;

    hold on; 
    plot_fov(source_info,model.fov_range,model.rD_max);
    for i=1:ntarget
        k_b_temp = k_birth(i); k_b_temp = k_b_temp(k_b_temp<=K);  % update birth time
        k_d_temp = k_death(i); k_d_temp = min(k_d_temp,K);   % update death time
        life_temp = k_b_temp : k_d_temp;
        pos_temp = X_track([1 3],:,i);
        if K > k_d_temp, Transparency_temp = Transparency; else, Transparency_temp = 1; end
        if ~isempty(k_b_temp)
            try
            color_temp = colorarray.rgb(assigncolor(truth.L{k_birth(i)}(i))+1,:) ;
            catch err
                disp(err.message);
            end
            htruth{i} = plot(pos_temp(1,life_temp),pos_temp(2,life_temp),'LineWidth',LineWidth, 'LineStyle','-','Color' , predefined_colors(i,:));
            htruth{i}.Color(4) = Transparency_temp;
        end
    end
for i = 1:ntarget
    k_b_temp = k_birth(i); 
    k_b_temp = k_b_temp(k_b_temp <= K);  % Update birth time
    k_d_temp = k_death(i); 
    k_d_temp = min(k_d_temp, K);   % Update death time
    life_temp = k_b_temp : k_d_temp;
    pos_temp = X_track([1 3], :, i); % Extract (x, y) positions
    
    if K > k_d_temp
        Transparency_temp = Transparency; 
    else
        Transparency_temp = 1; 
    end
    
    if ~isempty(k_b_temp)
        try
            color_temp = colorarray.rgb(assigncolor(truth.L{k_birth(i)}(i)), :) ;
        catch err
            disp(err.message);
        end

        % --- Plot Main Trajectory Line ---
        htruth{i} = plot(pos_temp(1, life_temp), pos_temp(2, life_temp), ...
                        'LineWidth', LineWidth, 'LineStyle', '-', 'Color', predefined_colors(i,:));
        htruth{i}.Color(4) = Transparency_temp;

        % --- Add Step Number Labels Every 10 Steps ---
        if plot_flags.show_time_labels
            for k = k_b_temp:1:k_d_temp  % Iterate in steps of 10
                text(pos_temp(1, k), pos_temp(2, k), num2str(k), ...
                     'FontSize', 10, 'FontName', font_name, ...
                     'FontWeight', 'bold', 'Color', 'k', ...
                     'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
            end
        end

        % --- Add Start and End Markers ---
        % Start Marker (Circle)
        scatter(pos_temp(1, k_b_temp), pos_temp(2, k_b_temp), 100, ...
                'LineWidth', 1, 'Marker', 'o', ...
                'MarkerFaceColor', predefined_colors(i,:), 'MarkerEdgeColor', 'black');

        % End Marker (Square)
        scatter(pos_temp(1, k_d_temp), pos_temp(2, k_d_temp), 100, ...
                'LineWidth', 1, 'Marker', 's', ...
                'MarkerFaceColor', predefined_colors(i,:), 'MarkerEdgeColor', 'black');
    end
end


    % --- Plot Attack Trajectories (truth.attack) ---
    if plot_flags.show_fake_trajectory && isfield(truth, 'attack') && isfield(truth.attack, 'X')
        [X_attack, k_birth_attack, k_death_attack] = extract_tracks(truth.attack.X, truth.attack.track_list, truth.attack.total_tracks);
        
        natk = truth.attack.total_tracks; % Number of attack targets
        for i = 1:natk
            idx = i+ntarget;
            k_b_temp = k_birth_attack(idx);
            k_b_temp = k_b_temp(k_b_temp <= K);  
            k_d_temp = k_death_attack(idx);
            k_d_temp = min(k_d_temp, K);   
            life_temp = k_b_temp : k_d_temp;
            pos_temp = X_attack([1 3], :, idx); 

            if K > k_d_temp, Transparency_temp = Transparency; else, Transparency_temp = 1; end

                if ~isempty(k_b_temp)
                    % --- Identify Gaps and Break the Plot Line Accordingly ---
                    max_allowed_gap = 50;  % Set a threshold for large jumps (adjust as needed)
                    x_values = pos_temp(1, life_temp);
                    y_values = pos_temp(2, life_temp);
                
                    % Find large gaps between consecutive points
                    gap_indices = find(abs(diff(x_values)) > max_allowed_gap | abs(diff(y_values)) > max_allowed_gap);
                
                    % Insert NaN values at gap points to break the line
                    x_values_fixed = x_values;
                    y_values_fixed = y_values;
                    
                    gap_positions_x = [];
                    gap_positions_y = [];
                
                    for gap = flip(gap_indices)  % Loop in reverse to avoid shifting indices
                        % Store the beginning and end of the gap
                        gap_positions_x = [gap_positions_x, x_values(gap), x_values(gap + 1)];
                        gap_positions_y = [gap_positions_y, y_values(gap), y_values(gap + 1)];
                        
                        % Insert NaN to break the line
                        x_values_fixed = [x_values_fixed(1:gap), NaN, x_values_fixed(gap+1:end)];
                        y_values_fixed = [y_values_fixed(1:gap), NaN, y_values_fixed(gap+1:end)];
                    end
                
                    % --- Now Plot the Fixed Line (Without Unwanted Connections) ---
                    htruth_attack{idx} = plot(x_values_fixed, y_values_fixed, ...
                                              'LineWidth', LineWidth*1.2, 'LineStyle', '--', 'Color', 'r'); 
                    htruth_attack{idx}.Color(4) = Transparency_temp;
                
                    % --- Add Start and End Markers for Attacks ---
                    scatter(pos_temp(1, k_b_temp), pos_temp(2, k_b_temp), 100, 'LineWidth', 1, ...
                            'Marker', 'o', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'black');
                    scatter(pos_temp(1, k_d_temp), pos_temp(2, k_d_temp), 100, 'LineWidth', 1, ...
                            'Marker', 's', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'black');
                
                    % --- Add Markers at Start and End of Gaps (Without Face Color) ---
                    if ~isempty(gap_positions_x)
                        scatter(gap_positions_x, gap_positions_y, 80, 'LineWidth', 1.5, ...
                                'Marker', 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'red');
                    end
                end

        end
    end

    
    % --- Sensor Node Positions (Honest vs Malicious) ---
    for i = 1:length(source_info)
        % Check if the node is malicious
        if source_info{i}.malicious_flag == 1
            % Filled red circle for malicious nodes
            plot(source_info{i}.source_pos(1), source_info{i}.source_pos(2), 'or', ...
                'MarkerSize', 10, 'MarkerFaceColor', 'r');
            node_status = '(Byzantine)';
        else
            % Black circle for normal nodes
            plot(source_info{i}.source_pos(1), source_info{i}.source_pos(2), 'ok', ...
                'MarkerSize', 10);
            node_status = '(Honest)';
        end
        
        hold on;
        
        % Increase the text offset and font size
        text_label = sprintf('Node %d\n%s', i, node_status); % Multi-line text
        text(source_info{i}.source_pos(1), source_info{i}.source_pos(2) + 5 * text_offset, ... % Increased height
            text_label, 'FontName', model.font_name, 'FontSize', model.font_size + 2, ... % Increased font size
            'FontWeight', 'bold', 'HorizontalAlignment', 'center'); % Bold for better visibility
    end
    
    xlabel('x-coordinate (m)', 'FontSize', font_size);
    ylabel('y-coordinate (m)', 'FontSize', font_size);
    set(gcf,'color','w');
    set(gca, 'FontSize', font_size, 'FontName', font_name);
    grid on;
    axis normal
    return;
    
    function idx= assigncolor(label)
        str= sprintf('%i*',label);
        tmp= strcmp(str,colorarray.lab);
        if any(tmp)
            idx= find(tmp);
        else
            colorarray.cnt= colorarray.cnt + 1;
            colorarray.lab{colorarray.cnt}= str;
            idx= colorarray.cnt;
        end
    end
end


