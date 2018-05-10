% Currently SCAnS can handle three types of systems:
%       1. Linear systems with control-dependent and additive Gaussian noise (referred to as GaussLin)
%       2. Markovian jump linear systems (referred to as MarkovJump)
%       3. Deterministic linear systems with output matrices containing Gaussian noises (referred to as GaussOut)
% We translate atomic propositions (APs, which are chance constraints) of 
% these two system types into MIP constraints. The system models, APs, and 
% AP translations are given in the folders
%       MODEL_and_AP\GaussLin 
%       MODEL_and_AP\MarkovJump
% For a new system type and/or for new chance constraints (APs), users need  
% to write their own translation files that turn APs into MIP constraints.
%
% Jiwei Li and Pierluigi Nuzzo

close all;
clear all;
clc; 

global to_add;
currentFolder = pwd;
to_add = {[currentFolder,'\StSTL'],...
    [currentFolder,'\Contract_Operation'],...
    [currentFolder,'\MODEL_and_AP'],...
    [currentFolder,'\MODEL_and_AP\GaussLin'],...
    [currentFolder,'\MODEL_and_AP\MarkovJump']};
addpath(to_add{1}, to_add{2}, to_add{3}, to_add{4}, to_add{5});

%--------------------------------------------------------------------------
% Step 1: set the system model and atomic propositions. A global struct 
%         MODEL that records model parameters is defined. A global struct 
%         AP that records the atomic propositions is defined.
% Users should modify the file MODEL_XXX and AP_XXX to specify their own 
% model parameters and APs.

% run MODEL_GaussLin;
% run AP_GaussLin;

run MODEL_MarkovJump;  
run AP_MarkovJump;

% run MODEL_GaussOut;
% run AP_GaussOut;

%--------------------------------------------------------------------------
% Step 2: configure the encoding of StSTL. A global struct StSTL that 
%         records the configurations is defined.
% Users may not need to modify the function.

StSTL_config();

%--------------------------------------------------------------------------
% Step 3: make contracts
% Users give the assumption and the guarantee (not necessarily in the
% saturated form) in StSTL, then make_contract() will return a struct
% recording the contract in the saturated form.

assumption = 'And(AP(1,0),AP(2,0))';
guarantee = 'Eventual(Not(AP(3)),1,3)';
% guarantee = 'Eventual(Eventual(Not(AP(3)),1,3),0,5)';
% guarantee = 'Weak( Eventual(Eventual(Not(AP(3)),1,3),0,5), F(), 0, 4)';
C1 = make_contract(assumption, guarantee);

assumption = 'AP(4,0)';
guarantee = 'Global(Not(AP(5)),1,3)';
% guarantee = 'Eventual(Global(Not(AP(5)),1,3),0,5)';
% guarantee = 'Weak( Eventual(Global(Not(AP(5)),1,3),0,5), F(), 0, 4)';
C2 = make_contract(assumption, guarantee);

%--------------------------------------------------------------------------
% Step 4: check consistency and compatibility

check_compat(C1, 'equivalent');               % use the equivalent encoding to check the compatibility of C1
check_consis(C1, 'equivalent');                  % use the equivalent encoding to check the compatibility of C1

check_compat(C2, 'equivalent');               % use the equivalent encoding to check the consistency of C2
check_consis(C2, 'equivalent');                  % use the equivalent encoding to check the consistency of C2

check_refine(C1, C2, 'equivalent');             % use the equivalent encoding to check C2 refines C1, C2 should refine C1
check_refine(C2, C1, 'equivalent');             % use the equivalent encoding to check C1 refines C2, C1 should not refine C2

fprintf('---------------------------------------------------------\n')

check_compat(C1, 'suffi_and_neces');       % use the sufficient encoding and necessary encoding to check the compatibility of C1
check_consis(C1, 'suffi_and_neces');          % use the sufficient encoding and necessary encoding to check the consistency of C1

check_compat(C2, 'suffi_and_neces');       % use the sufficient encoding and necessary encoding to check the compatibility of C2
check_consis(C2, 'suffi_and_neces');          % use the sufficient encoding and necessary encoding to check the consistency of C2

check_refine(C1, C2, 'suffi_and_neces');     % use the sufficient encoding and necessary encoding to check C2 refines C1, C2 should refine C1
check_refine(C2, C1, 'suffi_and_neces');     % use the sufficient encoding and necessary encoding to check C1 refines C2, C1 should not refine C2

rmpath(to_add{1}, to_add{2}, to_add{3}, to_add{4}, to_add{5});


