function flush(indices, duration)

%   FLUSH -- Open the solenoid(s) for a long time.
%
%     IN:
%       - `indices` (double) -- Indices of channels to flush. Defaults to
%         1.
%       - `duration` (double) -- Length of time to leave the channels open,
%         in milliseconds. Defaults to 10000.

if ( nargin == 0 )
  indices = 1;
  duration = 10e3;
elseif ( nargin == 1 )
  duration = 10e3;
end

comm = brains.arduino.get_serial_comm();
comm.start();

for i = 1:numel(indices)
  comm.reward( indices(i), duration );
end

comm.close();

end