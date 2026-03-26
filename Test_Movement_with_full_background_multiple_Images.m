clear all
close all
clc
%<<<<<<< HEAD
 %does this work 
 



% Declare global variables 
global m rho Cd A   F_drag F_dragx xl yl g i F_dragx2
 
% Declare physical constants 
m   = 10; % mass (kg)
rho = 1.2; % air density (kg/m^3)
Cd  = 5; % drag coefficient
A   = 10; % cross-sectional area (m^2)
g = 9.81; % gravitational acceleration (m/s^2)
 
%uy = 0; % applied force
%ux = 0;
F_drag = 0;      % drag force
F_dragx = 0;

F_dragx2 = 0;

i = 0;
 
%% ---------------- SERIAL SETUP ----------------
arduinoObj = serialport("COM4",115200);   % <<< CHANGE IF NEEDED
pause(5)
configureTerminator(arduinoObj,"CR/LF");
flush(arduinoObj);


%% ---------------- FIGURE SETUP ----------------
[bgWidth,bgHeight,bg, marshmellow, alpham, scale,Health_Bar,alphahb,Black_HB,...
    alphadhb,hb_width,hb_height,hb_left,hb_top,dhb_width,dhb_height,dhb_left,dhb_top] = figure_setup();
xl = 125;
yl = 75;
%{
figure('position',[400 100 700 700])
ax = gca;
ax.Position = [0 0 1 1];
axis off; hold on
set(gcf,'Toolbar','none','Menu','none');
set(gca,'visible','off');
set(gcf,'color','w');
% Background
bg = imread('Campfire_Smackdown_Backdrop.jpg'); bg = flipud(bg);
image('CData',bg,'XData',[0 1],'YData',[0 1])
set(gca,'XLim',[0 1],'YLim',[0 1]); axis off
    
 
  

    ylim([0 1])
    xlim([0 1])
%} 
    


    [ball,~,alpha] = imread('Ball.png');
    ball = flipud(ball);
    alpha = flipud(alpha);
    
    %{
    [marshmellow,~,alpham] = imread('marshmallow.png');
     marshmellow = flipud(marshmellow);
    alpham = flipud(alpham);
scale = 0.04;

    %}

%[b_img, a_img, ~] = size(ball);
 


[mx, my, ~] = size(marshmellow);

x = [0;0];
y = [0;0];
dt = 0.02;
screenx = 0.25;
screeny = 0.5;

xp2 = [0;0];
u2x = 0;

HB = image(Health_Bar, ...
    'XData',[hb_left, hb_left + hb_width], ...
    'YData',[hb_top - hb_height, hb_top], ...
    'AlphaData', alphahb);

DHB = image(Black_HB, ...
    'XData',[dhb_left, dhb_left + dhb_width], ...
    'YData',[dhb_top - hb_height, dhb_top], ...
    'AlphaData', alphadhb);



H = image(marshmellow,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+10/yl screeny+scale+10/yl], 'AlphaData',alpham);
%Q = image(ball,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+15/yl screeny+scale+15/yl], 'AlphaData',alpha); 
K = image(ball,'XData',[screenx-scale+7/xl screenx+scale+7/xl], 'YData',[screeny-scale+12/yl screeny+scale+12/yl], 'AlphaData',alpha); 
W = image(ball,'XData',[screenx-scale+4/xl screenx+scale+4/xl], 'YData',[screeny-scale+12/yl screeny+scale+12/yl], 'AlphaData',alpha); 

H2 = image(marshmellow,'XData',[screenx-scale+100/(xl*2) screenx+scale+100/(2*xl)], 'YData',[0-scale+10/(yl*2) 0+scale+10/(2*yl)], 'AlphaData',alpham);
% ----- Debug Text -----
%{
forceText = text(0.1,0.9,'Force: 0 N','FontSize',12,'Color','w');
dragText  = text(0.1,0.85,'Drag: 0 N','FontSize',12,'Color','w');
velText   = text(0.1,0.8,'Velocity: 0','FontSize',12,'Color','w');
healthText   = text(0.1,0.75,'Health: 0','FontSize',12,'Color','w');
%}

health = 100;
heart = 0;
T = 100;

