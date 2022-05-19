clear; close all;

% Task 1: Pre-processing -----------------------
% Step-1: Load input image
I = imread('IMG_11.png');
%figure, imshow(I)

% Step-2: Covert image to grayscale
I_gray = rgb2gray(I);
% figure, imshow(I_gray)

% Step-3: Rescale image
[rows, columns, numberOfColorChannels] = size(I_gray);

% obtain ratio for resize
ratio = rows/512;
I_resized = imresize(I_gray,[512,(columns/ratio)]);
figure, imshow(I_resized)

% Step-4: Produce histogram before enhancing
figure, imhist(I_resized,64);

% Step-5: Enhance image before binarisation

J = imadjust(I_resized);
%figure, imshow(J)

% Step-6: Histogram after enhancement
figure, imhist(J,64);

% Step-7: Image Binarisation
JBW = imbinarize(J);
figure, imshow(JBW)



% % Task 2: Edge detection ------------------------

% canny edge detection
boundsC = edge(JBW, 'Canny');

figure, imshow(boundsC)

% Task 3: Simple segmentation --------------------

% to keep structure of cells partially shown at boundary when closing,
% pad, close , fill, remove padding. Carry out for image top/bottom and for sides.

se = strel('disk',2); %create morphological structuring element

%pad top and bottom with white pixels
paddedTops = padarray(boundsC,[1,0],255);

closedTops = imclose(paddedTops,se); %close

hF = imfill(closedTops,'holes'); % fill holes

hF = hF(1+1:end-1,1:end); %remove padding

% repeat once more for the image sides
paddedSides = padarray(hF,[0,1],255);


closedSides = imclose(paddedSides,se);
F = imfill(closedSides,'holes');
F = F(1:end,1+1:end-1);


%remove objects smaller than blood cells and bacteria
F = bwareaopen(F, 300);

%figure, imshow(F) %uncomment to display segmented image

% %Task 4: Object Recognition --------------------
[B,L,N] = bwboundaries(F); %get boundaries

%get properties of connected components
props = regionprops(F,'all'); 

% Collect area into an individual array.
areas = [props.Area];

%show image with highlighted bacteria and blood cells
figure, imshow(F); hold on;

for k=1:length(B)
   boundary = B{k};
   % area is greater than 1000, red blood cell; fill white boundary red
   if(areas(k) >1000)
     fill(boundary(:,2), boundary(:,1), 'r');
   else % area is less than 1000, bacteria; fill white boundary cyan
     fill(boundary(:,2), boundary(:,1), 'c');
   end
end