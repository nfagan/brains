function clock_sync(frequency)

%   CLOCK_SYNC -- Send a sync pulse to plexon every `frequency` seconds.
%
%     IN:
%       - `comm` (BrainsSerialManagerPaired)
%       - `frequency` (double)

comm = brains.arduino.get_serial_comm();
comm.start();

time = tic();

while ( true )
  if ( toc(time) >= frequency )
%     comm.sync_pulse( 1 );
    disp( 'rewarding' );
    comm.reward( 1, 100 );
    time = tic();
  end
end

end