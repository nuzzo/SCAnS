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

contract_checking = 1;              % indicate that this is a contract checking
verbose = 0;                        % display optimization information
disp_feas = 0;                      % display a feasible solution
disp_cons_check = 0;                % display primal residuals of solved constraints

fprintf('----In check_refine(), using ''%s'' encoding----\n', encoding_style);
fprintf(['\tcontract1 = < ', contract1.A, ' ,,, ', contract1.G, ' >\n']);
fprintf(['\tcontract2 = < ', contract2.A, ' ,,, ', contract2.G, ' >\n']);

%--------------------------------------------------------------------------
% Step 1: check if refinement (contract2.A,contract2.G) <= (contract1.A,contract1.G) holds. 
% Need both 'for any u, contract1.A -> contract2.A' and 'for any u, contract2.G -> contract1.G' to imply refinement.

fprintf('Step 1: check if contract2 refines contract1 by ''%s'' encoding\n', encoding_style);

% Step 1.1: check if 'for any u, contract1.A -> contract2.A', as indicated by the infeasible optimization.
fprintf('Step 1.1: check if ''for any u, contract1.A -> contract2.A''\n');

inner_style = '';
if strcmp(encoding_style, 'equivalent')
    inner_style = 'equivalent';
    StSTL_reset(inner_style);    % reset StSTL and use the equivalent encoding
    SMPC_reset();
else
    inner_style = 'necessary';
    StSTL_reset(inner_style);       % reset StSTL and use the necessary encoding
    SMPC_reset();
end

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
    fprintf('\tBy %s encoding: not( contract1.A  ->  contract2.A ) is infeasible\n',inner_style);
    fprintf(['\t', diagnostic1.info, '\n']);
