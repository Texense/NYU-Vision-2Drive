% For a pixel vector, show how the map is

function [] = ShowField(Vec, Range, XPix, YPix, varargin)
Map = reshape(Vec(Range),YPix,XPix);
imagesc(Map)
colormap jet
set(gca,'YDir','normal')
colorbar
if nargin > 4
    title(varargin{1})
end
axis square
end