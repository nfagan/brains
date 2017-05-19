function test__one_sender( is_server, address, port )

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

i = 1;
total_time = 20;
send_interval = .001;
% update_interval = .001;
update_interval = 0;
update_interval_timer = tic;
total_timer = tic;
should_send = true;

while ( true )
  if ( ~is_server )
    if ( should_send )
      gaze = [200; 300] * i;
      comm.send( 'gaze', gaze );
%       comm.request_gaze();
      i = i + 1;
      send_interval_timer = tic;
    end
    should_send = toc( send_interval_timer ) > send_interval;
  end
  if ( update_interval > 0 )
    if ( toc(update_interval_timer) > update_interval )
      comm.update();
      update_interval_timer = tic;
    end
  else
    comm.update();
  end
  if ( toc(total_timer) > total_time )
    break;
  end
end

if ( is_server )
  while ( comm.tcp.BytesAvailable > 0 )
    comm.update();
  end
end

disp( 'Gaze:' );
disp( comm.DATA.gaze );
disp( 'Number of iterations' );
disp( i );
disp( 'Number of instructions remaining:' );
disp( numel(comm.outbox) )
disp( 'Number completed instructions:' );
disp( i - numel(comm.outbox) - 1 );

end