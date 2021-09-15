%% Plot rate functions from LDE data
% Input: L4EPlot Grid for E Y*X
%        L4IPlot Grid for I Y*X
%        FrLDE   LDe computed firing rates (XY)*5: SOn COn SOff COff I
%        a1,a2   lengths of X Y range
%        CtgrName Name of OD Category
%        ODCtgr   OD Category: 1-3 
%        CellCtgr: S C I
% Output: LDEFrcell Fr function on grid L4EPlot,L4IPlot

function [LDEFrcell] = LDEPlotRateFunc(L4EPlot,L4IPlot,FrLDE,a1,a2,CtgrName,ODCtgr,CellCtgr,varargin)
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

if nargin > 8
    smth = varargin{1};
else
    smth = true;
end

if smth
    LDEFrcell= smoothdata(...
                smoothdata(reshape((FrLDE(:,CId1)+FrLDE(:,CId2))/2,a2,a1)),2);
else
    LDEFrcell = reshape((FrLDE(:,CId1)+FrLDE(:,CId2))/2,a2,a1);
end
s = mesh(L4EPlot,L4IPlot,LDEFrcell,'FaceAlpha','0.4');
s.FaceColor = 'flat';
s.EdgeColor = 'none';
hold on
contour(L4EPlot,L4IPlot,LDEFrcell,'r',"ShowText",'on')
view([0 90])
xlabel('L4E'); ylabel('L4I');title([CellCtgr ' ' CtgrName{ODCtgr}])
colorbar;

end