%% Example use - Perspective video rendering
%  For making little animations in which images can move around in
%  perspective.
%
%  Matthew Sheen

close all; clear all;

%% Set up the figure
fig = figure;
hold on
fig.Color = [1,1,1];
fig.Position = [100,100,1920*3/4,1080*3/4];

%% Add surfaces
% Import images, skin them to surfaces.
[keySurf,keySurfTrans] = setUpImage('full_keyboard.png',0.2);
[QSurf,QSurfTrans] = setUpImage('Q.png',0.2);
[WSurf,WSurfTrans] = setUpImage('W.png',0.2);
[OSurf,OSurfTrans] = setUpImage('O.png',0.2);
[PSurf,PSurfTrans] = setUpImage('P.png',0.2);

[BSurf,BSurfTrans] = setUpImage('browser.png',1);

% Change initial transforms from being solely centered around the origin.
QSurfTrans.Matrix = makehgtform('translate',-410,79,1);
WSurfTrans.Matrix = makehgtform('translate',-330,79,1);
OSurfTrans.Matrix = makehgtform('translate',380,79,1);
PSurfTrans.Matrix = makehgtform('translate',460,79,1);
BSurfTrans.Matrix = makehgtform('translate',0,400,450,'xrotate',pi/2);

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
vw = VideoWriter('test','MPEG-4');
open(vw); % Remember to call close after the animation.

fps = 10;
tstep = 1/fps;
tFinal = 12;
lastTrans = [1 1 1 1 1 1]; % Keep track of the last set of transparency values so we don't go around changing them all the time.

%% Put loops below to move camera, do transforms, etc.
% Example camera move
for time = 9:tstep:tFinal  
%% Camera
    % Camera positions, targets, up-vectors are interpolated in time to get
    % nice smooth transitions.    
    camTimings = [0; 2; % Initial view
        3; 5;
        7; 10;
        11.5; tFinal];
    
    camTargets = [0 400 445; 0 400 445; 
        0 200 200; 0 200 200;
        0 0 0; 0 0 0;
        0 0 0; 0 0 0];
    
    camPositions = [0 -480 445; 0 -480 445;
        800 -1500 1000; 800 -1500 1000;
        100 -100 1200; 100 -100 1200;
        0 -100 1200; 0 -100 1200];
    
    camUps = [0 0 1; 0 0 1;
        0 0 1; 0 0 1;
        0 1 0; 0 1 0;
        0 1 0; 0 1 0];
      
    % Camera stuff - Do camera interpolation and assign to this axis.
    campos(interp1(camTimings,camPositions,time,'linear'));
    camtarget(interp1(camTimings,camTargets,time,'linear'));
    camup(interp1(camTimings,camUps,time,'linear'));
    
%% Transparencies
    transTimings = [0;6
        7;10;
        tFinal-0.1;tFinal];
    % [Key surface - Q - W - O - P - Browser] is the order
    transparencies = [1,1,1,1,1,1; 1,1,1,1,1,1;
    0.5,1,1,1,1,0.2; 0.5,1,1,1,1,0.2;
    0.1,1,1,1,1,0.; 0.1,1,1,1,1,0.];

    currTrans = interp1(transTimings,transparencies,time,'linear');

    changeTrans = ~(currTrans == lastTrans); % Only change transparencies when something has changed. It's super slow since it's a full map the same size as the image.

    if changeTrans(1), keySurf.AlphaData = keyAlpha*currTrans(1); end
    if changeTrans(2), QSurf.AlphaData = QAlpha*currTrans(2); end
    if changeTrans(3), WSurf.AlphaData = WAlpha*currTrans(3); end
    if changeTrans(4), OSurf.AlphaData = OAlpha*currTrans(4); end
    if changeTrans(5), PSurf.AlphaData = PAlpha*currTrans(5); end
    if changeTrans(6), BSurf.AlphaData = BAlpha*currTrans(6); end
    
    lastTrans = currTrans;
    
%% Movements/transforms

    stM = 7.3;
    
    moveTimings = [0;stM;
                   stM + 0.5; stM + 0.6;
                   stM + 1.1; stM + 1.2;
                   stM + 1.7; stM + 1.8;
                   stM + 2.3; stM + 2.4;
                   stM + 2.9; stM + 3.0;
                   stM + 3.5; stM + 3.6;
                   stM + 4.5; tFinal];
               
    QTranslate = [0 0 0; 0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   315 0 250; 315 0 250];
               
    OTranslate = [0 0 0; 0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   0 0 30; 0 0 30;
                   0 0 0;  0 0 0;
                   -315 0 250; -315 0 250];
               
    currQmove = interp1(moveTimings,QTranslate,time,'linear');
    currOmove = interp1(moveTimings,OTranslate,time,'linear');
        
    QSurfTrans.Matrix = makehgtform('translate',currQmove)*QTrans0;
    WSurfTrans.Matrix = makehgtform('translate',currQmove)*WTrans0;
    OSurfTrans.Matrix = makehgtform('translate',currOmove)*OTrans0;
    PSurfTrans.Matrix = makehgtform('translate',currOmove)*PTrans0;

    
%% Draw and record frame
    drawnow;
    
    fr = getframe(gcf);
    writeVideo(vw,fr);
end

%% Clean up
close(vw);
