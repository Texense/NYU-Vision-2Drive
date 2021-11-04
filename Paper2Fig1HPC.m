%% Figure1: Super fine contours HPC
%% Script for HPC:
% Fix S_EE, Run for different S_ILGN and r_IL6, each for one panel
% PanelInd: 1~PanelNum1*PanelNum2
% S_ElgnInd: Determine S_Elgn. Now should be 1,2,3
% S_IlgnInd:
%% Inds
S_EEInd = 3;
S_IIInd = 2;
S_ElgnInd = 2;
S_IlgnInd = 2;
rI_L6Ind = 2;

%% A Rough Estimation Contour for S_EI and S_IE
% first, setup connctivity map
CurrentFolder = pwd;
%FigurePath = [CurrentFolder '/Figures'];
addpath(CurrentFolder)
addpath([CurrentFolder '/Utils'])
addpath([CurrentFolder '/Data'])
SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/'];
addpath(SaveFolder)
DataFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/'];
addpath(DataFolder)

N_HC = 3;
% Number of E and I neurons
n_S_HC = 45; n_C_HC = 30; n_I_HC = 31; % per side of HC
N_S = n_S_HC^2 * N_HC^2; % neuron numbers In all
N_C = n_C_HC^2 * N_HC^2; % neuron numbers In all
N_I = n_I_HC^2 * N_HC^2;
N_E = N_S+N_C; CplxR = N_C/N_E;
% Grid sizes of E and I neurons;
Size_HC = 0.500; % in mm;
Size_S = Size_HC/n_S_HC; Size_C = Size_HC/n_C_HC; Size_I = Size_HC/n_I_HC;
% Projection: SD of distances
SD_E = 0.2/sqrt(2); SD_I = 0.125/sqrt(2);
Dist_LB = 0.36; % ignore the connection probability of dist>0.3mm
% Peak probability of projection
Peak_EE = 0.15; Peak_I = 0.6;

% spatial indexes of E and I neurons
[NnS.X,NnS.Y] = V1Field_Generation(N_HC,1:N_S,'e',n_S_HC,n_I_HC);
[NnC.X,NnC.Y] = V1Field_Generation(N_HC,1:N_C,'e',n_C_HC,n_I_HC);
[NnI.X,NnI.Y] = V1Field_Generation(N_HC,1:N_I,'i');

N_EE = 190; N_EI = 85; %*0.75
N_IE = 844; N_II = 84; %*0.75 Plan A:Original

CplxNEIncr = 255/N_EE; % Was 250 for 071021 simulation
EcplxInd = ismember(1:N_E, N_S+1:N_E); 

N_SS = N_EE * (1-CplxR);            N_SC = N_EE * (CplxR); 
N_CS = N_EE * (1-CplxR)*CplxNEIncr; N_CC = N_EE * (CplxR)*CplxNEIncr;
N_SI = N_EI;                        N_CI = N_EI; 
N_IS = N_IE * (1-CplxR);            N_IC = N_IE * (CplxR); 

% load connectivity from saved data file
N_PreSynPix = [N_SS, N_CS, N_IS;
               N_SC, N_CC, N_IC;
               N_SI, N_CI, N_II];
% S = load('ConnPixel_Cconst.mat');
% C_SS_Pixel_Us = S.C_SS_Pixel_Us;C_CS_Pixel_Us = S.C_CS_Pixel_Us;C_IS_Pixel_Us = S.C_IS_Pixel_Us;
% C_SC_Pixel_Us = S.C_SC_Pixel_Us;C_CC_Pixel_Us = S.C_CC_Pixel_Us;C_IC_Pixel_Us = S.C_IC_Pixel_Us;
% C_SI_Pixel_Us = S.C_SI_Pixel_Us;C_CI_Pixel_Us = S.C_CI_Pixel_Us;C_II_Pixel_Us = S.C_II_Pixel_Us;
%% Variables and Parameters
%independent parameters
S_amb = 0.01; rS_amb = 0.6; rC_amb = 0.75; rI_amb = 0.435;% was 0.5 for for 071021 simulation
%rE_amb = [rS_amb*ones(N_S,1);rC_amb*ones(N_C,1)];
 
tau_ampa_R = 0.5; tau_ampa_D = 3;
tau_nmda_R = 2; tau_nmda_D = 80;
tau_gaba_R = 0.5; tau_gaba_D = 5;
tau_ref = 2; % time unit is ms
p_EEFail = 0.2; 

gL_E = 1/20;  Ve = 14/3; rhoE_ampa = 0.8; rhoE_nmda = 0.2;
gL_I = 1/15;  Vi = -2/3; rhoI_ampa = 0.67;rhoI_nmda = 0.33;

% SEE and SII
S_EEtest = [0.018 0.021 0.024 0.027 0.030]; 
S_IItest = [0.08  0.12  0.16  0.20];
S_EE = S_EEtest(S_EEInd);
S_II = S_IItest(S_IIInd);%oefficient of variation

% Replace S_EI and SIE by testing values
GridNum1 = 160*2; %160
GridNum2 = 160*2; %160
S_EI_Mtp = [0.8, 2.0]; % of S_EE
S_IE_Mtp = [0.1, 0.25]; % of S_II
S_EItest = linspace(S_EI_Mtp(1),S_EI_Mtp(2),GridNum1)*S_EE;
S_IEtest = linspace(S_IE_Mtp(1),S_IE_Mtp(2),GridNum2)*S_II;%*S_EE; I only specify a vecter length here

