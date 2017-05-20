classdef IPInterface < handle
  
  properties
    tcp;
    address;
    port;
    network_role;
    outbox = {};
    can_send = true;
    is_open = false;
    PACKET_SIZE = 32;
    defaults;
    DATA;
    CHARS = struct( ...
          'can_send',   '*',  'can_receive', '%' ...
        , 'gaze_s',     'X',  'gaze_r', 'x' ...
        , 'state_s',    'S',  'state_r', 's' ...
        , 'choice_s',   'C',  'choice_r', 'c' ...
    );
    TIMEOUTS = struct( 'send_ready', 5 );
    DEBUG = false;
  end
  
  methods
    function obj = IPInterface(address, port, network_role)
      
      %   IPINTERFACE -- Instantiate an IPInterface object.
      %
      %     IN:
      %       - `address` (char) -- Address to which to connect; e.g.,
      %         '127.0.0.1'
      %       - `port` (double) -- Port to which to connect; e.g., 55000
      %       - `network_role` (char) -- 'server' or 'client'
      
      obj.tcp = tcpip( address, port, 'NetworkRole', network_role );
      obj.tcp.InputBufferSize = obj.PACKET_SIZE * 8;
      obj.tcp.OutputBufferSize = obj.PACKET_SIZE * 8;
      obj.address = address;
      obj.port = port;
      obj.network_role = network_role;
      
      obj.defaults.DATA.gaze = [ NaN; NaN ];
      obj.defaults.DATA.state = NaN;
      obj.defaults.DATA.choice = NaN;
      obj.defaults.DATA.fix_met = NaN;
      obj.default();
    end
    
    function start(obj)
      
      %   START -- Open the tcpip object.
      
      fopen( obj.tcp );
      obj.is_open = true;
    end
    
    function close(obj)
      
      %   CLOSE -- Close the tcpip object.
      
      fclose( obj.tcp );
      obj.is_open = false;
    end
    
    function default(obj)
      
      %   DEFAULT -- Reset the object.
      
      obj.DATA = obj.defaults.DATA;
    end
    
    function update(obj)
      
      %   UPDATE -- Respond to new BytesAvailable and / or update the
      %     outbox.
      
      obj.handle_receipt();
      obj.update_outbox();
    end
    
    function update_outbox(obj)
      
      %   UPDATE_OUTBOX -- Handle pending sent instructions.
      
      outb = obj.outbox;
      if ( isempty(outb) ), return; end;
      if ( ~obj.can_send ), return; end;
      obj.can_send = false;
      latest = outb{1};
      func = latest{1};
      args = latest{2};
      obj.outbox(1) = [];
      func( obj, args{:} );
    end
    
    function send(obj, kind, data)
      
      %   SEND -- Queue the sending of data of a specific kind.
      %
      %     IN:
      %       - `kind` (char) -- e.g., 'gaze'
      %       - `data` (double)
      
      switch ( kind )
        case 'gaze'
          id = obj.CHARS.gaze_s;
        case 'state'
          id = obj.CHARS.state_s;
        case 'choice'
          id = obj.CHARS.choice_s;
        otherwise
          error( 'Unrecognized data-kind ''%s''', kind );
      end
      buffer = zeros( obj.PACKET_SIZE, 1 );
      buffer(1:numel(data)+1) = [ real(id); data(:) ];
      obj.outbox{end+1} = { @send_, {buffer} };
    end
    
    function send_(obj, data)
      
      %   SEND_ -- Private. Immediately send data.
      %
      %     IN:
      %       - `data` (double)
      
      fwrite( obj.tcp, data, 'double' );
    end
    
    function send_when_ready(obj, varargin)
      
      %   SEND_WHEN_READY -- Wait until data can be sent, then send the
      %     data.
      %
      %     IN:
      %       - `varargin` (cell array) -- Inputs to be passed to send().
      %
      %     See also send
      
      timeout_check = tic;
      while ( ~obj.can_send )
        obj.update();
        if ( toc(timeout_check) > obj.TIMEOUTS.send_ready )
          error( ['Did not receive permission to send data within %0.1f' ...
            , ' seconds.'], obj.TIMEOUTS.send_ready );
        end
      end
      obj.send( varargin{:} );
      obj.update();
    end
    
    function request(obj, kind)
      
      %   REQUEST -- Request a kind of data.
      %
      %     IN:
      %       - `kind` (char) -- Kind of data to request.
      
      switch ( kind )
        case 'gaze'
          id = obj.CHARS.gaze_r;
        case 'state'
          id = obj.CHARS.state_r;
        case 'choice'
          id = obj.CHARS.choice_r;
        otherwise
          error( 'Unrecognized data-kind ''%s''', kind );
      end
      buffer = zeros( 32, 1 );
      buffer(1) = real( id );
      obj.outbox{end+1} = { @send_, {buffer} };
    end
    
    function handle_receipt(obj)
      
      %   HANDLE_RECEIPT -- Respond to new bytes available.
      
      response = obj.read_if_available();
      if ( isempty(response) ), return; end;
      identifier = char( response(1) );
      chars = obj.CHARS;
      switch ( identifier )
        % - sent acknowledgement
        case chars.can_send
          obj.assert__received_n_values( response, 32, 'the acknowledgement' );
          obj.can_send = true;
          
        % - incoming gaze data
        case chars.gaze_s
          handle_data_send( 'gaze', response(2:3) );
          
        % - outgoing gaze data
        case chars.gaze_r
          handle_data_receipt( 'gaze' );
        
        % - incoming state data
        case chars.state_s
          handle_data_send( 'state', response(2) );
          
        % - outgoing state data
        case chars.state_r
          handle_data_receipt( 'state' );
          
        % - incoming choice data
        case chars.choice_s
          handle_data_send( 'choice', response(2) );
          
        % - outgoing choice data
        case chars.choice_r
          handle_data_receipt( 'choice' );
          
        otherwise
          error( 'Unrecognized receipt identifer ''%s''', identifier );
      end
      
      function handle_data_send( kind, data )
        
        %   HANDLE_DATA_SEND -- Handle the receipt of a send character.
        %
        %     IN:
        %       - `kind` (char) -- Kind of data; e.g., 'choice'
        %       - `data` (double) -- Data to assign.
        
        msg = sprintf( 'the sent %s data', kind );
        obj.assert__received_n_values( response, 32, msg );
        obj.DATA.( kind ) = data;
        obj.receipt_ready_();
      end      
      function handle_data_receipt( kind )
        
        %   HANDLE_DATA_RECEIPT -- Handle the receipt of a receipt
        %     character.
        %
        %     IN:
        %       - `kind` (char) -- Kind of data; e.g., 'choice'
        
        msg = sprintf( 'the sent %s data', kind );
        obj.assert__received_n_values( response, 32, msg );
        obj.send( kind, obj.DATA.(kind) );
        obj.consume( kind );
      end
    end
    
    function response = read_if_available(obj)
      
      %   READ_IF_AVAILABLE -- Return data if it has been sent to the
      %     object.
      %
      %     OUT:
      %       - `response` (double, []) -- Read data, or [] if no bytes are
      %         available.
      
      response = [];
      if ( obj.tcp.BytesAvailable <= 0 ), return; end;
      response = fread( obj.tcp, obj.tcp.BytesAvailable/8, 'double' );
    end
    
    function receipt_ready(obj)
      
      %   RECEIPT_READY -- Communicate that the object is ready to receive
      %     new data.
      
      obj.outbox{end+1} = { @receipt_ready_, {} };
    end
    
    function receipt_ready_(obj)
      
      %   RECEIPT_READY_ -- Private receipt_ready.
      
      buffer = zeros( obj.PACKET_SIZE, 1 );
      buffer(1) = real( obj.CHARS.can_send );
      fwrite( obj.tcp, buffer(:), 'double' );
    end
    
    function data = consume(obj, kind)
      
      %   CONSUME -- Obtain data, then reset the data to the default value.
      %
      %     IN:
      %       - `kind` (char) -- Data field.
      %     OUT:
      %       - `data` (double)
      
      fs = fieldnames( obj.DATA );
      assert( any(strcmp(fs, kind)), ['The requested data-kind ''%''' ...
        , ' does not exist.'], kind );
      data = obj.DATA.(kind);
      obj.DATA.(kind) = obj.defaults.DATA.(kind);
    end
  end
  
  methods ( Static = true )
    
    function assert__received_n_values( received, expected_n, var_name )
      
      %   ASSERT__RECEIVED_N_VALUES -- Ensure a specific number of values
      %     were received.
      %
      %     IN:
      %       - `received` (double) -- Vector of received values.
      %       - `expected_n` (double) -- Scalar number of expected values.
      %       - `var_name` (char) |OPTIONAL| -- Optionally provide a more
      %         descriptive variable name in case the assertion fails.
      
      if ( nargin < 3 ), var_name = 'the received data'; end;
      msg = sprintf( ['Expected %s to have %d elements,' ...
        , ' but %d were present.'], var_name, expected_n, numel(received) );
      assert( numel(received) == expected_n, msg );
    end
    
    function assert__received_between_n_values( received, start, stop, var_name )
      
      %   ASSERT__RECEIVED_N_VALUES -- Ensure a specific number of values
      %     were received.
      %
      %     IN:
      %       - `received` (double) -- Vector of received values.
      %       - `start` (double) -- Scalar minimum number of expected
      %         values.
      %       - `stop` (double) -- Scalar maximum number of expected
      %         values.
      %       - `var_name` (char) |OPTIONAL| -- Optionally provide a more
      %         descriptive variable name in case the assertion fails.
      
      if ( nargin < 4 ), var_name = 'the received data'; end;
      N = numel( received );
      msg = sprintf( ['Expected %s to have between %d and %d elements,' ...
        , ' but %d were present.'], var_name, start, stop, N );
      assert( N >= start && N <= stop, msg );
    end
  end
end