function add_result = AP_to_equiv_MIP_GaussLin(AP_tag,k,formu_index,neg_prefix)
%AP_TO_MILP Translate an atomic proposition (AP) into equivalent MILP
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
    error(['cons_index = ',num2str(cons_index),' is beyond the boundry']);
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

if neg_prefix == 1
    % Note: Not(Pr{\mu <= 0} >= p), 0 < p < 1 will be encoded based on the 
    %   encoding of Pr{\mu <= 0} >= p. Let b_neg denote the binary variable 
    %   assigned to Not(Pr{\mu <= 0} >= p), i.e., 
    %           b_neg = 1 <--> Not(Pr{\mu <= 0} >= p).
    %   We will ensure this by
    %           (1 - b_neg) = 1 <--> Pr{\mu <= 0} >= p.
    if AP.p{cons_index} <= 0
        % Because Not( Pr{\mu <= 0} >= p ) <--> Pr{\mu <= 0} < p. When p is  
        % non-positive, this proposition must be false, we directly return.
        StSTL.formu_bin{formu_index} = 0;
        add_result = formu_index;
        return;
    end
else
    if AP.p{cons_index} <= 0
        % the chance constraint is trivally true
        StSTL.formu_bin{formu_index} = 1;
        add_result = formu_index;
        return;
    end
end

a = AP.a{cons_index};
b = AP.b{cons_index};
c = AP.c{cons_index};
p = AP.p{cons_index};

% the chance constraint is formulated as: 
%       lam1 + F_inv*lam2 <= 0
% where lam1 is the deterministic part, and lam2 is the random part

lam1 = a'*A^k*SMPC.x0 + b'*SMPC.u{k+1} + c;
lam2 = 0;

for t = 1:k
    lam1 = lam1 + a'*A^(k - t)*(zeta{1} + B{1}*SMPC.u{t});
    for l = 1:N
        lam1 = lam1 + a'*A^(k - t)*(zeta{1 + l} + B{1 + l}*SMPC.u{t})*w_bar(l);
    end
end

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
    % Lambda
    if norm(Lambda,2) < 10^(-6)
        lam2 = 0;
        fprintf(StSTL.fid, '***Lambda_{k-1} is very close to 0, with its 2 norm being %2.10f, so we set lam2 = 0.\n', norm(Lambda,2));
    else
        % lam2 = norm( sqrt(Lambda)*[u_vec;1], 2 );
        lam2 = sqrtm( [u_vec;1]'*Lambda*[u_vec;1] );
    end
end

% % Note: the following way to compute lam2 is a special case where Theta is diagonal.
% if F_inv ~= 0
%     for t = 1:k
%         for l = 1:N
%             lam2 = lam2 + Theta(l,l)*(a'*A^(k - t)*(zeta{1 + l} + B{1 + l}*SMPC.u{t}))^2;
%         end
%     end
%     lam2 = sqrtm(lam2);
% end

% Because the system state is Gaussian distributed, p == 0 or 1 leads F_inv
% to be -Inf or Inf. However, p == 1 or 0 is allowed if lam2 == 0.

if p > 0 && p < 1
    if k > 0
        F_inv = icdf('normal',p,0,1);
    else
        F_inv = 0;
    end
elseif p == 1
    if lam2 ~= 0
        error(['Invalid p = ', num2str(p) ,': cannot be 1.']);
    end
    F_inv = 0;
else
    error('Invalid p: cannot be larger than 1 or negative.');
end

if neg_prefix == 0
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam1 + F_inv*lam2 + (StSTL.formu_bin{formu_index} - 1)*M <= 0];
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam1 + F_inv*lam2 + StSTL.formu_bin{formu_index}*M >= epsl];
else
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam1 + F_inv*lam2 + (1 - StSTL.formu_bin{formu_index} - 1)*M <= 0];
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam1 + F_inv*lam2 + (1 - StSTL.formu_bin{formu_index})*M >= epsl];
end
StSTL.total_MIP_cons = StSTL.total_MIP_cons + 2;
add_result = formu_index;

end

