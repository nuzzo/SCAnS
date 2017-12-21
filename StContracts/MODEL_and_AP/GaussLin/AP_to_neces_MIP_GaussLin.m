function add_result = AP_to_neces_MIP_GaussLin(AP_tag,k,formu_index,neg_prefix)
% AP_TO_NECES_MIP_LSCAG Translate an atomic proposition (AP) into necessary MILP
% input: AP_tag - an integer (1,2,...) to index a particular AP
%        k      - the satisfaction time (0,1,2,...) of that AP
%        formu_index - the index of this AP stored in the StSTL encoding 
%                      quadruple (formu_str, formu_time, formu_neg, formu_bin)
%        neg_prefix  - a boolean value indicating whether this is a negation
%                      of AP or not
% Written by Jiwei Li

global StSTL MODEL SMPC AP contract_checking;

M = StSTL.large_num;
epsl = StSTL.small_num;
% epsl = 0.01;
A = MODEL.A;
B = MODEL.B;
nu = MODEL.nu;
zeta = MODEL.zeta;
N = MODEL.N;
Theta = MODEL.Theta;
w_bar = MODEL.w_bar;

cons_index = floor(str2double(AP_tag));
if isempty(cons_index)
    error('Invalid AP_tag: non-number elements inside.');
end
if ~isscalar(cons_index)
    error('Invalid AP_tag: multiple numbers inside.');
end
if cons_index < 0 || cons_index > AP.N
    error(['cons_index = ',num2str(cons_index),' is beyond the boundary']);
end

%-----------------------------define variables-----------------------------

% u in horizon [0,StSTL.unrolled] has been defined
for t = (StSTL.unrolled + 1):1:k % t is the 'real' time, just like k
    SMPC.u{t + 1} = sdpvar(MODEL.nu,1);
    if t == 0 && contract_checking == 1
        SMPC.x0 = sdpvar(MODEL.nx,1); % x0 is a variable here
    end
end
if StSTL.unrolled < k
    StSTL.unrolled = k;
end

%-------------------------------ensure AP----------------------------------
if ~isscalar(AP.p{cons_index})
    error(['Invalid p of AP ', num2str(cons_index), ': should be a scalar.']);
end
if AP.p{cons_index} > 1
    error(['Invalid p of AP ', num2str(cons_index), ': cannot be larger than 1.']);
end

less_than_0 = 0;
if neg_prefix == 1
    % Because Not( Pr{\mu <= 0} >= p ) <--> Pr{\mu <= 0} < p. When p is  
    % non-positive, this proposition must be false, we directly return.
    if AP.p{cons_index} <= 0
        StSTL.formu_bin{formu_index} = 0;
        add_result = formu_index;
        return; 
    elseif AP.p{cons_index} > 0 && AP.p{cons_index} < 1
        % Not(Pr{\mu <= 0} >= p) is equivalent to 
        %       Pr{-\mu < 0} > 1 - p.
        % This is equivalent to
        %       lam1 + F_inv(1 - p)*lam2 < 0  (hence less_than_0 = 1)
        % where lam1 is the mean of -\mu and lam2 is the variance of -\mu.
        %
        % Another option is to formulate the necessary condition, i.e.,
        % Not(Pr{\mu <= 0} >= p) is sufficient to      
        %       Pr{-\mu <= 0} >= 1 - p.
        % This is equivalent to
        %       lam1 + F_inv(1 - p)*lam2 <= 0.  (hence less_than_0 = 0)
        %
        % Attention!!! It is ideal for the necessary encoding to ensure that
        %       And( Not( (Pr{x <= 0} >= 1) ), (Pr{x <= 0} >= 1) )
        % is false. This is not so easy to achieve, because the 
        % necessary encoding enlarges solution spaces of both 
        % Not( (Pr{x <= 0} >= 1) ) and (Pr{x <= 0} >= 1), and there is 
        % often (almost inevitably) overlap between the expanded spaces.
        
        less_than_0 = 1;
        a = -AP.a{cons_index};
        b = -AP.b{cons_index};
        c = -AP.c{cons_index};
        p = 1 - AP.p{cons_index};
    elseif AP.p{cons_index} == 1
        % Not(Pr{\mu <= 0} >= 1) is equivalent to Pr{-\mu < 0} > 0. 
        % To avoid icdf(0) = -inf, we have to use
        %       Pr{-\mu < 0} >= epsl,
        % where epsl is sufficiently small. This is equivalent to
        %       lam1 + F_inv(epsl)*lam2 < 0
        less_than_0 = 1;
        a = -AP.a{cons_index};
        b = -AP.b{cons_index};
        c = -AP.c{cons_index};
        p = 0.00001;
    end
else
    if AP.p{cons_index} <= 0
        % the chance constraint is trivally true
        StSTL.formu_bin{formu_index} = 1;
        add_result = formu_index;
        return;
    end
    less_than_0 = 0;
    a = AP.a{cons_index};
    b = AP.b{cons_index};
    c = AP.c{cons_index};
    p = AP.p{cons_index};
end

% a
% b
% c
% p

% the chance constraint is formulated as: 
%       lam1 + F_inv*lam2 <= (<) 0
% where lam1 is the deterministic part, and lam2 is the random part

lam1 = a'*A^k*SMPC.x0 + b'*SMPC.u{k+1} + c;

for t = 1:k
    lam1 = lam1 + a'*A^(k - t)*(zeta{1} + B{1}*SMPC.u{t});
    for l = 1:N
        lam1 = lam1 + a'*A^(k - t)*(zeta{1 + l} + B{1 + l}*SMPC.u{t})*w_bar(l);
    end
end

