%% Clear workspace?
clc;close all;clrok=input('[FEM] Clear Workspace First? y/[n]: ', 's');
if ~isempty(clrok)&&((clrok=='y'||clrok=='Y'))
    clear;
end

%% Flags for controlling content generation. Setting to 0 will disable that portion in the overall video
enableCreateVideoFile = 1;
enablePlotData = 1;
enableVideoData = 1;
enableImageData = 1;
enableModelAnimationData = 1;

%% START OF DATA IMPORT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load user data into workspace
load DATA;

% Define the number of datasteps and desired length of composite video at 30fps
totalSamples = 2299;            % How many sets of data are there? Can be set to a variable in the Plotting data
startSample = 1;                % Set this to totalSamples to see what the final video would look like. Good for debugging
samplingRateHz = 1;             % Define a sampling rate in Hz for synchronis/deterministic data. 
videoTimeSeconds = 20;          % How long do you want the composite video to be
sampleIncrementSize = (totalSamples/30) / videoTimeSeconds;   % This determines the iteration size to ensure video duration at 30fps

% Set Default Fonts, Interpreter and Figure information
% Video Figure Size 1.77 aspect ratio for wide screen 16x9 aspect ratio
widthFig = 1920;
heightFig = 1080;
fs=16; % Default Fontsize
set(0,'defaulttextinterpreter','tex','DefaultTextFontSize',fs,'DefaultAxesFontSize',fs,...
    'DefaultTextFontWeight','Normal','DefaultAxesFontWeight','Normal','DefaultAxesFontName','Times','DefaultTextFontName','Times')
gcf = figure('Position', [0, 10 widthFig, heightFig],'visible', 'on');
set(gcf,'Color','w');
set(gca,'nextplot','replacechildren');

% Import Video Data 
if enableVideoData    
    videoData = VideoReader('VideoData.mp4');   % Read video data
    numVideoFrames = videoData.NumberOfFrames;  % Get number of frames (Usually 29.97 or 59.94)
    startingVideoFrame = 0;                     % User can bias the start of the video for synchronization issues
    videoHeight = videoData.Height;
    videoWidth = videoData.Width;
    % There are typically 29.97 frames per second. If data is taken faster
    % or slower, then the sequencing rate of the video need to be modified.
    % ie, 100Hz data has 100/29.97 data sets per video frame.
    % numDataSamplesPerVideoFrame = samplingRateHz/numVideoFrames;
    %
    % Another way is if the duration of the video is perfectly aligned with
    % the data, then you can divide the number of video frames by the total
    % data samples. 
    % ie, 3000 data sets with 2000 video frames is 2000/3000 or 0.667 data
    % samples per video frame
    numDataSamplesPerVideoFrame = numVideoFrames/totalSamples;   
end

% Import Sequential Image Data
Files = dir('ImageData\*.jpg');
for k=1:length(Files)
   ImageData{k} = Files(k).name;
end

% Model Animation Data 
% Data is based on Elements having Nodes in a coordinate space
if enableModelAnimationData
    ModelScale = 5;     % Define the scaling multiplier
    for i=1:numel(Elements)                
        iNode= Elements{i}.Nodes(1).ID;
        jNode= Elements{i}.Nodes(2).ID;    
%         ModelNodePair{i,1} = [iNode jNode];
        ElementNodePairs(i,1) = iNode;
        ElementNodePairs(i,2) = jNode;
    end    
%     ElmNd  = cat(1,ModelNodePair{:,1});
end

%% START OF SUBPLOT AND FIGURE DESIGN%%%%%%%%%%%%%%%%%%%
% Use the first step of data for initial design of figure
%  Positioning is based on the 4 point Position proprety vector of
%  'Position',[left bottom width height] normalized from 0 -> 1
%  where left  : 0 -> 1 right
%        bottom: 0 -> 1 top
%        width : pixels/widthFig
%        height: pixels/heightFig 
sampleNumber=1; 

% Design the image 
if enableImageData    
    left = 0.55;
    height = 0.23;
    bottom = 0.74;
    width = 0.20;
    sp_image = subplot('Position',[left bottom width height]);        
end

% Design the video 
if enableVideoData    
    left = 0.01;
    height = 0.48;
    bottom = 0.48;
    width = 0.48;
    sp_video = subplot('Position',[left bottom width height]);    
    annotation('textbox',[0.084 0.961 0.124 0.037],'FontSize',16,'string',...
               '{Video Data}','LineStyle','None','Interpreter','latex')             
end

