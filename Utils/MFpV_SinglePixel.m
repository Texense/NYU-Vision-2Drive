%% MF+V for Pixels. E is divided into S and C cells
%% Input: 
%        N_PreSynPix   within Pixel->Pixel connectivity matrix 
%                           3*3 Post(R)/Pre(C): S, C, I
%                                                       S
%                                                       C
%                                                       I
%        L4E, L4I                 Total E/I input kick numbers
%        Assume L4SE/CE/IE are proportional to presynaptic neuron numbers
%        S_EE,S_EI,S_IE,S_II      synaptic strength
%        S_EL6,S_IL6,rE_L6,rI_L6, L6 Input, All Scalar
%        S_amb,rE_amb,rI_amb      amb Input, All Scalar
%        p_EEFail                 E-to-E Synaptic failure prob
%        lgn_EOnOff,lgn_I         LGN input rate. Phase OnOff for E (2*1 vec) 
%        S_Elgn S_Ilgn            LGN strength of drives
%        NlgnS,NlgnC,NlgnI        LGN neuron # to SCI cells
%        gL_E,gL_I                Leaky time constants
%        Ve,Vi                    Reversal potentials
%        HyperPara           Cell. Entries are simulation hyperparameters
%                            1st: 'Mean' or 'Traj', indicate the form of the output
%                            2nd: Sample Number after stopping criteria
%                            3rd: Max Iteration before converged
%                            4th: Stepsize h
%                            5th: LIF simulation time
% Output:f_EnI               Estimation of firing rates, E and I; A sequences
%        meanVs              mean V of E and I
%        loop                Number of loops
%        SteadyIndicate      logical value for convergence
%% Ver 5:       For single pixels
% iteration
% Zhuo-Cheng Xiao 07/27/2021
function [f_EnIOut,meanVs,loop,SteadyIndicate,FailureIndicate]...
           = MFpV_SinglePixel(...
...% MF Parameters                     
                     N_PreSynPix, L4SE,L4SI, L4CE,L4CI, L4IE,L4II,... %3 
                     S_EE,S_EI,S_IE,S_II,p_EEFail,... %5
                     S_EL6,S_IL6,rL6E,rL6I,S_amb,rE_amb,rI_amb,...%7 L6 Amb                                   
                     lgn_EOnOff,lgn_I,NlgnS,NlgnC,NlgnI, S_Elgn,S_Ilgn,... %7
                     gL_E,gL_I,Ve,Vi, tau_ref,... %5
...% Below are LIF details
                     tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,... %7
                     rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,... %4
                     HyperPara) % if varagin non empty, we only export the last state
%% Hyperparameters
N_Hyp = length(HyperPara);
if N_Hyp > 0  % Specify: The number of loops I want, after stopping criteria met    
    AveLoop = HyperPara{2};
else 
    AveLoop = 100;
end

if N_Hyp > 1 % Specify: Maximum nubmer of loops before stopping
        StopLoop = HyperPara{3};
else 
        StopLoop = AveLoop;
end

if N_Hyp > 2 % Specify: stepsize h
    h_Step = HyperPara{4};
else
    h_Step = 1;        
end

if N_Hyp > 3 % Specify: LIF simulation timef_pre
    LIFSimuT = HyperPara{5};
else
    LIFSimuT = 20*1e3;    % unit in ms    
end

% initialize with a reasonable guess     
mVSOn = 0.67; mVSOff = 0.57; 
mVCOn = 0.67; mVCOff = 0.57;
mVI = 0.77; 
f_pre = zeros(5,1);
meanVs = [mVSOn;mVSOff;mVCOn;mVCOff;mVI];
f_SCIIni = MF_SCI_1Pix(N_PreSynPix, L4SE,L4SI, L4CE,L4CI, L4IE,L4II,...
                       S_EE,S_EI,S_IE,S_II,p_EEFail,...
                       S_EL6,S_IL6,rL6E,rL6I,S_amb,rE_amb,rI_amb,...%7 L6 Amb                                   
                       lgn_EOnOff,lgn_I,NlgnS,NlgnC,NlgnI, S_Elgn,S_Ilgn,... %7
                       gL_E,gL_I,Ve,Vi, tau_ref, meanVs, f_pre);
