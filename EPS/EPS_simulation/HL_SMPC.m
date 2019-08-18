function out_para = HL_SMPC(in_para)
%HL_SMPC Compute control asvice (on/off state) of contactors

%   Written by Jiwei Li

global StSTL EPS MODEL AP SMPC SIMU contract_checking control_contract;

SMPC_reset();

Ns = MODEL.Ns;
N_sl = MODEL.N_sl;
N_nsl = MODEL.N_nsl;

SIMU.t = in_para(1);
k = mod(SIMU.t,EPS.HL_sample_t);
if 0 == k || k > StSTL.unrolled
    fprintf('------time = %3.0f, HL_SMPC() computes new advice------\n',SIMU.t);
else
    fprintf('------time = %3.0f, HL_SMPC() applies old advice------\n',SIMU.t);
    delta_eng1 = [SMPC.HL_result.u{k+1}(1);SMPC.HL_result.u{k+1}(1+Ns)];
    delta_eng2 = [SMPC.HL_result.u{k+1}(2);SMPC.HL_result.u{k+1}(2+Ns)];
    delta_eng3 = [SMPC.HL_result.u{k+1}(3);SMPC.HL_result.u{k+1}(3+Ns)];
    conta_bus1_sload = SMPC.HL_result.u{k+1}((5*Ns + 1):(5*Ns + N_sl));
    conta_bus2_sload = ...
        SMPC.HL_result.u{k+1}((5*Ns + N_sl + N_nsl + 1):(5*Ns + 2*N_sl + N_nsl));
    conta = [delta_eng1;conta_bus1_sload;delta_eng2;conta_bus2_sload;delta_eng3];
    out_para = [conta;SIMU.t];
    return;
end

%---------------------obtain information from in_para----------------------

sensor = in_para(2:(1 + EPS.sensor_n));
SMPC.engine_h = sensor(1:EPS.engine_n,1);
SMPC.bat = sensor((EPS.sensor_n - 1):EPS.sensor_n);% battery level at time 0

%------------------------Probabilistic constraints-------------------------

tic;
StSTL_reset('sufficient');
contract_checking = 0;  % indicate that this is control, not contract checking

b = add_formula(control_contract.orig_G);
enforce_formula(b);

% G = ['And(','Global(AP(1),1,20),',...
%             'Global(AP(2),1,20),',...
%             'Global(AP(7),0,20),',...
%             'Global(AP(8),0,20),',...
%             'Global(AP(9),0,20),',...
%             'Global(AP(10),0,20),',...
%             'Global(AP(11),0,20),',...
%             'Global(AP(12),0,20),',...
%             'Global(AP(13),0,20),',...
%             'Or(Not(AP(3,0)),Until(T(),AP(5),0,',num2str(SMPC.bat1_hrzn),')),',...
%             'Or(Not(AP(4,0)),Until(T(),AP(6),0,',num2str(SMPC.bat2_hrzn),'))',')'];
% b = add_formula(G);
% enforce_formula(b);
% 
% % if battery level is too low, then should go up in 5 steps
% if AP.a{3}'*SMPC.bat + AP.c{3} <= 0
%     SMPC.bat1_hrzn = SMPC.bat1_hrzn - 1;
%     if SMPC.bat1_hrzn == 0
%         SMPC.bat1_hrzn = 1;
%     end
% else
%     SMPC.bat1_hrzn = 5; % reset
% end
% 
% if AP.a{4}'*SMPC.bat + AP.c{4} <= 0
%     SMPC.bat2_hrzn = SMPC.bat2_hrzn - 1;
%     if SMPC.bat2_hrzn == 0
%         SMPC.bat2_hrzn = 1;
%     end
% else
%     SMPC.bat2_hrzn = 5; % reset
% end

%------------------------derive performance function-----------------------

% contactors do not switch too frequently
if SIMU.t > 0
       % consider the switch between current-cycle first signal and last-cycle last signal,
       % and the switch between last signal and last but one signal of last cycle 
    Delta_switch = abs(SMPC.u{1}(1:2*Ns) - SMPC.last_delta);
    C_switch = abs(SMPC.u{1}((5*Ns + 1):end) - SMPC.last_c);
