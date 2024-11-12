%% HPC for large amount of IC tests
% RadiusInd: 10^-RadiusInd when using
% SampleSize: specify an integer. Fix
% SaveIDRange [min max]
function [] = HPCGlobalTest_Paper3_read(BlockID,SampleSize,minId,maxId, varargin)
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
SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3PlotingData_Global/']; % V1D2
%SaveFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/']; % V1
addpath(SaveFolder)

%% 4.1 Test a large sample
NSample = SampleSize;
if length(varargin)>0
    p = varargin{1};
    hStr = sprintf('_h%.2f',p)
else
    p = 0.33;
    hStr = ''
end

%% for Edepression
load([SaveFolder sprintf('Paper3GlobConv_BlockID%d_SaveId%d_Samp%d_h%.2f.mat',...
    BlockID,1,NSample,p)],...
    'L2Diff_OneStepAll')
EpocTest = size(L2Diff_OneStepAll,2)-1;
NSampleAll = SampleSize * maxId;

LDEPertOutAllSample = cell(NSampleAll,1);
LDETrajAll = cell(NSampleAll,1);
L2Diff_AllSample = zeros(NSampleAll,EpocTest+1);

SaveIdUsed = 0;
for SaveId = minId:maxId
    
    if isfile([SaveFolder sprintf('Paper3GlobConv_BlockID%d_SaveId%d_Samp%d_h%.2f.mat',...
            BlockID,SaveId,NSample,p)])
        tic
        fprintf('Paper3GlobConv_BlockID%d_SaveId%d_Samp%d_h%.2f.mat',BlockID,SaveId,NSample,p)
        load([SaveFolder sprintf('Paper3GlobConv_BlockID%d_SaveId%d_Samp%d_h%.2f.mat',...
                BlockID,SaveId,NSample,p)],...
            'LDEPertOutAll','L2Diff_OneStepAll')
        SampleIdRange = (SaveId-1)*NSample + 1 : SaveId*NSample;
        L2Diff_AllSample(SampleIdRange,:) = L2Diff_OneStepAll; % some of this may be 0 due to failure
        for SampleId = SampleIdRange
            LDEPertOutAllSample{SampleId} = LDEPertOutAll{SampleId - (SaveId-1)*NSample}{end}; % some of this may be [] due to failure
            LDETrajAll{SampleId} = LDEPertOutAll{SampleId - (SaveId-1)*NSample};
        end
        SaveIdUsed = SaveIdUsed + 1;
        fprintf('SaveId %d loaded, \n', SaveId)
        clear L2Diff_OneStepAll LDEPertOutAll
        toc
    else
        fprintf('SaveId %d missing, \n', SaveId)
    end

    
end
save([SaveFolder sprintf('Paper3GlobTests-Block%d_IDRange%d-%d_Samp%d%s.mat',...
    BlockID,minId,maxId,NSampleAll,hStr)],'LDEPertOutAllSample','L2Diff_AllSample','LDETrajAll','SaveIdUsed')