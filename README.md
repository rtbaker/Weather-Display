# Weather Display

Software to support a Raspberry Pi powered weather display. Using the Met Office feed to get the weather forecast for
the next 3 hours and display it by rotating a clock face like circle with weather symbols printed on it so that the current forecast is at the top (12 o'clock position).

## Comprises:

1. moveStepper
   A wiringPi C utility to turn the stepper motor to the correct position. The motor spins the display until the 12 o'clock position
   is detected (by using a small tab on the back of the face activating a micro switch). The display is then spun x degree's to the 
	 desired position.
	
	 Usage:
	 `moveStepper <degrees>`
		
2. getForecast.pl
   A perl script that retrieves the weather forecast using the Met Office Datapoint api and spins the display face to the required position.

3. forecastLocations.pl
	 Utility to help search for MetOffice Datapoint location id of the weather forecast you want.
	
	Requires:
		Google::GeoCoder::Smart Perl module.
		Geo::Distance Perl module.
		
4. MetOffice.pm
	 A perl module to support the above perl scripts.
	
	 Requires:
			Text::CSV Perl module.