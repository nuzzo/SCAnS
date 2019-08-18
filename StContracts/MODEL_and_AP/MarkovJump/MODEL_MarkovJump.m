% Markovian Jump Linear systems (shortened to MarkovJump) have the form
%
%   x_{k+1} = A_k*x_k + B_k*u_k + zeta_k
%       A_k = A(w_k)
%       B_k = B(w_k)
%    zeta_k = zeta(w_k)
%
%   w_k is a random variable taking values {0, 1, ..., N}. Its transition 
%   is described by a Markov chain. The transition probability matrix P and 
%   the initial probability distribution p_0 of w_0 should be specified in 
%   this script.  
%
% Written by Jiwei Li

global MODEL;
MODEL.type = 'MarkovJump';

% declare cell structures that will automatically expand
%   MODEL.A{1} stores the value of A(w_k) when w_k = 0
%   MODEL.A{N+1} stores the value of A(w_k) when w_k = N
MODEL.A = cell(1);
MODEL.B = cell(1);    
MODEL.zeta = cell(1);

%----------------users can modify the following information----------------

% w_k takes value within {0, 1, ..., N}
MODEL.N = 1;

% MODEL.P(i,j) is the transition probability of w_k from i - 1 to j - 1
MODEL.P = [0.5, 0.5; 0.5, 0.5];

% MODEL.p0 is the initial distribution probability of w_0
MODEL.p0 = [0.5, 0.5];

MODEL.nx = 2;                                  % dimension of x_k
MODEL.nu = 1;                                  % dimension of u_k

MODEL.A{1} = eye(MODEL.nx); % A_k
for i = 1:(MODEL.nx - 1)
    MODEL.A{1}(i, i + 1) = 1;
end

MODEL.A{2} = eye(MODEL.nx);
for i = 1:(MODEL.nx - 1)
    MODEL.A{2}(i, i + 1) = 1;
end

MODEL.B{1} = zeros(MODEL.nx, MODEL.nu); % B_k
MODEL.B{1}(MODEL.nx, :) = ones(1, MODEL.nu);

for l = 1:MODEL.N
    MODEL.B{l + 1} = zeros(MODEL.nx, MODEL.nu);
    MODEL.B{l + 1}(l, :) = ones(1, MODEL.nu);
end

MODEL.zeta{1} = zeros(MODEL.nx,1); % zeta_k
for l = 1:MODEL.N
    MODEL.zeta{l + 1} = zeros(MODEL.nx,1);
end

%----------------check the dimensions----------------

if size(MODEL.P, 1) ~= (MODEL.N + 1)
    error('The row number of MODEL.P must be MODEL.N + 1');
end

if size(MODEL.P, 2) ~= (MODEL.N + 1)
    error('The column number of MODEL.P must be MODEL.N + 1');
end

if size(MODEL.p0, 1) ~= 1
    error('The row number of MODEL.p0 must be 1');
end

if size(MODEL.p0, 2) ~= (MODEL.N + 1)
    error('The column number of MODEL.p0 must be MODEL.N + 1');
end
