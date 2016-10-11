%% Example use - Perspective video rendering
%  For making little animations in which images can move around in
%  perspective.
%
%  Matthew Sheen

close all; clear all;
addpath ../scripts

%% High level quick settings

showTransp = true; % Do transparencies?
vidWrite = true; % Write to file?
showVids = false; % Show video content within the scene, or just the keyframe.
showColorChanges = true; % Do we do color transforms?

fps = 30; % Frames per second. Low for testing stuff, high for render.
startTime = 0; % Zero means full scene. Raise it if I want to only see later stuff.

%% Set up the figure
fig = figure;
hold on
fig.Color = [1,1,1];
fig.Position = [100,100,1920*3/4,1080*3/4];

%% Read video elements
vr = VideoReader('../media/media1.mov');
initVidTime = 109; % time to begin the clip
vr.CurrentTime = initVidTime;
vidFr = readFrame(vr);
imwrite(vidFr,'../media/gameframe.png','PNG'); % First frame will be the default for the surface.

%% Add surfaces
% Import images, skin them to surfaces.
[keySurf,keySurfTrans] = setUpImage('../media/full_keyboard_transQWOP.png',0.2,false);
[QSurf,QSurfTrans] = setUpImage('../media/Q.png',0.2,true);
[WSurf,WSurfTrans] = setUpImage('../media/W.png',0.2,true);
[OSurf,OSurfTrans] = setUpImage('../media/O.png',0.2,true);
[PSurf,PSurfTrans] = setUpImage('../media/P.png',0.2,true);

[BSurf,BSurfTrans] = setUpImage('../media/gameFrame.png',2,false);

allSurfs = {keySurf,QSurf,WSurf,OSurf,PSurf,BSurf};

% Change initial transforms from being solely centered around the origin.
QSurfTrans.Matrix = makehgtform('translate',-410,79,1);
WSurfTrans.Matrix = makehgtform('translate',-330,79,1);
OSurfTrans.Matrix = makehgtform('translate',380,79,1);
PSurfTrans.Matrix = makehgtform('translate',460,79,1);
BSurfTrans.Matrix = makehgtform('translate',0,400,450,'xrotate',pi/2);

allSurfTrans = {keySurfTrans,QSurfTrans,WSurfTrans,OSurfTrans,PSurfTrans,BSurfTrans};

% Keey track of the original transformations
QTrans0 = QSurfTrans.Matrix;
WTrans0 = WSurfTrans.Matrix;
OTrans0 = OSurfTrans.Matrix;
PTrans0 = PSurfTrans.Matrix;
BTrans0 = BSurfTrans.Matrix;


% Keep track of the alpha channel data
keyAlpha = keySurf.AlphaData;
QAlpha = QSurf.AlphaData;
WAlpha = WSurf.AlphaData;
OAlpha = OSurf.AlphaData;
PAlpha = PSurf.AlphaData;
BAlpha = BSurf.AlphaData;

% Keep track of the CData
keyCol = keySurf.CData;
QCol = QSurf.CData;
WCol = WSurf.CData;
OCol = OSurf.CData;
PCol = PSurf.CData;
BCol = BSurf.CData;


%% Set up axes
ax = fig.Children;
ax.Clipping = 'off'; % Don't clip graphics to the bounds of the axes.
ax.Visible = 'off'; % Don't display the cartesian axes.
axis equal
axis([ax.XLim, ax.YLim]);

%% Initial camera settings
ax.CameraViewAngle = 40;
initTarget = ax.CameraTarget;
ax.CameraPosition = [1000,-10*200 + initTarget(2),2000];
ax.CameraUpVector = [0,0,1];
ax.Projection = 'perspective';


%% Set up video writer
tstep = 1/fps;
tFinal = 12;
lastTrans = [1 1 1 1 1 1]; % Keep track of the last set of transparency values so we don't go around changing them all the time.

if vidWrite
    vw = VideoWriter('test','MPEG-4');
    vw.FrameRate = fps;
    open(vw); % Remember to call close after the animation.
end

