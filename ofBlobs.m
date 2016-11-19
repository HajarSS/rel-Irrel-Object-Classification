% In the Name of GOD
% ------------------

% 10 sep 2013
% This function extracts all the rectangles around each blob detected by OpticalFlow algorithm.

function blobs= ofBlobs(act,vidNum,frNum)

% Input:
% act: name of the action like 'car','dig',...
% vidNum: the video number 
% frNum: the frame number

% Output:
% blobs: it's a matrix of n84 in which:
%        - 4 is for x,y,w,h for each rectangle around each blob
%        - n is the number of blobs

rectFolder= ['Detects/',lower(act),'Detect/'];
flowFolder= ['Blobs/',lower(act),'Blob/'];

% reading the rectangle around the person detected by people detection 
f=fopen(['./',rectFolder,'Rect_',act,num2str(vidNum),'_p.dat'],'r');
if (f==-1)
    f=fopen(['./',rectFolder,'Rect_',act,num2str(vidNum),'_c.dat'],'r');
    if (f==-1)
    f=fopen(['./',rectFolder,'Rect_',act,num2str(vidNum),'_mBike.dat'],'r');
    end
end

c = textscan(f,'%s','Delimiter','\n');
frameList = c{1}; %

blobs= []; % array of cells including blobs of the last frame in each track

rect= frameList{frNum};
if isempty(rect)
    exit(1);
end

rect= round(str2num(rect));
if((frNum*5)~=rect(1))
    error('error in frame number');
end


% load the optical flow for i'th frame
flowName= [lower(act),num2str(vidNum),'_',num2str(frNum*5),'_blob.mat'];
try
    load(['./',flowFolder,flowName]);
catch
    exist= 0;
    for i=(frNum-1):-1:1
        flowName= [lower(act),num2str(vidNum),'_',num2str(i*5),'_blob.mat'];
        try
            load(['./',flowFolder,flowName]);
            exist= 1;
            break;
        catch
            continue;
        end
    end

    if (~exist)
        for i=(frNum+1):100000
            flowName= [lower(act),num2str(vidNum),'_',num2str(i*5),'_blob.mat'];
            try
                load(['./',flowFolder,flowName]);
                exist= 1;
                break;
            catch
                continue;
            end
        end
    end
    if (~exist)
        error('---------- no flow file for the frame: %i\n',frNum);
    end
end
 

nRects= (size(rect,2)-1)/4; % the number of rectangles
for j=1:nRects
    blob(rect(4*(j-1)+3):rect(4*(j-1)+5),rect(4*(j-1)+2):rect(4*(j-1)+4))=0;
end
% now, "blob" contains only the motion pixels out of the rectangles


%{
figure(2), imshow(blob);
title(['action:throw','/video:',num2str(vidNum),'/frame:',num2str(i)]);
%haja= max(max(blob))-blob;
haja= blob;
figure(4), imshow(haja.*3);
 colormap gray;
cmap = colormap;
cmap = flipud(cmap);
colormap(cmap);
title(['action:throw','/video:',num2str(vidNum),'/frame:',num2str(i)]);
%}

temp= bwlabel(blob,8);
dataBlobs= regionprops(temp,'Area','BoundingBox');

nBlobs= max(max(temp));  % numel(dataBlobs);
for j=1:nBlobs   % j'th blob in i'th frame from video 'vidNum'
    [s1, s2]= find(temp==j);
    if(length(s1)<=4)
        blob(s1, s2)=0;
        continue;
    end
    
    blobs= cat(1,blobs,(dataBlobs(j).BoundingBox)); 
end

%}
