// Course: MECH 3905
// Project: Lab 5 – Arduino-MATLAB RK4 Joystick
// Date: February 26, 2026
// Group Members: Eric Adamson (B00962642), Francesco Borrelli (B00964461), Quinn Fox (B01020683)
// Purpose: Use a joystick to control a ball’s vertical motion, displayed on a screen, by applying a force to a zero-gravity ODE, utilizing Arduino–MATLAB communication.
 
int yPin = A0; // Declare a constant integer named ‘yPin’ to represent analog pin 0
long counter = 0; // Declare a constant long variable named ‘counter’ and initialize it as zero
 
void setup() {
  Serial.begin(115200); // Initialize serial communication at a baud rate of 115200 to match MATLAB
}
 
void loop() {
 
  int yValue = analogRead(yPin); // Reads analog voltage from yPin and stores the value (0–1023)
 
  Serial.print(counter); // Sends current counter value to the serial monitor 
  Serial.print(","); // Prints a comma (separate values) 
  Serial.println(yValue); // Sends yValue to the serial monitor and starts a new line
 
  counter++; // Increments counter by one
  
  delay(10); // Delays code by ten milliseconds 
}
