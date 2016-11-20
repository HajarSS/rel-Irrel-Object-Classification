* Determining Interacting Objects in Human-Centric actions via Qualitative Spatio-Temporal Reasoning - and then human action classification:

- We consider human-centric actions and look to identify which objects in the scene are involved in the dominant action

- We use SVM to recognize relevant objects based on these features

- We use HMM for action classification

- challenging Mind’s Eye dataset / 306 videos / 11 activities like carry, dig, throw, walk

- We do 4 experiments: 
  1. The baseline algorithm —> only uses the distance changes over time
  2. Leave-one-action-out —> train the classifier on 10 actions and evaluate on the 11th
  3. 10-fold cross validation
  4. adding action feature —> evaluate the model in scenarios where the action is known by a new binary indicator feature vector to encode the action being performed

- Total number of tracks: 15694

- Optical Flow —> to detect the moving blobs

- Tracking algorithm: Tracking-Learning-Detection (TLD) / a real-time algorithm for tracking unknown objects in videos

**************************** CODE:
- “hajar_actRelirrel.m” is the main function
   + It loads all train/test features —> the most relevant track per video
   + 10-fold cross-validation
   + training and testing with SVM
   + extracting features for the most relevant track to the person per video
   + We apply “bag of words” technique —> number of words: 1000


- featureFinder.m
   + Extracting features (20-values) for train/test data
    1.change-core9(9-values)  2.change-CoreInterval(6-values)  3.distance
    4.speed-obj1(based on its centroid)   5.speed-obj2  6.size of obj1,2
