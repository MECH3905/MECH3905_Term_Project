

clear all
close all
clc

% Declare global variables 
global m rho Cd A   F_drag F_dragx g F_dragx2 F_drag2 xl yl eq hitbox
 
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
eq = 0.1;
hitbox = 0.15;   % player hitbox parameter pi*r^2
 
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
 hb_width,hb_height,hb_left,hb_top,dhb_width,dhb_height,dhb_left,dhb_top, ...
 m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip,m_crouchflip,...
 alpha_crouchflip,m_jabflip,alpha_jabflip,m_upward_jabflip,alpha_upward_jabflip] = figure_setup();

xl = bgWidth*100;    % absolute x scaling
yl = bgHeight*100;   % absolute y scaling

x = [0;0];       % initializing player 1 x position and velocity
y = [0;0];       % initializing player 1 x position and velocity

xp2 = [0;0];     % initializing player 2 x position and velocity

player1image = {0,0};
player2image = {0,0};

dt = 0.02;       % time step

screenx = 0.25;  % initial x position 
screeny = 0.1;  % initial y position 


%% Initializing Images
HB = image(Health_Bar, 'XData',[hb_left, hb_left + hb_width], 'YData',[hb_top - hb_height, hb_top], 'AlphaData', alphahb);
DHB = image(Black_HB, 'XData',[dhb_left, dhb_left + dhb_width], 'YData',[dhb_top - hb_height, dhb_top], 'AlphaData', alphadhb);

run = image(m_run,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_run);

