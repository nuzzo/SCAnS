function add_result = add_formula(formula,varargin)
%ADD_FORMULA Encode a formula by assigning binary variables to its 
% sub-formulas and adding MIP constraints into the encoding constraint set.
%   Input: formula - string of the formula, like 'G(1,100)', 'U(1,2,20)'
%          formu_index - the index of this formula stored in the StSTL encoding 
%                        quadruple (formu_str, formu_time, formu_neg, formu_bin)
%          varargin - may contain the following items:
%                     1. sat_time_hint, indicating when the formula begins 
%                        to be satisfied. If user do not specify it, then 
%                        sat_time_hint is set to zero
%                     2. neg_prefix, an integer indicating that the number  
%                        of negations before str of the current formula
%   Output: add_result - formu_index of the input formula if the input 
%                        formula is added successfully (no repetion, illegal 
%                        syntex found). Otherwise, add_result = 0.
%   Note:  formu_index == 0 indicates that the index of this formula in the
%          quadruple (formu_str, formu_time, formu_neg, formu_bin) is unknown,
%          thus requiring a search in the triple (formu_str, formu_time, formu_neg) 
%          to figure out that whether the formula is new (has not been recorded 
%          in the quadruple) or not. In the first case, the formula is added 
%          to the quadruple. In the second case, formu_index is set to its 
%          proper value. Attention that the case formu_index == 0 or formu_index 
%          being omitted as an input argument ONLY occurs when the formula is 
%          specified by a user. The programs in the StSTL folder always
%          pass a meaningful integer to this argument!
%
%   Written by Jiwei Li

global StSTL;

add_result = 1;
if ~isscalar(ischar(formula))
    fprintf(StSTL.fid, 'You should add one formula expression at a time. Quit.\n');
    add_result = 0;
elseif ~ischar(formula)
    fprintf(StSTL.fid, 'This formula is not a string! Quit.\n');
    add_result = 0;
elseif ~strcmp(')',formula(end))
    fprintf(StSTL.fid, 'Formulas should end by )! Quit.\n');
    add_result = 0;
end

formula = strtrim(formula);
var_num = length(varargin);
switch var_num
    case 3
        formu_index = varargin{1};
        sat_time_hint = varargin{2};
        neg_prefix = varargin{3};
    case 2
        formu_index = varargin{1};
        sat_time_hint = varargin{2};
        neg_prefix = 0;
    case 1
        formu_index = varargin{1};
        sat_time_hint = -1; 
        % meaning that other formulas preceding this one do NOT provide any 
        % additional information on the satisfaction time of this formula.
        neg_prefix = 0;
    case 0
        formu_index = 0;
        sat_time_hint = -1;
        neg_prefix = 0;
    otherwise
        fprintf(StSTL.fid, 'too many input arguments! Quit.\n');
        add_result = 0;
end
if ~isscalar(formu_index) || any(formu_index < 0)
    fprintf(StSTL.fid, 'Invalid formu_index. Quit.\n');
    add_result = 0;
end
if size(sat_time_hint,1) ~= 1
    fprintf(StSTL.fid, 'sat_time_hint should be a row! Quit.\n');
    add_result = 0;
end
if 0 == add_result
    return;
end

if formu_index > 0
    if StSTL.display == 1
        fprintf(StSTL.fid, ['In add_formula(): ',StSTL.formu_str{formu_index},...
            ', formu_index = ',num2str(formu_index),...
            ', sat_time_hint = ',num2str(sat_time_hint),...
            ', neg_prefix = ',num2str(neg_prefix),'\n']);
    end
    if ~strcmp(formula,StSTL.formu_str{formu_index})...
            || any(StSTL.formu_time{formu_index} ~= sat_time_hint)...
            || any(StSTL.formu_neg{formu_index} ~= neg_prefix)
        error('formu_index is inconsistent with the formula it points to.');
    end
else % formu_index == 0 occurs ONLY when users pass 0 to formu_index or do
     % not provide any value for it. The program NEVER sets formu_index = 0 
     % and then invoke add_formula(formula,formu_index,...).
     if StSTL.display == 1
         fprintf(StSTL.fid, ['In add_formula(): ',formula,' given by user',' with sat_time_hint = ',...
             num2str(sat_time_hint),'\n']);
     end
    [is_found,formu_index] = search_track_formula(formula,sat_time_hint,neg_prefix);
    if is_found
        fprintf(StSTL.fid, ['formula ',formula,' with sat_time_hint ',num2str(sat_time_hint),...
                ' has already been translated!\n\t'...
                'This is a formula given by users so we just return 0 ',...
                'and stop further translation of it.\n']);
        add_result = 0;
        return;
    end
