%% function C_SS_mean = AveSpatKer(C_SS_Pixel_Us,N_HC,NPixX,NPixY)
% Input: C_SS_Pixel_Us: A Pixel connectivity matrix (from network).
% Pre(col)*Post(row)
%        N_HC,NPixX,NPixY: # of hypercolumns, # of pixels per HC
% Output: C_SS_mean: Averaged spatial kernal of firing ratas. Same size as
% C_SS_Pixel_Us

% Zhuo-Cheng Xiao 09/16/2021

function C_SS_mean = AveSpatKer(C_SS_Pixel_Us,N_HC,NPixX,NPixY)
%% Check if C_SS is an eligible matrix
if size(C_SS_Pixel_Us,1) ~= size(C_SS_Pixel_Us,2)
    error('Input Matrix not square!')
end
if size(C_SS_Pixel_Us,2) ~= N_HC*NPixX*N_HC*NPixY
    error('# of pixels doesnt match!')
end

if N_HC<3
    disp('Warning!: Reverse averaged kernal may have duplicate pixel infos')  
end

%% For each pixel: Extract a density map around it. Radius at most one HC,
% so 2HC-by-2HC
PrySynDist_all = zeros(2*NPixY,2*NPixX,size(C_SS_Pixel_Us,1));
for PixInd = 1:size(C_SS_Pixel_Us,1)
    % first get the spatial coord of the pixel
    PX = ceil(PixInd/(N_HC*NPixY)); 
    PY = mod(PixInd,N_HC*NPixY);
    if PY == 0
        PY = N_HC*NPixY;
    end
    
    % Make an extended map
    ConnVec = C_SS_Pixel_Us(PixInd,:)';
    ConnMap = reshape(ConnVec,N_HC*NPixY,N_HC*NPixX);
    Cen = floor((N_HC-1)/2);
    HC_Center = ConnMap(Cen*NPixY+1:(Cen+1)*NPixY,Cen*NPixX+1:(Cen+1)*NPixX);
    Bar_Center_hor = ConnMap(Cen*NPixY+1:(Cen+1)*NPixY,:);
    Bar_Center_ver = ConnMap(:,Cen*NPixX+1:(Cen+1)*NPixX);
    
    ConnMap_Ext = zeros((N_HC+2)*NPixY,(N_HC+2)*NPixX); %extend each side by 1 HC
    ConnMap_Ext(NPixY+1:(N_HC+1)*NPixY,...
                NPixX+1:(N_HC+1)*NPixX) = ConnMap;
    ConnMap_Ext(1:NPixY,...
                1:NPixX) = HC_Center; % 4 corners
    ConnMap_Ext((N_HC+1)*NPixY+1:(N_HC+2)*NPixY,...
                1:NPixX) = HC_Center;
    ConnMap_Ext(1:NPixY,...
                (N_HC+1)*NPixX+1:(N_HC+2)*NPixX) = HC_Center; 
    ConnMap_Ext((N_HC+1)*NPixY+1:(N_HC+2)*NPixY,...
                (N_HC+1)*NPixX+1:(N_HC+2)*NPixX) = HC_Center;
    ConnMap_Ext(1:NPixY,...
                NPixX+1:(N_HC+1)*NPixX) = Bar_Center_hor; % 4 sides
    ConnMap_Ext((N_HC+1)*NPixY+1:(N_HC+2)*NPixY,...
                NPixX+1:(N_HC+1)*NPixX) = Bar_Center_hor; 
    ConnMap_Ext(NPixY+1:(N_HC+1)*NPixY,...
                1:NPixX) = Bar_Center_ver; 
    ConnMap_Ext(NPixY+1:(N_HC+1)*NPixY,...
                (N_HC+1)*NPixX+1:(N_HC+2)*NPixX) = Bar_Center_ver; 
    
    % Extract a 2HC-by-2HC Presynaptic distribution
    PX_New = PX+NPixX; PY_New = PY+NPixY;
    PrySynDist_all(:,:,PixInd) = ConnMap_Ext(PY_New-NPixY:PY_New+NPixY-1,...
                                             PX_New-NPixX:PX_New+NPixX-1);
