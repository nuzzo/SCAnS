function [is_found,formu_index] = search_track_formula(str,sat_time_hint,neg_prefix)
%ASSIGN_FORMULA Search a formula in the triple (formu_str, formu_time, formu_neg)  
% and determine whether it is new or not. If the formula is new, then keep track 
% of it and assign a binary variable to it, thus forming a new quadruple 
% (formu_str, formu_time, formu_neg, formu_bin). Otherwise, just return 
% the formu_index of the formula.
%   Input: str - the formula string
%          sat_time_hint - a vector of numbers, indicating the hint on 
%                          satisfaction time from formulas preceding the 
%                          current formula
%          neg_prefix  - an integer indicating that the number of negations 
%                        before str of the current formula
%   Output: is_found - 1, if the input formula is found in existing quadruple 
%                    - 0, if the input formula is new and not found
%           formu_index - the index of the input formula in the quadruple
%                         record
%
%   Written by Jiwei Li

global StSTL;

if StSTL.total_formu > 0 && StSTL.repeat_check == 1
    formu_index = find(strcmp(str,StSTL.formu_str(1,1:StSTL.total_formu)));
    tmp = -3*ones(1,length(formu_index));
    for i = 1:length(formu_index)
        sat_time_old_formula = StSTL.formu_time{formu_index(i)};
        neg_prefix_old_formula = StSTL.formu_neg{formu_index(i)};
        if size(sat_time_old_formula,2) == size(sat_time_hint,2)
            if all(sat_time_old_formula == sat_time_hint)...
                    && all(neg_prefix_old_formula == neg_prefix)
                tmp(i) = 1;
            end
        end
    end
    formu_index = formu_index(tmp > 0);
else
    formu_index = 0;
end
if size(formu_index,2) >= 2
    error('Same str found to be assigned multiple times!');
elseif ~any(formu_index) % it is new, we should keep track of the str
    is_found = 0;
    StSTL.total_formu = StSTL.total_formu + 1;
    formu_index = StSTL.total_formu;
    StSTL.formu_str{formu_index} = str;             % record the string
    StSTL.formu_time{formu_index} = sat_time_hint;  % record the time
    StSTL.formu_neg{formu_index} = neg_prefix;      % record the prefix negation number
    StSTL.formu_bin{formu_index} = binvar(1);       % assign a binary variable
    if 1 == StSTL.display && 1 == StSTL.repeat_check
        fprintf(['In search_track_formula(): formula ',str,...
            ' with sat_time_hint = ',num2str(sat_time_hint),...
            ', neg_prefix = ',num2str(neg_prefix),...
            ' is new and tracked. formu_index = ',num2str(formu_index),'\n']);
    elseif 1 == StSTL.display && 0 == StSTL.repeat_check
        fprintf(['In search_track_formula(): formula ',str,...
            ' with sat_time_hint = ',num2str(sat_time_hint),...
            ', neg_prefix = ',num2str(neg_prefix),...
            ' is tracked without checking repetition. formu_index = ',...
            num2str(formu_index),'\n']);
    end
else
    is_found = 1;
end

end

