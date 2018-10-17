% vim:tabstop=4 expandtab syntax=tex:
% This is nih.cls by Alan Shields, May 2003
% email: Alan-Shields2omrf.ouhsc.edu
% Heavily based upon (read: copied almost exactly from)
%    nih.sty by Bruce R. Donald and Matthew L. Fidler
% Modified to be used as a DoD style for Authorea
% The DOD wants 12-point Times New Roman 1 inch margins. Numbered Pages.

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{dod-blank}[2005/05/24 NIH PHS 398 as of November 06]

% includes needed for preliminary code
\RequirePackage{ifthen}

\pagestyle{empty}


% Preliminary code
\newcommand{\nih@kk}{~}

\newboolean{nih@blank}
\setboolean{nih@blank}{true}% not strictly necessary, but let's be clear about it

% Options
%%%% Changed by M A Lewis, Ph.D. (mal11 at alumni.cwru.edu)
%%%% NIH suggests Helvetica or Arial 12pt. Use Helvetica Postscript fonts for 12pt also.
%\DeclareOption{12pt}{\AtEndOfClass{\RequirePackage{helvet}\renewcommand{\familydefault}{\sfdefault}}}
\DeclareOption{12pt}{\AtEndOfClass{\RequirePackage{times}}}
%\DeclareOption{12pt}{\AtEndOfClass{\RequirePackage{arial}}}
\DeclareOption{11pt}{\AtEndOfClass{\RequirePackage{helvet}\renewcommand{\familydefault}{\sfdefault}}}
\DeclareOption{nihblank}{\setboolean{nih@blank}{true}}
\DeclareOption{kk}{\renewcommand{\nih@kk}{\small KK}}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax

% The class we're overwriting
\LoadClassWithOptions{article}


% Begin Requirements
%%%% Changed by M A Lewis, Ph.D. (mal11 at alumni.cwru.edu)
%%%% PHS 398 allows 0.5in magins everywhere. Simplify page layout using geometry package.
%\RequirePackage{fullpage}

%% Page Margins
%% Use standard paper size (8 ½" x 11).
%% Use at least one-half inch margins (top, bottom, left, and right) for all pages. 
%  Leaves enough room on all margins:

% 0.5 inch top
%\RequirePackage[letterpaper,left=0.5in,top=0.5in,bottom=0.575in,right=0.55in,nohead,nofoot]{geometry} 

% 1 inch margins
\RequirePackage[letterpaper,left=1.0in,top=1.0in,bottom=1.0in,right=1.0in,nohead]{geometry} 



% 0.45 inch top
%\RequirePackage[letterpaper,left=0.5in,top=0.45in,bottom=0.575in,right=0.55in,nohead,nofoot]{geometry} 

% Ideal but Doesn't leave enough room on some margins:
%\RequirePackage[letterpaper,left=0.5in,top=0.5in,bottom=0.5in,right=0.5in,nohead,nofoot]{geometry} 

% the command below simply deletes the headers and footers and makes
% the geometry exactly like the paper grant application:
%\RequirePackage[letterpaper,margin=0.5in,includeheadfoot]{geometry}
\RequirePackage{fancyhdr}
\RequirePackage{amsmath}
\pagestyle{plain}


%%%% More code
% preamble stuff

\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0.75pt}

%%%% Changed by M A Lewis, Ph.D. (mal11 at alumni.cwru.edu)
%%%% Simplify page layout by using geometry package above.
% page dimensions (note: assumes 8.5x11)
%\setlength{\oddsidemargin}{31pt}
%\setlength{\textwidth}{8.5in}
%\addtolength{\textheight}{0in} % 0.5in margins on both sides
%\addtolength{\textwidth}{-1.1in}
%\setlength{\oddsidemargin}{-1in}
%\addtolength{\oddsidemargin}{0.505in}
%\setlength{\evensidemargin}{\oddsidemargin}
%\addtolength{\textheight}{0.2in}
%\addtolength{\topmargin}{-0.2in}
%\renewcommand{\baselinestretch}{.9}
%\headwidth=\textwidth

% \addtolength{\headheight}{2.5pt}
\addtolength{\headheight}{0pt}

% rename the bibliography section
%\AtBeginDocument{\renewcommand{\refname}{Literature~Cited}}
\AtBeginDocument{\renewcommand{\refname}{Bibliography \& References~Cited}}
%FIXME: something is going on with the bibliography style. Dunno what.
