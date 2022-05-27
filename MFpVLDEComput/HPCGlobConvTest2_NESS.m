%% HPC for large amount of IC tests. Start from NESS
% ContrastID: B. "1/2 contrast" = bg + 1/2 * (X_E-bg, X_I-bg)
%             C. (normal) full contrast = (X_E, X_I)
%             D. super-charged = bg + 3/2 * (X_E-bg, X_I-bg)
% SaveID Just for saving tag

function [] = HPCGlobConvTest2_NESS(ICId, ContrastID, ITestSize, PertSize)
CurrentFolder = pwd
%FigurePath = [CurrentFolder '/Figures/Demo022722/'];
addpath(CurrentFolder)
addpath([CurrentFolder '/Utils'])
addpath([CurrentFolder '/Data'])
SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/GlobConv/']; % V1D2
%SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/']; % V1
addpath(SaveFolder)
% DataFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/16Function_Scheme/']; % V1D2
% addpath(DataFolder)
addpath([CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/'])

load('GlobalConvTestWS1.mat')
clear LDEFrfuncLarge LDEFrfunc

%% NEW unified functions
%load('ICTesfuncLarge.mat')
%load('ICTesfuncSmall.mat')
DomList =  {'Small','Larger'}; % we have small, large, larger domains

Large = load(sprintf('Func16%sAng%s%s.mat',DataPoint,AngPrint,DomList{2}),...
    'LDEFrfunc','L4EmeshX','L4ImeshY');

Small = load(sprintf('Func16%sAng%s%s.mat',DataPoint,AngPrint,DomList{1}),...
    'LDEFrfunc','L4EmeshX','L4ImeshY');

L4EmeshXAll = {Small.L4EmeshX, Large.L4EmeshX};
L4ImeshYAll = {Small.L4ImeshY, Large.L4ImeshY};
LDEFrfuncAll = {Small.LDEFrfunc, Large.LDEFrfunc};
%% rest of folders
CurrentFolder = pwd; % Since loaded data will overwrite pwd...
SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/GlobConv/']; % V1D2
%SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/']; % V1
addpath(SaveFolder)
%% 4.1 Test a large sample
%% first prepare a driven IC
NSample = PertSize*ITestSize;

AngleAll = 0:7.5:90;
AngleInpt = AngleAll(ICId);% has to be multiples of 7.5
RotInd = floor(AngleInpt/45); % 0-3
MirInd = mod(floor(AngleInpt/22.5),2); % 0: no mirror; 1: mirror
switch MirInd % find the corresponding source
    case 0
        AngSource = mod(AngleInpt,45);
    case 1
        AngSource = mod(-AngleInpt,45);
end

% Use the source, decide which response function for angle should I use
AngFuncCtgrCdid = 0:7.5:22.5;
[~,AngFuncCtgr] = min(abs(AngFuncCtgrCdid - AngSource));

AngleList = {'0.0','7.5','15.0','22.5'};
AngPrint = AngleList{AngFuncCtgr};
load(sprintf('LDETraces_ang%s.mat',AngPrint))
LDEICPart = LDEEpoOutAll{1}{end};
LDEICPart = HCRot(LDEICPart,RotInd,N_HCOut,NPixX,NPixY,MirInd);

% Compose contrasts
ICWeights = 1/2:1/2:3/2;
fields = fieldnames(LDEICPart);
for FInd = 1:length(fields)
    LDEIC_temp.(fields{FInd}) = ...
        ICWeights(ContrastID) * LDEICPart.(fields{FInd});          
end

% Now perturbe and collect a group
IPertList = linspace(0.80,1.20,ITestSize);
PixPertScl = 0.15;
ICTestAll = cell(ITestSize,PertSize);
for ITestInd = 1:ITestSize
    for PertInd = 1:PertSize
        LDEIC_pert = LDEIC_temp;
        LDEIC_pert.I = LDEIC_pert.I * IPertList(ITestInd);
        
        % take a pixelwise peerturbation vec
        PertVec = 1 + rand(size(LDEIC_pert.I)) * PixPertScl*2 - PixPertScl;
        for FInd = 1:length(fields)
            LDEIC_pert.(fields{FInd}) = LDEIC_pert.(fields{FInd}).*PertVec;
        end
        ICTestAll{ITestInd,PertInd} = LDEIC_pert;
    end
end
ICTestAll = reshape(ICTestAll',NSample,1);

%% Simulate for each IC
LDEPertOutAll = cell(NSample,1);
EpocTest = 200;
L2Diff_EIWgtsAll = zeros(NSample,EpocTest+1);
DiffVecAll = zeros(NSample,EpocTest+1,NPixY*NPixX*3);

tic
for TestInd = 1:NSample
    ICUse = ICTestAll{TestInd};
    IniTest.S = symmHCs(ICUse.S,N_HCOut,NPixX,NPixY);
    IniTest.C = symmHCs(ICUse.C,N_HCOut,NPixX,NPixY);
    IniTest.I = symmHCs(ICUse.I,N_HCOut,NPixX,NPixY);
    
    % Function: small large combined   
    [LDEPertOutAll{TestInd},~,~,~,~] = ...
        LDEIteration_16FuncMain_CombDom(...
        PixInptCtgrUse,IniTest,p,EpocTest,...
        C_SS_mean,C_CS_mean,C_IS_mean,...
        C_SC_mean,C_CC_mean,C_IC_mean,...
        C_SI_mean,C_CI_mean,C_II_mean,...
        L4EmeshXAll,L4ImeshYAll,LDEFrfuncAll,...
        N_HCOut,NPixX,NPixY)  ;
    LDEequv = LDEPertOutAll{TestInd}{end}; 
    
    for EpcInd = 1:EpocTest+1
        LDEPertRslt = LDEPertOutAll{TestInd}{EpcInd};
        SDiff = LDEPertRslt.S - LDEequv.S;
        SDiffHC = reshape(SDiff,N_HCOut*NPixY,N_HCOut*NPixX);
        SDiff = reshape(SDiffHC(1:NPixY,1:NPixX),NPixY*NPixX,1);
        CDiff = LDEPertRslt.C - LDEequv.C;
        CDiffHC = reshape(CDiff,N_HCOut*NPixY,N_HCOut*NPixX);
        CDiff = reshape(CDiffHC(1:NPixY,1:NPixX),NPixY*NPixX,1);
        IDiff = LDEPertRslt.I - LDEequv.I;
        IDiffHC = reshape(IDiff,N_HCOut*NPixY,N_HCOut*NPixX);
        IDiff = reshape(IDiffHC(1:NPixY,1:NPixX),NPixY*NPixX,1);
        
        EDiff = SDiff*(1-CplxR) + CDiff*CplxR;
        L2Diff_EIWgtsAll(TestInd,EpcInd) = ...
                sqrt(sum(EDiff.^2 * 0.8^2 + IDiff.^2 * 0.2^2)/(NPixY*NPixX));
        DiffVecAll(TestInd,EpcInd,:) = [SDiff;CDiff;IDiff];
    end
    fprintf("sample %d is done.\n",TestInd)
end
toc
save([SaveFolder sprintf('Paper2GlobConv_IC%d_Ctrst%d.mat',...
    ICId,ContrastID)],'L2Diff_EIWgtsAll','DiffVecAll')
end

% rotate ICs
% LDEequv contains SCI
function [LDEequvUse] = ICRot(LDEequv,rotID,N_HCOut,NPixX,NPixY)
fields = fieldnames(LDEequv);
LDEequvUse = LDEequv;

[HCX, HCY] = meshgrid(1:N_HCOut,1:N_HCOut);
HCX = mod(HCX,2); HCY = mod(HCY,2); 
for FInd = 1:length(fields)
    CurrFieldVec = LDEequv.(fields{FInd});
    CurrFieldMap = reshape(CurrFieldVec,N_HCOut*NPixY,N_HCOut*NPixX);
    OneHC = rot90(CurrFieldMap(1:NPixY,1:NPixX),rotID); % get rotated one HC
    
    MapOut = zeros(size(CurrFieldMap));
    for xid = 1:N_HCOut
        for yid = 1:N_HCOut
            xmod = HCX(yid, xid); ymod = HCY(yid, xid);
            HCHold = OneHC;
            if xmod == 0
                HCHold = HCHold(:,end:-1:1);
            end
            
            if ymod == 0
                HCHold = HCHold(end:-1:1,:);
            end
            MapOut((yid-1)*NPixY+1:yid*NPixY, (xid-1)*NPixX+1:xid*NPixX) = HCHold;
        end
    end
    LDEequvUse.(fields{FInd})= reshape(MapOut,...
        length(CurrFieldVec),1);
end

end