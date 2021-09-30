%% This function generates arbitrary large field with lgn indexes, given a 3*3HC input
% Input:  lambda_SOn_drive: LGNon input for all S cells. There should be
%                           three unique values
%         NnSPixel: location of every S cell. Should be composed by field X
%                   and Y
%         N_HC,N_HCout: Number of HC for the whole map. n*n
%         NPixX,NPixY: Number of pixel per side
% Output: PixLGNCtgr: (N_HCout^2*NPixX*NPixY)-by-lgn matrix. lgn stand for
%                     different lgn types. Entries are percentage of each 
%                     type, sum of rows=1
%         LGNon: 1*lgn vecter, entries are lgn values of each type. from
%                 small to large


function [PixLGNCtgr,LGNon] = LGNIndSpat(lambda_SOn_drive,NnSPixel,N_HC,N_HCout,NPixX,NPixY)
PixNum = NPixX*N_HC * NPixY*N_HC;
% get LGN type of each cell
[LGNon,~,LGNtype]= unique(lambda_SOn_drive);
Ind_SOn_Pixel = zeros(PixNum,length(LGNon));

for PixInd = 1:PixNum % for each pixel:
    % First get all neruons in this pixel
    CurrentNeu = LGNtype(NnSPixel.Vec == PixInd);
    % get their lgn type and distribute in matrix
    [a,~,c] = find(sum(ind2vec(CurrentNeu'),2)/length(CurrentNeu));
    Ind_SOn_Pixel(PixInd,a)  = c;
end
% Reshape the lgn index vectors to maps
Ind_SOn_Map = zeros(NPixY*N_HC,NPixX*N_HC,length(LGNon));
for lgnTy = 1:length(LGNon)
    Ind_SOn_Map(:,:,lgnTy) = reshape(Ind_SOn_Pixel(:,lgnTy),NPixY*N_HC,NPixX*N_HC);
end

% Now extract a basic periodic 2*2HC map, then expand to a new N_HCout^2
% map
Ind_SOn_Map2by2 = Ind_SOn_Map(1:2*NPixY , 1:2*NPixX, :);
PixIndX = mod(1:N_HCout*NPixX,2*NPixX); PixIndX(PixIndX==0) = 2*NPixX;
PixIndY = mod(1:N_HCout*NPixY,2*NPixY); PixIndY(PixIndY==0) = 2*NPixY;
Ind_SOn_MapOut = Ind_SOn_Map2by2(PixIndY,PixIndX,:);

PixLGNCtgr = zeros(NPixY*N_HCout*NPixX*N_HCout,length(LGNon));
for lgnTy = 1:length(LGNon)
    PixLGNCtgr(:,lgnTy) = reshape(Ind_SOn_MapOut(:,:,lgnTy),NPixY*N_HCout*NPixX*N_HCout,1);
end
end