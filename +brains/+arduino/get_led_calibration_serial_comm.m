function comm = get_led_calibration_serial_comm()

%   GET_LED_CALIBRATION_SERIAL_COMM -- Return an interface to the
%     far-plane calibration serial-comm.
%
%     OUT:
%       - `comm` (serial_comm.SerialManager)

conf = brains.config.load();

if ( conf.INTERFACE.IS_M1 )
  port = conf.SERIAL.led_calibration_port.M1;
else
  port = conf.SERIAL.led_calibration_port.M2;
end

led_chars = { 'Q', 'W', 'E', 'R', 'T', 'Y', 'U' };

comm = brains.arduino.LEDComm( port, led_chars );
comm.bypass = ~conf.INTERFACE.use_arduino;

end