f_EnIOut = f_SCIIni;

loop = 0;
SteadyCounter = 0; % Indicate the number of loops after steady condition
SteadyIndicate = false;
TestPoints = floor(15); % How many consecutive points we test
%while( norm([mVEpre;mVIpre] - [mVE;mVI]) > 0.01 || norm(f_EnIpre - f_EnI0)>0.1) %%% relative difference for firing rates!!

FailureIndicate = 0;
Suspicious = false;
while SteadyCounter<AveLoop %the formal ending condition
% simulate one neuron with input                             
[mVE,~] = MEanFieldEst_SingleCell_L6('e', f_SCIIni, ...
                                         N_EE,N_EI,N_IE,N_II,...
                                         S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                         lgn_EOnOff,S_Elgn,rE_amb,S_amb,...
                                         lgn_I,S_Ilgn,rI_amb,...
                                         S_EL6,S_IL6,rL6E,rL6I,...
                                         tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                                         rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                                         gL_E,gL_I,Ve,Vi,LIFSimuT);
[mVI,~] = MEanFieldEst_SingleCell_L6('i', f_SCIIni, ...
                                         N_EE,N_EI,N_IE,N_II,...
                                         S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                         lgn_EOnOff,S_Elgn,rE_amb,S_amb,...
                                         lgn_I,S_Ilgn,rI_amb,...
                                         S_EL6,S_IL6,rL6E,rL6I,...
                                         tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                                         rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                                         gL_E,gL_I,Ve,Vi,LIFSimuT);
                                     
%% NOW! consider the previous mVs if it already satisfies steady condition
if loop>100
    mVEIn = mean(meanVs(1,end-10+1:end)) * 0.9 + mVE*0.1;
    mVIIn = mean(meanVs(2,end-10+1:end)) * 0.9 + mVI*0.1;
else
     mVEIn = mVE;
     mVIIn = mVI;
end

% estimate with ref now
f_EnI0 = MeanFieldEst_BkGd_ref_L6(N_EE,N_EI,N_IE,N_II,...
                                   S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                   lgn_EOnOff,S_Elgn,rE_amb,S_amb,...
                                   lgn_I,S_Ilgn,rI_amb,...
                                   S_EL6,S_IL6,rL6E,rL6I,...
                                   gL_E,gL_I,Ve,Vi,mVEIn,mVIIn,...
                                   tau_ref,f_SCIIni);

Suspicious = (min(f_EnI0)<0);
                               
%f_EnI0 = max([f_EnI0,[0;0]],[],2);
%f_EnI0 = abs(f_EnI0);                                     
%% The new input!
f_SCIIni = f_EnI0*h_Step + f_SCIIni*(1-h_Step);

loop = loop+1;

f_EnIOut = [f_EnIOut,f_EnI0];
meanVs = [meanVs, [mVE;mVI]];

if ~SteadyIndicate
  if loop >= TestPoints && max(std(f_EnIOut(:,end-TestPoints+1:end),0,2) ...
                            ./mean(f_EnIOut(:,end-TestPoints+1:end),2))<0.05 % std/mean for the last 10 samples
     SteadyIndicate = true;
  end  
else 
    SteadyCounter = SteadyCounter+1;
end

if (loop>100 | SteadyIndicate) & Suspicious
    FailureIndicate = 1;
end

% break out if not reaching convergence after 100 iterations. Tbis number
% should be larger than end condition of SteadyCounter
if (~SteadyIndicate && loop >= StopLoop) 
    disp('Firing rates unconverged')
    break
end
end

if N_Hyp > 0 && strcmpi(HyperPara(1),'Mean') % Specify: I don't need the trajectory but the final ones    
    f_EnIOut = mean(f_EnIOut(:,end-50:end),2);
    meanVs   = mean(meanVs(:,end-50:end),2);
end
end



