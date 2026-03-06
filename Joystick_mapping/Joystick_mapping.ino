int xPin = A0;
int yPin = A1;

float deadzone = 0.01;

void setup() {
  Serial.begin(9600);
}

void loop() {

  // read raw values
  float x_raw = readAxis(xPin);
  float y_raw = readAxis(yPin);

  // normalize (-1 to 1)
  float x = (x_raw - 512.0) / 512.0;
  float y = (y_raw - 512.0) / 512.0;

  // apply deadzone
  if (abs(x) < deadzone) x = 0;
  if (abs(y) < deadzone) y = 0;

  // clamp to circular range (fix corner distortion)
  float magnitude = sqrt(x * x + y * y);

  if (magnitude > 1.0) {
    x /= magnitude;
    y /= magnitude;
  }

  // print values
  Serial.print("real X: ");
  Serial.print(x_raw);
  Serial.print("  real Y: ");
  Serial.print(y_raw);

  Serial.print("  New X: ");
  Serial.print(x, 3);
  Serial.print("  New Y: ");
  Serial.println(y, 3);

  delay(100);
}


int readAxis(int pin) {
  long total = 0;

  // average 10 readings to smooth noise
  for (int i = 0; i < 10; i++) {
    total += analogRead(pin);
  }

  return total / 10;
}
