function add_result = AP_to_suffi_MIP_MarkovJump(AP_tag,k,formu_index,neg_prefix)
%AP_TO_MILP Translate an atomic proposition (AP) into equivalent MILP
% input: AP_tag - an integer (1,2,...) to index a particular AP
%        k      - the satisfaction time (0,1,2,...) of that AP
%        formu_index - the index of this AP stored in the StSTL encoding 
%                      quadruple (formu_str, formu_time, formu_neg, formu_bin)
%        neg_prefix  - a boolean value indicating whether this is a negation
%                      of AP or not
% Written by Jiwei Li

% We just call the equivalent encoding method.
add_result = AP_to_equiv_MIP_MarkovJump(AP_tag,k,formu_index,neg_prefix);

end

