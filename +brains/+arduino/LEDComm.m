classdef LEDComm < serial_comm.SerialManager
  
  properties (Access = private)
    led_chars;
    n_leds;
    led_end_char = 'e';
  end
  
  methods
    function obj = LEDComm(port, n_leds)
      
      %   LEDComm -- Instantiate an interface to an LED-lighting Arduino.
      %
      %     obj = LEDComm( 'COM5', 5 ); creates an LED manager associated
      %     with 5 individually-addressable LEDs.
      %
      %     IN:
      %       - `port` (char)
      %       - `led_chars` (cell array of strings)
      
      assert( isa(port, 'char'), 'Port must be a char; was a %s.', class(port) );
      assert( isa(n_leds, 'double') && numel(n_leds) == 1 && n_leds > 0 ...
        , 'Specify the number of LEDs as an integer greater than 0.' );
      obj = obj@serial_comm.SerialManager( port, struct(), '' );
      obj.n_leds = n_leds;
    end
    
    function light(obj, index, duration)
      
      %   light -- Light an LED for a given amount of ms.
      %
      %     IN:
      %       - `index` (double) -- Index into the `led_chars` array.
      %       - `duration` (double) -- Number of ms. Must be a whole
      %         number.
      
      if ( obj.bypass ), return; end
      assert( obj.is_started, 'The serial connection must be open.' );
      assert( index - 1 >= 0 && index <= obj.n_leds ...
        , 'Index out of range; must be > 0 and <= %d.', obj.n_leds );
      assert( mod(duration, 1) == 0, 'Specify whole number durations, only.' );
      obj.write( num2str(index-1), obj.led_end_char, duration, obj.led_end_char );
    end
  end
  
end