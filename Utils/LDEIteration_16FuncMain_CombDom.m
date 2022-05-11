%% LDE iteration w/o figures
% L4EmeshX,L4ImeshY,LDEFrfunc: compsed by several different response
% functions, and we choose the best from them for every step
%% Starting from the finest function!
% Output: Iteration firing maps, and L1 diff norm
function [LDEEpoOut,LDEIL2Diff,L2DiffNormNeib,L2Diameter,LDEequv,FuncUse] = ...
    LDEIteration_16FuncMain_CombDom(...
    PixInptCtgrUse,LDEIni,p,Epoc,...
    C_SS_mean,C_CS_mean,C_IS_mean,...
    C_SC_mean,C_CC_mean,C_IC_mean,...
    C_SI_mean,C_CI_mean,C_II_mean,...
    L4EmeshXAll,L4ImeshYAll,LDEFrfuncAll,varargin)
% specify NHCout
if ~isempty(varargin)
    N_HCOut = varargin{1};
    NPixX = varargin{2};
    NPixY = varargin{3};
else
    N_HCOut = 4; NPixX = 10; NPixY = 10;
end

LDEItr = cell(Epoc+1,1);LDEItr{1} = LDEIni;
LDEEpoOut = cell(Epoc+1,1); LDEEpoOut{1} = LDEIni;
LDEoutVec = zeros(size(LDEIni.I,1)*3,Epoc+1);
LDEoutVec(:,1) = [LDEIni.S;LDEIni.C;LDEIni.I];

% record the function quoted every step
FuncUseAll = zeros(Epoc,1);

InhKillFlag = true; Thrsld = 70; Highist = [100,97]; % pars for inhibition suppresion
for Epc = 1:Epoc
    % First do convolution
    LDEUse = LDEItr{Epc};
    if InhKillFlag % apply inhibition suppresion
        LDEUse.I = InhKill(LDEUse.I, Thrsld, Highist);
    end
    L4EUse = C_SS_mean*LDEUse.S + ...%- diag(C_SS_mean).*LDEUse.S + ...
        C_CS_mean*LDEUse.S + ...%- diag(C_CS_mean).*LDEUse.S + ...
        C_IS_mean*LDEUse.S + ...%- diag(C_IS_mean).*LDEUse.S + ...
        C_SC_mean*LDEUse.C + ...%- diag(C_SC_mean).*LDEUse.C + ...
        C_CC_mean*LDEUse.C + ...%- diag(C_CC_mean).*LDEUse.C + ...
        C_IC_mean*LDEUse.C  ;%- diag(C_IC_mean).*LDEUse.C ;
    L4IUse = C_SI_mean*LDEUse.I + ...%- diag(C_SI_mean).*LDEUse.I + ...
        C_CI_mean*LDEUse.I + ...%- diag(C_CI_mean).*LDEUse.I + ...
        C_II_mean*LDEUse.I  ;%- diag(C_II_mean).*LDEUse.I ;
    
    % No Need to resymmetrize!!...
%     L4EUse = symmHCs(L4EUse,N_HCOut,NPixX,NPixY);
%     L4IUse = symmHCs(L4IUse,N_HCOut,NPixX,NPixY);
    
    % Choose the best option of domain: Large by defalt; if better move to
    % smalle and smaller
    FuncN = length(L4EmeshXAll); % should be consistent for all three vars
        
    % Refer to functions
    LDEOut = struct('S',[],'C',[],'I',[]);    
    % adjust for different functions
    nanFlag = true;
    FuncUse = 1; % using the finest by defalt, then go coarser if not good enough
    while nanFlag && FuncUse<=FuncN
        L4EmeshX = L4EmeshXAll{FuncUse};
        L4ImeshY = L4ImeshYAll{FuncUse};
        LDEFrfunc = LDEFrfuncAll{FuncUse};
        LDEOut.S = LDEIterFunc_Grating_16Func(...
            L4EmeshX, L4ImeshY,...
            LDEFrfunc.S,...
            L4EUse,L4IUse,...
            PixInptCtgrUse);
        %ORTPix,OBLPix,OPTPix,ORTOBLBd_Pix,OPTOBLBd_Pix);
        LDEOut.C = LDEIterFunc_Grating_16Func(...
            L4EmeshX, L4ImeshY,...
            LDEFrfunc.C,...
            L4EUse,L4IUse,...
            PixInptCtgrUse);
        % ORTPix,OBLPix,OPTPix,ORTOBLBd_Pix,OPTOBLBd_Pix);
        LDEOut.I = LDEIterFunc_Grating_16Func(...
            L4EmeshX, L4ImeshY,...
            LDEFrfunc.I,...
            L4EUse,L4IUse,...
            PixInptCtgrUse);
        %ORTPix,OBLPix,OPTPix,ORTOBLBd_Pix,OPTOBLBd_Pix);
        
        % Now check if output contains nan
        nanFlag = isnan(sum(LDEOut.S+LDEOut.C+LDEOut.I,'all'));
        FuncUse = FuncUse+1;
    end
    
    if FuncUse>FuncN && nanFlag % return if used up all functions but still getting nans
        fprintf('***Warning! NAN results in the %d epoch. Returning...\n',Epc)
        return
    end
    
    % record the function used.
    FuncUseAll(Epc) = FuncUse;
    
    LDENext = struct(...
        'S',LDEOut.S*p + LDEUse.S*(1-p),...
        'C',LDEOut.C*p + LDEUse.C*(1-p),...
        'I',LDEOut.I*p + LDEUse.I*(1-p));
    LDEItr{Epc+1} = LDENext; LDEEpoOut{Epc+1} = LDEOut;
    LDEoutVec(:,Epc+1) = [LDEOut.S; LDEOut.C; LDEOut.I];
end

%L2DiffNorm = zeros(Epoc,1);
L2DiffNormNeib = zeros(Epoc,1);
L2Diameter = zeros(Epoc,1);
% get an "equilibrium" of I, and assume >150 is fine
LDEequv = mean(LDEoutVec(:,floor((Epc+1)*2/3):end),2);
LDEIL2Diff = sqrt(sum((LDEoutVec - repmat(LDEequv,1,Epoc+1)).^2, 1));
for Epc = 1:Epoc
%     L2DiffNorm(Epc) = ...
%         norm([LDEEpoOut{Epc}.S;LDEEpoOut{Epc}.C;LDEEpoOut{Epc}.I] - ...
%         [LDEEpoOut{end}.S;LDEEpoOut{end}.C;LDEEpoOut{end}.I], 2);
    
    L2DiffNormNeib(Epc) = ...
        norm([LDEEpoOut{Epc}.S;LDEEpoOut{Epc}.C;LDEEpoOut{Epc}.I] - ...
        [LDEEpoOut{Epc+1}.S;LDEEpoOut{Epc+1}.C;LDEEpoOut{Epc+1}.I], 2);
    L2Diameter(Epc) = max(LDEIL2Diff(Epc:end));
end
end