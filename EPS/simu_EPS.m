% Simulate the EPS under the control of stochastic MPC derived from a given
% contract.
%
% Jiwei Li and Pierluigi Nuzzo

close all;
clear all;
clc;

global to_add;
currentFolder = pwd;
to_add = {[currentFolder,'\StSTL'], [currentFolder,'\Contract_Operation'], ...
    [currentFolder,'\MODEL_and_AP'], [currentFolder,'\EPS_simulation']};
addpath(to_add{1}, to_add{2}, to_add{3}, to_add{4});

% Step 1: set the system model. A global struct SYS that records model 
%         parameters is defined.

run MODEL_EPS;

% Step 2: set atomic propositions. A global struct AP that records the 
%         atomic propositions is defined.

run AP_EPS;

% Step 3: configure StSTL and SMPC. Two global structs StSTL and SMPC are defined.

StSTL_config();
SMPC_config();

% Step 4: make contracts

global control_contract;
assumption = 'And(AP(14,0),AP(15,0),AP(16,0))';
guarantee = ['And(','Global(AP(1),1,20),',...
                    'Global(AP(2),1,20),',...
                    'Global(AP(7),0,20),',...
                    'Global(AP(8),0,20),',...
                    'Global(AP(9),0,20),',...
                    'Global(AP(10),0,20),',...
                    'Global(AP(11),0,20),',...
                    'Global(AP(12),0,20),',...
                    'Global(AP(13),0,20),',...
                    'Or(Not(AP(3,0)),Until(T(),AP(5),0,5)),',...
                    'Or(Not(AP(4,0)),Until(T(),AP(6),0,5))',')'];
control_contract = make_contract(assumption, guarantee);

% Step 5: simulation. The guarantee is translated into SMPC.

global SIMU;

SIMU.loop = 1000; % 500; % 5; % 50; % 
SIMU.step = 100; % 15; % 50; % 
SIMU.save = 1; % 0; % 

SIMU.engine_rec = zeros(EPS.engine_n,SIMU.step + 1,SIMU.loop);
SIMU.conta_h_rec = zeros(EPS.engine_sload_conta_n,SIMU.step + 1,SIMU.loop);
SIMU.conta_HL_rec = zeros(EPS.engine_sload_conta_n,SIMU.step + 1,SIMU.loop);
SIMU.conta_LL_rec = zeros(EPS.engine_sload_conta_n,SIMU.step + 1,SIMU.loop);
SIMU.load_rec = zeros(EPS.load_n,SIMU.step + 1,SIMU.loop);
SIMU.bat_rec = zeros(EPS.bat_n,SIMU.step + 1,SIMU.loop);

SIMU.t = 0;
SIMU.add_cons_t = zeros(SIMU.step + 1,SIMU.loop);
SIMU.opti_t = zeros(SIMU.step + 1,SIMU.loop);
SIMU.solver_t = zeros(SIMU.step + 1,SIMU.loop);

%--simulation begins--
for i = 1:SIMU.loop
    if mod(i,100) == 0
        fprintf('\n loop = %4.0f\n',i);
    end
    SIMU.LT = i;
    open_system('airplane_EPS');
    set_param('airplane_EPS/HL_SMPC','OutputDimensions',...
        num2str(EPS.engine_sload_conta_n + 1));
    set_param('airplane_EPS/LL_LMS','OutputDimensions',...
        num2str(EPS.engine_sload_conta_n));
    set_param('airplane_EPS/EPS_model/EPS_bus/bus_1_left/battery',...
        'SampleTime',num2str(EPS.LL_sample_t),...
        'InitialCondition',num2str(EPS.bat_init(1)),...
        'LimitOutput','on',...
        'LowerSaturationLimit','0',...
        'UpperSaturationLimit',num2str(EPS.bat_max(1)));
    set_param('airplane_EPS/EPS_model/EPS_bus/bus_2_right/battery',...
        'SampleTime',num2str(EPS.LL_sample_t),...
        'InitialCondition',num2str(EPS.bat_init(2)),...
        'LimitOutput','on',...
        'LowerSaturationLimit','0',...
        'UpperSaturationLimit',num2str(EPS.bat_max(2)));
    % SIMU.bat_rec(:,1,i) = EPS.bat_init;
    sim('airplane_EPS', SIMU.step);
end

%--plot the simulation--
j = 0:SIMU.step;

vio_freq = zeros(2,SIMU.step + 1);
for i = 1:SIMU.loop
    vio_freq(1,:) = vio_freq(1,:) + (SIMU.bat_rec(1,:,i) < 0.3*EPS.bat_max(1));
    vio_freq(2,:) = vio_freq(2,:) + (SIMU.bat_rec(2,:,i) < 0.3*EPS.bat_max(2));    