%% mean-field est With ref. We use parameters and mean Vs to estimate firing rates
% Input: N_PreSynPix         connectivity matrix for SCI within pixel. 3*3
%        S_EE,S_EI,S_IE,S_II synaptic strength
%        S_EL6,S_IL6,rE_L6,rI_L6 L6 Input
%        p_EEFail            Synaptic failure prob
%        lambda_E lambda_I   LGN input
%        rE_amb rI_amb       Ambient input
%        S_Elgn S_Ilgn S_amb Synaptic strength of drives
%        gL_E,gL_I           Leaky time constants
%        Ve,Vi               Reversak potentials
%        mVE,mVI             Mean Vs, collected from simulation
%        tau_ref             ref period, in ms
%        f_pre               from previous
% Output:Fr_MFinv            Estimation of firing rates, Son, Soff, Con, Coff, I

function Fr_MFinv = MF_SCI_1Pix(N_PreSynPix, L4SE,L4SI, L4CE,L4CI, L4IE,L4II,...
                             S_EE,S_EI,S_IE,S_II,p_EEFail,...
                             S_EL6,S_IL6,rL6E,rL6I,S_amb,rE_amb,rI_amb,...%7 L6 Amb                                   
                             lgn_EOnOff,lgn_I,NlgnS,NlgnC,NlgnI, S_Elgn,S_Ilgn,... % lgn
                             gL_E,gL_I,Ve,Vi, tau_ref, meanVs, f_pre)                             
%% PreSynaptic neuron numbers. External and internal (pixel)
N_SSi = N_PreSynPix(1,1); N_CSi = N_PreSynPix(1,2); N_ISi = N_PreSynPix(1,3); %% REally?? Row/Col
N_SCi = N_PreSynPix(2,1); N_CCi = N_PreSynPix(2,2); N_ICi = N_PreSynPix(2,3); 
N_SIi = N_PreSynPix(3,1); N_CIi = N_PreSynPix(3,2); N_IIi = N_PreSynPix(3,3); 

% Downplay current by a ref factor
RefM = diag(1-f_pre*tau_ref/1000);
% Mats
MatSS = (S_EE*(1-p_EEFail))*N_SSi; MatCS = (S_EE*(1-p_EEFail))*N_CSi; MatIS = S_IE * N_ISi;
MatSC = (S_EE*(1-p_EEFail))*N_SCi; MatCC = (S_EE*(1-p_EEFail))*N_CCi; MatIC = S_IE * N_ICi;
MatSI = S_EI *              N_SIi; MatCI = S_EI *              N_CIi; MatII = S_II * N_IIi;

eVSOn  = (Ve-meanVs(1));  iVSOn  = (Vi-meanVs(1));
eVCOn  = (Ve-meanVs(2));  iVCOn  = (Vi-meanVs(2));
eVSOff = (Ve-meanVs(3));  iVSOff = (Vi-meanVs(3));
eVCOff = (Ve-meanVs(4));  iVCOff = (Vi-meanVs(4));
eVI    = (Ve-meanVs(5));  iVI    = (Vi-meanVs(5));
% post/pre SOn              COn              SOff             COff             I
ConnMat = [MatSS/2.*eVSOn,  MatSC/2.*eVSOn,  MatSS/2.*eVSOn,  MatSC/2.*eVSOn,  MatSI.*iVSOn;  % SOn
           MatCS/2.*eVCOn,  MatCC/2.*eVCOn,  MatCS/2.*eVCOn,  MatCC/2.*eVCOn,  MatCI.*iVCOn;  % COn
           MatSS/2.*eVSOff, MatSC/2.*eVSOff, MatSS/2.*eVSOff, MatSC/2.*eVSOff, MatSI.*iVSOff; % SOff
           MatCS/2.*eVCOff, MatCC/2.*eVCOff, MatCS/2.*eVCOff, MatCC/2.*eVCOff, MatCI.*iVCOff; % COff
           MatIS/2.*eVI,    MatIC/2.*eVI,    MatIS/2.*eVI,    MatIC/2.*eVI,    MatII.*iVI];   % I
% Leak On/Off
LeakSOn  = gL_E * (0-meanVs(1)) * 1e3;
LeakCOn  = gL_E * (0-meanVs(2)) * 1e3;
LeakSOff = gL_E * (0-meanVs(3)) * 1e3;
LeakCOff = gL_E * (0-meanVs(4)) * 1e3;
LeakI =    gL_I * (0-meanVs(5)) * 1e3;
LeakV = [LeakSOn;
         LeakCOn;
         LeakSOff;
         LeakCOff;
         LeakI];
