function [minmax, d, m, VarNature, VarBds, FnGradAvail, NumConstraintGradAvail, StartingSol, budget, ObjBd, OptimalSol, NumRngs] = AMBUSQStructure(NumStartingSol, ProblemInstance)

% Inputs:
%	a) NumStartingSol: Number of starting solutions required. Integer, >= 0
%   b) ProblemInstance: a cell containing the problem instance:
%       (integer)   nAmbulances: # of ambulances
%       (scalar)    lambda: rate of call arrival
%       (scalar)    velfk: fast velocity of ambulances (in km/hr)
%       (scalar)    velsk: slow velocity of ambulances (in km/hr)
%       (scalar)    mus: mean of service times ~ Gamma
%       (scalar)    sigmas: std dev of service times ~ Gamma
%       (scalar)    callmodex: x coord of mode of call loc distribution
%       (scalar)    callmodey: y coord of mode of call loc distribution
%
% Return structural information on optimization problem
%     a) minmax: -1 to minimize objective , +1 to maximize objective
%     b) d: positive integer giving the dimension d of the domain
%     c) m: nonnegative integer giving the number of constraints. All
%        constraints must be inequality constraints of the form LHS >= 0.
%        If problem is unconstrained (beyond variable bounds) then should be 0.
%     d) VarNature: a d-dimensional column vector indicating the nature of
%        each variable - real (0), integer (1), or categorical (2).
%     e) VarBds: A d-by-2 matrix, the ith row of which gives lower and
%        upper bounds on the ith variable, which can be -inf, +inf or any
%        real number for real or integer variables. Categorical variables
%        are assumed to take integer values including the lower and upper
%        bound endpoints. Thus, for 3 categories, the lower and upper
%        bounds could be 1,3 or 2, 4, etc.
%     f) FnGradAvail: Equals 1 if gradient of function values are
%        available, and 0 otherwise.
%     g) NumConstraintGradAvail: Gives the number of constraints for which
%        gradients of the LHS values are available. If positive, then those
%        constraints come first in the vector of constraints.
%     h) StartingSol: One starting solution in each row, or NaN if NumStartingSol=0.
%        Solutions generated as per problem writeup
%     i) budget: maximum budget, or NaN if none suggested
%     j) ObjBd is a bound (upper bound for maximization problems, lower
%        bound for minimization problems) on the optimal solution value, or
%        NaN if no such bound is known.
%     k) OptimalSol is a d dimensional column vector giving an optimal
%        solution if known, and it equals NaN if no optimal solution is known.
%     l) NumRngs: the number of random number streams needed by the
%        simulation model

%   ***************************************
%   *** Written by Shane Henderson to   ***
%   *** use standard calling and random ***
%   *** number streams                  ***
%   *** Modified by Shane Henderson to  ***
%   *** run as a terminating simulation ***
%   *** where each day is one rep.      ***
%   *** Ambs start out avail at base.   ***
%   ***************************************
%  Last updated February 3, 2020

% Unpack problem instance
nAmbulances = ProblemInstance{1};
lambda = ProblemInstance{2};
velfk = ProblemInstance{3};
velsk = ProblemInstance{4};
mus = ProblemInstance{5};
sigmas = ProblemInstance{6};
callmodex = ProblemInstance{7};
callmodey = ProblemInstance{8};

minmax = -1; % Minimize mean response time (+1 for maximize)
d = 2 * nAmbulances; % (x, y) for each ambulance
m = 0; % No constraints
VarNature = zeros(d, 1); % Real variables
VarBds = ones(d, 1) * [0, 1]; % x, y are in [0, 1]
FnGradAvail = 0; % No derivatives when number of ambulances is > 1
NumConstraintGradAvail = 0; % No constraints
budget = 5000; % Number of one-day simulation replications allowed
ObjBd = NaN;
OptimalSol = NaN;
NumRngs = 3;

if (NumStartingSol < 0) || (NumStartingSol ~= round(NumStartingSol))
    fprintf('NumStartingSol should be integer >= 0, seed must be a positive integer\n');
    StartingSol = NaN;
else
    if (NumStartingSol == 0)
        StartingSol = NaN;
    else
        % Matlab fills random matrices by column, thus the transpose
        StartingSol = rand(2 * nAmbulances, NumStartingSol)'; % Each row is uniformly distributed in 2*NumAmbs dimensions
    end %if NumStartingSol
end %if inputs ok