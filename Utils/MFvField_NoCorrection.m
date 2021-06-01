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
FrEPixVec = 16 *ones(AA,1);
FrIPixVec = 64 *ones(AA,1);
mVEPixVec = 0.7 *ones(AA,1);
mVIPixVec = 0.8 *ones(AA,1);
%% Do the following iterations recursively
% Design Mats
MatEE = (S_EE*(1-p_EEFail))*C_EE_Pixel_Us.*(Ve-repmat(mVEPixVec,1,NPixX*N_HC*NPixY*N_HC)); % Need Ref here??
MatEI = S_EI *              C_EI_Pixel_Us.*(Vi-repmat(mVEPixVec,1,NPixX*N_HC*NPixY*N_HC));
MatIE = S_IE *              C_IE_Pixel_Us.*(Ve-repmat(mVIPixVec,1,NPixX*N_HC*NPixY*N_HC));
MatII = S_II *              C_II_Pixel_Us.*(Vi-repmat(mVIPixVec,1,NPixX*N_HC*NPixY*N_HC));
ConnMat = [MatEE,MatEI;MatIE,MatII];
% Leak
LeakE = gL_E * (0-mVEPixVec) * 1e3;
LeakI = gL_I * (0-mVIPixVec) * 1e3;
LeakV = [LeakE;LeakI];
% Ext
ExtE = (lambda_E_Pixel*S_Elgn + rE_amb*S_amb + L6E_Pixel*S_EL6).*(Ve-mVEPixVec) * 1e3;
ExtI = (lambda_I_Pixel*S_Ilgn + rI_amb*S_amb + L6I_Pixel*S_IL6).*(Ve-mVIPixVec) * 1e3;
ExtV = [ExtE;ExtI];
% Ref Vec
RefE = 1-FrEPixVec*tau_ref/1e3;
RefI = 1-FrIPixVec*tau_ref/1e3;
RefM = sparse(diag([RefE;RefI]));

% L4 MF Equations:
Fr_MFinv = (sparse(eye(2*NPixX*N_HC*NPixY*N_HC))-RefM*ConnMat) \ (RefM * ( ExtV + LeakV));
% The first order has already been good! Now do LIF...
[mVE,~] =  LIFPixels('e', Fr_MFinv, ...
                                         C_EE_Pixel_Us,C_EI_Pixel_Us,C_IE_Pixel_Us,C_II_Pixel_Us,...
                                         S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                         lambda_E_drive,S_Elgn,rE_amb,S_amb,...
                                         lambda_I_drive,S_Ilgn,rI_amb,...
                                         S_EL6,S_IL6,rE_L6_Drive,rI_L6_Drive,...
                                         tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                                         rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                                         gL_E,gL_I,Ve,Vi,LIFSimuT);
[mVI,~] =  LIFPixels('i', Fr_MFinv, ...
                                         C_EE_Pixel_Us,C_EI_Pixel_Us,C_IE_Pixel_Us,C_II_Pixel_Us,...
                                         S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                         lambda_E_drive,S_Elgn,rE_amb,S_amb,...
                                         lambda_I_drive,S_Ilgn,rI_amb,...
                                         S_EL6,S_IL6,rE_L6_Drive,rI_L6_Drive,...
                                         tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                                         rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                                         gL_E,gL_I,Ve,Vi,LIFSimuT);
end

function [meanV,fr] = LIFPixels(NeuronType, f_EnI, ...
                                         N_EE,N_EI,N_IE,N_II,...
                                         S_EE,S_EI,S_IE,S_II,p_EEFail,...
                                         lambda_E,S_Elgn,rE_amb,S_amb,...
                                         lambda_I,S_Ilgn,rI_amb,...
                                         S_EL6,S_IL6,rE_L6,rI_L6,...
                                         tau_ampa_R,tau_ampa_D,tau_nmda_R,tau_nmda_D,tau_gaba_R,tau_gaba_D,tau_ref,...
                                         rhoE_ampa,rhoE_nmda,rhoI_ampa,rhoI_nmda,...
                                         gL_E,gL_I,Ve,Vi,LIFSimuT)
%% attribute parameters for different types of neurons
if strcmpi(NeuronType,'e')
    N_E = N_EE; N_I = N_EI;
    S_E = S_EE; S_I = S_EI;
    p_Fail = p_EEFail;
    lambda = lambda_E; S_lgn = S_Elgn; r_amb = rE_amb;
    S_L6 = S_EL6; r_L6 = rE_L6;
    gL = gL_E;
    rho_ampa = rhoE_ampa; rho_nmda = rhoE_nmda;
