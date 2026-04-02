<<<<<<< Updated upstream
// Button Presses 

// Button Pins
const int jumpPin = 4;
const int dashPin = 5;
const int crouchPin = 6;
const int jabPin = 7;
=======
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
>>>>>>> Stashed changes

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

unsigned long lastDebounceTimeJump = 0;
unsigned long lastDebounceTimeDash = 0;
unsigned long lastDebounceTimeJab  = 0;

long counter = 0;

void setup() {
  Serial.begin(115200);

  pinMode(jumpPin, INPUT);
  pinMode(dashPin, INPUT);
  pinMode(crouchPin, INPUT);
  pinMode(jabPin, INPUT);

  delay(500);
}

void loop() {

  int xValue = analogRead(xPin);
  int yValue = analogRead(yPin);

  // JUMP BUTTON
  int jumpReading = digitalRead(jumpPin);

  if (jumpReading != lastJumpReading) {
    lastDebounceTimeJump = millis();
  }

  if ((millis() - lastDebounceTimeJump) > debounceDelay) {
    if (jumpReading != stableJumpState) {
      stableJumpState = jumpReading;

      if (stableJumpState == LOW) { 
        jumpBtn = 0; 
      }
    }
  }

  lastJumpReading = jumpReading;

  // DASH BUTTOn 
  int dashReading = digitalRead(dashPin);

  if (dashReading != lastDashReading) {
    lastDebounceTimeDash = millis();
  }

  if ((millis() - lastDebounceTimeDash) > debounceDelay) {
    if (dashReading != stableDashState) {
      stableDashState = dashReading;

      if (stableDashState == LOW) {
        dashBtn = 0;
      }
    }
  }

  lastDashReading = dashReading;

  // JAB BUTTON
  int jabReading = digitalRead(jabPin);

  if (jabReading != lastJabReading) {
    lastDebounceTimeJab = millis();
  }

  if ((millis() - lastDebounceTimeJab) > debounceDelay) {
    if (jabReading != stableJabState) {
      stableJabState = jabReading;

      if (stableJabState == LOW) {
        jabBtn = 0;
      }
    }
  }

  lastJabReading = jabReading;

  // CROUCH BUTTON
  crouchBtn = digitalRead(crouchPin);


  Serial.println(String(counter)+","+String(xValue)+","+String(yValue)+","+String(jumpBtn)+","+String(dashBtn)+","+String(crouchBtn)+","+String(jabBtn));

  jumpBtn = 1;
  dashBtn = 1;
  jabBtn = 1;

  counter++;
  delay(10);
}
