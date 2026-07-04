% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   January 2024
% -------------------------------------------------------------------------
% Description:   To be defined
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [xq,yq] = interpoly3(x,y,xmin,xmax)

if min(x) > xmin
    start = round(min(x));
else
    start = xmin;
end
if max(x) < xmax
    stop = round(max(x));
else
    stop = xmax;
end
p  = polyfit(x,y,3);
xq = start:1:stop;
yq = polyval(p,xq);
if min(xq) > xmin
    diff = min(xq)-xmin;
    xq = [xmin:xmin+diff-1 xq];
    yq = [nan(1,diff) yq];
end
if max(xq) < xmax
    diff = xmax-max(xq);
    xq = [xq xmax-diff+1:xmax];
    yq = [yq nan(1,diff)];
end
% figure; hold on; plot(x,y,'red'); plot(xq,yq,'blue');