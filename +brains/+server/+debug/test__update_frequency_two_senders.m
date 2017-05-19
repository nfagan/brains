function test__update_frequency_two_senders( is_server, address, port )

if ( nargin == 1 )
  if ( is_server )
    address = '0.0.0.0';
  else
    address = '127.0.0.1';
  end
  port = 55e3;
end

if ( is_server )
  comm = brains.server.Server( address, port );
  comm.start();
else
  comm = brains.server.Client( address, port );
  WaitSecs( 2 );
  comm.start();
end

i = 0;
total_time = 20;
total_timer = tic;
first_message = true;

if ( is_server )
  gaze_data = [200; 300];
else gaze_data = [400; 500];
end

msg_times = NaN( 10e3, 1 );

while ( true )
  comm.update();
  if ( comm.can_send )
    if ( first_message )
      first_message_timer = tic;
      first_message_time = toc( total_timer );
      first_message = false;
    end;
    comm.send( 'gaze', gaze_data );
    i = i + 1;
    msg_times(i) = toc( first_message_timer );
  end
  if ( toc(total_timer) > total_time ), break; end
end

completed_time = toc( total_timer );

if ( is_server )
  while ( comm.tcp.BytesAvailable > 0 )
    comm.update();
  end
end

comm.update();

disp( 'Instruction rate:' );
fprintf( '\n%0.4f ops/second \n\n', i / (completed_time-first_message_time) );
disp( 'Average inter-instruction interval (ms):' );
disp( num2str(1e3*mean(diff(msg_times(~isnan(msg_times))))) );
disp( 'Gaze:' );
disp( comm.DATA.gaze );
disp( 'Number of iterations' );
disp( i );
disp( 'Number of instructions remaining:' );
disp( numel(comm.outbox) )
disp( 'Number completed instructions:' );
disp( i - numel(comm.outbox) );

end