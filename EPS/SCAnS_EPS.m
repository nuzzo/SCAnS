% Main file for the Aircraft Electrical Power System case study in the
% paper
% Jiwei Li and Pierluigi Nuzzo

close all;
clear all;
clc; 

global to_add;
currentFolder = pwd;
to_add = {[currentFolder,'\StSTL'], [currentFolder,'\Contract_Operation'], ...
    [currentFolder,'\MODEL_and_AP'], [currentFolder,'\EPS_simulation']};
addpath(to_add{1}, to_add{2}, to_add{3}, to_add{4});

% Step 1: set the system model. A global struct SYS that records model 
%         parameters is defined.

run MODEL_EPS;

% Step 2: set atomic propositions. A global struct AP that records the 
%         atomic propositions is defined.

run AP_EPS;

% Step 3: configure the encoding of StSTL. A global struct StSTL that 
%         records the configurations is defined.

StSTL_config();

% Step 4: define contracts

global control_contract;
assumption = 'And(AP(14,0),AP(15,0),AP(16,0))';
guarantee = ['And(','Global(AP(1),1,20),',...
                    'Global(AP(2),1,20),',...
                    'Global(AP(7),0,20),',...
                    'Global(AP(8),0,20),',...
                    'Global(AP(9),0,20),',...
                    'Global(AP(10),0,20),',...
                    'Global(AP(11),0,20),',...
                    'Global(AP(12),0,20),',...
                    'Global(AP(13),0,20),',...
                    'Or(Not(AP(3,0)),Until(T(),AP(5),0,5)),',...
                    'Or(Not(AP(4,0)),Until(T(),AP(6),0,5))',')'];
control_contract = make_contract(assumption, guarantee);

% Step 5: check consistency and compatibility

% use sufficient encoding and necessary encoding to check the compatibility
check_compat(control_contract, 'suffi_and_neces');

% use sufficient encoding and necessary encoding to check the compatibility
check_consis(control_contract, 'suffi_and_neces');     

rmpath(to_add{1}, to_add{2}, to_add{3}, to_add{4});



