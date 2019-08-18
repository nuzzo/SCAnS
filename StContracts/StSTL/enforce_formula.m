function enforce_formula(formu_index, varargin)
%ENFORCE_FORMULA For hard constraints (default or indicated by 'hard' as 
% its second argument), assign the binary variable for a formula indexed 
% by formu_index to 1. For soft constraints indicated by 'soft' as its 
% second argument, add penalty items to StSTL.soft_penalty. 
% StSTL.soft_penalty will be minimized (maybe together with other performance
% objectives) by MPC.
%
%   Written by Jiwei Li

global StSTL;

if size(formu_index,1) ~= 1
    fprintf(StSTL.fid, 'In enforce_formula(): Error! Input of enforce_formula should be a row vector.\n');
    error('In enforce_formula(): Error! Input of enforce_formula should be a row vector.');
end

type = '';
weight = 1;
var_num = length(varargin);
switch var_num
    case 2
        type = varargin{1};
        weight = varargin{2};
    case 1      
        type = varargin{1};
    case 0
        type = 'hard';
end

if 1 == StSTL.display
    if strcmp(type, 'soft')
        fprintf(StSTL.fid, 'In enforce_formula(): type = %s, weight = %d\n', type, weight);
    else
        fprintf(StSTL.fid, 'In enforce_formula(): type = %s\n', type);
    end
end

if ~strcmp(type, 'hard') && ~strcmp(type, 'soft')
    fprintf(StSTL.fid, 'In enforce_formula(): Error! Constraint type is %s, which is neither ''soft'' nor ''hard''.\n', type);
    error('In enforce_formula(): Error! Constraint type is illegal.');
end

for j = 1:size(formu_index,2)
    k = formu_index(j);
    if k > 0 && strcmp(type, 'hard')
        StSTL.MIP_cons = [StSTL.MIP_cons, StSTL.formu_bin{k} == 1];
        StSTL.total_MIP_cons = StSTL.total_MIP_cons + 1;
    elseif k > 0 && strcmp(type, 'soft')
        % penalty items introduced for soft constraints
        StSTL.soft_penalty = StSTL.soft_penalty + weight*(1 - StSTL.formu_bin{k});
    end
end

% fprintf('In enforce_formula(): Total constraint number added into MIP_cons is %d.\n', StSTL.total_MIP_cons);

end

