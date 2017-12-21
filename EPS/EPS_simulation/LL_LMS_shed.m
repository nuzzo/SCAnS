function contactor_signal = LL_LMS_shed(sensor,advice_delta,advice_bus)
%LL_LMS_SELECT_CONTACTORS determin contactor on and off by shedding policy.

%   Written by Jiwei Li

global EPS SIMU;

engine_max = zeros(EPS.engine_n,1);
engine_max(1) = EPS.engine_max(1);
engine_max(2) = EPS.engine_max(2);
engine_max(3) = EPS.engine_max(3);
engine_health = sensor(1:EPS.engine_n,1);
bus1_load_n = EPS.bus1_sload_n + EPS.bus1_nsload_n;
bus2_load_n = EPS.bus2_sload_n + EPS.bus2_nsload_n;
eng_sload_c = EPS.engine_sload_conta_n;
bus1_load_meas = ...
    sensor((2*EPS.engine_n + 2*eng_sload_c + 1):...
    (2*EPS.engine_n + 2*eng_sload_c + bus1_load_n));
bus2_load_meas = ...
    sensor((2*EPS.engine_n + 2*eng_sload_c + bus1_load_n + 1):...
    (2*EPS.engine_n + 2*eng_sload_c + bus1_load_n + bus2_load_n));

fprintf('In LL_LMS_shed():\n');

%----------Compute power demand upon each engine under HL advice-----------
bus1_conta = advice_bus{1};
bus2_conta = advice_bus{2};
engine_conta = advice_delta;

bus1_load_esti = max(EPS.bus1_load_avg, bus1_load_meas).*advice_bus{1};
bus2_load_esti = max(EPS.bus2_load_avg, bus2_load_meas).*advice_bus{2};
bus1_power_esti = sum(bus1_load_esti);
bus2_power_esti = sum(bus2_load_esti);

engine_to_bus1 = find(engine_conta(1:2:5) == 1);
engine_to_bus2 = find(engine_conta(2:2:6) == 1);

if ~isempty(engine_to_bus1) && ~isempty(engine_to_bus2)
    engine1_power_req = 0;
    engine2_power_req = 0;
    engine3_power_req = 0;
    if (engine_to_bus1 == 1)
        engine1_power_req = bus1_power_esti;
    elseif (engine_to_bus1 == 2)
        engine2_power_req = bus1_power_esti;
    elseif (engine_to_bus1 == 3)
        engine3_power_req = bus1_power_esti;
    end

    if (engine_to_bus2 == 1)
        engine1_power_req = engine1_power_req + bus2_power_esti;
    elseif (engine_to_bus2 == 2)
        engine2_power_req = engine2_power_req + bus2_power_esti;
    elseif (engine_to_bus2 == 3)
        engine3_power_req = engine3_power_req + bus2_power_esti;
    end

    if engine1_power_req <= engine_max(1) &&...
            engine2_power_req <= engine_max(2) &&...
            engine3_power_req <= engine_max(3) &&...
            engine_health(engine_to_bus1) == 1 &&... % engine for bus 1 is OK
            engine_health(engine_to_bus2) == 1 % engine for bus 2 is OK
        contactor_signal = [engine_conta(1:2,1);bus1_conta(1:EPS.bus1_sload_n);...
            engine_conta(3:4,1);bus2_conta(1:EPS.bus2_sload_n);...
            engine_conta(5:6,1)];
        SIMU.will_consume_battery = zeros(2,1);
        fprintf('\tHL advice is good, battery will be charged.\n')
        return;
    end
end

%-------------------HL advice is not safe. Begin shedding------------------
%----Select engine for each bus----
engine_conta = zeros(EPS.engine_conta_n,1);
% generator selection for Bus 1 
for i = 1:EPS.engine_n
    engine = EPS.engine_to_bus1_prior_table(i);
%     engine
    if engine_health(engine) == 1
        engine_to_bus1 = engine;
        engine_conta((engine - 1)*2 + 1) = 1;
        fprintf('\tEngine %1.0f is connected to Bus %1.0f\n',engine,1);
        break
    end
end

