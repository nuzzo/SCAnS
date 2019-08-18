% Atomic propositions (APs) of EPS have the form
%
%   Pr{a_i'*x + b_i'*u + c_i <= 0} >= p_i, i = 1,...,N
% 
% where x and u are described in MODEL_EPS.m
% Written by Jiwei Li

global AP MODEL;

% declare cell structures that will automatically expand
AP.a = cell(1);
AP.b = cell(1);
AP.c = cell(1);
AP.p = cell(1);

%--------------------------------APs for EPS-------------------------------
AP.N = 16;                   % number of APs
small_num = 0.001;           % a sufficient small positive number
large_num = 10000;           % a sufficient large positive number

% 1st constraint: Pr{-B_1(k) + 0.3*MODEL.bat_max(1) <= 0} >= 0.95
AP.a{1} = [-1;0];
AP.b{1} = zeros(MODEL.nu,1);
AP.c{1} = 0.3*MODEL.bat_max(1);
AP.p{1} = 0.95;

% 2nd constraint: Pr{-B_2(k) + 0.3*MODEL.bat_max(2) <= 0} >= 0.95
AP.a{2} = [0;-1];
AP.b{2} = zeros(MODEL.nu,1);
AP.c{2} = 0.3*MODEL.bat_max(2);
AP.p{2} = 0.95;

% 3rd constraint: B_1(k) - 0.25*MODEL.bat_max(1) <= 0
AP.a{3} = [1;0];
AP.b{3} = zeros(MODEL.nu,1);
AP.c{3} = -0.25*MODEL.bat_max(1);
AP.p{3} = 1;

% 4th constraint: B_2(k) - 0.25*MODEL.bat_max(2) <= 0
AP.a{4} = [0;1];
AP.b{4} = zeros(MODEL.nu,1);
AP.c{4} = -0.25*MODEL.bat_max(2);
AP.p{4} = 1;

% 5th constraint: Pr{-B_1(k) + 0.4*MODEL.bat_max(1) <= 0} >= 0.95
AP.a{5} = [-1;0];
AP.b{5} = zeros(MODEL.nu,1);
AP.c{5} = 0.4*MODEL.bat_max(1);
AP.p{5} = 0.95;

% 6th constraint: Pr{-B_2(k) + 0.4*MODEL.bat_max(2) <= 0} >= 0.95
AP.a{6} = [0;-1];
AP.b{6} = zeros(MODEL.nu,1);
AP.c{6} = 0.4*MODEL.bat_max(2);
AP.p{6} = 0.95;

% engine power >0 <-> delta = 1
% ensured by:
% SMPC.u{1}(1)*small_num - SMPC.u{1}(7) <= 0,
% SMPC.u{1}(2)*small_num - SMPC.u{1}(8) <= 0,
% SMPC.u{1}(3)*small_num - SMPC.u{1}(9) <= 0,
% SMPC.u{1}(4)*small_num - SMPC.u{1}(10) <= 0,
% SMPC.u{1}(5)*small_num - SMPC.u{1}(11) <= 0,
% SMPC.u{1}(6)*small_num - SMPC.u{1}(12) <= 0,
% SMPC.u{1}(7) - SMPC.u{1}(1)*M <= 0,
% SMPC.u{1}(8) - SMPC.u{1}(2)*M <= 0,
% SMPC.u{1}(9) - SMPC.u{1}(3)*M <= 0,
% SMPC.u{1}(10) - SMPC.u{1}(4)*M <= 0,
% SMPC.u{1}(11) - SMPC.u{1}(5)*M <= 0,
% SMPC.u{1}(12) - SMPC.u{1}(6)*M <= 0,
AP.a{7} = zeros(2,12);
AP.b{7} = zeros(MODEL.nu,12);
AP.c{7} = zeros(12,1);
AP.p{7} = 1;
AP.b{7}(1,1) = small_num; AP.b{7}(7,1) = -1;
AP.b{7}(2,2) = small_num; AP.b{7}(8,2) = -1;
AP.b{7}(3,3) = small_num; AP.b{7}(9,3) = -1;
AP.b{7}(4,4) = small_num; AP.b{7}(10,4) = -1;
AP.b{7}(5,5) = small_num; AP.b{7}(11,5) = -1;
AP.b{7}(6,6) = small_num; AP.b{7}(12,6) = -1;
AP.b{7}(1,7) = -large_num; AP.b{7}(7,7) = 1;
AP.b{7}(2,8) = -large_num; AP.b{7}(8,8) = 1;
AP.b{7}(3,9) = -large_num; AP.b{7}(9,9) = 1;
AP.b{7}(4,10) = -large_num; AP.b{7}(10,10) = 1;
AP.b{7}(5,11) = -large_num; AP.b{7}(11,11) = 1;
AP.b{7}(6,12) = -large_num; AP.b{7}(12,12) = 1;

