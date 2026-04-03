// MECH3905 Term Project
// Date: April 6, 2026
// Group 6 Members: 
// Eric Adamson (B00962642)
// Francesco Borrelli (B00964461)
// Quinn Fox (B01020683)
// Purpose: Send button and joystick info to MATLAB

// Button Pins
const int crouchPin = 8; // Digital pin 8 represents the crouch pin
const int dashPin = 9;   // Digital pin 9 represents the dash pin
const int jabPin = 10;   // Digital pin 10 represents the jab pin 
const int jumpPin = 11;  // Digital pin 11 represents the jump pin

// Joystick Pins
const int xPin = A0; // Analog pin 0 represents the joystick x-axis pin
const int yPin = A1; // Analog pin 1 represents the joystick y-axis pin 

const unsigned long debounceDelay = 50; // Debounce delay set to 50 miliseconds 

// Button outputs 
bool jumpBtn = 1;   // Jump button state set to 1 (not pressed)
bool dashBtn = 1;   // Dash button state set to 1 (not pressed)
bool crouchBtn = 1; // Crouch button state set to 1 (not pressed)
bool jabBtn = 1;    // Jab button state set to 1 (not pressed)

// States
int lastJumpReading = HIGH; // Last reading of jump button set to high (not pressed, used for debounce)
int lastDashReading = HIGH; // Last reading of dash button set to high (not pressed, used for debounce)
int lastJabReading  = HIGH; // Last reading of jab button set to high (not pressed, used for debounce)

int stableJumpState = HIGH; // Stable jump debounce state set to HIGH
int stableDashState = HIGH; // Stable dash debounce state set to HIGH
int stableJabState  = HIGH; // Stable jab debounce state set to HIGH

unsigned long lastDebounceTimeJump = 0; // Last time jump button pressed initialized as 0
unsigned long lastDebounceTimeDash = 0; // Last time dash button pressed initialized as 0
unsigned long lastDebounceTimeJab  = 0; // Last time jab button pressed initialized as 0

long counter = 0; // Loop iteration counter initialized as 0

int i = 0; // Delay counter for jump button 
int k = 0; // Hold counter for jab button
int l = 0; // Hold limiter for jump button
int d = 0; // Delay counter for dash button 
int c = 0; // Hold limiter for dash button

void setup() {
  Serial.begin(2000000); // Initialize serial communication at a baud rate of 2000000

  // Button pins declared as inputs
  pinMode(jumpPin, INPUT); 
  pinMode(dashPin, INPUT);
  pinMode(crouchPin, INPUT);
  pinMode(jabPin, INPUT);

  delay(500); // 500 milisecond setup delay
}

void loop() {

  // Read joystick analog values
  int xValue = analogRead(xPin); // X-axis position values
  int yValue = analogRead(yPin); // Y-axis position values 

  // JUMP BUTTON
  int jumpReading = digitalRead(jumpPin); // Read jump button state

  if (i > 20){
    if (jumpReading == 0){ // If button pressed (LOW)
        if(l < 30){        // Limit how long btton stay pressed to 30 iterations of counter
          jumpBtn = 0;     // Register jump press
          l++;             // Increment hold duration counter
        }

    } else {
      i = 0;       // Reset delay counter
      jumpBtn = 1; // Register release
      l = 0;       // Reset hold limiter
    }
  }

  i++; // Increment jump delay counter

  // DASH BUTTON 

  int dashReading = digitalRead(dashPin); // Read dash button state

  if (d > 20){
    if (dashReading == 0){ // If button pressed (LOW)
        if(c < 30){        // Limit how long btton stay pressed to 30 iterations of counter
          dashBtn = 0;     // Register dash press
          c++;             // Increment hold duration counter
        }

    } else {
      d = 0;       // Reset delay counter
      dashBtn = 1; // Register release
      c = 0;       // Reset hold limiter
    }
  }

  d++; // Increment dash delay counter

  // JAB BUTTON 
  bool jabReading = digitalRead(jabPin); // Read jab button

  if (jabReading == 0){ // Button pressed
      if(k < 20){       // Shorter hold window than others
        jabBtn = 0;     // Register jab press
        k++;            // Increment hold duration counter
      }

  } else {
    jabBtn = 1; // Register release
    k = 0;      // Reset hold counter
  }

  //CROUCH BUTTON 
  crouchBtn = digitalRead(crouchPin); // Direct read (no debounce logic)

  // erial output. Send counter, joystick, and button state data
  Serial.println(
    String(counter) + "," +
    String(xValue) + "," +
    String(yValue) + "," +
    String(jumpBtn) + "," +
    String(dashBtn) + "," +
    String(crouchBtn) + "," +
    String(jabBtn)
  );

  // Reset button outputs (no button spam)
  jumpBtn = 1;
  dashBtn = 1;
  jabBtn = 1;

  counter++;   // Increment loop counter
  delay(10);   // Small loop delay (~100 Hz update rate)
}