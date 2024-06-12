%% HPC for large amount of IC tests
% RadiusInd: 10^-RadiusInd when using
% SampleSize: specify an integer. Fix
% SaveID Just for saving tag
function [] = HPCICTest_Paper3(RadiusInd,SampleSize,SaveID, varargin)
CurrentFolder = pwd
addpath(CurrentFolder)
addpath([CurrentFolder '/Utils'])
addpath([CurrentFolder '/Data'])
SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3ICTestData/']; % V1D2
%SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/']; % V1
addpath(SaveFolder)
% DataFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/16Function_Scheme/']; % V1D2
% addpath(DataFolder)
addpath([CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3PlotingData/'])

load('ICTest_Paper3.mat')
CurrentFolder = pwd
SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3ICTestData/']; % V1D2
%SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/']; % V1
addpath(SaveFolder)
%% 4.1 Test a large sample
NSample = SampleSize;
Radius = 10^(-RadiusInd);

LDEequv = LDEOutAll{1}{end};

LDEPertOutAll = cell(NSample,1);
EpocTest = 300;
L2Diff_OneStepAll = zeros(NSample,EpocTest+1);
DiffVecAll = zeros(NSample,EpocTest+1,NPixY*NPixX*3);
NANFlag = false(NSample,1);

N_HCOut = [N_HCOutX, N_HCOutY];

if length(varargin)>0
    p = StepSize;
else
    p = 0.33;
end


tic
for TestInd = 1:NSample
    rng(TestInd + NSample*SaveID, 'twister')
    NoiseAll = normrnd(0,Radius,NPixY*NPixX*3,NSample);
    NoiseAll(1)
    %NoiseUse = [];
    NoiNorm  = sqrt(sum(NoiseAll.^2,1));
    NoiseAll = NoiseAll./repmat(NoiNorm,NPixY*NPixX*3,1)*Radius;
    % OutBound = (NoiNorm>1e-7) | (NoiNorm<1e-10);
    % NoiseAll(:,OutBound) = [];

    IniTest.S = symmHCs(LDEequv.S,N_HCOut,NPixX,NPixY,...
        NoiseAll(1:NPixY*NPixX,TestInd));
    IniTest.C = symmHCs(LDEequv.C,N_HCOut,NPixX,NPixY,...
        NoiseAll(NPixY*NPixX+1:2*NPixY*NPixX,TestInd));
    IniTest.I = symmHCs(LDEequv.I,N_HCOut,NPixX,NPixY,...
        NoiseAll(2*NPixY*NPixX+1:3*NPixY*NPixX,TestInd));
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
        N_HCOutY,NPixX,NPixY,Isaturation,'xn',{},IKpUse)  ;
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
    end
    fprintf("sample %d is done.\n",TestInd)
    toc
end
toc
save([SaveFolder sprintf('Paper3LocalTest_Rad%d_size%d_ID%d_h%.2f.mat',...
    RadiusInd,NSample,SaveID,p)],'L2Diff_OneStepAll','DiffVecAll','LDEPertOutAll','LDEequv')