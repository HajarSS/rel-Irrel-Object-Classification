% In the name of GOD...
% ---------------------

%--------------------------------------------------------- 13 sep 2013
% ---------- Template Matching
% This function looks for a template image (tImg) in an image (sImg). At
% first we need to determine the search image around the * spot determined
% by SSD. We analyse different rectangles with different scales with
% maximum "scale" and minimum "1/scale".


function [x_best,y_best,w_best,h_best]= objDetect(tImg,Img,x,y,scale)
% Input:
%       tImg: template image
%       Img: the whole current image (frame)
%       x,y: place of * spot in the whole frame
%       scale: how big should be the search area
% Output:
% the detected object in a rectangle

% Determine the search area
% -------------------------
[r,c,~]= size(tImg);
[row,col,~]= size(Img);

% seach area
x_max= x-floor((c/2)*scale); % maximum scale
y_max= y-floor((r/2)*scale);
w_max= floor(c*scale);
h_max= floor(r*scale);
noCw= 0; % no change "w"
if(x_max+w_max>col)
    w_max= col-x_max; 
    noCw= 1;
end
noCh= 0; % no change "h"
if(y_max+h_max>row)
    h_max= row-y_max; 
    noCh= 1;
end

% Sliding window around the 'maximum correspondence:*spot'
% --------------------------------------------------------
x_min= x-floor((c/2)*(1/scale));   % minimum scale

x_t= x_max;
y_t= y_max;
w_t= w_max;
h_t= h_max;

corrMax= 0;
x_best= 0; % detected rectangle
y_best= 0;
w_best= 0;
h_best= 0;

while (x_t<=x_min)
    % extracting HOG features for the rectangles
    tHog= HOG(tImg) ; % for the template image
    cHog= HOG(Img(y_t:(y_t+h_t),x_t:(x_t+w_t))); % the candidate rectangle
    
                
    % correlation between two rectangles
    temp= corr(tHog,cHog);
    if temp>corrMax
        corrMax= temp;
        x_best= x_t; % detected rectangle
        y_best= y_t;
        w_best= w_t;
        h_best= h_t;
    end
    
    % new rectangle
    x_t= x_t + 1;
    y_t= y_t + 1;
    if noCw
        w_t= w_t - 1;  % the rect is connected to the borders
    else
        w_t= w_t - 2;
    end
    if noCh
        h_t= h_t - 1;  % the rect is connected to the borders
    else
        h_t= h_t - 2;
    end   
end
%{
% Show result
figure(2),
imshow(sImg);
hold on;
rectangle('Position',[yCorr-x_best xCorr-y_best 2*x_best 2*y_best],...
    'EdgeColor','b');
title(['x_best:',num2str(x_best),'y_best:',num2str(y_best)]);
%}


