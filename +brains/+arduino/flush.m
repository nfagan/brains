function flush(index, duration)

if ( nargin == 0 )
  index = 1;
  duration = 10e3;
elseif ( nargin < 2 )
  duration = 10e3;
end

reward_messages = { ...
  struct('message', 'REWARD1', 'char', 'A'), ...
  struct('message', 'REWARD2', 'char', 'B') ...
};

port = brains.arduino.get_arduino_port();
baud_rate = 115200;

comm = Communicator( reward_messages, port, baud_rate );

comm.send_reward_size( reward_messages{index}.char, duration );

message = sprintf( 'REWARD%d', index );

comm.send( message );


end