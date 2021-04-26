function h = CorrCoefFig(FrETemp, FrITemp, mVETemp, mVITemp)

h = figure('Name','Correlation');

subplot 231; 
scatter(FrETemp, mVETemp, 'r.'); 
Corr1 = corrcoef(FrETemp, mVETemp);
title(sprintf('Corr = %.2f', Corr1(2,1)))
xlabel('FrE');ylabel('mVE')
subplot 232; 
scatter(FrETemp, mVITemp, 'r.'); 
Corr1 = corrcoef(FrETemp, mVITemp);
title(sprintf('Corr = %.2f', Corr1(2,1)))
xlabel('FrE');ylabel('mVI')
subplot 233; 
scatter(FrETemp, FrITemp, 'r.'); 
Corr1 = corrcoef(FrETemp, FrITemp);
title(sprintf('Corr = %.2f', Corr1(2,1)))
xlabel('FrE');ylabel('FrI')
subplot 234; 
scatter(FrITemp, mVETemp, 'b.'); 
Corr1 = corrcoef(FrITemp, mVETemp);
title(sprintf('Corr = %.2f', Corr1(2,1)))
xlabel('FrI');ylabel('mVE')
subplot 235; 
scatter(FrITemp, mVITemp, 'b.'); 
Corr1 = corrcoef(FrITemp, mVITemp);
title(sprintf('Corr = %.2f', Corr1(2,1)))
xlabel('FrI');ylabel('mVI')
subplot 236; 
scatter(mVITemp, mVETemp, 'g.'); 
Corr1 = corrcoef(mVITemp, mVETemp);
title(sprintf('Corr = %.2f', Corr1(2,1)))
xlabel('mVI');ylabel('mVE')
end