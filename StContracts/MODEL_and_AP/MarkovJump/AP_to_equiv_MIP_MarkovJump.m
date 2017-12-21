function add_result = AP_to_equiv_MIP_MarkovJump(AP_tag,k,formu_index,neg_prefix)
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
nx = MODEL.nx;
% nu = MODEL.nu;
zeta = MODEL.zeta;
N = MODEL.N;
P = MODEL.P;
p0 = MODEL.p0;

cons_index = floor(str2double(AP_tag));
if isempty(cons_index)
    error('Invalid AP_tag: non-number elements inside.');
end
if ~isscalar(cons_index)
    error('Invalid AP_tag: multiple numbers inside.');
end
if cons_index < 0 || cons_index > AP.N
    error(['cons_index = ',num2str(cons_index),' is beyond AP.N']);
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

for t = (SMPC.MJ.AP_scena_unrolled(cons_index) + 1):1:k 
    SMPC.MJ.AP_scena_bin{cons_index, t + 1} = binvar( (N + 1)^t, 1 );
end
if SMPC.MJ.AP_scena_unrolled(cons_index) < k
    SMPC.MJ.AP_scena_unrolled(cons_index) = k;
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

% the AP (chance constraint)
%       Pr{ a'*x_k + b'*u_k + c <= 0 } >= p
% is formulated as:
%
%       p_cons = \sum AP_scena_bin( w_0 = w(1), ..., w_{k-1} = w(k) ) 
%                     * P{ w_0 = w(1), ..., w_{k-1} = w(k) } 
%              >= p, 
%
%       AP_scena_bin( w_0 = w(1), ..., w_{k-1} = w(k) ) = 1
%       <--> lam(x_0, u_0, ..., u_k, w(1), ..., w(k)) <= 0
%       <--> a'*x_k + b'*u_k + c <= 0.
%
% where w(1), ..., w(k) is a scenario (realization) of the random sequence
% w_0, ..., w_{k-1}. lam() <= 0 represents 
%       a'*x_k + b'*u_k + c <= 0 
% given the scenario w(1), ..., w(k).


p_cons = 0;       % the probability of satisfying the chance constraint

% A_scena{t + 1} stores 
%   A_{k-1}*...*A_t, t = 0,...,k 
% when a scenario of w is given. Note: A_{k-1}*...*A_{k} is defined to be I.
A_scena = cell(k + 1, 1);           
A_scena{k + 1} = eye(nx);

% B_scena stores 
%   [ a'*A_{k-1}*...*A_{t+1}*B_t, b' ], t = 0,...,k-1 
% when a scenario of w is given. Note: A_{k-1}*...*A_{k} is defined to be I.
B_scena = cell(k + 1, 1);
B_scena{k + 1} = b';

% zeta_scena stores 
%   sum_{t=0}^{k-1} a'*A_{k-1}*...*A_{t+1}*zeta_t, 
% when a scenario of w is given. Note: A_{k-1}*...*A_{k} is defined to be I.
zeta_scena = 0;

for scena = 1:(N + 1)^k
    % compute a scenario
    %   scena - 1 = w(1) + w(2)*(N + 1) + w(3)*(N + 1)^2 
    %                    + ... + w(k)*(N + 1)^(k - 1)
    %   w(1), ..., w(k) takes value in {0, ..., N}
    w = zeros(k, 1);  % holding a particular scenario of w_0, ..., w_{k-1}
    remnant = scena - 1;
    for j = 1:k
        % fprintf('j = %d, remnant = %d\n', j, remnant);
        w(j) = (mod(remnant, (N + 1)^j))/((N + 1)^(j - 1));
        remnant = remnant - w(j)*(N + 1)^(j - 1);
        % fprintf('w(j) = %d, remnant = %d\n', w(j), remnant);
        if remnant == 0
            break;
        elseif remnant < 0
            fprintf('scena = %d, remnant = %d\n', scena, remnant);
            error('remnant should not be negative!');
        end
    end
    
    % compute the probability of this scenario
    if k > 0
        p_scena = p0(w(1) + 1);
        for j = 2:k
            p_scena = p_scena*P(w(j - 1) + 1, w(j) + 1);
        end
    else
        % k == 0, there is only current state and no future trajectory, 
        % so the chance constraint becomes deterministic.
        p_scena = 1;
    end
    
    % fprintf(' k = %d, p_scena = %1.3f\n', k, p_scena);
    % eval('w''');
    
    % assign A_scena, B_scena, zeta_scena    
    for j = k:(-1):1
        % As defined earlier, A_scena{k + 1} = I
        A_scena{j} = A_scena{j + 1}*A{w(j) + 1};
        B_scena{j} = a'*A_scena{j + 1}*B{w(j) + 1};
        zeta_scena = zeta_scena + a'*A_scena{j + 1}*zeta{w(j) + 1};
    end
    
    % lam stores a'*x_k + b'*u_k + c.
    lam = a'*A_scena{k + 1}*SMPC.x0 + B_scena{k + 1}*SMPC.u{k + 1} + zeta_scena + c;
    for j = k:(-1):1
        lam = lam + B_scena{j}*SMPC.u{j};
    end
    
    % Use the binary variable SMPC.MJ.AP_scena_bin{cons_index, k + 1}(scena) 
    % to indicate that whether a'*x_k + b'*u_k + c <= 0 is satisfied or
    % not by the system trajectory in a scenario
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam + (SMPC.MJ.AP_scena_bin{cons_index, k + 1}(scena) - 1)*M <= 0];
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam + SMPC.MJ.AP_scena_bin{cons_index, k + 1}(scena)*M >= epsl];
    StSTL.total_MIP_cons = StSTL.total_MIP_cons + 2;

    % add p_cons
    p_cons = p_cons + SMPC.MJ.AP_scena_bin{cons_index, k + 1}(scena)*p_scena;
end

if neg_prefix == 0
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        p - p_cons + (StSTL.formu_bin{formu_index} - 1)*M <= 0];
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        p - p_cons + StSTL.formu_bin{formu_index}*M >= epsl];
else
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        p - p_cons + (1 - StSTL.formu_bin{formu_index} - 1)*M <= 0];
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        p - p_cons + (1 - StSTL.formu_bin{formu_index})*M >= epsl];
end
StSTL.total_MIP_cons = StSTL.total_MIP_cons + 2;
add_result = formu_index;

end

