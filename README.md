# SCAnS (Stochastic Contract-based Analysis and Synthesis)
SCAnS is a MATLAB ToolBox that can analyze and synthesis systems with probabilistic requirements. 
SCAnS is based on the research project described on the paper **"Stochastic Assume-Guarantee Contracts for Cyber-Physical System Design Under Probabilistic Requirements"** by Jiwei Li, Pierluigi Nuzzo, Alberto Sangiovanni-Vincentelli, Yugeng Xi, and Dewei Li. 
Online version is available on arXiv.org (https://arxiv.org/abs/1705.09316).

## Software Installation
To run SCAnS, installations of MATLAB, SCAnS itself, and two external optimization solvers - GUROBI and YALMIP - are necessary.

### Prerequisites
[MATLAB](https://www.mathworks.com/products/matlab.html)

### SCAnS Installation
[Clone or download SCAnS repository](https://github.com/chanwook128/SCAnS)

### GUROBI Installation
GUROBI is an optimization solver for mathematical programming. It is designed to exploit modern architectures and multi-core processors using the most advanced 
implementations of the latest algorithms. For SCAnS, GUROBI is used to solve mixed-integer linear programming (MILP) problems.
1. [Download and install GUROBI](http://www.gurobi.com/downloads/gurobi-optimizer) 
2. [Setup GUROBI for MATLAB](http://www.gurobi.com/documentation/7.5/quickstart_mac/matlab_setting_up_gurobi_f.html)

### YALMIP Installation
YALMIP is a MATLAB ToolBox for optimization modeling. YALMIP is compatible with GUROBI. For SCAnS, YALMIP will use GUROBI to solve mixed-integer programming (MIP) problems within MATLAB.   
1. [Download YALMIP](https://yalmip.github.io/download/)
2. [Add YALMIP directories to MATLAB path](https://yalmip.github.io/tutorial/installation/)

## Tutorial
[Tutorial](https://docs.google.com/document/d/1q9CrAZu_s-gSZm0IidqVB4v763PZR6Eue1En87biOEg/edit?usp=sharing)

## Authors
- **Chanwook Oh**, PhD Student, Department of Electrical Engineering, University of Southern California, chanwooo@usc.edu
- **Aashish Parthasarathy**, Master Student, Department of Electrical Engineering, University of Southern California, part785@usc.edu
- **Jiwei Li**, Department of Automation, Shanghai Jiao Tong University, adanos@126.com, {ygxi,dwli}@sjtu.edu.cn
- **Pierlugi Nuzzo**, Assistant Professor, Department of Electrical Engineering, University of Southern California, nuzzo@usc.edu

## Citations
- I. Gurobi Optimization, “Gurobi optimizer reference manual,” 2015. [Online]. Available: http://www.gurobi.com
- J. Lofberg, "YALMIP : a toolbox for modeling and optimization in MATLAB," 2004 IEEE International Conference on Robotics and Automation (IEEE Cat. No.04CH37508), Taipei, 2004, pp. 284-289.

## Acknowledgement
- Where we got funded from
