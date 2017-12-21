function enforce_formula(formu_index)
%ENFORCE_FORMULA Assign the binary variable for a formula indexed by 
%   formu_index to 1.
%
%   Written by Jiwei Li

global StSTL;

if size(formu_index,1) ~= 1
    error('Input of enforce_formula should be a row vector.');
end
for j = 1:size(formu_index,2)
    k = formu_index(j);
    if k > 0
        StSTL.MIP_cons = [StSTL.MIP_cons, StSTL.formu_bin{k} == 1];
        StSTL.total_MIP_cons = StSTL.total_MIP_cons + 1;
    end
end

end

