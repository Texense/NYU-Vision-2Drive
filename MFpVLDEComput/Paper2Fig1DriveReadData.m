%% Read drive data on HPC

%% 0: make dirs
CurrentFolder = pwd
%FigurePath = [CurrentFolder '/Figures'];
addpath(CurrentFolder)
addpath([CurrentFolder '/Utils'])
addpath([CurrentFolder '/Data'])
DataFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/'];
addpath(DataFolder)

load( 'DriveWkSp_SCSepa_Cconst_Conn.mat','CMatAll','EcplxInd');
% Get conn mats
C_EE_Fix_Bd = CMatAll.C_EE_Fix_Bd ;
C_EI_Fix_Bd = CMatAll.C_EI_Fix_Bd ;
C_IE_Fix_Bd = CMatAll.C_IE_Fix_Bd ;
C_II_Fix_Bd = CMatAll.C_II_Fix_Bd ;

C_SS_Fix_Bd = C_EE_Fix_Bd(~EcplxInd,~EcplxInd);
C_SC_Fix_Bd = C_EE_Fix_Bd(~EcplxInd,EcplxInd);
C_CS_Fix_Bd = C_EE_Fix_Bd(EcplxInd,~EcplxInd);
C_CC_Fix_Bd = C_EE_Fix_Bd(EcplxInd,EcplxInd);
C_SI_Fix_Bd = C_EI_Fix_Bd(~EcplxInd,:);
C_CI_Fix_Bd = C_EI_Fix_Bd(EcplxInd,:);
C_IS_Fix_Bd = C_IE_Fix_Bd(:,~EcplxInd);
C_IC_Fix_Bd = C_IE_Fix_Bd(:,EcplxInd);

fid = fopen([DataFolder 'MFVDriveTestV4.txt'],'rt');
C = textscan(fid, '%f%f', 'MultipleDelimsAsOne',true, 'Delimiter','[;');
fclose(fid);

