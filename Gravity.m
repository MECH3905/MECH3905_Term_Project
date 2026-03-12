  %% ============================================================
%  MECH3905 LAB 5
%  Force Controlled Mass with Quadratic Drag
%  RK4 Integration
%  Live Force + Drag + Velocity Display
% ============================================================
 
clear
close all
clc
 
%% ---------------- GLOBAL VARIABLES ----------------
global m rho Cd A uy ux  F_drag F_dragx xl yl g
 
% ----- Physical Constants -----
m   = 10;        % mass (kg)
rho = 1.2;       % air density (kg/m^3)
Cd  = 10;       % drag coefficient
A   = 10;      % cross-sectional area (m^2)
g = 9.81; %gravitational acceleration (m/s^2)
 
uy = 0;           % applied force
ux = 0;
F_drag = 0;      % drag force
F_dragx = 0;
xl = 150;
yl = 100;

 
%% ---------------- SERIAL SETUP ----------------
arduinoObj = serialport("COM4",115200);   % <<< CHANGE IF NEEDED
pause(2)
configureTerminator(arduinoObj,"CR/LF");
flush(arduinoObj);
 
%% ---------------- FIGURE SETUP ----------------
[e, ball, alpha] = figure_setup();
scale = 0.07;

[b_img, a_img, ~] = size(ball);
 
% State vector: x = [position; velocity]
x = [0;0];
y = [0;0];
dt = 0.02;
 
H = image(ball,'XData',[x(1)-scale*a_img/2 x(1)+scale*a_img/2], 'YData',[y(1)-scale*b_img/2+10 y(1)+scale*b_img/2+10], 'AlphaData',alpha);
Q = image(ball,'XData',[x(1)-scale*a_img/2 x(1)+scale*a_img/2], 'YData',[y(1)-scale*b_img/2+15 y(1)+scale*b_img/2+15], 'AlphaData',alpha); 
K = image(ball,'XData',[x(1)-scale*a_img/2+7 x(1)+scale*a_img/2+7], 'YData',[y(1)-scale*b_img/2+12 y(1)+scale*b_img/2+12], 'AlphaData',alpha); 
W = image(ball,'XData',[x(1)-scale*a_img/2+5 x(1)+scale*a_img/2+5], 'YData',[y(1)-scale*b_img/2+12 y(1)+scale*b_img/2+12], 'AlphaData',alpha); 
% ----- Debug Text -----
forceText = text(-80,80,'Force: 0 N','FontSize',12,'Color','k');
dragText  = text(-80,70,'Drag: 0 N','FontSize',12,'Color','k');
velText   = text(-80,60,'Velocity: 0','FontSize',12,'Color','k');
healthText   = text(-80,50,'Health: 0','FontSize',12,'Color','k');


health = 100;
T = 100;
 
