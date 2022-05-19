% Task 5: Robust method --------------------------
clear; close all;

%Load input images from input directory (Assumes this file is within it, or
%inside another directory within the same parent folder)
file_list = dir("..\Assignment_Input");
imgs = {};

%Create output directory in parent folder
mkdir '..' output

%filter to just images and add to list of images to be processed
for i = 1:numel(file_list)
    
    file = file_list(i);
    [filepath,name,ext] = fileparts(file.name);
    abs_path = fullfile(file.folder, file.name);

    %if file name ends with .png, add to image list
    if regexp(file.name, "\.png$")
        I = imread(abs_path); % load image
        imgs{end+1} = I; % append to image array
    end  
end

%for each image in array
for l=1:length(imgs)
    
    % print image number
    fprintf(strcat("Image no. ", num2str(l), "\n"));

    % convert img cell to img
    I = cell2mat(imgs(l));

    % covert image to grayscale
    I_gray = rgb2gray(I);

    % rescale image
    [rows, columns, numberOfColorChannels] = size(I_gray); %get current size 
    
    ratio = rows/512; % obtain ratio for resize
    I_resized = imresize(I_gray,[512,(columns/ratio)]);
    
    % filter image with Gaussian smoothing kernel with standard deviation sigma 0.6.
    smoothImage = imgaussfilt(I_resized, 0.6);
    
    % adjust image contrast
    J = imadjust(smoothImage,[0.1 0.3],[]);
 
    % binarise Image
    JBW = imbinarize(J,0.4);

    % edge detection

    boundsC = edge(JBW, 'Canny');

    % segmentation
    
    se = strel('disk',1); %create morphological structuring element
    
    % to keep structure of cells partially shown at boundary when closing,
    % pad, close , fill, remove padding. Carry out for image top/bottom and for sides.

    %pad top and bottom with white pixels
    paddedTops = padarray(boundsC,[1,0],255);

    closedTops = imclose(paddedTops,se); %close

    hF = imfill(closedTops,'holes');% fill holes
    
    hF = hF(1+1:end-1,1:end); %remove padding

    % repeat once more for the image sides
    paddedSides = padarray(hF,[0,1],255);

    closedSides = imclose(paddedSides,se);
    F = imfill(closedSides,'holes');
    F = F(1:end,1+1:end-1);
    
    % create an image with only cells by opening the image with a large disk
    % structuring element 'altF'
    se = strel('disk',15);
    altF = imopen(F, se);%only cells

    %for whole image 'F', lightly erode for a less noisey image. Contains
    %both cells and bacteria.
    se = strel('line',8,85);
    F = imerode(F, se);

    % remove objects smaller than blood cells and bacteria. This is more
    % extreme for the cell-only image as cells are distinctly much larger.
    altF = bwareaopen(altF, 2000);
    F = bwareaopen(F, 600);
    
    % get size of F
    [rows, columns, numberOfColorChannels] = size(F);
    
    %Create new image newF, which is a union of cell image 'altF' and actual image 'F', where the
    %differences are highlighted as pixel value 2 (bacteria)

    newF = zeros(rows,columns);% establish empty image

    for i=1:rows
        for j=1:columns
            %if actual image contains data and so does cell image, make
            %pixel value = 1 (cell)
            if (F(i,j)~= 0 && altF(i,j)~=0)
                newF(i,j) = 1;
            %if actual image contains data and cell image doesn't, it is
            %bacteria; pixel value = 2     
            elseif (F(i,j) ~= 0 && altF(i,j)==0 )               
                newF(i,j) = 2;
            end
        end % empty background pixels will remain with a 0 value
    end


    % map for label2rgb colours (red & cyan)
    map = [1 0 0
        0 1 1];
    
    % create image numbering system for saving images
    imNumberStr = num2str(l);
    if (strlength(imNumberStr) == 1) %e.g. if image is 1, labeled '01'
         imNumberStr =  strcat("0", imNumberStr);
    end

        
    % create image name
    imSaveName = strcat("output_", imNumberStr,".png");

    % save image
    imwrite(label2rgb(newF,map,[0 0 0]), strcat('..\output\',imSaveName));

 % Task 6: Performance evaluation -----------------

    % load ground truth data

     dirString = "..\Assignment_GT\";

    % loads in accordance to input image number in loop

     imName = strcat("IMG_",imNumberStr,"_GT.png"); 
     imPath = strcat(dirString,imName);
     GT = imread(imPath);
    
    % get initial size of ground truth "GT" image
    [rows, columns, numberOfColorChannels] = size(GT);

    % resize
    ratio = rows/512; %obtain ratio for resize

    GT_resized = imresize(GT,[512,(columns/ratio)]);

    % convert to 2-D array
    GT = rgb2gray(GT_resized);

    % convert to double-types for dice score to work
    GT = double(GT);
    newF = double(newF);

    % get dice score
    similarity = dice(newF, GT);

    %uncomment to show similarity figures for entire dataset
%     figure
%     imshowpair(GT, newF)
%     title([num2str(similarity)]);
%     similarity;

    % get Precision & Accuracy for Cells----------

    [rows, columns, numberOfColorChannels] = size(GT_resized); % get rows and cols sizes

    cTP=0;cFP=0;cTN=0;cFN=0;
    % compare pixel values for "1" in segmented and GT images and add to
    % relevant metric
    for i=1:rows
        for j=1:columns
            if (newF(i,j) == 1 && GT(i,j) ==1)
                cTP = cTP+1;
            elseif(newF(i,j) == 1 && GT(i,j) ~= 1)
                cFP=cFP+1;
            elseif(newF(i,j) ~= 1 && GT(i,j) ~= 1)
                cTN = cTN +1;
            else
                cFN = cFN+1;
            end
        end
    end
    
    % calculate precision & recall
    cPrecision = cTP/(cTP+cFP);
    cRecall = cTP/(cTP+cFN);

    % get Precision & Accuracy for Bacteria----------

    bTP=0;bFP=0;bTN=0;bFN=0;
    
    %same as previously except pixel values to compare are "2" for bacteria.

    for i=1:rows
        for j=1:columns 
            if (newF(i,j) == 2 && GT(i,j) ==2)
                bTP = bTP+1;
            elseif(newF(i,j) == 2 && GT(i,j) ~= 2)
                bFP=bFP+1;
            elseif(newF(i,j) ~= 2 && GT(i,j) ~= 2)
                bTN = bTN +1;
            else
                bFN = bFN+1;
            end
        end
    end

    bPrecision = bTP/(bTP+bFP);
    bRecall = bTP/(bTP+bFN);

    bPrecision = bTP/(bTP+bFP);
    bRecall = bTP/(bTP+bFN);

    %create table showing metrics
    Type = ["cell";"bacteria"];
    Precision = [cPrecision; bPrecision];
    Recall = [cRecall; bRecall];

    Dice = [similarity(1);similarity(2)]; 

    metrics = table(Type,Dice,Precision,Recall);
    disp(metrics);
end