elseif strcmpi(NeuronType,'i')
    N_E = N_IE; N_I = N_II;
    S_E = S_IE; S_I = S_II;
    p_Fail = 0;
    lambda = lambda_I; S_lgn = S_Ilgn; r_amb = rI_amb;
    S_L6 = S_IL6; r_L6 = rI_L6;
    gL = gL_I;
    rho_ampa = rhoI_ampa; rho_nmda = rhoI_nmda;
else 
    disp('***Unrecognized Neuron Type')    
end
rE = f_EnI(1)/1000; rI = f_EnI(2)/1000; % f_EnI in s^-1, but here we use ms^-1
%% Evolve single neurons
T = LIFSimuT; % in ms. Default: 20*1e3 ms
dt = 0.1; t = 0:dt:T;
SampleProp = 9/10; % last half time for meanV

v = zeros(size(t)); 
G_gaba_D = zeros(size(t)); G_gaba_R = zeros(size(t));
G_ampa_D = zeros(size(t)); G_ampa_R = zeros(size(t));
G_nmda_D = zeros(size(t)); G_nmda_R = zeros(size(t));
spike = [];

%rng(100)
% input determination: Assume all Poisson
%rng(100)
p_lgn = dt*lambda;                    Sp_lgn = double(rand(size(t))<=p_lgn);
%rng(101)
p_amb = dt*r_amb;                     Sp_amb = double(rand(size(t))<=p_amb);
%rng(102)
p_EV1 = dt*rE*full(N_E)*(1-p_Fail);   Sp_EV1 = double(rand(size(t))<=p_EV1);
%rng(103)
p_IV1 = dt*rI*full(N_I);              Sp_IV1 = double(rand(size(t))<=p_IV1);
p_L6  = dt*r_L6;                      Sp_L6  = double(rand(size(t))<=p_L6);

RefTimer = 0; 
for tInd = 1:length(t)-1
    % Firstly, refrectory neurons get out due to exponetial distributed time
     if isnan(v(tInd))
        RefTimer = RefTimer+dt; %RefTimer goes up
        if RefTimer>=tau_ref    %if timer reach tau_ref, kick v out of refrectory
            v(tInd+1) = 0;
            RefTimer = 0;
        else
            v(tInd+1) = nan;
        end
     else
         G_I = 1/(tau_gaba_D-tau_gaba_R) * (G_gaba_D(tInd) - G_gaba_R(tInd)); % S_EI is included in amplitude of GE_gaba
         G_E = 1/(tau_ampa_D-tau_ampa_R) * (G_ampa_D(tInd) - G_ampa_R(tInd)) ...
             + 1/(tau_nmda_D-tau_nmda_R) * (G_nmda_D(tInd) - G_nmda_R(tInd)); % 
         vv  = v(tInd) + dt*(-gL*v(tInd) - G_E.*(v(tInd)-Ve) - G_I.*(v(tInd)-Vi)); 
         if vv >= 1
             v(tInd+1) = nan;
             spike = [spike,t(tInd)];
         else
             v(tInd+1) = vv;
         end
     end

     % conductances
     G_gaba_R(tInd+1) = (G_gaba_R(tInd) +                                           S_I*Sp_IV1(tInd)                                     ) * exp(-dt/tau_gaba_R); 
     G_gaba_D(tInd+1) = (G_gaba_D(tInd) +                                           S_I*Sp_IV1(tInd)                                     ) * exp(-dt/tau_gaba_D); 
     G_ampa_R(tInd+1) = (G_ampa_R(tInd) + S_lgn*Sp_lgn(tInd) + S_amb*Sp_amb(tInd) + S_E*Sp_EV1(tInd)*rho_ampa + S_L6*Sp_L6(tInd)*rho_ampa) * exp(-dt/tau_ampa_R);
     G_ampa_D(tInd+1) = (G_ampa_D(tInd) + S_lgn*Sp_lgn(tInd) + S_amb*Sp_amb(tInd) + S_E*Sp_EV1(tInd)*rho_ampa + S_L6*Sp_L6(tInd)*rho_ampa) * exp(-dt/tau_ampa_D);
     G_nmda_R(tInd+1) = (G_nmda_R(tInd) +                                           S_E*Sp_EV1(tInd)*rho_nmda + S_L6*Sp_L6(tInd)*rho_nmda) * exp(-dt/tau_nmda_R);
     G_nmda_D(tInd+1) = (G_nmda_D(tInd) +                                           S_E*Sp_EV1(tInd)*rho_nmda + S_L6*Sp_L6(tInd)*rho_nmda) * exp(-dt/tau_nmda_D);
end
meanV = mean(v(floor(end*(1-SampleProp)):end), 'omitnan');
fr = length(find(spike>(1-SampleProp)*T))/(T*SampleProp/1000);
end