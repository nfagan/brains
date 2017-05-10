classdef BrainsArduino < handle
  
  properties
    timer;
    comm;
    debounce_time = .001;
  end
  
  methods    
    function obj = BrainsArduino( comm )
      obj.comm = comm;
      obj.timer = tic;
    end
    
    function reset_(obj)

      %   RESET_ -- Reset the states and gaze data to their defaults.

      obj.comm.send_gaze( 'X', 0 );
      obj.comm.send_gaze( 'Y', 0 );
      obj.set_state( 0 );
    end
    
    function reset(obj)
      
      %   RESET -- Reset the states and gaze data to their defaults.
      
      obj.debounce( @reset_ );
    end
    
    function varargout = debounce(obj, func, varargin)
      
      %   DEBOUNCE -- Call functions no quicker than `obj.debounce_time` s.
      %
      %     IN:
      %       - `func` (function_handle)
      %       - `varargin` (/any/) -- Additional arguments to pass to func.
      %     OUT:
      %       - `varargout` (/any/) -- Any output arguments required by
      %         `func`.
      
      while ( toc(obj.timer) < obj.debounce_time )
        %   wait
      end
      [varargout{1:nargout()}] = func( varargin{:} );
      obj.timer = tic;
    end
  end
  
end