% generator selection for Bus 2
for i = 1:EPS.engine_n
    engine = EPS.engine_to_bus2_prior_table(i);
    if engine_health(engine) == 1
        engine_to_bus2 = engine;
        engine_conta((engine - 1)*2 + 2) = 1;
        fprintf('\tEngine %1.0f is connected to Bus %1.0f\n',engine,2);
        break
    end
end

if engine_to_bus1 == engine_to_bus2
    error('Currently we do not handle the case one engine connected to multiple buses.');
end

%----Compute the power demand upon each engine----
% At the beginning, all loads are assumed to be on the bus.
bus1_load_esti = max(EPS.bus1_load_avg, bus1_load_meas);
bus2_load_esti = max(EPS.bus2_load_avg, bus2_load_meas);
bus1_power_esti = sum(bus1_load_esti);
bus2_power_esti = sum(bus2_load_esti);

engine1_power_req = 0; 
engine2_power_req = 0; 
engine3_power_req = 0;
if (engine_to_bus1 == 1)
    engine1_power_req = bus1_power_esti;
elseif (engine_to_bus1 == 2)
    engine2_power_req = bus1_power_esti;
elseif (engine_to_bus1 == 3)
    engine3_power_req = bus1_power_esti;
end

if (engine_to_bus2 == 1)
    engine1_power_req = engine1_power_req + bus2_power_esti;
elseif (engine_to_bus2 == 2)
    engine2_power_req = engine2_power_req + bus2_power_esti;
elseif (engine_to_bus2 == 3)
    engine3_power_req = engine3_power_req + bus2_power_esti;
end

%----Shed loads on each bus----
bus1_conta = ones(EPS.bus1_sload_n,1);
bus2_conta = ones(EPS.bus2_sload_n,1);

% shed load for engine 1
engine = 1;
bus1_shed_prior = 1;
bus2_shed_prior = 1;
while engine1_power_req >= engine_max(engine)
    if engine_to_bus2 == engine && bus2_shed_prior <= EPS.bus2_sload_n
        % remove sheddable load from bus 2
        sload = EPS.shed_prior_table_bus2(engine,bus2_shed_prior);
        engine1_power_req = engine1_power_req - bus2_load_esti(sload);
        bus2_conta(sload) = 0;
        fprintf(['\tFor Engine %1.0f: sheddable Load %1.0f',...
            ' on Bus %1.0f is shed, power requirement reduced to %6.0f\n'],...
            engine,sload,2,engine1_power_req);
        bus2_shed_prior = bus2_shed_prior + 1;
    elseif engine_to_bus1 == engine && bus1_shed_prior <= EPS.bus1_sload_n
        % remove sheddable load from bus 1
        sload = EPS.shed_prior_table_bus1(engine,bus1_shed_prior);
        engine1_power_req = engine1_power_req - bus1_load_esti(sload);
        bus1_conta(sload) = 0;
        fprintf(['\tFor Engine %1.0f: sheddable Load %1.0f',...
            ' on Bus %1.0f is shed, power requirement reduced to %6.0f\n'],...
            engine,sload,1,engine1_power_req);
        bus1_shed_prior = bus1_shed_prior + 1;
    end
    if (bus1_shed_prior > EPS.bus1_sload_n && bus2_shed_prior > EPS.bus2_sload_n) ||...
       (engine_to_bus2 ~= engine && bus1_shed_prior > EPS.bus1_sload_n) ||...
       (engine_to_bus1 ~= engine && bus2_shed_prior > EPS.bus2_sload_n)
        % all sheddable loads are shed when
        % 1. engine 1 is connected to bus 1 and bus 2
        % 2. engine 1 is only connected to bus 1
        % 3. engine 1 is only connected to bus 2
        if engine1_power_req > engine_max(engine)
            disp(['WARNING in LL_LMS_shed()! Engine 1 may provide',...
                ' insufficient power for unsheddable loads!\n']);
        end
        break;
    end
end

