// Button Presses 

// Button Pins
const int jumpPin = 4;
const int dashPin = 5;
const int crouchPin = 6;
const int jabPin = 7;

// Joystick Pins
const int xPin = A0;
const int yPin = A1;

// Debounce
const unsigned long debounceDelay = 50;

// Button outputs 
bool jumpBtn = 1;
bool dashBtn = 1;
bool crouchBtn = 1;
bool jabBtn = 1;

// States
int lastJumpReading = HIGH;
int lastDashReading = HIGH;
int lastJabReading  = HIGH;

int stableJumpState = HIGH;
int stableDashState = HIGH;
int stableJabState  = HIGH;

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