%xp2 = screenx + 100/(2*xl);
y2 = 0+10/(2*yl);
%% ---------------- MAIN LOOP ----------------
while ishandle(H)
 
 
    % ----- Read Arduino -----
    if arduinoObj.NumBytesAvailable > 0
 
        data = readline(arduinoObj);
        tmp = split(strtrim(data),',');
 
       
            num = str2double(tmp);

                raw = num(2);
                btn2 = num(4);
                % Deadband
                if (raw - 512) > 300
                        
                  
                    up = 1;
                else 
                    up = 0;
                end  

                if btn2 == 0
                        
                  
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
 
                
                btn1 = num(7);

                h = 1.0+(100.0-health)*0.01;

                P2leftBtn = num(8);
                P2rightBtn = num(9);

                if  P2rightBtn == 1
                if P2leftBtn == 0
                    u2x = -100;
                else 
                    u2x =0;
                end
                end
                
                
                if P2leftBtn == 1
                if P2rightBtn == 0
                    u2x = 100;
                else 
                    u2x =0;
                end 
                end
    end
        
    if raw <10

        c = 0;
    else 
        c = 1;
    end    
 
    
    



    % ----- RK4 Integration -----
    y = RK4(y, dt, h, uy);
    x = RK4x(x, dt, h, ux);
    xp2 = RK4x2(xp2, dt, h, u2x);

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
        x(1) = - xl;
        x(2) = 0;
    end

     if xp2(1) > xl
        xp2(1) = xl;
        xp2(2) = 0;
    elseif xp2(1) < -xl
        xp2(1) = - xl;
        xp2(2) = 0;
    end
   
     if c == 0

        T = 0.2;
        s = 2;
    else 
        T = 0;
        s=1;

    end
 
    x1 = (x(1)+xl)/(2*xl);
    y1 = (y(1)+yl)/(2*yl);

    x2 = (xp2(1)+xl)/(2*xl);

    if x1 > x2

        back = -1;
        
        
    else 
        back = 1;
       
    end    
   
  
    if btn1 == 0
        b = 1;

        if back == 1
                
            if (x1 + 30/(2*xl)) > x2

                if x1  < x2

                    if y1 < y2

                        heart =  (0.025 + (sqrt(ux^2 + uy^2))*0.000001)*crouch;
                    else 
                        heart =0;
                    end
                else 
                    heart =0;

                end
            else 
                heart = 0;

            end 

        end

        if back ==-1

            if (x1 - 30/(2*xl)) < x2

                if x1  > x2

                    if y1 < y2

                        heart =  (0.025 + (sqrt(ux^2 + uy^2))*0.000001)*crouch;
                    else 
                        heart =0;
                    end
                else 
                    heart =0;

                end
            else 
                heart = 0;

            end 

        end

        health = health - heart;
    
    else 
        b = 0;
    end  
    
        
    blackw = 1.000001 - health/100;
    dhb_width  = 0.18*blackw;

    % ----- Update Ball -----
    set(H,'XData',[x1-scale x1+scale],'YData',[y1-scale+10/(2*yl) y1+scale+10/(2*yl)]);
    %set(Q,'XData',[x1-scale x1+scale],'YData',[y1-scale+15/(2*yl)+5*c/(2*yl) y1+scale+15/(2*yl)+5*c/(2*yl)]);
    set(K,'XData',[x1-scale+5*back/(2*xl)+7*b*back/(2*xl) x1+scale+5*back/(xl*2)+7*back*b/(2*xl)], 'YData',[y1-scale+(15+7*up*b)/(2*yl) y1+scale+(15+7*up*b)/(2*yl)], 'AlphaData',alpha); 
    set(W,'XData',[x1-scale*s+4/(2*xl) x1+scale*s+4/(2*xl)], 'YData',[y1-scale*s+12/(2*yl) y1+scale*s+12/(2*yl)], 'AlphaData',T); 

    set(H2,'XData',[x2-scale x2+scale], 'YData',[y2-scale y2+scale], 'AlphaData',alpham); 

    set(DHB, 'XData',[dhb_left dhb_left+dhb_width], ...
    'YData',[hb_top - hb_height hb_top], ...
    'AlphaData', alphadhb);


% ----- Debug Text -----
  %{
    set(forceText,'String',sprintf('Force: %.2f N',abs(uy)+abs(ux)));
    set(dragText,'String',sprintf('Drag: %.2f N',F_drag+F_dragx));
    set(velText,'String',sprintf('Velocity: %.2f',sqrt(((y(2))^2)+((x(2))^2))));
    set(healthText,'String',sprintf('Health: %.2f',health));
  %}    

%{  
    if x1 > x2

       marshmellow = fliplr(marshmellow);
       alpha = fliplr(alpham);

    end    
  %}


    drawnow limitrate

    if health <= 0
        
        break

    end

end
     
clear arduinoObj
 
%% ============================================================
% RK4 FUNCTION
% ============================================================
 
