function add_result = add_weak(str,formu_index,sat_time_hint,neg_prefix)
%ADD_WEAK Encode a WEAK UNTIL formula by assigning binary variables to its 
% sub-formulas and adding MIP constraints into the encoding constraint set.
%   Input: str - the formula string, must have the form 'f1,f2,t_start,t_end'.
%          sat_time_hint
%                    - must be a scalar, serving as a starting time after 
%                      which the formula is satisfied.
%          neg_prefix  - an integer indicating the number of negations 
%                        before str of the current formula.
%   Output: add_result - takes value of formu_index if this formula addition 
%                        is successful
%                      - takes value of 0 if this formula addition fails
%
%   Written by Jiwei Li

global StSTL;

str = strtrim(str);
[comma_index,comma_num] = find_comma(str);
if comma_num == 3
    f1 = strtrim(str(1:(comma_index(1) - 1)));
    t_start = floor(str2double(str((comma_index(2) + 1):(comma_index(3) - 1))));
    t_end = floor(str2double(str((comma_index(3) + 1):end)));
    if t_start < 0 || t_end < 0 || t_start > t_end
        error('In add_weak(), invalid t_start or t_end!');
    end
else
    error('Parameter number should be 3 in add_weak()!');
end
if ~isscalar(sat_time_hint)
    error('Invalid sat_time_hint!');
end

sub_str = cell(1,2);
sub_index = zeros(1,2);

sub_str{1} = ['Until(',str,')'];
[is_found,index_1] = search_track_formula(sub_str{1},sat_time_hint,neg_prefix);
if is_found && 1 == StSTL.display
    fprintf(StSTL.fid, ['In add_weak(), formula ',StSTL.formu_str{index_1},...
        ' with sat_time_hint ',num2str(StSTL.formu_time{index_1}),...
        ', neg_prefix ',num2str(StSTL.formu_neg{index_1}),...
        ' that has already tracked is revoked by ',...
        sub_str{1},' with sat_time_hint ',...
        num2str(sat_time_hint),'\n']);
end
sub_index(1) = index_1;

sub_str{2} = ['Global(',f1,',',num2str(t_start),',',num2str(t_end),')'];
[is_found,index_2] = search_track_formula(sub_str{2},sat_time_hint,neg_prefix);
if is_found && 1 == StSTL.display
    fprintf(StSTL.fid, ['In add_weak(), formula ',StSTL.formu_str{index_2},...
        ' with sat_time_hint ',num2str(StSTL.formu_time{index_2}),...
        ', neg_prefix ',num2str(StSTL.formu_neg{index_2}),...
        ' that has already tracked is revoked by ',...
        sub_str{2},' with sat_time_hint ',...
        num2str(sat_time_hint),'\n']);
end
sub_index(2) = index_2;

for i = 1:2
    add_result = add_formula(sub_str{i},sub_index(i),sat_time_hint,neg_prefix);
    if 0 == add_result
        break;
    end
end
if add_result
    sum_vars = 0;
    for i = 1:2
        sum_vars = sum_vars + StSTL.formu_bin{sub_index(i)};
    end
    if neg_prefix == 0 % logical or
        StSTL.MIP_cons = [StSTL.MIP_cons,1/2*sum_vars <= StSTL.formu_bin{formu_index}];
        StSTL.MIP_cons = [StSTL.MIP_cons,StSTL.formu_bin{formu_index} <= sum_vars];
    else % logical and
        StSTL.MIP_cons = [StSTL.MIP_cons,sum_vars - 1 <= StSTL.formu_bin{formu_index}];
        StSTL.MIP_cons = [StSTL.MIP_cons,StSTL.formu_bin{formu_index} <= 1/2*sum_vars];
    end
    StSTL.total_MIP_cons = StSTL.total_MIP_cons + 2;
    add_result = formu_index;
end

end

