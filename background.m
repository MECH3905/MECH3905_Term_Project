close all
clear
clc

% Create fullscreen figure
figure('WindowState','maximized',...
       'Toolbar','none',...
       'MenuBar','none',...
       'Color','w')

% Make axes fill the entire window
ax = gca;
ax.Position = [0 0 1 1];
axis off

% Load background
bg = imread('background.jpg');

% Fix flipped image
bg = flipud(bg);

% Display background stretched to axes
image('CData',bg,...
      'XData',[0 1],...
      'YData',[0 1])

set(gca,'XLim',[0 1],'YLim',[0 1])

axis off