clear all;
clc;

% address = '172.23.7.165';
address = '127.0.0.1';
port = 55e3;

% brains.server.debug.debug__master( address, port );
brains.server.debug.debug__await_feedback( false, address, port );

%%

clear all;
clc;

server_address = '127.0.0.1';
port = 55e3;

client = brains.server.BrainsClient( server_address, port );
client.start();

interval = 5;
total_time = 20;
interval_timer = tic;
timeout_timer = tic;
i = 1;

while ( true )
  
  if ( toc(interval_timer) > interval )
    i = i + 1;
    interval_timer = tic;
%     disp( 'sent' );
    client.send_gaze( [100;200] * i );
  end
  
  if ( toc(timeout_timer) > total_time )
    break;
  end
  
  client.update();
end