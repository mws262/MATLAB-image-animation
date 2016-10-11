%% Example use - Perspective video rendering
%  For making little animations in which images can move around in
%  perspective.
%
%  Matthew Sheen

close all; clear all;


%% High level quick settings

showTransp = true; % Do transparencies?
vidWrite = true; % Write to file?
showVids = true; % Show video content within the scene, or just the keyframe.

fps = 30; % Frames per second. Low for testing stuff, high for render.
startTime = 0; % Zero means full scene. Raise it if I want to only see later stuff.

%% Set up the figure
fig = figure;
hold on
fig.Color = [1,1,1];
fig.Position = [100,100,1920*3/4,1080*3/4];

%% Read video elements
vr = VideoReader('media1.mov');
initVidTime = 109; % time to begin the clip
vr.CurrentTime = initVidTime;
vidFr = readFrame(vr);
imwrite(vidFr,'gameframe.png','PNG'); % First frame will be the default for the surface.

%% Add surfaces
% Import images, skin them to surfaces.
[keySurf,keySurfTrans] = setUpImage('full_keyboard.png',0.2,false);
[QSurf,QSurfTrans] = setUpImage('Q.png',0.2,true);
[WSurf,WSurfTrans] = setUpImage('W.png',0.2,true);
[OSurf,OSurfTrans] = setUpImage('O.png',0.2,true);
[PSurf,PSurfTrans] = setUpImage('P.png',0.2,true);

%[BSurf,BSurfTrans] = setUpImage('browser.png',1);
[BSurf,BSurfTrans] = setUpImage('gameFrame.png',2,false);

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
tFinal = 35;
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
    camTimings = [0; 2; % Initial view
        3; 5;
        7; 10;
        11.5; 14; % All keys together
        17; 20; % QW to side
        22; 24; % Return to nominal
        27; 30; % OP to side
        32; tFinal]; % Return
    
    camTargets = [0 400 445; 0 400 445; 
        0 200 200; 0 200 200;
        0 0 0; 0 0 0;
        0 0 0; 0 0 0;
        500,0,500; 500,0,500 % Side to look at QW
        0 0 0; 0 0 0; % Back to head-on 
        -500 0 500; -500,0,500; % Side to look at OP
        0 0 0; 0 0 0;]; % Back to head-on
    
    camPositions = [0 -480 445; 0 -480 445;
        800 -1500 1000; 800 -1500 1000;
        100 -100 1200; 100 -100 1200;
        0 -100 1200; 0 -100 1200;
        0 0 500; 0 0 500; % Side to look at QW
        0 -100 1200; 0 -100 1200; % Back to head-on
        0 0 500; 0 0 500; % Side to look at OP
        0 -100 1200; 0 -100 1200]; % Back to head on
    
    camUps = [0 0 1; 0 0 1;
        0 0 1; 0 0 1;
        0 1 0; 0 1 0;
        0 1 0; 0 1 0;
        0 0 1; 0 0 1 % Side to look at QW
        0 1 0; 0 1 0; % Back to head-on
        0 0 1; 0 0 1; % Side to look at OP
        0 1 0; 0 1 0]; % Back to head-on
      
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
    transTimings = [0;6
        7;10;
        11.5;14;
        17;tFinal];
    % [Key surface - Q - W - O - P - Browser] is the order
    transparencies = [1,1,1,1,1,1; 1,1,1,1,1,1;
    0.5,1,1,1,1,0.2; 0.5,1,1,1,1,0.2;
    0.1,1,1,1,1,0.; 0.1,1,1,1,1,0.
    0.8,1,1,1,1,0.; 0.8,1,1,1,1,0.];

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

%% Movements/transforms
    stM = 7.3;
    
    moveTimings = [0;stM;
                   stM + 0.5; stM + 0.6;
                   stM + 1.1; stM + 1.2;
                   stM + 1.7; stM + 1.8;
                   stM + 2.3; stM + 2.4;
                   stM + 2.9; stM + 3.0;
                   stM + 3.5; stM + 3.6;
                   stM + 4.5; 14;
                   17; 20; % QW to side
                   22; 24; % Back to nominal
                   27; 30; % OP to side
                   32; tFinal]; % Back to normal
               
    % Q transforms
    QTranslate = [0 0 0; 0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   315 0 250; 315 0 250; % All to center
                   840 40 500; 840 40 500; % Off to side
                   0 0 0; 0 0 0 % Back to nominal
                   0 0 0; 0 0 0 % OP to side
                   0 0 0; 0 0 0]; % OP back to normal
    QRotate = [0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   pi/2 -pi/2 0; pi/2 -pi/2 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;];
               
    % W transforms
    WTranslate = [0 0 0; 0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   315 0 250; 315 0 250;
                   760 -40 500; 760 -40 500
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0];            
    WRotate = [0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   pi/2 -pi/2 0; pi/2 -pi/2 0
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0];
               
    % O transforms           
    OTranslate = [0 0 0; 0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   -315 0 250; -315 0 250;
                   0 0 0;  0 0 0;
                   0 0 0;  0 0 0;
                   -760 -40 500; -760 -40 500
                   0 0 0;  0 0 0;];
    ORotate = [0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0
                   pi/2 pi/2 0; pi/2 pi/2 0
                   0 0 0; 0 0 0];
               
    % O transforms           
    PTranslate = [0 0 0; 0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   -315 0 250; -315 0 250;
                   0 0 0;  0 0 0;
                   0 0 0;  0 0 0;
                   -840 40 500; -840 40 500
                   0 0 0;  0 0 0;];
    PRotate = [0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0;
                   0 0 0; 0 0 0
                   pi/2 pi/2 0; pi/2 pi/2 0
                   0 0 0; 0 0 0];
               
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
