% In the name of GOD...
% ---------------------
% Working on KR conference
% Start: 2013-09-10


%{
%--------------------------------------------------------- 29 oct 2013
%------------- Extracting fatures(18-values) for test data
% features(18-values):
% 1.change-core9(9-values)  2.change-CoreInterval(6-values)  3.distance
% 4.speed-obj1(based on its centroid)   5.speed-obj2

global row col %frame row and column

scale= 0.5;  %resize each frame

% list of actions to be processed (11 actions at the moment)
actionList= ['carry  ';'dig    ';'fall   ';'jump   ';'kick   ';'pickup ';
    'putdown';'run    ';'throw  ';'turn   ';'walk   ';];

% ~~~~~~~~~~~~~~~~~~~ feature extraction
for action= 2:size(actionList,1)
    fprintf('action: %s\n',actionList(action,1:7));
    
    rectFolder= ['./Detects/',actionList(action,1:3),'Detect/'];
    
    listRects= dir(['./',rectFolder,'/Rect*.dat']);
    numRects= numel(listRects);
    
    fvid = fopen(['./videos/list',upper(actionList(action,1:3)),'.txt']);
    c = textscan(fvid,'%s','Delimiter','\n');
    videoList = c{1};
    
    for i=1:numRects % ith video
        tic;
        
        % Loading annotations for interacting people
        % ------------------------------------------
        curVideo= listRects(i).name;  % current video
        videoNum= sscanf(curVideo,'%*4c_%*3c%i_*.dat');
        f=fopen(['./',rectFolder,curVideo],'r');
        c = textscan(f,'%s','Delimiter','\n');
        personRectList = c{1};
        fclose(f);
        
        % Change personRectList from string to int
        temp= [];
        for j=1:size(personRectList,1)
            temp= cat(1,temp,round(str2num(cell2mat(personRectList(j,:)))));
        end
        personRectList= temp;
        
        
        % Loading annotations for involved objects
        % ----------------------------------------
        % refine tracks (for zero rows)
        [tr, fr_se]= refineTracks(lower(actionList(action,1:3)),videoNum);
        
        trNum= size(tr, 2); % number of tracks in video i
        
        
        tline= videoList{videoNum};
        object= VideoReader(['./videos/',tline]);
        
        im= imresize(read(object,1),scale);
        [row,col,~]= size(im);
        
        
        features= {}; % an array of 'trNum' cells
        for j=1:trNum % j'th track in video i
            fprintf('- action: %s, video(%i): %i/%i, track: %i/%i ...\n',...
                lower(actionList(action,1:3)), videoNum,i,numRects,j,trNum);
            
            objRectList= tr{j};
            
            feat= {};
            lastC= zeros(1,9);
            lastCI= zeros(1,6);
            for pNum=1:floor(size(personRectList,2)/4) % number of people in video i
                f= [];
                for k=1:size(objRectList,1) % length of this track
                    curFr= fr_se(1,j)+k-1;  % current frame number
                    
                    % check If there are both obj and person
                    personRow= find(personRectList(:,1)==curFr*5);
                    if isempty(personRow)
                        % means there is obj but no person
                        continue;
                    end
                    
                    objRect= objRectList(k,:); % objRect= [x y w h]
                    pRect= personRectList(personRow,2:end);
                    pRect(pNum*4-1)= pRect(pNum*4-1)-pRect(pNum*4-3);
                    pRect(pNum*4)= pRect(pNum*4)-pRect(pNum*4-2);
                    % pRect= [x y w h]
                    
                    if (k==1)
                        cent1= [(pRect(pNum*4-3)+(pRect(pNum*4-1)/2)),...
                            (pRect(pNum*4-2)+(pRect(pNum*4)/2))];
                        cent2= [(objRect(1)+(objRect(3)/2)),(objRect(2)+(objRect(4)/2))];
                    end
                    
                    % extract features
                    objNum= 2; % one obj, one person
                    
                    [aiFeat,C,CI,c1,c2]= ...
                        core9_extractor3(objNum,pRect((pNum*4-3):(pNum*4)),...
                        objRect,lastC,lastCI,cent1,cent2);
                    lastC= C;
                    lastCI= CI;
                    cent1= c1;
                    cent2= c2;
                    if k>1 % not at the first frame
                        f= cat(1, f, aiFeat); % 1*18 vector of core9 features
                    end
                end
                feat= cat(2, feat, f);
            end
            features= cat(2, features, {feat});
        end
        ti= toc;
        fprintf('--- Time: %1.2f min\n',ti/60);
        fprintf('--------------------\n');
        
        save(['features_',lower(actionList(action,1:3)),...
                num2str(videoNum),'.mat'],'features');
    end      % i'th video
end
%}





%--------------------------------------------------------- 14 Nov 2013
%------------- Extracting fatures(20-values) for test data
%------------- We save information about the rectangles also
% features(20-values):
% 1.change-core9(9-values)  2.change-CoreInterval(6-values)  3.distance
% 4.speed-obj1(based on its centroid)   5.speed-obj2  6.size of obj1,2

global row col %frame row and column

scale= 0.5;  %resize each frame

% list of actions to be processed (11 actions at the moment)
actionList= ['carry  ';'dig    ';'fall   ';'jump   ';'kick   ';'pickup ';
    'putdown';'run    ';'throw  ';'turn   ';'walk   ';];

