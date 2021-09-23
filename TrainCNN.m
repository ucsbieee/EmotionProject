function [Progress, accuracy, net] = TrainCNN()
%% Load in Contructed Image Data Base as a Image Data Store for Training of Network

try %see if the network has already been trained and saved before 
    load net %load the neural network
    
    %constuct data base to validate accuracy of model
    ImgDatasetPath = 'database'; %set path to database folder
    
    %store images in database variable for network to work with
    imds = imageDatastore(ImgDatasetPath, ...
        'IncludeSubfolders',true, ...
        'LabelSource','foldernames');
    
    %split into validation set, don't need to use all images 
    [imdsTrain,imdsValidation] = splitEachLabel(imds,0.7,'randomized');
    
    %classify the validation set with trained network
    YPred = classify(net,imdsValidation);
    
    %store validation labels 
    YValidation = imdsValidation.Labels;
    
    %get accuracy variable value
    accuracy = sum(YPred == YValidation)/numel(YValidation);
    
    %update progress variable for output
    Progress = "Network Trained";
catch %if the network has not been previously trained and saved (when network fails to load)
    
    %constuct data base to validate accuracy of model
    ImgDatasetPath = 'database';%set path to database folder
    
    %store images in database variable for network to work with
    imds = imageDatastore(ImgDatasetPath, ...
        'IncludeSubfolders',true, ...
        'LabelSource','foldernames');
    %split image set into validation and training set
    [imdsTrain,imdsValidation] = splitEachLabel(imds,0.7,'randomized');
    
    %define input size and number of emotion classes for network
    inputSize = [48 48 1];
    numClasses = 7;
    
    %define the layers of the network
    layers = [
        imageInputLayer(inputSize) %input layer
        
        %first neural layer
        convolution2dLayer(3,8,'Padding','same')
        batchNormalizationLayer
        reluLayer
        
        %pooling layer for first neural layer
        maxPooling2dLayer(2,'Stride',2)
        
        %second neural layer
        convolution2dLayer(3,16,'Padding','same')
        batchNormalizationLayer
        reluLayer
        
        %pooling layer for second neural layer
        maxPooling2dLayer(2,'Stride',2)
        
        %third neural layer 
        convolution2dLayer(3,32,'Padding','same')
        batchNormalizationLayer
        reluLayer
        
        %pooling layer for third neural layer
        maxPooling2dLayer(2,'Stride',2)
        
        %fourth neural layer  
        convolution2dLayer(3,64,'Padding','same')
        batchNormalizationLayer
        reluLayer
        
        %output layers
        fullyConnectedLayer(numClasses) %multiplies the input by weight matrix and adds bias vector. 
        softmaxLayer %applies softmax function to input.
        classificationLayer]; % classifies based on input(computes the cross-entropy loss for classification)
    
    %set of options for training a network using
    %stochastic gradient descent with momentum. Reduce the 
    %learning rate by a factor of 0.01 every epoch. 
    %Set the maximum number of epochs for training to 3. Shuffle different 
    %classification images into each epoch for diverse training. Set
    %validation freauency to every 30 images. Set Verbose Indicator to false to not 
    %display training progress information in the command window. Show
    %plots of training progress
    options = trainingOptions('sgdm', ...
        'InitialLearnRate',0.01, ...
        'MaxEpochs',3, ...
        'Shuffle','every-epoch', ...
        'ValidationData',imdsValidation, ...
        'ValidationFrequency',30, ...
        'Verbose',false, ...
        'Plots','training-progress');
    
    %train the network
    net = trainNetwork(imdsTrain,layers,options);
    %save the network in current folder
    save net
    
    %predict labels with network in validation set
    YPred = classify(net,imdsValidation); %classify with network
    YValidation = imdsValidation.Labels; %get true label values
    
    %use above elements to determine accuracy
    accuracy = sum(YPred == YValidation)/numel(YValidation); %get accuracy
    Progress = "Network Trained"; %change progress metric for output 
end
end