classdef BrainsServer < handle
  
  properties
    tcp;
    client_address;
    port;
    state_num;
    coordinates = cell( 1, 2 );
    fix_met;
    chosen_option;
    instructions = {};
    next_instruction_ready = true;
    CHARS = struct( 'next_instruction_ready', '*' );
  end
  
  methods
    function obj = BrainsServer( client_address, port )
      
      %   BRAINSSERVER -- Instantiate a BrainsServer object.
      %
      %     IN:
      %       - `client_adress` (char) -- E.g., '127.0.0.1'
      %       - `port` (double) -- E.g., 55000
      
      obj.tcp = tcpip( client_address, port, 'NetworkRole', 'server' );
      obj.client_address = client_address;
      obj.port = port;
    end
    
    function listen(obj)
      
      %   LISTEN -- Start the server.
      
      fopen( obj.tcp );
    end
    
    function update(obj)
      
      obj.handle_receipt();
      if ( ~obj.next_instruction_ready ), return; end;
      if ( isempty(obj.instructions) ), return; end;
      obj.next_instruction_ready = false;
      latest = obj.instructions{1};
      func = latest{1};
      args = latest{2};
      obj.instructions(1) = [];
      func( obj, args{:} );
      fwrite( obj.tcp, real(obj.CHARS.next_instruction_ready) );
    end
    
    function handle_receipt(obj)
      
      if ( obj.tcp.BytesAvailable <= 0 ), return; end;
      response = fread( obj.tcp, obj.tcp.BytesAvailable );
      identifier = char( response(1) );
      switch ( identifier )
        case '*'
          disp( 'updated ready state' );
          obj.next_instruction_ready = true;
        case 'X'
          disp( 'updated coordinates' );
          obj.coordinates{2}.X = response(2);
          obj.coordinates{2}.Y = response(3);
          fwrite( obj.tcp, real(obj.CHARS.next_instruction_ready) );
        otherwise
          error( 'Unrecognized receipt identifer ''%s''', identifier );
      end 
    end
  end
  
end