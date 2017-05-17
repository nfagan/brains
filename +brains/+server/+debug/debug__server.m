clear all;
clc;

% address = '172.23.7.165';
address = '127.0.0.1';
port = 55e3;

% brains.server.debug.debug__master( address, port );
brains.server.debug.debug__await_feedback( true, address, port );

%%

clear all;
clc;

client_address = '0.0.0.0';
port = 55e3;

server = brains.server.BrainsServer( client_address, port );
server.listen();

interval = 5;
total_time = 20;
interval_timer = tic;
timeout_timer = tic;

while ( true )
  
  if ( toc(interval_timer) > interval )
    interval_timer = tic;
  end
  
  if ( toc(timeout_timer) > total_time )
    break;
  end
  
  server.update();
%   if ( ~isempty(server.coordinates{2}) )
%     disp( server.coordinates );
%   end
end