%% MF+v for the field. Ver1: LGN on/off not considered so far.
% Input: NW parameters, 
%        connectivity matrices,
%        External input rates
%        Pixel setups
% Output: FrE, FrI, mVE, mVI

% Note: Let's not use anything to speed up linear inverse for now.
%% Functions quoting outside this file:
% 1. function [SpaPixMat,NnEPixel] = NeuVec2Pixel(FrE,NnE,NPxX,NPxY)
function [FrEPixVecOut, FrIPixVecOut, ...
          mVEPixVecOut, mVIPixVecOut] = MFvField_NoCorrection(C_EE_Fix,C_EI_Fix,C_IE_Fix,C_II_Fix,...     %4
                                                        S_EE,S_EI,S_IE,S_II,p_EEFail,...            %5
                                                        lambda_EOn_drive, lambda_EOff_drive, LGNFreq, S_Elgn,rE_amb,S_amb,...      %6 lambda_E drive is vector for each cell
                                                        lambda_I_drive,                               S_Ilgn,rI_amb,...            %3
                                                        S_EL6,S_IL6,rE_L6_Drive,rI_L6_Drive,...     %4 
                                                        ... % L6 drives are vectors for each cell. Vital since length(rQL6) for NE and NI
                                                        tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,... %7
                                                        rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,... %4
                                                        gL_E,gL_I,Ve,Vi,...                         %4
                                                        N_HC,NnE,NnI,NPixX, NPixY, varargin)        %5+x % if varagin non empty, we only export the last state
                                                        %This line: spatial indexes of E and I neurons. Numbers of pixels
%% Hyperparameters for iterations
if nargin > 41+1  % Specify: The number of loops I want, after stopping criteria met    
    AveLoop = varargin{2};
else 
    AveLoop = 100;
end

if nargin > 42+1 % Specify: Maximum nubmer of loops before stopping
        StopLoop = varargin{3};
else 
        StopLoop = AveLoop;
end

if nargin > 43+1 % Specify: stepsize h
    h_Step = varargin{4};
else
    h_Step = 1;        
end

if nargin > 44+1 % Specify: LIF simulation timef_pre
    LIFSimuT = varargin{5};
else
    LIFSimuT = 20*1e3;    % unit in ms    
end
%% Get matrices for pixels
% First, get connectivity matrix between Pixels
PixNum = NPixX*N_HC*NPixY*N_HC; % Number of pixels
C_EE_Pixel = zeros(PixNum);
C_EI_Pixel = zeros(PixNum);
C_IE_Pixel = zeros(PixNum);
C_II_Pixel = zeros(PixNum);
[~,NnEPixel] = NeuVec2Pixel(zeros(length(NnE.X),1),NnE,NPixX*N_HC,NPixY*N_HC);
[~,NnIPixel] = NeuVec2Pixel(zeros(length(NnI.X),1),NnI,NPixX*N_HC,NPixY*N_HC);
tic
parfor PixIndPost = 1:PixNum
    for PixIndPre = 1:PixNum
        C_EE_Pixel(PixIndPost,PixIndPre) = mean(sum(C_EE_Fix(NnEPixel.Vec == PixIndPost, NnEPixel.Vec == PixIndPre),2));
        C_EI_Pixel(PixIndPost,PixIndPre) = mean(sum(C_EI_Fix(NnEPixel.Vec == PixIndPost, NnIPixel.Vec == PixIndPre),2));
        C_IE_Pixel(PixIndPost,PixIndPre) = mean(sum(C_IE_Fix(NnIPixel.Vec == PixIndPost, NnEPixel.Vec == PixIndPre),2));
        C_II_Pixel(PixIndPost,PixIndPre) = mean(sum(C_II_Fix(NnIPixel.Vec == PixIndPost, NnIPixel.Vec == PixIndPre),2));
    end    
