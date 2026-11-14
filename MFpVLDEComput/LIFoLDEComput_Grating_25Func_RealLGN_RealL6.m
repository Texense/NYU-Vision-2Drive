%% Precomputing on Planes: Give input, compute firing rates as functions of inputs
% Output: save([SaveFolder 'MFpV_LDE_' num2str(InputCtgr) '.mat'],...
%              'f_EnIOut','meanVs','SteadyIndicate','FailureIndicate','L4ERcrd','L4IRcrd')
% Input:  Angle:ranging from 0-90 deg, although we only use 0 7.5 15 22.5
%         LGNctgr, L6ctgr: ranging from 1-4
%         TF: 4, 10, 16 Hz; SF: 1.5, 2.5, 3.5
%% NOTE: Now we are computing for binocular, and has to mix BG and drive inputs
%         LGNctgr, L6ctgr: ranging from 1-5!! 5 means background!
%         L6Mapctgr: 1 for linear, 2 for cosine
%         FlagLargeDom: 1 for small domain, 2 for large domain
% Version 1: L6 range switched to [10 60] Hz per L6 neuron
% Version 3: Starting to use REAL LGN spike trains!
% Version 4: L6 now depends on L4!!! So L6ctgr is now 1: 23, corresponding
% to FL6 = 6:72 Hz;
% Zhuo-Cheng Xiao 10/20/2023

function [] = LIFoLDEComput_Grating_25Func_RealLGN_RealL6(Angle, LGNctgr, L6ctgr, lgnTF, lgnSF, varargin)
CurrentFolder = pwd;
disp(CurrentFolder)
%FigurePath = [CurrentFolder '/Figures'];
addpath(CurrentFolder)
addpath([CurrentFolder '/Utils'])
addpath([CurrentFolder '/Data'])
SaveToFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/25Function_binocular_realLGN/'];
addpath(SaveToFolder)
DataFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/'];
addpath(DataFolder)
DataFolder1 = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/'];
DataFolder2 = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3LGNSpikeData/'];
addpath(DataFolder1)
addpath(DataFolder2)
% L6Mapctgr determines the mapping of input to L6
% Likely to use L6Mapctgr = 2;
if length(varargin)<1
    L6Mapctgr = 1;
    ExpTex = 'Linear';
else
    L6Mapctgr = varargin{1};
    switch L6Mapctgr
        case 1
            ExpTex = 'Linear';
        case 2
            ExpTex = 'Cosine';
        case 3
            ExpTex = 'Final';   
        case 4
            ExpTex = 'CtrlL4';      
    end
end
% FlagLargeDom determines the domain
if length(varargin)<2
    FlagLargeDom = 1;
else
    FlagLargeDom = varargin{2};
end

if length(varargin)<3 % contrast parameters 
    C = 100
else
    C = varargin{3} %
end

DomStr = {'S','L','Ler'};

L6up = 120; L6low = 3; %[10 54; 12 50]

DataPt = 'V4D2';
SaveStr = 'LGN';
LGN4DataAll = cell(13,1); LGN6DataAll = cell(13,1);
switch C
    case 100
        LGNStr = sprintf('LGNc%d_SF%.1f_TF%d',LGNctgr,lgnSF, lgnTF);
        LGN1Data = load(sprintf('LGN_Cell1_Row0.12_Col0.15_deg0.0_SF%.1f_TF%d_TSimu25.mat',...
            lgnSF, lgnTF),'SpTimeMix'); % 1-cell config doesn't care about orientation
        LGN2Data = load(sprintf('LGN_Cell2_Row0.12_Col0.15_deg90.0_SF%.1f_TF%d_TSimu25.mat',...
            lgnSF, lgnTF),'SpTimeMix'); % 2-cell for C only; ortho

        AngAll = 0:7.5:90; % all simulated LGN angles
        for AngId = 1:length(AngAll)
            LGN4DataAll{AngId} = load(sprintf('LGN_Cell4_Row0.14_Col0.15_deg%.1f_SF%.1f_TF%d_TSimu25.mat',...
                AngAll(AngId),lgnSF, lgnTF),'SpTimeMix');
            % For 4-cell, rowdist is 0.14
            LGN6DataAll{AngId} = load(sprintf('LGN_Cell6_Row0.12_Col0.15_deg%.1f_SF%.1f_TF%d_TSimu25.mat',...
                AngAll(AngId),lgnSF, lgnTF),'SpTimeMix');
            % For 6-cell, rowdist is 0.12
        end
    otherwise
        LGNStr = sprintf('LGNc%d_SF%.1f_TF%d_Contr%d',LGNctgr,lgnSF, lgnTF, C);
        LGN1Data = load(sprintf('LGN_Contr%d_Cell1_Row0.12_Col0.15_deg0.0_SF%.1f_TF%d_TSimu25.mat',...
            C, lgnSF, lgnTF),'SpTimeMix'); % 1-cell config doesn't care about orientation
        LGN2Data = load(sprintf('LGN_Contr%d_Cell2_Row0.12_Col0.15_deg90.0_SF%.1f_TF%d_TSimu25.mat',...
            C, lgnSF, lgnTF),'SpTimeMix'); % 2-cell for C only; ortho

        AngAll = 0:7.5:90; % all simulated LGN angles
        for AngId = 1:length(AngAll)
            LGN4DataAll{AngId} = load(sprintf('LGN_Contr%d_Cell4_Row0.14_Col0.15_deg%.1f_SF%.1f_TF%d_TSimu25.mat',...
                C,AngAll(AngId),lgnSF, lgnTF),'SpTimeMix');
            % For 4-cell, rowdist is 0.14
            LGN6DataAll{AngId} = load(sprintf('LGN_Contr%d_Cell6_Row0.12_Col0.15_deg%.1f_SF%.1f_TF%d_TSimu25.mat',...
                C,AngAll(AngId),lgnSF, lgnTF),'SpTimeMix');
            % For 6-cell, rowdist is 0.12
        end
