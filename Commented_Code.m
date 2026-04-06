% MECH3905 Term Project
% April 6, 2026
% Group 6 Members:
% Eric Adamson (B00962642)
% Francesco Borrelli (B00964461)
% Quinn Fox (B01020683)
% Purpose: Two player fighter game using arduino uno joystick and button inputs

% IMAGE REFERENCE
% Author: Google Gemini Nano Bannana 2
% Website URL: https://gemini.google.com/app?android-min-version=301356232&ios-min-version=322.0&is_sa=1&hl=en-CA&utm_campaign=microsite_gemini_image_generation_page&icid=microsite_gemini_image_generation_page&utm_source=gemini&utm_medium=web&_gl=1*xe3rwt*_gcl_au*ODk5Njc3MzQuMTc3Mjc1OTQxMg..*_ga*NDc0OTA2Mjk2LjE3NzI3NTk0MTA.*_ga_WC57KJ50ZZ*czE3NzU0ODI3NDAkbzI1JGcwJHQxNzc1NDgyNzQwJGo2MCRsMCRoMA..
% Dates: March 4, 2026 - April 2, 2026

% CODE REFERENCE
% Author: Mae Seto, BrightSpace lecture content 
% Website URL: https://dal.brightspace.com/d2l/le/content/414169/Home
% Dates: January 7, 2026 - April 6, 2026

clear all % Clear all variables from workspace
close all % Close all open figures
clc       % Clear command window

% GLOBAL VARIABLES
% Declare physical constants
m   = 10;      % Mass of player (kg)
rho = 1.2;     % Density of air (kg/m^3)
Cd  = 5;       % Drag coefficient (unitless)
A   = 10;      % Cross-sectional area of player (m^2)
g = 9.81;      % Gravitational acceleration (m/s^2)
F_drag = 0;    % Initialize player 1 vertical drag force to zero
F_dragx = 0;   % Initialize player 1 horizontal drag force to zero
F_dragx2 = 0;  % Initialize player 2 horizontal drag force to zero
F_drag2 = 0;   % Initialize player 2 vertical drag force to zero
eq = 1;        % Equilibrium flag
hitbox = 0.15; % Radius parameter for circular hit detection
 
% SERIAL SETUP
arduinoObj1 = serialport("COM3",2000000); % Start serial communication to Player 1's Arduino on COM3 at 2000000 baud
arduinoObj2 = serialport("COM5",2000000); % Start serial communication to Player 2's Arduino on COM5 at 2000000 baud

pause(2) % Wait 2 seconds for setup

configureTerminator(arduinoObj1,"CR/LF"); % Tell MATLAB when a line of data from Player 1 ends
configureTerminator(arduinoObj2,"CR/LF"); % Tell MATLAB when a line of data from Player 2 ends

flush(arduinoObj1);   % clear any buffered data in Player 1's serial input buffer
flush(arduinoObj2);   % clear any buffered data in Player 2's serial input buffer

% FIGURE SETUP
% Call figure_setup() to create the game window and load all images
% Returns background dimensions, player images and alpha data,
% health bar images and layout coordinates, and win screen images
[bgWidth, bgHeight, bg, m_run, alpha_run, m_jump, alpha_jump, ...
 m_crouch, alpha_crouch, m_jab, alpha_jab, ...
 m_upward_jab, alpha_upward_jab, ...
 scale, P1_HB, alphaP1, P2_HB, alphaP2, Black_HB, alphadhb,...
 hb_width,hb_height, hb_left, hb_top, dhb_width, dhb_height, dhb_left, dhb_top,...
 m_runflip, alpha_runflip, m_jumpflip, alpha_jumpflip, m_crouchflip, alpha_crouchflip,...
 m_jabflip, alpha_jabflip, m_upward_jabflip, alpha_upward_jabflip, ...
 Roasted_Run, alpha_Roasted_Run, Roasted_Runflip, alpha_Roasted_Runflip, p2_left,dhb_right, p2_dhb_left, ...
 Roasted_Jump, alpha_Roasted_Jump, Roasted_Jumpflip, alpha_Roasted_Jumpflip, Roasted_Crouch, alpha_Roasted_Crouch,...
 Roasted_Crouchflip, alpha_Roasted_Crouchflip, Roasted_Jab,alpha_Roasted_Jab, Roasted_Jabflip, alpha_Roasted_Jabflip,...
 Roasted_Upwards_Jab, alpha_Roasted_Upwards_Jab, Roasted_Upwards_Jabflip, alpha_Roasted_Upwards_Jabflip, ...
 Unroasted_Dash, alpha_upward_Unroasted_Dash, Unroasted_Dashflip, alpha_Unroasted_Dashflip, ...
 Roasted_Dash, alpha_Roasted_Dash, Roasted_Dashflip, alpha_Roasted_Dashflip, p1_win, p2_win] = figure_setup();

xl = bgWidth*100;  % Compute absolute x-axis boundary 
yl = bgHeight*100; % Compute absolute y-axis boundary 

x1start = [0;0]; % Initialize Player 1 x position (m) and x velocity (m/s) as column vector
y1start = [0;0]; % Initialize Player 1 y position (m) and y velocity (m/s) as column vector
x2start = [0;0]; % Initialize Player 2 x position (m) and x velocity (m/s) as column vector
y2start = [0;0]; % Initialize Player 2 y position (m) and y velocity (m/s) as column vector

player1image = {0,0}; % Placeholder array for Player 1's current image and alpha data
player2image = {0,0}; % Placeholder array for Player 2's current image and alpha data

dt = 0.02; % Time step (seconds)

screenx = 0.25; % Initial normalized x position for player images
screeny = 0.1;  % Initial normalized y position for player images

% INITIALIZE IMAGES
% Set Player 1's health bar image at its fixed position on the screen
HB1 = image(P1_HB, 'XData',[hb_left, hb_left + hb_width], 'YData',[hb_top - hb_height+0.0027, hb_top], 'AlphaData', alphaP1);

% Set Player 2's health bar image at its fixed mirrored position on the screen
HB2 = image(P2_HB, 'XData',[p2_left, p2_left + hb_width], 'YData',[hb_top - hb_height, hb_top], 'AlphaData', alphaP2);

% Create black rectangle for damage overlay bar for Player 1
DHB1 = image(Black_HB, 'XData',[dhb_left, dhb_left + dhb_width], 'YData',[dhb_top - dhb_height, dhb_top], 'AlphaData', alphadhb);
% Create black rectangle for damage overlay bar for Player 2 
DHB2 = image(Black_HB, 'XData',[bgWidth-0.48 bgWidth-0.03], 'YData',[0.97-0.06 0.97], 'AlphaData', alphadhb);

