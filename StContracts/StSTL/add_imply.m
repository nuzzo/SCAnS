function add_result = add_imply(str,formu_index,sat_time_hint,neg_prefix)
%ADD_IMPLY Encode an IMPLY formula by assigning binary variables to its 
% sub-formulas and adding MIP constraints into the encoding constraint set.
%   Input: str - the formula string, must have the form 'f1,f2'.
%          formu_index - the index of this formula stored in the StSTL encoding 
%                        quadruple (formu_str, formu_time, formu_neg, formu_bin)
%          sat_time_hint 
%                    - -1, indicating no hint on satisfaction time from 
%                         formulas preceding the current formula
%                    - t, indicating that the sat_time_hint of f1 and f2 is t
%          neg_prefix  - an integer indicating that the number of negations 
%                        before str of the current formula
%   Output: add_result - takes value of formu_index if this formula addition 
%                        is successful
%                      - takes value of 0 if this formula addition fails
%
%   Written by Jiwei Li

global StSTL;

if ~isscalar(sat_time_hint)
    error('In add_imply(), sat_time_hint has to be a scalar.');
end
if neg_prefix > 1
    error('neg_prefix should be no larger than 1');
end
[comma_index,comma_num] = find_comma(str);
if comma_num ~= 1
    error('add_imply() needs its formula string to have two parameters, i.e., ''f1,f2''!');
end
sub_formula1 = strtrim(str(1:(comma_index - 1)));
sub_formula2 = strtrim(str((comma_index + 1):end));

if 1 == StSTL.display
    fprintf(StSTL.fid, ['In add_imply()',...
        ', sat_time_hint = ',num2str(sat_time_hint),...
        ', neg_prefix = ',num2str(neg_prefix),...
        ', f1 = ',num2str(sub_formula1),', f2 = ',num2str(sub_formula2),'\n']);
end

if sat_time_hint ~= -1 && sat_time_hint < 0
    error('In add_imply(), illegal sat_time_hint!');
end

% if neg_prefix == 0
%     equiv_str = ['Or(','Not(',sub_formula1,'), ',sub_formula2,')'];
% else
%     equiv_str = ['And(',sub_formula1,'Not(',sub_formula2,')',')'];
% end

equiv_str = ['Or(','Not(',sub_formula1,'), ',sub_formula2,')'];

[is_found,equiv_index] = search_track_formula(equiv_str, sat_time_hint, neg_prefix);
if is_found && StSTL.display == 1
    fprintf(StSTL.fid, ['In add_imply(), formula ',StSTL.formu_str{equiv_index},...
        ' with sat_time_hint ',num2str(StSTL.formu_time{equiv_index}),...
        ', neg_prefix ',num2str(StSTL.formu_neg{equiv_index}),...
        ' that has already tracked is revoked by ',...
        equiv_str,' with sat_time_hint ',...
        num2str(sat_time_hint),'\n']);
end

add_result = add_formula(equiv_str, equiv_index, sat_time_hint, neg_prefix);
if add_result
    StSTL.total_MIP_cons = StSTL.total_MIP_cons + 1;
    StSTL.MIP_cons = [StSTL.MIP_cons,StSTL.formu_bin{equiv_index} == StSTL.formu_bin{formu_index}];
    add_result = formu_index;
end

end

