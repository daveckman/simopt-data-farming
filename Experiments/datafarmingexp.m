% Data-farming experiment with cross design between problem factors and
% solver factors

% Calling this script would cause a GUI to pop-up...

% -------------------------------------------------------------------------

% Choose settings for problem factors - not all need to be specified
problem_name = 'AMBUSQ'; % to be selected from drop-down menu
n_problem_factors = 8; % to be obtained from problem_structure function

% TO APPEAR IN GUI:
%       (integer)   nAmbulances: # of ambulances
%       (scalar)    lambda: rate of call arrival
%       (scalar)    velfk: fast velocity of ambulances (in km/hr)
%       (scalar)    velsk: slow velocity of ambulances (in km/hr)
%       (scalar)    mus: mean of service times ~ Gamma
%       (scalar)    sigmas: std dev of service times ~ Gamma
%       (scalar)    callmodex: x coord of mode of call loc distribution
%       (scalar)    callmodey: y coord of mode of call loc distribution

% DEMO: VARY JUST THE FIRST TWO SOLVER FACTORS
problem_factor_settings = [...
    1 4 0;        % nAmbulances
    1/100 1/10 2  % lambda
    ];
n_problem_factors_set = 2;

% Write problem factor settings to .txt file
writematrix(problem_factor_settings,'problem_factor_settings.txt','Delimiter','space')

% Create problem factor design - Single-stack NOLHS is hard-coded
!powershell Get-Content problem_factor_settings.txt | stack_nolhs.rb -s 1 > problem_design.txt

% -------------------------------------------------------------------------

% Choose settings for solver factors - not all need to be specified
solver_name = 'STRONG'; % to be selected from drop-down menu
n_solver_factors = 7; % to be obtained from solver_structure function

% DEMO: VARY JUST THE FIRST TWO SOLVER FACTORS
solver_factor_settings = [...
    10 50 0; % r
    1 1.4 2  % delta_threshold
    ];
n_solver_factors_set = 2;

% Write solver factor settings to .txt file
writematrix(solver_factor_settings,'solver_factor_settings.txt','Delimiter','space')

% TO APPEAR IN GUI:
%       (integer)   r: # of replications taken at each solution
%       (scalar)    delta_threshold: minimum trust region radius
%       (scalar)    delta_T: initial trust region radius
%       (scalar)    eta_0: the threshold of accepting
%       (scalar)    eta_1: the threshold of accepting if new soln is much better
%       (scalar)    gamma1: the multiplier of shrinking the trust region
%       (scalar)    gamma2: the multiplier of expanding the trust region

% Create solver factor design - Single-stack NOLHS is hard-coded
!powershell Get-Content solver_factor_settings.txt | stack_nolhs.rb -s 1 > solver_design.txt

% -------------------------------------------------------------------------

% Cross problem factor and solver factor designs
!powershell cross.rb problem_design.txt solver_design.txt > cross_design.csv

% Read in cross design matrix - Each row is a design point
cross_design_matrix = readmatrix('cross_design.csv');
% !!! For categorical factors, the design matrix will need to be stored in a cell

% Chosen in GUI after seeing how many design points there are
n_macroreps = 2;

% -------------------------------------------------------------------------

%%

% Set up the shared variables for parallel computing toolbox
% The following block of code is taken from DOERunWrapper_parallel.m
% Function handles can be made here, outside the parfor loop.

% problempath = strcat(pwd,'/../Problems/',problemname);
% if exist(problempath, 'dir') ~= 7
%     disp(strcat('The problem folder ', problemname, ' does not exist.'))
%     return
% end
% addpath(problempath)
% probHandle = str2func(problemname);
% probstructHandle = str2func(strcat(problemname, 'Structure'));
% probgenHandle = str2func(strcat(problemname, 'Generate'));
% 
% % % If Parallel Computing Toolbox installed...
% % if exist('gcp', 'file') == 2
% %     % Share problem file problem_name.m to all processors
% %     addAttachedFiles(gcp, strcat(problemname,'.m'))
% %     addAttachedFiles(gcp, strcat(problemname,'Structure.m'))
% % end
% 
% rmpath(problempath)
% 
% % Create function handle for solver
% solverpath = strcat(pwd,'/../Solvers/',solvername);
% if exist(solverpath, 'dir') ~= 7
%     disp(strcat('The solver folder ', solvername, ' does not exist.'))
%     return
% end
% addpath(solverpath)
% solverHandle = str2func(solvername);
% 
% % % If Parallel Computing Toolbox installed...
% % if exist('gcp', 'file') == 2
% %     % Share problem file solver_name.m to all processors
% %     addAttachedFiles(gcp, strcat(solvername,'.m'))
% % end
% 
% rmpath(solverpath)

% -------------------------------------------------------------------------

%%

% For each design point, store data in a separate .mat file.
parfor rowid = 1:size(cross_design_matrix,1)
    
    fprintf('Running design point %d of %d.\n', rowid, size(cross_design_matrix,1))
    
    % Extract the problem factors from the cross design matrix
    problem_factors_set = cross_design_matrix(rowid, 1:n_problem_factors_set);
    problem_params = cell(1, n_problem_factors);
    for i = 1:n_problem_factors_set % The GUI will provide the right mapping
        problem_params{i} = problem_factors_set(i);
        % Empty elements will be set to defaults within DOERunWrapper
    end
    
    % Extract the solver factors from the cross design matrix
    solver_factors_set = cross_design_matrix(rowid, (n_problem_factors_set + 1):(n_problem_factors_set + n_solver_factors_set));
    solver_params = cell(1, n_solver_factors);
    for i = 1:n_solver_factors_set % The GUI will provide the right mapping
        solver_params{i} = solver_factors_set(i);
        % Empty elements will be set to defaults within DOERunWrapper
    end
    
    % Run macroreplications at design point and record outputs to
    % Experiment_#.mat
    experiment_name = ['Experiment_',num2str(rowid)];
    DOERunWrapper_parallel(problem_name, solver_name, n_macroreps, problem_params, solver_params, experiment_name)

end