classdef BrainsClient < handle
  
  properties
    tcp;
    server_address;
    port;
    instructions;
    next_instruction_ready = true;
    CHARS = struct( 'next_instruction_ready', '*' );
  end
  
  methods    
    function obj = BrainsClient(server_address, port)
      obj.tcp = tcpip( server_address, port );
      obj.server_address = server_address;
      obj.port = port;
    end
    
    function start(obj)
      
      %   START -- Start the client;
      
      fopen( obj.tcp );
    end
    
    function update(obj)
      
      obj.update_ready_state();
      if ( ~obj.next_instruction_ready ), return; end;
      if ( isempty(obj.instructions) ), return; end;
      obj.next_instruction_ready = false;
      latest = obj.instructions{1};
      func = latest{1};
      args = latest{2};
      obj.instructions(1) = [];
      func( obj, args{:} );
%       fwrite( obj.tcp, real(obj.CHARS.next_instruction_ready) );
    end
    
    function update_ready_state(obj)
      
      if ( obj.next_instruction_ready ), return; end;
      if ( obj.tcp.BytesAvailable <= 0 ), return; end;
      response = char( fread(obj.tcp, 1) );
      err_msg = sprintf( ['Expected to receive the feedback character ''%s'',' ...
        , ' but received ''%s''.'], obj.CHARS.next_instruction_ready, response );
      assert( isequal(response, obj.CHARS.next_instruction_ready), err_msg );
      obj.next_instruction_ready = true;
    end
    
    function send_gaze(obj, gaze)
      
      obj.instructions{end+1} = { @send_gaze_, {gaze} };      
    end
    
    function send_gaze_(obj, gaze)
      
      disp( 'Sent gaze' );
      fwrite( obj.tcp, [real('X'); gaze(:)] );
    end
  end
  
end