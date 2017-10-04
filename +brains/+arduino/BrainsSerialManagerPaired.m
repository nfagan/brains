classdef BrainsSerialManagerPaired < serial_comm.SerialManagerPaired
  
  properties    
    addtl_chars = struct( 'LED_END', 'T' );
    led_ids = { 'Y', 'U' };
    plex_ids = { '1', '2', '3', '4' };
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
      %       - `id` (char, double) -- Index of LED to light.
      %       - `duration` (double)
      
      if ( ~ischar(id) )
        id = obj.led_ids{ id };
      end
      obj.write( id, duration, obj.addtl_chars.LED_END );
    end
    
    function sync_pulse(obj, id)
      
      %   SYNC_PULSE -- Send a synchronization pulse to Plexon.
      %
      %     The length of a pulse is defined in the brains.ino file as
      %     `plex_sync_pulse_length`.
      %
      %     IN:
      %       - `id` (char) -- Char identifying the channel on which to
      %         output.
      
      if ( ~ischar(id) )
        id = num2str( id );
      end
      assert( any(strcmp(obj.plex_ids, id)), 'Unrecognized plex id.' );
      obj.write( id );
    end
  end  
  
end