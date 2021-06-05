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
                                                        lambda_E_drive,S_Elgn,rE_amb,S_amb,...      %4 lambda_E drive is vector for each cell
                                                        lambda_I_drive,S_Ilgn,rI_amb,...            %4
                                                        S_EL6,S_IL6,rE_L6_Drive,rI_L6_Drive,...     %4 
                                                        ... % L6 drives are vectors for each cell. Vital since length(rQL6) for NE and NI
                                                        tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,... %7
                                                        rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,... %4
                                                        gL_E,gL_I,Ve,Vi,...                         %4
                                                        N_HC,NnE,NnI,NPixX, NPixY, varargin)        %5+x % if varagin non empty, we only export the last state
                                                        %This line: spatial indexes of E and I neurons. Numbers of pixels
%% Hyperparameters for iterations
if nargin > 37+4  % Specify: The number of loops I want, after stopping criteria met    
    AveLoop = varargin{2};
else 
    AveLoop = 100;
end

if nargin > 38+4 % Specify: Maximum nubmer of loops before stopping
        StopLoop = varargin{3};
else 
        StopLoop = AveLoop;
end

if nargin > 39+4 % Specify: stepsize h
    h_Step = varargin{4};
else
    h_Step = 1;        
end

if nargin > 40+4 % Specify: LIF simulation timef_pre
    LIFSimuT = varargin{5};
else
    LIFSimuT = 20*1e3;    % unit in ms    
end
%% Get matrices for pixels
% First, get connectivity matrix between Pixels
AA = NPixX*N_HC*NPixY*N_HC; % Number of pixels
C_EE_Pixel = zeros(AA);
C_EI_Pixel = zeros(AA);
C_IE_Pixel = zeros(AA);
C_II_Pixel = zeros(AA);
[~,NnEPixel] = NeuVec2Pixel(zeros(length(NnE.X),1),NnE,NPixX*N_HC,NPixY*N_HC);
[~,NnIPixel] = NeuVec2Pixel(zeros(length(NnI.X),1),NnI,NPixX*N_HC,NPixY*N_HC);
tic
parfor PixIndPost = 1:AA
    for PixIndPre = 1:AA
        C_EE_Pixel(PixIndPost,PixIndPre) = mean(sum(C_EE_Fix(NnEPixel.Vec == PixIndPost, NnEPixel.Vec == PixIndPre),2));
        C_EI_Pixel(PixIndPost,PixIndPre) = mean(sum(C_EI_Fix(NnEPixel.Vec == PixIndPost, NnIPixel.Vec == PixIndPre),2));
        C_IE_Pixel(PixIndPost,PixIndPre) = mean(sum(C_IE_Fix(NnIPixel.Vec == PixIndPost, NnEPixel.Vec == PixIndPre),2));
        C_II_Pixel(PixIndPost,PixIndPre) = mean(sum(C_II_Fix(NnIPixel.Vec == PixIndPost, NnIPixel.Vec == PixIndPre),2));
    end    
end
toc
C_EE_Pixel_Us = full(C_EE_Pixel);
C_IE_Pixel_Us = full(C_IE_Pixel);
C_EI_Pixel_Us = full(C_EI_Pixel);
C_II_Pixel_Us = full(C_II_Pixel);
% Then get input vec for each pixel
lambda_E_Pixel = zeros(AA,1);
L6E_Pixel = zeros(AA,1);
L6I_Pixel = zeros(AA,1);
for PixInd = 1:AA
    lambda_E_Pixel(PixInd) = mean(lambda_E_drive(NnEPixel.Vec == PixInd));
    L6E_Pixel(PixInd) = mean(rE_L6_Drive(NnEPixel.Vec == PixInd));
    L6I_Pixel(PixInd) = mean(rI_L6_Drive(NnIPixel.Vec == PixInd));
