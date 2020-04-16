function [ProblemInstance] = AMBUSQGenerate(ProbParam) %InstanceParameters

% Inputs:
% a) ProbParam: Parameters associated with desired instance, a cell. 
% See markdown file for more detail. Cell contains:
%       (integer)   nAmbulances: # of ambulances
%       (scalar)    lambda: rate of call arrival
%       (scalar)    velfk: fast velocity of ambulances (in km/hr)
%       (scalar)    velsk: slow velocity of ambulances (in km/hr)
%       (scalar)    mus: mean of service times ~ Gamma
%       (scalar)    sigmas: std dev of service times ~ Gamma
%       (scalar)    callmodex: x coord of mode of call loc distribution
%       (scalar)    callmodey: y coord of mode of call loc distribution      

%  If InstanceParameters is the empty cell then default values are used.
%
% Outputs
% a) ProblemInstance: a cell containing the problem instance:
%       (integer)   nAmbulances: # of ambulances
%       (scalar)    lambda: rate of call arrival
%       (scalar)    velfk: fast velocity of ambulances (in km/hr)
%       (scalar)    velsk: slow velocity of ambulances (in km/hr)
%       (scalar)    mus: mean of service times ~ Gamma
%       (scalar)    sigmas: std dev of service times ~ Gamma
%       (scalar)    callmodex: x coord of mode of call loc distribution
%       (scalar)    callmodey: y coord of mode of call loc distribution

%   *************************************************************
%   ***          Adapted from AMBUSQ by David Eckman          ***
%   ***    david.eckman@northwestern.edu    April 9, 2020     ***
%   *************************************************************

defaults = {...
    3, ...     % nAmbulances
    1/60, ...  % lambda % 1 call per hour
    60, ...    % velfk
    40, ...    % velsk
    45/60, ... % mus 
    5/60, ...  % sigmas
    0.8, ...   % callmodex 
    0.8};       % callmodey 

DefaultSize = size(defaults);
nparam = DefaultSize(2);

CellSize = size(ProbParam);
if (CellSize(1) ~= 1) || (CellSize(2) ~= nparam)
  fprintf('Input parameter cell to AMBUSQ should be a cell of %d components. \n', nparam);
  return;

else
    % Copy inputs and initialize empty inputs to default values
    ProblemInstance = ProbParam;
    
    % Need to check constraints on components of ProbParam (e.g.,
    % nonnegativity, integer)
    
    for param_index = 1:nparam
        if isempty(ProblemInstance{param_index})
            ProblemInstance{param_index} = defaults{param_index};
        end
    end
end