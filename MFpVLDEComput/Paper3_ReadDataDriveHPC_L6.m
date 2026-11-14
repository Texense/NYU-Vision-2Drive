%% Read drive data on HPC

%% 0: make dirs
function [] = Paper3_ReadDataDriveHPC_L6(sampleId)
CurrentFolder = pwd
%FigurePath = [CurrentFolder '/Figures'];
addpath(CurrentFolder)
addpath([CurrentFolder '/Utils'])
addpath([CurrentFolder '/Data'])
DataFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/'];
SaveToFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3NWData/'];
addpath(DataFolder)
addpath(SaveToFolder)

load('DriveWkSp_SCSepa_Cconst_Conn.mat','EcplxInd');

L6Intesect = 0.65;
L6ShapeAll = [0.04, 0.07, 0.10, 0.04, 0.07, 0.10];
L6EndAll = [1 1 1 1.05 1.05 1.05];

GratingAll = 0:7.5:22.5;
%SampleNum = 10;
aa = length(L6ShapeAll); bb = length(GratingAll);

BgFrs = zeros(aa*bb,3);
DrvFrs = cell(aa*bb,4); %SCEI
MtpRcd = zeros(aa*bb,2);
SmpFrac = 0.8; % sample from how much time
dirInd = 1;


for TestId = 1:aa
    for AngInd = 1:bb
            L6Shape = L6ShapeAll(TestId);
            L6End   = L6EndAll(TestId);
            Grating = GratingAll(AngInd);
            % Frst setup network
            N_HC = 3;
            % Number of E and I neurons
            n_S_HC = 45; n_C_HC = 30; n_I_HC = 31; % per side of HC
            N_S = n_S_HC^2 * N_HC^2; % neuron numbers In all
            N_C = n_C_HC^2 * N_HC^2; % neuron numbers In all
            N_I = n_I_HC^2 * N_HC^2;
            N_E = N_S+N_C; CplxR = N_C/N_E;
            % Grid sizes of E and I neurons;
%             Size_HC = 0.500; % in mm;
%             Size_S = Size_HC/n_S_HC; Size_C = Size_HC/n_C_HC; Size_I = Size_HC/n_I_HC;
%             % Projection: SD of distances
%             SD_E = 0.2/sqrt(2); SD_I = 0.125/sqrt(2);
%             Dist_LB = 0.36; % ignore the connection probability of dist>0.3mm
%             % Peak probability of projection
%             Peak_EE = 0.15; Peak_I = 0.6;

            % spatial indexes of E and I neurons
            [NnS.X,NnS.Y] = V1Field_Generation(N_HC,1:N_S,'e',n_S_HC,n_I_HC);
            [NnC.X,NnC.Y] = V1Field_Generation(N_HC,1:N_C,'e',n_C_HC,n_I_HC);
            [NnI.X,NnI.Y] = V1Field_Generation(N_HC,1:N_I,'i');

%             N_EE = 190; N_EI = 85; %*0.75
%             N_IE = 844; N_II = 84; %*0.75 Plan A:Original
% 
%             CplxNEIncr = 255/N_EE; % Was 250 for 071021 simulation
%             EcplxInd = ismember(1:N_E, N_S+1:N_E);
% 
%             N_SS = N_EE * (1-CplxR);            N_SC = N_EE * (CplxR);
%             N_CS = N_EE * (1-CplxR)*CplxNEIncr; N_CC = N_EE * (CplxR)*CplxNEIncr;
%             N_SI = N_EI;                        N_CI = N_EI;
%             N_IS = N_IE * (1-CplxR);            N_IC = N_IE * (CplxR);
% 
%             p_EEFail = 0.2; S_amb = 0.01;
%             rS_amb = 0.6;
%             rC_amb = 0.75;
%             rE_amb = [rS_amb*ones(N_S,1);rC_amb*ones(N_C,1)];
%             rI_amb = 0.435; % was 0.5 for for 071021 simulation
% 
%             tau_ampa_R = 0.5; tau_ampa_D = 3;
%             tau_nmda_R = 2; tau_nmda_D = 80;
%             tau_gaba_R = 0.5; tau_gaba_D = 5;
%             tau_ref = 2; % time unit is ms
% 
%             gL_E = 1/20;  Ve = 14/3; rhoE_ampa = 0.8; rhoE_nmda = 0.2;
%             gL_I = 1/15;  Vi = -2/3; rhoI_ampa = 0.67;rhoI_nmda = 0.33;
%             %NW Connectivity and L6 Input
%             %NOTE: L input is VEC now. But Fortunately can still support
%             S_EE = 0.024; S_EI = S_EE*1.88;
%             S_II = 0.120; S_IE = S_II*0.131;
%             % L6 input
%             S_EL6 = 1/3*S_EE; S_IL6 = 1/3*S_IE;
%             rL6_One = 0.007;
%             NS_L6 = 45; NC_L6 = 55; NI_L6 = 150; % was 55
%             rS_L6 = NS_L6*rL6_One;
%             rC_L6 = NC_L6*rL6_One;
%             rI_L6 = NI_L6*rL6_One;
%             rE_L6 = (rS_L6*double(~EcplxInd) + rC_L6*double(EcplxInd))';     %rI_L6 = rE_L6*3; %250hz for now
%             % Make up LGN
%             S_Elgn = 2*S_EE;
%             S_Ilgn = 2*S_Elgn;
%             %N_Slgn = 4.75; N_Clgn = 1.25; N_Ilgn = 4.5;
%             N_Slgn = 4.75; N_Clgn = 1.5; N_Ilgn = 4.5;
%             lambda_E = 0.02*[N_Slgn*ones(N_S,1);N_Clgn*ones(N_C,1)]; % ~16 LGN spike can excite a E neurons. 0.25 spike/ms makes 64 ms for such period.
%             lambda_I = 0.02*N_Ilgn;

