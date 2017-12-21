% Linear systems with control-dependent and additive Gaussian noise (shorten to GaussLin) have the form
%
%   x_{k+1} = A*x_k + B_k*u_k + zeta_k
%       B_k = B{1} + B{2}*w_{k,1} + ... + B{1 + N}*w_{k,N}
%    zeta_k = zeta{1} + zeta{2}*w_{k,1} + ... + zeta{1 + N}*w_{k,N}
%       w_k = [w_{k,1}, ... , w_{k,N}]^T
%       w_k is mutually independent and follows N(w_bar,Theta)
%
% Written by Jiwei Li

global MODEL;
MODEL.type = 'GaussLin';

% declare cell structures that will automatically expand
MODEL.B = cell(1);    
MODEL.zeta = cell(1);

%--------------users can modify the following information-------------

MODEL.nx = 2; % dimension of x_k
MODEL.nu = 2; % dimension of u_k

MODEL.A = eye(MODEL.nx); % A_k
for i = 1:(MODEL.nx - 1)
    MODEL.A(i, i + 1) = 1;
end

MODEL.B{1} = zeros(MODEL.nx, MODEL.nu); % B_k
MODEL.B{1}(MODEL.nx, :) = ones(1, MODEL.nu);

MODEL.N = MODEL.nx; % [w_{k,1}, ... , w_{k,N}]
for l = 1:MODEL.N
    MODEL.B{l + 1} = zeros(MODEL.nx, MODEL.nu);
    MODEL.B{l + 1}(l, :) = ones(1, MODEL.nu);
end

MODEL.zeta{1} = zeros(MODEL.nx,1); % zeta_k
for l = 1:MODEL.N
    MODEL.zeta{l + 1} = zeros(MODEL.nx,1);
end

% w_k follows N(w_bar,Theta)
MODEL.w_bar = zeros(MODEL.N,1); % mean of w_k
MODEL.Theta = 1*eye(MODEL.N); % covariance matrix of w_k

