% Course: MECH 3905
% Project: Lab 5 – Arduino-MATLAB RK4 Joystick
% Date: February 26, 2026
% Group Members: Eric Adamson (B00962642), Francesco Borrelli (B00964461), 
  Quinn Fox (B01020683)
% Purpose: Use a joystick to control a ball's vertical motion, displayed on a 
  screen, by applying a force to a zero-gravity ODE, utilizing Arduino–MATLAB 
  communication.

close all % Closes all figure windows.
clear all % Clears all variables from workspace.
clc % Clears command window. 
 
global m rho Cd A u F_drag xl % Declare global variables 
 
                 % Declare constants
m   = 10;        % Mass (kg)
rho = 1.2;       % Air density (kg/m^3)
Cd  = 10;        % Drag coefficient
A   = 10;        % Cross-sectional area (m^2)
u = 0;           % Applied force
F_drag = 0;      % Drag force
xl = 150;        % Boundary extreme
 
arduinoObj = serialport("COM4", 115200); % Initialize serial communication at a baud rate of 115200
pause(2) % Pause for 2 seconds to allow MATLAB to setup 

configureTerminator(arduinoObj,"CR/LF"); % Setup I/O terminator to be "Carriage Return" and "Linefeed"

flush(arduinoObj); % Discard all data currently in the serial stream
 
% Figure setup
[e, ball, alpha] = figure_setup(); % Create figure and load ball image
scale = 0.07; % Set movement scale
 
[b_img, a_img, ~] = size(ball); % Get ball image size
 
% Initial 2x1 state vector (2 rows, 1 column)
x = [0;     % Initial position (m)  
     0];    % Initial velocity (m/s)
dt = 0.02;  % Time steps to use for solution
 
% Declare arrays to store computed values for later use in plotting
h= [];
ui = [];
xi = [];


H = image(ball,'XData',[-scale*a_img/2 scale*a_img/2], 'YData',[x(1)-scale*b_img/2 x(1)+scale*b_img/2], 'AlphaData',alpha); % Draw ball
 
while ishandle(H) % Test for valid graphic handle
 
    if arduinoObj.NumBytesAvailable > 0 % If Arduino has data ready for  
                                          MATLAB:
        data = readline(arduinoObj);    % Receive data from Arduino
        tmp = split(strtrim(data),','); % Data string is comma-delimited
        num = str2double(tmp);          % Convert strings to numeric double 
                                          type
        raw = num(2);                   % Store Arduino data
 	
	  i = num(1);

                % Deadband (ignore stick drift)
                if abs(raw - 512) < 10 % If force is below 10, do:
                    u = 0; % No force

                else
                    u = (raw - 512); % Apply force
                end
    end
 
    x = RK4(x, dt); % Update position using RK4
 
    % Keep ball inside of boundary Limits
    if  x(1) > xl 
        x(1) = xl; 
        x(2) = 0; 

    elseif x(1) < -xl 
        x(1) = -xl; 
        x(2) = 0; 
    end
 
    h(i) = toc(start_iteration);

    ui(i) = u;

    xi(i) = x(1);
     
    % Move ball on screen 
    set(H,'YData',[x(1)-scale*b_img/2 x(1)+scale*b_img/2]); 
 
    drawnow limitrate % Update figures and process callbacks

end
 
clear arduinoObj % Close the Serial Communication port
% Plot results
figure(1) 
plot(h,ui,'r','LineWidth',1.5)
title("Force vs Time",'FontSize',16)
xlabel('Time (s)','FontSize',14)
ylabel('Force (N)','FontSize',14)

figure(2)
plot(h,xi,'r','LineWidth',2)
title("Position vs Time",'FontSize',16)
xlabel('Time (s)','FontSize',14)
ylabel('Position (m)','FontSize',14)

% RK4 solver
function x_new = RK4(x, dt) 
    w1=1/6; w2=1/3; w3=1/3; w4=1/6; 
    a21=1/2; a31=0; a32=1/2; a41=0; a42=0; a43=1;

    k1=dt*f(x);
    k2=dt*f(x+a21*k1);
    k3=dt*f(x+a31*k1+a32*k2);
    k4=dt*f(x+a41*k1+a42*k2+a43*k3);

    x_new=x+w1*k1+w2*k2+w3*k3+w4*k4; % Update state 

end
 
function dxdt = f(x) % Dynamics function
 
    global m rho Cd A u F_drag % Global variables defined at top of code
 
    dxdt = zeros(2,1); % Create derivative array 

    v = x(2); % Calculate velocity 
 
    % Quadratic drag
    F_drag = 0.5 * rho * Cd * A * v * abs(v); % Calculate drag force
 
    dxdt(1) = v; % Position derivative equals velocity
    dxdt(2) = (u - F_drag) / m; % Velocity derivative equals acceleration 
                                  (calculate acceleration)
end
 
% Figure setup function
function [e, ball_image, alpha] = figure_setup()
 
global xl % global variables defined at top of code

    e = figure('position',[200 50 560 826]); % Create figure


    axis equal % Sets aspect ratio of axis to be equal in every direction
    ax = gca;                                   % Get current axes handle
    ax.Position = [0 0 1 1];                    % normalized position of axes  
                                                  [left bottom width height] 
    set(gcf,'Toolbar','none','Menu','none');    % Remove toolbar and menu
    set(gca,'visible','off');                   % Remove axis labels
    set(gcf,'color','w');                       % Make figure background 
                                                  white
 
    ylim([-xl xl])                              % Set y axis limits
 
    [ball_image,~,alpha] = imread('circle_black_transparent.png'); % Load 
    ball image 
 
    ball_image = flipud(ball_image); % Flip image so it is oriented correctly
    alpha = flipud(alpha); % Flip transparency 
end
