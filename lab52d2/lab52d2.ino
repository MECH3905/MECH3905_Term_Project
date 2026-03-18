// Button Presses 
const int jumpPin = 4;   // Digital pin 4 connected to the jump button
const int dashPin = 5;   // Digital pin 5 connected to the dash button
const int crouchPin = 6; // Digital pin 6 connected to the crouch button
const int jabPin = 7;    // Digital pin 7 connected to the jab button

const int yPin = A0; // Analog pin 0 connected to the y direction of joystick movement 
const int xPin = A1; // Analog pin 1 connected to the x direction of joystick movement 

long counter = 0;                   
unsigned long lastDebounceTime = 0; 
unsigned long debounce = 50;        

bool jumpBtn = 1;
bool dashBtn = 1;
bool crouchBtn = 1;
bool jabBtn = 1;

int i = 0;
int j = 0;
int k = 0;
int l = 0;

void setup() {
  Serial.begin(115200); // Initialize serial communication at a baud rate of 115200 MUST match MATLAB

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