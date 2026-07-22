/*
  Physical Nudge PoC — Posture Wellness

  Arduino UNO R4 WiFi + SG90 micro servo, triggered over the local WiFi
  network when the Mac app detects sustained poor posture. Fun demo
  hardware for a launch video, not part of the shipped app - no cloud,
  LAN only, same POST is easy to fire manually with curl for bench testing.

  Wiring:
    Servo signal (orange) -> D9
    Servo power  (red)    -> separate 5V supply, NOT the Uno's 5V/USB
                              pin (servo stall current can brown out
                              the board mid-swing)
    Servo ground (brown)  -> shared with Uno ground

  On nudge, the onboard 12x8 LED matrix also flashes a fist/punch icon
  in sync with the servo swing - no wiring needed, it's built into the
  board and driven by the bundled Arduino_LED_Matrix library.

  Board setup (Arduino IDE):
    Tools > Board > Boards Manager -> install "Arduino UNO R4 Boards"
    Tools > Board -> "Arduino UNO R4 WiFi"
    No extra libraries needed - Servo.h, WiFiS3.h and
    Arduino_LED_Matrix.h all ship with the core.
    If WiFi.begin() hangs at "Connecting to WiFi....", update the WiFi
    co-processor firmware via File > Examples > WiFiS3 > Tools >
    FirmwareUpdater (follow its on-screen instructions).

  Manual test once flashed:
    curl -X POST http://<uno-ip>/nudge
*/

#include <WiFiS3.h>
#include <Servo.h>
#include "Arduino_LED_Matrix.h"

const char* WIFI_SSID = "TODO";
const char* WIFI_PASSWORD = "TODO";

const int SERVO_PIN = 9;
const int REST_ANGLE = 0;
const int NUDGE_ANGLE = 90;
const int SWING_HOLD_MS = 250;

Servo nudgeServo;
WiFiServer server(80);
ArduinoLEDMatrix matrix;

// 12x8 fist icon - arm punching in from the left into a rounded fist.
// Not const: ArduinoLEDMatrix::renderBitmap() takes a non-const uint8_t*.
uint8_t punchFrame[8][12] = {
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0 },
  { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
  { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
  { 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0 },
  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
};

uint8_t blankFrame[8][12] = { 0 };

void sendResponse(WiFiClient& client, int statusCode, const String& body) {
  client.print(String("HTTP/1.1 ") + statusCode + " OK\r\n");
  client.print("Content-Type: text/plain\r\n");
  client.print("Content-Length: " + String(body.length()) + "\r\n");
  client.print("Connection: close\r\n");
  client.print("\r\n");
  client.print(body);
}

void handleRequest(WiFiClient& client, const String& requestLine) {
  if (requestLine.startsWith("POST /nudge")) {
    Serial.println("Nudge triggered");
    matrix.renderBitmap(punchFrame, 8, 12);
    nudgeServo.write(NUDGE_ANGLE);
    delay(SWING_HOLD_MS);
    nudgeServo.write(REST_ANGLE);
    matrix.renderBitmap(blankFrame, 8, 12);
    sendResponse(client, 200, "ok");
  } else if (requestLine.startsWith("GET /")) {
    sendResponse(client, 200, "Physical Nudge PoC online");
  } else {
    sendResponse(client, 404, "not found");
  }
}

void setup() {
  Serial.begin(115200);

  nudgeServo.attach(SERVO_PIN, 500, 2400);
  nudgeServo.write(REST_ANGLE);

  matrix.begin();
  matrix.renderBitmap(blankFrame, 8, 12);

  if (WiFi.status() == WL_NO_MODULE) {
    Serial.println("WiFi module not found - check board selection");
    while (true) delay(1000);
  }

  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Connected. IP address: ");
  Serial.println(WiFi.localIP());

  server.begin();
  Serial.println("HTTP server started");
}

unsigned long lastStatusPrint = 0;

void loop() {
  // Reprint the IP every 5s so it's visible whenever Serial Monitor is
  // opened, not just in the instant right after WiFi connects.
  if (millis() - lastStatusPrint > 5000) {
    lastStatusPrint = millis();
    Serial.print("Alive. IP address: ");
    Serial.println(WiFi.localIP());
  }

  WiFiClient client = server.available();
  if (!client) return;

  String currentLine = "";
  String requestLine = "";
  bool gotRequestLine = false;

  while (client.connected()) {
    if (client.available()) {
      char c = client.read();
      if (c == '\n') {
        if (!gotRequestLine) {
          requestLine = currentLine;
          gotRequestLine = true;
        }
        if (currentLine.length() == 0) {
          handleRequest(client, requestLine);
          break;
        }
        currentLine = "";
      } else if (c != '\r') {
        currentLine += c;
      }
    }
  }

  delay(1);
  client.stop();
}
