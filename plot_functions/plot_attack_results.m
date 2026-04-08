function plot_attack_results(settings, model, truth, fused_agents, k_0, k_3, k_p1, k_p2, rendezvous_state)
% PLOT_ATTACK_RESULTS Plot MPC spoofed trajectory and filter results for one trial.
% Called from run_mc_stealthy.m for the selected plot_seed trial.

    %% --- Sanity plot: spoofed trajectory with timestamps
    figure; set(gcf, 'Position', [1100, 630, 648, 263]); hold on;
    plot_fov(settings.source_info, model.fov_range, model.rD_max);
    for k = k_0:k_3
        if ~isempty(truth.attack.X{k})
            plot(truth.attack.X{k}(1), truth.attack.X{k}(3), 'r.', 'HandleVisibility', 'off');
        end
        if ~isempty(truth.X{k})
            plot(truth.X{k}(1,1), truth.X{k}(3,1), 'g.', 'HandleVisibility', 'off');
            if size(truth.X{k}, 2) >= 2
                plot(truth.X{k}(1,2), truth.X{k}(3,2), 'b.', 'HandleVisibility', 'off');
            end
        end
    end
    plot(nan, nan, 'r.', 'DisplayName', 'Spoofed');
    plot(nan, nan, 'g.', 'DisplayName', 'Victim');
    plot(nan, nan, 'b.', 'DisplayName', 'Impostor');
    if ~isempty(rendezvous_state)
        plot(rendezvous_state(1), rendezvous_state(3), 'kp', ...
            'MarkerSize', 12, 'MarkerFaceColor', 'k', 'DisplayName', 'Rendezvous');
    end
    label_step = 5; offset_x = 30; offset_y = 40;
    for k = k_0:label_step:k_3
        if ~isempty(truth.attack.X{k})
            px = truth.attack.X{k}(1);
            py = truth.attack.X{k}(3);
            plot([px, px+offset_x], [py, py+offset_y], '-k', 'LineWidth', 0.5, 'HandleVisibility', 'off');
            text(px+offset_x, py+offset_y, num2str(k), 'FontSize', 7, ...
                'HorizontalAlignment', 'left', 'HandleVisibility', 'off');
        end
    end
    xline(truth.X{k_p1}(1,1), '--k', 'Pull-off',  'LabelVerticalAlignment', 'bottom', 'HandleVisibility', 'off');
    xline(truth.X{k_p2}(1,1), '--k', 'Injection', 'LabelVerticalAlignment', 'bottom', 'HandleVisibility', 'off');
    xlim([-331.1, 2509.8]); ylim([0, 848.2465]);
    legend('Location', 'northwest');
    xlabel('x-coordinate (m)'); ylabel('y-coordinate (m)');
    set(gca, 'FontSize', 14, 'FontName', 'Times New Roman');
    grid on; hold off;

    %% --- Ground truth plot
    plot_flags.show_time_labels     = false;
    plot_flags.show_fake_trajectory = true;
    [~, colorarray] = plot_truth(settings.source_info, model, truth, plot_flags);

    %% --- Filter results
    sel_agent = 3;
    report_single_result(sel_agent, fused_agents);
    plot_fused_results(model, truth, fused_agents, 'sel_agent', sel_agent);
    settings.plot_flags.show_time_labels = false;
    plot_est_vs_truth(model, settings, truth, fused_agents, 'sel_agent', sel_agent, 'colorarray', colorarray);
    plot_node_estimates(model, settings, truth, fused_agents, 'show_truth', false);

end