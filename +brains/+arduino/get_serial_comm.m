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

if ( is_master )
  m_str = 'M1';
  role = 'master';
else
  m_str = 'M2';
  role = 'slave';
end

port = SERIAL.ports.(m_str);
rwd_channels = SERIAL.reward_channels.(m_str);
rwd_channels = fliplr( rwd_channels );
messages = [ SERIAL.messages.shared; SERIAL.messages.(m_str) ];

comm = BrainsSerialManagerPaired( port, messages, rwd_channels, role );

end