% Design the model animation
if enableModelAnimationData
    left = 0.77;
    height = 0.69;
    bottom = 0.2;
    width = 0.20;
    sp_model = subplot('Position',[left bottom width height]);          
    hold on;
    axis off;
    axis([-1.0 6 -0.5 4.5]); 
    
    % Get Active Nodes coordinate information
    for i=1:numel(Nodes)        
        NodeX(1,i) = Nodes(i).Xcoord;
        NodeY(1,i) = Nodes(i).Ycoord;        
    end
    % Plot all Nodes as points
    ModelAnimationNodes = scatter(NodeX,NodeY,'s','MarkerEdgeColor',[0 0 1]); 
    
    % For each Element, get the coordinates between the Active Node pairs 
    for i=1:length(ElementNodePairs)
        ElementX(1,i) = Nodes(ElementNodePairs(i,1)).Xcoord;
        ElementX(2,i) = Nodes(ElementNodePairs(i,2)).Xcoord;
        ElementY(1,i) = Nodes(ElementNodePairs(i,1)).Ycoord;
        ElementY(2,i) = Nodes(ElementNodePairs(i,2)).Ycoord;        
    end
    % Plot the Lines
    ModelAnimationLines = line(ElementX,ElementY,'LineWidth',2,'Color',[1 0 0]);                    
end

% Design the data plot
if enablePlotData    
    % Time Series Plotting with indicator
    left = 0.05;
    height = 0.41;
    bottom = 0.06;
    width = 0.44;
    sp_x = subplot('Position',[left bottom width height]);
    plot_x = plot(TIME(1:totalSamples),X_TARGET(1:totalSamples),'r',TIME(1:sampleNumber),X_DATA(1:sampleNumber),'-.b',TIME(sampleNumber),X_DATA(sampleNumber),'--b>','MarkerSize',3,'MarkerFaceColor','r','LineWidth',1);
    grid on
    ylabel('Data','FontSize',16)
    xlabel('Time','FontSize',16)
    legend('Predicted','Measured','Location','southwest','FontSize',11,'NumColumns',2)
    axis([0 345 -5 5]);
    yticks(-5:2.5:5)
    annotation('textbox',...
    [0.0512152777777791 0.441124296341152 0.0680555555555542 0.0268518513275516],...
    'String','Control Protocol',...
    'FontSize',12,...
    'FitBoxToText','on');      

    % XY Plotting with indicator
    left = 0.55;
    height = 0.47;
    bottom = 0.23;
    width = 0.20;
    sp_xy = subplot('Position',[left bottom width height]);
    plot_xy = plot(X_DATA(1:sampleNumber),FORCE_DATA(1:sampleNumber),'b',X_DATA(sampleNumber),FORCE_DATA(sampleNumber),'--r>','MarkerSize',3,'MarkerFaceColor','r','LineWidth',1);
    grid on
    ylabel('Y Data','FontSize',16);
    xlabel('X Data','FontSize',16);
    axis([-5 5 -75 75]);
    xticks(-5:2.5:5)
    annotation('textbox',...
    [0.551215277777778 0.670548963726985 0.111631944444444 0.0268518513275517],...
    'String','Energy',...
    'FontSize',12,...
    'FitBoxToText','on');   
end  

% Logo Design at the bottom right corner
height = 73/heightFig; %496/heightFig;
width = 182/widthFig; %198/widthFig;
left = 1-width; % align to right
bottom = 0.0;   % align to corner
sp_logo = subplot('Position',[left bottom width height]);
imshow('Logos_182w_73h.jpg')

% Annotations
% Title
annotation('textbox',...
    [0.607698259949576 0.0166666666666667 0.296989240050424 0.0454153182308524],...
    'String','\textbf{My Compositive Video}',...
    'LineStyle','none',...
    'Interpreter','latex',...
    'FontSize',22,...
    'FitBoxToText','off');
% North Arrow
annotation('arrow',[0.32725 0.357291666666667],...
    [0.882549382716051 0.881481481481482],'Color',[1 0 0],'LineWidth',10,...
    'HeadWidth',20,...
    'HeadStyle','plain');
% North Text Label
annotation('textbox',...
    [0.35605 0.865141975308643 0.0190624999999999 0.0346296296296295],...
    'Color',[1 0 0],...
    'String','\textbf{N}',...
    'LineStyle','none',...
    'Interpreter','latex',...
    'FontSize',24,...
    'FitBoxToText','off');

%% Open the composite video file and append with time to avoid overwriting
if enableCreateVideoFile
    videoFile = VideoWriter(['composite_' datestr(now,'yyyy-mm-dd--HH-MM-SS') ''],'MPEG-4');
    open(videoFile);
end

