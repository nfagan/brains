classdef LEDComm < serial_comm.SerialManager
  
  properties (Access = private)
    led_chars;
    led_end_char = 'X';
  end
  
  methods
    function obj = LEDComm(port, led_chars)
      
      %   LEDComm -- Instantiate an interface to an LED-lighting Arduino.
      %
      %     obj = LEDComm( 'COM5', {'Q', 'W'} ); creates an LED manager
      %     whose first LED is associated with the character 'Q', and the
      %     second 'W'.
      %
      %     IN:
      %       - `port` (char)
      %       - `led_chars` (cell array of strings)
      
      assert( isa(port, 'char'), 'Port must be a char; was a %s.', class(port) );
      assert( iscellstr(led_chars), ['Led characters must be a' ...
        , ' cell array of strings.'] );
      assert( ~isempty(led_chars), 'Specify at least one LED character.' );
      obj = obj@serial_comm.SerialManager( port, struct(), '' );
      obj.led_chars = led_chars;
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
      n_leds = numel( obj.led_chars );
      assert( index > 0 && index <= n_leds ...
        , 'Index out of range; must be > 0 and <= %d.', n_leds );
      assert( mod(duration, 1) == 0, 'Specify whole number durations, only.' );
      obj.write( obj.led_chars{index}, duration, obj.led_end_char );
    end
  end
  
end