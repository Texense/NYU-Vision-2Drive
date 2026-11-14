[V,x]=linearpad(V,x);
[V,x]=linearpad(fliplr(V),flip(x)); V=fliplr(V);
V=V.';
[V,y]=linearpad(V,y); 
[V,y]=linearpad(fliplr(V),flip(y)); V=fliplr(V);
V=V.';
Vq=interp2(x,y,V,xq,yq,'linear');
function [D,z]=linearpad(D0,z0)
  factor=1e6;
  
  dz=z0(end)-z0(end-1);
  dD=D(:,end)-D(:,end-1);
  
  z=z0;
  z(end+1)=z(end)+factor*dz;
  
  D=D0;
  D(:,end+1)=D(:,end) + factor*dD;
end