% ~~~~~~~~~~~~~~~~~~~ feature extraction
for action= 1:size(actionList,1)
    tic;
    fprintf('action: %s\n',actionList(action,1:7));
    
    rectFolder= ['./Detects/',actionList(action,1:3),'Detect/'];
    
    listRects= dir(['./',rectFolder,'/Rect*.dat']);
    numRects= numel(listRects);
    
    fvid = fopen(['./videos/list',upper(actionList(action,1:3)),'.txt']);
    c = textscan(fvid,'%s','Delimiter','\n');
    videoList = c{1};
    
    for i= 1:numRects % ith video
        
        % Loading annotations for interacting people
        % ------------------------------------------
        curVideo= listRects(i).name;  % current video
        videoNum= sscanf(curVideo,'%*4c_%*3c%i_*.dat');
        f=fopen(['./',rectFolder,curVideo],'r');
        c = textscan(f,'%s','Delimiter','\n');
        personRectList = c{1};
        fclose(f);
        
        % Change personRectList from string to int
        temp= [];
        for j=1:size(personRectList,1)
            temp= cat(1,temp,round(str2num(cell2mat(personRectList(j,:)))));
        end
        personRectList= temp;
        
        
        % Loading annotations for involved objects
        % ----------------------------------------
        % refine tracks (for zero rows)
        [tr, fr_se]= refineTracks(lower(actionList(action,1:3)),videoNum);
        featured_fr_se= zeros(size(fr_se)); % start-end frame which features extracted
        
        trNum= size(tr, 2); % number of tracks in video i
        
        
        tline= videoList{videoNum};
        object= VideoReader(['./videos/',tline]);
        
        im= imresize(read(object,1),scale);
        [row,col,~]= size(im);
        
        
        features= {}; % an array of 'trNum' cells
        rectFeat= {}; % an array of cells for the corresponding rectangles
        for j=1:trNum % j'th track in video i
            fprintf('- action: %s, video(%i): %i/%i, track: %i/%i ...\n',...
                lower(actionList(action,1:3)), videoNum,i,numRects,j,trNum);
            
            objRectList= tr{j};
            
            feat= {};
            recF= {};
            lastC= zeros(1,9);
            lastCI= zeros(1,6);
            for pNum=1:floor(size(personRectList,2)/4) % number of people in video i
                f= [];
                r= [];
                for k=1:size(objRectList,1) % length of this track
                    curFr= fr_se(1,j)+k-1;  % current frame number
                    
                    % check If there are both obj and person
                    personRow= find(personRectList(:,1)==curFr*5);
                    if isempty(personRow)
                        % means there is obj but no person
                        continue;
                    end

                    objRect= objRectList(k,:); % objRect= [x y w h]
                    pRect= personRectList(personRow,2:end);
                    pRect(pNum*4-1)= pRect(pNum*4-1)-pRect(pNum*4-3);
                    pRect(pNum*4)= pRect(pNum*4)-pRect(pNum*4-2);
                    % pRect= [x y w h]
                    
                    if (k==1)
                        cent1= [(pRect(pNum*4-3)+(pRect(pNum*4-1)/2)),...
                            (pRect(pNum*4-2)+(pRect(pNum*4)/2))];
                        cent2= [(objRect(1)+(objRect(3)/2)),(objRect(2)+(objRect(4)/2))];
                    end
                    
                    % extract features
                    objNum= 2; % one obj, one person
                    
                    [aiFeat,C,CI,c1,c2]= ...
                        core9_extractor3(objNum,pRect((pNum*4-3):(pNum*4)),...
                        objRect,lastC,lastCI,cent1,cent2);
                    lastC= C;
                    lastCI= CI;
                    cent1= c1;
                    cent2= c2;
                       
                    if k>1 % not at the first frame
                        f= cat(1, f, aiFeat); % 1*20 vector of core9 features
                        r= cat(1, r, objRect); % 1*4 for the obj rectangle
                        if (k==2)
                            %start frame for extracting features
                            featured_fr_se(:,j)= curFr; 
                        else
                            %end frame for extracting features
                            featured_fr_se(2,j)= featured_fr_se(2,j)+1; 
                        end
                    end
                end
                feat= cat(2, feat, f);
                recF= cat(2, recF, r);
            end
            features= cat(2, features, {feat});
            rectFeat= cat(2, rectFeat, {recF});
        end
        
        % finds empty cells in features
        emptyCells = cellfun(@isempty,features);
        
        % remove empty cells from features and fr_se
        features(emptyCells) = [];
        rectFeat(emptyCells) = [];
        featured_fr_se(:,emptyCells)= [];
        fr_se= featured_fr_se;
        
        save(['./feature_test/dist_features_',lower(actionList(action,1:3)),...
            num2str(videoNum),'.mat'],'features');
        save(['./feature_test/dist_rectangles_',lower(actionList(action,1:3)),...
            num2str(videoNum),'.mat'],'rectFeat');
        save(['./feature_test/fr_se_',lower(actionList(action,1:3)),...
            num2str(videoNum),'.mat'],'fr_se');
    end      % i'th video
    ti= toc;
    fprintf('--- Time: %1.2f min\n',ti/60);
    fprintf('--------------------\n');
end







