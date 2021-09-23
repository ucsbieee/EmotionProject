function [label,IMwithFace] = ClassifyFrame(RGBframe,net)
%Capture Frame Image
Grayframe = rgb2gray(RGBframe);

%Create Face Recognition Object
faceDetector = vision.CascadeObjectDetector('MergeThreshold',10);


%detect face and crop image to just face for machine learning model to
%recognize
bboxes  = faceDetector(Grayframe);

try
    %resize the bounding box of the face to account for more facial space
    %with 100 pixel buffer
    if isempty(bboxes)
        buffer = 100;
        bboxes(1) = bboxes(1) - buffer;
        bboxes(2) = bboxes(2) - buffer;
        bboxes(3) = bboxes(3) + buffer;
        bboxes(4) = bboxes(4) + buffer;
    end
    imCropped = imcrop(Grayframe,bboxes);%crop image 
    imCropped = imresize(imCropped,[48 48]);%resize to fit network inputs 
    label = classify(net,imCropped); %classify image with network
    label = string(label);% convert label to string 
    IMwithFace = insertObjectAnnotation(RGBframe,'rectangle',bboxes,label); %inset bounding box onto image
catch
    %if face could not be read 
    label = "Couldn't Read Face"; %indicate no facial recognition on emotion element
    IMwithFace = RGBframe; %just show regular webcam image 
end
end