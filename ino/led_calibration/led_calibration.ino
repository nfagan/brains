//
//  Initialization + reward
//

char init_char = '*';

//
//  LED
//

const int n_leds = 7;
int led_pins[n_leds] = { 2 };
char led_messages[n_leds] = { 'Q', 'W', 'E', 'R', 'T', 'Y', 'U' };
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

  Serial.print( init_char );

  Serial.begin( 115200 );
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
  int inByte = Serial.read();
  char inChar = char( inByte );
  int led_index = findIndex( led_messages, n_leds, inChar );
  if ( led_index == -1 ) return;
  String led_time_str = readIn( led_time_end, "" );
  int led_time = stringToInt( led_time_str, 0 );
  handleNewLEDTime( led_index, led_time );
}

void handleNewLEDTime( int index, int value ) {
  
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

String readIn( char endMessage, String initial ) {

  while ( Serial.available() <= 0 ) {
    delay( 5 );
  }
  while ( Serial.available() > 0 ) {
    int pos = Serial.read();
    pos = char( pos );
    if ( pos == endMessage ) break;
    initial += char(pos);
  }
  return initial;
}

int findIndex( char* arr, int arrsz, char search ) {

  int pos = -1;
  for ( int i = 0; i < arrsz; i++ ) {
    if ( arr[i] == search ) {
      pos = i;
      break;
    }
  }
  return pos;
}

int stringToInt( String str, int removeNLeading ) {
  int bufferSize = str.length() + 1;
  char charNumber[ bufferSize ] = { 'b' };
  for ( int i = 0; i < removeNLeading; i++ ) {
    str.remove(0, 1);
  }
  str.toCharArray( charNumber, bufferSize );
  return atol( charNumber );
}