end

%% Load LGN spiking data!
L6Str  = sprintf('L6c%d_uplow%d-%d_%s',L6ctgr, L6up,L6low, ExpTex);
FileStr = sprintf(...
    'Paper3_LIFLib_%s_Ang%.1f_%s_%s_%s.mat',...
              DataPt, Angle, LGNStr,L6Str,DomStr{FlagLargeDom})
if isfile([SaveToFolder FileStr])
    disp('Result data file exists. exiting...')
    return
else
    disp('Result data file missing. running the rest of the script...')
end

%% Load sample data for network dynamics; L4 network parameters

S = load(sprintf('AllMFPixPara_Paper2TuneFig1%s.mat',DataPt));
% For part one: Preparing...
C_SS_Pixel_Us = S.C_SS_Pixel_Us;
C_CS_Pixel_Us = S.C_CS_Pixel_Us;
C_IS_Pixel_Us = S.C_IS_Pixel_Us;
C_SC_Pixel_Us = S.C_SC_Pixel_Us;
C_CC_Pixel_Us = S.C_CC_Pixel_Us;
C_IC_Pixel_Us = S.C_IC_Pixel_Us;
C_SI_Pixel_Us = S.C_SI_Pixel_Us;
C_CI_Pixel_Us = S.C_CI_Pixel_Us;
C_II_Pixel_Us = S.C_II_Pixel_Us;
    %N_Slgn = S.N_Slgn; N_Clgn = S.N_Clgn; N_Ilgn = S.N_Ilgn;
NS_L6 = S.NS_L6; NC_L6 = S.NC_L6; NI_L6 = S.NI_L6;
    %L6Ord_F  = S.L6Ord_F;
N_HC = S.N_HC; NPixX = S.NPixX; NPixY = S.NPixY;
FrSPixVec = S.FrSPixVec;
FrCPixVec = S.FrCPixVec;
FrIPixVec = S.FrIPixVec;
% For part two: parfor...
S_EE=S.S_EE; S_EI=S.S_EI; S_IE=S.S_IE; S_II=S.S_II; p_EEFail=S.p_EEFail;
S_EL6=S.S_EL6; S_IL6=S.S_IL6;
S_amb=S.S_amb; rS_amb=S.rS_amb; rC_amb=S.rC_amb; rI_amb=S.rI_amb;
S_Elgn=S.S_Elgn; 
% CHANGING SILGN!!
S_Ilgn=S.S_Ilgn;% * 1.1;
gL_E=S.gL_E; gL_I=S.gL_I; Ve=S.Ve; Vi=S.Vi;  tau_ref=S.tau_ref;

tau_ampa_R=S.tau_ampa_R; tau_ampa_D=S.tau_ampa_D;
tau_nmda_R=S.tau_nmda_R; tau_nmda_D=S.tau_nmda_D;
tau_gaba_R=S.tau_gaba_R; tau_gaba_D=S.tau_gaba_D;
rhoE_ampa=S.rhoE_ampa; rhoE_nmda=S.rhoE_nmda;
rhoI_ampa=S.rhoI_ampa; rhoI_nmda=S.rhoI_nmda;
%LGNFreq = S.LGNFreq;
clear S

%% Prepare for a canonical pixel
Angles_4Input = Angle + [0 45 90 135];
%lgn_SOnOff = [45+abs(mod(Angles_4Input,180)-90)/2;
%    45-abs(mod(Angles_4Input,180)-90)/2]/1e3;
% redefine low-up bounds for L6: [10 54]
NL6S = NS_L6; NL6C = NC_L6; NL6I = NI_L6;

