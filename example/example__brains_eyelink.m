import brains.arduino.calino.send_bounds;
import brains.arduino.calino.get_ids;
import brains.arduino.calino.send_stim_param;

brains.arduino.calino.close_ports();

port = 'COM6';
baud = 9600;

comm = brains.arduino.calino.init_serial( port, baud );
comm.BytesAvailableFcn = @(x) fprintf('%s', x);

send_bounds( comm, 'm1', 'screen', [0, 0, 1024, 768] );
send_bounds( comm, 'm2', 'screen', [0, 0, 1024, 768] );
send_bounds( comm, 'm1', 'eyes', [400, 400, 401, 401] );
send_bounds( comm, 'm2', 'eyes', [100, 0, 101, 1024*3] );
send_bounds( comm, 'm1', 'face', [1024, 0, 100, 200] );
send_bounds( comm, 'm2', 'mouth', [0, 0, 100, 200] );

%%

ids = brains.arduino.calino.get_ids();

send_stim_param( comm, 'all', 'probability', 100 );
send_stim_param( comm, 'all', 'frequency', 100 );
send_stim_param( comm, 'all', 'stim_stop_start', 1 );
send_stim_param( comm, 'all', 'protocol', ids.stim_protocols.probabilistic );
send_stim_param( comm, 'all', 'global_stim_timeout', 1 );

%%

fprintf( comm, 'p' );

while ( comm.BytesAvailable == 0 )
end

s = {};

while ( comm.BytesAvailable > 0 )
  s{end+1} = fscanf( comm );
end

disp( strjoin(s, '\n') );