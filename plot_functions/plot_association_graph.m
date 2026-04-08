% function plot_association_graph(G, l_space)
    % Check if the graph has any edges
    if isempty(G.Edges)
        disp('No associations found in l_asso_hist.');
        return;
    end

    % Extract node labels
    node_labels = cellfun(@num2str, num2cell(l_space(2, :)), 'UniformOutput', false);

    % Define figure
    figure;
    set(gcf, 'Position', [100, 100, 800, 600]); % Set figure size
    hold on;

    % Plot Graph
    h = plot(G, 'Layout', 'force', 'NodeLabel', node_labels, 'EdgeAlpha', 0.6);

    % Style the graph for better visibility
    h.MarkerSize = 8;          % Node marker size
    h.LineWidth = 1.5;         % Edge thickness
    h.EdgeColor = [0.5 0.5 0.5]; % Gray edges for clarity
    h.NodeColor = [0 0.4470 0.7410]; % MATLAB blue for nodes

    % Add title
    title('Association History Graph');

    hold off;
% end