end
vio_freq = vio_freq/SIMU.loop;
vio_freq1 = vio_freq(:,2:end); % exclude the initial state
fprintf('\nMaximal violation frequency of B >= 0.3 is: %1.3f\n',...
    max(vio_freq1(vio_freq1>0)));

fprintf('\nAverage and maximal solver time is: %3.3f, %3.3f\n',...
    mean(SIMU.solver_t(SIMU.solver_t>0)),max(SIMU.solver_t(SIMU.solver_t>0)));
fprintf('\nAverage and maximal optimization time is: %3.3f, %3.3f\n',...
    mean(SIMU.opti_t(SIMU.opti_t>0)),max(SIMU.opti_t(SIMU.opti_t>0)));

for i = 1:SIMU.loop
    figure(1); hold on;
    plot(j,SIMU.bat_rec(1,:,i)/EPS.bat_max(1),'r',...
         j,SIMU.bat_rec(2,:,i)/EPS.bat_max(2),'b');
end
legend('Battery 1','Battery 2');
hold on;
plot(j,0.3*ones(1,SIMU.step + 1),'g--',j,0.3*ones(1,SIMU.step + 1),'c--');
hold on;
plot(j,ones(1,SIMU.step + 1),'g--',j,ones(1,SIMU.step + 1),'c--');
hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
ylim([0,1 + 50/max(EPS.bat_max)]);

figure(2); 
subplot(2,1,1); hold on;
plot(j,SIMU.conta_HL_rec(1,:,1),'ro--'); ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 1,:,1),'gd--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(4 + EPS.sload_n + 1,:,1),'b*--');
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('HL-LMS contactor advices: Engines to Bus 1');
legend('Engine 1','Engine 2','Engine 3','Location','NorthWest');
subplot(2,1,2); hold on;
plot(j,SIMU.conta_HL_rec(2,:,1),'ro--'); ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2,:,1),'gd--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(4 + EPS.sload_n + 2,:,1),'b*--'); 
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('HL-LMS contactor advices: Engines to Bus 2');
legend('Engine 1','Engine 2','Engine 3','Location','NorthWest');

figure(3); 
subplot(2,1,1); hold on;
plot(j,SIMU.conta_HL_rec(2 + 1,:,1),'r--'); ylim([0,1.5]); 
hold on;
plot(j,SIMU.conta_HL_rec(2 + 2,:,1) - 0.01,'g--'); ylim([0,1.5]); 
hold on;
plot(j,SIMU.conta_HL_rec(2 + 3,:,1) - 0.02,'b--'); ylim([0,1.5]); 
hold on;
plot(j,SIMU.conta_HL_rec(2 + 4,:,1) - 0.03,'c--'); ylim([0,1.5]); 
hold on;
plot(j,SIMU.conta_HL_rec(2 + 5,:,1) - 0.04,'m--'); ylim([0,1.5]); 
hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('HL-LMS contactor advices: Bus 1 to sheddable loads 1 to 5');
legend('Load 1','Load 2','Load 3','Load 4','Load 5','Location','NorthWest');
subplot(2,1,2); hold on;
plot(j,SIMU.conta_HL_rec(2 + 6,:,1),'r--'); ylim([0,1.5]); 
hold on;
plot(j,SIMU.conta_HL_rec(2 + 7,:,1) - 0.01,'g--'); ylim([0,1.5]); 
hold on;
plot(j,SIMU.conta_HL_rec(2 + 8,:,1) - 0.02,'b--'); ylim([0,1.5]); 
hold on;
plot(j,SIMU.conta_HL_rec(2 + 9,:,1) - 0.03,'c--'); ylim([0,1.5]); 
hold on;
plot(j,SIMU.conta_HL_rec(2 + 10,:,1) - 0.04,'m--'); ylim([0,1.5]); 
hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('HL-LMS contactor advices: Bus 1 to sheddable loads 6 to 10');
legend('Load 6','Load 7','Load 8','Load 9','Load 10','Location','NorthWest');

figure(4); 
subplot(2,1,1); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 1,:,1),'r--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 2,:,1) - 0.01,'g--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 3,:,1) - 0.02,'b--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 4,:,1) - 0.03,'c--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 5,:,1) - 0.04,'m--'); 
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('HL-LMS contactor advices: Bus 2 to sheddable loads 1 to 5');
legend('Load 1','Load 2','Load 3','Load 4','Load 5','Location','NorthWest');
subplot(2,1,2); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 6,:,1),'r--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 7,:,1) - 0.01,'g--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 8,:,1) - 0.02,'b--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 9,:,1) - 0.03,'c--'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_HL_rec(2 + EPS.bus1_sload_n + 2 + 10,:,1) - 0.04,'m--'); 
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('HL-LMS contactor advices: Bus 2 to sheddable loads 6 to 10');
legend('Load 6','Load 7','Load 8','Load 9','Load 10','Location','NorthWest');