end
lambda_I_Pixel = lambda_I_drive;
% Then initialize FrPix and mVPix vectors
% Start from uniform guessed values
FrEIni = 16; FrIIni = 64;
FrEPixIni = FrEIni *ones(AA,1);
FrIPixIni = FrIIni *ones(AA,1);
mVEPixIni = 0.7 *ones(AA,1);
mVIPixIni = 0.8 *ones(AA,1);
L4EInputIni = [C_EE_Pixel_Us*FrEPixIni*(1-p_EEFail);C_IE_Pixel_Us*FrEPixIni]/1e3;   
L4IInputIni = [C_EI_Pixel_Us*FrIPixIni           ;  C_II_Pixel_Us*FrIPixIni]/1e3;   
%% PreSet Input events to Pixel-LIF neurons
LGNCurInp = 0; L6CurInp = 0;
dt = 0.1; TimeFrac = 0.05;
tic
lgnEPix_Events = PoissonInputForNetwork(AA,lambda_E_Pixel*(1-LGNCurInp),LIFSimuT*TimeFrac,dt);
lgnIPix_Events = PoissonInputForNetwork(AA,lambda_I_Pixel*(1-LGNCurInp),LIFSimuT*TimeFrac,dt);
AmbEPix_Events = PoissonInputForNetwork(AA,rE_amb,LIFSimuT*TimeFrac,dt);
AmbIPix_Events = PoissonInputForNetwork(AA,rI_amb,LIFSimuT*TimeFrac,dt);
L6EPix_Events  = PoissonInputForNetwork(AA,L6E_Pixel*(1-L6CurInp),LIFSimuT*TimeFrac,dt);
L6IPix_Events  = PoissonInputForNetwork(AA,L6I_Pixel*(1-L6CurInp),LIFSimuT*TimeFrac,dt);
% Idea for L4: changing every loop, but we can always rescale from the
% original event counts in each bin
L4Pix_EventsEIni  = PoissonInputForNetwork(2*AA,L4EInputIni,LIFSimuT*TimeFrac,dt); % E to everyone
L4Pix_EventsIIni  = PoissonInputForNetwork(2*AA,L4IInputIni,LIFSimuT*TimeFrac,dt); % I to everyone
toc
%% Do the following iterations recursively
for Epoch = 1:10
    tic
    % Design Mats
    MatEE = (S_EE*(1-p_EEFail))*C_EE_Pixel_Us.*(Ve-repmat(mVEPixIni,1,NPixX*N_HC*NPixY*N_HC)); % Need Ref here??
    MatEI = S_EI *              C_EI_Pixel_Us.*(Vi-repmat(mVEPixIni,1,NPixX*N_HC*NPixY*N_HC));
    MatIE = S_IE *              C_IE_Pixel_Us.*(Ve-repmat(mVIPixIni,1,NPixX*N_HC*NPixY*N_HC));
    MatII = S_II *              C_II_Pixel_Us.*(Vi-repmat(mVIPixIni,1,NPixX*N_HC*NPixY*N_HC));
    ConnMat = [MatEE,MatEI;
        MatIE,MatII];
    % Leak
    LeakE = gL_E * (0-mVEPixIni) * 1e3;
    LeakI = gL_I * (0-mVIPixIni) * 1e3;
    LeakV = [LeakE;LeakI];
    % Ext
    ExtE = (lambda_E_Pixel*S_Elgn + rE_amb*S_amb + L6E_Pixel*S_EL6).*(Ve-mVEPixIni) * 1e3;
    ExtI = (lambda_I_Pixel*S_Ilgn + rI_amb*S_amb + L6I_Pixel*S_IL6).*(Ve-mVIPixIni) * 1e3;
    ExtV = [ExtE;ExtI];
    % Ref Vec
    RefE = 1-FrEPixIni*tau_ref/1e3;
    RefI = 1-FrIPixIni*tau_ref/1e3;
    RefM = diag([RefE;RefI]);
    
    % L4 MF Equations:
    Fr_MFinv = (eye(2*NPixX*N_HC*NPixY*N_HC)-RefM*ConnMat) \ (RefM * ( ExtV + LeakV));
    % The first order has already been good! Now do LIF...
    
    if Epoch < 10
       [mVEPixNew,mVIPixNew] =  LIFPixels(Fr_MFinv, L4Pix_EventsEIni, L4Pix_EventsIIni, L4EInputIni, L4IInputIni,...
                                   C_EE_Pixel_Us,C_EI_Pixel_Us,C_IE_Pixel_Us,C_II_Pixel_Us,...
                                   S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                   lgnEPix_Events,S_Elgn,AmbEPix_Events,S_amb,...
                                   lgnIPix_Events,S_Ilgn,AmbIPix_Events,...
                                   S_EL6,S_IL6,L6EPix_Events,L6IPix_Events,...
                                   tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                                   rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                                   gL_E,gL_I,Ve,Vi,LIFSimuT, dt, AA,...
                                   LGNCurInp, L6CurInp,...
                                   lambda_E_Pixel,lambda_I_Pixel,L6E_Pixel,L6I_Pixel);
       mVEPixIni = mVEPixIni*(1-h_Step) + mVEPixNew * h_Step;
       mVIPixIni = mVIPixIni*(1-h_Step) + mVIPixNew * h_Step;
   
    end
   toc
   figure(1)
   subplot 221
   ShowField(Fr_MFinv, 1:900, 30, 30 )
   caxis([0 40])
   subplot 222
   ShowField(mVEPixIni, 1:900, 30, 30 )
   caxis([0.64 0.77])
   subplot 223
   ShowField(Fr_MFinv, 901:1800, 30, 30 )
   caxis([20 120])
   subplot 224
   ShowField(mVIPixIni, 1:900, 30, 30 )
   caxis([0.74 0.83])
   drawnow
