% For a pixel vector, show how the map is

function [] = ShowField(Vec, Range, XPix, YPix, varargin)
if size(Vec,2) == 1
    Map = reshape(Vec(Range),YPix,XPix);
    imagesc(Map)
    colormap jet
    set(gca,'YDir','normal')
    colorbar
elseif size(Vec,2) == 3
    Map = zeros(YPix,XPix,3);
    for LgnInd = 1:3
        Map(:,:,LgnInd) = reshape(Vec(Range,LgnInd),YPix,XPix);
    end
    image(Map)
    set(gca,'YDir','normal')
end
%% Plot HC boundaries
hold on
XHc = floor(XPix/10); YHc = floor(YPix/10);
for VerInd = 1:XHc -1
    plot(ones(length(0:YPix))*(VerInd*10+0.1),0:YPix,'g-','LineWidth',1)
end
for HorInd = 1:YHc -1
    plot(0:XPix,ones(length(0:XPix))*(HorInd*10+0.1),'g-','LineWidth',1)
end

if nargin > 4
    title(varargin{1})
end
if nargin > 5
    caxis(varargin{2})
end
axis square
end