function SMPC_config()
%SMPC_CONFIG Initialize the control inputs and the performance function of SMPC.
%
% Written by Jiwei Li

global SMPC MODEL;

SMPC.u = cell(1);                         % input sequence, automatically resizing
SMPC.perf_func = [];                      % The performance function to be optimized subject to MIP constraints
SMPC.Lambda1 = [0;1;2;...                 % penalty on engine 1,2,3 to bus 1
                1;0;2];                   % penalty on engine 1,2,3 to bus 2
SMPC.Lambda2 = -[(1:1:MODEL.N_sl)';...     % penalty on left load 1,...,10 to bus 1
                zeros(MODEL.N_nsl,1);...   % penalty on left load 11,...,20 to bus 1
                (1:1:MODEL.N_sl)';...      % penalty on right load 1,...,10 to bus 2
                zeros(MODEL.N_nsl,1)];     % penalty on right load 11,...,20 to bus 2
SMPC.cons = [];                 % constraint set of SMPC
SMPC.engine_h = [];             % engine health read by stochastic MPC
SMPC.bat = [];                  % battery level read by stochastic MPC
SMPC.HL_result = [];            % store optimization result
SMPC.last_delta = [];           % most recent delta state
SMPC.last_c = [];               % most recent c state
SMPC.bat1_hrzn = 5;
SMPC.bat2_hrzn = 5;

end

