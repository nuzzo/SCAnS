function StSTL_reset(encoding_style)
%STSTL_RESET Specify the encoding style and discard old formulas that have already been recorded.
%   input: encoding_style - It is a string and has 3 possible values:
%                           'equivalent': equivalent encoding, which will call AP_to_equiv_MIP.m
%                           'sufficient': sufficient encoding, which will call AP_to_suffi_MIP.m
%                           'necessary': necessary encoding, which will call AP_to_neces_MIP.m
%
%	Written by Jiwei Li

global StSTL;

StSTL.style = encoding_style;   % set the encoding style as given
StSTL.total_formu = 0;          % clear the number of formulas been recorded
StSTL.MIP_cons = [];            % empty MIP constraints
StSTL.total_MIP_cons = 0;       % clear the number of MIP constraints
StSTL.unrolled = -1;            % [u_0, ..., u_{StSTL.unrolled}] has been defined by encoding APs
                                % StSTL.unrolled = -1 indicates that u_0 has not been defined
end

