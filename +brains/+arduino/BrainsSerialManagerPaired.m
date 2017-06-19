classdef BrainsSerialManagerPaired < serial_comm.SerialManagerPaired
  
  properties    
    addtl_chars = struct( 'LED_END', 'T' );
    led_ids = { 'Y', 'U' };
  end
  
  methods
    
    function obj = BrainsSerialManagerPaired(varargin)
      
      %   BRAINSSERIALMANAGERPAIRED -- Instantiate a
      %     BrainsSerialManagerPaired object.
      %
      %     BrainsSerialManagerPaired is a class that inherits from the
      %     SerialManagerPaired superclass. The majority of functions are
      %     contained in serial_comm.SerialManager and
      %     serial_comm.SerialManagerPaired.
      %
      %     IN:
      %       - `port` (char)
      %       - `messages` (struct array) -- Struct array with 'char' and
      %         'message' fields.
      %       - `channels` (cell array of strings) -- Reward channel ids.
      %       - `role` (char) -- 'slave' or 'master'
      
      obj = obj@serial_comm.SerialManagerPaired( varargin{:} );
    end
    
    function LED(obj, id, duration)
      
      %   LED -- Light up an LED for the given duration.
      %
      %     IN:
      %       - `duration` (double)
      
      if ( ~ischar(id) )
        id = obj.led_ids{ id };
      end
      obj.write( id, duration, obj.addtl_chars.LED_END );
    end
  end  
  
end