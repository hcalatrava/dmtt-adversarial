function settings =  gen_settings(varargin)
    % Generate a general setting for a particular scenario via a
    % variable-length input argument list, i.e., a pair of (property, value).
    % Example usage: settings =  gen_settings('case_id',1,'sel_pd',0.98);    

    %% --- Input Parser
    p = inputParser;
    addParameter(p, 'case_id',   'stealthy', @(x) ischar(x) || isstring(x));
    addParameter(p, 'n_sensors', 0,          @isnumeric);
    addParameter(p, 'sel_pd',    0.98,       @isnumeric);
    addParameter(p, 'save_data', false,      @islogical);
    parse(p, varargin{:});
    settings.p.Results = p.Results;

    if p.Results.save_data
        settings.folder_path = create_subfolder_by_timestamp('results');
        write_to_log(settings.folder_path, '%%%%%%%%%%----- Start program ------%%%%%%%%%%%%%%%%%\n', 'fopen_tag', 'a');
    end

    %% --- Network parameters
    n_sensors = 3;
    if p.Results.n_sensors > 0, n_sensors = p.Results.n_sensors; end
    sel_pd = 0.98;
    if p.Results.sel_pd > 0,    sel_pd    = p.Results.sel_pd;    end

    settings.K             = 80;
    settings.limit         = [-500, 2500; 0, 1000];
    settings.fov_angle     = 60;
    settings.fov_center    = 90;
    settings.rD_max        = 800;
    settings.winlen_lm     = 5;
    settings.sigma_v_truth = 0.1;

    init_source_pos = [0 0; 1000 0; 1800 0]';
    malicious_flag  = [0, 1, 0];
    for i = 1:n_sensors
        settings.source_info{i}.source_id      = i;
        settings.source_info{i}.source_pos     = init_source_pos(:, i);
        settings.source_info{i}.malicious_flag = malicious_flag(i);
        settings.source_info{i}.P_D            = sel_pd;
    end
    settings.source_info{1}.neighbor_id = [2, 3];
    settings.source_info{2}.neighbor_id = [1, 3];
    settings.source_info{3}.neighbor_id = [1, 2];
    
    %% --- Target trajectories
    % Victim target (born at k=1, moves right across the scene)
    settings.xstart(:, 1) = [-200; 17; 450; 0];
    settings.tbirth(1)    = 1;
    settings.tdeath(1)    = 80;

    % Impostor target
    settings.xstart(:, 2) = [2550; -17; 400; 0];
    settings.tbirth(2)    = 28;
    settings.tdeath(2)    = 80;

    % Spoofed track 
    settings.xstart_attack(:, 1) = [280; 10; 450; 0]; % this could be extracted from intercepted readings
    settings.tbirth_attack(1)    = 17;
    settings.tdeath_attack(1)    = 80;

    %% LMB birth model
    % birth info: birth parameters (LMB birth model, single component only) --- 
    % when adaptive birth not used (i.e., at k = 1 when no measurements available yet)
    settings.T_birth  = 2;
    settings.L_birth  = zeros(settings.T_birth, 1);
    settings.r_birth  = zeros(settings.T_birth, 1);
    settings.w_birth  = cell(settings.T_birth, 1);
    settings.m_birth  = cell(settings.T_birth, 1);
    settings.B_birth  = cell(settings.T_birth, 1);
    settings.P_birth  = cell(settings.T_birth, 1);
    settings.Bb_birth = diag([30; 20; 30; 20]);
    settings.Pb_birth = settings.Bb_birth * settings.Bb_birth';
    settings.rb_birth = 0.04;

    for i = 1:settings.T_birth
        settings.L_birth(i)        = 1;
        settings.r_birth(i)        = settings.rb_birth;
        settings.w_birth{i}(1, 1)  = 1;
        settings.B_birth{i}(:,:,1) = settings.Bb_birth;
        settings.P_birth{i}(:,:,1) = settings.Pb_birth;
    end
    settings.m_birth{1}(:, 1) = [0;   0; 0;   0];
    settings.m_birth{2}(:, 1) = [100; 0; 100; 0];                                         %cov of Gaussians
    
    % adaptive birth procedure
    settings.abp.enable = true; 
    settings.abp.lambda_b = 0.5;                                                                    %expected number of births at each time
    settings.abp.rB_max = 0.03;                                                                     %maximum existence probability of a newly born object
    settings.abp.w_birth = 1;                                                                       %weight of Gaussians
    settings.abp.P_birth = settings.Pb_birth;                                                       %birth covariance     
    
end