%             % drive parameter
%             LGNFreq = 4; % 2 4 10Hz
%             tMod = 1e3/LGNFreq;
            % T partition
            T = 10000; %dt = 0.1; 
            TPar = 10;

            %% Read dat
            ReadFolder = [SaveToFolder sprintf('L6Int%.2fL6Sh%.2fend%.2f_Ang%.1f_sample%d/',L6Intesect,L6Shape,L6End,Grating,sampleId)];
            MtpRcd(dirInd,1) = L6Shape; MtpRcd(dirInd,2) = Grating;
            fprintf('L6Int%.2fL6Sh%.2fend%.2f_Ang%.1f_sample%s/',L6Intesect,L6Shape,L6End,Grating,sampleId)
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
                    DriveFName = [sprintf('DriveWkSp_L6Sh%.2f_Ang%.1f',L6Shape,Grating) num2str(TSec) 's.mat'];
                    %DriveFName = [sprintf('DriveWkSp_SIlgnMpt%.3f_Ang%.1f',SIlgnMpt,Grating) num2str(TSec) 's.mat'];
                    load([ReadFolder DriveFName],'NWTrace');

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
                %%      Count firing rates for each pixel
                Window = [T*(1-SmpFrac),T];
                EffSize = Window(2)-max(0,Window(1));
                NPixX = 10; %10
                NPixY = 10;

                % take E and F firing rate for each neuron
                ESPinWin = SpE(:,2)>=Window(1) & SpE(:,2)<=Window(2);
                SpEGood = SpE(ESPinWin,1);
                [SpCN, SpCI] = groupcounts(SpEGood);
                FrE_temp = zeros(N_E,1);
                FrE_temp(SpCI) = SpCN*1e3/(EffSize);
                ISPinWin = (SpI(:,2)>=Window(1) & SpI(:,2)<=Window(2));
                SpIGood = SpI(ISPinWin,1);
                [SpCN, SpCI] = groupcounts(SpIGood);
                FrI_temp = zeros(N_I,1);
                FrI_temp(SpCI) = SpCN*1e3/EffSize;

                [FrSPixMat,~] = NeuVec2Pixel(FrE_temp(~EcplxInd),NnS,NPixX*N_HC,NPixY*N_HC);
                [FrCPixMat,~] = NeuVec2Pixel(FrE_temp(EcplxInd),NnC,NPixX*N_HC,NPixY*N_HC);
                FrEPixMat = FrSPixMat*(1-CplxR)+ FrCPixMat*CplxR;
                [FrIPixMat,~] = NeuVec2Pixel(FrI_temp,NnI,NPixX*N_HC,NPixY*N_HC);

                DrvFrs{dirInd,1} = FrSPixMat; DrvFrs{dirInd,2} = FrCPixMat;
                DrvFrs{dirInd,3} = FrEPixMat; DrvFrs{dirInd,4} = FrIPixMat;
            else
                disp('No such data folder, continue...')
                continue
            end            
        dirInd = dirInd+1;
    end
end
save([SaveToFolder sprintf('Paper3DriveNW_L6_Samps%d_L6Sh%.2f_%.2f_L6End%.2f_%.2f.mat',...
    sampleId,min(L6ShapeAll),max(L6ShapeAll),min(L6EndAll),max(L6EndAll))],'BgFrs','DrvFrs','MtpRcd')
end