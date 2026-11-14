FrEPixVec = reshape(FrEPixMat,PixNum,1);
FrEOnPixVec  = reshape(FrEOnPixMat,PixNum,1);
FrEOffPixVec = reshape(FrEOffPixMat,PixNum,1);
FrIPixVec = reshape(FrIPixMat,PixNum,1);

mVEPixVec = reshape(mVEPixMat,PixNum,1);
mVEOnPixVec  = reshape(mVEOnPixMat,PixNum,1);
mVEOffPixVec = reshape(mVEOffPixMat,PixNum,1);
mVIPixVec = reshape(mVIPixMat,PixNum,1);

FrEOnPixVecUse  = FrEOnPixVec;
FrEOffPixVecUse = FrEOffPixVec;
FrIPixVecUse = FrIPixVec;
for ii = 1:10
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

ExtEOn  = (lambda_EOn_Pixel*S_Elgn  + rE_amb*S_amb + L6E_Pixel*S_EL6).*(Ve-mVEOnPixVec ) * 1e3;
ExtEOff = (lambda_EOff_Pixel*S_Elgn + rE_amb*S_amb + L6E_Pixel*S_EL6).*(Ve-mVEOffPixVec) * 1e3;
ExtI =    (lambda_I_Pixel*S_Ilgn    + rI_amb*S_amb + L6I_Pixel*S_IL6).*(Ve-mVIPixVec)    * 1e3;
ExtV = [ExtEOn;ExtEOff;ExtI];
% Ref Vec
RefEOn = 1-FrEOnPixVecUse*tau_ref/1e3;
RefEOff = 1-FrEOffPixVecUse*tau_ref/1e3;
RefI = 1-FrIPixVecUse*tau_ref/1e3;
RefM = sparse(diag([RefEOn;RefEOff;RefI]));
% L4 Frs
Fr_L4 = [FrEOnPixVec; FrEOffPixVec; FrIPixVec];

% MF Equations:
%Fr_MF = RefM * (ConnMat*Fr_L4 + ExtV + LeakV);
tic
Fr_MFinv = (sparse(eye(3*PixNum))-RefM*ConnMat) \ (RefM * ( ExtV + LeakV));
toc
% Err
FrErr = Fr_MFinv - Fr_L4;


SC = Fr_MFinv;
h = figure(1);
ax1 = subplot(221);
hold on
scatter(FrIPixVec, SC(1801:2700))
scatter(FrEOnPixVec, SC(1:900))
scatter(FrEOffPixVec, SC(901:1800))
plot(1:120, 1:120)

ax2 = subplot(222);
hold on
scatter(FrIPixVec, SC(1801:2700))
scatter(FrEPixVec, (SC(1:900)+SC(901:1800))/2 )
plot(1:120, 1:120)
drawnow
pause(2)

subplot 223
ShowField(FrErr, 1:900, 30, 30)
subplot 224
ShowField(FrErr, 901:1800, 30, 30)
if ii < 10
cla(ax1); cla(ax2)
end

FrEOnPixVecUse  = SC(1:900);
FrEOffPixVecUse = SC(901:1800);
FrIPixVecUse = SC(1801:2700);

FrE_OffNeg = FrEOffPixVecUse; FrE_OffNeg(FrE_OffNeg>=0) = 0;
FrEOnPixVecUse = FrEOnPixVecUse + FrE_OffNeg;
FrEOffPixVecUse(FrEOffPixVecUse<=0) = 0;
end