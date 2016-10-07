function [ s, strans ] = setUpImage( imagePath, scaleFactor )
% SETUPIMAGE Take an image, map it to a rectangular surface and attach a
% transform.
%   IN:
%   imagePath - an image file that has an alpha channel, example 'test.png'
%   scaleFactor - scale of surface relative to the original image (1 ->
%   same)
%   OUT:
%   s - surface to which the image is mapped
%   strans - hgtransform object to which the surface is attached
%   
%   Matthew Sheen   
%
%   See also HGTRANSFORM, MAKEHGTFORM, SURF   

[Im,~,ImAlpha]  = imread(imagePath); % Read in the image we're going to use as a texture.
Im = flipud(Im); % imread reverses y. Flip it back.
ImAlpha = flipud(ImAlpha);

dimX = floor(size(Im,1)*scaleFactor); % Dimensions of the surface we're going to map the image to.
dimY = floor(size(Im,2)*scaleFactor);

XCoords = linspace(-dimX/2,dimX/2,dimX); % Coordinates of the surface:
YCoords = linspace(-dimY/2,dimY/2,dimY); % Center them around the origin.

s = surf(YCoords,XCoords,zeros(dimX,dimY)); % Make the surface centered around the origin at z = 0.
s.FaceColor = 'texturemap'; % Image texturemap.
s.FaceAlpha = 'texturemap'; % Also transparency should come from an image.
s.EdgeColor = 'none';
s.CData = Im; % Map image to surface.
s.AlphaData = ImAlpha; % Map transparency to surface.

ax = s.Parent; % Get the parent axis object
strans = hgtransform(ax); % Give it a transform as a child
s.Parent =strans; % Make the surface a child of the transform.


% Alter the transform using: strans.Matrix = makehgtform...
end

