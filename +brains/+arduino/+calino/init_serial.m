function comm = init_serial(port, baud_rate)

if ( nargin < 2 )
  baud_rate = 115200;
end

comm = serial( port );
comm.BaudRate = baud_rate;

fopen( comm );

try
  brains.arduino.calino.await_char( comm, '*', 'Incorrect initialization character(s).' );
catch err
  if ( strcmp(comm.Status, 'open') )
    fclose( comm );
  end
  throw( err );
end

end