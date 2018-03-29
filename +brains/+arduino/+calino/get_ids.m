function ids = get_ids()

%   See brains_eyelink.ino for mapping.

ids = struct();
ids.ack = 'a';
ids.error = '!';
ids.bounds = 'o';
ids.stim_param = 't';

monk_ids = struct();
monk_ids.m1 = 'j';
monk_ids.m2 = 'k';

roi_ids = struct();
roi_ids.eyes = 'e';
roi_ids.mouth = 'm';
roi_ids.screen = 's';
roi_ids.face = 'f';

stim_params = struct();
stim_params.probability = 'y';
stim_params.frequency = 'u';
stim_params.protocol = 'i';

ids.monkey = monk_ids;
ids.roi = roi_ids;
ids.stim_params = stim_params;

end