% one engine is connected to one bus at most
% ensured by:
% SMPC.u{1}(1) + SMPC.u{1}(4) - 1 <= 0,
% SMPC.u{1}(2) + SMPC.u{1}(5) - 1 <= 0,
% SMPC.u{1}(3) + SMPC.u{1}(6) - 1 <= 0,
AP.a{8} = zeros(2,3);
AP.b{8} = zeros(MODEL.nu,3);
AP.c{8} = zeros(3,1);
AP.p{8} = 1;
AP.b{8}(1,1) = 1; AP.b{8}(4,1) = 1; AP.c{8}(1) = -1;
AP.b{8}(2,2) = 1; AP.b{8}(5,2) = 1; AP.c{8}(2) = -1;
AP.b{8}(3,3) = 1; AP.b{8}(6,3) = 1; AP.c{8}(3) = -1;

% power from engine m is always distributed among 2 buses
% ensured by:
% -MODEL.engine_max(1)*(SMPC.u{1}(1) + SMPC.u{1}(4)) 
%     + SMPC.u{1}(7) + SMPC.u{1}(10) <= 0,
% MODEL.engine_max(1)*(SMPC.u{1}(1) + SMPC.u{1}(4)) 
%     - SMPC.u{1}(7) - SMPC.u{1}(10) <= 0,
% -MODEL.engine_max(2)*(SMPC.u{1}(2) + SMPC.u{1}(5)) 
%     + SMPC.u{1}(8) + SMPC.u{1}(11) <= 0,
% MODEL.engine_max(2)*(SMPC.u{1}(2) + SMPC.u{1}(5)) 
%     - SMPC.u{1}(8) - SMPC.u{1}(11) <= 0,
% -MODEL.engine_max(3)*(SMPC.u{1}(3) + SMPC.u{1}(6)) 
%     + SMPC.u{1}(9) + SMPC.u{1}(12) <= 0,
% MODEL.engine_max(3)*(SMPC.u{1}(3) + SMPC.u{1}(6)) 
%     - SMPC.u{1}(9) - SMPC.u{1}(12) <= 0,
AP.a{9} = zeros(2,6);
AP.b{9} = zeros(MODEL.nu,6);
AP.c{9} = zeros(6,1);
AP.p{9} = 1;
AP.b{9}(1,1) = -MODEL.engine_max(1);
AP.b{9}(4,1) = -MODEL.engine_max(1);
AP.b{9}(7,1) = 1;
AP.b{9}(10,1) = 1;
AP.b{9}(1,2) = MODEL.engine_max(1);
AP.b{9}(4,2) = MODEL.engine_max(1);
AP.b{9}(7,2) = -1;
AP.b{9}(10,2) = -1;
AP.b{9}(2,3) = -MODEL.engine_max(2);
AP.b{9}(5,3) = -MODEL.engine_max(2);
AP.b{9}(8,3) = 1;
AP.b{9}(11,3) = 1;
AP.b{9}(2,4) = MODEL.engine_max(2);
AP.b{9}(5,4) = MODEL.engine_max(2);
AP.b{9}(8,4) = -1;
AP.b{9}(11,4) = -1;
AP.b{9}(3,5) = -MODEL.engine_max(3);
AP.b{9}(6,5) = -MODEL.engine_max(3);
AP.b{9}(9,5) = 1;
AP.b{9}(12,5) = 1;
AP.b{9}(3,6) = MODEL.engine_max(3);
AP.b{9}(6,6) = MODEL.engine_max(3);
AP.b{9}(9,6) = -1;
AP.b{9}(12,6) = -1;

