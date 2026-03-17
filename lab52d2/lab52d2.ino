// Button Presses 
const int jumpPin = 4; // Declare jump button to represent digital pin 4
const int dashPin = 5; // Declare dash button to represent digital pin 5
const int crouchPin = 6; // Declare crouch button to represent digital pin 6
const int jabPin = 7; // Declare jab button to represent digital pin 7

const int yPin = A0; // Declare y direction of joystick to represent analog pin 0
const int xPin = A1; // Declare x direction of joystick to represent analog pin 1

long counter = 0;
unsigned long lastDebounceTime = 0;  // Innizalize the last time a button was pressed to 0
unsigned long debounce = 50; // Declare a debounce variable equal to 50 miliseconds

bool jumpBtn = 1;
bool dashBtn = 1;
bool crouchBtn = 1;
bool jabBtn = 1;

int i = 0;
int j = 0;
int k = 0;
int l = 0;

void setup() {
  Serial.begin(115200); // Baud rate MUST match MATLAB

  pinMode(jumpPin, INPUT); // Declare jumpPin as an input
  pinMode(dashPin, INPUT); // Declare dashPin as an input
  pinMode(crouchPin, INPUT); // Declare crouchPin as an input
  pinMode(jabPin, INPUT); // Declare jabPin as an input

  delay(500); // Pause for 500 miliseconds to allow MATLAb to setup
}
 
void loop() {

  int yValue = analogRead(yPin);  
    
  int xValue = analogRead(xPin); 

  // JUMP BUTTON
  int jumpBtnState = digitalRead(jumpPin); // Set the current button state equal to the current reading from the input pin

    if (i <= 5){

      if (jumpBtnState == LOW){

        int current_time = millis();

        if(current_time - lastDebounceTime > debounce){
            
          jumpBtn = 0;
        }

        lastDebounceTime = current_time;

        i++;
      }
    }

    else{
      i = 0;
      jumpBtn = 1;
    }

  // DASH BUTTON 
  int dashBtnState = digitalRead(dashPin); // Set the current button state equal to the current reading from the input pin

    if (j <= 5){

      if (dashBtnState == LOW){

        int current_time = millis();

        if(current_time - lastDebounceTime > debounce){
            
          dashBtn = 0;
        }

        lastDebounceTime = current_time;

        j++;
      }
    }

    else{
      i = 0;
      dashBtn = 1;
    }

  // CROUCH BUTTON 
  int crouchBtnState = digitalRead(crouchPin); // Set the current button state equal to the current reading from the input pin

  // JAB BUTTON 
  int jabBtnState = digitalRead(jabPin); // Set the current button state equal to the current reading from the input pin

    if (l <= 5){

      if (jabBtnState == LOW){

        int current_time = millis();

        if(current_time - lastDebounceTime > debounce){
            
          jabBtn = 0;
        }

        lastDebounceTime = current_time;

        l++;
      }
    }

    else{
      i = 0;
      jabBtn = 1;
    }
  Serial.println(String(String(counter)+","+String(yValue)+","+String(xValue)+","+String(jumpBtn)+","+String(dashBtn)+","+String(crouchBtn)+","+String(jabBtn)));
  delay(10);
}