lam2_u = 0;
lam2_l = 0;
if k >= 1
    Lambda_11 = zeros(k*nu, k*nu);
    Lambda_12 = zeros(k*nu, 1);
    Lambda_22 = 0;
    u_vec = sdpvar(k*nu, 1);
    for t = (k - 1):(-1):0
        alpha_t = 0;
        beta_t = 0;
        t1 = t + 1;             % t_1 decreases from k to 1
        for l1 = 1:N
            for l2 = 1:N
                alpha_t = alpha_t + B{l1 + 1}'*(A^t)'*(a*a')*A^t*B{l2 + 1}*Theta(l1,l2);
                beta_t = beta_t + a'*A^t*zeta{1 + l1}*a'*A^t*B{l2 + 1}*Theta(l1,l2);
                Lambda_22 = Lambda_22 ...
                    + a'*A^(k - t1)*zeta{1 + l1}*a'*A^(k - t1)*zeta{1 + l2}*Theta(l1,l2);
            end
        end
        Lambda_11( (t*nu + 1):((t + 1)*nu), (t*nu + 1):((t + 1)*nu) ) = alpha_t;
        Lambda_12( (t*nu + 1):((t + 1)*nu), 1 ) = beta_t;
        t_incr = k - 1 - t;     % t_incr increases from 0 to k - 1
        u_vec( (t_incr*nu + 1):((t_incr + 1)*nu), 1 ) = SMPC.u{t_incr + 1};
    end
    Lambda = [Lambda_11, Lambda_12; Lambda_12', Lambda_22];
    if norm(Lambda,2) < 10^(-6)
        lam2_u = 0;
        lam2_l = 0;
        fprintf(StSTL.fid, '***Lambda_{k-1} is very close to 0, with its 2 norm being %2.10f, so we set lam2_u = 0.\n', norm(Lambda,2));
    else
        % lam2 = norm( sqrtm(Lambda)*[u_vec;1], 2 );
        % Lambda_sqrt = sqrt(Lambda);
        [U,S,V] = svd(Lambda);
        posi_eigen_num = 0; % positive eigenvalue number
        for n = 1:(k*nu + 1)
            if S(n,n) < 10^(-6)
                break;
            end
            posi_eigen_num = posi_eigen_num + 1;
        end
        if posi_eigen_num == 0
            error('Lambda should have at least one positive eigenvalue!');
        end
        fprintf(StSTL.fid, ['In AP_to_neces_MIP_GaussLin(): posi_eigen_num = ', num2str(posi_eigen_num), '\n']);
        Lambda_sqrt_simp = sqrtm(S(1:posi_eigen_num, 1:posi_eigen_num))*(V(:, 1:posi_eigen_num))';
        if norm(Lambda_sqrt_simp'*Lambda_sqrt_simp - Lambda, 2) > 10^(-6)
            eval('Lambda');
            eval('U');
            eval('S');
            eval('V');
            eval('U - V')
            error('Lambda_sqrt_simp wrong!');
        end
        % Lambda_sqrt_simp
        I = eye(posi_eigen_num);
        for j = 1:posi_eigen_num
            e_j = I(:, j);
            lam2_u = lam2_u + abs(e_j'*Lambda_sqrt_simp*[u_vec;1]);
        end
        lam2_l = 1/sqrtm(posi_eigen_num)*lam2_u;
    end
end

if p > 0 && p < 1
    if k > 0
        F_inv = icdf('normal',p,0,1);
    else
        F_inv = 0;
    end
elseif p == 1 
    % Because the system state is Gaussian distributed, p == 0 or 1 leads
    % F_inv to be -Inf or Inf. However, p == 1 is allowed if lam2_u == 0.
    if lam2_u ~= 0
        error(['Invalid p = ', num2str(p) ,': cannot be 1.']);
    end
    F_inv = 0;
else
    eval('p');
    error('Invalid p: cannot be larger than 1 or negative.');
end
% neg_prefix
% less_than_0 = 0;

if F_inv >= 0 % p >= 0.5
    if less_than_0 == 0
        % lam1 + F_inv*lam2 <= 0
        StSTL.MIP_cons = [StSTL.MIP_cons,...
            lam1 + F_inv*lam2_l + (StSTL.formu_bin{formu_index} - 1)*M <= 0];
        StSTL.MIP_cons = [StSTL.MIP_cons,...
            lam1 + F_inv*lam2_l + StSTL.formu_bin{formu_index}*M >= epsl];
    else
        % lam1 + F_inv*lam2 < 0
        StSTL.MIP_cons = [StSTL.MIP_cons,...
            lam1 + F_inv*lam2_l + (StSTL.formu_bin{formu_index} - 1)*M <= -epsl];
        StSTL.MIP_cons = [StSTL.MIP_cons,...
            lam1 + F_inv*lam2_l + StSTL.formu_bin{formu_index}*M >= 0];
    end
else
    if less_than_0 == 0
        % lam1 + F_inv*lam2 <= 0
        StSTL.MIP_cons = [StSTL.MIP_cons,...
            lam1 + F_inv*lam2_u + (StSTL.formu_bin{formu_index} - 1)*M <= 0];
        StSTL.MIP_cons = [StSTL.MIP_cons,...
            lam1 + F_inv*lam2_u + StSTL.formu_bin{formu_index}*M >= epsl];
    else
        % lam1 + F_inv*lam2 < 0
        StSTL.MIP_cons = [StSTL.MIP_cons,...
            lam1 + F_inv*lam2_u + (StSTL.formu_bin{formu_index} - 1)*M <= -epsl];
        StSTL.MIP_cons = [StSTL.MIP_cons,...
            lam1 + F_inv*lam2_u + StSTL.formu_bin{formu_index}*M >= 0];
    end
end
StSTL.total_MIP_cons = StSTL.total_MIP_cons + 2;
add_result = formu_index;

end

