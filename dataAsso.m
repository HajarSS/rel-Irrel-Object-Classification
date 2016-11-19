% In the name of GOD...
% ---------------------
% Working on KR conference
% Start: 2013-09-10



% Data Association
function idx= dataAsso(target, measurments, frame)
% Input:
% target: (1*4 matrix) one blob we want to find if there is any blob
% associated to it
% measurments: (n*4 matrix in which n is the number of measurement
% rectangles) one or more blobs which can be associated to target
% both inputs are some rectangles (x y w h)
% frame: the current frame

% Output (Idx):
% 1..size(measurments): the index of a blob in measurments
% 0: when there is no associations between target with any of measurments

% The used cues for associations: Intersection and shape (HOG)

idx= 0; % no association
mse_thr= 0.05; % threshold for MSE
measur= [];

% applying Intersection cue (80 percent)
for i=1:size(measurments,1)
    area= rectint(target,measurments(i,:));
    if((target(3)*target(4))>(measurments(i,3)*measurments(i,4)))
        smlRec= measurments(i,3)*measurments(i,4); % smaller area
    else
        smlRec= target(3)*target(4);
    end
    
    if area>(0.8*smlRec) 
        % the measurments with at least %80 intersections
        measur= cat(1,measur,measurments(i,:)); 
    end
end

% applying shape (HOG) cue
mse_min= 1000000; % a big number
for i=1:size(measur,1)
    clear rect1
    clear rect2
    rect1(:,:,1)= frame(target(2):target(2)+target(4),...
        target(1):target(1)+target(3),1);
    rect1(:,:,2)= frame(target(2):target(2)+target(4),...
        target(1):target(1)+target(3),2);
    rect1(:,:,3)= frame(target(2):target(2)+target(4),...
        target(1):target(1)+target(3),3);
    hog1= HOG(rect1);
    
    rect2(:,:,1)= frame(measur(i,2):measur(i,2)+measur(i,4),...
        measur(i,1):measur(i,1)+measur(i,3),1);
    rect2(:,:,2)= frame(measur(i,2):measur(i,2)+measur(i,4),...
        measur(i,1):measur(i,1)+measur(i,3),2);
    rect2(:,:,3)= frame(measur(i,2):measur(i,2)+measur(i,4),...
        measur(i,1):measur(i,1)+measur(i,3),3);
    hog2= HOG(rect2);
    
    [~,mse,~,~]= measerr(hog1,hog2); % the mean square error (MSE)
    
    if(mse<mse_min)
        idx= i;
        mse_min= mse;
    end
    
end

if(mse_min>mse_thr)
    idx= 0; % it's not acceptable  -no association found
end