% engine power >= 0
%-SMPC.u{1}(1:52) <= 0,
AP.a{10} = zeros(2,MODEL.nu);
AP.b{10} = -eye(MODEL.nu);
AP.c{10} = zeros(MODEL.nu,1);
AP.p{10} = 1;

% unhealthy engine is always disconnected from bus
% SMPC.u{1}(1:3) - SMPC.engine_h <= 0, SMPC.engine_h = SMPC.u{1}(13:15)
% SMPC.u{1}(4:6) - SMPC.engine_h <= 0, SMPC.engine_h = SMPC.u{1}(13:15)
AP.a{11} = zeros(2,6);
AP.b{11} = zeros(MODEL.nu,6);
AP.c{11} = zeros(6,1);
AP.p{11} = 1;
AP.b{11}(1:3,1:3) = eye(3);
AP.b{11}(13:15,1:3) = -eye(3);
AP.b{11}(4:6,4:6) = eye(3);
AP.b{11}(13:15,4:6) = -eye(3);

% bus 1 is connected to one engine
% SMPC.u{1}(1) + SMPC.u{1}(2) + SMPC.u{1}(3) - 1 <= 0,
% -SMPC.u{1}(1) - SMPC.u{1}(2) - SMPC.u{1}(3) + 1 <= 0,
AP.a{12} = zeros(2,2);
AP.b{12} = zeros(MODEL.nu,2);
AP.c{12} = zeros(2,1);
AP.p{12} = 1;
AP.b{12}(1:3,1) = ones(3,1);
AP.c{12}(1) = -1;
AP.b{12}(1:3,2) = -ones(3,1);
AP.c{12}(2) = 1;

% bus 2 is connected to one engine
% SMPC.u{1}(4) + SMPC.u{1}(5) + SMPC.u{1}(6) - 1 <= 0,
% -SMPC.u{1}(4) - SMPC.u{1}(5) - SMPC.u{1}(6) + 1 <= 0,
AP.a{13} = zeros(2,2);
AP.b{13} = zeros(MODEL.nu,2);
AP.c{13} = zeros(2,1);
AP.p{13} = 1;
AP.b{13}(4:6,1) = ones(3,1);
AP.c{13}(1) = -1;
AP.b{13}(4:6,2) = -ones(3,1);
AP.c{13}(2) = 1;

% at least two engines work: sum(engine_health) >= 2
% - SMPC.u{1}(13) - SMPC.u{1}(14) - SMPC.u{1}(15) + 2 <= 0
AP.a{14} = zeros(2,1);
AP.b{14} = zeros(MODEL.nu,1);
AP.c{14} = 2;
AP.p{14} = 1;
AP.b{14}(13:15,1) = -ones(3,1);

% B(k) - 1*MODEL.bat_max <= 0
AP.a{15} = eye(2,2);
AP.b{15} = zeros(MODEL.nu,2);
AP.c{15} = -1*MODEL.bat_max;
AP.p{15} = 1;

% -B(k) + 0.2*MODEL.bat_max <= 0
AP.a{16} = -eye(2,2);
AP.b{16} = zeros(MODEL.nu,2);
AP.c{16} = 0.2*MODEL.bat_max;
AP.p{16} = 1;



