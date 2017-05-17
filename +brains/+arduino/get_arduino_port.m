function port = get_arduino_port()

%   GET_ARDUINO_PORT -- Search for the port on which an Arduino is
%     connected.
%
%     The Arduino must be loaded with a slave.ino or master.ino file, as
%     found in the communicator repository.

n_ports = 6;
messages = { struct('message', 'NULL', 'char', '!') };
baud_rate = 115200;
found_port = false;

for i = 1:n_ports
  port = sprintf( 'COM%d', i );
  try
    comm = Communicator( messages, port, baud_rate );
    found_port = true;
    comm.stop();
  catch err
    continue;
  end
  if ( found_port ), break; end
end

if ( ~found_port )
  error( ['Could not locate any Arduinos. If an Arduino is plugged in,' ...
    , ' it must be setup with a slave.ino or master.ino file.'] );
end

end