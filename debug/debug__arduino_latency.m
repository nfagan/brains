ardu = brains.arduino.get_serial_comm();
ardu.start();

N = 5000;

results = zeros( 1, N );

for i = 1:N
  received_response = false;
  flushinput( ardu.comm );
  flushoutput( ardu.comm );
  start = tic;
  ardu.sync_pulse( 1 );
  while ( ~received_response )
    received_response = ardu.comm.BytesAvailable > 0;
  end
  results(i) = toc( start );
end

fprintf( '\n Average round trip latency: %0.4f ms', mean(results) * 1e3 );
fprintf( '\n Std dev round trip latency: %0.4f ms', std(results) * 1e3 );

ardu.close();
clear ardu;