%% ---------------- MAIN LOOP ----------------
while ishandle(H)
 
 
    % ----- Read Arduino -----
    if arduinoObj.NumBytesAvailable > 0
 
        data = readline(arduinoObj);
        tmp = split(strtrim(data),',');
 
       
            num = str2double(tmp);

                raw = num(2);
 
                % Deadband
                if (raw - 512) > 300
                        
                  
                    uy = 1000;
                    
                   j=j+1;

                   if j>30
                      uy = -100;
                      
                   end  

                else
                    uy = 0;  % Reset applied force if within deadband
                    j =0;
                end

                if raw < 10

                    crouch = 0;
                else 
                    crouch = 1;
                end    
 
             
              
                    
                rawx = num(3);
 
                % Deadband
                if abs(rawx - 512) < 10
                    ux = 0;
                else
                    ux = (rawx - 512);
                end
 
                
                btn1 = num(4);

                if btn1 == 0

                    health = health - (0.025 + (abs(ux) + abs(uy))*0.0001)*crouch;
                end

                h = 1.0+(100.0-health)*0.05;
    end
        
    if raw <10

        c = 0;
    else 
        c = 1;
    end    
 
    if btn1 == 1

        b = 0;
    else 
        b = 1;
    end    

    % ----- RK4 Integration -----
    y = RK4(y, dt, h);
    x = RK4x(x, dt, h);

    % ----- Boundary Limits -----
    if y(1) > 0

        y(1) = 0;
        y(2) = 0;
    elseif y(1) < -yl
        y(1) = -yl;
        y(2) = 0;
    end
   
    if x(1) > xl
        x(1) = xl;
        x(2) = 0;
    elseif x(1) < -xl
        x(1) = -xl;
        x(2) = 0;
    end

     if c == 0

        T = 0.2;
        s = 2;
    else 
        T = 0;
        s=1;

    end
 
    % ----- Update Ball -----
    set(H,'XData',[x(1)-scale*a_img/2 x(1)+scale*a_img/2],'YData',[y(1)-scale*b_img/2+10 y(1)+scale*b_img/2+10]);
    set(Q,'XData',[x(1)-scale*a_img/2 x(1)+scale*a_img/2],'YData',[y(1)-scale*b_img/2+15+5*c y(1)+scale*b_img/2+15+5*c]);
    set(K,'XData',[x(1)-scale*a_img/2+7+5*b x(1)+scale*a_img/2+7+5*b], 'YData',[y(1)-scale*b_img/2+12 y(1)+scale*b_img/2+12], 'AlphaData',alpha); 
    set(W,'XData',[x(1)-scale*a_img*s/2+5 x(1)+scale*a_img*s/2+5], 'YData',[y(1)-scale*b_img*s/2+12 y(1)+scale*b_img*s/2+12], 'AlphaData',T); 
% ----- Debug Text -----
    % ----- Update Debug Text -----
    set(forceText,'String',sprintf('Force: %.2f N',abs(uy)+abs(ux)));
    set(dragText,'String',sprintf('Drag: %.2f N',F_drag+F_dragx));
    set(velText,'String',sprintf('Velocity: %.2f',sqrt(((y(2))^2)+((x(2))^2))));
    set(healthText,'String',sprintf('Health: %.2f',health));

   


    drawnow limitrate

    if health <= 0
        
        break

    end
    
    
    
end
 
clear arduinoObj
 
%% ============================================================
% RK4 FUNCTION
% ============================================================
 
function y_new = RK4(y, dt, h)
    w1=1/6; w2=1/3; w3=1/3; w4=1/6; 
    a21=1/2; a31=0; a32=1/2; a41=0; a42=0; a43=1;

    k1=dt*f(y, h);
    k2=dt*f(y+a21*k1, h);
    k3=dt*f(y+a31*k1+a32*k2, h);
    k4=dt*f(y+a41*k1+a42*k2+a43*k3, h);

    y_new=y+w1*k1+w2*k2+w3*k3+w4*k4;
end



function x_new = RK4x(x, dt, h)
    w1=1/6; w2=1/3; w3=1/3; w4=1/6; 
    a21=1/2; a31=0; a32=1/2; a41=0; a42=0; a43=1;

    k1=dt*fx(x, h);
    k2=dt*fx(x+a21*k1, h);
    k3=dt*fx(x+a31*k1+a32*k2, h);
    k4=dt*fx(x+a41*k1+a42*k2+a43*k3, h);

    x_new=x+w1*k1+w2*k2+w3*k3+w4*k4;
end
 
%% ============================================================
% DYNAMICS FUNCTION
% ============================================================
 
function dxdt = f(y, h)
 
    global m rho Cd A uy F_drag g
 
    dxdt = zeros(2,1);
 
    v = y(2);
 
    % Quadratic drag
    F_drag = 0.5 * rho * Cd * A * v * abs(v) * h;
 
    dxdt(1) = v;
    dxdt(2) = (uy - F_drag - g*m) / m;
end
 
function dxdtx = fx(x, h)
 
    global m rho Cd A ux F_dragx
 
    dxdtx = zeros(2,1);
 
    vx = x(2);
 
    % Quadratic drag
    F_dragx = 0.5 * rho * Cd * A * vx * abs(vx) * h;
 
    dxdtx(1) = vx;
    dxdtx(2) = (ux - F_dragx) / m;
end
%% ============================================================
% FIGURE SETUP FUNCTION
% ============================================================
 
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