# Instructions

To run STRONG on AMBUSQ, do the following:

1. In the MATLAB terminal, navigate to this folder (Experiments).

2. Create a length-8 cell array called `ProbParam`; e.g., `ProbParam = {[], [], [], [], [], [], [], []};`.

3. Create a length-7 cell array called 'SolverParam'; e.g., `SolverParam = {[], [], [], [], [], [], []};`.

4. To run 10 macroreplications (runs) and save to a file with the tag "Experiment 1", type `DOERunWrapper('AMBUSQ', 'STRONG', 10, ProbParam, SolverParam, 'Experiment1');`

**Example:** The first entry in SolverParam is the number of replications STRONG takes at a given feasible solution. If `ProbParam{1}` is left as `[]`, the default value is 30.
