%% HPC for large amount of IC tests. Start from NESS
% BlockID 1,2,5
% SaveID Just for saving tag

function [] = HPCGlobConvTest2_RAND_Paper3(BlockID, SaveID, NSample, varargin)
CurrentFolder = pwd
%FigurePath = [CurrentFolder '/Figures/Demo022722/'];
addpath(CurrentFolder)
addpath([CurrentFolder '/Utils'])
addpath([CurrentFolder '/Data'])
% DataFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/16Function_Scheme/']; % V1D2
% addpath(DataFolder)
addpath([CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/'])
addpath([CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3PlotingData/'])
DataFolder4 = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3ICTestData/'];
addpath(DataFolder4)

load('ICTest_Paper3-L4EDepression.mat')
clear LDEFrfuncLarge LDEFrfunc
load('LDE_CoG_h0.60_Samp600.mat','LDE_CoG')
LDEequv = LDE_CoG;

CurrentFolder = pwd
SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3PlotingData_Global/']; % V1D2
%SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/']; % V1
addpath(SaveFolder)

if length(varargin)>0
    p = varargin{1}
else
    p = 0.33
end

if length(varargin)>1
    EpocTest = varargin{2}
else
    EpocTest = 300
end
%% first prepare a driven IC
LDEIC_temp.S = zeros(PixNumOut,1);
LDEIC_temp.C = zeros(PixNumOut,1);
LDEIC_temp.I = zeros(PixNumOut,1); 


% Now perturbe and collect a group
BckSzAll = [1,2,5];
PertBckSz = BckSzAll(BlockID); % size of the block
BlockN = floor(NPixX/PertBckSz);
  % Use Kronecker Tensor Product
ICTestAll = cell(NSample,1);

for SampInd = 1:NSample
    rng(SaveID*NSample + SampInd, 'twister')
    LDEIC_pert = LDEIC_temp;
    Block = ones(PertBckSz);
    %PertMtx = ones(BlockN);
    
    EPert = 60*rand(BlockN); % random in [1,2]
    IPert = 100*rand(BlockN) + 20; %(4*rand(BlockN)+2).* EPert; % random in [1/2,1]
    
    SPert = EPert/1.6;
    CPert = SPert*3;
    
    %PertMtxUse = kron(PertMtx,Block);
    % take a blockwise peerturbation
    LDEIC_pert.S = symmHCs(LDEIC_pert.S,[N_HCOutX, N_HCOutY],NPixX,NPixY,kron(SPert,Block),'add');
    LDEIC_pert.C = symmHCs(LDEIC_pert.C,[N_HCOutX, N_HCOutY],NPixX,NPixY,kron(CPert,Block),'add');
    LDEIC_pert.I = symmHCs(LDEIC_pert.I,[N_HCOutX, N_HCOutY],NPixX,NPixY,kron(IPert,Block),'add');
    
    ICTestAll{SampInd} = LDEIC_pert;
    
end


%% Simulate for each IC
LDEPertOutAll = cell(NSample,1);

L2Diff_OneStepAll = zeros(NSample,EpocTest+1);
DiffVecAll = zeros(NSample,EpocTest+1,NPixY*NPixX*3);
NANFlag = false(NSample,1);

%N_HCOut = [N_HCOutX, N_HCOutY];

tic
for TestInd = 1:NSample
    IniTest = ICTestAll{TestInd};
    tic
    [LDEPertOutAll{TestInd},~,~,~,~,~,...
        NANFlag(TestInd)] = ...
        LDEIteration_135FuncMain_CombDom_RealLGNL6(...
        PixLGNCtgr,L6Kernel,IniTest,p,L6pars{L6parId}, EpocTest,...
        C_SS_meanU,C_CS_meanU,C_IS_mean,...
        C_SC_meanU,C_CC_meanU,C_IC_mean,...
        C_SI_mean, C_CI_mean, C_II_mean,...
        L4SEp, L4SIp, ...
        L4CEp, L4CIp, ...
        L4IEp, L4IIp, ...
        L4EmeshXAll,L4ImeshYAll,LDEFrfuncAll,...
        N_HCOutY,NPixX,NPixY,Isaturation,'xn',EKpUse,IKpUse)  ;
    %LDEequv = LDEOutAll{TestInd}{end};

    RunTime = toc;
    sprintf('RunTime = %.2f',RunTime)
    tic
    if ~NANFlag(TestInd)
        for EpcInd = 1:EpocTest+1
            LDEPertRslt = LDEPertOutAll{TestInd}{EpcInd};
            SDiff = LDEPertRslt.S - LDEequv.S;
            SDiffHC = reshape(SDiff,N_HCOutY*NPixY,N_HCOutX*NPixX);
            SDiff = reshape(SDiffHC(1:NPixY,1:NPixX),NPixY*NPixX,1);
            CDiff = LDEPertRslt.C - LDEequv.C;
            CDiffHC = reshape(CDiff,N_HCOutY*NPixY,N_HCOutX*NPixX);
            CDiff = reshape(CDiffHC(1:NPixY,1:NPixX),NPixY*NPixX,1);
            IDiff = LDEPertRslt.I - LDEequv.I;
            IDiffHC = reshape(IDiff,N_HCOutY*NPixY,N_HCOutX*NPixX);
            IDiff = reshape(IDiffHC(1:NPixY,1:NPixX),NPixY*NPixX,1);

            L2Diff_OneStepAll(TestInd,EpcInd) = ...
                sqrt(sum((SDiff*(1-CplxR)+CDiff*CplxR).^2,'all'));%sqrt(sum([SDiff;CDiff;IDiff].^2));
            DiffVecAll(TestInd,EpcInd,:) = [SDiff;CDiff;IDiff];
        end
        fprintf("sample %d is done.\n",TestInd)
    else
        fprintf("sample %d crashed.\n",TestInd)
    end
    
    toc
end
toc
save([SaveFolder sprintf('Paper3GlobConv_BlockID%d_SaveId%d_Samp%d_h%.2f.mat',...
    BlockID,SaveID,NSample,p)],...
    'LDEPertOutAll','L2Diff_OneStepAll','DiffVecAll')
end
