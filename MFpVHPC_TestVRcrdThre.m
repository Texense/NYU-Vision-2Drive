
function [] = MFpVHPC_TestVRcrdThre(vRcrdThre)
CurrentFolder = pwd
addpath(CurrentFolder)
addpath([CurrentFolder '/Utils'])
addpath([CurrentFolder '/Data'])
SaveFolder = [CurrentFolder '/Figures/Demo082721/'];
addpath(SaveFolder)
DataFolder = [CurrentFolder '/Figures/Demo082121/'];
addpath(DataFolder)

S = load('AllMFPixPara.mat');

%% Start parallel computation
cluster = parpool([4 128]);
%vRcrdThre = 0.05;

mVLIF = zeros(5,S.PixNum); FrLIF = zeros(5,S.PixNum);
f_EnIOut = cell(S.PixNum,1);
meanVs = cell(S.PixNum,1);
SteadyIndicate = zeros(S.PixNum,1);
FailureIndicate = zeros(S.PixNum,1);
parfor  PInd = 1:900
        %meanVs = [VSonP;VConP;VSoffP;VCoffP;VIP]
        f_pre = [S.FrSOnPixVec(PInd) ;
                 S.FrCOnPixVec(PInd);
                 S.FrSOffPixVec(PInd);
                 S.FrCOffPixVec(PInd);
                 S.FrIPixVec(PInd)];
        % Input
        NlgnS = S.N_Slgn; NlgnC = S.N_Clgn; NlgnI = S.N_Ilgn;
        rL6E = (S.L6S_Pixel(PInd) + S.L6C_Pixel(PInd))/2; rL6I = S.L6I_Pixel(PInd);
        lgn_SOnOff = [S.lambda_SOn_Pixel(PInd)/NlgnS;
                      S.lambda_SOff_Pixel(PInd)/NlgnS];
        lgn_COnOff = [S.lambda_COn_Pixel(PInd)/NlgnC;
                      S.lambda_COff_Pixel(PInd)/NlgnC];
        lgn_I =       S.lambda_I_Pixel/NlgnI;
        % L4 Input and parameters
        N_PreSynPix = [S.C_SS_Pixel_Us(PInd, PInd),S.C_CS_Pixel_Us(PInd, PInd),S.C_IS_Pixel_Us(PInd, PInd);
                       S.C_SC_Pixel_Us(PInd, PInd),S.C_CC_Pixel_Us(PInd, PInd),S.C_IC_Pixel_Us(PInd, PInd);
                       S.C_SI_Pixel_Us(PInd, PInd),S.C_CI_Pixel_Us(PInd, PInd),S.C_II_Pixel_Us(PInd, PInd)];
