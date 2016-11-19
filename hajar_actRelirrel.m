% In the name of GOD...
% ---------------------

% ****************** 7 April 2015 *****************************************
% Action classification using rel/irrel results (with our results)
% TASK #1: HMM / Bag of Words
% Finding the most relevant track per video and doing action classification
% for all 306 videos 
    
% STEP 1: Finding the probability of belonging each track to 'irrel'or'rel'
% -------
%{
% 10-fold crossValidation / SVM 

% Confusion Matrix(without PCA): 12965(85.4647)   2205(14.5353)   
%                                18(3.4351)       506(96.5649)

% run vlfeat-0.9.18/toolbox/vl_setup
% addpath(libsvm-3.12)

load('first_part_try21');
probStimate= zeros(size(predicts,1), numel(unique(allClass)));

svmParams = '-q -t 2 -g 0.31 -d 3 -b 1';
% -t kernel_type, 1 -- polynomial: (gamma*u'*v + coef0)^degree
%                 2 -- radial basis function: exp(-gamma*|u-v|^2)
% -g gamma : set gamma in kernel function (default 1/num_features)
% -d degree : set degree in kernel function (default 3)

tic;
for cv= 1:kf       % 10-Fold cross-validation
    fprintf('Partition test data: %i/%i ...\n', cv, kf);
    
    % test data
    % ---------
    tstIndx= find(test(cvPart, cv)); % indices for the test data
    tstFeat= allFeat(tstIndx,:);
    tstClass= allClass(tstIndx,:);
    
    % Selecting negative data
    % -----------------------
    trnIndx= find(training(cvPart, cv)); % indices for train data
    trnFeat= allFeat(trnIndx,:);

    temp= allnegIs(trnIndx,:);

    negFeat= trnFeat;
    negFeat(temp==0,:)= []; % remove non-negative data

    
    % Adding more positive data
    % -------------------------
    temp= allClass(trnIndx,:);
    pFeat= trnFeat;
    pFeat(temp==0,:)= []; % remove negative data
    posFeat= cat(1, posFeat, pFeat);
    
    % Step3: Making training data (X) and their ground truth classes (Y)
    % ------------------------------------------------------------------
    X= cat(1, posFeat, negFeat);
    Y= zeros(size(X,1),1);
    Y(1:size(posFeat,1),1)= 1;
    
    %tabulate(Y)
    
    % Step4: Creating a Classification Tree
    %--------------------------------------
    model = svmtrain(Y,X,svmParams);
    
    
    % Step5: Predicting test data
    % ---------------------------
    [predictedL,~,prob_st] = svmpredict(tstClass,tstFeat,model,'-b 1');
    
    predicts(tstIndx, :)= predictedL;
    probStimate(tstIndx, :)= prob_st;
    evalu(tstIndx,:)= (predictedL==tstClass);

end 


% Step7: Confusion Matrix
% -----------------------
tab = tabulate(allClass); 
% tab: 1st Col: classes (0,1), 2nd col: counts, 3rd col: percentage
confusionmat(allClass, predicts)
bsxfun(@rdivide,confusionmat(allClass, predicts),tab(:,2))*100

acc = (length(find((predicts == allClass) == 1))/length(allClass))*100 

save('probStimate1_10foldCV_2015April07','probStimate');
%}


% STEP 2: Extract (18)features for pair relevantObjectTrack-person
% -------
%{
% run vlfeat-0.9.18/toolbox/vl_setup
% addpath(libsvm-3.12)

load('first_part_try21');
load('probStimate1_10foldCV_2015April07');
load('allActType');


% list of actions to be processed (11 actions at the moment)
actionList= ['carry  ';'dig    ';'fall   ';'jump   ';'kick   ';'pickup ';
    'putdown';'run    ';'throw  ';'turn   ';'walk   ';];

listVid= []; % list of negative and test videos
for i=1:size(actionList,1)
    listVid= cat(1, listVid, ...
        dir(['./feature_test/dist_features_',actionList(i,1:3),'*.mat']));
end
tic

trFeat= {};   % A cell of all features per track
trSE= [];
allnegIs= []; % a binary vector, shows a track is negative or not
% tstCount= 1;  % counts the number of test tracks 

fprintf('Loading All Data...\n');
for i=1:numel(listVid)   % number of all videos (306)
    curVid= listVid(i).name;    % features for the current video 
    negIsName = strrep(curVid,'dist_features','negIs');
    
    act= sscanf(curVid,'%*4c_%*8c_%3c%*i_*.mat');
    actName= strcat(char(act(1:end))');                  % action name
    actNum= sscanf(curVid,'%*4c_%*8c_%*3c%i_*.mat');     % action number
    
    % Ground truth's rectangles
    rectFolder= ['Detects/',actName,'Detect'];
    listRects= dir(['./',rectFolder,'/Rect*.dat']);
    
    for j= 1:numel(listRects) % ith video
        k= sscanf(listRects(j).name,'%*4c_%*3c%i_*.mat');
        if  (actNum==k)
            num= j;
            break;
        end
    end

    curGt= ['pos_obj_',actName,num2str(num),'.dat'];
    try
        gtTr= load(['./GroundTruth-InvolvedObj/',curGt]);
        gtFr_s= gtTr(1,1)/5;
        gtTr= gtTr(:, 2:end);
        found= 1;
    catch
        % if there is no ground truth for this video, it means that there
        % is no involved object for it
        found= 0;
    end
    
    % Detected(track)'s rectangles
    load (['./feature_test/',curVid]);
    load (['./feature_test/dist_rectangles_',actName,num2str(actNum),'.mat']);
    load (['./feature_test/fr_se_',actName,num2str(actNum),'.mat']);
    load (['./feature_test/',negIsName]);
    
    trNum= size(features,2);
    if size(negIs,2)~=trNum
        error('Missed track! ;)');
    end
    
    allnegIs= cat(1, allnegIs, negIs');
    
    for k=1:trNum   % number of tracks
        if (negIs(k)~=1) && (negIs(k)~=0)
            error('Bad value in negIs! ;)');
        end
        for pNum=1:size(features{k})
            f= features{k}{pNum};
            f(:,16)= f(:,16)./f(:,19);  % distance/size
            f(:,17)= f(:,17)./f(:,19);  % speed_obj1/size_obj1
            f(:,18)= f(:,18)./f(:,20);  % speed_obj2/size_obj2
            f= f(:,1:18);
            
            % Putting the features in a cell array
            % ------------------------------------
            trFeat= cat(2, trFeat, f); % trFeat is a cell of 1xnumTracks
            trSE= cat(2, trSE, fr_se(:,k)); % start-end of each track
        end
    end
end


% Find the most relevant track in each video
%-------------------------------------------
relMask = zeros(size(vidNum)); % a MASK, 1 for the most relevant track per video

for i=1:max(vidNum) % number of videos(306)

    fr_se = zeros(size(trSE));
    fr_se(:, vidNum==i) = trSE(:, vidNum==i);

    temp = probStimate(:,2).*(vidNum==i);
    temp((probStimate(:,2) - probStimate(:,1)) < 0) = 0;
    [m, max_idx] = max(temp);
    
    % if there are more than 1 maximum, choose the longest track
    if sum( temp > (m-0.001)) > 1
        idx = find(temp>(m-0.001)); 
        [~, max_idx] = max(fr_se(2, idx) - fr_se(1, idx));
        max_idx = idx(max_idx , 1);
    end
    if (~isempty(max_idx))
        % if max probability belongs to a relevant track 
        relMask(max_idx,1) = 1; % the most relevant track in video i    
    end
end

% Selecting the most relevant track for each video
relTrFeat= trFeat(relMask==1);
classData= actType(relMask==1); % a vector for class of each video/1..11

% #########################################################################
% for k= 1:max(vidNum)
%     h= probStimate(vidNum==k,2)';
%     fr_se = trSE(:, vidNum==k);
%     
%     fig = figure(k);
%     for i=1:size(fr_se, 2)
%         if(h(i) < 0.9)
%             continue;
%         end
%         plot([fr_se(1,i) , fr_se(2,i)],[h(i),h(i)],'*-b')
%         hold on;
%     end
%     print(fig,'-djpeg',['./figs/probability_',num2str(k),'.jpg']);
%     close;
% end
% #########################################################################
% {
clearvars -except relTrFeat classData

 
% Bag of Words technique: (BoW) 
% to convert each cell of relTrFeat from (numFr-1 x 18) to (numFr-1 x1)
% ---------------------------------------------------------------------
X= [];
numFrames= [];
nClust= 1000; % number of words (clusters)

% Load all data
for i=1:size(relTrFeat, 2) 
    fprintf('track: %i/%i\n',i,size(relTrFeat,2));
    X((end+1):(end+size(relTrFeat{i},1)),:)= relTrFeat{i};
    numFrames= cat(1, numFrames, size(relTrFeat{i},1));
end

% Normalise the data
[~,p] = size(X);              
Xnorm = sqrt(sum(X.^2, 2));     % norm of each instance vector
X = X ./ Xnorm(:,ones(1,p));    % normalize to unit length
X = bsxfun(@rdivide, X, Xnorm);

[~,centers]= kmeans(X,nClust,'emptyaction','singleton','display','iter');

% calculate distance of each instance to all cluster centers
clustIDX= zeros(size(X,1),1);
for i=1:size(X,1)
    %fprintf('pixel:%i...\n', i);
    D= zeros(1,nClust);
    for j=1:nClust
        D(1,j) = sum((X(i,:)-centers(j,:)).^2);
    end
    [~,clustIDX(i,1)]= min(D);
end
% gscatter(X(:,1), X(:,2), clustIDX), axis tight


newTrFeat= {};  % new cell for the track's features
idx= 1;
for i=1:size(relTrFeat, 2)  % number of tracks
    jObs= clustIDX(idx:(numFrames(i)+idx-1),1);
    idx= idx+numFrames(i);
    
    newTrFeat= cat(2, newTrFeat, jObs);
end

save('actionRecog-relIrrel1-2015April07');
%}


% STEP 3: Action Recognition on the features extracted in STEP 2 
% -------
%{
load('actionRecog-relIrrel1-2015April07');

addpath './HMMall/';
mycolors = [ 0.0 0.0 0.5;
             0.0 0.0 1.0;
             0.0 0.5 1.0;
             0.0 1.0 1.0;
             0.3 0.8 0.5;
             0.9 0.9 0.0;
             1.0 0.5 0.0;
             1.0 0.0 0.0;
             0.5 0.0 0.0;
             0.8 0.0 0.5;
             0.2 0.6 0.8;];
         


% list of actions to be processed (11 actions at the moment)
actionList= ['carry  ';'dig    ';'fall   ';'jump   ';'kick   ';'pickup ';
             'putdown';'run    ';'throw  ';'turn   ';'walk   ';];

nState= 2;       % number of states
nObs= 1000;      % number of observation (number of clusters: nClust)
priorD= 0.0001;  % Pseudocount (Dirichlet Prior)

estPrior= cell(1,size(actionList,1));
estTrans= cell(1,size(actionList,1));
estEmis= cell(1,size(actionList,1));

results= zeros(size(actionList,1)); % 11x11 matrix

% ----------------------- Loading Training Data
trainData= newTrFeat; 

for act= 1:size(actionList,1) % act: the action with CrossVal on that
    fprintf('---------- action: %s\n',actionList(act,1:end));
       
    othAct= 1:11;
    othAct(act)= [];  % other actions with no-CrossVal
    
    fprintf('----- Training other actions than CV-action including:\n');
    % training other actions (non-CrossVal actions)
    for i=1:length(othAct) % training on other actions
        fprintf('----- action: %s\n',actionList(othAct(i),1:end));
        % ----------------------- Initial Parameters
        % initial probability
        prior= normalise(rand(nState,1));

        % initial state transition matrix
        trans= mk_stochastic(rand(nState,nState));
        
        % initial observation emission matrix
        emis= mk_stochastic(rand(nState,nObs));
        % ------------------------------------------
        
        % ----------------------- Training HMM
        % improve guess of parameters using EM
        [LL,x1,x2,x3]= ...
            dhmm_em(trainData(classData==othAct(i)),prior,trans,emis,'max_iter',100,'obs_prior_weight',priorD);
        %fprintf('(%d data)\n',length(trainData(classData==othAct(i))));
        estPrior{othAct(i)}= x1;
        estTrans{othAct(i)}= x2;
        estEmis{othAct(i)}= x3;
    end
    
    % traning CrossVal action (CV)
    for i=1:sum(classData==act) % number of training data in CV-action
        % ------------------------------------------
        trainD= trainData(classData==act);
        testD= trainD(i);    % one video for test, all others for train
        trainD(i)= [];       % delete the test data video)

        % train the model on trainD
        % ------------------------------------------
        prior= normalise(rand(nState,1));
        trans= mk_stochastic(rand(nState,nState));
        emis= mk_stochastic(rand(nState,nObs));

        [LL,x1,x2,x3]= ...
            dhmm_em(trainD,prior,trans,emis,'max_iter',100,'obs_prior_weight',priorD);
        estPrior{act}= x1;
        estTrans{act}= x2;
        estEmis{act}= x3;
        
        % test the model on testD including only one video of action 'act'
        % ------------------------------------------
        % ----------------------- Evaluation HMM models
        loglik= zeros(1,size(actionList,1));
        for j=1:size(actionList,1)  % number of actions
            loglik(j)=dhmm_logprob(testD,estPrior{j},estTrans{j},estEmis{j});
        end
        [mag,idx]= max(loglik);
        
        fprintf(' - data %d,loglike: %.2f, estimated action: %s\n',i,mag,actionList(idx,1:end));
        results(act,idx)= results(act,idx)+1;

        %fid = fopen('EvalRes.dat','a');
        %fprintf(fid,' - data %d, estimated action: %s',i,actionList(idx,1:end));
        %fprintf(fid,'\n');
        %fclose(fid);
    end
    fig= figure(11);
    bar(results(act,:),'FaceColor',mycolors(act,:));
    set(gca,'XTickLabel',{'carry','dig','fall','jump','kick','pickup',...
        'putdown','run','throw','turn','walk',});
    axis([0 12 0 sum(classData==act)]);  
    title(actionList(act,1:3));
    grid on
    
    print(fig,'-djpeg',[actionList(act,1:3),'.jpg']);
    fprintf('\n');
end
%fprintf('Time used: %0.2f min\n',(cputime-t)/60);


% Confusin Matrix
confMat= zeros(size(results));
for i=1:size(results,1)
    confMat(i, :)=  (results(i,:)/sum(results(i,:)))*100;
end


% Figure: Draw the confusion matrix
close all

% Create data
mymatrix = confMat;

% generate a plot
image(mymatrix); 
colormap(jet);
colorbar

% Define the labels 
lab = [{'carry'};{'dig'};{'fall'};{'jump'};{'kick'};{'pickup'};{'putdown'};...
    {'run'};{'throw'};{'turn'};{'walk'}];


% Set the tick locations and remove the labels 
set(gca,'XTick',1:11,'XTickLabel','','YTick',1:11,'YTickLabel',lab); 

% Estimate the location of the labels based on the position of the xlabel 
hx = get(gca,'XLabel');  % Handle to xlabel 
set(hx,'Units','data'); 
pos = get(hx,'Position'); 
yt = pos(2); 

textStrings = num2str(mymatrix(:),'%0.2f');  %# Create strings from the matrix values
textStrings = strtrim(cellstr(textStrings));  %# Remove any space padding
[x,y] = meshgrid(1:11);   %# Create x and y coordinates for the strings
hStrings = text(x(:),y(:),textStrings(:),...      %# Plot the strings
                'HorizontalAlignment','center','FontSize', 6);
midValue = mean(get(gca,'CLim'));  %# Get the middle value of the color range
textColors = [0 0 0]; 
set(hStrings,{'Color'},num2cell(textColors,2));  %# Change the text colors


pos = get( gca, 'Position' );
set( gca, 'Position', [0.2 0.17 0.7 0.7] )
        
Xt=get(gca,'XTick');
% Place the new labels 
for i = 1:size(lab,1) 
    t(i) = text(Xt(i),yt,lab(i,:)); 
end 

set(t,'Rotation',45,'HorizontalAlignment','right')  
saveas(gca,'confMat_HMM1-2015April07','epsc')
%}
% *************************************************************************





% ****************** 13 April 2015 ****************************************
% TASK #3: 
% Classifier: SVM / Fisher Vector
% Finding the most relevant track per video and doing action classification
% for all 306 videos

% {
% STEP 1: Extracting (18)features for each track over frames of a video 
% .....................................................................

% list of actions to be processed (11 actions at the moment)
actionList= ['carry  ';'dig    ';'fall   ';'jump   ';'kick   ';'pickup ';
    'putdown';'run    ';'throw  ';'turn   ';'walk   ';];

listVid= []; % list of negative and test videos
for i=1:size(actionList,1)
    listVid= cat(1, listVid, ...
        dir(['./feature_test/dist_features_',actionList(i,1:3),'*.mat']));
end
tic

trFeat= {};   % A cell of all features per track
allnegIs= []; % a binary vector, shows a track is negative or not
tstCount= 1;  % counts the number of test tracks 


fprintf('Loading All Data...\n');
for i=1:numel(listVid);  % number of all videos (306)
    curVid= listVid(i).name;   % features for the current video 
    negIsName = strrep(curVid,'dist_features','negIs');
    
    act= sscanf(curVid,'%*4c_%*8c_%3c%*i_*.mat');
    actName= strcat(char(act(1:end))');                  % action name
    actNum= sscanf(curVid,'%*4c_%*8c_%*3c%i_*.mat');     % action number
    
    % Ground truth's rectangles
    rectFolder= ['./Detects/',actName,'Detect/'];
    listRects= dir(['./',rectFolder,'/Rect*.dat']);
    
    for j= 1:numel(listRects) % ith video
        k= sscanf(listRects(j).name,'%*4c_%*3c%i_*.mat');
        if  (actNum==k)
            num= j;
            break;
        end
    end
    curGt= ['pos_obj_',actName,num2str(num),'.dat'];
    try
        gtTr= load(['./GroundTruth-InvolvedObj/',curGt]);
        gtFr_s= gtTr(1,1)/5;
        gtTr= gtTr(:, 2:end);
        found= 1;
    catch
        % if there is no ground truth for this video, it means that there
        % is no involved object for it
        found= 0;
    end
    
    % Detected(track)'s rectangles
    load (['./feature_test/',curVid]);
    load (['./feature_test/dist_rectangles_',actName,num2str(actNum),'.mat']);
    load (['./feature_test/fr_se_',actName,num2str(actNum),'.mat']);
    load (['./feature_test/',negIsName]);
    
    trNum= size(features,2);
    if size(negIs,2)~=trNum
        error('Missed track! ;)');
    end
    
    allnegIs= cat(1, allnegIs, negIs');
    
    for k=1:trNum   % number of tracks
        if (negIs(k)~=1) && (negIs(k)~=0)
            error('Bad value in negIs! ;)');
        end
        for pNum=1:size(features{k})
            f= features{k}{pNum};
            f(:,16)= f(:,16)./f(:,19);  % distance/size
            f(:,17)= f(:,17)./f(:,19);  % speed_obj1/size_obj1
            f(:,18)= f(:,18)./f(:,20);  % speed_obj2/size_obj2
            f= f(:,1:18);
            
            % Putting the features in a cell array
            % ------------------------------------
            trFeat= cat(2, trFeat, f); % trFeat is a cell of 1xnumTracks

        end
    end
end

clearvars -except trFeat

% Bag of Words technique: (BoW) 
% to convert each cell of trFeat from (numFr-1 x 18) to (numFr-1 x 1)
% ----------------------------------------------------------------------
X= [];
numFrames= [];
nClust= 1000; % number of words (clusters)

% Load all data
for i=1:size(trFeat, 2) 
    fprintf('track: %i/%i\n',i,size(trFeat,2));
    X((end+1):(end+size(trFeat{i},1)),:)= trFeat{i};
    numFrames= cat(1, numFrames, size(trFeat{i},1));
end

% Normalise the data
[~,p] = size(X);              
Xnorm = sqrt(sum(X.^2, 2));     % norm of each instance vector
X = X ./ Xnorm(:,ones(1,p));    % normalize to unit length
X = bsxfun(@rdivide, X, Xnorm);


% pick a subset
SUBSET_SIZE = 10000;             % subset size
ind = randperm(size(X,1));
data = X(ind(1:SUBSET_SIZE), :);

[~,centers]= kmeans(data,nClust,'emptyaction','singleton','display','iter');

% calculate distance of each instance to all cluster centers
clustIDX= zeros(size(X,1),1);
for i=1:size(X,1)
    %fprintf('pixel:%i...\n', i);
    D= zeros(1,nClust);
    for j=1:nClust
        D(1,j) = sum((X(i,:)-centers(j,:)).^2);
    end
    [~,clustIDX(i,1)]= min(D);
end
% gscatter(X(:,1), X(:,2), clustIDX), axis tight


newTrFeat= {};  % new cell for the track's features
idx= 1;
for i=1:size(trFeat, 2)  % number of tracks
    jObs= clustIDX(idx:(numFrames(i)+idx-1),1);
    idx= idx+numFrames(i);
    
    newTrFeat= cat(2, newTrFeat, jObs);
end

%}

% STEP 2: Action Recognition on the features extracted in STEP 1
% ..............................................................
addpath './HMMall/';
mycolors = [ 0.0 0.0 0.5;
             0.0 0.0 1.0;
             0.0 0.5 1.0;
             0.0 1.0 1.0;
             0.3 0.8 0.5;
             0.9 0.9 0.0;
             1.0 0.5 0.0;
             1.0 0.0 0.0;
             0.5 0.0 0.0;
             0.8 0.0 0.5;
             0.2 0.6 0.8;];
         


% list of actions to be processed (11 actions at the moment)
actionList= ['carry  ';'dig    ';'fall   ';'jump   ';'kick   ';'pickup ';
             'putdown';'run    ';'throw  ';'turn   ';'walk   ';];

nState= 2;    % number of states
nObs= 1000;    % number of observation (number of clusters: nClust)
priorD= 0.0001;  % Pseudocount (Dirichlet Prior)


estPrior= cell(1,size(actionList,1));
estTrans= cell(1,size(actionList,1));
estEmis= cell(1,size(actionList,1));

results= zeros(size(actionList,1)); % 11x11 matrix

% ----------------------- Loading Training Data
load predicts_10FoldCV_29May2014.mat % predicts: rel/irrelevancy
trainData= newTrFeat(1,predicts==1); 
load allActType;
classData= actType(predicts==1,:); % a vector for class of each training data includes 1..11


for act= 1:size(actionList,1) % act: the action with CrossVal on that
    fprintf('---------- action: %s\n',actionList(act,1:end));
       
    othAct= 1:11;
    othAct(act)= [];  % other actions with no-CrossVal
    
    fprintf('----- Training other actions than CV-action including:\n');
    % training other actions (non-CrossVal actions)
    for i=1:length(othAct) % training on other actions
        fprintf('----- action: %s\n',actionList(othAct(i),1:end));
        % ----------------------- Initial Parameters
        % initial probability
        prior= normalise(rand(nState,1));

        % initial state transition matrix
        trans= mk_stochastic(rand(nState,nState));
        
        % initial observation emission matrix
        emis= mk_stochastic(rand(nState,nObs));
        % ------------------------------------------
        
        % ----------------------- Training HMM
        % improve guess of parameters using EM
        [LL,x1,x2,x3]= ...
            dhmm_em(trainData(classData==othAct(i)),prior,trans,emis,'max_iter',100,'obs_prior_weight',priorD);
        %fprintf('(%d data)\n',length(trainData(classData==othAct(i))));
        estPrior{othAct(i)}= x1;
        estTrans{othAct(i)}= x2;
        estEmis{othAct(i)}= x3;
    end
    
    % traning CrossVal action (CV)
    for i=1:sum(classData==act) % number of training data in CV-action
        % ------------------------------------------
        trainD= trainData(classData==act);
        testD= trainD(i);    % one video for test, all others for train
        trainD(i)= [];       % delete the test data video)

        % train the model on trainD
        % ------------------------------------------
        prior= normalise(rand(nState,1));
        trans= mk_stochastic(rand(nState,nState));
        emis= mk_stochastic(rand(nState,nObs));

        [LL,x1,x2,x3]= ...
            dhmm_em(trainD,prior,trans,emis,'max_iter',100,'obs_prior_weight',priorD);
        estPrior{act}= x1;
        estTrans{act}= x2;
        estEmis{act}= x3;
        
        % test the model on testD including only one video of action 'act'
        % ------------------------------------------
        % ----------------------- Evaluation HMM models
        loglik= zeros(1,size(actionList,1));
        for j=1:size(actionList,1)  % number of actions
            loglik(j)=dhmm_logprob(testD,estPrior{j},estTrans{j},estEmis{j});
        end
        [mag,idx]= max(loglik);
        
        fprintf(' - data %d,loglike: %.2f, estimated action: %s\n',i,mag,actionList(idx,1:end));
        results(act,idx)= results(act,idx)+1;
        
        %fid = fopen('EvalRes.dat','a');
        %fprintf(fid,' - data %d, estimated action: %s',i,actionList(idx,1:end));
        %fprintf(fid,'\n');
        %fclose(fid);
    end
    fig= figure(11);
    bar(results(act,:),'FaceColor',mycolors(act,:));
    set(gca,'XTickLabel',{'carry','dig','fall','jump','kick','pickup',...
        'putdown','run','throw','turn','walk',});
    axis([0 12 0 sum(classData==act)]);  
    title(actionList(act,1:3));
    grid on
    
    print(fig,'-djpeg',[actionList(act,1:3),'.jpg']);
    fprintf('\n');
end
%fprintf('Time used: %0.2f min\n',(cputime-t)/60);


% Confusin Matrix
confMat= zeros(size(results));
for i=1:size(results,1)
    confMat(i, :)=  (results(i,:)/sum(results(i,:)))*100;
end


% Figure: Draw the confusion matrix 
close all

% Create data
mymatrix = confMat;

% generate a plot
image(mymatrix); 
colormap(jet);
colorbar

% Define the labels 
lab = [{'carry'};{'dig'};{'fall'};{'jump'};{'kick'};{'pickup'};{'putdown'};...
    {'run'};{'throw'};{'turn'};{'walk'}];


% Set the tick locations and remove the labels 
set(gca,'XTick',1:11,'XTickLabel','','YTick',1:11,'YTickLabel',lab); 

% Estimate the location of the labels based on the position of the xlabel 
hx = get(gca,'XLabel');  % Handle to xlabel 
set(hx,'Units','data'); 
pos = get(hx,'Position'); 
yt = pos(2); 

textStrings = num2str(mymatrix(:),'%0.2f');  %# Create strings from the matrix values
textStrings = strtrim(cellstr(textStrings));  %# Remove any space padding
[x,y] = meshgrid(1:11);   %# Create x and y coordinates for the strings
hStrings = text(x(:),y(:),textStrings(:),...      %# Plot the strings
                'HorizontalAlignment','center','FontSize', 6);
midValue = mean(get(gca,'CLim'));  %# Get the middle value of the color range
textColors = [0 0 0]; 
set(hStrings,{'Color'},num2cell(textColors,2));  %# Change the text colors


pos = get( gca, 'Position' );
set( gca, 'Position', [0.2 0.17 0.7 0.7] )
        
Xt=get(gca,'XTick');
% Place the new labels 
for i = 1:size(lab,1) 
    t(i) = text(Xt(i),yt,lab(i,:)); 
end 

set(t,'Rotation',45,'HorizontalAlignment','right')  
saveas(gca,'figure_name_out','epsc')

%}


% ---------------------------- Leeds --------------------------------------
% The best gamma parameter for SVM for 10-fold cross-validation (ACCV-2014)
% g= 0.1 : 12528(82.5840)   2642(17.4160)   Macro Acc: 88.2386
%          32(6.1069)       492(93.8931)
% g= 0.2 : 12799(84.3705)   2371(15.6295)   Macro Acc: 89.9906
%          23(4.3893)       501(95.6107)
% g= 0.3 : 12960(85.4318)   2210(14.5682)   Macro Acc: 90.9983
%                      18(3.4351)       506(96.5649)
% g= 0.4 : 12760(84.1134)   2410(15.8866)   Macro Acc: 90.5300
%          16(3.0534)       508(96.9466)%
% g= 0.5 : 10329(68.0883)   4841(31.9117)   Macro Acc: 82.6129
%          15(2.8626)       509(97.1374)
% g= 0.6 : 9843(64.8846)    5327(35.1154)   Macro Acc: 81.1064
%          14(2.6718)       510(97.3282)
% g= 0.7 : 9538(62.8741)    5632(37.1259)   Macro Acc: 80.1011
%          14(2.6718)       510(97.3282)

% g= 0.31: 12965(85.4647)   2205(14.5353)   Macro Acc: 91.0148
%          18(3.4351)       506(96.5649)