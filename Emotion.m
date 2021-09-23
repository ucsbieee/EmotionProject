classdef Emotion < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        GridLayout              matlab.ui.container.GridLayout
        LeftPanel               matlab.ui.container.Panel
        ControlsPanel           matlab.ui.container.Panel
        ProgressEditFieldLabel  matlab.ui.control.Label
        ProgressEditField       matlab.ui.control.EditField
        BuildDataBaseButton     matlab.ui.control.Button
        StopButton              matlab.ui.control.Button
        StartButton             matlab.ui.control.Button
        TrainCNNButton          matlab.ui.control.Button
        AccuracyEditFieldLabel  matlab.ui.control.Label
        AccuracyEditField       matlab.ui.control.NumericEditField
        RightPanel              matlab.ui.container.Panel
        OutputsPanel            matlab.ui.container.Panel
        UIAxes                  matlab.ui.control.UIAxes
        EmotionEditField        matlab.ui.control.EditField
        EmotionEditFieldLabel   matlab.ui.control.Label
        net %Trained Neural Network
        stop 
    end
    
    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end
    
    % Callbacks that handle component events
    methods (Access = private)
        
        % Button pushed function: BuildDataBaseButton
        function BuildDataBaseButtonPushed(app, event)
            %% Load in data, Convert data to Images, and Build Data Base
            % Data Source: https://www.kaggle.com/c/challenges-in-representation-learning-facial-expression-recognition-challenge
            
            % Details on Data Source: The data consists of 48x48 pixel grayscale images of faces.
            %The faces have been automatically registered so that the face is more or less
            %centered and occupies about the same amount of space in each image.
            %The task is to categorize each face based on the emotion shown in the facial
            %expression in to one of seven categories (0=Angry, 1=Disgust, 2=Fear, 3=Happy, 4=Sad,
            %5=Surprise, 6=Neutral).
            
            % Note this Process of Image Extraction and Database formation form given
            % data takes approx 106 seconds
            
            %write file path to check if any images in Angry Emotions
            %Folder 
            filelist = dir(fullfile('/Users/user/Desktop/Emotion Project/database/Angry','*.*'));
            
            %Adjust the Progress Meter
            app.ProgressEditField.Value = "Building Data Base";
            
            %Pause for change to occur in GUI Progress Section
            pause(0.1)
                 
            if length(filelist) <= 4 %check to see if database already constructed by reading number of files in ANGRY folder
                %If the data base is not constructed then run this code
                
                %read in the face data from the data file 
                datafile = 'icml_face_data.xlsx'; 
                data = readtable(datafile);
                
                %organize the data to put into image pixel arrays from data
                %source
                dim = size(data); %get size of origional data source
                
                for j = 1:dim(1) %iterate through all facial data component 
                    
                    %read in image file and convert from table to number matrix
                    %element 
                    im = data(j,3);
                    im = table2array(im);
                    im = cellfun(@str2num,im,'UniformOutput',false);
                    im = cell2mat(im);
                    
                    %initialize Image Pixel Array
                    Image = [];
                    
                    %Organize image pixel values in data source into image
                    %48x48 pixel array 
                    for i = 1:48
                        Image = cat(1,Image,im((((i-1)*48)+1):(i*48)));
                    end
                    
                    %need to normalize imgages in order for matlab to be
                    %able to work with them
                    maxx = max(Image(:));
                    minx = min(Image(:));
                    img  = (Image - minx) / (maxx - minx);
                    
                    %Store Image in data base based ion which emotion it is
                    databaseFolder = 'database';
                    
                    emotion = data(j,1); %read emotion label from data base
                    emotion = table2array(emotion); %convert table element to array
                    
                    %get correct folder name to store image in
                    switch(emotion)
                        case 0
                            fileFolder = 'Angry';
                        case 1
                            fileFolder = 'Disgust';
                        case 2
                            fileFolder = 'Fear';
                        case 3
                            fileFolder = 'Happy';
                        case 4
                            fileFolder = 'Sad';
                        case 5
                            fileFolder = 'Suprise';
                        case 6
                            fileFolder = 'Neutral';
                    end
                    
                    
                    %Store Image Pixel array as a png image in correct data
                    %base folder 
                    filename = strcat(num2str(j),'.png');%construct file name
                    filepath = fullfile(databaseFolder,fileFolder,filename); %construct file path to store
                    imwrite(img,filepath) %store image in correct folder 
                end
            end
            
            %Update Progress Metric 
            app.ProgressEditField.Value = "Data Base Done";
        end
        
        % Button pushed function: TrainCNNButton
        function TrainCNNButtonPushed(app, event)
            %Construct file path to check if data b ase constructed 
            filelist = dir(fullfile('/Users/user/Desktop/Emotion Project/database/Angry','*.*'));
            ErrorFlag = 0; %Initialize Error idicator 
            
            %check to see if database is constructed by counting number of
            %images in Angry Folder
            if length(filelist) <= 4
                app.ProgressEditField.Value = "Database not Constructed";
                ErrorFlag = 1;
            end
            
            if ErrorFlag == 0
                %update the progress metric on GUI
                app.ProgressEditField.Value  = "Training Neural Network";
                
                %pause to allow progres metric to register
                pause(0.1)
                
                %Train the CNN and get back the trained neural network with
                %accuracy
                [Progress, Accuracy, EmotionNet] = TrainCNN();
                
                %update Progress and Accuracy elements in the GUI
                app.ProgressEditField.Value  = Progress;
                app.AccuracyEditField.Value = Accuracy;
                
                %store the trained network in GUI element for cross function
                %purposes
                app.net = EmotionNet;
            end
        end
        
        
        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            %Construct file path to check if data b ase constructed 
            filelist = dir(fullfile('/Users/user/Desktop/Emotion Project/database/Angry','*.*'));
            
            %update progress metric
            app.ProgressEditField.Value = "Connecting to Webcam"; %Update Progress Checker
            ErrorFlag = 0; %initialize error indicator 
            app.stop = 0; %Set Stop property to 0 for signal continuous looping 
            
            %check to see if data base constructed 
            if length(filelist) <= 4
                app.ProgressEditField.Value = "Database not Constructed";
                ErrorFlag = 1;
            end
            
            %check to see if network trained and stored in property
            if isempty(app.net)
                app.ProgressEditField.Value = "Network not Trained";
                ErrorFlag = 1;
            end
            
            %%
            %continue if there are no errors 
            if ErrorFlag == 0
                %Acces the webcam
                try
                    webcamlist;
                    mycam = webcam;
                catch
                    app.ProgressEditField.Value = "Couldn't Connect Camera";
                end
                %%
                %Acquire the frame image and process while webcam is live
                
                %update progress metric 
                app.ProgressEditField.Value = "Reading Face";
                
                %continue looping and reading facial emotion with network
                while app.stop == 0
                    RGBframe = snapshot(mycam); %take frame image from webcam
                    [label,IMwithFace] = ClassifyFrame(RGBframe,app.net); %use network to classify
                    
                    imshow(IMwithFace,'Parent', app.UIAxes); %show facial image with label on GUI
                    app.EmotionEditField.Value = label; %update emotion field with label
                    pause(0.1) %pause to allow GUI to update and function to check for stop property change
                end
            end
        end
        
        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            app.stop = 1; %change stop property to 1 to stop looping 
            app.ProgressEditField.Value = 'Stopped Reading Face'; %update progress metric 
            
            %pause before reseting value in GUI to allow user to see its
            %stopped
            pause(1)
            
            %reset Emotion and Progress Values 
            app.EmotionEditField.Value = '';
            app.ProgressEditField.Value = '';
            
            %reset the image to a black default 
            imgBlack = zeros(720,1280,3,'uint8'); %create black image pixel array
            imshow(imgBlack,'Parent', app.UIAxes); %show on GUI
        end
        
        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {220, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end
    
    % Component initialization
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            
            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {220, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';
            
            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.BackgroundColor = [0 0.4471 0.7412];
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            
            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.LeftPanel);
            app.ControlsPanel.ForegroundColor = [1 1 1];
            app.ControlsPanel.TitlePosition = 'centertop';
            app.ControlsPanel.Title = 'Controls';
            app.ControlsPanel.BackgroundColor = [0.0745 0.6235 1];
            app.ControlsPanel.Position = [6 6 208 468];
            
            % Create ProgressEditFieldLabel
            app.ProgressEditFieldLabel = uilabel(app.ControlsPanel);
            app.ProgressEditFieldLabel.HorizontalAlignment = 'right';
            app.ProgressEditFieldLabel.FontName = 'Palatino';
            app.ProgressEditFieldLabel.FontSize = 18;
            app.ProgressEditFieldLabel.FontColor = [0.149 0.149 0.149];
            app.ProgressEditFieldLabel.Position = [67 393 74 33];
            app.ProgressEditFieldLabel.Text = 'Progress';
            
            % Create ProgressEditField
            app.ProgressEditField = uieditfield(app.ControlsPanel, 'text');
            app.ProgressEditField.FontName = 'Palatino';
            app.ProgressEditField.FontColor = [0.149 0.149 0.149];
            app.ProgressEditField.Position = [10 361 189 33];
            
            % Create BuildDataBaseButton
            app.BuildDataBaseButton = uibutton(app.ControlsPanel, 'push');
            app.BuildDataBaseButton.ButtonPushedFcn = createCallbackFcn(app, @BuildDataBaseButtonPushed, true);
            app.BuildDataBaseButton.BackgroundColor = [1 1 1];
            app.BuildDataBaseButton.FontName = 'Palatino';
            app.BuildDataBaseButton.FontSize = 18;
            app.BuildDataBaseButton.FontColor = [0.149 0.149 0.149];
            app.BuildDataBaseButton.Position = [25 289 160 39];
            app.BuildDataBaseButton.Text = 'Build DataBase';
            
            % Create StopButton
            app.StopButton = uibutton(app.ControlsPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.BackgroundColor = [1 1 1];
            app.StopButton.FontName = 'Palatino';
            app.StopButton.FontSize = 18;
            app.StopButton.Position = [24 40 160 39];
            app.StopButton.Text = 'Stop';
            
            % Create StartButton
            app.StartButton = uibutton(app.ControlsPanel, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.BackgroundColor = [1 1 1];
            app.StartButton.FontName = 'Palatino';
            app.StartButton.FontSize = 18;
            app.StartButton.Position = [24 105 160 39];
            app.StartButton.Text = 'Start';
            
            % Create TrainCNNButton
            app.TrainCNNButton = uibutton(app.ControlsPanel, 'push');
            app.TrainCNNButton.ButtonPushedFcn = createCallbackFcn(app, @TrainCNNButtonPushed, true);
            app.TrainCNNButton.BackgroundColor = [1 1 1];
            app.TrainCNNButton.FontName = 'Palatino';
            app.TrainCNNButton.FontSize = 18;
            app.TrainCNNButton.Position = [25 214 160 39];
            app.TrainCNNButton.Text = 'Train CNN';
            
            % Create AccuracyEditFieldLabel
            app.AccuracyEditFieldLabel = uilabel(app.ControlsPanel);
            app.AccuracyEditFieldLabel.HorizontalAlignment = 'center';
            app.AccuracyEditFieldLabel.FontName = 'Palatino';
            app.AccuracyEditFieldLabel.FontSize = 14;
            app.AccuracyEditFieldLabel.FontColor = [0.149 0.149 0.149];
            app.AccuracyEditFieldLabel.Position = [25 177 64 22];
            app.AccuracyEditFieldLabel.Text = 'Accuracy';
            
            % Create AccuracyEditField
            app.AccuracyEditField = uieditfield(app.ControlsPanel, 'numeric');
            app.AccuracyEditField.HorizontalAlignment = 'center';
            app.AccuracyEditField.FontName = 'Palatino';
            app.AccuracyEditField.FontColor = [0.149 0.149 0.149];
            app.AccuracyEditField.Position = [100 177 85 22];
            
            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.BackgroundColor = [0 0.4471 0.7412];
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
            
            % Create OutputsPanel
            app.OutputsPanel = uipanel(app.RightPanel);
            app.OutputsPanel.ForegroundColor = [1 1 1];
            app.OutputsPanel.TitlePosition = 'centertop';
            app.OutputsPanel.Title = 'Outputs';
            app.OutputsPanel.BackgroundColor = [0.0745 0.6235 1];
            app.OutputsPanel.Position = [6 6 408 468];
            
            % Create UIAxes
            app.UIAxes = uiaxes(app.OutputsPanel);
            app.UIAxes.Position = [11 94 389 332];
            
            % Create EmotionEditField
            app.EmotionEditField = uieditfield(app.OutputsPanel, 'text');
            app.EmotionEditField.FontName = 'Palatino';
            app.EmotionEditField.Position = [187 30 171 34];
            
            % Create EmotionEditFieldLabel
            app.EmotionEditFieldLabel = uilabel(app.OutputsPanel);
            app.EmotionEditFieldLabel.HorizontalAlignment = 'right';
            app.EmotionEditFieldLabel.FontName = 'Palatino';
            app.EmotionEditFieldLabel.FontSize = 24;
            app.EmotionEditFieldLabel.Position = [71 35 96 28];
            app.EmotionEditFieldLabel.Text = 'Emotion';
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end
    
    % App creation and deletion
    methods (Access = public)
        
        % Construct app
        function app = Emotion
            
            % Create UIFigure and components
            createComponents(app)
            
            % Register the app with App Designer
            registerApp(app, app.UIFigure)
            
            if nargout == 0
                clear app
            end
        end
        
        % Code that executes before app deletion
        function delete(app)
            
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end