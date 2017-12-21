function add_result = AP_to_suffi_MIP_EPS(AP_tag,k,formu_index,neg_prefix)
% AP_TO_SUFFI_MIP_EPS Translate an atomic proposition (AP) into sufficient MILP
% input: AP_tag - an integer (1,2,...) to index a particular AP (see 
%                 AP_Sec7.m for an example of the AP definition).
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
zeta = MODEL.zeta;
H = MODEL.H;
Nb = MODEL.Nb;
Ns = MODEL.Ns;
N_sl = MODEL.N_sl;
N_nsl = MODEL.N_nsl;

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
% StSTL.unrolled: u in [0,unrolled] has been defined when parsing StSTL formulas
for t = (StSTL.unrolled + 1):1:k % t is the 'real' time, like k
    if t == 0 && contract_checking == 1
        SMPC.bat = sdpvar(2,1);               % for contract verification
        SMPC.engine_h = binvar(Ns,1);         % for contract verification
    end
    SMPC.u{t+1} = [binvar(Ns,1);...         % 3 engines to bus 1, contactor
                   binvar(Ns,1);...         % 3 engines to bus 2, contactor
                   sdpvar(Ns,1);...         % 3 engines to bus 1, power
                   sdpvar(Ns,1);...         % 3 engines to bus 2, power
                   SMPC.engine_h;...        % 3 engines' health
                   binvar(N_sl,1);...       % bus 1, sheddable contactor
                   ones(N_nsl,1);...        % bus 1, non-sheddable contactor
                   binvar(N_sl,1);...       % bus 2, sheddable contactor
                   ones(N_nsl,1)];          % bus 2, non-sheddable contactor
end
if StSTL.unrolled < k
    StSTL.unrolled = k;
end

%-------------------------------ensure AP----------------------------------
if neg_prefix == 1 % negation of this AP
    if AP.p{cons_index} == 0
        StSTL.formu_bin{formu_index} = 0;
        add_result = formu_index;
        return;
    end
    if AP.p{cons_index} == 1    % Not(Pr{\mu <= 0} >= 1) is a negation of deterministic constraint,
                                % which is equivalent to
                                % Pr{\mu > 0} >= 1
        a0 = -AP.a{cons_index};
        b0 = -AP.b{cons_index};
        c0 = -AP.c{cons_index} + epsl;
        p0 = 1;
    else                        % Not(Pr{\mu <= 0} >= p), 0 < p < 1 is guaranteed by
                                % Pr{-\mu + epsl <= 0} >= 1 - p + epsl
        a0 = -AP.a{cons_index};
        b0 = -AP.b{cons_index};
        c0 = -AP.c{cons_index} + epsl;
        p0 = 1 - AP.p{cons_index} + epsl;
    end
else
    a0 = AP.a{cons_index};
    b0 = AP.b{cons_index};
    c0 = AP.c{cons_index};
    p0 = AP.p{cons_index};
end

% cons.p == 1 is allowed if: 1. input constraints (i.e., a0 == 0), or                         
%                            2. constraints for k == 0
if ~isscalar(p0)
    error('Invalid p: should be a scalar.');
end
if p0 <= 0 % the chance constraint is trivally true
    StSTL.formu_bin{formu_index} = 1;
    add_result = formu_index;
    return;
elseif p0 > 0 && p0 < 1
    if k > 0
        F_inv = icdf('normal',p0,0,1);
    else
        F_inv = 0;
    end
elseif p0 == 1 
    if norm(a0) > 0 && k ~= 0 % chance cons for x_k, k ~= 0
        error('Invalid p: cannot be equal to 1.');
    end
    F_inv = 0;
else
    error('Invalid p: cannot be larger than 1.');
end

% the chance constraint is formulated as: 
%       lam1 + F_inv*lam2 <= 0
% where lam1 is the deterministic part, and lam2 is the random part

lam1 = a0'*A^k*SMPC.bat + b0'*SMPC.u{k+1} + c0;
lam2_u = 0;
lam2_l = 0;
if F_inv ~= 0
    for t = 1:k

%%%   lam1 and lam2_u can be computed as follows:
%         lam1 = lam1 + a0'*A^(k - t)*(zeta{1} + B{1}*SMPC.u{t});
%         for l = 1:H
%             lam1 = lam1 + MODEL.load_avg(l)*a0'*A^(k - t)*...
%                 (zeta{1 + l} + B{1 + l}*SMPC.u{t});
%             lam2_u = lam2_u + MODEL.load_dev(l)*...
%                 abs(a0'*A^(k - t)*(zeta{1 + l} + B{1 + l}*SMPC.u{t}));
%         end
%%%   However, since H = 40, the loop above takes some time. A more
%%%   conservative but more efficient formulation is as follows.

        lam1_1 = a0'*A^(k - t)*zeta{1};
        lam1_2 = a0'*A^(k - t)*B{1};
        lam2_u_1 = 0;
        lam2_u_2 = 0;
        for l = 1:H
            lam1_1 = lam1_1 + MODEL.load_avg(l)*a0'*A^(k - t)*zeta{1 + l};
            lam1_2 = lam1_2 + MODEL.load_avg(l)*a0'*A^(k - t)*B{1 + l};
            lam2_u_1 = lam2_u_1 + MODEL.load_dev(l)*abs(a0'*A^(k - t)*zeta{1 + l});
            lam2_u_2 = lam2_u_2 + MODEL.load_dev(l)*abs(a0'*A^(k - t)*B{1 + l});
        end
        lam1 = lam1 + lam1_1 + lam1_2*SMPC.u{t};
        lam2_u = lam2_u_1 + lam2_u_2*SMPC.u{t}; % since u{t} >= 0
    end
    if k > 0
        lam2_l = 1/sqrt(k*H)*lam2_u;
    end
end

if F_inv >= 0 % p0 >= 0.5
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam1 + F_inv*lam2_u + (StSTL.formu_bin{formu_index} - 1)*M <= 0];
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam1 + F_inv*lam2_u + StSTL.formu_bin{formu_index}*M >= epsl];
else
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam1 + F_inv*lam2_l + (StSTL.formu_bin{formu_index} - 1)*M <= 0];
    StSTL.MIP_cons = [StSTL.MIP_cons,...
        lam1 + F_inv*lam2_l + StSTL.formu_bin{formu_index}*M >= epsl];
end
StSTL.total_MIP_cons = StSTL.total_MIP_cons + 2;
add_result = formu_index;

end

