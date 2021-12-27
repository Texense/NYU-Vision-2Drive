%% Plot rate functions from LDE data
% Input: L4EPlot Grid for E Y*X
%        L4IPlot Grid for I Y*X
%        FrLDE   LDe computed firing rates (XY)*5: SOn COn SOff COff I
%        a1,a2   lengths of X Y range
%        CtgrName Name of OD Category
%        ODCtgr   OD Category: 1-3 
%        CellCtgr: S C I
%        varargin: smooth/not contour/not MFv/LIF [rowsmoothwin colsmoothwin]
% Output: LDEFrcell Fr function on grid L4EPlot,L4IPlot

function [LDEFrVec] = LDEPlotRateFunc(L4EPlot,L4IPlot,FrLDE,a1,a2,CtgrName,ODCtgr,CellCtgr,varargin)
if nargin > 8 % smooth or not
    smth = varargin{1};
else
    smth = true;
end

if nargin >9 % plot contour or not
    Contour = varargin{2};
else
    Contour = true;
end

if nargin >10 % MFv (true) or LIf (false)
    MFv = varargin{3};
else
    MFv = true;
end

if nargin > 11
    rowWinSize = varargin{4}(1);
    colWinSize = varargin{4}(2);
else
    rowWinSize = 5;
    colWinSize = 5;
end

if MFv
    switch CellCtgr
        case 'S'
            CId1 = 1; CId2 = 3;
        case 'C'
            CId1 = 2; CId2 = 4;
        case 'I'
            CId1 = 5; CId2 = 5;
        otherwise
            disp('No such cell category. Return')
            return
    end
else
    switch CellCtgr
        case 'S'
            CId1 = 1; CId2 = 1;
        case 'C'
            CId1 = 2; CId2 = 2;
        case 'I'
            CId1 = 3; CId2 = 3;
        otherwise
            disp('No such cell category. Return')
            return
    end
end

if smth
    LDEFrcell= smoothdata(...
                smoothdata(reshape((FrLDE(:,CId1)+FrLDE(:,CId2))/2,a2,a1),...
                2,'movmean',rowWinSize),...
                  'movmean',colWinSize);
%  LDEFrcell= smoothdata(...
%                 smoothdata(reshape((FrLDE(:,CId1)+FrLDE(:,CId2))/2,a2,a1),2));
 else
    LDEFrcell =            reshape((FrLDE(:,CId1)+FrLDE(:,CId2))/2,a2,a1);
end

s = mesh(L4EPlot,L4IPlot,LDEFrcell,'FaceAlpha','0.4');
s.FaceColor = 'flat';
s.EdgeColor = 'none';
hold on
if Contour
   contour(L4EPlot,L4IPlot,LDEFrcell,'r',"ShowText",'on')
end
view([0 90])
xlabel('L4E'); ylabel('L4I');title([CellCtgr ' ' CtgrName{ODCtgr}])
colorbar;
axis tight

LDEFrVec = reshape(LDEFrcell,a1*a2,1);
end