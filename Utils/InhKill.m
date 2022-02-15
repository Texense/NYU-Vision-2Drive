%% Inhibition suppresion
% input:
%        LDEUseI  I firing rates
%        Thrsld    Threshold we start suppresion, i.e., below Thrsld should
%        be identity map
%        Highist   [largestinput, largestoutput]

% Using second order
function ...
    LDEUseIKill = InhKill(LDEUseI, Thrsld, Highist)

%% First make up a substitute function
x0 = Thrsld; x1 = Highist(1); y1 = Highist(2);

a = (y1-x1)/(x1-x0)^2;
b = 1 - 2*a*x0;
c = x0 - a*x0^2 - b*x0;

f = @(x) a*x.^2 + b*x + c;
hardbound = 120; % back again to linear
d = f(hardbound);
f1 = @(x) x-(hardbound-d);

% Manupulate I frs
LDEUseIKill = LDEUseI;
KillInd = LDEUseIKill>Thrsld & LDEUseIKill<hardbound;
LDEUseIKill(KillInd) = f(LDEUseIKill(KillInd));

LinearInd = LDEUseIKill>hardbound;

LDEUseIKill(LinearInd) = f1(LDEUseIKill(LinearInd));

end