if L6Mapctgr == 1
    FL6_Angle1 = ((abs(mod(Angles_4Input,180)-90)/90)      *(L6up-L6low)+L6low) /1e3; % get L6 frs
    
elseif L6Mapctgr == 2
    FL6_Angle1 = ((cosd(abs(mod(Angles_4Input,180))*2)+1)/2*(L6up-L6low)+L6low) /1e3;
elseif L6Mapctgr == 3
    ScaledLGN = (cosd(abs(mod(Angles_4Input,180))*2)+1)/2;
    FL6_Angle1 = (L6CurveFinalize(ScaledLGN) * (L6up-L6low)+L6low) /1e3;
elseif L6Mapctgr == 4
    FL6_Angle1 = (L6low:3:L6up) * 1e-3;
else
    
    error("illigal L6 mapping.")
end
%% NOTE: Now we are computing for binocular, and has to mix BG and drive
if L6Mapctgr<4
    FL6_Angle1 = [FL6_Angle1, 0.007]; % background L6 frs
elseif L6Mapctgr == 4 
    % When L4E is large enough, we take L6 upper bound, then other L6 rates
    % are useless. Once that happens we will directly stop the LDE
    % simulations.
    StopFlag = (FL6_Angle1(L6ctgr) ~= max(FL6_Angle1, [], 'all'));
end
%lgn_SOnOff = [lgn_SOnOff, [0.02;0.02]];
%lgn_COnOff = [0.045*ones(2,4),[0.02;0.02]];
%lgn_IOnOff = [0.045*ones(1,4),0.02];

rL6SU = NL6S*FL6_Angle1(L6ctgr); %rL6EU = rL6E(InputCtgr);
rL6CU = NL6C*FL6_Angle1(L6ctgr);
rL6IU = NL6I*FL6_Angle1(L6ctgr);

Ilgn_iduse = 7; % back from 90, 6 different angles
if LGNctgr == 5 % BG LGN
    lgn_S = 0.02; % spikes/ms
    lgn_C = 0.02;
    lgn_I = 0.02;
else
    % C gets 1 and 2-cell config
    lgn_C = cell(2,1); 
    lgn_C{1} = sort(LGN1Data.SpTimeMix); % dont forget: SpTimeMix is UNSORTED data
    lgn_C{2} = sort(LGN2Data.SpTimeMix); 
    % S gets 4 and 6-cell config
    AngleNow = Angles_4Input(LGNctgr); % this is a number in 0:7.5:(90 + 135)
    S_configId = floor(mod(AngleNow,180)/7.5) + 1; 
    if S_configId > 13 % anyone from 0:7.5:90
        S_configId = 24 - (S_configId - 1) + 1 ; 
    end
    lgn_S = cell(2,1); 
    lgn_S{1} = sort(LGN4DataAll{S_configId}.SpTimeMix); 
    lgn_S{2} = sort(LGN6DataAll{S_configId}.SpTimeMix);
    % I gets randomly from 4 configs; using 45-90 deg only
       % I suspect Fr can be too high for 45? >80Hz/cell for peaks
    lgn_I = cell(Ilgn_iduse,1);
    for angId = 1:Ilgn_iduse
        lgn_I{angId} = sort(LGN4DataAll{end - angId + 1}.SpTimeMix);
    end
end

% drive: use REAL LGN!
if iscell(lgn_S) 
    disp('Drive regime. Use presimulated LGN input')
end

% Determine L4 Input from a range
L4SE = zeros(N_HC*NPixX*N_HC*NPixY,1);
L4SI = zeros(N_HC*NPixX*N_HC*NPixY,1);
L4CE = zeros(N_HC*NPixX*N_HC*NPixY,1);
L4CI = zeros(N_HC*NPixX*N_HC*NPixY,1);
L4IE = zeros(N_HC*NPixX*N_HC*NPixY,1);
L4II = zeros(N_HC*NPixX*N_HC*NPixY,1);
for PInd = 1:N_HC*NPixX*N_HC*NPixY
    L4SE(PInd) = (C_SS_Pixel_Us(PInd,:)*FrSPixVec          + C_SC_Pixel_Us(PInd,:)*FrCPixVec);
    L4SI(PInd) =  C_SI_Pixel_Us(PInd,:)*FrIPixVec ;
    L4CE(PInd) = (C_CS_Pixel_Us(PInd,:)*FrSPixVec          + C_CC_Pixel_Us(PInd,:)*FrCPixVec);
    L4CI(PInd) =  C_CI_Pixel_Us(PInd,:)*FrIPixVec ;
    L4IE(PInd) = (C_IS_Pixel_Us(PInd,:)*FrSPixVec          + C_IC_Pixel_Us(PInd,:)*FrCPixVec);
    L4II(PInd) =  C_II_Pixel_Us(PInd,:)*FrIPixVec ;
