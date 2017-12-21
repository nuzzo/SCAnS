function contactor_signal = LL_LMS(input_args)
%LL_LMS low level load management system, tries to follow the advice given 
%   by HL-LMS if conditions are satisfied. It mainly checks two conditions:
%       1. Engines used by high level LMS are in good health condition.
%       2. Battery level is above 25%. 
%   If above conditions are met, then HL advice is used. Else, it revokes
%   LL_LMS_shed() to determine the contactor control signal. Note that 
%   different from LL_LMS(), LL_LMS_shed() does not consider the HL advice,
%   but evaluates last-cycle contactor signal in a conservative perspective. 
%   LL_LMS_shed() begins shedding if this last-cycle signal consumed more 
%   power than engine generated, or engine health changes.
%
% From top to bottom, the input_args contains: 
%   1. advice, from the high level load management system (HL_LMS)
%   2. sensor (see variable_note.m), as a collection of:
%       engine health and power
%       contactor health and on/off state
%       power consumption of each load
%       battery input power and level
%   3. time_stamp_HL, time stamp of advice
%   4. t, current time
%
% Written by Jiwei Li

% pause

global EPS SIMU SMPC;

% check validity of input_args
in_para_dim = EPS.engine_sload_conta_n + 1 + EPS.sensor_n + 1;
if size(input_args,1) ~= in_para_dim
    error('Invalid input dimension of function LL_LMS()!');
end
time_stamp_HL = input_args(EPS.engine_sload_conta_n + 1,1); % time stamp from HL_LMS
t = input_args(in_para_dim,1);                 % actual sample time
if time_stamp_HL ~= t
    error('Inconsistent time!');
end

% retrive information from input_args, see variable_note.txt
advice = input_args(1:EPS.engine_sload_conta_n,1);
SIMU.conta_HL_rec(:,t + 1,SIMU.LT) = advice;
fprintf('In LL_LMS(), time = %3.0f\n',t);
% HL advice for engine, bus 1, and bus 2
advice_delta =...
    [advice(1:2);...
     advice((2 + EPS.bus1_sload_n + 1):(2 + EPS.bus1_sload_n + 2));...
     advice((4 + EPS.sload_n + 1):(4 + EPS.sload_n + 2))];
advice_bus = cell(1,2);
advice_nsload_bus1 = ones(EPS.bus1_nsload_n,1);
advice_bus{1} = ...
    [advice((2 + 1):(2 + EPS.bus1_sload_n));...
     advice_nsload_bus1];
advice_nsload_bus2 = ones(EPS.bus2_nsload_n,1);
advice_bus{2} = ...
    [advice((4 + EPS.bus1_sload_n + 1):(4 + EPS.bus1_sload_n + EPS.bus2_sload_n));...
     advice_nsload_bus2];
% system output information from sensors
sensor = input_args((EPS.engine_sload_conta_n + 2):(EPS.engine_sload_conta_n + EPS.sensor_n + 1),1);
engine_health = sensor(1:EPS.engine_n,1);
EPS.engine_rec(:,t + 1,SIMU.LT) = sensor((EPS.engine_n + 1):(2*EPS.engine_n),1);
% load_bus = cell(1,2);
% load_bus{1} = sensor((2*EPS.engine_n + 2*EPS.engine_sload_conta_n + 1):...
%                      (2*EPS.engine_n + 2*EPS.engine_sload_conta_n + EPS.bus1_load_n));
% load_bus{2} = ...
%     sensor((2*EPS.engine_n + 2*EPS.engine_sload_conta_n + EPS.bus1_load_n + 1):...
%            (2*EPS.engine_n + 2*EPS.engine_sload_conta_n + EPS.bus1_load_n + EPS.load_n));
bat_input = ...
    sensor((EPS.sensor_n - 2*EPS.bat_n + 1):(EPS.sensor_n - EPS.bat_n),1);
bat_level = sensor((EPS.sensor_n - EPS.bat_n + 1):EPS.sensor_n,1);
SIMU.bat_rec(:,t + 1,SIMU.LT) = bat_level;
fprintf('\tcurrent battery level is (%6.3f,%6.3f), last-cycle battery input power is (%6.3f,%6.3f).\n',...
    bat_level(1),bat_level(2),bat_input(1),bat_input(2));

%-----------------------------check safety---------------------------------
% Check the following:
%     1. connection: if each bus is connected to a healthy engine.
%     2. battery level: if each battery level is above 5%.
% If there is any violation, then LL_LMS begins its sheding. Else, the advise 
% from the HL_LMS is used.

unsafe_flag = 0;

engine_to_bus = zeros(EPS.engine_n,2); % row - engine, column - bus
for i = 1:EPS.engine_n
    engine_to_bus(i,:) = advice_delta(((i - 1)*2 + 1):(i*2))';
    if all(engine_to_bus(i,:) > 0) 
       % One engine is connected to both buses, which is probable but brings
       % complication in determining the power distribution among buses,
       % and whether batteries are in state of charging or discharging.
        error('Currently we do not handle the case one engine connected to multiple buses.');
    end
end

for bus = 1:2
    engine = find(engine_to_bus(:,bus));
    if isempty(engine)
        unsafe_flag = 1;
        fprintf('\tBus %1.0f has no engine to supply power under HL advice!\n',bus);
        break;
    elseif ~isscalar(engine)
        unsafe_flag = 2;
        fprintf(['\tBus %1.0f is connected to multiple engines (',num2str(engine'),') under HL advice!\n'],bus);
        break;
    end
    if engine_health(engine) == 0
        unsafe_flag = 3;
        fprintf('\tBus %1.0f is connected to unhealthy Engine %1.0f under HL advice!\n',bus,engine);
        break;
    end
    
    if bat_level(bus) < 0.25*EPS.bat_max(bus);
        unsafe_flag = 4;
        fprintf('\tBattery %1.0f is less than 25%%!\n',bus);
        break;
    end
end

if unsafe_flag ~= 0 && unsafe_flag ~= 4
    fprintf('\t***HL advice is unsafe! LL-LMS calls LL_LMS_shed().\n');
    contactor_signal = LL_LMS_shed(sensor,advice_delta,advice_bus);
elseif unsafe_flag == 4
    fprintf('\t***Battery %1.0f < 25%%! LL-LMS calls LL_LMS_shed().\n',bus);
    contactor_signal = LL_LMS_shed(sensor,advice_delta,advice_bus);
else
    fprintf('\t***No critical problem found. LL-LMS uses advice from HL_SMPC.\n');
    contactor_signal = advice;
end

SIMU.conta_LL_rec(:,t + 1,SIMU.LT) = contactor_signal;

% most recent delta state
SMPC.last_delta = ...
    [contactor_signal(1);
     contactor_signal(13);
     contactor_signal(25);
     contactor_signal(2);
     contactor_signal(14);
     contactor_signal(26)];

% most recent c state
SMPC.last_c = ...
    [contactor_signal(3:12);
     ones(10,1);
     contactor_signal(15:24);
     ones(10,1)];
end

