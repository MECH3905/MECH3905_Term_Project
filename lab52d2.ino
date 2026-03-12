

// ============================================
// MECH Lab - MATLAB Communication (Y Only)
// Sends: counter,yValue
// ============================================
const int button1Pin = 7; 
const int button2Pin = 6; 
const int yPin = A0;
const int xPin = A1;
long counter = 0;
unsigned long lastDebounceTime = 0;  // the last time the output pin was toggled
unsigned long debounceDelay = 50;  

void setup() {
  Serial.begin(115200);   // MUST match MATLAB
  pinMode(button1Pin, INPUT);
  pinMode(button2Pin, INPUT);
  delay(500);
}
 
void loop() {
  //if (Serial.available() > 2)
  //{
  
    int yValue = analogRead(yPin);   // 0–1023
    int xValue = analogRead(xPin);
    
    
     // the current state of the output pin
    int button1State = digitalRead(button1Pin);         // the current reading from the input pin
  // the previous reading from the input pin

    int button2State = digitalRead(button2Pin);
 

  
 

  Serial.println(String(String(counter)+","+String(yValue)+","+String(xValue)+","+String(button1State)+","+String(button2State)));
  delay(10);

}