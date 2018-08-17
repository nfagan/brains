function send_stim_param(comm, roi_name, param_name, param)

%   SEND_STIM_PARAM -- Send stimulation parameter to arduino.

ids = brains.arduino.calino.get_ids();

if ( strcmp(roi_name, 'all') )
  rois = setdiff( fieldnames(ids.roi), 'screen' );
  for i = 1:numel(rois)
    brains.arduino.calino.send_stim_param( comm, rois{i}, param_name, param );
  end
  return;
end

is_stim_param_id = ids.stim_param;
param_id = ids.stim_params.(param_name);
roi_id = ids.roi.(roi_name);

cmd = sprintf( '%s%s%s%d', is_stim_param_id, param_id, roi_id, param );

fprintf( comm, cmd );

brains.arduino.calino.await_char( comm, ids.ack, 'Incorrect stim param ack character.' );

end