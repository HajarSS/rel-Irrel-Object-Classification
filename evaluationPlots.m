% In the name of GOD...
% ---------------------
% Working on KR conference
% Start: 2013-09-10

% 
%--------------------------------------------------------- 14 Nov 2013
%------- Working on Imbalanced data
%------- Treebagger
%{
load ionosphere;
rng(1945,'twister')
b = TreeBagger(50,X,Y,'oobvarimp','on');
figure(10);
plot(oobError(b));
xlabel('Number of Grown Trees');
ylabel('Out-of-Bag Classification Error');

finbag = zeros(1,b.NTrees);
for t=1:b.NTrees
    finbag(t) = sum(all(~b.OOBIndices(:,1:t),2));
end
finbag = finbag / size(X,1);
figure(12);
plot(finbag);
xlabel('Number of Grown Trees');
ylabel('Fraction of in-Bag Observations');

figure(13);
bar(b.OOBPermutedVarDeltaError);
xlabel('Feature Index');
ylabel('Out-of-Bag Feature Importance');
idxvar= find(b.OOBPermutedVarDeltaError>0.8)

b5v = TreeBagger(100,X(:,idxvar),Y,'oobpred','on');
figure(14);
plot(oobError(b5v));
xlabel('Number of Grown Trees');
ylabel('Out-of-Bag Classification Error');

b5v = fillProximities(b5v);
figure(16);
hist(b5v.OutlierMeasure);
xlabel('Outlier Measure');
ylabel('Number of Observations');
b5v
figure(17);
[s,e] = mdsProx(b5v,'colors','rb');
xlabel('1st Scaled Coordinate');
ylabel('2nd Scaled Coordinate');
b5v

[Yfit,Sfit] = oobPredict(b5v);

% for 'g'
[fpr,tpr] = perfcurve(b5v.Y,Sfit(:,1),'g');
figure(19);
plot(fpr,tpr);
xlabel('False Positive Rate');
ylabel('True Positive Rate');

% for 'b'
[fpr,tpr] = perfcurve(b5v.Y,Sfit(:,2),'b');
figure(19);
plot(fpr,tpr);
xlabel('False Positive Rate');
ylabel('True Positive Rate');
%}

%{  
load posFeat;
load negFeat;

X= cat(1, posFeat, negFeat);
Y= zeros(size(X,1),1);
Y(1:size(posFeat,1),1)= 1;

b = TreeBagger(50,X,Y,'oobvarimp','on');
figure(1);
plot(oobError(b)); % Out-of-bag error
% classification error (fraction of misclassified observations)
xlabel('Number of Grown Trees');
ylabel('Out-of-Bag Classification Error'); 
title('Classification error (fraction of misclassified observations)');

finbag = zeros(1,b.NTrees);
for t=1:b.NTrees
    finbag(t) = sum(all(~b.OOBIndices(:,1:t),2));
end
finbag = finbag / size(X,1);
figure(2);
plot(finbag);
xlabel('Number of Grown Trees');
ylabel('Fraction of in-Bag Observations');

figure(3);
bar(b.OOBPermutedVarDeltaError);
xlabel('Feature Index');
ylabel('Out-of-Bag Feature Importance');
idxvar= find(b.OOBPermutedVarDeltaError>0.3);

b5v = TreeBagger(100,X(:,idxvar),Y,'oobpred','on');
figure(4);
plot(oobError(b5v));
xlabel('Number of Grown Trees');
ylabel('Out-of-Bag Classification Error');
title('Selecting the important features > 0.3');

figure(5);
plot(oobMeanMargin(b5v));
xlabel('Number of Grown Trees');
ylabel('Out-of-Bag Mean Classification Margin');
%For each observation, the margin is defined as the difference between the
%score for the true class and the maximal score for other classes predicted
%by this tree

b5v = fillProximities(b5v);
figure(6);
hist(b5v.OutlierMeasure);
xlabel('Outlier Measure');
ylabel('Number of Observations');

% By applying multidimensional scaling to the computed matrix of
% proximities, you can inspect the structure of the input data and look for
% possible clusters of observations. 
figure(7);
[s,e] = mdsProx(b5v,'colors','rb');
xlabel('1st Scaled Coordinate');
ylabel('2nd Scaled Coordinate');

figure(8);
bar(e(1:50));
xlabel('Scaled Coordinate Index');
ylabel('Eigenvalue'); 
title('the first 50 eigenvalues obtained by scaling');

% Receiver Operating Characteristic (ROC) curve
% ROC: the true positive rate versus the false positive rate
[Yfit,Sfit] = oobPredict(b5v);

% ROC for involved objects
[fpr,tpr] = perfcurve(b5v.Y,Sfit(:,1),'1');
figure(9);
plot(fpr,tpr);
xlabel('False Positive Rate');
ylabel('True Positive Rate');

% ROC for un-involved objects
[fpr,tpr] = perfcurve(b5v.Y,Sfit(:,1),'0');
figure(10);
plot(fpr,tpr);
xlabel('False Positive Rate');
ylabel('True Positive Rate');

[fpr,accu,thre] = perfcurve(b5v.Y,Sfit(:,1),'1','ycrit','accu');
figure(11);
plot(thre,accu);
xlabel('Threshold for ''involved'' Returns');
ylabel('Classification Accuracy');

[maxaccu,iaccu] = max(accu);

%The optimal threshold is:
optThr= thre(iaccu);

[fpr,accu,thre] = perfcurve(b5v.Y,Sfit(:,2),'0','ycrit','accu');
figure(11);
plot(thre,accu);
xlabel('Threshold for ''un-involved'' Returns');
ylabel('Classification Accuracy');

[maxaccu,iaccu] = max(accu);

%The optimal threshold is:
optThr= thre(iaccu);
%}




%--------------------------------------------------------- 15 Nov 2013
% 
%------- Ensemble ClassificationTree, using RUSBoost
% Step 1. Obtain the data.
load posFeat;
load negFeat;

X= cat(1, posFeat, negFeat);
Y= zeros(size(X,1),1);
Y(1:size(posFeat,1),1)= 1;

tabulate(Y)
% '0':  6970 (98.09%), '1': 136 (1.91%)
% This imbalance indicates that RUSBoost is an appropriate algorithm.

[X,Y]= SMOTE(X,Y);
tabulate(Y)

% Step 2. Create the ensemble.
t = ClassificationTree.template('minleaf',5,'prior','uniform');
tic
rusTree = fitensemble(X,Y,'RUSBoost',1000,t,...
    'LearnRate',0.1,'nprint',100);
toc

load tstFeat;
load tstClass;

[tstFeat,tstClass]= SMOTE(tstFeat,tstClass);
tabulate(tstClass)

% Step 3. Inspect the classification error.
figure;
tic
plot(loss(rusTree,tstFeat,tstClass,'mode','cumulative'));
toc
grid on;
xlabel('Number of trees');
ylabel('Test classification error');

% Examine the confusion matrix for each class as a percentage of the true
% class.
tic
Yfit = predict(rusTree,tstFeat);
toc
tab = tabulate(tstClass);
bsxfun(@rdivide,confusionmat(tstClass,Yfit),tab(:,2))*100
%}









