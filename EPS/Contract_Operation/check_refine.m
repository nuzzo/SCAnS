function out = check_refine(contract1, contract2, encoding_style)
%CHECK_REFINE Check that whether contract2 refines contract1.
%   input: contract1, contract2 - two structures of contracts, each containing its assumption and guarantee.
%          encoding_style - a string of 'equivalent' or 'suffi_and_neces'.
%                           If encoding_style = 'equivalent', then the
%                           equivalent encoding is used. In the other
%                           case, we will first use the necessary encoding, 
%                           whose infeasibility can verify the refinement. 
%                           If it is feasible, then we will use the 
%                           sufficient encoding, whose feasibility verifies
%                           that the refinement does not hold.
%   output: out - 1 indicates that contract2 refines contract1.
%                 0 indicates that contract2 does not refine contract1.
%                 -1 indicates that no conclusion is drawn.
%
% Written by Jiwei Li

global StSTL SMPC contract_checking;

%--------------------------------------------------------------------------
% Step 1: check if refinement (contract2.A,contract2.G) <= (contract1.A,contract1.G) holds. 
% Need both 'for any u, contract1.A -> contract2.A' and 'for any u, contract2.G -> contract1.G' to imply refinement.

% Step 1.1: check if 'for any u, contract1.A -> contract2.A', as indicated by the infeasible optimization.
if strcmp(encoding_style, 'equivalent')
    StSTL_reset(encoding_style);    % reset StSTL and use the equivalent encoding
    SMPC_reset();
else
    StSTL_reset('necessary');       % reset StSTL and use the necessary encoding
    SMPC_reset();
end

contract_checking = 1;              % indicate that this is a contract checking
verbose = 0;                        % display optimization information
disp_feas = 0;                      % display a feasible solution

i1 = add_formula(['And(',contract1.A,',Not(',contract2.A,'))']);      % not contract1.A -> contract2.A
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
if diagnostic1.problem == 1
    any_u_A1_imply_A2 = 1;