% Ext
ExtSOn  = (lgn_EOnOff(1)*NlgnS*S_Elgn + rE_amb*S_amb + rL6E*S_EL6)*eVSOn *1e3 ...
        + (L4SI*S_EI)*iVSOn + L4SE*S_EE*eVSOn*(1-p_EEFail); 
ExtCOn  = (lgn_EOnOff(1)*NlgnC*S_Elgn + rE_amb*S_amb + rL6E*S_EL6)*eVCOn *1e3 ...
        + (L4CI*S_EI)*iVCOn + L4CE*S_EE*eVCOn*(1-p_EEFail);
ExtSOff = (lgn_EOnOff(2)*NlgnS*S_Elgn + rE_amb*S_amb + rL6E*S_EL6)*eVSOff *1e3...
        + (L4SI*S_EI)*iVSOn + L4SE*S_EE*eVSOff*(1-p_EEFail);
ExtCOff = (lgn_EOnOff(2)*NlgnC*S_Elgn + rE_amb*S_amb + rL6E*S_EL6)*eVCOff *1e3...
        + (L4CI*S_EI)*iVCOn + L4CE*S_EE*eVCOff*(1-p_EEFail);
ExtI =    (lgn_I        *NlgnI*S_Ilgn + rI_amb*S_amb + rL6I*S_IL6)*eVI    *1e3...
        + (L4II*S_II)*iVI   + L4IE*S_IE*eVI;
ExtV = [ExtSOn;
        ExtCOn;
        ExtSOff;
        ExtCOff
        ExtI];
    
Fr_MFinv = (eye(5)-RefM*ConnMat) \ (RefM * ( ExtV + LeakV));
%f_EnI = -(ref_fac*MatEI-eye(2))^-1*ref_fac*(Leak+VecInput);

end

%% single cell simulation: to collect mean V (and firing rates)

function [mVs,FrLIF] = LIF1Pixel(Fr_MFinv, N_PreSynPix, L4SE,L4SI, L4CE,L4CI, L4IE,L4II,...
                                 S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                 S_EL6,S_IL6,rL6E,rL6I,S_amb,rE_amb,rI_amb,...%7 L6 Amb                                   
                                 lgn_EOnOff,lgn_I,NlgnS,NlgnC,NlgnI, S_Elgn,S_Ilgn,...
                                 tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                                 rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                                 gL_E,gL_I,Ve,Vi,LIFSimuT, dt) % No more Freq
                               % Last two lines in case we have used current input...
%% First check if L4 rates match neuron numbers
if length(Fr_MFinv) == 3*PixNum
rE = (Fr_MFinv(1:PixNum) + Fr_MFinv(PixNum+1:2*PixNum))/2; 
rI = Fr_MFinv(2*PixNum+1:3*PixNum); % f_EnI in s^-1, but here we use ms^-1
rE(rE<=0) = 0; rI(rI<0) = 0;
else
    error('L4 FRs dont match!')
end
%% Setup input and record
T = LIFSimuT; % in ms. Default: 20*1e3 ms
T1s = 1e3;
tt = 0:dt:T;
t1 = 0:dt:T1s;
SampleProp = 19/20; % last half time for meanV
DroptInd = floor(length(tt)*(1-SampleProp));
% L4 input determination: Assume all Poisson
% Can be optimized in the future, but let's make var correct for now
L4EInputNow = [C_EE_Pixel_Us*rE*(1-p_EEFail); 
               C_IE_Pixel_Us*rE             ]/1000;   
L4IInputNow = [C_EI_Pixel_Us*rI             ; 
               C_II_Pixel_Us*rI             ]/1000;   
