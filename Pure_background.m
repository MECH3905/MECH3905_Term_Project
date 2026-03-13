clear all
close all
clc

xl = 125;
yl = 75;

%% ---------------- FIGURE SETUP ----------------
%[bg, ball, alpha] = figure_setup(); 
screenSize = get(0,'ScreenSize');

screenW = screenSize(3);
screenH = screenSize(4);

figH = screenH;
figW = figH * 16/9;

xPos = (screenW - figW)/2; % center 
yPos = 0;


figure('WindowState','maximized',... % black background
       'Toolbar','none',...
       'MenuBar','none',...
       'Color','k')

ax = axes;
ax.Position = [0 0 1 1];
axis off
hold on

% Background
bg = imread('background.jpg');
bg = flipud(bg);


image('CData',bg,'XData',[0 16],'YData',[yPos 9])
axis off

ylim([0 9])
xlim([0 16])
