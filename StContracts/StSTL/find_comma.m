function [comma_index,comma_num] = find_comma(input_str)
%FIND_COMMA Find locations of commas that separates the parameters in the 
% input string.
%
%   Written by Jiwei Li

n = length(input_str);
comma_index = zeros(1,n);
comma_num = 0;
left_par = strfind(input_str,'(');
right_par = strfind(input_str,')');
for i = 1:n
    if sum(left_par <= i) == sum(right_par <= i) && strcmp(input_str(i),',')
        comma_num = comma_num + 1;
        comma_index(comma_num) = i;
    end
end
comma_index = comma_index(1:comma_num);

end

