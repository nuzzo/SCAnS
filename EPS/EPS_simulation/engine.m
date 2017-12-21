function out_para = engine(t)
%ENGINE_POWER Generates CONSTANT engine power
%   Written by Jiwei Li

global EPS;

if t + 1 > size(EPS.engine_h,2)
    t = size(EPS.engine_h,2) - 1;
end
power = EPS.engine_max.*EPS.engine_h(:,t + 1);
out_para = [EPS.engine_h(:,t + 1);power];

end