end
toc
C_EE_Pixel_Us = full(C_EE_Pixel);
C_IE_Pixel_Us = full(C_IE_Pixel);nonlinear dynamics
C_EI_Pixel_Us = full(C_EI_Pixel);
C_II_Pixel_Us = full(C_II_Pixel);
% Then get input vec for each pixel
lambda_EOn_Pixel = zeros(size(mVEPixVec));
lambda_EOff_Pixel = zeros(size(mVEPixVec));
L6E_Pixel = zeros(size(mVEPixVec));
L6I_Pixel = zeros(size(mVEPixVec));
for PixInd = 1:PixNum
    lambda_EOn_Pixel(PixInd)  = mean(lambda_EOn_drive(NnEPixel.Vec == PixInd));
    lambda_EOff_Pixel(PixInd) = mean(lambda_EOff_drive(NnEPixel.Vec == PixInd));
    L6E_Pixel(PixInd) = mean(rE_L6_Drive(NnEPixel.Vec == PixInd));
    L6I_Pixel(PixInd) = mean(rI_L6_Drive(NnIPixel.Vec == PixInd));
end
lambda_I_Pixel = lambda_I_drive;
% Then initialize FrPix and mVPix vectors
% Start from uniform guessed values
FrEIni = 16; FrIIni = 64;
FrEPixIni = FrEIni *ones(PixNum,1);
FrIPixIni = FrIIni *ones(PixNum,1);
mVEPixVec = 0.7 *ones(PixNum,1);
mVIPixVec = 0.8 *ones(PixNum,1);
% L4EInputIni = [C_EE_Pixel_Us*FrEPixIni*(1-p_EEFail);C_IE_Pixel_Us*FrEPixIni]/1e3;   
% L4IInputIni = [C_EI_Pixel_Us*FrIPixIni           ;  C_II_Pixel_Us*FrIPixIni]/1e3;   
%% PreSet Input events to Pixel-LIF neurons
LGNCurInp = 0; L6CurInp = 0;
dt = 0.1; TimeFrac = 1e3/LIFSimuT;
lambda_E_Pixel = (lambda_EOn_Pixel + lambda_EOff_Pixel)/2;
tic
lgnEPix_Events = PoissonInputForNetwork(PixNum,lambda_E_Pixel*(1-LGNCurInp),LIFSimuT*TimeFrac,dt);
lgnIPix_Events = PoissonInputForNetwork(PixNum,lambda_I_Pixel*(1-LGNCurInp),LIFSimuT*TimeFrac,dt);
AmbEPix_Events = PoissonInputForNetwork(PixNum,rE_amb,LIFSimuT*TimeFrac,dt);
AmbIPix_Events = PoissonInputForNetwork(PixNum,rI_amb,LIFSimuT*TimeFrac,dt);
L6EPix_Events  = PoissonInputForNetwork(PixNum,L6E_Pixel*(1-L6CurInp),LIFSimuT*TimeFrac,dt);
L6IPix_Events  = PoissonInputForNetwork(PixNum,L6I_Pixel*(1-L6CurInp),LIFSimuT*TimeFrac,dt);
% Idea for L4: changing every loop, but we can always rescale from the
% original event counts in each bin
toc

%% Do the following iterations recursively
for Epoch = 1:10
    tic
