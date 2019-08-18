function out = check_consis(contract, encoding_style)
%CHECK_COMPAT Check the consistency of a given contract, i.e., if the
% guarantee of the contract is feasible.
%   input: contract - a structure containing the assumption and the guarantee.
%          encoding_style - a string of 'equivalent' or 'suffi_and_neces'.
%                           If encoding_style = 'equivalent', then the
%                           equivalent encoding is used. In the other 
%                           case, we will first use the sufficient encoding, 
%                           whose feasibility verifies that the contract is 
%                           consistent. If it is not feasible, then we will 
%                           use the necessary encoding, whose infeasibility 
%                           verifies that the contract is inconsistent.
%   output: out - 1 indicates that this contract is consistent.
%                 0 indicates that this contract is inconsistent.
%                 -1 indicates that no conclusion is drawn.
%
% Written by Jiwei Li

global StSTL SMPC contract_checking;

if strcmp(encoding_style, 'equivalent')
    StSTL_reset(encoding_style);    % reset StSTL and use the equivalent encoding
    SMPC_reset();
else
    StSTL_reset('sufficient');      % reset StSTL and use the sufficient encoding
    SMPC_reset();
end

contract_checking = 1;              % indicate that this is a contract checking
verbose = 0;                        % display optimization information
disp_feas = 0;                      % display a feasible solution

i1 = add_formula(contract.G);
enforce_formula(i1);
options = sdpsettings('solver','gurobi','verbose',verbose);
diagnostic1 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
if diagnostic1.problem ~= 1 && diagnostic1.problem ~= 0     % maybe gurobi is not applicable
    options = sdpsettings('solver','bmibnb','bmibnb.upper','fmincon','verbose',verbose);
    diagnostic1 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
end
if diagnostic1.problem ~= 1 && diagnostic1.problem ~= 0     % if still does not work, let Yalmip choose a solver
    options = sdpsettings('verbose',verbose);
    diagnostic1 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
end
if diagnostic1.problem == 0
    out = 1;
    fprintf(['contract (',contract.A,',,,',contract.G,') is consistent\n']);
    if disp_feas == 1
        fprintf('\ta feasible x_0 is given by:\n');
        eval('value(SMPC.x0)');
        fprintf('\ta feasible trajectory of u is given by:\n');
        for t = 0:StSTL.unrolled
            eval('value(SMPC.u{t + 1})');
        end
    end
    fprintf('\tcheck_consis() solvertime: %3.3f\n', diagnostic1.solvertime);
    fprintf(['\tencoding style: ', encoding_style, ', ',diagnostic1.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
elseif diagnostic1.problem == 1 && strcmp(encoding_style, 'equivalent')
    out = 0;
    fprintf(['contract (',contract.A,',,,',contract.G,') is inconsistent\n']);
    fprintf('\tcheck_consis() solvertime: %3.3f\n', diagnostic1.solvertime);
    fprintf(['\tencoding style: ', encoding_style, ', ',diagnostic1.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
elseif strcmp(encoding_style, 'equivalent')
    out = -1;
    fprintf(['no conclusion on whether contract (',contract.A,',,,',contract.G,') is consistent or not\n']);
    fprintf('\tcheck_consis() solvertime: %3.3f\n', diagnostic1.solvertime);
    fprintf(['\tcheck_consis() optimization information: ', diagnostic1.info, '\n']);
    fprintf(['\tencoding style: ', encoding_style, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
end

StSTL_reset('necessary');           % reset StSTL and use the necessary encoding

i2 = add_formula(contract.G);
enforce_formula(i2);
options = sdpsettings('solver','gurobi','verbose',verbose);
diagnostic2 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
if diagnostic2.problem ~= 1 && diagnostic2.problem ~= 0     % maybe gurobi is not applicable
    options = sdpsettings('solver','bmibnb','bmibnb.upper','fmincon','verbose',verbose);
    diagnostic2 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
end
if diagnostic2.problem ~= 1 && diagnostic2.problem ~= 0     % if still does not work, let Yalmip choose a solver
    options = sdpsettings('verbose',verbose);
    diagnostic2 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
end
if diagnostic2.problem == 1
    out = 0;                        % infeasible optimization indicates that this contract is inconsistent
    fprintf(['contract (',contract.A,',,,',contract.G,') is inconsistent\n']);
    fprintf('\tcheck_consis() solvertime: %3.3f\n', diagnostic2.solvertime);
    fprintf(['\tencoding style: ', encoding_style, ', ', diagnostic2.info, '\n']);
    contract_checking = 0;          % indicate that contract checcking terminates
    return;
else
    out = -1;
    fprintf(['no conclusion on whether contract (',contract.A,',,,',contract.orig_G,') is consistent or not\n']);
    fprintf('\tcheck_consis() solvertime: %3.3f\n', diagnostic1.solvertime + diagnostic2.solvertime);
    fprintf(['\tcheck_consis() optimization information: ', diagnostic1.info, ', ', diagnostic2.info, '\n']);
    fprintf(['\tencoding style: ', encoding_style, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
end

end

