function cmd = get_stim_param_cmd(roi_name, param_name, param)

ids = brains.arduino.calino.get_ids();

is_stim_param_id = ids.stim_param;
param_id = ids.stim_params.(param_name);
roi_id = ids.roi.(roi_name);

cmd = sprintf( '%s%s%s%d', is_stim_param_id, param_id, roi_id, param );

end