end
end

%% For each pixel, use 1E and 1I neurons to represent them
function [mVELIF,mVILIF] = LIFPixels(Fr_MFinv, L4Pix_EventsEIni, L4Pix_EventsIIni, L4EInputIni, L4IInputIni,...
                                     C_EE_Pixel_Us,C_EI_Pixel_Us,C_IE_Pixel_Us,C_II_Pixel_Us,...
                                     S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                     lgnEPix_Events,S_Elgn,AmbEPix_Events,S_amb,...
                                     lgnIPix_Events,S_Ilgn,AmbIPix_Events,...
                                     S_EL6,S_IL6,L6EPix_Events,L6IPix_Events,...
                                     tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                                     rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                                     gL_E,gL_I,Ve,Vi,LIFSimuT, dt, PixNum,...
                                     LGNCurInp, L6CurInp,...
                                     lambda_E_Pixel,lambda_I_Pixel,L6E_Pixel,L6I_Pixel)
                               % Last two lines in case we have used current input...
%% First check if L4 rates match neuron numbers
if length(Fr_MFinv) == 2*PixNum
rE = Fr_MFinv(1:PixNum); rI = Fr_MFinv(PixNum+1:2*PixNum); % f_EnI in s^-1, but here we use ms^-1
rE(rE<=0) = 0; rI(rI<0) = 0;
else
    error('L4 FRs dont match!')
end
%% Setup input and record
T = LIFSimuT; % in ms. Default: 20*1e3 ms
tt = 0:dt:T;
SampleProp = 9/10; % last half time for meanV
DroptInd = floor(length(tt)*(1-SampleProp));
% L4 input determination: Assume all Poisson
L4EInputNow = [C_EE_Pixel_Us*rE*(1-p_EEFail); 
               C_IE_Pixel_Us*rE             ]/1000;   
L4IInputNow = [C_EI_Pixel_Us*rI             ; 
               C_II_Pixel_Us*rI             ]/1000;   
L4Pix_EventsEU = L4Pix_EventsEIni.*repmat(L4EInputNow./L4EInputIni,1,size(L4Pix_EventsEIni,2));
L4Pix_EventsIU = L4Pix_EventsIIni.*repmat(L4IInputNow./L4IInputIni,1,size(L4Pix_EventsIIni,2));
% Incorporate L4 and other input
EampaInp = single(full(S_Elgn * (lgnEPix_Events + lambda_E_Pixel*dt*LGNCurInp) ...
                     + S_amb  *  AmbEPix_Events ...
                     + S_EL6  * (L6EPix_Events  + L6E_Pixel*dt*L6CurInp) * rhoE_ampa)); %  * rhoE_ampa
IampaInp = single(full(S_Ilgn * (lgnIPix_Events+ lambda_I_Pixel*dt*LGNCurInp) ...
                     + S_amb  *  AmbIPix_Events ...
                     + S_IL6  * (L6IPix_Events  + L6I_Pixel*dt*L6CurInp) * rhoI_ampa)); %  * rhoI_ampa

EnmdaInp = single(full(S_EL6  * (L6EPix_Events  + L6E_Pixel*dt*L6CurInp) * rhoE_nmda)); %
InmdaInp = single(full(S_IL6  * (L6IPix_Events  + L6I_Pixel*dt*L6CurInp) * rhoI_nmda));
L4InputfEampa = single(full( [S_EE * L4Pix_EventsEU(1:PixNum,:) * rhoE_ampa;
                              S_IE * L4Pix_EventsEU(PixNum+1:2*PixNum,:) * rhoI_ampa] ));
L4InputfEnmda = single(full( [S_EE * L4Pix_EventsEU(1:PixNum,:) * rhoE_nmda;
                              S_IE * L4Pix_EventsEU(PixNum+1:2*PixNum,:) * rhoI_nmda] ));
