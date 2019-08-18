function load = load_demand(t)
%LOAD_DEMAND give random load demand
%   Created on Jan 12, 2016
global EPS SIMU;

load_mean = [EPS.bus1_load_avg;EPS.bus2_load_avg];
load_stand_dev = [EPS.bus1_load_dev;EPS.bus2_load_dev];
load_horizon = size(EPS.bus1_load_avg,2);

if t < load_horizon % time starts from 0 and ends at simu_step
    load = random('Normal',load_mean(:,t + 1),load_stand_dev(:,t + 1),...
        EPS.load_n,1);
else
    load = random('Normal',load_mean(:,load_horizon),...
        load_stand_dev(:,load_horizon),EPS.load_n,1);
end
SIMU.load_rec(:,t + 1) = load;

end

