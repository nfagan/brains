comm = brains.arduino.get_serial_comm();
comm.start();

%%

index = 2;  %   1 or 2
duration = 2000;  % ms

comm.LED( index, duration );

%%

comm.close();
clear comm;