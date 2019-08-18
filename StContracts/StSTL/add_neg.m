function add_result = add_neg(str,formu_index,sat_time_hint,neg_prefix)
%ADD_NEG Encode a NOT formula by assigning binary variables to its 
% sub-formulas and adding MIP constraints into the encoding constraint set.
%   Input: str - the formula string, must have the form 'f' or 'f,t'
%          formu_index - the index of this formula stored in the StSTL encoding 
%                        quadruple (formu_str, formu_time, formu_neg, formu_bin)
%          sat_time_hint
%                    - -1, indicating no hint on satisfaction time from 
%                         formulas preceding the current formula
%                    - (t1,...,tn), giving its subformula a series of 
%                      satisfaction time (for example, 'Not(And(f1,f2,...,fn))').
%                      (t1,...,tn) CANNOT be (-1,...,-1).
%          neg_prefix  - an integer indicating that the number of negations 
%                        before str of the current formula
%   Output: add_result - takes value of formu_index if this formula addition 
%                        is successful
%                      - takes value of 0 if this formula addition fails
%   Note: if neg_prefix == 1, add_neg() will set neg_prefix = 0. In other 
%         translating programs such as add_always(), add_AP(), ect., 
%         neg_prefix == 0 lets them behave as normal, neg_prefix = 1 lets 
%         them propagate the negation to their sub-formulas.
%
%   Written by Jiwei Li

global StSTL;

[comma_index,comma_num] = find_comma(str);
if comma_num == 0
    sub_formula = strtrim(str);
elseif comma_num == 1
    sub_formula = strtrim(str(1:(comma_index(1) - 1)));
    time_point_1 = str2double(str((comma_index(1) + 1):end));
    if sat_time_hint ~= -1 && sat_time_hint ~= time_point_1
        error('Inconsistent between formula string and sat_time_hint');
    elseif sat_time_hint == -1
        sat_time_hint = time_point_1;
    end
else
    error('Maximal parameter number is 2 in add_negation!');
end

if neg_prefix == 2 % there are two negation prefix before str
    neg_prefix = 0;
elseif neg_prefix > 2
    error('neg_prefix should be less than 3');
end

[is_found,sub_formula_index] = search_track_formula(sub_formula,sat_time_hint,neg_prefix);
if is_found && StSTL.display == 1
    fprintf(StSTL.fid, ['formula ',StSTL.formu_str{sub_formula_index},...
        ' with sat_time_hint ',num2str(StSTL.formu_time{sub_formula_index}),...
        ', neg_prefix ',num2str(StSTL.formu_neg{sub_formula_index}),...
        ' that has already tracked is revoked by ',...
        sub_formula,' with sat_time_hint ',...
        num2str(sat_time_hint),'\n']);
end

add_result = add_formula(sub_formula,sub_formula_index,sat_time_hint,neg_prefix);
if add_result
    StSTL.total_MIP_cons = StSTL.total_MIP_cons + 1;
    StSTL.MIP_cons = [StSTL.MIP_cons,StSTL.formu_bin{formu_index} == StSTL.formu_bin{sub_formula_index}];
    add_result = formu_index;
end

end