% shed load for engine 2
engine = 2;
bus1_shed_prior = 1;
bus2_shed_prior = 1;
while engine2_power_req >= engine_max(engine)
    if engine_to_bus1 == engine && bus1_shed_prior <= EPS.bus1_sload_n
        % remove sheddable load from bus 1
        sload = EPS.shed_prior_table_bus1(engine,bus1_shed_prior);
        engine2_power_req = engine2_power_req - bus1_load_esti(sload);
        bus1_conta(sload) = 0;
        fprintf(['\tFor Engine %1.0f: sheddable Load %1.0f',...
            ' on Bus %1.0f is shed, power requirement reduced to %6.0f\n'],...
            engine,sload,1,engine2_power_req);
        bus1_shed_prior = bus1_shed_prior + 1;
    elseif engine_to_bus2 == engine && bus2_shed_prior <= EPS.bus2_sload_n
        % remove sheddable load from bus 2
        sload = EPS.shed_prior_table_bus2(engine,bus2_shed_prior);
        engine2_power_req = engine2_power_req - bus2_load_esti(sload);
        bus2_conta(sload) = 0;
        fprintf(['\tFor Engine %1.0f: sheddable Load %1.0f',...
            ' on Bus %1.0f is shed, power requirement reduced to %6.0f\n'],...
            engine,sload,2,engine2_power_req);
        bus2_shed_prior = bus2_shed_prior + 1;
    end
    if (bus1_shed_prior > EPS.bus1_sload_n && bus2_shed_prior > EPS.bus2_sload_n) ||...
       (engine_to_bus2 ~= engine && bus1_shed_prior > EPS.bus1_sload_n) ||...
       (engine_to_bus1 ~= engine && bus2_shed_prior > EPS.bus2_sload_n)
        % all sheddable loads are shed when
        % 1. engine 2 is connected to bus 1 and bus 2
        % 2. engine 2 is only connected to bus 1
        % 3. engine 2 is only connected to bus 2
        if engine2_power_req > engine_max(engine)
            disp(['WARNING in LL_LMS_shed()! Engine 2 may provide',...
                ' insufficient power for unsheddable loads!\n']);
        end
        break;
    end
end

% shed load for engine 3
engine = 3;
bus1_shed_prior = 1;
bus2_shed_prior = 1;
while engine3_power_req >= engine_max(engine)
    if engine_to_bus1 == engine && bus1_shed_prior <= EPS.bus1_sload_n
        % remove sheddable load from bus 1
        sload = EPS.shed_prior_table_bus1(engine,bus1_shed_prior);
        engine3_power_req = engine3_power_req - bus1_load_esti(sload);
        bus1_conta(sload) = 0;
        fprintf(['\tFor Engine %1.0f: sheddable Load %1.0f',...
            ' on Bus %1.0f is shed, power requirement reduced to %6.0f\n'],...
            engine,sload,1,engine3_power_req);
        bus1_shed_prior = bus1_shed_prior + 1;
    elseif engine_to_bus2 == engine && bus2_shed_prior <= EPS.bus2_sload_n
        % remove sheddable load from bus 2
        sload = EPS.shed_prior_table_bus2(engine,bus2_shed_prior);
        engine3_power_req = engine3_power_req - bus2_load_esti(sload);
        bus2_conta(sload) = 0;
        fprintf(['\tFor Engine %1.0f: sheddable Load %1.0f',...
            ' on Bus %1.0f is shed, power requirement reduced to %6.0f\n'],...
            engine,sload,2,engine3_power_req);
        bus2_shed_prior = bus2_shed_prior + 1;
    end
    if (bus1_shed_prior > EPS.bus1_sload_n && bus2_shed_prior > EPS.bus2_sload_n) ||...
       (engine_to_bus2 ~= engine && bus1_shed_prior > EPS.bus1_sload_n) ||...
       (engine_to_bus1 ~= engine && bus2_shed_prior > EPS.bus2_sload_n)
        % all sheddable loads are shed when
        % 1. engine 3 is connected to bus 1 and bus 2
        % 2. engine 3 is only connected to bus 1
        % 3. engine 3 is only connected to bus 2
        if engine3_power_req > engine_max(engine)
            disp(['WARNING in LL_LMS_shed()! Engine 3 may provide',...
                ' insufficient power for unsheddable loads!\n']);
        end
        break;
    end
end

contactor_signal = [engine_conta(1:2,1);bus1_conta;engine_conta(3:4,1);bus2_conta;engine_conta(5:6,1)];
% contactor_signal
% engine_conta
end