% PH for MF: Need variable modification
    Fr_MFinv = MFgivV(S_EE,S_EI,S_IE,S_II,p_EEFail,...
                     S_Elgn,S_Ilgn, rE_amb,rI_amb,S_amb, S_EL6,S_IL6, ...
                     gL_E,gL_I, Ve,Vi,...    
                     C_EE_Pixel_Us, C_EI_Pixel_Us, C_IE_Pixel_Us, C_II_Pixel_Us,...
                     lambda_EOn_Pixel,lambda_EOff_Pixel,lambda_I_Pixel, L6E_Pixel, L6I_Pixel,...
                     mVEOnPixVec, mVEOffPixVec, mVIPixVec, PixNum, ...
                     FrEOnPixVec, FrEOffPixVec, FrIPixVec, tau_ref);
    
    if Epoch < 10
       [mVEOnPixNew,mVEOffPixNew,mVIPixNew] =  ...
           LIFPixels(Fr_MFinv, L4Pix_EventsEIni, ...
                     C_EE_Pixel_Us,C_EI_Pixel_Us,C_IE_Pixel_Us,C_II_Pixel_Us,...
                     S_EE,S_EI,S_IE,S_II,p_EEFail,...
                     lgnEPix_Events,S_Elgn,AmbEPix_Events,S_amb,...
                     lgnIPix_Events,S_Ilgn,AmbIPix_Events,...
                     S_EL6,S_IL6,L6EPix_Events,L6IPix_Events,...
                     tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                     rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                     gL_E,gL_I,Ve,Vi,LIFSimuT, dt, PixNum,...
                     LGNCurInp, L6CurInp,...
                     lambda_E_Pixel,lambda_I_Pixel,L6E_Pixel,L6I_Pixel,...
                     lambda_EOn_Pixel, lambda_EOff_Pixel, LGNFreq);
       mVEOnPixVec = mVEOnPixVec*(1-h_Step) + mVEOnPixNew * h_Step;
       mVEOffPixVec = mVEOffPixVec*(1-h_Step) + mVEOffPixNew * h_Step;
       mVIPixVec = mVIPixVec*(1-h_Step) + mVIPixNew * h_Step;
   
    end
   toc
   figure(1)
   subplot 321
   ShowField(Fr_MFinv, 1:900, 30, 30 )
   caxis([0 40])
   subplot 322
   ShowField(mVEOnPixVec, 1:900, 30, 30 )
   caxis([0.64 0.77])
   subplot 323
   ShowField(Fr_MFinv, 901:1800, 30, 30 )
   caxis([0 40])
   subplot 324
   ShowField(mVEOffPixVec, 1:900, 30, 30 )
   caxis([0.64 0.77])
      subplot 323
   ShowField(Fr_MFinv, 1801:2700, 30, 30 )
   caxis([20 120])
   subplot 324
   ShowField(mVIPixVec, 1:900, 30, 30 )
   caxis([0.74 0.83])
   drawnow
end
end

%% MF Computing: giving mVs
function [Fr_MFinv] = MFgivV(S_EE,S_EI,S_IE,S_II,p_EEFail,...
                     S_Elgn,S_Ilgn, rE_amb,rI_amb,S_amb, S_EL6,S_IL6, ...
                     gL_E,gL_I, Ve,Vi,...    
                     C_EE_Pixel_Us, C_EI_Pixel_Us, C_IE_Pixel_Us, C_II_Pixel_Us,...
                     lambda_EOn_Pixel,lambda_EOff_Pixel,lambda_I_Pixel, L6E_Pixel, L6I_Pixel,...
                     mVEOnPixVec, mVEOffPixVec, mVIPixVec, PixNum, ...
                     FrEOnPixVec, FrEOffPixVec, FrIPixVec, tau_ref,...
                     FrPreUse, FrPreUseDim) % The last 2: Use preset Frs, and their entry location
    % Mats
    MatEE = (S_EE*(1-p_EEFail))*C_EE_Pixel_Us; % Need Ref here??
    MatEI = S_EI *              C_EI_Pixel_Us;
    MatIE = S_IE *              C_IE_Pixel_Us.*(Ve-repmat(mVIPixVec,1,PixNum));
    MatII = S_II *              C_II_Pixel_Us.*(Vi-repmat(mVIPixVec,1,PixNum));
    ConnMat = [MatEE.*(Ve-repmat(mVEOnPixVec,1,PixNum))/2 , MatEE.*(Ve-repmat(mVEOnPixVec,1,PixNum))/2 , MatEI.*(Vi-repmat(mVEOnPixVec,1,PixNum));
               MatEE.*(Ve-repmat(mVEOffPixVec,1,PixNum))/2, MatEE.*(Ve-repmat(mVEOffPixVec,1,PixNum))/2, MatEI.*(Vi-repmat(mVEOffPixVec,1,PixNum));
               MatIE/2                                    , MatIE/2                                    , MatII];
    % Leak On/Off
    LeakEOn  = gL_E * (0-mVEOnPixVec)  * 1e3;
    LeakEOff = gL_E * (0-mVEOffPixVec) * 1e3;
    LeakI =    gL_I * (0-mVIPixVec)    * 1e3;
    LeakV = [LeakEOn;LeakEOff;LeakI];
    
    % Ext
    ExtEOn  = (lambda_EOn_Pixel*S_Elgn  + rE_amb*S_amb + L6E_Pixel*S_EL6).*(Ve-mVEOnPixVec ) * 1e3;
    ExtEOff = (lambda_EOff_Pixel*S_Elgn + rE_amb*S_amb + L6E_Pixel*S_EL6).*(Ve-mVEOffPixVec) * 1e3;
    ExtI =    (lambda_I_Pixel*S_Ilgn    + rI_amb*S_amb + L6I_Pixel*S_IL6).*(Ve-mVIPixVec)    * 1e3;
    ExtV = [ExtEOn;ExtEOff;ExtI];
    % Ref Vec
    RefEOn = 1-FrEOnPixVec*tau_ref/1e3;
    RefEOff = 1-FrEOffPixVec*tau_ref/1e3;
    RefI = 1-FrIPixVec*tau_ref/1e3;
    RefM = sparse(diag([RefEOn;RefEOff;RefI]));
    
    % MF Equations:
    if isempty(FrPreUse)
    Fr_MFinv = (sparse(eye(3*PixNum))-RefM*ConnMat) \ (RefM * ( ExtV + LeakV));
    else
        FrPreVec = zeros(PixNum*3,1); FrPreVec(FrPreUseDim) = FrPreUse;
        DimAll = 1:PixNum*3; FrminusDim = DimAll(~ismember(DimAll,FrPreUse));
        FrPreReplace = RefM*ConnMat * FrPreVec; 
        % Now compute in the subspace
        FrPreMinus = FrPreReplace(FrminusDim);
        RefMMinus  = RefM(FrminusDim, FrminusDim);
        ConnMatMinus = ConnMat(FrminusDim, FrminusDim);
        ExtVMinus = ExtV(FrminusDim);
        LeakVMinus = LeakV(FrminusDim);
        Fr_MFinvMinus = (sparse(eye(length(FrminusDim)))-RefMMinus*ConnMatMinus) \ ...
                        (RefMMinus * ( ExtVMinus + LeakVMinus) + FrPreMinus);
        % make up MF output            
        Fr_MFinv = zeros(PixNum*3,1);   
        Fr_MFinv(FrminusDim) = Fr_MFinvMinus; Fr_MFinv(FrPreUseDim) = FrPreUse; 
    end


