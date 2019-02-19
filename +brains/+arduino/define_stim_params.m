function stim_params = define_stim_params()

ids = brains.arduino.calino.get_ids();

stim_params = struct();
stim_params.use_stim_comm = false;  % whether to initialize stimulation arduino
stim_params.sync_m1_m2_params = false;  % whether to send m2's calibration data to m1
stim_params.probability = 50; % percent
stim_params.frequency = 15000;  % ISI, ms
% stim_params.max_n = intmax( 'int16' );  % maximum number of stimulations. max possible is intmax('int16');
stim_params.max_n = 10;
stim_params.active_rois = { 'eyes' }; % which rois will trigger stimulation
% stim_params.protocol = ids.stim_protocols.probabilistic;
stim_params.protocol = ids.stim_protocols.m1_exclusive_event;
% stim_params.protocol = ids.stim_protocols.m2_exclusive_event
% stim_params.protocol = ids.stim_protocols.mutual_event

end