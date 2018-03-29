function send_stim_param(comm, roi_id, param)

%   SEND_STIM_PARAM -- Send stimulation parameter to arduino.

ids = brains.arduino.calino.get_ids();

stim_param_id = ids.stim_param;

cmd = sprintf( '%s%s%d', stim_param_id, roi_id, param );

fprintf( comm, cmd );

brains.arduino.calino.await_char( comm, ids.ack, 'Incorrect stim param ack character.' );

end