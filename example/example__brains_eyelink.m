brains.arduino.calino.close_ports();

port = 'COM6';
baud = 9600;

comm = brains.arduino.calino.init_serial( port, baud );

brains.arduino.calino.send_bounds( comm, 'm1', 'screen', [0, 0, 1024, 768] );
brains.arduino.calino.send_bounds( comm, 'm2', 'screen', [0, 0, 1024, 768] );
brains.arduino.calino.send_bounds( comm, 'm1', 'eyes', [400, 400, 401, 401] );
brains.arduino.calino.send_bounds( comm, 'm2', 'eyes', [100, 0, 101, 1024*3] );
brains.arduino.calino.send_bounds( comm, 'm1', 'face', [1024, 0, 100, 200] );
brains.arduino.calino.send_bounds( comm, 'm2', 'mouth', [0, 0, 100, 200] );
% send_bounds( comm, 'm2', 'face', 0, 0, 400, 400 );


%%

fprintf( comm, 'p' );

while ( comm.BytesAvailable == 0 )
end

s = {};

while ( comm.BytesAvailable > 0 )
  s{end+1} = fscanf( comm );
end

disp( strjoin(s, '\n') );