%% Put loops below to move camera, do transforms, etc.
% Things this does (all are linearly interpolated on targets and times):
% 1) Camera movement.
%       a) Position
%       b) Target
%       c) "Up" vector
% 2) Update any video frames of any movie surfaces.
% 3) Change any surface transparencies.
% 4) Individual surface transforms (rotations & translations).
% 5) Update and take video frame (if turned on)
for time = startTime:tstep:tFinal  
%% Camera
    % Camera positions, targets, up-vectors are interpolated in time to get
    % nice smooth transitions.    
    camTimings = [0;tFinal]; % Return
    
    camTargets = [
        0 0 0; 0 0 0;];

    camPositions = [
        0 -100 1200; 0 -100 1200;];
    
    camUps = [
        0 1 0; 0 1 0;]; % Back to head-on
      
    % Camera stuff - Do camera interpolation and assign to this axis.
    campos(interp1(camTimings,camPositions,time,'linear'));
    camtarget(interp1(camTimings,camTargets,time,'linear'));
    camup(interp1(camTimings,camUps,time,'linear'));
   
%% Change video elements
if showVids
    vr.CurrentTime = time + initVidTime;
    BSurf.CData = flipud(readFrame(vr));
end
    
%% Transparencies
if showTransp
    transTimings = [0;tFinal];
    % [Key surface - Q - W - O - P - Browser] is the order
    transparencies = [1,1,1,1,1,0; 1,1,1,1,1,0];

    currTrans = interp1(transTimings,transparencies,time,'linear');

    changeTrans = ~(currTrans == lastTrans); % Only change transparencies when something has changed. It's super slow since it's a full map the same size as the image.

    for surfIter = 1:length(allSurfs) % Iterate transparency changes for all surfaces.  
        if changeTrans(surfIter)
            if allSurfs{surfIter}.AlphaDataMapping == 'scaled' % Decide whether to use simple scalar scaling or scaling of an entire alpha map the same size as CDATA
                allSurfs{surfIter}.FaceAlpha = currTrans(surfIter);
            else
                allSurfs{surfIter}.AlphaData = keyAlpha*currTrans(surfIter);
            end
        end
    end
    
    lastTrans = currTrans;
end  

%% Color transforms -- Basically just flat color RGB channel multipliers.
% Make keys light up when pressed.
if showColorChanges
    
    colTimings = [0;3;
                    3.5; 5;
                    5.5; 7;
                    7.5; 9;
                    9.5; tFinal];
    
    QColCoeff = [1 1 1; 1 1 1;
        1 1 1; 1 1 1;
        1 1 1; 1 1 1;
        0.4 0.7 1; 0.4 0.7 1;
        1 1 1; 1 1 1;];
    WColCoeff = [1 1 1; 1 1 1;
        1 0.7 0.4; 1 0.7 0.4;
        1 1 1; 1 1 1;
        1 1 1; 1 1 1;
        1 1 1; 1 1 1;];
    OColCoeff = [1 1 1; 1 1 1;
        1 0.7 0.4; 1 0.7 0.4;
        1 1 1; 1 1 1;
        1 1 1; 1 1 1;
        1 1 1; 1 1 1;];
    PColCoeff = [1 1 1; 1 1 1;
        1 1 1; 1 1 1;
        1 1 1; 1 1 1;
        0.4 0.7 1; 0.4 0.7 1;
        1 1 1; 1 1 1;];
    
    currQCol = interp1(colTimings,QColCoeff,time,'linear');
    currWCol = interp1(colTimings,WColCoeff,time,'linear');
    currOCol = interp1(colTimings,OColCoeff,time,'linear');
    currPCol = interp1(colTimings,PColCoeff,time,'linear');
    
    QSurf.CData(:,:,1) = currQCol(1)*QCol(:,:,1);
    QSurf.CData(:,:,2) = currQCol(2)*QCol(:,:,2);
    QSurf.CData(:,:,3) = currQCol(3)*QCol(:,:,3);
    
    WSurf.CData(:,:,1) = currWCol(1)*WCol(:,:,1);
    WSurf.CData(:,:,2) = currWCol(2)*WCol(:,:,2);
    WSurf.CData(:,:,3) = currWCol(3)*WCol(:,:,3);
    
    OSurf.CData(:,:,1) = currOCol(1)*OCol(:,:,1);
    OSurf.CData(:,:,2) = currOCol(2)*OCol(:,:,2);
    OSurf.CData(:,:,3) = currOCol(3)*OCol(:,:,3);
    
    PSurf.CData(:,:,1) = currPCol(1)*PCol(:,:,1);
    PSurf.CData(:,:,2) = currPCol(2)*PCol(:,:,2);
    PSurf.CData(:,:,3) = currPCol(3)*PCol(:,:,3);
