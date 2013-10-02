#include <wiringPi.h>
#include <stdio.h>
#include <stdarg.h>
#include <errno.h>
#include <limits.h>
#include <stdlib.h>

static volatile int buttonPressed;

void buttonPressedInt (void) { buttonPressed = 1; }
void moveMotor(float degrees);

#define DEBUG 0
void debugPrintf (char *format, ...);

#define SWITCH_PIN 5

/* Motor is in wiringPi pins 0,1,2,3 */

#define STEP_COUNT 8
/* we have a 64 step motor, with a 64:1 ratio gearbox, so 64x64 steps per 260 degrees
 * see: http://www.raspberrypi-spy.co.uk/wp-content/uploads/2012/07/Stepper-Motor-28BJY-48-Datasheet.pdf 
 */
#define STEPS_PER_360 4096

/* delay between steps in milliseconds */
#define STEP_DELAY 5

int motorSequence[STEP_COUNT][4] = {
  {1,0,0,0},
  {1,1,0,0},
  {0,1,0,0},
  {0,1,1,0},
  {0,0,1,0},
  {0,0,1,1},
  {0,0,0,1},
  {1,0,0,1}
};

int main (int argc, char **argv)
{
  if ( argc != 2 ) /* argc should be 2 for correct execution */
    {
      /* We print argv[0] assuming it is the program name */
      printf( "usage: %s <degrees to move>\n", argv[0] );
      return 1;
    }

  /* take from: https://www.securecoding.cert.org/confluence/display/seccode/INT06-C.+Use+strtol()+or+a+related+function+to+convert+a+string+token+to+an+integer */
  const char* const c_str = argv[1];
  char *end;
  int degrees;
 
  errno = 0;
 
  const long sl = strtol(c_str, &end, 10);

  if (end == c_str) {
    fprintf(stderr, "%s: not a decimal number\n", c_str);
    return 1;
  }
  else if ('\0' != *end) {
    fprintf(stderr, "%s: extra characters at end of input: %s\n", c_str, end);
    return 1;
  }
  else if ((LONG_MIN == sl || LONG_MAX == sl) && ERANGE == errno) {
    fprintf(stderr, "%s out of range of type long\n", c_str);
    return 1;
  }
  else if (sl > INT_MAX) {
    fprintf(stderr, "%ld greater than INT_MAX\n", sl);
    return 1;
  }
  else if (sl < INT_MIN) {
    fprintf(stderr, "%ld less than INT_MIN\n", sl);
    return 1;
  }
  else {
    degrees = (int)sl;
  }

  buttonPressed = 0;
  wiringPiSetup () ;

  /* Setup the micro switch pin */
  pinMode (SWITCH_PIN, INPUT);
  pullUpDnControl (SWITCH_PIN, PUD_DOWN);
  wiringPiISR (SWITCH_PIN, INT_EDGE_RISING, &buttonPressedInt) ;

  /* setup the motor output pins */
  int pin;
  for (pin = 0 ; pin < 4 ; ++pin){
    pinMode (pin, OUTPUT);
    digitalWrite (pin, 0);
  }

  while (!buttonPressed) moveMotor(1);

  moveMotor(degrees);
  return 0;
}

/* global so that we carry on from where we left off */
int stepCounter = 0;

void moveMotor(float degrees){
  int stepsRequired = (degrees/360) * STEPS_PER_360;
  
  debugPrintf("motor will step %d steps for %f degrees\n", stepsRequired, degrees);

  while (stepsRequired){
    int pin;
    for (pin = 0; pin < 4; ++pin){
      digitalWrite (pin, motorSequence[stepCounter][pin]);
    }

    stepCounter += 1;

    /* If we reach the end of the sequence start again */
    if (stepCounter == STEP_COUNT)
      stepCounter = 0;
    if (stepCounter < 0)
      stepCounter = STEP_COUNT;
    
    stepsRequired--;

    delay (STEP_DELAY);
  }
  
}

void debugPrintf(char *format, ...){
  if (!DEBUG) return; 

  va_list args;
  va_start (args, format);

  vprintf (format, args);

  va_end (args);
}
