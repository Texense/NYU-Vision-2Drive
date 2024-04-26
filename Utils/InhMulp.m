%% for multiplicative depressions of firing rates
% LDEUse: any vector - the operation is entrywise
% IKp: IKp.Thrsld = 60; IKp.Highist = 120;  IKp.Slope = 0.9; before thrsld,
% 
% the factor is 1, after 120 is 0.9, between them comes from linear
% interpolation

function [LDEUseOut,Factor]  = InhMulp(LDEUse, IKp)
Factor = ones(size(LDEUse));
Factor(LDEUse>=IKp.Highist) = IKp.Slope;

InterpId = LDEUse<IKp.Highist & LDEUse>IKp.Thrsld;
if strcmp(IKp.Mode,'linear') == 1
    Factor(InterpId) = 1 + (LDEUse(InterpId) - IKp.Thrsld)/(IKp.Highist - IKp.Thrsld) * (IKp.Slope - 1);
elseif strcmp(IKp.Mode,'sigmoid') == 1
    % using -6 to 6 to interpolate:
    aa = IKp.IntH; bb = IKp.IntL;
    xx = (LDEUse(InterpId) - IKp.Thrsld)/(IKp.Highist - IKp.Thrsld) * (aa - -bb) -bb;
    sigm = sigmod(xx);
    high = sigmod(aa); low = sigmod(-bb);
    % rescale the outcome of sigm
    sigmRescle = (sigm - low)/(high-low);
    Factor(InterpId) = 1 + sigmRescle * (IKp.Slope - 1);
end

LDEUseOut = LDEUse .* Factor; % multiplicative saturation
end

function y = sigmod(x)
y = exp(x)./(1+exp(x));

end