end

%% Movements/transforms
    
    moveTimings = colTimings;
               
    % Q transforms
    QTranslate = [0 0 0; 0 0 0;
        0 0 0; 0 0 0;
        0 0 0; 0 0 0;
        0 0 20; 0 0 20;
        0 0 0; 0 0 0;];            
    QRotate = zeros(10,3);
               
    % W transforms
    WTranslate = [0 0 0; 0 0 0;
        0 0 20; 0 0 20;
        0 0 0; 0 0 0;
        0 0 0; 0 0 0;
        0 0 0; 0 0 0;];            
    WRotate = zeros(10,3);
               
    % O transforms           
    OTranslate = [0 0 0; 0 0 0;
        0 0 20; 0 0 20;
        0 0 0; 0 0 0;
        0 0 0; 0 0 0;
        0 0 0; 0 0 0;];
    ORotate = zeros(10,3);
               
    % O transforms           
    PTranslate = [0 0 0; 0 0 0;
        0 0 0; 0 0 0;
        0 0 0; 0 0 0;
        0 0 20; 0 0 20;
        0 0 0; 0 0 0;];
    PRotate = zeros(10,3);
               
    % Interpolate linear motions           
    currQmove = interp1(moveTimings,QTranslate,time,'linear');
    currWmove = interp1(moveTimings,WTranslate,time,'linear');
    currOmove = interp1(moveTimings,OTranslate,time,'linear');
    currPmove = interp1(moveTimings,PTranslate,time,'linear');
    
    % Interpolate rotations
    currQrot = interp1(moveTimings,QRotate,time,'linear');
    currWrot = interp1(moveTimings,WRotate,time,'linear');
    currOrot = interp1(moveTimings,ORotate,time,'linear');
    currProt = interp1(moveTimings,PRotate,time,'linear');
    
    % Compound the transforms (TODO verify the order of rotations is correct)
    QSurfTrans.Matrix = makehgtform('xrotate',currQrot(1),'yrotate',currQrot(2),'zrotate',currQrot(3)); % Do rotation transform about initial centered placement.
    QSurfTrans.Matrix = makehgtform('translate',currQmove)*QTrans0*QSurfTrans.Matrix; % Then do whatever movement gets it to the original position + our extra translation.
    
    WSurfTrans.Matrix = makehgtform('xrotate',currWrot(1),'yrotate',currWrot(2),'zrotate',currWrot(3));
    WSurfTrans.Matrix = makehgtform('translate',currWmove)*WTrans0*WSurfTrans.Matrix;
    
    OSurfTrans.Matrix = makehgtform('xrotate',currOrot(1),'yrotate',currOrot(2),'zrotate',currOrot(3));
    OSurfTrans.Matrix = makehgtform('translate',currOmove)*OTrans0*OSurfTrans.Matrix;
    
    PSurfTrans.Matrix = makehgtform('xrotate',currProt(1),'yrotate',currProt(2),'zrotate',currProt(3));
    PSurfTrans.Matrix = makehgtform('translate',currPmove)*PTrans0*PSurfTrans.Matrix;

    
%% Draw and record frame
    drawnow;
    if vidWrite
        fr = getframe(gcf);
        writeVideo(vw,fr);
    end
end

%% Clean up
if vidWrite, close(vw); end