p2run = image(m_runflip,'XData',[screenx+0.5-scale screenx+0.5+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_runflip);

%% Initial Values

health = 100;
heart = 0;

p1jabbtn = 1;

y2 = screeny; % delete this when player 2 can jump
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
                rawx = num(3);
                p1jumpbtn = num(4);
                p1dashbtn = num(5);
                p1crouchbtn = num(6);
                p1jabbtn = num(7);


                P2leftBtn = num(8);
                P2rightBtn = num(9);

                % Deadband
                if (raw - 512) > 300
                        
                  
                    up = 0;
                
                else 
                    up = 1;
                end  

                if p1jumpbtn == 0
                        
                    uy = 300;

                elseif p1dashbtn == 0

                    uy = 300*(raw-512)/512;
                    
                else
                    uy = 0;  % Reset applied force if within deadband
                end

                if p1crouchbtn == 0

                    crouch = 0;
                    
                else 
                    crouch = 1;
                end 
                
 
                % Deadband
                if abs(rawx - 512) < 10
                    ux = 0;

                elseif p1dashbtn == 0

                    ux = 3000*(rawx-512)/512;
                    
                else 
                    ux = (rawx - 512);
                    
                end 
                
 
                if ux == 0 %&& p1jabbtn ~= 0
                    x(2) = 0;
                
                end

   
              if P2rightBtn == 1 && P2leftBtn == 0

                  u2x = -200;

              elseif P2leftBtn == 1 && P2rightBtn == 0

                  u2x = 200;

              else

                  u2x = 0;

              end

              h = 1.0+(100.0-health)*0.01;
    end
        
   

    % ----- RK4 Integration -----
    y = RK4(y, dt, h, uy);
    x = RK4x(x, dt, h, ux);
    xp2 = RK4x2(xp2, dt, h, u2x);

    % ----- Absolute Boundary Limits -----
   
    if y(1) > yl

        y(1) = yl;
        y(2) = 0;
    elseif y(1) < 0
        y(1) = 0;
        y(2) = 0;
    end
   
    if x(1) > xl
        x(1) = xl;
        x(2) = 0;
    elseif x(1) < -xl
        x(1) = -xl;
        x(2) = 0;
    end

     if xp2(1) > xl
        xp2(1) = xl;
        xp2(2) = 0;
    elseif xp2(1) < -xl
        xp2(1) = -xl;
        xp2(2) = 0;
     end
   
     %% y = screeeny-1 && x = 0-1.778

    x1 = ((x(1)+xl)/(2*xl))*bgWidth;
    y1 = (y(1)/yl)*bgHeight;

    if y1 > bgHeight

        y1 = bgHeight;
    elseif y1 < screeny
        y1 = screeny;
    end

    x2 =((xp2(1)+xl)/(2*xl))*bgWidth;
   
    %% replacing plyer images  
    
    player1image = changeimage(ux, up, p1crouchbtn, p1jabbtn, p1jumpbtn, m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab);
    set(run,'CData', player1image{1}, 'AlphaData', player1image{2});

    player2image = changeimage(x2, up, p1crouchbtn, p1jabbtn, p1jumpbtn, m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab);
    set(p2run,'CData', player2image{1}, 'AlphaData', player2image{2});
  
    %% Player hit and damage function
    if p1jabbtn == 0 % make punch crouch and jump into functions add dash
        x(2) = 0;
        hit = jabfunction(x1, y1, x2, y2, up);
        
        heart =  (0.0025 + (sqrt(ux^2 + uy^2))*0.00000001)*crouch;
        health = health - heart*hit;

    end  
    
        
    blackw = 1.000001 - health/100;
    dhb_width  = 0.18*blackw;

    %% ----- Update Ball -----
    set(run,'XData',[x1-scale x1+scale],'YData',[y1-scale+0.1 y1+scale+0.1]);

    set(DHB, 'XData',[dhb_left dhb_left+dhb_width], 'YData',[hb_top - hb_height hb_top], 'AlphaData', alphadhb);

    set(p2run,'XData',[x2-scale x2+scale],'YData',[y2-scale+0.1 y2+scale+0.1]); 
    
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
 
    global m rho Cd A  F_drag g 
 
    dxdt = zeros(2,1);
 
    v = y(2);
 
    % Quadratic drag
    F_drag = 0.5 * rho * Cd * A * v * abs(v) * h;
 
    dxdt(1) = v;
    dxdt(2) = (uy - F_drag - g*m) / m; 
end
 
function dxdtx = fx(x, h, ux)
 
    global m rho Cd A F_dragx eq
 
    dxdtx = zeros(2,1);
 
    
    vx = x(2); 
    
    % Quadratic drag
    F_dragx = 0.5 * rho * Cd * A * vx * abs(vx) * h;


    dxdtx(1) = vx;
    dxdtx(2) = (ux*eq - F_dragx) / m;
end
function dxdtx2 = fx2(xp2, h, u2x)
 
    global m rho Cd A F_dragx2 eq
 
    dxdtx2 = zeros(2,1);
 
    vx2 = xp2(2);
 
    % Quadratic drag
    F_dragx2 = 0.5 * rho * Cd * A * vx2 * abs(vx2) * h;


    dxdtx2(1) = vx2;
    dxdtx2(2) = (u2x*eq - F_dragx2) / m;
end
%% ============================================================
% FIGURE SETUP FUNCTION
% ============================================================
function [bgWidth,bgHeight,bg, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab, ...
          scale,Health_Bar,alphahb,Black_HB,alphadhb,...
          hb_width,hb_height,hb_left,hb_top,dhb_width,dhb_height,dhb_left,dhb_top,...
          m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip] = figure_setup()

 

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

[m_runflip,~,alpha_runflip] = imread('m_run.png');
m_runflip = rot90(m_runflip,2);
alpha_runflip = rot90(alpha_runflip,2);

[m_jump,~,alpha_jump] = imread('m_jump.png');
m_jump = flipud(m_jump);
alpha_jump = flipud(alpha_jump);

[m_jumpflip,~,alpha_jumpflip] = imread('m_jump.png');
m_jumpflip = rot90(m_jumpflip,2);
alpha_jumpflip = rot90(alpha_jumpflip,2);

[m_crouch,~,alpha_crouch] = imread('m_crouch.png');
m_crouch = flipud(m_crouch);
alpha_crouch = flipud(alpha_crouch);

[m_crouchflip,~,alpha_crouchflip] = imread('m_crouch.png');
m_crouchflip = rot90(m_crouchflip,2);
alpha_crouchflip = rot90(alpha_crouchflip,2);

[m_jab,~,alpha_jab] = imread('m_jab.png');
m_jab = flipud(m_jab);
alpha_jab = flipud(alpha_jab);

[m_jabflip,~,alpha_jabflip] = imread('m_jab.png');
m_jabflip = rot90(m_jabflip,2);
alpha_jabflip = rot90(alpha_jabflip,2);

[m_upward_jab,~,alpha_upward_jab] = imread('m_upward_jab.png');
m_upward_jab = flipud(m_upward_jab);
alpha_upward_jab = flipud(alpha_upward_jab);

[m_upward_jabflip,~,alpha_upward_jabflip] = imread('m_upward_jab.png');
m_upward_jabflip = rot90(m_upward_jabflip,2);
alpha_upward_jabflip = rot90(alpha_upward_jabflip,2);

% Object scale (normalized)
scale = 200/imgW;
 
    
  [Health_Bar,~,alphahb] = imread('Health_Bar.png');
    Health_Bar = rot90(Health_Bar,2);
    

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


function jab = jabfunction(x1, y1, x2, y2, up)
    
    global hitbox
    

    if x1 < x2 && (x1 + hitbox) > x2 && y1 < y2+hitbox/2 && y1 > y2-hitbox+hitbox*up/2      %if player 1 is to the left of player 2

             hit = 1;                                             % 1 means he hit

    elseif x1 > x2 && (x1 - hitbox) < x2 && y1 <y2+hitbox/2 && y1 > y2-hitbox+hitbox*up/2   %if player 1 is to the right of player 2

             hit =  1;
    else 

             hit = 0;

    end

    jab = hit;

end

function image = changeimage(x1, up, p1crouchbtn, p1jabbtn, p1jumpbtn, m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab)

    image{1} = m_run;
    image{2}= alpha_run;

 if x1 < 0
    image{1} = m_runflip;
    image{2}= alpha_runflip;   

    if p1crouchbtn == 0 
        image{1} = m_crouchflip;
        image{2}= alpha_crouchflip;
        
    end

    if p1jabbtn == 0 
        if up == 0
            image{1} = m_upward_jabflip;
            image{2}= alpha_upward_jabflip;
            
        else
            image{1} = m_jabflip;
            image{2}= alpha_jabflip;
            
        end
    end

    if p1jumpbtn == 0
        image{1} = m_jumpflip;
        image{2}= alpha_jumpflip;
        
    end
end
    
if x1 >= 0 
       image{1} = m_run;
       image{2}= alpha_run;

    if p1crouchbtn == 0 
        image{1} = m_crouch;
        image{2}= alpha_crouch;
        
    end

    if p1jabbtn == 0 
        if up == 0
            image{1} = m_upward_jab;
            image{2}= alpha_upward_jab;
            
        else
            image{1} = m_jab;
            image{2}= alpha_jab;
            
        end
    end   
    
    if p1jumpbtn == 0
        image{1} = m_jump;
        image{2}= alpha_jump;
    end
    
end

end