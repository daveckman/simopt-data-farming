function DOERunWrapper_parallel(problemname, solvername, repsAlg, ProbParam, SolverParam, expname)
% Run a single algorithm on a single problem and write the solutions
% visited, objective function means and variances to a .mat file.

% Inputs:
% problemnameArray: structure listing the problem names
% solvernameArray: structure listing the solver names
% repsAlg: number of macroreplications of each solver on each problem
% Instanceseed: an optional substream index to use for generating random
%   problem instances
% ProbParam: a cell containing the parameters for the problem
% expname: a string to be appended to file names - unique identifier

%   *************************************************************
%   ***                 Updated by David Eckman               ***
%   ***      david.eckman@northwestern.edu   May 1, 2020      ***
%   *************************************************************

% Check if number of macroreplications is an integer
if (repsAlg <= 0) || (mod(repsAlg,1) ~= 0)
    disp('The number of macroreplications (repsAlg) must be a positive integer.')
    return
end

problempath = strcat(pwd,'/../Problems/',problemname);
if exist(problempath, 'dir') ~= 7
    disp(strcat('The problem folder ', problemname, ' does not exist.'))
    return
end
addpath(problempath)
probHandle = str2func(problemname);
probstructHandle = str2func(strcat(problemname, 'Structure'));
probgenHandle = str2func(strcat(problemname, 'Generate'));

% % If Parallel Computing Toolbox installed...
% if exist('gcp', 'file') == 2
%     % Share problem file problem_name.m to all processors
%     addAttachedFiles(gcp, strcat(problemname,'.m'))
%     addAttachedFiles(gcp, strcat(problemname,'Structure.m'))
% end

rmpath(problempath)

% Create function handle for solver
solverpath = strcat(pwd,'/../Solvers/',solvername);
if exist(solverpath, 'dir') ~= 7
    disp(strcat('The solver folder ', solvername, ' does not exist.'))
    return
end
addpath(solverpath)
solverHandle = str2func(solvername);

% % If Parallel Computing Toolbox installed...
% if exist('gcp', 'file') == 2
%     % Share problem file solver_name.m to all processors
%     addAttachedFiles(gcp, strcat(solvername,'.m'))
% end

rmpath(solverpath)

%Generate problem instance specified by ProbParam
ProblemInstance = probgenHandle(ProbParam);

% % If Parallel Computing Toolbox installed...
% if exist('gcp', 'file') == 2
%     % Share variable ProblemInstance to all processors
%     addAttachedFiles(gcp, ProblemInstance)
% end

% Check if the problem is random
%[~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, isRandom] = probstructHandle(0, {});

%     if isRandom == 1 % if problem is random, generate random problem instance      
%         
%         % Create 1 new random number streams that is common across macroreps:
%         %       Stream 1 is used to generate the random problem instance
%         InstanceRng = RandStream.create('mrg32k3a', 'NumStreams', 1, ...
%             'StreamIndices', 1);
%         
%         % Check if given Instanceseed is valid. Otherwise default
%         if (Instanceseed <= 0) || (round(Instanceseed) ~= Instanceseed)
%             fprintf('Problem instance seed was unspecified or not a positive integer. Setting to default value of 1.\n');
%             Instanceseed = 1;
%         end
%     
%         % Generate random problem instance
%         RandStream.setGlobalStream(InstanceRng);
%         InstanceRng.Substream = Instanceseed;
%         ProblemInstance = probgenHandle(InstanceParameters);
%     
%     else % deterministic problem -> ProblemInstance is unused
%         ProblemInstance = {};
%     end

% Get the number of streams needed for the problem
[~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, NumRngs] = probstructHandle(0, ProblemInstance);

% Initialize cells for reporting recommended solutions, etc.
Ancalls_cell = cell(1, repsAlg);
A_cell = cell(1, repsAlg);
AFnMean_cell = cell(1, repsAlg);
AFnVar_cell = cell(1, repsAlg);

% Do repsAlg macroreplications of the algorithm on the problem
%fprintf('Solver %s on problem %s: \n', solvername, problemname)

for j = 1:repsAlg

    %fprintf('\t Macroreplication %d of %d ... \n', j, repsAlg)

    % Create (2 + NumRngs) new random number streams to use for each macrorep solution
    % (#s = {1 + (2 + NumRngs)*(j - 1) + 1, ..., 1 + (2 + NumRngs)*j}) 
    % I.e., for the first macrorep, 
    %       Stream 2 will be used to generate the random initial solution
    %       Stream 3 will be used for a solver's internal randomness
    %       Streams 4, ..., 3 + NumRngs will be used by the problem function
    solverRng = cell(1, 2);
    [solverRng{1}, solverRng{2}] = RandStream.create('mrg32k3a', 'NumStreams', 1 + (2 + NumRngs)*repsAlg, ...
        'StreamIndices', [1 + (2 + NumRngs)*(j - 1) + 1, 1 + (2 + NumRngs)*(j - 1) + 2]);

    problemRng = cell(1, NumRngs);
    for i = 1:NumRngs
        problemRng{i} = RandStream.create('mrg32k3a', 'NumStreams', 1 + (2 + NumRngs)*repsAlg, ...
            'StreamIndices', 1 + (2 + NumRngs)*(j - 1) + 2 + i);
    end

    % Run the solver on the problem and return the solutions (and
    % obj fn mean and variance) whenever the recommended solution changes
    [Ancalls_cell{j}, A_cell{j}, AFnMean_cell{j}, AFnVar_cell{j}, ~, ~, ~, ~, ~, ~] = solverHandle(probHandle, probstructHandle, problemRng, solverRng, ProblemInstance, SolverParam);

    % Append macroreplication number to reporting of budget points
    Ancalls_cell{j} = [j*ones(length(Ancalls_cell{j}),1), Ancalls_cell{j}];

end

% Concatenate cell data across macroreplications
BudgetMatrix = cat(1, Ancalls_cell{:});
SolnMatrix = cat(1, A_cell{:});
FnMeanMatrix = cat(1, AFnMean_cell{:});
FnVarMatrix = cat(1, AFnVar_cell{:});

% Store data in .mat file in RawData folder
solnsfilename = strcat('RawData_',solvername,'_on_',problemname,'_',expname,'.mat');
if exist(strcat('RawData/',solnsfilename), 'file') == 2
    fprintf('\t Overwriting \t --> ')
end

save(strcat(pwd,'/RawData/RawData_',solvername,'_on_',problemname,'_',expname,'.mat'), 'BudgetMatrix', 'SolnMatrix', 'FnMeanMatrix', 'FnVarMatrix', 'ProblemInstance');
fprintf('\t Saved output to file "%s" \n', solnsfilename)

end