end

%% For each pixel, use 1E and 1I neurons to represent them
function [mVEOnLIF,mVEOffLIF,mVILIF] = ...
                           LIFPixels(Fr_MFinv, ...
                                     C_EE_Pixel_Us,C_EI_Pixel_Us,C_IE_Pixel_Us,C_II_Pixel_Us,...
                                     S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                     lgnEPix_Events,S_Elgn,AmbEPix_Events,S_amb,...
                                     lgnIPix_Events,S_Ilgn,AmbIPix_Events,...
                                     S_EL6,S_IL6,L6EPix_Events,L6IPix_Events,...
                                     tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                                     rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                                     gL_E,gL_I,Ve,Vi,LIFSimuT, dt, PixNum,...
                                     LGNCurInp, L6CurInp,...
                                     lambda_E_Pixel,lambda_I_Pixel,L6E_Pixel,L6I_Pixel,...
                                     lambda_EOn_Pixel, lambda_EOff_Pixel, LGNFreq)
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
T = LIFSimuT*2; % in ms. Default: 20*1e3 ms
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
%     if tInd > DroptInd
%         if OnOffPhase(FrameInd) == 1
%             VNanOnCount = VNanOnCount + isnan(ov);
%             osv = ov; osv(isnan(osv)) = 0;
%             sumVOn = sumVOn + osv;
%         elseif OnOffPhase(FrameInd) == 0
%       % sumV = sum([sumV,ov],2,'omitnan');
%             VNanOffCount = VNanOffCount + isnan(ov);
%             osv = ov; osv(isnan(osv)) = 0;
%             sumVOff = sumVOff + osv;
%         end
%     end
    % Transfer variables
    vt = ov; 
end
mVOnLIF = sumVOn./((length(tt)-1 - DroptInd)/2 - VNanOnCount);
mVOffLIF = sumVOff./((length(tt)-1 - DroptInd)/2 - VNanOnCount);
mVEOnLIF = mVOnLIF(1:PixNum); mVEOffLIF = mVOffLIF(1:PixNum);
mVILIF = (mVOnLIF(PixNum+1:2*PixNum) + mVOffLIF(PixNum+1:2*PixNum))/2;
% fr = length(find(spike>(1-SampleProp)*T))/(T*SampleProp/1000);
end