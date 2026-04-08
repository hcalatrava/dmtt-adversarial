% --- Van Nguyen et al. TC-DMTT framework
addpath(genpath('misc'));
addpath('filters_joint');
addpath('gen');
addpath('plot_functions');
addpath('results');
addpath('data_fusion');
addpath('run');
addpath('analyze_results');
addpath('track_matching');

% --- Attack code (label hijacking paper)
% --- CasADi (required for stealthy attack MPC)
% Download from https://web.casadi.org/get/ and place in mpc/casadi_files/
addpath('mpc/casadi_files');
addpath('mpc');