function SMPC_reset()
%SMPC_RESET Reset the control inputs and the performance function of SMPC.
%
% Written by Jiwei Li

global SMPC;

SMPC.u = cell(1);                         % input sequence, automatically resizing
SMPC.perf_func = [];                      % The performance function to be optimized subject to MIP constraints
SMPC.cons = [];                           % constraint set of SMPC
SMPC.engine_h = [];                       % engine health read by stochastic MPC
SMPC.bat = [];                            % battery level

end

