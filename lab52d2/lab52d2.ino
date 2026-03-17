

// ============================================
// MECH Lab - MATLAB Communication (Y Only)
// Sends: counter,yValue
// ============================================
const int button1Pin = 7; 
const int button2Pin = 6; 
const int yPin = A0;
const int xPin = A1;
long counter = 0;

unsigned long lastButton = 0;  // the last time the output pin was toggled
unsigned long debounce = 50;  

bool btn1 = 1;
int i = 0;
void setup() {
  Serial.begin(115200);   // MUST match MATLAB
  pinMode(button1Pin, INPUT);
  pinMode(button2Pin, INPUT);
  delay(500);
}
 
void loop() {

    

    int yValue = analogRead(yPin);  
    
    int xValue = analogRead(xPin);
    
    
     
     
    int button1State = digitalRead(button1Pin);         // the current reading from the input pin

      if (i <= 5){
      if (button1State == LOW){
          int current_time = millis();

          if(current_time - lastButton > debounce){

            
            btn1 = 0;
          }
          

          lastButton = current_time;

          i++;
      }
      }
      else{
        i = 0;
        btn1 = 1;
         
      }


    int button2State = digitalRead(button2Pin);
 

  
 

  Serial.println(String(String(counter)+","+String(yValue)+","+String(xValue)+","+String(btn1)+","+String(button2State)));
  delay(10);

}