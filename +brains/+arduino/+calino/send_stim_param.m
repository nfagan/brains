function send_stim_param(comm, roi_id, param_name, param)

%   SEND_STIM_PARAM -- Send stimulation parameter to arduino.

ids = brains.arduino.calino.get_ids();

is_stim_param_id = ids.stim_param;
param_id = ids.(param_name);

cmd = sprintf( '%s%s%s%d', is_stim_param_id, roi_id, param_id, param );

fprintf( comm, cmd );

brains.arduino.calino.await_char( comm, ids.ack, 'Incorrect stim param ack character.' );

end