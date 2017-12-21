function health = contactor_health(in_para)
%CONTRACTOR_HEALTH Assign health state to each contactor
%   Written by Jiwei Li
global EPS SIMU;

t = in_para(1); % time starts from 0 and ends at simu_step
health = binornd(1,EPS.conta_h_prob,EPS.engine_sload_conta_n,1);
if t >= 1
    last_state = SIMU.conta_h_rec(:,t);
    health = health.*last_state;
end   
% health'
SIMU.conta_h_rec(:,t + 1) = health;

end

