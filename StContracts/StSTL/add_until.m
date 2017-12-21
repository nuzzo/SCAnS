function add_result = add_until(str,formu_index,sat_time_hint,neg_prefix)
%ADD_UNTIL Encode an UNTIL formula by assigning binary variables to its 
% sub-formulas and adding MIP constraints into the encoding constraint set.
%   Input: str - the formula string, must have the form 'f' or 'f,t'
%          formu_index - the index of this formula stored in the StSTL encoding 
%                        quadruple (formu_str, formu_time, formu_neg, formu_bin)
%          sat_time_hint
%                    - must be a scalar, serving as a starting time after 
%                      which the formula is satisfied.
%          neg_prefix  - an integer indicating the number of negations 
%                        before str of the current formula
%   Output: add_result - takes value of formu_index if this formula addition 
%                        is successful
%                      - takes value of 0 if this formula addition fails
%   Note: sat_time_hint = 5 means Until applies to x_{k+5},x_{k+6},...
%         sat_time_hint = -1 means that higher-level formulas do NOT set 
%         staring time, so we set sat_time_hint = 0.
%
%   Written by Jiwei Li

global StSTL;

[comma_index,comma_num] = find_comma(str);
if comma_num == 3
    f1 = strtrim(str(1:(comma_index(1) - 1)));
    f2 = strtrim(str((comma_index(1) + 1):(comma_index(2) - 1)));
    t_start = floor(str2double(str((comma_index(2) + 1):(comma_index(3) - 1))));
    t_end = floor(str2double(str((comma_index(3) + 1):end)));
    if t_start < 0 || t_end < 0 || t_start > t_end
        error('In add_until(), invalid t_start or t_end!');
    end
else
    error('Parameter number should be 3 in add_until()!');
end
if ~isscalar(sat_time_hint)
    error('Invalid sat_time_hint!');
end
if sat_time_hint == -1
    sat_time_hint = 0;
elseif sat_time_hint < 0
    error('Invalid sat_time_hint!');
end
T0 = sat_time_hint;

sub_num = t_end - t_start + 1;
sub_index = zeros(1,sub_num);
sub_t_vector = cell(1,sub_num);
sub_str = cell(1,sub_num);

sub_str{1} = f2;
sub_t_vector{1} = t_start + T0;
[is_found,index_1] = search_track_formula(sub_str{1},sub_t_vector{1},neg_prefix);
if is_found && 1 == StSTL.display
    fprintf(StSTL.fid, ['In add_until(), formula ',StSTL.formu_str{index_1},...
        ' with sat_time_hint ',num2str(StSTL.formu_time{index_1}),...
        ', neg_prefix ',num2str(StSTL.formu_neg{index_1}),...
        ' that has already tracked is revoked by ',...
        sub_str{1},' with sat_time_hint ',...
        num2str(sub_t_vector{1}),'\n']);
end
sub_index(1) = index_1;

for i = 2:sub_num
    if neg_prefix == 0
        sub_str{i} = ['And(',f2];
        for j = 1:(i - 1)
            sub_str{i} = [sub_str{i},',',f1];
        end
        sub_str{i} = [sub_str{i},')'];
    else
        sub_str{i} = ['Or(',f2];
        for j = 1:(i - 1)
            sub_str{i} = [sub_str{i},',',f1];
        end
        sub_str{i} = [sub_str{i},')'];
    end
    sub_t_vector{i} = (t_start + T0 + i - 1):(-1):(t_start + T0);
    [is_found,index_i] = search_track_formula(sub_str{i},sub_t_vector{i},neg_prefix);
    if is_found && 1 == StSTL.display
        fprintf(StSTL.fid, ['In add_until(), formula ',StSTL.formu_str{index_i},...
            ' with sat_time_hint ',num2str(StSTL.formu_time{index_i}),...
            ', neg_prefix ',num2str(StSTL.formu_neg{index_i}),...
            ' that has already tracked is revoked by ',...
            sub_str{i},' with sat_time_hint ',...
            num2str(sub_t_vector{i}),'\n']);
    end
    sub_index(i) = index_i;
end

for i = 1:sub_num
    add_result = add_formula(sub_str{i},sub_index(i),sub_t_vector{i},neg_prefix);
    if 0 == add_result
        break;
    end
end

if add_result
    sum_vars = 0;
    for i = 1:sub_num
        sum_vars = sum_vars + StSTL.formu_bin{sub_index(i)};
    end
    if neg_prefix == 0 % logical or
        StSTL.MIP_cons = [StSTL.MIP_cons,1/sub_num*sum_vars <= StSTL.formu_bin{formu_index}];
        StSTL.MIP_cons = [StSTL.MIP_cons,StSTL.formu_bin{formu_index} <= sum_vars];
    else % logical and
        StSTL.MIP_cons = [StSTL.MIP_cons,sum_vars - sub_num + 1 <= StSTL.formu_bin{formu_index}];
        StSTL.MIP_cons = [StSTL.MIP_cons,StSTL.formu_bin{formu_index} <= 1/sub_num*sum_vars];
    end
    StSTL.total_MIP_cons = StSTL.total_MIP_cons + 2;
    add_result = formu_index;
end

end

