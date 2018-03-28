function comm = get_led_calibration_serial_comm()

%   GET_LED_CALIBRATION_SERIAL_COMM -- Return an interface to the
%     far-plane calibration serial-comm.
%
%     OUT:
%       - `comm` (serial_comm.SerialManager)

conf = brains.config.load();

port = conf.SERIAL.ports.led_calibration;

n_leds = 14;

comm = brains.arduino.LEDComm( port, n_leds );
comm.bypass = ~conf.INTERFACE.use_arduino;

end