end
L4Eall = L4SE+L4CE+L4IE; L4Iall = L4SI+L4CI+L4II;
L4SEp = mean(L4SE./L4Eall);L4CEp = mean(L4CE./L4Eall);L4IEp = mean(L4IE./L4Eall);
L4SIp = mean(L4SI./L4Iall);L4CIp = mean(L4CI./L4Iall);L4IIp = mean(L4II./L4Iall);
LineFit = polyfit(L4Eall,L4Iall,1);
YRange = L4Iall - (LineFit(1)*L4Eall+LineFit(2)); % We plan to use 2 times of the range
Bdry = floor(max(abs(YRange))/100)*100;
% domain time scale: 160000 cost 3hrs:
switch FlagLargeDom
    case 1
        L4ERange = 0:100:ceil(max(L4Eall)*1.5/100)*100;
        L4IDiffRange = -20*Bdry:100:20*Bdry;
        HyperPara = {20*1e3};
    case 2
        L4ERange = 0:600:ceil(max(L4Eall)*12/100)*100;
        L4IDiffRange = -120*Bdry:600:60*Bdry;
        HyperPara = {20*1e3};
    case 3 % remember: can't do too much computation here. Firing rates could be too high to run
        L4ERange = 0:4000:ceil(max(L4Eall)*50/100)*100;
        L4IDiffRange = -500*Bdry:4000:500*Bdry;
        HyperPara = {20*1e3}; % let's keep Larger simulation shorter in time
end

%% Start parallel computation
cluster = gcp('nocreate');
if isempty(cluster)
    cluster = parpool("local",[4,128]);
end
addAttachedFiles(cluster, {'AllMFPixPara_Paper2TuneFig1V4D2.mat'});

a0 = length(L4ERange)*length(L4IDiffRange);
f_EnIOut = cell(a0,1);
% meanVs = cell(a0,1);
% SteadyIndicate = zeros(a0,1);
% FailureIndicate = zeros(a0,1);
L4ERcrd = zeros(a0,1);
L4IRcrd = zeros(a0,1);

parfor  LDEInd = 1:a0
    L4EInd = ceil(LDEInd/length(L4IDiffRange));
    L4IDiffInd = mod(LDEInd,length(L4IDiffRange));
    if L4IDiffInd == 0
        L4IDiffInd = length(L4IDiffRange);
    end
    L4EU = L4ERange(L4EInd);
    L4IU = LineFit(1)*L4EU+LineFit(2) + L4IDiffRange(L4IDiffInd);
    L4ERcrd(LDEInd) = L4EU;
    L4IRcrd(LDEInd) = L4IU;

    if (StopFlag && L4EU > max(L4Eall)*8)
        % when both 1. L6 is not the maximum, and 2. L4E is too large happens
        % Simply drop the simulation
        continue
        %disp('L6 is not max, and L4E too large')
        %f_EnIOut{LDEInd} = nan;
    elseif min(L4EU,L4IU)<0
        continue
    else
        %Distribute L4Input
        L4SEU = L4SEp*L4EU; L4CEU = L4CEp*L4EU; L4IEU = L4IEp*L4EU;
        L4SIU = L4SIp*L4IU; L4CIU = L4CIp*L4IU; L4IIU = L4IIp*L4IU;

        tic
        [f_EnIOut{LDEInd}]...
            = LIFo_SinglePixel_RealLGN(...
            ...% MF Parameters
            lgnTF, L4SEU,L4SIU, L4CEU,L4CIU, L4IEU,L4IIU,... %3
            S_EE,S_EI,S_IE,S_II,p_EEFail,... %5
            S_EL6,S_IL6,rL6SU,rL6CU,rL6IU,S_amb,rS_amb,rC_amb,rI_amb,...%7 L6 Amb
            lgn_S, lgn_C,lgn_I,...%N_Slgn,N_Clgn,N_Ilgn, ...
            S_Elgn,S_Ilgn,... %7
            ...% Below are LIF details
            gL_E,gL_I,Ve,Vi, tau_ref,... %5
            tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,... %7
            rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,... %4
            HyperPara); % if varagin non empty, we only export the last state
        time1 = toc;
        fprintf('tLIF=%.2f\n',time1)
    end
end

% Save MFpV Data
%CurrentFolder = pwd;
%SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/'];

save([SaveToFolder FileStr],...
    'f_EnIOut','L4ERcrd','L4IRcrd')
end