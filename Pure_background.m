clear all
close all
clc

% Create full screen black figure
figure('WindowState','maximized', ...
'Toolbar','none', ...
'MenuBar','none', ...
'Color','k');

% Load background
bg = imread('Campfire_Smackdown_Backdrop.jpg'); % read in background img
bg = flipud(bg); % flip img
[imgH,imgW,~] = size(bg);  % read size
imgRatio = imgW/imgH; % get img ratio

% Get screen ratio
screen = get(0,'ScreenSize'); 
screenRatio = screen(3)/screen(4);

axH = 1; % max y
axW = imgRatio; % img x size
axX = (1-axW)/2; % img location 
axY = 0; % min y

% Create axes
ax = axes('Position',[axX axY axW axH]);
hold on
axis off

% Draw background with correct aspect ratio
bgWidth = imgRatio;
bgHeight = 1;

image('CData',bg,...
      'XData',[0 bgWidth],...
      'YData',[0 bgHeight])

axis image
xlim([0 bgWidth])
ylim([0 bgHeight])

% Load sprites
[ball,~,alpha] = imread('Ball.png');
ball = flipud(ball);
alpha = flipud(alpha);

[marshmellow,~,alpham] = imread('marshmallow.png');
marshmellow = flipud(marshmellow);
alpham = flipud(alpham);

% Object scale (normalized)
scale = 90/imgW;

% Object position (normalized)
screenx = .2;
screeny = .2;

% Draw marshmallow
H = image(marshmellow,...
'XData',[screenx-scale screenx+scale],...
'YData',[screeny-scale screeny+scale],...
'AlphaData',alpham);
