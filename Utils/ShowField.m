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
if nargin > 4
    title(varargin{1})
end
axis square
end