BgFrs = zeros(length(C{1}),3);
DrvFrs = zeros(length(C{1}),6);
MtpRcd = zeros(length(C{1}),2);
SmpFrac = 0.8;
for dirInd = 1:length(C{1})
    SIEMtp = C{1}(dirInd);
    SEIMtp = C{2}(dirInd);
    % Frst setup network
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
    
    p_EEFail = 0.2; S_amb = 0.01;
    rS_amb = 0.6;
    rC_amb = 0.75;
    rE_amb = [rS_amb*ones(N_S,1);rC_amb*ones(N_C,1)];
    rI_amb = 0.435; % was 0.5 for for 071021 simulation
    
    tau_ampa_R = 0.5; tau_ampa_D = 3;
    tau_nmda_R = 2; tau_nmda_D = 80;
    tau_gaba_R = 0.5; tau_gaba_D = 5;
    tau_ref = 2; % time unit is ms
    
    gL_E = 1/20;  Ve = 14/3; rhoE_ampa = 0.8; rhoE_nmda = 0.2;
    gL_I = 1/15;  Vi = -2/3; rhoI_ampa = 0.67;rhoI_nmda = 0.33;
    %NW Connectivity and L6 Input
    %NOTE: L input is VEC now. But Fortunately can still support
    S_EE = 0.024; S_EI = S_EE*SEIMtp;
    S_II = 0.120; S_IE = S_II*SIEMtp;
    % L6 input
    S_EL6 = 1/3*S_EE; S_IL6 = 1/3*S_IE;
    rL6_One = 0.007;
    NS_L6 = 45; NC_L6 = 55; NI_L6 = 150; % was 55
    rS_L6 = NS_L6*rL6_One;
    rC_L6 = NC_L6*rL6_One;
    rI_L6 = NI_L6*rL6_One;
    rE_L6 = (rS_L6*double(~EcplxInd) + rC_L6*double(EcplxInd))';     %rI_L6 = rE_L6*3; %250hz for now
    % Make up LGN
    S_Elgn = 2*S_EE;
    S_Ilgn = 2*S_Elgn;
    %N_Slgn = 4.75; N_Clgn = 1.25; N_Ilgn = 4.5;
    N_Slgn = 4.75; N_Clgn = 1.5; N_Ilgn = 4.5;
    lambda_E = 0.02*[N_Slgn*ones(N_S,1);N_Clgn*ones(N_C,1)]; % ~16 LGN spike can excite a E neurons. 0.25 spike/ms makes 64 ms for such period.
    lambda_I = 0.02*N_Ilgn;
    
    % drive parameter
    ODNum = 4; % 4 orientation domains
    % A function from Neuron Ind and spatial scales to Orientation Domains
    OD_S = zeros(size(NnS.X),'single');
    OD_SMap = zeros(n_S_HC*N_HC,'single');
    for NeuInd = 1:length(NnS.X)
        OD_S(NeuInd) = OrientDom(ODNum,NnS.X(NeuInd),NnS.Y(NeuInd),n_S_HC);
        OD_SMap(NnS.Y(NeuInd),NnS.X(NeuInd)) = OD_S(NeuInd);
    end
    
    OD_C = zeros(size(NnC.X),'single');
    OD_CMap = zeros(n_C_HC*N_HC,'single');
    for NeuInd = 1:length(NnC.X)
        OD_C(NeuInd) = OrientDom(ODNum,NnC.X(NeuInd),NnC.Y(NeuInd),n_C_HC);
        OD_CMap(NnC.Y(NeuInd),NnC.X(NeuInd)) = OD_C(NeuInd);
    end
    OD_E = [OD_S, OD_C];
    
    OD_I = zeros(size(NnI.X),'single');
    OD_IMap = zeros(n_I_HC*N_HC,'single');
    for NeuInd = 1:length(NnI.X)
        OD_I(NeuInd) = OrientDom(ODNum,NnI.X(NeuInd),NnI.Y(NeuInd),n_I_HC);
        OD_IMap(NnI.Y(NeuInd),NnI.X(NeuInd)) = OD_I(NeuInd);
    end
    StimulusFac = 1;
    LGNFreq = 4; % 2 4 10Hz
    tMod = 1e3/LGNFreq; MaxOnPhase = tMod/2;% Each Cycle lasts for 500 ms
    PhaseE = single(tMod*rand(N_E,1));
    PhaseFRS = [90 67.5 45 67.5,    0  22.5 45 22.5] *N_Slgn/1e3 * StimulusFac; % 4 to 5
    %PhaseFRC = [90 67.5 45 67.5,    0  22.5 45 22.5] *N_Clgn/1e3 * StimulusFac;
    PhaseFRC = 45*ones(1,8) *N_Clgn/1e3 * StimulusFac;
    lambda_EOn_drive  = [PhaseFRS(OD_S),PhaseFRC(OD_C)]'; % Should do another for Cplx cells
    lambda_EOff_drive = [PhaseFRS(OD_S+ODNum),PhaseFRC(OD_C+ODNum)]';
    % T partition
    T = 10000; dt = 0.1; TPar = 10;
    %DriveE = [60,53,48,53]*4/1e3; % Ordered by domains, times the number of lgn cells, normalized by 1000ms
    lambda_E_drive_Pre = 45 *N_Slgn/1e3 * StimulusFac;
    lambda_I_drive_Pre = 45 *N_Ilgn/1e3 * StimulusFac;
    
    L6Ord_F = [50 31 12 31];
    L6S_Drive = L6Ord_F*NS_L6/1e3 * StimulusFac;
    L6C_Drive = L6Ord_F*NC_L6/1e3 * StimulusFac;
    L6I_Drive = L6Ord_F*NI_L6/1e3 * StimulusFac;
    
    % NOTE: Doing Gaussian blur
    FigOn = false;
    L6SFilt = SpatialGaussianFilt(OD_SMap,L6S_Drive,n_S_HC/8,FigOn);
    L6CFilt = SpatialGaussianFilt(OD_CMap,L6C_Drive,n_C_HC/8,FigOn);
    L6IFilt = SpatialGaussianFilt(OD_IMap,L6I_Drive,n_I_HC/8,FigOn);
    
    rE_L6_Drive = [L6SFilt;L6CFilt];
    rI_L6_Drive = L6IFilt;
    
    % Making Poisson here/Reading
    TimeFrac = 0.05;
    LGNCurInp = 0;
    
    % get corresponding neurons
    OptE = [L6SFilt>0.91*max(L6S_Drive);  L6CFilt>0.91*max(L6C_Drive)]';
    OptI =  L6IFilt'>0.91*max(L6I_Drive);
    OrtE = [L6SFilt<1.1*min(L6S_Drive);  L6CFilt<1.1*min(L6C_Drive)]';
    OrtI =  L6IFilt'<1.1*min(L6I_Drive);
    
    OD1S = find(OptE & (~EcplxInd));
    OD1C = find(OptE & (EcplxInd));
    OD1I = find(OptI);
    
    OD3S = find(OrtE & (~EcplxInd));
    OD3C = find(OrtE & (EcplxInd));
    OD3I = find(OrtI);
