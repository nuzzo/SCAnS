% The parameters of the EPS.
%
% Written by Jiwei Li

global EPS;

EPS.LL_sample_t = 1;
EPS.HL_sample_t = 10;

EPS.engine_n = 3;
% EPS.engine_max = [100;100;90]; % kW
EPS.engine_max = [100;100;85]; % kW
EPS.engine_conta_n = 2*EPS.engine_n;

EPS.bus_n = 2;
EPS.bus1_sload_n = 10;
EPS.bus2_sload_n = EPS.bus1_sload_n;
EPS.bus1_nsload_n = 10;
EPS.bus2_nsload_n = EPS.bus1_nsload_n;
EPS.sload_n = EPS.bus1_sload_n + EPS.bus2_sload_n;
EPS.nsload_n = EPS.bus1_nsload_n + EPS.bus2_nsload_n;
EPS.load_n = EPS.nsload_n + EPS.sload_n;

EPS.bat_n = 2;
EPS.bat_max = [200;200];
EPS.bat_init = [45,45];
% EPS.bat_init = [10,10];

EPS.engine_sload_conta_n = EPS.engine_conta_n + EPS.sload_n;
EPS.conta_h_prob = ones(EPS.engine_sload_conta_n,1);
EPS.sensor_n = ...
    2*EPS.engine_n...  % engine health, engine power
    + 2*EPS.engine_sload_conta_n... % contactor health, contactor power
    + EPS.load_n...    % power consume of loads
    + 2*EPS.bat_n;   % battery input, battery electricity

EPS.shed_prior_table_bus1 = ...
    [1:10;... % engine 1 to 10 sheddable loads on bus 1
     1:10;... % engine 2 to 10 sheddable loads on bus 1
     1:10];   % engine 3 to 10 sheddable loads on bus 1
EPS.shed_prior_table_bus2 = ...
    [1:10;... % engine 1 to 10 sheddable loads on bus 2
     1:10;... % engine 2 to 10 sheddable loads on bus 2
     1:10];   % engine 3 to 10 sheddable loads on bus 2              
EPS.engine_to_bus1_prior_table = [1 3 2]; % first choice comes first
EPS.engine_to_bus2_prior_table = [2 3 1];

EPS.engine_h = ...
    [ones(1,100 + 1);...                                   % engine 1 over time
     ones(1,floor(100/3) + 1),zeros(1,100 - floor(100/3)); % engine 2 over time
     ones(1,100 + 1)];                                     % engine 3 over time
EPS.bus1_load_avg = ...
    [1;5;2;2;1;5;1;2;2;2;...  % Bus1, sheddable
     5;1;1;2;1;1;45;5;8;0.5]; % Bus1, non-sheddable
EPS.bus2_load_avg = ...
    [1;2;2;5;1;4;1;3;2;2;...      % Bus2, sheddable
     4;1;1;2;11;1.5;2;39;10;0.5]; % Bus2, non-sheddable
EPS.load_avg = [EPS.bus1_load_avg;EPS.bus2_load_avg];
EPS.bus1_load_dev = 0.1*EPS.bus1_load_avg;
EPS.bus2_load_dev = 0.1*EPS.bus2_load_avg;
EPS.load_dev = [EPS.bus1_load_dev;EPS.bus2_load_dev];

