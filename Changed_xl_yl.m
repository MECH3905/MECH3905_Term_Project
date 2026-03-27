

clear all
close all
clc

% Declare global variables 
global m rho Cd A   F_drag F_dragx g F_dragx2 F_drag2 xl yl eq
 
% Declare physical constants 
m   = 10;        % mass (kg)
rho = 1.2;       % air density (kg/m^3)
Cd  = 5;         % drag coefficient
A   = 10;        % cross-sectional area (m^2)
g = 9.81;        % gravitational acceleration (m/s^2)
F_drag = 0;      % player 1 y-component initial drag force
F_dragx = 0;     % player 1 x-component initial drag force
F_dragx2 = 0;    % player 2 x-component initial drag force
F_drag2 = 0;     % player 2 y-component initial drag force

eq = 0.000001;      % the Equalizer, makes everything very small to try and fit into 0-1
 
%% ---------------- SERIAL SETUP ----------------
arduinoObj = serialport("COM4",115200);   % <<< CHANGE IF NEEDED
pause(5)
configureTerminator(arduinoObj,"CR/LF");
flush(arduinoObj);


%% ---------------- FIGURE SETUP ----------------
[bgWidth,bgHeight,bg, m_run, alpha_run, m_jump, alpha_jump, ...
 m_crouch, alpha_crouch, m_jab, alpha_jab, ...
 m_upward_jab, alpha_upward_jab, ...
 scale,Health_Bar,alphahb,Black_HB,alphadhb,...
 hb_width,hb_height,hb_left,hb_top,dhb_width,dhb_height,dhb_left,dhb_top] = figure_setup();

xl = bgWidth;    % absolute x limit
yl = bgHeight;   % absolute y limit

%xl = 100;
%yl = 100;

x = [0;0];       % initializing player 1 x position and velocity
y = [0;0];       % initializing player 1 x position and velocity

xp2 = [0;0];     % initializing player 2 x position and velocity

dt = 0.02;       % time step

screenx = 0.25;  % initial x position 
screeny = 0.1;  % initial y position 


%% Initializing Images
HB = image(Health_Bar, 'XData',[hb_left, hb_left + hb_width], 'YData',[hb_top - hb_height, hb_top], 'AlphaData', alphahb);
DHB = image(Black_HB, 'XData',[dhb_left, dhb_left + dhb_width], 'YData',[dhb_top - hb_height, dhb_top], 'AlphaData', alphadhb);

run = image(m_run,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_run);

crouch = image(m_crouch,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_crouch);

jab = image(m_jab,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_jab);

jump = image(m_jump,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_jump);

upward_jab = image(m_upward_jab,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_upward_jab);

%% Initial Values

health = 100;
heart = 0;
T = 100;

y2 = 0.1;

jab_timer = 0;

