%% for multiplicative depressions of firing rates
% LDEUse: any vector - the operation is entrywise
% IKp: IKp.Thrsld = 60; IKp.Highist = 120;  IKp.Slope = 0.9; before thrsld,
% 
% the factor is 1, after 120 is 0.9, between them comes from linear
% interpolation

function [LDEUseOut,Factor]  = InhMulp(LDEUse, IKp1)
Factor = ones(size(LDEUse));
Factor(LDEUse>=IKp1.Highist) = IKp1.Slope;

if strcmp(IKp1.Mode,'linear') == 1
    InterpId = LDEUse<IKp1.Highist & LDEUse>IKp1.Thrsld;
    Factor(InterpId) = 1 + (LDEUse(InterpId) - IKp1.Thrsld)/(IKp1.Highist - IKp1.Thrsld) * (IKp1.Slope - 1);
elseif strcmp(IKp1.Mode,'sigmoid') == 1
    % using -6 to 6 to interpolate:
    InterpId = LDEUse<IKp1.Highist & LDEUse>IKp1.Thrsld;
    aa = IKp1.IntH; bb = IKp1.IntL;
    xx = (LDEUse(InterpId) - IKp1.Thrsld)/(IKp1.Highist - IKp1.Thrsld) * (aa - -bb) -bb;
    sigm = sigmod(xx);
    high = sigmod(aa); low = sigmod(-bb);
    % rescale the outcome of sigm
    sigmRescle = (sigm - low)/(high-low);
    Factor(InterpId) = 1 + sigmRescle * (IKp1.Slope - 1);
elseif strcmp(IKp1.Mode,'mutisigmoid') == 1 % multiple lags of sigmoid
    InterpId2 = LDEUse<IKp1.Highist & LDEUse>=IKp1.Thrsld2;
    InterpId1 = LDEUse<=IKp1.Thrsld2 & LDEUse>=IKp1.Thrsld1;
    aL = IKp1.IntaL; bL = IKp1.IntbL;
    aH = IKp1.IntaH; bH = IKp1.IntbH;
    % for lag 1
    xxbb = (LDEUse(InterpId1) - IKp1.Thrsld1)/(IKp1.Thrsld2 - IKp1.Thrsld1) * (bH+bL) -bL;
    sigmbb = sigmod(xxbb);
    highbb = sigmod(bH); lowbb = sigmod(-bL);
    % rescale the outcome of sigm
    sigmResclebb = (sigmbb - lowbb)/(highbb-lowbb);
    sigmResclebb = sigmResclebb/max(sigmResclebb,[],'all') * 0.5;% rescale to make sure that the end goes down one half
    Factor(InterpId1) = 1 + sigmResclebb * (IKp1.Slope - 1);
    % for lag 2
    xxaa = (LDEUse(InterpId2) - IKp1.Thrsld2)/(IKp1.Highist - IKp1.Thrsld2) * (aH+aL) -aL;
    sigmaa = sigmod(xxaa);
    highaa = sigmod(aH); lowaa = sigmod(-aL);
    % rescale the outcome of sigm
    sigmRescleaa = (sigmaa - lowaa)/(highaa-lowaa);
    sigmRescleaa = (sigmRescleaa - min(sigmRescleaa,[],'all')) / ...
        max(sigmRescleaa - min(sigmRescleaa,[],'all'),[],'al') *0.5 + 0.5;
    Factor(InterpId2) = 1 + sigmRescleaa * (IKp1.Slope - 1);

end

LDEUseOut = LDEUse .* Factor; % multiplicative saturation
end

function y = sigmod(x)
y = exp(x)./(1+exp(x));

end