elseif diagnostic1.problem == 0
    fprintf('\tBy %s encoding: not( contract1.A  ->  contract2.A ) is feasible\n',inner_style);
    if disp_feas == 1
        fprintf(['\t\tcontract1.A = ', contract1.A, '\n']);
        fprintf(['\t\tcontract2.A = ', contract2.A, '\n']);
        fprintf('\t\ta feasible x_0 is given by:\n');
        eval('value(SMPC.x0)');
        fprintf('\t\ta feasible trajectory of u is given by:\n');
        for t = 0:StSTL.unrolled
            eval('value(SMPC.u{t + 1})');
        end
    end
    [pres,dres] = check(StSTL.MIP_cons);
    if any(pres < -0.001)
        fprintf('**Step 1.1: Warning! This result may not be accurate since the minimal value of the primal residual is %2.8f\n', min(pres));
    end
    if disp_cons_check == 1
        check(StSTL.MIP_cons);
    end
    fprintf(['\t', diagnostic1.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    if strcmp(encoding_style, 'equivalent')
        fprintf('**After Step 1.1: contract2 does not refine contract1\n');
        fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic1.solvertime);
        fprintf('\tcheck_refine() yalmiptime: %3.3f\n', diagnostic1.yalmiptime);
        out = 0;
        return;
    end
    any_u_A1_imply_A2 = 0;
else
    any_u_A1_imply_A2 = 0;
end

% Step 1.2: check if 'for any u, contract2.G -> contract1.G', as indicated by the infeasible optimization.
fprintf('Step 1.2: check if ''for any u, contract2.G -> contract1.G''\n');

if strcmp(encoding_style, 'equivalent')
    inner_style = 'equivalent';
    StSTL_reset(inner_style);       % reset StSTL and use the equivalent encoding
else
    inner_style = 'necessary';
    StSTL_reset(inner_style);       % reset StSTL and use the necessary encoding
end

i2 = add_formula(['Not(Or(Not(',contract2.G,'),',contract1.G,'))']);    % not contract2.G -> contract1.G
% i2 = add_formula(['And( Not(',contract1.orig_G,'),',contract2.orig_G,')']);    % not contract2.orig_G -> contract1.orig_G
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
    fprintf('\tBy %s encoding: not( contract2.G  ->  contract1.G ) is infeasible\n', inner_style);
    fprintf(['\t', diagnostic2.info, '\n']);
elseif diagnostic2.problem == 0
    fprintf('\tBy %s encoding: not( contract2.G  ->  contract1.G ) is feasible\n', inner_style);
    if disp_feas == 1
        fprintf(['\t\tcontract2.G = ', contract2.G, '\n']);
        fprintf(['\t\tcontract1.G = ', contract1.G, '\n']);
        fprintf('\ta feasible x_0 is given by:\n');
        eval('value(SMPC.x0)');
        fprintf('\ta feasible trajectory of u is given by:\n');
        for t = 0:StSTL.unrolled
            eval('value(SMPC.u{t + 1})');
        end
    end
    [pres,dres] = check(StSTL.MIP_cons);
    if any(pres < -0.001)
        fprintf('**Step 1.2: Warning! This result may not be accurate since the minimal value of the primal residual is %2.8f\n', min(pres));
    end
    if disp_cons_check == 1
        check(StSTL.MIP_cons);
    end
    fprintf(['\t', diagnostic2.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    if strcmp(encoding_style, 'equivalent')
        fprintf('**After Step 1.2: contract2 does not refine contract1\n');
        fprintf('\tsolvertime: %3.3f\n', diagnostic1.solvertime + diagnostic2.solvertime);
        fprintf('\tyalmiptime: %3.3f\n', diagnostic1.yalmiptime + diagnostic2.yalmiptime);
        out = 0;
        return;
    end
    any_u_G2_imply_G1 = 0;
else
    any_u_G2_imply_G1 = 0;
end

if any_u_A1_imply_A2 == 1 && any_u_G2_imply_G1 == 1
    out = 1;
    fprintf('**After Step 1: contract2 is verified to refine contract1\n');
    fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic1.solvertime + diagnostic2.solvertime);
    fprintf('\tcheck_refine() yalmiptime: %3.3f\n', diagnostic1.yalmiptime + diagnostic2.yalmiptime);
    % fprintf(['\tencoding style: ', encoding_style, ', ',diagnostic2.info, '\n']);
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
else
    fprintf('**After Step 1: unable to verify that contract2 refines contract1\n');
end

%--------------------------------------------------------------------------
% Step 2: check if refinement (contract2.A,contract2.G) <= (contract1.A,contract1.G) does not hold. 
% Need either 'for some u, Not(contract1.A -> contract2.A)' or 'for some u, Not(contract2.G -> contract1.G)' to imply no refinement.

fprintf('Step 2: check if contract2 does not refine contract1 by ''%s'' encoding\n', encoding_style);

% Step 2.1: check if 'for some u, Not(contract1.A -> contract2.A)', as indicated by the feasible optimization.
fprintf('Step 2.1: check if ''for some u, Not(contract1.A -> contract2.A)''\n');

if strcmp(encoding_style, 'equivalent')
    inner_style = 'equivalent';
    StSTL_reset(inner_style);    % reset StSTL and use the equivalent encoding
else
    inner_style = 'sufficient';
    StSTL_reset(inner_style);      % reset StSTL and use the sufficient encoding
end

% i3 = add_formula(['Not(Or(Not(',contract1.A,'),',contract2.A,'))']);      % not contract1.A -> contract2.A
i3 = add_formula(['And(',contract1.A,',Not(',contract2.A,'))']);      % not contract1.A -> contract2.A
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
    fprintf('\tBy %s encoding: Not( contract1.A  ->  contract2.A ) is feasible\n', inner_style);
    fprintf(['\t', diagnostic3.info, '\n']);
    fprintf('**After Step 2.1: contract2 does not refine contract1\n');
    fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic3.solvertime);
    fprintf('\tcheck_refine() yalmiptime: %3.3f\n', diagnostic3.yalmiptime);
    
    if disp_feas == 1
        fprintf('\ta feasible x_0 is given by:\n');
        eval('value(SMPC.x0)');
        fprintf('\ta feasible trajectory of u is given by:\n');
        for t = 0:StSTL.unrolled
            eval('value(SMPC.u{t + 1})');
        end
    end
    [pres,dres] = check(StSTL.MIP_cons);
    if any(pres < -0.001)
        fprintf('**After Step 2.1: Warning! This result may not be accurate since the minimal value of the primal residual is %2.8f\n', min(pres));
    end
    if disp_cons_check == 1
        check(StSTL.MIP_cons);
    end
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
elseif diagnostic3.problem == 1
    fprintf('\tBy %s encoding: Not( contract1.A  ->  contract2.A ) is infeasible\n', inner_style);
    fprintf(['\t', diagnostic3.info, '\n']);
end

% Step 2.2: check if 'for some u, Not(contract2.G -> contract1.G)', as indicated by the feasible optimization.
fprintf('Step 2.2: check if ''for some u, Not(contract2.G -> contract1.G)''\n');

if strcmp(encoding_style, 'equivalent')
    inner_style = 'equivalent';
    StSTL_reset(inner_style);    % reset StSTL and use the equivalent encoding
else
    inner_style = 'sufficient';
    StSTL_reset(inner_style);      % reset StSTL and use the sufficient encoding
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
    fprintf('\tBy %s encoding: Not( contract2.G  ->  contract1.G ) is feasible\n', inner_style);
    fprintf(['\t', diagnostic4.info, '\n']);
    fprintf('**After Step 2.2: contract2 does not refine contract1\n');
    fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic4.solvertime);
    fprintf('\tcheck_refine() yalmiptime: %3.3f\n', diagnostic4.yalmiptime);
    
    if disp_feas == 1
        fprintf(['\t\tcontract2.G = ', contract2.G, '\n']);
        fprintf(['\t\tcontract1.G = ', contract1.G, '\n']);
        fprintf('\ta feasible x_0 is given by:\n');
        eval('value(SMPC.x0)');
        fprintf('\ta feasible trajectory of u is given by:\n');
        for t = 0:StSTL.unrolled
            eval('value(SMPC.u{t + 1})');
        end
    end
    [pres,dres] = check(StSTL.MIP_cons);
    if any(pres < -0.001)
        fprintf('**After Step 2.2: Warning! This result may not be accurate since the minimal value of the primal residual is %2.8f\n', min(pres));
    end
    if disp_cons_check == 1
        check(StSTL.MIP_cons);
    end
    contract_checking = 0;              % indicate that contract checcking terminates
    return;
elseif diagnostic4.problem == 1
    fprintf('\tBy %s encoding: Not( contract2.G  ->  contract1.G ) is infeasible\n', inner_style);
    fprintf(['\t', diagnostic4.info, '\n']);
end

out = -1;
fprintf('**After Step 1 and Step 2: no conclusion on whether contract2 refines contract1 or not\n');
fprintf('\tcheck_refine() solvertime: %3.3f\n', diagnostic1.solvertime + diagnostic2.solvertime + diagnostic3.solvertime + diagnostic4.solvertime);
fprintf('\tcheck_refine() yalmiptime: %3.3f\n', diagnostic1.yalmiptime + diagnostic2.yalmiptime + diagnostic3.yalmiptime + diagnostic4.yalmiptime);
% fprintf(['\tsolvers used: ', diagnostic1.info, ',', diagnostic2.info, ',', diagnostic3.info, ',', diagnostic4.info, ',', '\n']);
contract_checking = 0;              % indicate that contract checcking terminates

end

