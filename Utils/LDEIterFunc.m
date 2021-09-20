%% Iterations of LDE: Use precomputed function to determine output of a cell type
% Input: L4EmeshX, L4ImeshY  Domain of precomputed functions
%        LDEFrfuncS          Function of cell type Q, including ort, obl, opt
%        L4EUse,L4IUse       All input L4E L4I
%        LDEUse              Just for output formality
%        ORTPix,OBLPix,OPTPix,ORTOBLBd_Pix,OPTOBLBd_Pix   Pixel index of
%        different ODs

% Zhuo-Cheng Xiao 09/18/2021

function [LDEOutS] = LDEIterFunc(L4EmeshX, L4ImeshY,...
                                 LDEFrfuncSORT,LDEFrfuncSOBL,LDEFrfuncSOPT,...
                                 L4EUse,L4IUse,LDEUse,...
                                 ORTPix,OBLPix,OPTPix,ORTOBLBd_Pix,OPTOBLBd_Pix)
    LDEOutS = LDEUse;
    LDEOutS(ORTPix) = interp2(L4EmeshX, L4ImeshY,LDEFrfuncSORT,...
                               L4EUse(ORTPix),L4IUse(ORTPix));
    LDEOutS(OBLPix) = interp2(L4EmeshX, L4ImeshY,LDEFrfuncSOBL,...
                               L4EUse(OBLPix),L4IUse(OBLPix));
    LDEOutS(OPTPix) = interp2(L4EmeshX, L4ImeshY,LDEFrfuncSOPT,...
                               L4EUse(OPTPix),L4IUse(OPTPix));
    LDEOutS(ORTOBLBd_Pix) = interp2(L4EmeshX, L4ImeshY,(LDEFrfuncSORT+LDEFrfuncSOBL)/2,...
                               L4EUse(ORTOBLBd_Pix),L4IUse(ORTOBLBd_Pix));
    LDEOutS(OPTOBLBd_Pix) = interp2(L4EmeshX, L4ImeshY,(LDEFrfuncSOPT+LDEFrfuncSOBL)/2,...
                               L4EUse(OPTOBLBd_Pix),L4IUse(OPTOBLBd_Pix));



end