else % SIMU.t == 0
    Delta_switch = zeros(2*Ns,1);
    C_switch = zeros(2*(N_sl + N_nsl),1);
end

SMPC.penalty = SMPC.Lambda1'*SMPC.u{1}(1:2*Ns) +...
    SMPC.Lambda2'*SMPC.u{1}((5*Ns + 1):end) +...
    10*sum(Delta_switch) + 10*sum(C_switch);

for t = 1:1:StSTL.unrolled
    % compute the switch time of contactors
    Delta_switch = abs(SMPC.u{t + 1}(1:2*Ns) - SMPC.u{t}(1:2*Ns));
    C_switch = abs(SMPC.u{t + 1}((5*Ns + 1):end) - SMPC.u{t}((5*Ns + 1):end));
        
    SMPC.penalty = SMPC.penalty +...
        SMPC.Lambda1'*SMPC.u{t + 1}(1:2*Ns) +...
        SMPC.Lambda2'*SMPC.u{t + 1}((5*Ns + 1):end) +...
        10*sum(Delta_switch) + 10*sum(C_switch);
end

SIMU.add_cons_t(SIMU.t + 1,SIMU.LT) = toc;

%-------------------------SMPC optimization problem------------------------

tic;

options = sdpsettings('solver','gurobi','verbose',1,'gurobi.MIPGap',0.1);
% options = sdpsettings('verbose',1);
diagnostics = optimize(StSTL.MIP_cons,SMPC.penalty,options);
SIMU.opti_t(SIMU.t + 1,SIMU.LT) = toc;
SIMU.solver_t(SIMU.t + 1,SIMU.LT) = diagnostics.solvertime;

fprintf(['###HL_SMPC used %3.3f to add constraints, ',...
         '%3.3f to optimize, solvertime is %3.3f \n'],...
        SIMU.add_cons_t(SIMU.t + 1,SIMU.LT),...
        SIMU.opti_t(SIMU.t + 1,SIMU.LT),...
        SIMU.solver_t(SIMU.t + 1,SIMU.LT));
    
% checkset(StSTL.MIP_cons)
[prim_resi, ~] = check(StSTL.MIP_cons);
if any(isnan(prim_resi)) || any(prim_resi < - 0.01)
%     disp('Optimization in HL-SMPC is infeasible!');
%     checkset([SMPC.cons,StSTL.MIP_cons]);
    adopt_solution = 0;
else
    adopt_solution = 1;
end

if 1 == adopt_solution
    for i = 1:(StSTL.unrolled + 1)
        SMPC.u{i} = value(SMPC.u{i});
        SMPC.u{i}(1:Ns*2) = SMPC.u{i}(1:Ns*2) > 0.5;
        SMPC.u{i}((5*Ns + 1):end) = SMPC.u{i}((5*Ns + 1):end) > 0.5;
    end
else
    for i = 1:(StSTL.unrolled + 1)
        SMPC.u{i} = [1;0;0;0;1;0;ones(EPS.MODEL.nu - 6,1)]; 
        % advice to turn on all loads, will be corrected by LL-LMS
    end
    eval('SMPC.bat');
    disp('HL_SMPC is infeasible!');
end

SMPC.HL_result.u = SMPC.u;
delta_eng1 = [SMPC.u{1}(1);SMPC.u{1}(1+Ns)];
delta_eng2 = [SMPC.u{1}(2);SMPC.u{1}(2+Ns)];
delta_eng3 = [SMPC.u{1}(3);SMPC.u{1}(3+Ns)];
conta_bus1_sload = SMPC.u{1}((5*Ns + 1):(5*Ns + N_sl));
conta_bus2_sload = SMPC.u{1}((5*Ns + N_sl + N_nsl + 1):(5*Ns + 2*N_sl + N_nsl));
conta = [delta_eng1;conta_bus1_sload;delta_eng2;conta_bus2_sload;delta_eng3];

yalmip('clear');
out_para = [conta;SIMU.t]; % SIMU.t acts as a time stamp

end