%         N_PreSynPix(1,1) = C_SS_Pixel_Us(PInd, PInd);%mean(diag(C_SS_Pixel_Us)); %;
%         N_PreSynPix(1,2) = C_CS_Pixel_Us(PInd, PInd);%mean(diag(C_CS_Pixel_Us)); %;
%         N_PreSynPix(1,3) = C_IS_Pixel_Us(PInd, PInd);%mean(diag(C_IS_Pixel_Us)); %;
%         N_PreSynPix(2,1) = C_SC_Pixel_Us(PInd, PInd);%mean(diag(C_SC_Pixel_Us)); %;
%         N_PreSynPix(2,2) = C_CC_Pixel_Us(PInd, PInd);%mean(diag(C_CC_Pixel_Us)); %;
%         N_PreSynPix(2,3) = C_IC_Pixel_Us(PInd, PInd);%mean(diag(C_IC_Pixel_Us)); %;
%         N_PreSynPix(3,1) = C_SI_Pixel_Us(PInd, PInd);%mean(diag(C_SI_Pixel_Us)); %;
%         N_PreSynPix(3,2) = C_CI_Pixel_Us(PInd, PInd);%mean(diag(C_CI_Pixel_Us)); %;
%         N_PreSynPix(3,3) = C_II_Pixel_Us(PInd, PInd);%mean(diag(C_II_Pixel_Us)); %;
        
        L4SE = (S.C_SS_Pixel_Us(PInd,:) *    S.FrSPixVec       + S.C_SC_Pixel_Us(PInd,:) *    S.FrCPixVec)...
              - S.C_SS_Pixel_Us(PInd,PInd) * S.FrSPixVec(PInd) - S.C_SC_Pixel_Us(PInd,PInd) * S.FrCPixVec(PInd);
        L4SI =  S.C_SI_Pixel_Us(PInd,:) *    S.FrIPixVec       - S.C_SI_Pixel_Us(PInd,PInd) * S.FrIPixVec(PInd);
        L4CE = (S.C_CS_Pixel_Us(PInd,:) *    S.FrSPixVec       + S.C_CC_Pixel_Us(PInd,:) *    S.FrCPixVec)...
              - S.C_CS_Pixel_Us(PInd,PInd) * S.FrSPixVec(PInd) - S.C_CC_Pixel_Us(PInd,PInd) * S.FrCPixVec(PInd);
        L4CI =  S.C_CI_Pixel_Us(PInd,:) *    S.FrIPixVec       - S.C_CI_Pixel_Us(PInd,PInd) * S.FrIPixVec(PInd);
        L4IE = (S.C_IS_Pixel_Us(PInd,:) *    S.FrSPixVec       + S.C_IC_Pixel_Us(PInd,:) *    S.FrCPixVec)...
              - S.C_IS_Pixel_Us(PInd,PInd) * S.FrSPixVec(PInd) - S.C_IC_Pixel_Us(PInd,PInd) * S.FrCPixVec(PInd);
        L4II =  S.C_II_Pixel_Us(PInd,:) *    S.FrIPixVec       - S.C_II_Pixel_Us(PInd,PInd) * S.FrIPixVec(PInd);
        
        LIFSimuT = 10000;
        Fr_MFinv = f_pre;
        [mVLIF(:,PInd),FrLIF(:,PInd)] = LIF1Pixel(Fr_MFinv, N_PreSynPix, L4SE,L4SI, L4CE,L4CI, L4IE,L4II,...
                                                  S.S_EE, S.S_EI, S.S_IE,S.S_II,S.p_EEFail,...
                                                  S.S_EL6,S.S_IL6,rL6E,rL6I,S.S_amb,  S.rE_amb,S.rI_amb,...%7 L6 Amb                                   
                                                  lgn_SOnOff,lgn_COnOff,lgn_I,NlgnS,NlgnC,NlgnI, S.S_Elgn,S.S_Ilgn,...
                                                  S.tau_ampa_R,S.tau_ampa_D,S.tau_nmda_R,S.tau_nmda_D,S.tau_gaba_R,S.tau_gaba_D,S.tau_ref,...
                                                  S.rhoE_ampa,S.rhoE_nmda,S.rhoI_ampa,S.rhoI_nmda,...
                                                  S.gL_E,S.gL_I,S.Ve,S.Vi,LIFSimuT, S.dt, vRcrdThre);

        HyperPara = {'Traj',50,50,1,5000,vRcrdThre};
        tic
       [f_EnIOut{PInd},meanVs{PInd},loop,SteadyIndicate(PInd),FailureIndicate(PInd)]...
           = MFpV_SinglePixel(...
...% MF Parameters                     
                     N_PreSynPix, L4SE,L4SI, L4CE,L4CI, L4IE,L4II,... %3 
                     S.S_EE, S.S_EI, S.S_IE,S.S_II,S.p_EEFail,... %5
                     S.S_EL6,S.S_IL6,rL6E,rL6I,S.S_amb,S.rE_amb,S.rI_amb,...%7 L6 Amb                                   
                     lgn_SOnOff, lgn_COnOff,lgn_I,NlgnS,NlgnC,NlgnI, S.S_Elgn,S.S_Ilgn,... %7
                     S.gL_E,S.gL_I,S.Ve,S.Vi, S.tau_ref,... %5
...% Below are LIF details
                     S.tau_ampa_R,S.tau_ampa_D,S.tau_nmda_R,S.tau_nmda_D,S.tau_gaba_R,S.tau_gaba_D,... %7
                     S.rhoE_ampa,S.rhoE_nmda,S.rhoI_ampa,S.rhoI_nmda,... %4
                     HyperPara);
        toc
    
end
CurrentFolder = pwd;
SaveFolder = [CurrentFolder '/Figures/Demo082721/'];
save([SaveFolder 'MFpVPixVth' num2str(vRcrdThre) '.mat'],...
      'mVLIF','FrLIF','f_EnIOut','meanVs','SteadyIndicate','FailureIndicate')   

end