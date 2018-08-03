function comm = get_dummy_serial_comm()

import brains.arduino.BrainsSerialManagerPaired;

comm = BrainsSerialManagerPaired( '~', struct(), {}, 'master' );
comm.bypass = true;


end