function y_new = RK4(y, dt, h, uy)
    w1=1/6; w2=1/3; w3=1/3; w4=1/6; 
    a21=1/2; a31=0; a32=1/2; a41=0; a42=0; a43=1;

    k1=dt*f(y, h, uy);
    k2=dt*f(y+a21*k1, h, uy);
    k3=dt*f(y+a31*k1+a32*k2, h, uy);
    k4=dt*f(y+a41*k1+a42*k2+a43*k3, h, uy);

    y_new=y+w1*k1+w2*k2+w3*k3+w4*k4;
end



function x_new = RK4x(x, dt, h, ux)
    w1=1/6; w2=1/3; w3=1/3; w4=1/6; 
    a21=1/2; a31=0; a32=1/2; a41=0; a42=0; a43=1;

    k1=dt*fx(x, h, ux);
    k2=dt*fx(x+a21*k1, h, ux);
    k3=dt*fx(x+a31*k1+a32*k2, h, ux);
    k4=dt*fx(x+a41*k1+a42*k2+a43*k3, h, ux);

    x_new=x+w1*k1+w2*k2+w3*k3+w4*k4;
end



function x2_new = RK4x2(xp2, dt, h, u2x)
    w1=1/6; w2=1/3; w3=1/3; w4=1/6; 
    a21=1/2; a31=0; a32=1/2; a41=0; a42=0; a43=1;

    k1=dt*fx2(xp2, h, u2x);
    k2=dt*fx2(xp2+a21*k1, h, u2x);
    k3=dt*fx2(xp2+a31*k1+a32*k2, h, u2x);
    k4=dt*fx2(xp2+a41*k1+a42*k2+a43*k3, h, u2x);

    x2_new=xp2+w1*k1+w2*k2+w3*k3+w4*k4;
end
 
%% ============================================================
% DYNAMICS FUNCTION
% ============================================================
 
function dxdt = f(y, h, uy)
 
    global m rho Cd A  F_drag g 
 
    dxdt = zeros(2,1);
 
    v = y(2);
 
    % Quadratic drag
    F_drag = 0.5 * rho * Cd * A * v * abs(v) * h;
 
    dxdt(1) = v;
    dxdt(2) = (uy - F_drag - g*m) / m;
end
 
function dxdtx = fx(x, h, ux)
 
    global m rho Cd A F_dragx
 
    dxdtx = zeros(2,1);
 
    vx = x(2);
 
    % Quadratic drag
    F_dragx = 0.5 * rho * Cd * A * vx * abs(vx) * h;


    dxdtx(1) = vx;
    dxdtx(2) = (ux - F_dragx) / m; % + mom
end
function dxdtx2 = fx2(xp2, h, u2x)
 
    global m rho Cd A F_dragx2
 
    dxdtx2 = zeros(2,1);
 
    vx2 = xp2(2);
 
    % Quadratic drag
    F_dragx2 = 0.5 * rho * Cd * A * vx2 * abs(vx2) * h;


    dxdtx2(1) = vx2;
    dxdtx2(2) = (u2x - F_dragx2) / m; % + mom
end
%% ============================================================
% FIGURE SETUP FUNCTION
% ============================================================
 
function [bgWidth,bgHeight,bg, marshmellow, alpham, scale,Health_Bar,alphahb,Black_HB,alphadhb,...
    hb_width,hb_height,hb_left,hb_top,dhb_width,dhb_height,dhb_left,dhb_top] = figure_setup()


 
    % Create fullscreen figure
figure('WindowState','maximized', 'Toolbar','none', 'MenuBar','none', 'Color','k');
    
    % Background
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

image('CData',bg, 'XData',[0 bgWidth], 'YData',[0 bgHeight])

axis image
xlim([0 bgWidth])
ylim([0 bgHeight])
   
    % Load Player Images
[marshmellow,~,alpham] = imread('marshmallow.png');
marshmellow = flipud(marshmellow);
alpham = flipud(alpham);

% Object scale (normalized)
scale = 90/imgW;
 
  %  [ball_image,~,alpha] = imread('circle_black_transparent.png');
    
   
  %  ball_image = flipud(ball_image);
  %  alpha = flipud(alpha);
    
  [Health_Bar,~,alphahb] = imread('Health_Bar.png');
    Health_Bar = flipud(Health_Bar);
    Health_Bar = fliplr(Health_Bar);

    alphahb = flipud(alphahb);

    [Black_HB,~,alphadhb] = imread('Black_HB.png');
    alphadhb = flipud(alphadhb);
    
    hb_width  = 0.18;   
    hb_height = 0.06;   
    hb_left   = 0.01;   
    hb_top    = 0.97;  
  
    blackw = 0.000001;
    dhb_width  = 0.18*blackw;   
    dhb_height = 0.06;   
    dhb_left   = 0.01;   
    dhb_top    = 0.97;  
end

