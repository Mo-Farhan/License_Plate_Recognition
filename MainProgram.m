clear all;
close all;
clc;

% Loading the test image as variable 'L'
[filename, pathname] = uigetfile({'30 car images (q7)\*.jpg'},'Select Car Image'); 
inputImage = strcat(pathname, filename);
L = imread(inputImage);

% Splitting the RGB into 3 components
R = L(:,:,1);
G = L(:,:,2);
B = L(:,:,3);

% Creating a mask - Identifying thresholds and selecting pixels
threshMask =  R >= 127 & R <= 250 & G >= 127 & G <= 250 & ...
              B >= 0 & B <= 120;

figure;
imshow(threshMask);
axis image;
title('Binary mask using thresholds');

% STEP 2 - APPLYING MAJORITY FILTER
M = size(threshMask,1);
N = size(threshMask,2);

W = 3; % 3x3 Window 

mjryBinary = threshMask; 
for i=1+floor(W/2):M-floor(W/2)    % Will leave border unconvolved
    for j=1+floor(W/2):N-floor(W/2)        
        window       = threshMask(i-floor(W/2):i+floor(W/2),j-floor(W/2):j+floor(W/2));        
        window       = window(:);        
        outputValue  = mode(window); % mode function to get most repeated pixels in window       
        mjryBinary(i,j)  = uint8(outputValue);
    end % end for
end % end for

figure;
imshow(mjryBinary);
axis image;
title('Image after applying Majority Filter');

% APPLYING MORPHOLOGICAL OPERATORS 
% Creating strels using 'strel' function
s = strel('square', 65);
s2 = strel('square', 80);
s3 = strel('square', 90);

% Applying morphological operations
closingImage = imclose(mjryBinary, s);
morphImage = imopen(closingImage, s2);

% Calculating the numbers of clusters in the morphed image
C = bwconncomp(morphImage,8);
clusters = C.NumObjects;
disp(['Clusters Selected = ', num2str(clusters)]);

L = im2double(L);

% STEP 3 - Checking number of clusters
% Using if to check the number of clusters in the morphed image.
% ocr works best if number of clusters in the input image == 1
if(clusters > 1)

   % if the intial morphed image has number of clusters > 1 then the image
   % is further morphed again using strel s3 and opening morph operation.
    morphImage2 = imopen(morphImage, s3);

   % image is cropped using 'morphimage2' instead of 'morphimage'
    numPlateCrop = L .* cat(3, morphImage2, morphImage2, morphImage2);

   % displaying clusters of morphImage2
    C2 = bwconncomp(morphImage2,8);
    clusters2 = C2.NumObjects;
    disp(['Clusters Selected = ', num2str(clusters2)]);

    figure;
    imshow(morphImage2);
    axis image;
    title('Morph Image if clusters > 1');

elseif(clusters == 1)
    
    figure;
    imshow(morphImage);
    axis image;
    title('Morph Image if clusters = 1');

    numPlateCrop = L .* cat(3, morphImage, morphImage, morphImage);
end % end if

figure;
imshow(numPlateCrop);
axis image;
title('Input to OCR');

%  STEP - 4 - Performing the ocr function on the cropped input image and 
% using 'TextLayout' as 'Word' so the ocr treats the text in the image as a
% single word of text and using the ocr training file generated after
% training the ocr model. NOTE - select the eng.traineddata file on prompt
[filename2, pathname2] = uigetfile({'OCR training data (q7)\tessdata\eng.traineddata'},...
    'Select training data file'); 
ocrTrainPath = strcat(pathname2,filename2);
ocrResult = ocr(numPlateCrop, 'TextLayout', 'Word', 'Language', ocrTrainPath);
% getting confidence values for each letter recognized and the final confidence value
% is calculated by calculating avg of all the character confidence values
ocrConf = ocrResult.CharacterConfidences;
confValue = (sum(ocrConf, 'omitnan')/numel(ocrConf, 'omitnan'))*100;

% Displaying the text recognized by the ocr and displaying the properties
ocrText = ocrResult.Text;
disp(['License Plate = ', ocrText]);
disp(['Confidence Value = ' num2str(confValue, '%0.2f') '%']);
confLabel = ['Confidence: ' num2str(confValue, '%0.2f') '%'];

% Inserting object annotation onto the original image
rectanglePos = ocrResult.WordBoundingBoxes;
objectAnnotation = insertObjectAnnotation(L,'rectangle', rectanglePos , ... 
    confLabel, 'TextBoxOpacity', 1, 'LineWidth', 7, 'FontSize', 70);

figure;
imshow(objectAnnotation);
axis image;
title('OCR result');