elseif diagnostic1.problem == 0 && strcmp(encoding_style, 'equivalent')
    out = 0;
    fprintf(['(',contract2.A,',',contract2.orig_G,') does not refine (',contract1.A,',',contract1.orig_G,')\n']);
    fprintf(['\tbecause for any u, not(',contract1.A,' -> ',contract2.A,') holds\n']);
    if disp_feas == 1
        fprintf('\ta feasible x_0 is given by:\n');
        eval('value(SMPC.x0)');
        fprintf('\ta feasible trajectory of u is given by:\n');
        for t = 0:StSTL.unrolled
            eval('value(SMPC.u{t + 1})');
        end
    end
    fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic1.solvertime);
    fprintf(['\tencoding style: ', encoding_style, ', ',diagnostic1.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
else
    any_u_A1_imply_A2 = 0;
end

% Step 1.2: check if 'for any u, contract2.G -> contract1.G', as indicated by the infeasible optimization.
if strcmp(encoding_style, 'equivalent')
    StSTL_reset(encoding_style);    % reset StSTL and use the equivalent encoding
else
    StSTL_reset('necessary');       % reset StSTL and use the necessary encoding
end

i2 = add_formula(['Not(Or(Not(',contract2.G,'),',contract1.G,'))']);    % not contract2.G -> contract1.G
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
    any_u_G2_imply_G1 = 1;
elseif diagnostic2.problem == 0 && strcmp(encoding_style, 'equivalent')
    out = 0;
    fprintf(['(',contract2.A,',',contract2.orig_G,') does not refine (',contract1.A,',',contract1.orig_G,')\n']);
    fprintf(['\tbecause for any u, not(',contract2.G,' -> ',contract1.G,') holds\n']);
    if disp_feas == 1
        fprintf('\ta feasible x_0 is given by:\n');
        eval('value(SMPC.x0)');
        fprintf('\ta feasible trajectory of u is given by:\n');
        for t = 0:StSTL.unrolled
            eval('value(SMPC.u{t + 1})');
        end
    end
    fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic1.solvertime + diagnostic2.solvertime);
    fprintf(['\tencoding style: ', encoding_style, ', ',diagnostic2.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
else
    any_u_G2_imply_G1 = 0;
end

if any_u_A1_imply_A2 == 1 && any_u_G2_imply_G1 == 1
    out = 1;
    fprintf(['(',contract2.A,',',contract2.orig_G,') refines (',contract1.A,',',contract1.orig_G,')\n']);
    fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic1.solvertime + diagnostic2.solvertime);
    fprintf(['\tencoding style: ', encoding_style, ', ',diagnostic2.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
end

%--------------------------------------------------------------------------
% Step 2: check if refinement (contract2.A,contract2.G) <= (contract1.A,contract1.G) does not hold. 
% Need either 'for some u, Not(contract1.A -> contract2.A)' or 'for some u, Not(contract2.G -> contract1.G)' to imply no refinement.

% Step 2.1: check if 'for some u, Not(contract1.A -> contract2.A)', as indicated by the feasible optimization.
if strcmp(encoding_style, 'equivalent')
    StSTL_reset(encoding_style);    % reset StSTL and use the equivalent encoding
else
    StSTL_reset('sufficient');      % reset StSTL and use the sufficient encoding
end

i3 = add_formula(['Not(Or(Not(',contract1.A,'),',contract2.A,'))']);      % not contract1.A -> contract2.A
enforce_formula(i3);
options = sdpsettings('solver','gurobi','verbose',verbose);
diagnostic3 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
if diagnostic3.problem ~= 1 && diagnostic3.problem ~= 0     % maybe gurobi is not applicable
    options = sdpsettings('solver','bmibnb','bmibnb.upper','fmincon','verbose',verbose);
    diagnostic3 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
end
if diagnostic3.problem ~= 1 && diagnostic3.problem ~= 0     % if still does not work, let Yalmip choose a solver
    options = sdpsettings('verbose',verbose);
    diagnostic3 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
end
if diagnostic3.problem == 0     % 'for some u, Not(contract1.A -> contract2.A)'
    out = 0;
    fprintf(['(',contract2.A,',',contract2.orig_G,') does not refine (',contract1.A,',',contract1.orig_G,')\n']);
    fprintf(['\tbecause for some u, Not(',contract1.A,' -> ',contract2.A,') holds\n']);
    if disp_feas == 1
        fprintf('\ta feasible x_0 is given by:\n');
        eval('value(SMPC.x0)');
        fprintf('\ta feasible trajectory of u is given by:\n');
        for t = 0:StSTL.unrolled
            eval('value(SMPC.u{t + 1})');
        end
    end
    fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic3.solvertime);
    fprintf(['\tencoding style: ', encoding_style, ', ', diagnostic3.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
end

% Step 2.2: check if 'for some u, Not(contract2.G -> contract1.G)', as indicated by the feasible optimization.
if strcmp(encoding_style, 'equivalent')
    StSTL_reset(encoding_style);    % reset StSTL and use the equivalent encoding
else
    StSTL_reset('sufficient');      % reset StSTL and use the sufficient encoding
end

i4 = add_formula(['Not(Or(Not(',contract2.G,'),',contract1.G,'))']);      % not contract2.G -> contract1.G
enforce_formula(i4);
options = sdpsettings('solver','gurobi','verbose',verbose);
diagnostic4 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
if diagnostic4.problem ~= 1 && diagnostic4.problem ~= 0     % maybe gurobi is not applicable
    options = sdpsettings('solver','bmibnb','bmibnb.upper','fmincon','verbose',verbose);
    diagnostic4 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
end
if diagnostic4.problem ~= 1 && diagnostic4.problem ~= 0     % if still does not work, let Yalmip choose a solver
    options = sdpsettings('verbose',verbose);
    diagnostic4 = optimize(StSTL.MIP_cons, SMPC.perf_func, options);
end
if diagnostic4.problem == 0     % 'for some u, Not(contract2.G -> contract1.G)'
    out = 0;
    fprintf(['(',contract2.A,',',contract2.orig_G,') does not refine (',contract1.A,',',contract1.orig_G,')\n']);
    fprintf(['\tbecause for some u, Not(',contract2.G,' -> ',contract1.G,') holds\n']);
    if disp_feas == 1
        fprintf('\ta feasible x_0 is given by:\n');
        eval('value(SMPC.x0)');
        fprintf('\ta feasible trajectory of u is given by:\n');
        for t = 0:StSTL.unrolled
            eval('value(SMPC.u{t + 1})');
        end
    end
    fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic4.solvertime);
    fprintf(['\tencoding style: ', encoding_style, ', ', diagnostic4.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
end

out = -1;
fprintf(['no conclusion on whether (',contract2.A,',',contract2.orig_G,') refines (',contract1.A,',',contract1.orig_G,') or not\n']);
fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic1.solvertime + diagnostic2.solvertime + diagnostic3.solvertime + diagnostic4.solvertime);
fprintf(['\tencoding style: ', encoding_style, ', solvers used: ', diagnostic1.info, ',', diagnostic2.info, ',', diagnostic3.info, ',', diagnostic4.info, ',', '\n']);
contract_checking = 0;              % indicate that contract checcking terminates

end

