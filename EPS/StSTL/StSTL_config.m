function StSTL_config()
%STSTL_CONFIG Configure the encoding of StSTL.
%
%	Written by Jiwei Li

global StSTL;
StSTL.style = 'equivalent';     % 'equivalent' - equivalent encoding, which will call AP_to_equiv_MIP.m
                                % 'sufficient' - sufficient encoding, which will call AP_to_suffi_MIP.m
                                % 'necessary' - necessary encoding, which will call AP_to_neces_MIP.m
                                % This setting is a placeholder and will be changed by StSTL_reset(). 

StSTL.display = 0;              % display information about the encoding for debugging
StSTL.repeat_check = 1;         % check if formulas have been already encoded
StSTL.large_num = 10^5;         % Big-M default value. large_num = 10^10 brings unpredictable infeasible issue!!!
StSTL.small_num = 0.001;        % Small-epsilon default value

% The following codes form a quadruple (formu_str, formu_time, formu_neg, formu_bin).
% Each new formula encountered in the encoding is recorded in the quadruple.
% These four fields will automatically expand to accommodate new formulas.
StSTL.formu_str = cell(1,1);    % the string of a formula
StSTL.formu_time = cell(1,1);   % the satisfaction interval of a formula
StSTL.formu_neg = cell(1,1);    % the number of negation prefixes of a formula
StSTL.formu_bin = cell(1,1);    % the binary variable assigned to a formula

StSTL.total_formu = 0;          % number of formulas recorded in the quadruple
StSTL.MIP_cons = [];            % MIP constraints to encode the formulas
StSTL.total_MIP_cons = 0;       % number of MIP constraints

StSTL.unrolled = -1;            % [u_0, ..., u_{StSTL.unrolled}] has been defined by encoding APs
                                % StSTL.unrolled = -1 indicates that u_0 has not been defined
end