%% ---------------- MAIN LOOP ----------------
while ishandle(run)
 
 
    % ----- Read Arduino -----
    if arduinoObj.NumBytesAvailable > 0
 
        data = readline(arduinoObj);
        tmp = split(strtrim(data),',');
 
       
           num = str2double(tmp);

           if numel(num) < 9 || any(isnan(num(1:9)))
              continue
           end

                raw = num(2);
                btn2 = num(4);
                % Deadband
                if (raw - 512) > 300
                        
                  
                    up = 1;
                else 
                    up = 0;
                end  

                if btn2 == 0
                        
                  
                    uy = 100;
                    
                else
                    uy = 0;  % Reset applied force if within deadband
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


              if P2rightBtn == 1 && P2leftBtn == 0

                  u2x = -200;

              elseif P2leftBtn == 1 && P2rightBtn == 0

                  u2x = 200;

              else

                  u2x = 0;

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
   
    if y(1) > 1

        y(1) = 1;
        y(2) = 0;
    elseif y(1) < 0
        y(1) = 0;
        y(2) = 0;
    end
   
   
    if x(1) > xl
        x(1) = xl;
        x(2) = 0;
    elseif x(1) < 0
        x(1) = 0;
        x(2) = 0;
    end

     if xp2(1) > xl
        xp2(1) = xl;
        xp2(2) = 0;
    elseif xp2(1) < 0
        xp2(1) = 0;
        xp2(2) = 0;
    end
   
     if c == 0

        T = 0.2;
        s = 2;
    else 
        T = 0;
        s=1;

    end
   
   
    x1 = x(1);
    y1 = y(1);

    x2 =xp2(1);
   

    if x1 > x2

        back = -1;
        
        
    else 
        back = 1;
       
    end    
   
  
    if btn1 == 0
        b = 1;

        if back == 1
                
            if (x1 + 0.15) > x2

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

        jab_timer = 5;   % lasts 5 frames

             if (x1 - 30.15) < x2

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

    %% ----- Update Ball -----
    set(run,'XData',[x1-scale x1+scale],'YData',[y1-scale+0.1 y1+scale+0.1]);

    set(DHB, 'XData',[dhb_left dhb_left+dhb_width], 'YData',[hb_top - hb_height hb_top], 'AlphaData', alphadhb);


    if jab_timer > 0
    set(run,'CData', m_jab, 'AlphaData', alpha_jab);
    jab_timer = jab_timer - 1;
    else
    set(run,'CData', m_run, 'AlphaData', alpha_run);
    end
    drawnow limitrate

    if health <= 0
        
        
        close all % close figure window once guy is super toasted
         
        
        
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
 
    global m rho Cd A  F_drag g eq
 
    dxdt = zeros(2,1);
 
    v = y(2);
 
    % Quadratic drag
    F_drag = 0.5 * rho * Cd * A * v * abs(v) * h;
 
    dxdt(1) = v;
    dxdt(2) = ((uy - F_drag - g*m)*eq) / m; 
end
 
function dxdtx = fx(x, h, ux)
 
    global m rho Cd A F_dragx eq
 
    dxdtx = zeros(2,1);
 
    vx = x(2)*ux/(abs(ux)+eq);
 
    % Quadratic drag
    F_dragx = 0.5 * rho * Cd * A * vx * abs(vx) * h;


    dxdtx(1) = vx;
    dxdtx(2) = ((ux - F_dragx)*eq) / m; % + mom
end
function dxdtx2 = fx2(xp2, h, u2x)
 
    global m rho Cd A F_dragx2 eq
 
    dxdtx2 = zeros(2,1);
 
    vx2 = xp2(2)*u2x/(abs(u2x)+eq);
 
    % Quadratic drag
    F_dragx2 = 0.5 * rho * Cd * A * vx2 * abs(vx2) * h;


    dxdtx2(1) = vx2;
    dxdtx2(2) = ((u2x - F_dragx2)*eq) / m; % + mom
end
%% ============================================================
% FIGURE SETUP FUNCTION
% ============================================================
function [bgWidth,bgHeight,bg, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab, ...
          scale,Health_Bar,alphahb,Black_HB,alphadhb,...
          hb_width,hb_height,hb_left,hb_top,dhb_width,dhb_height,dhb_left,dhb_top] = figure_setup()

 
    % Create fullscreen figure
figure('WindowState','maximized', 'Toolbar','none', 'MenuBar','none', 'Color','k');
    
    % Background
bg = imread('Campfire_Smackdown_Backdrop.jpg'); % read in background img
bg = flipud(bg); % flip img
[imgH,imgW,~] = size(bg);  % read size
imgRatio = imgW/imgH; % get img ratio
 
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
[m_run,~,alpha_run] = imread('m_run.png');
m_run = flipud(m_run);
alpha_run = flipud(alpha_run);

[m_jump,~,alpha_jump] = imread('m_jump.png');
m_jump = flipud(m_jump);
alpha_jump = flipud(alpha_jump);

[m_crouch,~,alpha_crouch] = imread('m_crouch.png');
m_crouch = flipud(m_crouch);
alpha_crouch = flipud(alpha_crouch);

[m_jab,~,alpha_jab] = imread('m_jab.png');
m_jab = flipud(m_jab);
alpha_jab = flipud(alpha_jab);

[m_upward_jab,~,alpha_upward_jab] = imread('m_upward_jab.png');
m_upward_jab = flipud(m_upward_jab);
alpha_upward_jab = flipud(alpha_upward_jab);

% Object scale (normalized)
scale = 90/imgW;
 
    
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