L4Pix_EventsEU  = PoissonInputForNetwork(2*PixNum,L4EInputNow,LIFSimuT*TimeFrac,dt); % E to everyone
L4Pix_EventsIU  = PoissonInputForNetwork(2*PixNum,L4IInputNow,LIFSimuT*TimeFrac,dt); % I to everyone           
% Adjust Phase variant LGN
% Note: For LGN, I did the same scaling stuff for network simulation, so
% keep it for now.
tMod = T1s/LGNFreq; MaxOnPhase = tMod/2;
OnOffPhase = floor(mod(t1,tMod)/MaxOnPhase);
OnOffPhasePix = zeros(size(lgnEPix_Events));
OnOffPhasePix(:,OnOffPhase == 0) = repmat(lambda_EOff_Pixel, 1, sum(OnOffPhase == 0));
OnOffPhasePix(:,OnOffPhase == 1) = repmat(lambda_EOn_Pixel, 1, sum(OnOffPhase == 1));
OnOffMulp = OnOffPhasePix./repmat(lambda_E_Pixel,1,length(t1));
% Leakage
gL = [gL_E*ones(size(rE)); gL_I*ones(size(rI))];
% Initialize records
sumVOn = zeros(2*PixNum, 1);
sumVOff = zeros(2*PixNum, 1);
VNanOnCount = zeros(2*PixNum, 1);
VNanOffCount = zeros(2*PixNum, 1);
vt = zeros(2*PixNum, 1);
%% Evolve single neurons
RefTimer = zeros(2*PixNum, 1); 
vRecordNum = 0;
mVEon = zeros(PixNum,floor(T/T1s));
mVEoff = zeros(PixNum,floor(T/T1s));
mVI = zeros(PixNum,floor(T/T1s));
%% Can precompute all Gs...
for tInd = 1:length(tt)-1
    % First, Get input matrices from series
    InpWin = T1s; FrameNum = floor(InpWin/dt);
    FrameInd = mod(tInd, FrameNum);
    if FrameInd == 0
    FrameInd = FrameNum;
    end
    
    % When sample from Gs, GAMPA and GNMDA should use same time frame;
    if FrameInd == 1 % if the first frame, recompute input mats
        vRecord = zeros(length(vt),FrameNum);
        lgnEPix_Events = lgnEPix_Events(:,randperm(length(t1))); lgnIPix_Events = lgnIPix_Events(:,randperm(length(t1)));
        AmbEPix_Events = AmbEPix_Events(:,randperm(length(t1))); AmbIPix_Events = AmbIPix_Events(:,randperm(length(t1)));
        L6EPix_Events = L6EPix_Events(:,randperm(length(t1)));   L6IPix_Events = L6IPix_Events(:,randperm(length(t1)));
        L4Pix_EventsEU = L4Pix_EventsEU(:,randperm(length(t1))); L4Pix_EventsIU = L4Pix_EventsIU(:,randperm(length(t1)));
        % Incorporate L4 and other input
        EampaInp = single(full(S_Elgn * (lgnEPix_Events + lambda_E_Pixel*dt*LGNCurInp).*OnOffMulp ...
                             + S_amb  *  AmbEPix_Events ...
                             + S_EL6  * (L6EPix_Events  + L6E_Pixel*dt*L6CurInp) * rhoE_ampa)); %  * rhoE_ampa
        IampaInp = single(full(S_Ilgn * (lgnIPix_Events+ lambda_I_Pixel*dt*LGNCurInp) ...
                             + S_amb  *  AmbIPix_Events ...
                             + S_IL6  * (L6IPix_Events  + L6I_Pixel*dt*L6CurInp) * rhoI_ampa)); %  * rhoI_ampa
        
        EnmdaInp = single(full(S_EL6  * (L6EPix_Events  + L6E_Pixel*dt*L6CurInp) * rhoE_nmda)); %
        InmdaInp = single(full(S_IL6  * (L6IPix_Events  + L6I_Pixel*dt*L6CurInp) * rhoI_nmda));
        L4InputfEampa = single(full( [S_EE * L4Pix_EventsEU(1:PixNum,:)          * rhoE_ampa;
                                      S_IE * L4Pix_EventsEU(PixNum+1:2*PixNum,:) * rhoI_ampa] ));
        L4InputfEnmda = single(full( [S_EE * L4Pix_EventsEU(1:PixNum,:)          * rhoE_nmda;
                                      S_IE * L4Pix_EventsEU(PixNum+1:2*PixNum,:) * rhoI_nmda] ));
        L4InputfI     = single(full( [S_EI * L4Pix_EventsIU(1:PixNum,:);
                                      S_II * L4Pix_EventsIU(PixNum+1:2*PixNum,:)] ));
        %% Precompute All Conductances: Speed up by ifft/fft
        winAMPA = 0:dt:tau_ampa_D*5;
        winNMDA = 0:dt:tau_nmda_D*5;
        winGABA = 0:dt:tau_gaba_D*5;
        KerAMPA = 1/(tau_ampa_D-tau_ampa_R) * (exp(-winAMPA/tau_ampa_D) - exp(-winAMPA/tau_ampa_R));
        KerNMDA = 1/(tau_nmda_D-tau_nmda_R) * (exp(-winNMDA/tau_nmda_D) - exp(-winNMDA/tau_nmda_R));
        KerGABA = 1/(tau_gaba_D-tau_gaba_R) * (exp(-winGABA/tau_gaba_D) - exp(-winGABA/tau_gaba_R));
        KerAMPA = KerAMPA / (sum(KerAMPA)*dt);
        KerNMDA = KerNMDA / (sum(KerNMDA)*dt);
        KerGABA = KerGABA / (sum(KerGABA)*dt);
        n = size(EampaInp,2);
        GAMPA = ifft(fft(([EampaInp; IampaInp] + L4InputfEampa)',n) .* repmat(fft(KerAMPA',n),1,2*PixNum))';
        GNMDA = ifft(fft(([EnmdaInp; InmdaInp] + L4InputfEnmda)',n) .* repmat(fft(KerNMDA',n),1,2*PixNum))';
        GGABA = ifft(fft(L4InputfI',n)                              .* repmat(fft(KerGABA',n),1,2*PixNum))';
        GE = GAMPA + GNMDA; GI = GGABA;
        GEU = GE;  
        GIU = GI; 
        vRecordNum = vRecordNum + 1;
    end
    
    % Firstly, refrectory neurons get out if timer reachs t_ref
    RefTimer(isnan(vt)) = RefTimer(isnan(vt)) + dt;
    vt(RefTimer>=tau_ref) = 0;
    RefTimer(RefTimer>=tau_ref) = 0;
    
    ov  = vt + dt*(-gL.*vt - GEU(:,FrameInd).*(vt-Ve) - GIU(:,FrameInd).*(vt-Vi));
    ov(ov>=1) = nan;
    vRecord(:,FrameInd) = ov;
    
    if FrameInd == FrameNum
        mVEon(:,vRecordNum) = nanmean(vRecord(1:PixNum , find(OnOffPhase == 1)), 2);
        mVEoff(:,vRecordNum) = nanmean(vRecord(1:PixNum , find(OnOffPhase == 0)), 2);
        mVI(:,vRecordNum) = nanmean(vRecord(PixNum+1:2*PixNum,:),2);
    end
    % Compute meanV
     if tInd > DroptInd
         if OnOffPhase(FrameInd) == 1