% lgn
S_Elgntest = [1.5 2 2.5 3.0]*S_EE;
S_Elgn = S_Elgntest(S_ElgnInd);
S_Ilgn_Mtp = [1.5 2 2.5 3]; % of S_Elgn
S_Ilgntest = S_Ilgn_Mtp * S_Elgn;
S_Ilgn = S_Ilgntest(S_IlgnInd);% number ofLGN cells
N_Slgn = 4.75; N_Clgn = 1.5; N_Ilgn = 4.5;
lgn_I = 0.02; 
lgn_S = [0.02;0.02]; lgn_C = lgn_S;

% L6
S_EL6 = 1/3*S_EE; % S_IL6 = 1/3*S_IEOneTime; Now S_IL6 is porp to S_IE
S_IL6test = 1/3 * S_IEtest;

rL6_One = 0.007;
NS_L6 = 45; NC_L6 = 55; 
NI_L6_Mtp  = [1.5 3 4.5 6]; % of rE_L6
NI_L6 = NI_L6_Mtp(rI_L6Ind)*50; 
rS_L6 = NS_L6*rL6_One;
rC_L6 = NC_L6*rL6_One;
rI_L6 = NI_L6*rL6_One;
%rE_L6 = (rS_L6*double(~EcplxInd) + rC_L6*double(EcplxInd))';   

% creat a 10-hr parallel
cluster = gcp('nocreate');
if isempty(cluster)
    cluster = parpool([4 64]);
%    cluster.IdleTimeout = 1200;
end
%cluster = parpool([4 128]);
%% MF estimation:
a0 = length(S_EItest)*length(S_IEtest);
f_EnIOut = cell(a0,1);
meanVs = cell(a0,1);
loopCount = zeros(a0,1);
SteadyIndicate = zeros(a0,1);
FailureIndicate = zeros(a0,1);

% We are using the 0.2 threshold here... see how it goes 
HyperPara = {'Traj',50,50,0.8,10000,'thre',0};
parfor MFVInd = 1:a0
        SEIInd = ceil(MFVInd/length(S_EItest));
        SIEInd = mod(MFVInd,length(S_EItest));
        if SIEInd == 0
            SIEInd = length(S_EItest);
        end
        S_EI = S_EItest(SEIInd);
        S_IE = S_IEtest(SIEInd);
        S_IL6 = S_IL6test(SIEInd);
        
        % Add lines boundaries
        LineL1 = polyfit([0.1  0.2 ],[0.9 0.8],1); % S_IEMtp first, second S_EIMtp. Those numbers are multipliers of S_II and S_EE
        LineL2 = polyfit([0.06 0.28],[0.9 0.4],1);
        LineU1 = polyfit([0.1  0.3 ],[2.5 2.2 ],1); % LineU1 = polyfit([0.1  0.3 ],[2.5 0.8],1);

        if (S_EI/S_EE<=S_IE/S_II*LineL1(1)+LineL1(2) || S_EI/S_EE<=S_IE/S_II*LineL2(1)+LineL2(2) )
            disp(['S_IE = ' num2str(S_IE/S_II,'%.3f') '*S_II, S_EI = ' num2str(S_EI/S_EE,'%.3f') '*S_EE; Fr may be too high, break...'])
            continue
        end
        if (S_EI/S_EE>=S_IE/S_II*LineU1(1)+LineU1(2) )
            disp(['S_IE = ' num2str(S_IE/S_II,'%.3f') '*S_II, S_EI = ' num2str(S_EI/S_EE,'%.3f') '*S_EE; Fr may be too low, break...'])
            continue
        end
        
        tic
       [f_EnIOut{MFVInd},meanVs{MFVInd},loopCount(MFVInd),...
        SteadyIndicate(MFVInd),FailureIndicate(MFVInd)]...
           = MFpV_SinglePixel(...% MF Parameters                     
                     N_PreSynPix, 0,0, 0,0, 0,0,... %3 
                     S_EE,S_EI,S_IE,S_II,p_EEFail,... %5
                     S_EL6,S_IL6,rS_L6,rC_L6,rI_L6,S_amb,rS_amb,rC_amb,rI_amb,...%7 L6 Amb                                   
                     lgn_S, lgn_C,lgn_I,N_Slgn,N_Clgn,N_Ilgn, S_Elgn,S_Ilgn,... %7
                     gL_E,gL_I,Ve,Vi, tau_ref,... %5
                     ...% Below are LIF details
                     tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,... %7
                     rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,... %4
                     HyperPara);
        toc      
end
f_EnIOut = reshape(f_EnIOut,length(S_EItest), length(S_IEtest));
meanVs = reshape(meanVs,length(S_EItest), length(S_IEtest));
loopCount = reshape(loopCount,length(S_EItest), length(S_IEtest));
SteadyIndicate = reshape(SteadyIndicate,length(S_EItest), length(S_IEtest));
FailureIndicate = reshape(FailureIndicate,length(S_EItest), length(S_IEtest));

% save data
%Trajs = struct('Fr_NoFixTraj', Fr_NoFixTraj, 'mV_NoFixTraj',mV_NoFixTraj);
ContourData_PP2 = ws2struct();
% add important info to the end of filename
% CommentString = sprintf('_S_EE=%.3f_S_II=%.2f_S_Elgn=%.3f_7D_HPC_S_IlgnInd%d_rI_L6Ind%d',S_EE,S_II,S_Elgn,S_IlgnInd,rI_L6Ind);
save([SaveFolder 'Paper2Figure1_Data.mat'],'ContourData_PP2')