%% Read drive data on HPC

%% 0: make dirs
function [] = Paper3_ReadDataTEST(sampleId)
CurrentFolder = pwd
%FigurePath = [CurrentFolder '/Figures'];
addpath(CurrentFolder)
addpath([CurrentFolder '/Utils'])
addpath([CurrentFolder '/Data'])
DataFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/'];
SaveToFolder = [CurrentFolder '/Data/Paper2_NetworkTuning/Fig1V4/Paper3NWData/'];
addpath(DataFolder)
addpath(SaveToFolder)

%load('DriveWkSp_SCSepa_Cconst_Conn.mat','EcplxInd');

SIlgnMptAll = 1:0.04:1.2;
GratingAll = 0:7.5:22.5;
%SampleNum = 10;
aa = length(SIlgnMptAll); bb = length(GratingAll);

for SIlgnInd = 1:aa
    for AngInd = 1:bb
        SIlgnMpt = SIlgnMptAll(SIlgnInd);
        Grating = GratingAll(AngInd);
        % Frst setup network

        % T partition
        T = 10000; %dt = 0.1;
        TPar = 10;

        %% Read data
        ReadFolder = [SaveToFolder sprintf('SIlgnMpt%.3f_Ang%.1f_sample%d/',SIlgnMpt,Grating,sampleId)];
        fprintf('SIlgnMpt%.3f_Ang%.1f_sample%d\n',SIlgnMpt,Grating,sampleId)
        if isfolder(ReadFolder)
            % read Drive Frs
            for TSec = 1:TPar
                DriveFName = [sprintf('DriveWkSp_SIlgnMpt%.3f_Ang%.1f',SIlgnMpt,Grating) num2str(TSec) 's.mat'];
                fprintf('%s\n',[ReadFolder DriveFName])
                load([ReadFolder DriveFName],'NWTrace');

                SpECurrent = []; SpICurrent = [];
                for WinInd = 1:length(NWTrace)
                    SpECurrent = [SpECurrent; NWTrace(WinInd).SpEs];
                    SpICurrent = [SpICurrent; NWTrace(WinInd).SpIs];
                end

                fprintf('Test:TotalSpETime = %.7f\n',sum(SpECurrent(:),"all",'omitnan'))
                clear NWTrace
            end

        else
            disp('No such data folder, continue...')
            continue
        end
    end
end