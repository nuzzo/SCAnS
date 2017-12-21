function add_result = add_or(str,formu_index,sat_time_hint,neg_prefix)
%ADD_OR Encode an OR formula by assigning binary variables to its 
% sub-formulas and adding MIP constraints into the encoding constraint set.
%   Input: str - the formula string, must have the form 'f1,f2,...,fm'
%          formu_index - the index of this formula stored in the StSTL encoding 
%                        quadruple (formu_str, formu_time, formu_neg, formu_bin)
%          sat_time_hint - (t1,...,tn), giving its subformula a series of 
%                          satisfaction time
%   Note: There are three cases that we can understand and proceed:
%          first, m = n, giving each subformula a satisfaction time; 
%          second, m = 1, n > 1, giving the only subformula a handful of 
%                  satisfaction time, yielding 'or(f(t1),...,f(tn))';
%          third, m > 1, n = 1, then giving all subformulas the 
%                 same satisfaction time, yielding 'or(f1(t),...,fm(t))'.
%
% Written by Jiwei Li

global StSTL;

if size(sat_time_hint,1) ~= 1
    error('In add_or(), sat_time_hint has to be a row.');
end
[comma_index,comma_num] = find_comma(str);
given_sub_num = comma_num + 1;
given_satis_num = size(sat_time_hint,2);

% enumerate the opposite situations in which add_or() will not handle
if given_sub_num > 1 && given_satis_num > 1 && given_satis_num ~= given_sub_num
    error('In add_or(), #sat_time_hint ~= #subformulas, but they both > 1!');
end

sub_num = max(given_sub_num,given_satis_num);
sub_index = zeros(1,sub_num);
sub_str = cell(1,sub_num);

if given_sub_num == 1
    for i = 1:sub_num
        sub_str{i} = strtrim(str);
    end
else % two subformulas at least
    sub_str{1} = strtrim(str(1:(comma_index(1) - 1)));
    for i = 1:(comma_num - 1)
        sub_str{i + 1} = strtrim(str((comma_index(i) + 1):(comma_index(i + 1) - 1)));
    end
    sub_str{sub_num} = strtrim(str((comma_index(comma_num) + 1):end));
end

if given_satis_num == 1
    sat_time_hint = sat_time_hint*ones(1,sub_num);
end

for i = 1:sub_num
    [is_found,index] = search_track_formula(sub_str{i},sat_time_hint(i),neg_prefix);
    if is_found && 1 == StSTL.display
        fprintf(StSTL.fid, ['In add_or(), formula ',StSTL.formu_str{index},...
            ' with sat_time_hint ',num2str(StSTL.formu_time{index}),...
            ', neg_prefix ',num2str(StSTL.formu_neg{index}),...
            ' that has already been recorded is revoked by ',...
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
    StSTL.total_MIP_cons = StSTL.total_MIP_cons + 2;
    if neg_prefix == 0 % logical or
        StSTL.MIP_cons = [StSTL.MIP_cons, 1/sub_num*sum_vars <= StSTL.formu_bin{formu_index}];
        StSTL.MIP_cons = [StSTL.MIP_cons, StSTL.formu_bin{formu_index} <= sum_vars];
    else % logical and
        StSTL.MIP_cons = [StSTL.MIP_cons, sum_vars - sub_num + 1 <= StSTL.formu_bin{formu_index}];
        StSTL.MIP_cons = [StSTL.MIP_cons, StSTL.formu_bin{formu_index} <= 1/sub_num*sum_vars];
    end
    add_result = formu_index;
end

end

