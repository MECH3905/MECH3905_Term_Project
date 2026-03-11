close all; clear; clc;
global m rho Cd A u F_drag xl

% Physics constants
m = 10; rho = 1.2; Cd = 10; A = 10;
u = 0; F_drag = 0; xl = 150;

% --- Connect to Arduino ---
arduino = serialport("COM3", 2000000);  % Change COM3 to your port
configureTerminator(arduino, "LF");
flush(arduino);

% Create fullscreen figure
figure('WindowState','maximized','Toolbar','none','MenuBar','none','Color','w')
ax = gca;
ax.Position = [0 0 1 1];
axis off; hold on

% Background
bg = imread('background.jpg'); bg = flipud(bg);
image('CData',bg,'XData',[0 1],'YData',[0 1])
set(gca,'XLim',[0 1],'YLim',[0 1]); axis off

% Ball
[ball,~,alpha] = imread('Ball.png');
ball = flipud(ball); alpha = flipud(alpha);
scale = 0.06;

% RK4 state
x = [0;0]; dt = 0.02; ballY = 0.5;
screenX = 0.5;

H = image(ball,'XData',[screenX-scale screenX+scale],...
    'YData',[ballY-scale ballY+scale],'AlphaData',alpha);

% Game loop
while ishandle(H)

    % --- Read joystick from Arduino ---
    if arduino.NumBytesAvailable > 0
        line = readline(arduino);
        parts = strsplit(strtrim(line), ',');
        if numel(parts) == 2
            raw = str2double(parts{2});   % 0–1023
            if ~isnan(raw)
                % Map joystick: 512 = center (dead zone ±50)
                joystick = raw - 512;     % -512 to +511
                if abs(joystick) < 50
                    u = 0;                % dead zone
                else
                    u = (joystick / 512) * 300;  % scale to force
                end
            end
        end
    end

    % RK4 update
    x = RK4(x, dt);

    % Boundary limits
    if x(1) > xl;  x(1) = xl;  x(2) = 0;
    elseif x(1) < -xl; x(1) = -xl; x(2) = 0; end

    screenX = (x(1) + xl) / (2*xl);
    set(H,'XData',[screenX-scale screenX+scale],...
          'YData',[ballY-scale ballY+scale]);
    drawnow limitrate
end

clear arduino  % close serial port

% RK4 Solver
function x_new = RK4(x, dt)
    k1 = dt*f(x);
    k2 = dt*f(x + 0.5*k1);
    k3 = dt*f(x + 0.5*k2);
    k4 = dt*f(x + k3);
    x_new = x + (k1 + 2*k2 + 2*k3 + k4)/6;
end

function dxdt = f(x)
    global m rho Cd A u F_drag
    v = x(2);
    F_drag = 0.5*rho*Cd*A*v*abs(v);
    dxdt = [v; (u - F_drag)/m];
end