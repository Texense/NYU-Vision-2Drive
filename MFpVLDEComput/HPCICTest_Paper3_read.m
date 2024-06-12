%% HPC for large amount of IC tests
% RadiusInd: 10^-RadiusInd when using
% SampleSize: specify an integer. Fix
% SaveIDRange [min max]
function [] = HPCICTest_Paper3_read(RadiusInd,SampleSize,minId,maxId, varargin)
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

%% 4.1 Test a large sample
NSample = SampleSize;
% if length(varargin)>0
%     p = StepSize;
% else
%     p = 0.33;
% end
% load([SaveFolder sprintf('Paper3LocalTest_Rad%d_size%d_ID%d_h%.2f.mat',...
%     RadiusInd,NSample,SaveID,p)],'L2Diff_OneStepAll','DiffVecAll','LDEPertOutAll','LDEequv')
load([SaveFolder sprintf('Paper3LocalTest_Rad%d_size%d_ID%d.mat',...
    RadiusInd,NSample,1)],'L2Diff_OneStepAll')
EpocTest = size(L2Diff_OneStepAll,2)-1;
NSampleAll = SampleSize * maxId;

LDEPertOutAllSample = cell(NSampleAll,1);
L2Diff_AllSample = zeros(NSampleAll,EpocTest+1);

SaveIdUsed = 0;
for SaveId = minId:maxId
    
    if isfile([SaveFolder sprintf('Paper3LocalTest_Rad%d_size%d_ID%d.mat',...
            RadiusInd,NSample,SaveId)])
        tic
        load([SaveFolder sprintf('Paper3LocalTest_Rad%d_size%d_ID%d.mat',...
            RadiusInd,NSample,SaveId)],'L2Diff_OneStepAll','LDEPertOutAll')
        SampleIdRange = (SaveId-1)*NSample + 1 : SaveId*NSample;
        L2Diff_AllSample(SampleIdRange,:) = L2Diff_OneStepAll;
        for SampleId = SampleIdRange
            LDEPertOutAllSample{SampleId} = LDEPertOutAll{SampleId - (SaveId-1)*NSample}{end};
        end
        SaveIdUsed = SaveIdUsed + 1;
        fprintf('SaveId %d loaded, \n', SaveId)
        clear L2Diff_OneStepAll LDEPertOutAll
        toc
    else
        fprintf('SaveId %d missing, \n', SaveId)
    end

    
end
save([SaveFolder sprintf('Paper3LocalTestAll_Rad%d_IDRange%d-%d.mat',...
    RadiusInd,minId,maxId)],'LDEPertOutAllSample','L2Diff_AllSample','SaveIdUsed')