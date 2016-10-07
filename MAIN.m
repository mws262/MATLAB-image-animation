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
fig.Position = [100,100,960,540];

%% Add surfaces
% Import images, skin them to surfaces.
[keySurf,keySurfTrans] = setUpImage('full_keyboard.png',0.2);
[OSurf,OSurfTrans] = setUpImage('O.png',0.2);

% Change initial transforms from being solely centered around the origin.
OSurfTrans.Matrix = makehgtform('translate',0,0,1);

%% Set up axes
ax = fig.Children;
ax.Clipping = 'off'; % Don't clip graphics to the bounds of the axes.
ax.Visible = 'off'; % Don't display the cartesian axes.
axis equal
axis([ax.XLim, ax.YLim]);

%% Initial camera settings
ax.CameraViewAngle = 40;
initTarget = ax.CameraTarget;
ax.Projection = 'perspective';


%% Set up video writer
vw = VideoWriter('test','MPEG-4');
open(vw); % Remember to call close after the animation.


%% Put loops below to move camera, do transforms, etc.
% Example camera move
for i = 1:-0.01:0
    ax.CameraUpVector = [0,1,0];
    ax.CameraPosition = [initTarget(1),i*200 + initTarget(2),600];
    
    drawnow;
    fr = getframe(gcf);
    writeVideo(vw,fr);
end

% Example image move
for i = 0:0.05:10
    OSurfTrans.Matrix = makehgtform('scale',1.01)*OSurfTrans.Matrix;
    
    drawnow;
    fr = getframe(gcf);
    writeVideo(vw,fr);
end

%% Clean up
close(vw);