L4InputfI     = single(full( [S_EI * L4Pix_EventsIU(1:PixNum,:);
                              S_II * L4Pix_EventsIU(PixNum+1:2*PixNum,:)] ));

% Leakage
gL = [gL_E*ones(size(rE)); gL_I*ones(size(rI))];
% Initialize records
sumV = zeros(size(Fr_MFinv));
VNanCount = zeros(size(Fr_MFinv));
vt = zeros(size(Fr_MFinv));
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
%% Evolve single neurons
RefTimer = zeros(size(Fr_MFinv)); 
% G_ampa_R = zeros(size(Fr_MFinv)); 
% G_nmda_R = zeros(size(Fr_MFinv)); 
% G_gaba_R = zeros(size(Fr_MFinv)); 
% G_ampa_D = zeros(size(Fr_MFinv)); 
% G_nmda_D = zeros(size(Fr_MFinv)); 
% G_gaba_D = zeros(size(Fr_MFinv));                                          
%% Can precompute all Gs...
for tInd = 1:length(tt)-1
    % First, Get input matrices from series
    InpWin = 10; FrameNum = floor(InpWin/dt);
    FrameInd = mod(tInd, FrameNum);
    if FrameInd == 0
    FrameInd = FrameNum;
    end
    
    % When sample from Gs, GAMPA and GNMDA should use same time frame;
    if FrameInd == 1 % if the first frame, recompute input mats
        RandTimBin = randi([1 n-FrameNum],2,1);
        GEU = GE(:,RandTimBin(1):RandTimBin(1)+FrameNum);  
        GIU = GI(:,RandTimBin(2):RandTimBin(2)+FrameNum); 
    end
    
    % Firstly, refrectory neurons get out if timer reachs t_ref
    RefTimer(isnan(vt)) = RefTimer(isnan(vt)) + dt;
    vt(RefTimer>=tau_ref) = 0;
    RefTimer(RefTimer>=tau_ref) = 0;
    
%     G_I = 1/(tau_gaba_D-tau_gaba_R) * (G_gaba_D - G_gaba_R); % S_EI is included in amplitude of GE_gaba
%     G_E = 1/(tau_ampa_D-tau_ampa_R) * (G_ampa_D - G_ampa_R) ...
%         + 1/(tau_nmda_D-tau_nmda_R) * (G_nmda_D - G_nmda_R); %
    ov  = vt + dt*(-gL.*vt - GEU(:,FrameInd).*(vt-Ve) - GIU(:,FrameInd).*(vt-Vi));
    ov(ov>=1) = nan;

    % conductances
%     G_gaba_R = (G_gaba_R +                                               L4InputfI(:,FrameInd)) * exp(-dt/tau_gaba_R);
%     G_gaba_D = (G_gaba_D +                                               L4InputfI(:,FrameInd)) * exp(-dt/tau_gaba_D);
%     G_ampa_R = (G_ampa_R + [EampaInp(:,FrameInd);IampaInp(:,FrameInd)] + L4InputfEampa(:,FrameInd)) * exp(-dt/tau_ampa_R);
%     G_ampa_D = (G_ampa_D + [EampaInp(:,FrameInd);IampaInp(:,FrameInd)] + L4InputfEampa(:,FrameInd)) * exp(-dt/tau_ampa_D);
%     G_nmda_R = (G_nmda_R + [EnmdaInp(:,FrameInd);InmdaInp(:,FrameInd)] + L4InputfEnmda(:,FrameInd)) * exp(-dt/tau_nmda_R);
%     G_nmda_D = (G_nmda_D + [EnmdaInp(:,FrameInd);InmdaInp(:,FrameInd)] + L4InputfEnmda(:,FrameInd)) * exp(-dt/tau_nmda_D);
%     
    % Compute meanV
    if tInd > DroptInd
      % sumV = sum([sumV,ov],2,'omitnan');
       VNanCount = VNanCount + isnan(ov);
       osv = ov; osv(isnan(osv)) = 0;
       sumV = sumV + osv;
    end
    % Transfer variables
    vt = ov; 
end
mVLIF = sumV./(length(tt)-1 - DroptInd - VNanCount);
mVELIF = mVLIF(1:PixNum);
mVILIF = mVLIF(PixNum+1:2*PixNum);
% fr = length(find(spike>(1-SampleProp)*T))/(T*SampleProp/1000);
end