// Button Pins
const int jumpPin = 8;
const int dashPin = 9;
const int crouchPin = 10;
const int jabPin = 11;

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
int i = 0;
int k = 0;
int l = 0;
int d = 0;
int c = 0;


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


 if (i>20){
    if (jumpReading == 0){
        if(l<30){
          jumpBtn = 0;
          l++;
          
        }
        
    }else{
      i=0;
      jumpBtn = 1;
      l = 0;
    }
 }

 i++;

  // DASH BUTTOn 
  int dashReading = digitalRead(dashPin);

  if (d>20){
    if (dashReading == 0){
        if(c<30){
          dashBtn = 0;
          c++;
          
        }
        
    }else{
      d=0;
      dashBtn = 1;
      c = 0;
    }
 }

 d++;
  // JAB BUTTON
  bool jabReading = digitalRead(jabPin);

  

    if (jabReading == 0){
        if(k<20){
          jabBtn = 0;
          k++;
          
        }
        
    }else{
      //i=0;
      jabBtn = 1;
      k = 0;
    }




  // CROUCH BUTTON
  crouchBtn = digitalRead(crouchPin);

  Serial.println(String(counter)+","+String(xValue)+","+String(yValue)+","+String(jumpBtn)+","+String(dashBtn)+","+String(crouchBtn)+","+String(jabBtn));

  jumpBtn = 1;
  dashBtn = 1;
  jabBtn = 1;

  counter++;
  delay(10);
}
