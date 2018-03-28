//
//  Initialization + reward
//

struct IDS 
{
  const char terminator = 'e';
  const char error = '!';
} ids;

char init_char = '*';

//
//  LED
//
const int BUFFER_SIZE = 32;
char BUFFER[BUFFER_SIZE];

const int n_leds = 14;
int led_pins[n_leds] = { 22 };
const char led_time_end = 'X';
int led_times[n_leds] = { 0 };
int led_magnitudes[n_leds] = { 200 };
bool led_state_changed[n_leds] = { false };

int response_index = 0;

unsigned long millisLastFrame;
unsigned long millisThisFrame;

void setup() {

  initialize_led_arrays();

  while ( !Serial ) {
    //  wait
  }

  for (int i = 0; i < BUFFER_SIZE; i++) {
    BUFFER[i] = 'a';
  }

  Serial.begin( 115200 );

  Serial.print( init_char );
  
  for ( int i = 0; i < n_leds; i++ ) {
    pinMode( led_pins[i], OUTPUT );
  }
}

void loop() {

  millisThisFrame = millis();

  handleSerialComm();

  handleLED();

  millisLastFrame = millisThisFrame;

}

void initialize_led_arrays()
{
  for (unsigned i = 1; i < n_leds; ++i)
  {
    led_pins[i] = led_pins[0] + i;
    led_times[i] = led_times[0];
    led_magnitudes[i] = led_magnitudes[0];
    led_state_changed[i] = led_state_changed[0]; 
  }
}

void handleSerialComm() {

  if ( Serial.available() <= 0 ) return;
  int led_index = get_led_index();
  int led_time = get_led_time();
  handleNewLEDTime( led_index, led_time );
}

void clear_buffer() {
  for (int i = 0; i < BUFFER_SIZE; i++) {
    BUFFER[i] = 'a';
  }
}

int get_led_index() {
  return await_int(ids.terminator);
}

int get_led_time() {
  return await_int(ids.terminator);
}

int await_int(char terminator) {
  int n_read = Serial.readBytesUntil(terminator, BUFFER, sizeof(BUFFER)-1);

    if (n_read == 0)
    {
        Serial.print(ids.error);
        return -1;
    }

    BUFFER[n_read] = '\0';

    return atoi(BUFFER);
}

void handleNewLEDTime( int index, int value ) {

  if (index < 0 || index > n_leds-1)
  {
      Serial.print(ids.error);
      return;
  }
  
  led_times[index] = value;
  led_state_changed[index] = true;
}

void handleLED() {

  unsigned long delta = millisThisFrame - millisLastFrame;
  for ( int i = 0; i < n_leds; i++ ) {
    if ( led_times[i] == 0 ) continue;
    led_times[i] -= delta;
    if ( led_times[i] <= 0 ) {
      led_state_changed[i] = true;
      led_times[i] = 0;
    }
    if (!led_state_changed[i]) continue;
    if ( led_times[i] == 0 ) {
      digitalWrite( led_pins[i], LOW );
    } else {
      analogWrite( led_pins[i], led_magnitudes[i] );
    }
    led_state_changed[i] = false;
  }
}
