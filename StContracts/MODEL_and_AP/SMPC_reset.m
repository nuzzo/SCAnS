function SMPC_reset()
%SMPC_RESET Initialize the control inputs and the performance function of SMPC.
%
% Written by Jiwei Li

global SMPC MODEL AP;

SMPC.u = cell(1,1);            % input variables that will be defined when encoding APs
SMPC.perf_func = [];           % The performance function to be optimized subject to MIP constraints
 
%--------------------------------------------------------------------------
% the following is specially for Markovian Jump Linear Systems (MarkovJump)

if exist('MODEL','var') == 1 && strcmp(MODEL.type,'MarkovJump') == 1
    % SMPC.MJ.AP_scena_bin{i,j} stores an array of binary variables indicating
    % whether a scenario satisfies the i-th AP (chance constraint) at time 
    % j - 1.
    SMPC.MJ.AP_scena_bin = cell(1,1);

    % AP_scena_unrolled(i) = t indicates the horizon [0,t] within which 
    %   AP_scena_bin{i,1}, ..., AP_scena_bin{i,t + 1} 
    % has been assigned to binary values.
    SMPC.MJ.AP_scena_unrolled = -1*ones(AP.N, 1);
end

end

