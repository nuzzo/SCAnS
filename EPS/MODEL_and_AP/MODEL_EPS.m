% Electric Power System (EPS) for control and analysis has the form
%
% x_{k+1} = A*x_k + B_k u_k:
%  x_k = [B_1(k);B_2(k)];          % 2 battery levels
%  u_k = [delta11;delta21;delta31; % contactor states: 3 engines to bus 1
%         delta12;delta22;delta32; % contactor states: 3 engines to bus 2
%         P11;P21;P31;             %            power: 3 engines to bus 1
%         P12;P22;P32;             %            power: 3 engines to bus 2
%         h1;h2;h3                 %    engine health: 3 engines
%         c1_1;...;c1_20;          % contactor states: bus 1 to 20 loads
%         c2_1;...;c2_20;]         % contactor states: bus 2 to 20 loads
%    A = [1,0;0,1]
%  B_k = [0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,-L1_1(k),...,-L1_20(k),0_{1*20};...
%         0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0_{1*20},-L2_1(k),...,-L2_20(k)];
%      = B{1} + \sum_{i=2}^41 B{i}*L{i}(k)
% where L{i}(k) is the power demand of load i at time k, which follows a
% Gaussian distribution.
%
% Written by Jiwei Li

global MODEL;
MODEL.type = 'EPS';

% declare cell structures that will automatically expand
MODEL.B = cell(1);    
MODEL.zeta = cell(1);

%--------------------------system parameters of EPS------------------------

run EPS_config;                 % load settings of EPS and use some of them

MODEL.Nb = EPS.bus_n;                     % 2 buses
MODEL.Ns = EPS.engine_n;                  % 3 sources (engines)
MODEL.N_sl = EPS.bus1_sload_n;            % 10 sheddable loads on each bus
MODEL.N_nsl = EPS.bus1_nsload_n;          % 10 non-sheddable loads on each bus
MODEL.bat_max = EPS.bat_max;
MODEL.engine_max = EPS.engine_max;

MODEL.nx = 2;                     % 2 battery levels as system states
MODEL.A = eye(2);                 
MODEL.nu = 55;                    % see the definition of u_k above
MODEL.H = 40;                     % 40 loads in total (20 sheddable, 20 non-sheddable)
MODEL.B{1} = zeros(2,MODEL.nu);
MODEL.B{1}(1,7:1:9) = 1;
MODEL.B{1}(2,10:1:12) = 1;
for i = 1:20
    MODEL.B{i + 1} = zeros(2,MODEL.nu);
    MODEL.B{i + 1}(1,15 + i) = -1;
    MODEL.B{i + 21} = zeros(2,MODEL.nu);
    MODEL.B{i + 21}(2,35 + i) = -1;
end
for i = 1:(MODEL.H + 1)
    MODEL.zeta{i} = zeros(2,1);
end
MODEL.load_avg = EPS.load_avg;
MODEL.load_dev = EPS.load_dev;