end

MIP_cons_num_prev = StSTL.total_MIP_cons;
formulas_track_num_prev = StSTL.total_formu;
left_par = strfind(formula,'(');
if isempty(left_par)
    error('No ( found in the formula.');
elseif 1 == left_par(1)
    error('( found at the very beginning of the formula.');
end
neg_prefix = mod(neg_prefix, 2); % cancel the double negation

formu_type = strtrim(formula(1:(left_par(1) - 1)));
inner_formu = strtrim(formula((left_par(1) + 1):(end - 1)));
switch formu_type
    case 'Not' % negation, syntex: 'Not(f)'
        neg_prefix = neg_prefix + 1;
        add_result = add_neg(inner_formu,formu_index,sat_time_hint,neg_prefix);
    case 'Until' % until, syntex: 'Until(f1,f2,t_start,t_end)'
        add_result = add_until(inner_formu,formu_index,sat_time_hint,neg_prefix);
    case 'Weak' % until, syntex: 'Weak(f1,f2,t_start,t_end)'
        add_result = add_weak(inner_formu,formu_index,sat_time_hint,neg_prefix);
    case 'And' % and, syntex: 'And(f1,...,fm)'
        add_result = add_and(inner_formu,formu_index,sat_time_hint,neg_prefix);
    case 'Global' % always, syntex: 'Global(f,t_start,t_end)'
        add_result = add_always(inner_formu,formu_index,sat_time_hint,neg_prefix);
    case 'Or' % or, syntex: 'Or(f1,...,fm)'
        add_result = add_or(inner_formu,formu_index,sat_time_hint,neg_prefix);
    case 'Eventual' % eventually, syntex: 'Eventual(f,t_start,t_end)'
        add_result = add_eventual(inner_formu,formu_index,sat_time_hint,neg_prefix);
    case 'Imply' % imply, syntex: 'Imply(f1,f2)'
        add_result = add_imply(inner_formu,formu_index,sat_time_hint,neg_prefix);
    case 'T' % true, syntex: 'T()'
        if neg_prefix == 0
            StSTL.MIP_cons = [StSTL.MIP_cons, StSTL.formu_bin{formu_index} == 1];
            StSTL.total_MIP_cons = StSTL.total_MIP_cons + 1;
        else % neg_prefix == 1
            StSTL.MIP_cons = [StSTL.MIP_cons, StSTL.formu_bin{formu_index} == 0];
            StSTL.total_MIP_cons = StSTL.total_MIP_cons + 1;
        end
        add_result = 1;
    case 'F' % false, syntex: 'F()'
        if neg_prefix == 0
            StSTL.MIP_cons = [StSTL.MIP_cons, StSTL.formu_bin{formu_index} == 0];
            StSTL.total_MIP_cons = StSTL.total_MIP_cons + 1;
        else % neg_prefix == 1
            StSTL.MIP_cons = [StSTL.MIP_cons, StSTL.formu_bin{formu_index} == 1];
            StSTL.total_MIP_cons = StSTL.total_MIP_cons + 1;
        end
        add_result = 1;
    case 'AP' % atomic proposition, syntex: 'AP(n,t)' or 'AP(n)'
              % 'AP(n,t)': n is the index of this AP, t is the time when the AP holds
              % 'AP(n)': satisfaction time could be inferred from its preceding 
              %          formulas, i.e., this time is given by sat_time_hint
        add_result = add_AP(inner_formu,formu_index,sat_time_hint,neg_prefix);
    otherwise
        fprintf(StSTL.fid, ['Invalid sub formula ''',formula(1:(left_par(1) - 1)),''' detected. Quit.\n']);
        add_result = 0;
        return
end

if add_result
    add_result = formu_index;
else % add_result == 0
    for i = (formulas_track_num_prev + 1):StSTL.total_formu
        StSTL.formu_bin{i} = [];
    end
    StSTL.total_formu = formulas_track_num_prev;
    StSTL.MIP_cons = StSTL.MIP_cons(1:MIP_cons_num_prev);
    StSTL.total_MIP_cons = MIP_cons_num_prev;
end

end