%             VNanOnCount = VNanOnCount + isnan(ov);
%             osv = ov; osv(isnan(osv)) = 0;
%             sumVOn = sumVOn + osv;
             FrEOnLIF = FrEOnLIF + SpNow(1:PixNum);
         elseif OnOffPhase(FrameInd) == 0
%       % sumV = sum([sumV,ov],2,'omitnan');
%             VNanOffCount = VNanOffCount + isnan(ov);
%             osv = ov; osv(isnan(osv)) = 0;
%             sumVOff = sumVOff + osv;
             FrEOffLIF = FrEOffLIF + SpNow(1:PixNum);   
         end
         FrILIF = FrILIF + SpNow(PixNum+1:2*PixNum);
     end
    % Transfer variables
    vt = ov; 
end
mVOnLIF = sumVOn./((length(tt)-1 - DroptInd)/2 - VNanOnCount);
mVOffLIF = sumVOff./((length(tt)-1 - DroptInd)/2 - VNanOffCount);
mVEOnLIF = mVOnLIF(1:PixNum); mVEOffLIF = mVOffLIF(1:PixNum);
mVILIF = (mVOnLIF(PixNum+1:2*PixNum) + mVOffLIF(PixNum+1:2*PixNum))/2;
% fr = length(find(spike>(1-SampleProp)*T))/(T*SampleProp/1000);
end