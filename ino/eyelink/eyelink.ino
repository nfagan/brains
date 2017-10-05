#include <BrainsEyelink.h>

enum GAZE_PINS1 {
  PINX1 = A1,
  PINY1
};

enum GAZE_PINS2 {
  PINX2 = A3,
  PINY2
};

const int screen_rect1[4] = { 0, 0, 800, 600 };
const int screen_rect2[4] = { 0, 0, 800, 600 };

int X = 0;
int Y = 0;

unsigned long millis_this_frame = millis();
unsigned long millis_last_frame = 0;
unsigned long delta_millis = 0;

unsigned int report_interval = 50;

BrainsEyelink eyelink1 = BrainsEyelink(&Serial, PINX1, PINY1, screen_rect1);
BrainsEyelink eyelink2 = BrainsEyelink(&Serial, PINX2, PINY2, screen_rect2);

void setup() {

  while ( !Serial ) {
    //  wait
  }

  Serial.begin( 115200 );

  eyelink1.setup();
  eyelink2.setup();
}

void loop() {

  millis_this_frame = millis();
  delta_millis += millis_this_frame - millis_last_frame;
  millis_last_frame = millis_this_frame;
  if ( delta_millis > report_interval ) {
    eyelink1.update();
    eyelink1.print_pixel_coords();
    delta_millis = 0;
  }
}