%% Process each data set to create the next animated figure
for i=startSample:sampleIncrementSize:totalSamples
    % Get sample step info
    sampleNumber = ceil(i); % Round the the next sample since incrementing at certain rates to match final duration will not always be whole number
    if sampleNumber > totalSamples
        % Break out of this loop after the end of the data set
        break;
    end
    % Show progress
    disp (['Step: ' num2str(sampleNumber) ' / ' num2str(totalSamples)]);
    
    % Images
    if enableImageData
        subplot(sp_image);
        % Get image 
        imageFile = imread(['ImageData\' ImageData{sampleNumber}]);
        imshow(imageFile,'Border','tight');     
    end

    % Video 
    if enableVideoData           
        subplot(sp_video);  
        frameNumber = startingVideoFrame + round(sampleNumber*numDataSamplesPerVideoFrame); % Synchronize to the correct video frame
        % If the sequencing of the video was offset, make sure it doesn't
        % go outside the boundary, otherwise just hold position. Good for
        % padding data or if video was started or stopped before or after
        % data was taken
        if frameNumber < 1
            frameNumber = 1;
        elseif frameNumber > numVideoFrames
            frameNumber = numVideoFrames;           
        end
        videoFrame = read(videoData, frameNumber);            
        imshow(videoFrame,'Border','tight');  
    end        
    
    % Model Animation
    if enableModelAnimationData
        subplot(sp_model)
        % Update the coordinate space with the translation data of each
        % node and distance between element node pairs
        % Nodes
        for i=1:numel(Nodes)
            % If a node is restricted, the UX or UY will be -1 so ignore
            % Position is multipled by scaling factor
            if (Nodes(i).UX ~= -1)
                NodeX(1,i) = Nodes(i).Xcoord + ModelScale * MODEL_DATA(sampleNumber, Nodes(i).UX);
            else
                NodeX(1,i) = Nodes(i).Xcoord;
            end
            if (Nodes(i).UY ~= -1)
                NodeY(1,i) = Nodes(i).Ycoord + ModelScale * MODEL_DATA(sampleNumber, Nodes(i).UY);
            else
                NodeY(1,i) = Nodes(i).Ycoord;
            end
        end
        set(ModelAnimationNodes, 'XData', NodeX);
        set(ModelAnimationNodes, 'YData', NodeY);
        % Lines
        for i=1:length(Elements)
            % If a node is restricted, the UX or UY will be -1 so ignore
            % Position is multipled by scaling factor
            ElementX = get(ModelAnimationLines,'XData');
            ElementY = get(ModelAnimationLines,'YData');
            if (Nodes(ElementNodePairs(i,1)).UX ~= -1)
                ElementX{i}(1) = Nodes(ElementNodePairs(i,1)).Xcoord + ModelScale * MODEL_DATA(sampleNumber, Nodes(ElementNodePairs(i,2)).UX);
            else
                ElementX{i}(1) = Nodes(ElementNodePairs(i,1)).Xcoord;
            end
            if (Nodes(ElementNodePairs(i,2)).UX ~= -1)
                ElementX{i}(2) = Nodes(ElementNodePairs(i,2)).Xcoord + ModelScale * MODEL_DATA(sampleNumber, Nodes(ElementNodePairs(i,2)).UX);
            else
                ElementX{i}(2) = Nodes(ElementNodePairs(i,2)).Xcoord;
            end
            if (Nodes(ElementNodePairs(i,1)).UY ~= -1)
                ElementY{i}(1) = Nodes(ElementNodePairs(i,1)).Ycoord + ModelScale * MODEL_DATA(sampleNumber, Nodes(ElementNodePairs(i,1)).UY);
            else
                ElementY{i}(1) = Nodes(ElementNodePairs(i,1)).Ycoord;
            end
            if (Nodes(ElementNodePairs(i,2)).UY ~= -1)
                ElementY{i}(2) = Nodes(ElementNodePairs(i,2)).Ycoord + ModelScale * MODEL_DATA(sampleNumber, Nodes(ElementNodePairs(i,2)).UY);
            else
                ElementY{i}(2) = Nodes(ElementNodePairs(i,2)).Ycoord;
            end
            set(ModelAnimationLines, {'XData'}, ElementX);
            set(ModelAnimationLines, {'YData'}, ElementY);
        end        
    end
     
    % Plots
    if enablePlotData    
        % Time History SPN X
        subplot(sp_x);
        Xupdate = {TIME(1:totalSamples)';TIME(1:sampleNumber)';TIME(sampleNumber)'};
        Yupdate = {X_TARGET(1:totalSamples)';X_DATA(1:sampleNumber)';X_DATA(sampleNumber)'};
        set(plot_x,{'XData'},Xupdate,{'YData'},Yupdate) % Update the plot data                                           
        
        % Hysteresis X
        subplot(sp_xy);
        Xupdate = {X_DATA(1:sampleNumber)';X_DATA(sampleNumber)'};
        Yupdate = {FORCE_DATA(1:sampleNumber)';FORCE_DATA(sampleNumber)'};
        set(plot_xy,{'XData'},Xupdate,{'YData'},Yupdate) % Update the plot data                                                   
     end  
        
    % Write final figure frame to video file
    if enableCreateVideoFile
        writeVideo(videoFile,getframe(gcf));
    end 
end

%% Close the video file to complete process
if enableCreateVideoFile
    close(videoFile);
end