%% Read data
    ReadFolder = [DataFolder sprintf('SIEMt%.3f_SEIMt%.3f/',SIEMtp,SEIMtp)]
    MtpRcd(dirInd,1) = SIEMtp; MtpRcd(dirInd,2) = SEIMtp; 
    sprintf('SIEMt%.3f, SEIMt%.3f/',MtpRcd(dirInd,1), MtpRcd(dirInd,2))
    if isfolder(ReadFolder)
        % read BG Frs
        load([ReadFolder 'BGNWTrace.mat'],'NWTrace');
        BgFrs(dirInd,1) = mean(NWTrace.FrSs(floor(end*(1-SmpFrac)):end));
        BgFrs(dirInd,2) = mean(NWTrace.FrCs(floor(end*(1-SmpFrac)):end));
        BgFrs(dirInd,3) = mean(NWTrace.FrIs(floor(end*(1-SmpFrac)):end));
        clear NWTrace
        
        % read Drive Frs
        SpE = []; SpI = [];
        PhaseEAll = [];
        for TSec = 1:TPar
            text = [sprintf('DriveWkSp_SCSepa_Cconst_%dHz',LGNFreq) num2str(TSec) 's.mat'];
            load([ReadFolder text],'NWTrace');
            
            SpECurrent = []; SpICurrent = [];
            for WinInd = 1:length(NWTrace)
                SpECurrent = [SpECurrent; NWTrace(WinInd).SpEs];
                SpICurrent = [SpICurrent; NWTrace(WinInd).SpIs];
            end
            
            if isempty(SpECurrent)
                disp('NaN. Continue')
                continue
            end
            
            SpECurrent(:,2) = SpECurrent(:,2) + (TSec-1)*T/TPar;
            SpICurrent(:,2) = SpICurrent(:,2) + (TSec-1)*T/TPar;
            SpE = [SpE;SpECurrent];
            SpI = [SpI;SpICurrent];
            clear NWTrace            
        end
        if isempty(SpE)
            disp('NaN. Continue')
            continue
        end
%         WinNum = size(SpE,2);
%         StatWin = linspace(0,T,WinNum+1);
%         StatWinSize = StatWin(2) - StatWin(1);
        
        scatter1S = find(ismember(SpE(:,1),OD1S));
        scatter1C = find(ismember(SpE(:,1),OD1C));
        scatter1I = find(ismember(SpI(:,1),OD1I));
        
        scatter3S = find(ismember(SpE(:,1),OD3S));
        scatter3C = find(ismember(SpE(:,1),OD3C));
        scatter3I = find(ismember(SpI(:,1),OD3I));
        
        DrvFrs(dirInd,1) = length(SpE(scatter1S,2))/(T/1e3)/length(OD1S);
        DrvFrs(dirInd,2) = length(SpE(scatter1C,2))/(T/1e3)/length(OD1C);
        DrvFrs(dirInd,3) = length(SpI(scatter1I,2))/(T/1e3)/length(OD1I);
        
        DrvFrs(dirInd,4) = length(SpE(scatter3S,2))/(T/1e3)/length(OD3S);
        DrvFrs(dirInd,5) = length(SpE(scatter3C,2))/(T/1e3)/length(OD3C);
        DrvFrs(dirInd,6) = length(SpI(scatter3I,2))/(T/1e3)/length(OD3I);
    else
        disp('No such data folder, continue...')
        continue
    end
end
save([DataFolder 'MFVDriveNWRslt.mat'],'BgFrs','DrvFrs','MtpRcd')