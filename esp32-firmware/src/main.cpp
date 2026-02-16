#include <WiFi.h>
#include <WiFiUdp.h>
#include <FastLED.h>
#include <ArduinoJson.h>

#define LED_PIN 5
#define NUM_LEDS 64
#define MATRIX_WIDTH 8
#define MATRIX_HEIGHT 8

CRGB leds[NUM_LEDS];
WiFiUDP udp;
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";

void setup() {
  Serial.begin(115200);
  FastLED.addLeds<NEOPIXEL, LED_PIN>(leds, NUM_LEDS);
  fill_solid(leds, NUM_LEDS, CRGB::Black);
  FastLED.show();

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");

  udp.begin(7777);
  Serial.println("UDP server started");
}

void loop() {
  int packetSize = udp.parsePacket();
  if (packetSize) {
    StaticJsonDocument<1024> doc;
    DeserializationError error = deserializeJson(doc, udp);
    if (error) {
      Serial.print("deserializeJson() failed: ");
      Serial.println(error.c_str());
      return;
    }

    JsonArray bars = doc["bars"];
    bool beat = doc["beat"];

    // Map bars to LED matrix
    for (int i = 0; i < MATRIX_WIDTH; i++) {
      float value = bars[i];
      int height = (int)(value * MATRIX_HEIGHT);

      for (int y = 0; y < MATRIX_HEIGHT; y++) {
        int ledIndex = (MATRIX_HEIGHT - 1 - y) * MATRIX_WIDTH + i;
        if (y < height) {
          leds[ledIndex] = CHSV(map(i, 0, MATRIX_WIDTH, 0, 255), 255, 255);
        } else {
          leds[ledIndex] = CRGB::Black;
        }
      }
    }

    if (beat) {
      fill_solid(leds, NUM_LEDS, CRGB::White);
    }

    FastLED.show();
  }
}
