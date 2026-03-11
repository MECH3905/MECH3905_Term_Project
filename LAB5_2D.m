clear all
close all
clc

%% ---------------- GLOBAL VARIABLES ----------------
global m rho Cd A ux F_dragx xl yl

% ----- Physical Constants -----
m   = 10;        % mass (kg)
rho = 1.2;       % air density (kg/m^3)
Cd  = 10;        % drag coefficient
A   = 10;        % cross-sectional area (m^2)

ux = 0;
F_dragx = 0;

xl = 150;
yl = 150;

%% ---------------- SERIAL SETUP ----------------
arduinoObj = serialport("COM4",115200);
pause(2)
configureTerminator(arduinoObj,"CR/LF");
flush(arduinoObj);

%% ---------------- FIGURE SETUP ----------------
[e, ball, alpha] = figure_setup();
scale = 0.07;

[b_img, a_img, ~] = size(ball);

% State vector: [position; velocity]
x = [0;0];

dt = 0.02;

H = image(ball,...
    'XData',[x(1)-scale*a_img/2 x(1)+scale*a_img/2],...
    'YData',[-scale*b_img/2 scale*b_img/2],...
    'AlphaData',alpha);

%% ---------------- MAIN LOOP ----------------
while ishandle(H)

    % ----- Read Arduino -----
    if arduinoObj.NumBytesAvailable > 0

        data = readline(arduinoObj);
        tmp = split(strtrim(data),',');

        num = str2double(tmp);

        rawx = num(3);

        % Deadband
        if abs(rawx - 512) < 10
            ux = 0;
        else
            ux = (rawx - 512);
        end

    end

    % ----- RK4 Integration -----
    x = RK4x(x, dt);

    % ----- Boundary Limits -----
    if x(1) > xl
        x(1) = xl;
        x(2) = 0;
    elseif x(1) < -xl
        x(1) = -xl;
        x(2) = 0;
    end

    % ----- Update Ball (Y fixed) -----
    set(H,'XData',[x(1)-scale*a_img/2 x(1)+scale*a_img/2],...
          'YData',[-scale*b_img/2 scale*b_img/2]);

    drawnow limitrate
end

clear arduinoObj

%% ============================================================
% RK4 FUNCTION
%% ============================================================

function x_new = RK4x(x, dt)

    w1=1/6; w2=1/3; w3=1/3; w4=1/6;
    a21=1/2; a31=0; a32=1/2; a41=0; a42=0; a43=1;

    k1 = dt*fx(x);
    k2 = dt*fx(x+a21*k1);
    k3 = dt*fx(x+a31*k1+a32*k2);
    k4 = dt*fx(x+a41*k1+a42*k2+a43*k3);

    x_new = x + w1*k1 + w2*k2 + w3*k3 + w4*k4;
end

%% ============================================================
% X DYNAMICS
%% ============================================================

function dxdtx = fx(x)

    global m rho Cd A ux F_dragx

    dxdtx = zeros(2,1);

    vx = x(2);

    % Quadratic drag
    F_dragx = 0.5 * rho * Cd * A * vx * abs(vx);

    dxdtx(1) = vx;
    dxdtx(2) = (ux - F_dragx) / m;
end

%% ============================================================
% FIGURE SETUP
%% ============================================================

function [e, ball_image, alpha] = figure_setup()

global yl xl

    e = figure('position',[200 200 500 500]);
    hold on
    axis equal

    ax = gca;
    ax.Position = [0 0 1 1];

    set(gcf,'Toolbar','none','Menu','none');
    set(gca,'visible','off');
    set(gcf,'color','w');

    ylim([-yl yl])
    xlim([-xl xl])

    [ball_image,~,alpha] = imread('circle_black_transparent.png');

    ball_image = flipud(ball_image);
    alpha = flipud(alpha);
end