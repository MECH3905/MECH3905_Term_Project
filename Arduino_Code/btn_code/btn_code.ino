const int btn_jump = 2;
const int btn_jab = 3;
const int btn_crouch = 4;

long lastTimeJump = 0;
const int debounceTimeJump = 50;
bool jumpTriggered = false;

long lastTimeJab = 0;
const int debounceTimeJab = 50;
bool jabTriggered = false;

long lastTimeCrouch = 0;
const int debounceTimeCrouch = 20;

void setup() {
  Serial.begin(9600);

  pinMode(btn_jump, INPUT_PULLUP);
  pinMode(btn_jab, INPUT_PULLUP);
  pinMode(btn_crouch, INPUT_PULLUP);
}

void loop() {
  if (Serial.available()) {
    String msg = Serial.readStringUntil('\n');
    msg.trim();

    if (msg == "1") Serial.println("JUMP");
    else if (msg == "2") Serial.println("JAB");
    else if (msg == "3") Serial.println("CROUCH");
    else if (msg == "JUMP_OK") jumpTriggered = false;
  }

  checkJump();
  checkJab();
  checkCrouch();
}

void checkJump() {
  long now = millis();
  int state = digitalRead(btn_jump);

  if (state == LOW && (now - lastTimeJump > debounceTimeJump) && !jumpTriggered) {
    Serial.println("JUMP");
    jumpTriggered = true;
    lastTimeJump = now;
  }

  if (state == HIGH) {
    jumpTriggered = false;
  }
}

void checkJab() {
  long now = millis();
  int state = digitalRead(btn_jab);

  if (state == LOW && (now - lastTimeJab > debounceTimeJab) && !jabTriggered) {
    Serial.println("JAB");
    jabTriggered = true;
    lastTimeJab = now;
  }

  if (state == HIGH) {
    jabTriggered = false;
  }
}

void checkCrouch() {
  long now = millis();
  int state = digitalRead(btn_crouch);

  if (state == LOW && (now - lastTimeCrouch > debounceTimeCrouch)) {
    Serial.println("CROUCH");
    lastTimeCrouch = now;
  }
}