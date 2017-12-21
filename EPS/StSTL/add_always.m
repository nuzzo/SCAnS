function add_result = add_always(str,formu_index,sat_time_hint,neg_prefix)
%ADD_ALWAYS Encode an ALWAYS formula by assigning binary variables to its 
% sub-formulas and adding MIP constraints into the encoding constraint set.
%   Input: str - the formula string, must have the form 'f,t_start,t_end'.
%          formu_index - the index of this formula stored in the StSTL encoding 
%                        quadruple (formu_str, formu_time, formu_neg, formu_bin)
%          sat_time_hint 
%                    - -1, indicating no hint on satisfaction time from 
%                         formulas preceding the current formula
%                    - t, indicating that the actual satisfaction time 
%                         of f is [t + t_start, t + t_end]
%          neg_prefix  - an integer indicating that the number of negations 
%                        before str of the current formula
%   Output: add_result - takes value of formu_index if this formula addition 
%                        is successful
%                      - takes value of 0 if this formula addition fails
%
%   Written by Jiwei Li

global StSTL;

if ~isscalar(sat_time_hint)
    error('In add_always(), sat_time_hint has to be a scalar.');
end
if size(sat_time_hint,2) > 1 && all(sat_time_hint == -1)
    error(['In add_always(), if sat_time_hint = [-1,...,-1], then just ',...
           'set sat_time_hint = -1.']);
end
if neg_prefix > 1
    error('neg_prefix should be no larger than 1');
end
[comma_index,comma_num] = find_comma(str);
if comma_num == 0 || comma_num == 1
    error('add_always() needs formula string to have three parameters!');
end
sub_formula = str(1:(comma_index(1) - 1));
t_start = floor(str2double(str((comma_index(1) + 1):(comma_index(2) - 1))));
t_end = floor(str2double(str((comma_index(2) + 1):end)));

if 1 == StSTL.display
    fprintf(['In add_always()',...
        ', sat_time_hint = ',num2str(sat_time_hint),...
        ', neg_prefix = ',num2str(neg_prefix),...
        ', t_start = ',num2str(t_start),', t_end = ',num2str(t_end),'\n']);
end
if t_start < 0 || t_end < 0 || t_start > t_end
    error('In add_always(), invalid t_start or t_end!');
end
if sat_time_hint ~= -1 && sat_time_hint < 0
    error('In add_always(), illegal sat_time_hint!');
elseif sat_time_hint >= 0
    t_start = t_start + sat_time_hint;
    t_end = t_end + sat_time_hint;
end

equiv_str = sub_formula;
if t_end >= t_start + 1
    if neg_prefix == 0
        equiv_str = ['And(',equiv_str,')'];
    else
        equiv_str = ['Or(',equiv_str,')'];
    end
end

[is_found,equiv_index] = search_track_formula(equiv_str,t_start:1:t_end,neg_prefix);
if is_found && StSTL.display == 1
    fprintf(['In add_always(), formula ',StSTL.formu_str{equiv_index},...
        ' with sat_time_hint ',num2str(StSTL.formu_time{equiv_index}),...
        ', neg_prefix ',num2str(StSTL.formu_neg{equiv_index}),...
        ' that has already tracked is revoked by ',...
        equiv_str,' with sat_time_hint ',...
        num2str(sat_time_hint),'\n']);
end

add_result = add_formula(equiv_str,equiv_index,t_start:1:t_end,neg_prefix);
if add_result
    StSTL.total_MIP_cons = StSTL.total_MIP_cons + 1;
    StSTL.MIP_cons = [StSTL.MIP_cons,StSTL.formu_bin{equiv_index} == StSTL.formu_bin{formu_index}];
    add_result = formu_index;
end

end