% Place Player 1's roasted image at starting screen position
burntrun = image(Roasted_Run,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_Roasted_Run);  
% Place Player 1's unroasted image at starting screen position (on top of roasted image)
run = image(m_run,'XData',[screenx-scale screenx+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_run);

% Place Player 2's burnt sprite at starting position (offset 0.5 to the right)
burntrun2 = image(Roasted_Runflip,'XData',[screenx+0.5-scale screenx+0.5+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_Roasted_Runflip);
% Place Player 2's normal sprite at starting position
p2run = image(m_runflip,'XData',[screenx+0.5-scale screenx+0.5+scale], 'YData',[screeny-scale+0.1 screeny+scale+0.1], 'AlphaData',alpha_runflip);

health1 = 100; % Initialize Player 1 full health to 100
health2 = 100; % Initialize Player 2 full health to 100

% INITIALIZE VARIABLE VALUES
heart = 0;    % Accumulated damage for Player 2 
burnt = 1;    % Player 1 roasted image transparency multiplier; 1 = fully healthy 
burnt2 = 1;   % Player 2 roasted image transparency multiplier; 1 = fully healthy 
crouch = 1;   % Player 1 crouch state initialized to 1
p1jabbtn = 1; % Initialize Player 1 jab button state to 1 

ux = 0;   % Initialize Player 1 horizontal force input to zero
u2x = 0;  % Initialize Player 2 horizontal force input to zero


% GAME SOUNDS
[y0, leep] = audioread('Guile_theme.mp3'); % Load background music 
y0 = 0.2*y0;                               % Scale volume down to 20% 
backgroundsound = audioplayer(y0, leep);   % Create audio player object for background music
play(backgroundsound);                     % Start playing background music 

% Jab impact sound for Player 2 hitting Player 1 
[y, Fs] = audioread('jab_oof.mp4'); % Read audio file for hit sound effect
Fs = 1.75*Fs;                       % Increase by 1.75x to raise pitch
Jab_sound = audioplayer(y, Fs);     % Create audio player for Player 2's jab sound

% Jab impact sound for Player 1 hitting Player 2 
[y, Fs] = audioread('jab_oof.mp4'); % Read audio file again for second player
Fs = 1.5*Fs;                        % Increase by 1.5x to raise pitch
Jab_sound2 = audioplayer(y, Fs);    % Ceate audio player for Player 1's jab sound

[name1, name2] = startScreen(); % Show the start screen and take player-entered names
pause(1)                        % Pause for 1 second after start screen closes before game begins
 
% PLAYER NAMES
% Display Player 1's name above their character in blue bold text
nameText1 = text(0, 0, name1, 'Color','blue','FontSize',24,'FontWeight','bold','HorizontalAlignment','center');
% Display Player 2's name above their character in red bold text
nameText2 = text(0, 0, name2, 'Color','red','FontSize',24,'FontWeight','bold','HorizontalAlignment','center');

i = 0; % Initialize counter uto 0

% MAIN LOOP
while ishandle(run) % Continue game loop as long as the figure window is open

    if i < 200 % For first 200 counts
        ux = -30000; % Apply leftward force on Player 1 to push them left from center
        u2x = 30000; % Apply rightward force on Player 2 to push them right fromcenter
        i = i + 1;   % Increment counter
    end
    
    % READ ARDUINO
    % Player 1 serial input
    if arduinoObj1.NumBytesAvailable > 0 % Only read if data avalable
        data1 = readline(arduinoObj1);    % Read one line from Player 1's Arduino
        tmp1 = split(strtrim(data1),','); % Split comma-separated values into an array
        num1 = str2double(tmp1);          % Convert each string to a double
    
        if numel(num1) < 7 || any(isnan(num1)) % Skip if incomplete or invalid 
            continue
        end
    
        raw = num1(2);         % Joystick Y-axis raw value (0–1023) for Player 1
        rawx = num1(3);        % Joystick X-axis raw value (0–1023) for Player 1
        p1jumpbtn = num1(4);   % Jump button state for Player 1 (0 = pressed, 1 = not pressed)
        p1dashbtn = num1(5);   % Dash button state for Player 1 (0 = pressed, 1 = not pressed)
        p1crouchbtn = num1(6); % Crouch button state for Player 1 (0 = pressed, 1 = not pressed)
        p1jabbtn = num1(7);    % Jab button state for Player 1 (0 = pressed, 1 = not pressed)
    end
    
    % Player 2 serial input
    if arduinoObj2.NumBytesAvailable > 0 % Only read if data avalible 
        data2 = readline(arduinoObj2);    % Read line from Player 2's Arduino
        tmp2 = split(strtrim(data2),','); % Split comma-separated values into an array
        num2 = str2double(tmp2);          % Convert each string to a double
    
        if numel(num2) < 7 || any(isnan(num2)) % Skip if incomplete or invalid 
            continue
        end
    
        raw2 = num2(2);        % Joystick Y-axis raw value for Player 2
        rawx2 = num2(3);       % Joystick X-axis raw value for Player 2
        p2jumpbtn = num2(4);   % Jump button state for Player 2
        p2dashbtn = num2(5);   % Dash button state for Player 2
        p2crouchbtn = num2(6); % Crouch button state for Player 2
        p2jabbtn = num2(7);    % Jab button state for Player 2
    end

                % Player 1 Vertical (Y-axis) joystick deadband and input 
                if (raw - 512) > 500 % If joystick is pushed upward    
                    up = 0; % Signals joystick is upward
                
                else 
                    up = 1; % Signals joystick is centered or downward
                end  

                if p1jumpbtn == 0 && y1 < (screeny+0.2) % If ump button pressed and player is on ground:    
                    uy = 800*(0.15+0.85*p1crouchbtn); % Apply upward force, reduce if crouching 

                elseif p1dashbtn == 0 && p1crouchbtn == 1 && y1 < (screeny+0.2) % Dash button pressed and not crouching and on ground
                    uy = 400*(raw-512)/512; % Apply vertical force based on joystick position during dash
                    
                else
                    uy = 0; % No vertical force applied, player falls by gravity
                end

                % Player 1 Horizontal (X-axis) joystick deadband and input 
                if abs(rawx - 512) < 20 % If inside deadband, ignore small joystick input
                    % ux = 0;        % Zero horizontal force
                    % x1start(2) = 0; % Zero horizontal velocity

                elseif p1dashbtn == 0 && p1crouchbtn == 1 % If dash button held and not crouching:
                    ux = -3000*(rawx-512)/512; % Apply horizontal dash force based on joystick input
                    
                else 
                    ux = -(rawx - 512)*(0.15+0.85*p1crouchbtn); % Reduced force while crouching
                end 
                                
            % Player 2 Vertical (Y-axis) joystick deadband and input
                if (raw2 - 512) > 500   % If joystick pushed upward:
                    up2 = 0;            % Signals joystick is upward
                
                else
                    up2 = 1;   % Signals joystick is centered or downward
                end
                
                if p2jumpbtn == 0 && y2 < (screeny+0.2) % If jump button pressed and Player 2 on ground:
                    u2y = 800*(0.15+0.85*p2crouchbtn);  % Apply upward force, reduce if crouching
                
                elseif p2dashbtn == 0 && p2crouchbtn == 1 && y2 < (screeny+0.2) % Dash while on ground and not crouching
                    u2y = 400*(raw2-512)/512; % Vertical force during dash
                
                else
                    u2y = 0; % No vertical force applied, player falls by gravity
                end
                
                % Player 2 Horizontal (X-axis) joystick deadband and input 
                if abs(rawx2 - 512) < 20 % If inside deadband, ignore small joystick input
                    % u2x = 0;        % Zero horizontal force
                    % x2start(2) = 0; % Zero horizontal velocity
                
                elseif p2dashbtn == 0 && p2crouchbtn == 1 % Dash for Player 2
                    u2x = -3000*(rawx2-512)/512; % Horizontal dash force based on joystick input
                
                else
                    u2x = -(rawx2 - 512)*(0.15+0.85*p2crouchbtn); % Reduced force while crouching
                end
                
% Compute drag scaling factor based on health
h1 = 1.0+(100.0-health1)*0.05; % Player 1 drag multiplier
h2 = 1.0+(100.0-health2)*0.05; % Player 2 drag multiplier

% RK4 Integration
y1start = RK4(y1start, dt, h1, uy,m, rho, Cd, A, g);    % Update Player 1 vertical position and velocity
x1start = RK4x(x1start, dt, h1, ux, m, rho, Cd, A, g);  % Update Player 1 horizontal position and velocity
x2start = RK4x(x2start, dt, h2, u2x, m, rho, Cd, A, g); % Update Player 2 horizontal position and velocity
y2start = RK4(y2start, dt, h2, u2y, m, rho, Cd, A, g);  % Update Player 2 vertical position and velocity
  
    if p1jabbtn == 0 && p1dashbtn == 1 % If Player 1 is jabbing but not dashing:
        x1start(2) = 0; % Zero Player 1's horizontal velocity 
    end

    if p2jabbtn == 0 && p2dashbtn == 1 % If Player 2 is jabbing but not dashing:
        x2start(2) = 0; % Zero Player 2's horizontal velocity during jab  
    end
    
    % BOUNDARY LIMITS
    % Player 1 vertical limits 
    if y1start(1) > yl    % If Player 1 goes above top boundary:
        y1start(1) = yl;  % Limit position to top boundary
        y1start(2) = 0;   % Zero vertical velocity

    elseif y1start(1) < 0 % If Player 1 goes below bottom boundary:
        y1start(1) = 0;   % Limit position to bottom boundary
        y1start(2) = 0;   % Zero vertical velocity 
    end
    
    % Player 2 vertical limits 
    if y2start(1) > yl    % If Player 2 goes above top boundary:
        y2start(1) = yl;  % Limit position to top boundary
        y2start(2) = 0;   % Zero vertical velocity

    elseif y2start(1) < 0 % If Player 2 goes below bottom boundary:
        y2start(1) = 0;   % Limit position to bottom boundary
        y2start(2) = 0;   % Zero vertical velocity 
    end
    
    % Player 1 horizontal boundary clamping
    if x1start(1) > xl      % If Player 1 goes right boundary:
        x1start(1) = xl;    % Limit position to right boundary
        x1start(2) = 0;     % Zero horizontal velocity

    elseif x1start(1) < -xl % If Player 1 goes past left boundary:
        x1start(1) = -xl;   % Limit position to left boundary
        x1start(2) = 0;     % Zero horizontal velocity
    end
    
    % Player 2 horizontal boundary clamping
    if x2start(1) > xl      % If Player 2 goes right boundary:
        x2start(1) = xl;    % Limit position to right boundary
        x2start(2) = 0;     % Zero horizontal velocity

    elseif x2start(1) < -xl % If Player 2 goes past left boundary:
        x2start(1) = -xl;   % Limit position to left boundary
        x2start(2) = 0;     % Zero horizontal velocity
    end
    
    % Convert coordinates to normalized screen coordinates 
    % Map Player 1 x to screen range [0, bgWidth]
    x1 = ((x1start(1)+xl)/(2*xl))*bgWidth; 
    % Map Player 1 y to screen range [0, bgHeight]
    y1 = (y1start(1)/yl)*bgHeight; 
    
    % Limit Player 1 screen y to valid display range
    if y1 > bgHeight
        y1 = bgHeight; % Prevent player from going above top screen boundary
    
    elseif y1 < screeny
        y1 = screeny;  % Prevent player from going below bottom screen boundary 
    end
    
    % Map Player 2 x to screen range [0, bgWidth]
    x2 = ((x2start(1)+xl)/(2*xl))*bgWidth; 
    % Map Player 2 y to screen range [0, bgHeight]
    y2 = (y2start(1)/yl)*bgHeight; 
    
    % Limit Player 2 screen y to valid display range
    if y2 > bgHeight
        y2 = bgHeight; % Prevent player from going above top screen boundary
    
    elseif y2 < screeny
        y2 = screeny;  % Prevent player from going below bottom screen boundary 
    end

    % Make Player 1's name float above their image 
    set(nameText1, 'Position', [x1, y1+scale+0.05, 0]); 
    % Make Player 2's name float above their image
    set(nameText2, 'Position', [x2, y2+scale+0.05, 0]); 
   
    % Apply images based on player button states and direction
    if x1 <= x2 % If Player 1 is to the left of Player 2
        
        % Determine Player 1's current image position
        player1image = changeimage(ux, up, burnt, p1crouchbtn, p1jabbtn, p1jumpbtn, p1dashbtn, m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab,Roasted_Run,alpha_Roasted_Run, Roasted_Runflip,alpha_Roasted_Runflip, ...
          Roasted_Jump, alpha_Roasted_Jump, Roasted_Jumpflip,alpha_Roasted_Jumpflip, Roasted_Crouch,alpha_Roasted_Crouch,...
          Roasted_Crouchflip,alpha_Roasted_Crouchflip, Roasted_Jab,alpha_Roasted_Jab, Roasted_Jabflip,alpha_Roasted_Jabflip,...
          Roasted_Upwards_Jab,alpha_Roasted_Upwards_Jab, Roasted_Upwards_Jabflip,alpha_Roasted_Upwards_Jabflip, ...
          Unroasted_Dash,alpha_upward_Unroasted_Dash, Unroasted_Dashflip,alpha_Unroasted_Dashflip, ...
          Roasted_Dash,alpha_Roasted_Dash, Roasted_Dashflip,alpha_Roasted_Dashflip);

        % Apply Player 1's roasted image and alpha
        set(burntrun,'CData', player1image{3}, 'AlphaData', player1image{4});
        % Apply Player 1's unroasted image and alpha 
        set(run,'CData', player1image{1}, 'AlphaData', player1image{2});

        % Determine Player 2's current image position
        player2image = changeimageflip(u2x, up2, burnt2, p2crouchbtn, p2jabbtn, p2jumpbtn, p2dashbtn, m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab,Roasted_Run,alpha_Roasted_Run, Roasted_Runflip,alpha_Roasted_Runflip, ...
          Roasted_Jump, alpha_Roasted_Jump, Roasted_Jumpflip,alpha_Roasted_Jumpflip, Roasted_Crouch,alpha_Roasted_Crouch,...
          Roasted_Crouchflip,alpha_Roasted_Crouchflip, Roasted_Jab,alpha_Roasted_Jab, Roasted_Jabflip,alpha_Roasted_Jabflip,...
          Roasted_Upwards_Jab,alpha_Roasted_Upwards_Jab, Roasted_Upwards_Jabflip,alpha_Roasted_Upwards_Jabflip, ...
          Unroasted_Dash,alpha_upward_Unroasted_Dash, Unroasted_Dashflip,alpha_Unroasted_Dashflip, ...
          Roasted_Dash,alpha_Roasted_Dash, Roasted_Dashflip,alpha_Roasted_Dashflip);

        % Apply Player 2's unroasted image
        set(p2run,'CData', player2image{1}, 'AlphaData', player2image{2});
        % Apply Player 2's roasted image
        set(burntrun2,'CData', player2image{3}, 'AlphaData', player2image{4});

    else % Player 1 is to the right of Player 2 
        player1image = changeimageflip(ux, up, burnt, p1crouchbtn, p1jabbtn, p1jumpbtn, p1dashbtn, m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab,Roasted_Run,alpha_Roasted_Run, Roasted_Runflip,alpha_Roasted_Runflip, ...
          Roasted_Jump, alpha_Roasted_Jump, Roasted_Jumpflip,alpha_Roasted_Jumpflip, Roasted_Crouch,alpha_Roasted_Crouch,...
          Roasted_Crouchflip,alpha_Roasted_Crouchflip, Roasted_Jab,alpha_Roasted_Jab, Roasted_Jabflip,alpha_Roasted_Jabflip,...
          Roasted_Upwards_Jab,alpha_Roasted_Upwards_Jab, Roasted_Upwards_Jabflip,alpha_Roasted_Upwards_Jabflip, ...
          Unroasted_Dash,alpha_upward_Unroasted_Dash, Unroasted_Dashflip,alpha_Unroasted_Dashflip, ...
          Roasted_Dash,alpha_Roasted_Dash, Roasted_Dashflip,alpha_Roasted_Dashflip);

        % Apply Player 1's roasted image
        set(burntrun,'CData', player1image{3}, 'AlphaData', player1image{4});
        % Apply Player 1's unroasted image
        set(run,'CData', player1image{1}, 'AlphaData', player1image{2});

        player2image = changeimage(u2x, up2, burnt2, p2crouchbtn, p2jabbtn, p2jumpbtn, p2dashbtn, m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab,Roasted_Run,alpha_Roasted_Run,Roasted_Runflip,alpha_Roasted_Runflip, ...
          Roasted_Jump, alpha_Roasted_Jump, Roasted_Jumpflip,alpha_Roasted_Jumpflip, Roasted_Crouch,alpha_Roasted_Crouch,...
          Roasted_Crouchflip,alpha_Roasted_Crouchflip, Roasted_Jab,alpha_Roasted_Jab, Roasted_Jabflip,alpha_Roasted_Jabflip,...
          Roasted_Upwards_Jab,alpha_Roasted_Upwards_Jab, Roasted_Upwards_Jabflip,alpha_Roasted_Upwards_Jabflip, ...
          Unroasted_Dash,alpha_upward_Unroasted_Dash, Unroasted_Dashflip,alpha_Unroasted_Dashflip, ...
          Roasted_Dash,alpha_Roasted_Dash, Roasted_Dashflip,alpha_Roasted_Dashflip);

        % Apply Player 2's unroasted image
        set(p2run,'CData', player2image{1}, 'AlphaData', player2image{2});
        % Apply Player 2's roasted image
        set(burntrun2,'CData', player2image{3}, 'AlphaData', player2image{4});
    end

    % HIT DETECTION AND DAMAGE
    % Check if Player 2 is jabbing Player 1 
    if p2jabbtn == 0 && p2crouchbtn == 1 && p1crouchbtn == 1 % If Player 2's jab hits Player 1:
        hit2 = jabfunction(x2, y2, x1, y1, up2, hitbox); % Hit detection
    
        if hit2 == 1 % If Player 2's jab hits Player 1:
            ux = 5*u2x*(abs(u2x)/(abs(u2x)+0.001)); % Knock Player 1 back proportional to Player 2's velocity
            
            play(Jab_sound2); % Play hit sound effect 
            
            % Calculate damage based on Player 2's speed at time of impact
            heart2 = (0.01 + (sqrt(u2x^2 + u2y^2))*0.000001); % Base damage + velocity-scaled bonus
            health1 = health1 - heart2;                       % Subtract damage from Player 1's health
            burnt = 0.1 + health1/111.11;                     % Update Player 1's roasted transparency
        end
        
    % Check if Player 1 is jabbing Player 2
    elseif p1jabbtn == 0 && p1crouchbtn == 1 &&  p2crouchbtn == 1 % If Player 1's jab connects with Player 2:
        hit = jabfunction(x1, y1, x2, y2, up, hitbox); % Hit detection
    
        if hit == 1 % If Player 1's jab hits Player 2:
            u2x = 5*ux*(abs(ux)/(abs(ux)+0.001)); % Knock Player 2 back proportional to Player 1's velocity
            
            play(Jab_sound); % Play hit sound effect
            
            % Calculate damage based on Player 1's speed at time of impact
            heart = (0.01 + (sqrt(ux^2 + uy^2))*0.000001); % Base damage + velocity-scaled bonus
            health2 = health2 - heart;                     % Subtract damage from Player 2's health
            burnt2 = 0.1 + health2/111.11;                 % Update Player 2's roasted transparency
        end

    else
        ux = 0;  % No jab active, clear knockback force on Player 1
        u2x = 0; % No jab active, clear knockback force on Player 2
    end  
    
    % Compute black damage bar for Player 1 
    blackw1 = 1.000001 - health1/100;
    % Scale damage bar width for Player 1
    dhb_width1 = dhb_width*blackw1+(0.003*(1-health1/100));
    
    % Compute black damage bar for Player 2
    blackw2 = 1.000001 - health2/100;
    % Scale damage bar width for Player 2
    dhb_width2 = dhb_width*blackw2;
    
    % Update Player 1 image positions on screen
    % Move Player 1's roasted image to their current screen position 
    set(burntrun,'XData',[x1-scale x1+scale],'YData',[y1-scale+0.1 y1+scale+0.1]);
    % Move Player 1's unroasted image to the same position
    set(run,'XData',[x1-scale x1+scale],'YData',[y1-scale+0.1 y1+scale+0.1]);

    % Update Player 1's damage bar
    set(DHB1, 'XData',[dhb_right - dhb_width1, dhb_right], 'YData',[dhb_top - dhb_height, dhb_top], 'AlphaData', alphadhb);

    % Move Player 2's roasted image to their current screen position
    set(burntrun2,'XData',[x2-scale x2+scale],'YData',[y2-scale+0.1 y2+scale+0.1]);
    % Move Player 2's unroasted image to the same position
    set(p2run,'XData',[x2-scale x2+scale],'YData',[y2-scale+0.1 y2+scale+0.1]); 
    
    % Update Player 2's damage bar
    set(DHB2, 'XData',[p2_dhb_left, p2_dhb_left + dhb_width2], 'YData',[dhb_top - dhb_height, dhb_top]);

    drawnow limitrate % Flush all pending graphics updates to screen
    
    % Check win/loss condition
    if health1 <= 0 || health2 <= 0
    
        if health1 <= 0
            % If Player 1's health hit zero: Player 2 wins
            showWinScreen(2, p1_win, p2_win, backgroundsound, Jab_sound, Jab_sound2); 
        else
            % If Player 2's health hit zero: Player 1 wins
            showWinScreen(1, p1_win, p2_win, backgroundsound, Jab_sound, Jab_sound2); 
        end
    
        break % Exit the main game loop after showing win screen
    end
end

stop(backgroundsound); % Stop background music when game loop ends   
clear arduinoObj1      % Release Player 1 serial port object and close the COM port
clear arduinoObj2      % Release Player 2 serial port object and close the COM port

% RK4 FUNCTION
% 4th-order Runge-Kutta integrator for vertical motion 
function y_new = RK4(y, dt, h, uy, m, rho, Cd, A, g)
    % Standard RK4 weights and coefficients
    w1=1/6; w2=1/3; w3=1/3; w4=1/6;               % Weighted sum coefficients 
    a21=1/2; a31=0; a32=1/2; a41=0; a42=0; a43=1; % Stage dependency coefficients

    k1=dt*f(y, h, uy,m, rho, Cd, A, g);                      % Slope at current state
    k2=dt*f(y+a21*k1, h, uy,m, rho, Cd, A, g);               % Slope at midpoint using k1
    k3=dt*f(y+a31*k1+a32*k2, h, uy,m, rho, Cd, A, g);        % Slope at midpoint using k2
    k4=dt*f(y+a41*k1+a42*k2+a43*k3, h, uy,m, rho, Cd, A, g); % Slope at endpoint using k3

    y_new=y+w1*k1+w2*k2+w3*k3+w4*k4; % Weighted combination gives 4th-order accurate next state
end

% RK4 integrator for horizontal motion 
function x_new = RK4x(x, dt, h, ux, m, rho, Cd, A, g)
    % Standard RK4 weights and coefficients
    w1=1/6; w2=1/3; w3=1/3; w4=1/6;               % Weighted sum coefficients 
    a21=1/2; a31=0; a32=1/2; a41=0; a42=0; a43=1; % Stage dependency coefficients

    k1=dt*fx(x, h, ux, m, rho, Cd, A, g);                      % Slope at current state
    k2=dt*fx(x+a21*k1, h, ux, m, rho, Cd, A, g);               % Slope at midpoint using k1
    k3=dt*fx(x+a31*k1+a32*k2, h, ux, m, rho, Cd, A, g);        % Slope at midpoint using k2
    k4=dt*fx(x+a41*k1+a42*k2+a43*k3, h, ux, m, rho, Cd, A, g); % Slope at endpoint using k3

    x_new=x+w1*k1+w2*k2+w3*k3+w4*k4; % Weighted combination gives 4th-order accurate next state
end

% DYNAMICS FUNCTIONS 
% Vertical dynamics: Gravity, air drag, applied force
function dxdt = f(y, h, uy, m, rho, Cd, A, g)
 
    dxdt = zeros(2,1); % Preallocate output, [velocity; acceleration]
 
    v = y(2); % Extract current vertical velocity from state vector
 
    % Compute aerodynamic drag force in verticle direction
    F_drag = 0.5 * rho * Cd * A * v * abs(v) * h;
 
    dxdt(1) = v;                       % Verticle velocity
    dxdt(2) = (uy - F_drag - g*m) / m; % Verticle acceleration 
end
 
% Horizontal dynamics: Drag 
function dxdtx = fx(x, h, ux, m, rho, Cd, A, g)
 
    dxdtx = zeros(2,1); % Preallocate output [velocity; acceleration]

    vx = x(2); % Extract current horizontal velocity from state vector
    
    % Compute aerodynamic drag force in horizontal direction
    F_dragx = 0.5 * rho * Cd * A * vx * abs(vx) * h;

    dxdtx(1) = vx;                 % Horizontal velocity
    dxdtx(2) = (ux - F_dragx) / m; % Horizontal acceleration 
end

% FIGURE SETUP FUNCTION
% Creates the game window, loads all sprite images, sets up the background, 
% health bars, and returns all layout parameters
function [bgWidth,bgHeight,bg, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab, ...
          scale,P1_HB,alphaP1,P2_HB,alphaP2,Black_HB,alphadhb,...
          hb_width,hb_height,hb_left,hb_top,dhb_width,dhb_height,dhb_left,dhb_top,...
          m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, ...
          Roasted_Run,alpha_Roasted_Run, Roasted_Runflip,alpha_Roasted_Runflip,p2_left,dhb_right,p2_dhb_left,...
          Roasted_Jump, alpha_Roasted_Jump, Roasted_Jumpflip,alpha_Roasted_Jumpflip, Roasted_Crouch,alpha_Roasted_Crouch,...
          Roasted_Crouchflip,alpha_Roasted_Crouchflip, Roasted_Jab,alpha_Roasted_Jab, Roasted_Jabflip,alpha_Roasted_Jabflip,...
          Roasted_Upwards_Jab,alpha_Roasted_Upwards_Jab, Roasted_Upwards_Jabflip,alpha_Roasted_Upwards_Jabflip, ...
          Unroasted_Dash,alpha_upward_Unroasted_Dash, Unroasted_Dashflip,alpha_Unroasted_Dashflip, ...
          Roasted_Dash,alpha_Roasted_Dash, Roasted_Dashflip,alpha_Roasted_Dashflip, p1_win, p2_win] = figure_setup()

    % Create fullscreen figure with no toolbars
    figure('WindowState','maximized', 'Toolbar','none', 'MenuBar','none', 'Color','k');
    
    % Background image setup
    bg = imread('Campfire_Smackdown_Backdrop.jpg'); % Load background image 
    bg = flipud(bg);                                % Flip vertically 
    [imgH,imgW,~] = size(bg);                       % Get image pixel dimensions
    imgRatio = imgW/imgH;                           % Compute aspect ratio 
 
    axH = 1;         % Axis height matches image height
    axW = imgRatio;  % Axis width matches image width
    axX = (1-axW)/2; % Center the axis horizontally within the figure
    axY = 0;         % Axis starts at bottom of figure

    % Create axis with computed position and aspect dimensions
    ax = axes('Position',[axX axY axW axH]);
    hold on  % Allow multiple images to be loaded onto same axis
    axis off % Hide axis lines

    % Store normalized background dimensions for coordinate mapping
    bgWidth = imgRatio;
    bgHeight = 1;

    % Stretch background image to fill the axis
    image('CData',bg, 'XData',[0 bgWidth], 'YData',[0 bgHeight])

    axis image         % Equal aspect ratio 
    xlim([0 bgWidth])  % Set x-axis limits to match background width
    ylim([0 bgHeight]) % Set y-axis limits to match background height
   
    % LOAD PLAYER IMAGES
    % Each image is loaded and flipped vertically
    % Horizontally mirrored version is created for the opposite-facing direction

    % Player 1 unroasted runing image (facing right)
    [m_run,~,alpha_run] = imread('m_run.png');
    m_run = flipud(m_run);
    alpha_run = flipud(alpha_run);

    % Player 2 unroasted running image (facing left)
    [m_runflip,~,alpha_runflip] = imread('m_run.png');
    m_runflip = rot90(m_runflip,2);
    alpha_runflip = rot90(alpha_runflip,2);

    % Player 1 roasted running image (facing right) 
    [Roasted_Run,~,alpha_Roasted_Run] = imread('Roasted_Run.png');
    Roasted_Run = flipud(Roasted_Run);
    alpha_Roasted_Run = flipud(alpha_Roasted_Run);

    % Player 2 roasted running image (facing left)
    [Roasted_Runflip,~,alpha_Roasted_Runflip] = imread('Roasted_Run.png');
    Roasted_Runflip = rot90(Roasted_Runflip,2);
    alpha_Roasted_Runflip = rot90(alpha_Roasted_Runflip,2);

    % Player 1 unroasted jump image (facing right)
    [m_jump,~,alpha_jump] = imread('m_jump.png');
    m_jump = flipud(m_jump);
    alpha_jump = flipud(alpha_jump);

    % Player 2 unroasted jump image (facing left)
    [m_jumpflip,~,alpha_jumpflip] = imread('m_jump.png');
    m_jumpflip = rot90(m_jumpflip,2);
    alpha_jumpflip = rot90(alpha_jumpflip,2);

    % Player 1 roasted jump image (facing right)
    [Roasted_Jump,~,alpha_Roasted_Jump] = imread('Roasted_Jump.png');
    Roasted_Jump = flipud(Roasted_Jump);
    alpha_Roasted_Jump = flipud(alpha_Roasted_Jump);

    % Player 2 roasted jump image (facing left)
    [Roasted_Jumpflip,~,alpha_Roasted_Jumpflip] = imread('Roasted_Jump.png');
    Roasted_Jumpflip = rot90(Roasted_Jumpflip,2);
    alpha_Roasted_Jumpflip = rot90(alpha_Roasted_Jumpflip,2);

    % Player 1 unroasted crouch image (facing right)
    [m_crouch,~,alpha_crouch] = imread('m_crouch.png');
    m_crouch = flipud(m_crouch);
    alpha_crouch = flipud(alpha_crouch);

    % Player 2 unroasted crouch image (facing left)
    [m_crouchflip,~,alpha_crouchflip] = imread('m_crouch.png');
    m_crouchflip = rot90(m_crouchflip,2);
    alpha_crouchflip = rot90(alpha_crouchflip,2);

    % Player 1 roasted crouch image (facing right)
    [Roasted_Crouch,~,alpha_Roasted_Crouch] = imread('Roasted_Crouch.png');
    Roasted_Crouch = flipud(Roasted_Crouch);
    alpha_Roasted_Crouch = flipud(alpha_Roasted_Crouch);

    % Player 2 roasted crouch image (facing left)
    [Roasted_Crouchflip,~,alpha_Roasted_Crouchflip] = imread('Roasted_Crouch.png');
    Roasted_Crouchflip = rot90(Roasted_Crouchflip,2);
    alpha_Roasted_Crouchflip = rot90(alpha_Roasted_Crouchflip,2);

    % Player 1 unroasted jab image (facing right)
    [m_jab,~,alpha_jab] = imread('m_jab.png');
    m_jab = flipud(m_jab);
    alpha_jab = flipud(alpha_jab);

    % Player 2 unroasted jab image (facing left)
    [m_jabflip,~,alpha_jabflip] = imread('m_jab.png');
    m_jabflip = rot90(m_jabflip,2);
    alpha_jabflip = rot90(alpha_jabflip,2);

    % Player 1 roasted jab jab (facing right)
    [Roasted_Jab,~,alpha_Roasted_Jab] = imread('Roasted_Jab.png');
    Roasted_Jab = flipud(Roasted_Jab);
    alpha_Roasted_Jab = flipud(alpha_Roasted_Jab);

    % Player 2 roasted jab image (facing left)
    [Roasted_Jabflip,~,alpha_Roasted_Jabflip] = imread('Roasted_Jab.png');
    Roasted_Jabflip = rot90(Roasted_Jabflip,2);
    alpha_Roasted_Jabflip = rot90(alpha_Roasted_Jabflip,2);

    % Player 1 unroasted upward jab image (facing right)
    [m_upward_jab,~,alpha_upward_jab] = imread('m_upward_jab.png');
    m_upward_jab = flipud(m_upward_jab);
    alpha_upward_jab = flipud(alpha_upward_jab);

    % Player 2 unroasted upward jab image (facing left)
    [m_upward_jabflip,~,alpha_upward_jabflip] = imread('m_upward_jab.png');
    m_upward_jabflip = rot90(m_upward_jabflip,2);
    alpha_upward_jabflip = rot90(alpha_upward_jabflip,2);

    % Player 1 roasted upward jab image (facing right)
    [Roasted_Upwards_Jab,~,alpha_Roasted_Upwards_Jab] = imread('Roasted_Upwards_Jab.png');
    Roasted_Upwards_Jab = flipud(Roasted_Upwards_Jab);
    alpha_Roasted_Upwards_Jab = flipud(alpha_Roasted_Upwards_Jab);

    % Player 2 roasted upward jab image(facing left)
    [Roasted_Upwards_Jabflip,~,alpha_Roasted_Upwards_Jabflip] = imread('Roasted_Upwards_Jab.png');
    Roasted_Upwards_Jabflip = rot90(Roasted_Upwards_Jabflip,2);
    alpha_Roasted_Upwards_Jabflip = rot90(alpha_Roasted_Upwards_Jabflip,2);

    % Player 1 unroasted dash jab (facing right)
    [Unroasted_Dash,~,alpha_upward_Unroasted_Dash] = imread('Unroasted_Dash.png');
    Unroasted_Dash = flipud(Unroasted_Dash);
    alpha_upward_Unroasted_Dash = flipud(alpha_upward_Unroasted_Dash);

    % Player 2 unroasted dash image (facing left)
    [Unroasted_Dashflip,~,alpha_Unroasted_Dashflip] = imread('Unroasted_Dash.png');
    Unroasted_Dashflip = rot90(Unroasted_Dashflip,2);
    alpha_Unroasted_Dashflip = rot90(alpha_Unroasted_Dashflip,2);

    % Player 1 roasted dash image (facing right)
    [Roasted_Dash,~,alpha_Roasted_Dash] = imread('Roasted_Dash.png');
    Roasted_Dash = flipud(Roasted_Dash);
    alpha_Roasted_Dash = flipud(alpha_Roasted_Dash);

    % Player 2 roasted dash image (facing left)
    [Roasted_Dashflip,~,alpha_Roasted_Dashflip] = imread('Roasted_Dash.png');
    Roasted_Dashflip = rot90(Roasted_Dashflip,2);
    alpha_Roasted_Dashflip = rot90(alpha_Roasted_Dashflip,2);

    % Load win screen images for each player
    [p1_win,~,~] = imread('Player1_Wins.jpg'); % Player 1 win screen
    p1_win = flipud(p1_win);                   % Flip to correct MATLAB image orientation

    [p2_win,~,~] = imread('Player2_Wins.jpg'); % Player 2 win screen
    p2_win = flipud(p2_win);                   % Flip to correct MATLAB image orientation

    % Compute image scale relative to background width 
    scale = 200/imgW;
    
    % Load Player 1 health bar image and flip it upright
    [P1_HB,~,alphaP1] = imread('P1_Health.png');
    P1_HB = flipud(P1_HB);
    alphaP1 = flipud(alphaP1);
    
    % Load Player 2 health bar image and flip it upright
    [P2_HB,~,alphaP2] = imread('P2_Health.png');
    P2_HB = flipud(P2_HB);
    alphaP2 = flipud(alphaP2);

    % Load black damage overlay bar image 
    [Black_HB,~,alphadhb] = imread('Black_HB.png');
    alphadhb = flipud(alphadhb); % Flip alpha channel upright 
    
    % Health bar layout dimensions and position 
    hb_width  = 0.45;  % Width of full health bar 
    hb_height = 0.15;  % Height of health bar
    hb_left   = 0.028; % Left edge x-position of Player 1's health bar
    hb_top    = 0.923; % Top edge y-position of health bars
  
    % Black damage overlay bar layout dimensions
    dhb_width  = 0.23;    % Width of damage overlay bar 
    dhb_height = 0.08745; % Height of damage overlay bar
    dhb_left   = 0.182;   % Left edge x-position of Player 1's damage bar
    dhb_top    = 0.8935;  % Top edge y-position of damage bars

    p2_left = bgWidth - hb_left - hb_width; % Compute Player 2's health bar left position 

    dhb_right = dhb_left + dhb_width;             % Compute right edge of Player 1's damage bar 
    p2_dhb_left = bgWidth - dhb_left - dhb_width; % Compute Player 2's damage bar left position (mirrored)
end

% JAB HIT DETECTION FUNCTION
% Checks if a jab from player at (x1,y1) connects with player at (x2,y2)
% Returns jab = 1 if hit, 0 if miss
function jab = jabfunction(x1, y1, x2, y2, up, hitbox)

    if x1 < x2 && (x1 + hitbox) > x2 && y1 < y2+hitbox/2 && y1 > y2-hitbox+hitbox*up/2
        % Jabber is to the left: check if their right-side hitbox overlaps target's position
        hit = 1; % Valid hit

    elseif x1 > x2 && (x1 - hitbox) < x2 && y1 < y2+hitbox/2 && y1 > y2-hitbox+hitbox*up/2
        % Jabber is to the right: check if their left-side hitbox overlaps target's position 
        hit = 1; % Valid hit

    else 
        hit = 0; % No overlap, no hit
    end

    jab = hit; % Return hit result
end

% CHANGE IMAGE 
% Loads image based on current action state (crouch, jab, jump, dash, run)
% Roasted transparency multiplier
function image = changeimage(ux, up, burnt, p1crouchbtn, p1jabbtn, p1jumpbtn, p1dashbtn, m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab,Roasted_Run,alpha_Roasted_Run, Roasted_Runflip,alpha_Roasted_Runflip, ...
          Roasted_Jump, alpha_Roasted_Jump, Roasted_Jumpflip,alpha_Roasted_Jumpflip, Roasted_Crouch,alpha_Roasted_Crouch,...
          Roasted_Crouchflip,alpha_Roasted_Crouchflip, Roasted_Jab,alpha_Roasted_Jab, Roasted_Jabflip,alpha_Roasted_Jabflip,...
          Roasted_Upwards_Jab,alpha_Roasted_Upwards_Jab, Roasted_Upwards_Jabflip,alpha_Roasted_Upwards_Jabflip, ...
          Unroasted_Dash,alpha_upward_Unroasted_Dash, Unroasted_Dashflip,alpha_Unroasted_Dashflip, ...
          Roasted_Dash,alpha_Roasted_Dash, Roasted_Dashflip,alpha_Roasted_Dashflip)

 if ux >= 0 % If player is facing/moving right or stationary use right-facing images
       
    if p1crouchbtn == 0 % If crouch button held (facing/moving right):
        image{1} = m_crouch;             % Load unroasted crouch image 
        image{2}= alpha_crouch*burnt;    % Transparency for unroasted image
        image{3} = Roasted_Crouch;       % Load roasted crouch image
        image{4} = alpha_Roasted_Crouch; % Transparency for roasted image
        
    elseif p1jabbtn == 0 && p1crouchbtn == 1 % If jab button pressed while standing:

        if up == 0 % If joystick pointing upward use upward jab image
            image{1} = m_upward_jab;              % Load unroasted upward jab image 
            image{2}= alpha_upward_jab*burnt;     % Transparency for unroasted image
            image{3} = Roasted_Upwards_Jab;       % Load roasted upward jab image
            image{4} = alpha_Roasted_Upwards_Jab; % Transparency for roasted image
            
        else % If joystick centered/downward use regular jab image (facing/moving right)
            image{1} = m_jab;             % Load unroasted jab image 
            image{2}= alpha_jab*burnt;    % Transparency for unroasted image
            image{3} = Roasted_Jab;       % Load roasted jab image
            image{4} = alpha_Roasted_Jab; % Transparency for roasted image
        end
    
    elseif p1jumpbtn == 0 && p1crouchbtn == 1 % If jump button pressed while standing use jump image (facing/moving right)
        image{1} = m_jump;             % Load unroasted jump image 
        image{2}= alpha_jump*burnt;    % Transparency for unroasted image
        image{3} = Roasted_Jump;       % Load roasted jump image
        image{4} = alpha_Roasted_Jump; % Transparency for roasted image

    elseif p1dashbtn == 0 && p1crouchbtn == 1 % If dash button pressed while standing use dash image (facing/moving right)
        image{1} = Unroasted_Dash;                   % Load unroasted dash image 
        image{2}= alpha_upward_Unroasted_Dash*burnt; % Transparency for unroasted image
        image{3} = Roasted_Dash;                     % Load roasted dash image
        image{4} = alpha_Roasted_Dash;               % Transparency for roasted image

    else % If no button presses, default to running image (facing/moving right)
        image{1} = m_run;             % Load unroasted running image 
        image{2} = alpha_run*burnt;   % Transparency for unroasted image
        image{3} = Roasted_Run;       % Load roasted running image
        image{4} = alpha_Roasted_Run; % Transparency for roasted image
    end
   
 else % If player is facing/moving left use left-facing images

    if p1crouchbtn == 0 % If crouch button held (facing/moving left):
        image{1} = m_crouchflip;             % Load unroasted crouch image 
        image{2}= alpha_crouchflip*burnt;    % Transparency for unroasted image
        image{3} = Roasted_Crouchflip;       % Load roasted crouch image
        image{4} = alpha_Roasted_Crouchflip; % Transparency for roasted image
        
    elseif p1jabbtn == 0 && p1crouchbtn == 1 % If jab button pressed while standing:

        if up == 0 % If joystick is upwards while jabbing (facing/moving left):
            image{1} = m_upward_jabflip;              % Load unroasted upwards jab image 
            image{2}= alpha_upward_jabflip*burnt;     % Transparency for unroasted image
            image{3} = Roasted_Upwards_Jabflip;       % Load roasted upwards jab image
            image{4} = alpha_Roasted_Upwards_Jabflip; % Transparency for roasted image
            
        else % If jab button pressed (facing/moving left):
            image{1} = m_jabflip;             % Load unroasted jab image 
            image{2}= alpha_jabflip*burnt;    % Transparency for unroasted image
            image{3} = Roasted_Jabflip;       % Load roasted jab image
            image{4} = alpha_Roasted_Jabflip; % Transparency for roasted image
        end
    
    elseif p1jumpbtn == 0 && p1crouchbtn == 1 % If jump button held (facing/moving left):
        image{1} = m_jumpflip;             % Load unroasted jump image 
        image{2}= alpha_jumpflip*burnt;    % Transparency for unroasted image
        image{3} = Roasted_Jumpflip;       % Load roasted jump image
        image{4} = alpha_Roasted_Jumpflip; % Transparency for roasted image

    elseif p1dashbtn == 0 && p1crouchbtn == 1 % If dash button held (facing/moving left)
        image{1} = Unroasted_Dashflip;             % Load unroasted dash image 
        image{2}= alpha_Unroasted_Dashflip*burnt;  % Transparency for unroasted image
        image{3} = Roasted_Dashflip;               % Load roasted dash image
        image{4} = alpha_Roasted_Dashflip;         % Transparency for roasted image


    else % If no button presses, default to running image (facing/moving left)
        image{1} = m_runflip;             % Load unroasted running image 
        image{2} = alpha_runflip*burnt;   % Transparency for unroasted image
        image{3} = Roasted_Runflip;       % Load roasted running image
        image{4} = alpha_Roasted_Runflip; % Transparency for roasted image
    end
 end
 
end

% CHANGE IMAGE FLIP 
% Used when a player's relative position is reversed compared to it's default facing

function image = changeimageflip(ux, up, burnt, p1crouchbtn, p1jabbtn, p1jumpbtn, p1dashbtn, m_runflip,alpha_runflip,m_jumpflip,alpha_jumpflip, m_crouchflip,alpha_crouchflip,...
          m_jabflip,alpha_jabflip, m_upward_jabflip,alpha_upward_jabflip, m_run, alpha_run, m_jump, alpha_jump, ...
          m_crouch, alpha_crouch, m_jab, alpha_jab, ...
          m_upward_jab, alpha_upward_jab,Roasted_Run,alpha_Roasted_Run, Roasted_Runflip,alpha_Roasted_Runflip, ...
          Roasted_Jump, alpha_Roasted_Jump, Roasted_Jumpflip,alpha_Roasted_Jumpflip, Roasted_Crouch,alpha_Roasted_Crouch,...
          Roasted_Crouchflip,alpha_Roasted_Crouchflip, Roasted_Jab,alpha_Roasted_Jab, Roasted_Jabflip,alpha_Roasted_Jabflip,...
          Roasted_Upwards_Jab,alpha_Roasted_Upwards_Jab, Roasted_Upwards_Jabflip,alpha_Roasted_Upwards_Jabflip, ...
          Unroasted_Dash,alpha_upward_Unroasted_Dash, Unroasted_Dashflip,alpha_upward_Unroasted_Dashflip, ...
          Roasted_Dash,alpha_Roasted_Dash, Roasted_Dashflip,alpha_Roasted_Dashflip)

 if ux <= 0 % If facing/moving left or stationary use left facing images
   
    if p1crouchbtn == 0 % If crouch button held (facing/moving left): 
        image{1} = m_crouchflip;             % Load unroasted crouch image 
        image{2}= alpha_crouchflip*burnt;    % Transparency for unroasted image
        image{3} = Roasted_Crouchflip;       % Load roasted crouch image
        image{4} = alpha_Roasted_Crouchflip; % Transparency for roasted image
        
    elseif p1jabbtn == 0 && p1crouchbtn == 1 % If jab button pressed while standing (facing/moving left):

        if up == 0 % If jab putton pressed and joystick upwards (facing/moving left):
            image{1} = m_upward_jabflip;              % Load unroasted upwards jab image 
            image{2}= alpha_upward_jabflip*burnt;     % Transparency for unroasted image
            image{3} = Roasted_Upwards_Jabflip;       % Load roasted upwards jab image
            image{4} = alpha_Roasted_Upwards_Jabflip; % Transparency for roasted image
            
        else % If jab button is pressed (facing/moving left):
            image{1} = m_jabflip;             % Load unroasted jab image 
            image{2}= alpha_jabflip*burnt;    % Transparency for unroasted image
            image{3} = Roasted_Jabflip;       % Load roasted jab image
            image{4} = alpha_Roasted_Jabflip; % Transparency for roasted image
        end
    
    elseif p1jumpbtn == 0 && p1crouchbtn == 1 % If jump button pressed while standing (facing/moving left):
        image{1} = m_jumpflip;             % Load unroasted jump image 
        image{2}= alpha_jumpflip*burnt;    % Transparency for unroasted image
        image{3} = Roasted_Jumpflip;       % Load roasted jump image
        image{4} = alpha_Roasted_Jumpflip; % Transparency for roasted image

    elseif p1dashbtn == 0 && p1crouchbtn == 1 % if dash button pressed while standing (facing/moving left):
        image{1} = Unroasted_Dashflip;                   % Load unroasted dash image 
        image{2}= alpha_upward_Unroasted_Dashflip*burnt; % Transparency for unroasted image
        image{3} = Roasted_Dashflip;                     % Load roasted dash image
        image{4} = alpha_Roasted_Dashflip;               % Transparency for roasted image

    else  % No buttons pressed (facing/facing/moving left)
        image{1} = m_runflip;             % Load unroasted running image
        image{2} = alpha_runflip*burnt;   % Transparency for unroasted image
        image{3} = Roasted_Runflip;       % Load roasted running image
        image{4} = alpha_Roasted_Runflip; % Transparency for roasted image
    end
 
 else % If facing/moving right use right-facing images 
       
    if p1crouchbtn == 0 % If crouch button pressed (facing/moving right):
        image{1} = m_crouch;             % Load unroasted crouch image
        image{2}= alpha_crouch*burnt;    % Transparency for unroasted image
        image{3} = Roasted_Crouch;       % Load roasted crouch image
        image{4} = alpha_Roasted_Crouch; % Transparency for roasted image
        
    elseif p1jabbtn == 0 && p1crouchbtn == 1 % Jab button pressed while standing (facing/moving right)

        if up == 0 % If jab button pressed and joystick upwards (facing/moving right):
            image{1} = m_upward_jab;              % Load unroasted upwards jab image
            image{2}= alpha_upward_jab*burnt;     % Transparency for unroasted image
            image{3} = Roasted_Upwards_Jab;       % Load roasted upwards jab image
            image{4} = alpha_Roasted_Upwards_Jab; % Transparency for roasted image
            
        else % If jab button pressed (facing/moving right):
            image{1} = m_jab;             % Load unroasted jab image
            image{2}= alpha_jab*burnt;    % Transparency for unroasted image
            image{3} = Roasted_Jab;       % Load roasted jab image
            image{4} = alpha_Roasted_Jab; % Transparency for roasted image
        end
    
    elseif p1jumpbtn == 0 % If jump button pressed (facing/moving right):
        image{1} = m_jump;             % Load unroasted jump image
        image{2}= alpha_jump*burnt;    % Transparency for unroasted image
        image{3} = Roasted_Jump;       % Load roasted jump image
        image{4} = alpha_Roasted_Jump; % Transparency for roasted image

    elseif p1dashbtn == 0 && p1crouchbtn == 1 % If dash button pressed while standing (facing/moving right):
        image{1} = Unroasted_Dash;                   % Load unroasted dash image
        image{2}= alpha_upward_Unroasted_Dash*burnt; % Transparency for unroasted image
        image{3} = Roasted_Dash;                     % Load roasted dash image
        image{4} = alpha_Roasted_Dash;               % Transparency for roasted image

    else % No buttons pressed (facing/moving right)
        image{1} = m_run;             % Load unroasted running image
        image{2} = alpha_run*burnt;   % Transparency for unroasted image
        image{3} = Roasted_Run;       % Load roasted running image
        image{4} = alpha_Roasted_Run; % Transparency for roasted image
        
    end  
end
end

% WIN SCREENS 
% Stops all audio, clears the figure, shows the winner's image,
% and waits for the window to be closed

    function showWinScreen(winner, p1_win, p2_win, backgroundsound, Jab_sound, Jab_sound2) % Declares function and it's inputs

    stop(backgroundsound); % Stop background music
    stop(Jab_sound);       % Stop Player 1 jab sound
    stop(Jab_sound2);      % Stop Player 2 jab sound

    clf; % Clear the current figure contents 
    set(gcf,'WindowState','maximized','Color','k'); % Keep fullscreen with black background figure

    % Laod the appropriate win image based on which player won
    if winner == 1
        img = p1_win; % If Player 1 wins
    else
        img = p2_win; % If Player 2 wins
    end

    % Compute image aspect ratio for correct display sizing
    [imgH,imgW,~] = size(img);
    imgRatio = imgW/imgH;

    % Set up axis to fill screen with correct aspect ratio
    axH = 1;             % Set axis height to 1
    axW = imgRatio;      % Matches axis width with the image aspect ratio
    axX = (1 - axW) / 2; % Centers horizontally
    axY = 0;             % Starts the axis at 0

    ax = axes('Position',[axX axY axW axH]); % Create axis object
    hold on  % Keep existing plots
    axis off % Remove axis lines from figure

    % Load the win screen image filling the axes
    image('CData', img, 'XData',[0 axW], 'YData',[0 axH]); % Load image
    axis image                  % Equal aspect ratio  
    set(gca, 'YDir', 'normal'); % Y-axis is not inverted
    xlim([0 axW])               % Limit axis width
    ylim([0 axH])               % Limit axis height 
    drawnow;                    % Draws win screen
 
    waitfor(gcf); % Pause until user closes the win screen window
end

% START SCREEN 
% Players type their names and press Start; returns both names as strings
    function [name1, name2] = startScreen() % Creates function and declares its inputs 

    % Create fullscreen figure with black background for start screen
    fig = figure('WindowState','maximized', 'Toolbar','none', 'MenuBar','none', 'Color','k');

    bg = imread('Start_Screen.jpg'); % Read  and loadd image file
    bg = flipud(bg);                 % Flip image upsidedown 
    [imgH, imgW, ~] = size(bg);      % Reads dimensions of image 
    imgRatio = imgW / imgH;          % Computes aspect ratio of image 

    % Set up axis to fill screen with correct aspect ratio
    axH = 1;             % Set axis height to 1
    axW = imgRatio;      % Matches axis width with the image aspect ratio
    axX = (1 - axW) / 2; % Centers horizontally
    axY = 0;             % Starts the axis at 0

   ax = axes('Position',[axX axY axW axH]); % Create axis object
    hold on  % Keep existing plots
    axis off % Remove axis lines from figure
    
    % Load the win screen image filling the axes
    image('CData', bg, 'XData',[0 imgRatio], 'YData',[0 1]); % Fits image to screen
    axis image                  % Load image
    axis image                  % Equal aspect ratio  
    set(gca, 'YDir', 'normal'); % Y-axis is not inverted
    xlim([0 imgRatio])          % Limit axis width
    ylim([0 1])                 % Limit axis height 
    
    % Create Player 1 name input text box 
    p1box = uicontrol('Style','edit', ...             
        'Units','normalized', ...
        'Position',[0.0372 0.622 0.235 0.093], ...    % Position and size in normalized figure units
        'String','Player 1', ...                      % Default placeholder text
        'FontSize',25, ...                            % Setting font size
        'FontName','Cooper Black', ...                % Setting font style
        'BackgroundColor',[79/255 53/255 35/255], ... % Setting background color
        'ForegroundColor',[228/255 210/255 173/255]); % Setting text color

    % Create Player 2 name input text box 
    p2box = uicontrol('Style','edit', ...
        'Units','normalized', ...
        'Position',[0.7378 0.622 0.235 0.093], ...    % Position and size in normalized figure units
        'String','Player 2', ...                      % Default placeholder text
        'FontSize',25, ...                            % Setting font size
        'FontName','Cooper Black', ...                % Setting font style
        'BackgroundColor',[79/255 53/255 35/255], ... % Setting background color
        'ForegroundColor',[228/255 210/255 173/255]); % Setting text color

    % Define start button dimensions and position 
    btn_width  = 0.365;          % Button width in axis units
    btn_height = 0.2;            % Button height in axis units
    btn_cx     = imgRatio*0.505; % Horizontal center of button
    btn_cy     = 0.55;           % Vertical center of button

    % Load start button image 
    [start_btn, ~, start_alpha] = imread('Start_Button.png'); % Read start button image
    start_btn   = flipud(start_btn);   % Flip image upright
    start_alpha = flipud(start_alpha); % Flip alpha channel upright

    % Render start button on the axis 
    start_img = image(ax, 'CData', start_btn, ...                   % Reads image data
        'XData',[btn_cx - btn_width/2,  btn_cx + btn_width/2], ...  % Positions the button horizontally
        'YData',[btn_cy - btn_height/2, btn_cy + btn_height/2], ... % Positions the button vertically 
        'AlphaData', start_alpha * 0);                              % Control image alpha data

    % Clicking start button resumes execution 
    set(start_img, 'ButtonDownFcn', @(~,~) uiresume(fig));

    uiwait(fig); % Wait until the start button is clicked

    % Retrieve player names from the text boxes after uiresume
    name1 = get(p1box, 'String'); % Get Player 1 name as a string 
    name2 = get(p2box, 'String'); % Get Player 2 name as a string

    close(fig); % Close the start screen figure and begin game
end

