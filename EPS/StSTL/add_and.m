function add_result = add_and(str,formu_index,sat_time_hint,neg_prefix)
%ADD_AND Encode an AND formula by assigning binary variables to its 
% sub-formulas and adding MIP constraints into the encoding constraint set.
%   Input: str - the formula string, must have the form 'f1,f2,...,fm'
%          formu_index - the index of this formula stored in the StSTL encoding 
%                        quadruple (formu_str, formu_time, formu_neg, formu_bin)
%          sat_time_hint - (t1,...,tn), inferred from formulas preceding 
%                          the current formula
%          neg_prefix  - an integer indicating that the number of negations 
%                        before str of the current formula
%   Output: add_result - formu_index, if this formula addition is successful
%                      - 0, if this formula addition fails
%   Note that there are three cases that we can understand and proceed:
%          first, m = n, giving each subformula a satisfaction time;
%          second, m = 1, n > 1, giving the only subformula a handful of 
%                  satisfaction time (e.g., for operator always), yielding 
%                  'and(f(t1),...,f(tn))';
%          third, m > 1, n = 1, then giving all subformulas the 
%                 same satisfaction time, yielding 'and(f1(t),...,fm(t))'.
%
%   Written by Jiwei Li

global StSTL;

if size(sat_time_hint,1) ~= 1
    error('In add_and(), sat_time_hint has to be a row.');
end
if neg_prefix > 1
    error('neg_prefix should be no larger than 1');
end
[comma_index,comma_num] = find_comma(str);
given_sub_num = comma_num + 1;
given_sat_num = size(sat_time_hint,2);

% enumerate the opposite situations in which add_and() will not handle
if given_sub_num > 1 && given_sat_num > 1 && given_sat_num ~= given_sub_num
    error('In add_and(), #sat_time_hint ~= #subformulas, but they both > 1!');
end

sub_num = max(given_sub_num,given_sat_num);
sub_index = zeros(1,sub_num);
sub_str = cell(1,sub_num);

if given_sub_num == 1
    for i = 1:sub_num
        sub_str{i} = str;
    end
else % two subformulas at least
    sub_str{1} = str(1:(comma_index(1) - 1));
    for i = 1:(comma_num - 1)
        sub_str{i + 1} = str((comma_index(i) + 1):(comma_index(i + 1) - 1));
    end
    sub_str{sub_num} = str((comma_index(comma_num) + 1):end);
end

if given_sat_num == 1
    sat_time_hint = sat_time_hint*ones(1,sub_num);
end

for i = 1:sub_num
    [is_found,index] = search_track_formula(sub_str{i},sat_time_hint(i),neg_prefix);
    if is_found && 1 == StSTL.display
        fprintf(['In add_and(), formula ',StSTL.formu_str{index},...
            ' with sat_time_hint ',num2str(StSTL.formu_time{index}),...
            ', neg_prefix ',num2str(StSTL.formu_neg{index}),...
            ' that has already tracked is revoked by ',...
            sub_str{i},' with sat_time_hint ',...
            num2str(sat_time_hint(i)),'\n']);
    end
    sub_index(i) = index;
end

for i = 1:sub_num
    add_result = add_formula(sub_str{i},sub_index(i),sat_time_hint(i),neg_prefix);
    if 0 == add_result
        break;
    end
end

if add_result
    sum_vars = 0;
    for i = 1:sub_num
        sum_vars = sum_vars + StSTL.formu_bin{sub_index(i)};
    end
    if neg_prefix == 0 % logical and
        StSTL.MIP_cons = [StSTL.MIP_cons,sum_vars - sub_num + 1 <= StSTL.formu_bin{formu_index}];
        StSTL.MIP_cons = [StSTL.MIP_cons,StSTL.formu_bin{formu_index} <= 1/sub_num*sum_vars];
    else % logical or
        StSTL.MIP_cons = [StSTL.MIP_cons,1/sub_num*sum_vars <= StSTL.formu_bin{formu_index}];
        StSTL.MIP_cons = [StSTL.MIP_cons,StSTL.formu_bin{formu_index} <= sum_vars];
    end
    StSTL.total_MIP_cons = StSTL.total_MIP_cons + 2;
    add_result = formu_index;
end

end

