function contract = make_contract(A, G)
%SET_CONTRACT Make a contract using the assumption and the guarantee.
%   input: A - a string of StSTL representing the assumption
%          G - a string of StSTL representing the guarantee
%   output: contract - a structure containing the assumption and the
%                      guarantee
%
% Written by Jiwei Li

global MODEL;

contract = [];
contract.sys = MODEL.type;                        % record the system over which the contract is interpreted
contract.A = A;
contract.orig_G = G;
contract.G = ['Or(Not(',A,'),',G,')'];

end