figure(5); 
subplot(2,1,1); hold on;
plot(j,SIMU.conta_LL_rec(1,:,1),'ro-'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 1,:,1),'gd-'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(4 + EPS.sload_n + 1,:,1),'b*-'); 
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('LL-LMS contactor signals: Engines to Bus 1');
legend('Engine 1','Engine 2','Engine 3','Location','NorthWest');
subplot(2,1,2); hold on;
plot(j,SIMU.conta_LL_rec(2,:,1),'ro-'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2,:,1),'gd-'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(4 + EPS.sload_n + 2,:,1),'b*-'); 
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('LL-LMS contactor signals: Engines to Bus 2');
legend('Engine 1','Engine 2','Engine 3','Location','NorthWest');

figure(6); 
subplot(2,1,1); hold on;
plot(j,SIMU.conta_LL_rec(2 + 1,:,1),'r'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + 2,:,1) - 0.01,'g'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + 3,:,1) - 0.02,'b'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + 4,:,1) - 0.03,'c'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + 5,:,1) - 0.04,'m'); 
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('LL-LMS contactor signals: Bus 1 to sheddable loads 1 to 5');
legend('Load 1','Load 2','Load 3','Load 4','Load 5','Location','NorthWest');
subplot(2,1,2); hold on;
plot(j,SIMU.conta_LL_rec(2 + 6,:,1),'r'); 
hold on;
plot(j,SIMU.conta_LL_rec(2 + 7,:,1) - 0.01,'g'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + 8,:,1) - 0.02,'b'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + 9,:,1) - 0.03,'c'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + 10,:,1) - 0.04,'m'); 
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('LL-LMS contactor signals: Bus 1 to sheddable loads 6 to 10');
legend('Load 6','Load 7','Load 8','Load 9','Load 10','Location','NorthWest');

figure(7); 
subplot(2,1,1); 
hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 1,:,1),'r'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 2,:,1) - 0.01,'g'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 3,:,1) - 0.02,'b'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 4,:,1) - 0.03,'c'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 5,:,1) - 0.04,'m'); 
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('LL-LMS contactor signals: Bus 2 to sheddable loads 1 to 5');
legend('Load 1','Load 2','Load 3','Load 4','Load 5','Location','NorthWest');
subplot(2,1,2); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 6,:,1),'r'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 7,:,1) - 0.01,'g'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 8,:,1) - 0.02,'b'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 9,:,1) - 0.03,'c'); 
ylim([0,1.5]); hold on;
plot(j,SIMU.conta_LL_rec(2 + EPS.bus1_sload_n + 2 + 10,:,1) - 0.04,'m'); 
ylim([0,1.5]); hold on;
plot(34*ones(1,7),0.6:0.1:1.2,'k'); % engine 2 shuts down at 34
hold on;
title('LL-LMS contactor signals: Bus 2 to sheddable loads 6 to 10');
legend('Load 6','Load 7','Load 8','Load 9','Load 10','Location','NorthWest');

figure(77);
% hold on;
% plot(j,min(SIMU.add_cons_t,[],2),'rd',j,min(SIMU.opti_t,[],2),'bs',j,min(SIMU.solver_t,[],2),'g*');
% legend('minimal time of adding constraints','minimal time of optimization','minimal solver time');
hold on;
max_handle = plot(j,max(SIMU.add_cons_t,[],2),'rd',...
    j,max(SIMU.opti_t,[],2),'bd',...
    j,max(SIMU.solver_t,[],2),'gd');
hold on;
avg_handle = plot(j,mean(SIMU.add_cons_t,2),'r*',...
    j,mean(SIMU.opti_t,2),'b*',...
    j,mean(SIMU.solver_t,2),'g*');
legend([max_handle;avg_handle],...
    'maximal time of adding constraints','maximal time of optimization',...
    'maximal solver time','average time of adding constraints',...
    'average time of optimization','average solver time');
title('time spent');

if 1 == SIMU.save
    Time = datestr(now,'yyyy-mm-dd HH-MM-SS');
    save([num2str(Time),'.mat']);
end

rmpath(to_add{1}, to_add{2}, to_add{3}, to_add{4});


