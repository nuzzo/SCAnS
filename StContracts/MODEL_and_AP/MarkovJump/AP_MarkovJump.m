% Atomic propositions (APs) of Markovian Jump Linear Systems have the form
%
%   Pr{a_i'*x_k + b_i'*u_k + c_i <= 0} >= p_i,	i = 1,...,N
% 
% Written by Jiwei Li

global AP;

if exist('MODEL','var') ~= 1 || strcmp(MODEL.type,'MarkovJump') == 0
    error('MODEL should be defined first by calling MODEL_MarkovJump.m!');
end

% declare cell structures that will automatically expand
AP.a = cell(1);
AP.b = cell(1);
AP.c = cell(1);
AP.p = cell(1);

%--------------users can modify the following information-------------
AP.N = 5;                   % number of APs

% 1st constraint: -[1,0,..,0]x + 1 <= 0
AP.a{1} = zeros(MODEL.nx,1);
AP.a{1}(1,1) = -1;
AP.b{1} = zeros(MODEL.nu,1);
AP.c{1} = 1;
AP.p{1} = 1;

% 2nd constraint: [1,0,..,0]x - 2 <= 0
AP.a{2} = zeros(MODEL.nx,1);
AP.a{2}(1,1) = 1;
AP.b{2} = zeros(MODEL.nu,1);
AP.c{2} = -2;
AP.p{2} = 1;

% 3rd constraint: P{[1,0,..,0]x - 1 <= 0} >= 0.7
AP.a{3} = zeros(MODEL.nx,1);
AP.a{3}(1,1) = 1;
AP.b{3} = zeros(MODEL.nu,1);
AP.c{3} = -1;
AP.p{3} = 0.7;

% 4th constraint: [1,0,..,0]x - 3 <= 0
AP.a{4} = zeros(MODEL.nx,1);
AP.a{4}(1,1) = 1;
AP.b{4} = zeros(MODEL.nu,1);
AP.c{4} = -3;
AP.p{4} = 1;

% 5th constraint: P{[1,0,..,0]x - 2 <= 0} >= 0.3
AP.a{5} = zeros(MODEL.nx,1);
AP.a{5}(1,1) = 1;
AP.b{5} = 0;
AP.c{5} = -2;
AP.p{5} = 0.3;

