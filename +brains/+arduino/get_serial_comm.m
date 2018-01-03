function comm = get_serial_comm()

%   GET_SERIAL_COMM -- Get an instantiated BrainsSerialManagerPaired
%     object.
%
%     OUT:
%       - `comm` (BrainsSerialManagerPaired)

import brains.arduino.BrainsSerialManagerPaired;

conf = brains.config.load();

SERIAL = conf.SERIAL;

is_master = conf.INTERFACE.is_master_arduino;
is_m1 = conf.INTERFACE.IS_M1;

if ( is_master )
  role = 'master';
else
  role = 'slave';
end

if ( is_m1 )
  m_str = 'M1';
else
  m_str = 'M2';
end

port = SERIAL.ports.reward;
rwd_channels = SERIAL.reward_channels;
messages = [ SERIAL.messages.shared; SERIAL.messages.(m_str) ];
comm = BrainsSerialManagerPaired( port, messages, rwd_channels, role );

end