end
Ker_SS_mean = mean(PrySynDist_all,3);

%% Put Kernel back to Matrix
C_SS_mean  = zeros(N_HC*NPixX*N_HC*NPixY);
for PixInd = 1:size(C_SS_Pixel_Us,1)
    PX = ceil(PixInd/(N_HC*NPixY)); 
    PY = mod(PixInd,N_HC*NPixY);
    if PY == 0
        PY = N_HC*NPixY;
    end
    PX_New = PX+NPixX; PY_New = PY+NPixY;
    % Create an extended map and center the smoothed kernel around a pixel
    ConnMap_Rev = zeros((N_HC+2)*NPixY,(N_HC+2)*NPixX);
    ConnMap_Rev(PY_New-NPixY:PY_New+NPixY-1,...
                PX_New-NPixX:PX_New+NPixX-1) = Ker_SS_mean;
    
    %Add cancidates up, since the 2HC-by-2HC mat can't extend to three consecutive HCs...
    CenExt = floor((N_HC+2-1)/2);
    %HC_Cen_Ext = ConnMap_Rev(CenExt*NPixY+1:(CenExt+1)*NPixY, CenExt*NPixX+1:(CenExt+1)*NPixX);
    % Fisrt Pile back four sides (get rid of corners)
       ConnMap_Rev(  CenExt*NPixY+1:(CenExt+1)*NPixY, NPixX+1:(N_HC+1)*NPixX) ...% Center Row...
     = ConnMap_Rev(  CenExt*NPixY+1:(CenExt+1)*NPixY, NPixX+1:(N_HC+1)*NPixX) ...
     + ConnMap_Rev(               1:           NPixY, NPixX+1:(N_HC+1)*NPixX) ...   
     + ConnMap_Rev((N_HC+1)*NPixY+1:  (N_HC+2)*NPixY, NPixX+1:(N_HC+1)*NPixX);
       ConnMap_Rev(NPixY+1:(N_HC+1)*NPixY,   CenExt*NPixX+1:(CenExt+1)*NPixX) ...% center column,
     = ConnMap_Rev(NPixY+1:(N_HC+1)*NPixY,   CenExt*NPixX+1:(CenExt+1)*NPixX) ...
     + ConnMap_Rev(NPixY+1:(N_HC+1)*NPixY,                1:           NPixX) ...   
     + ConnMap_Rev(NPixY+1:(N_HC+1)*NPixY, (N_HC+1)*NPixX+1:  (N_HC+2)*NPixX);
       ConnMap_Rev(CenExt*NPixY  +1:(CenExt+1)*NPixY, CenExt*NPixX  +1:(CenExt+1)*NPixX) ... % center, 4 corners, 4 midHC come together
     = ConnMap_Rev(CenExt*NPixY  +1:(CenExt+1)*NPixY, CenExt*NPixX  +1:(CenExt+1)*NPixX) ... 
     + ConnMap_Rev(               1:           NPixY,                1:           NPixX) ...
     + ConnMap_Rev((N_HC+1)*NPixY+1:  (N_HC+2)*NPixY,                1:           NPixX) ...
     + ConnMap_Rev(               1:           NPixY, (N_HC+1)*NPixX+1:  (N_HC+2)*NPixX) ...
     + ConnMap_Rev((N_HC+1)*NPixY+1:  (N_HC+2)*NPixY, (N_HC+1)*NPixX+1:  (N_HC+2)*NPixX);
    
    % Put back to Build a mat with the averaged kernal
    ConnMapPix = ConnMap_Rev(NPixY+1:(N_HC+1)*NPixY, NPixX+1:(N_HC+1)*NPixX);
    C_SS_mean(PixInd,:) = reshape(ConnMapPix,N_HC*NPixX*N_HC*NPixY,1)';
end
end