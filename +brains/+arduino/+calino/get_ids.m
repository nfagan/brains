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
roi_ids.social_control_dots_left = 'x';
roi_ids.social_control_dots_right = 'z';

stim_params = struct();
stim_params.stim_stop_start = 'r';
stim_params.global_stim_timeout = 'q';
stim_params.probability = 'y';
stim_params.frequency = 'u';
stim_params.protocol = 'i';
stim_params.event = 'w';
stim_params.max_n = 'v';
stim_params.print_n_stim = 'P';
stim_params.radius = '1';

stim_protocols = struct();
stim_protocols.mutual_event = 0;
stim_protocols.m1_exclusive_event = 1;
stim_protocols.m2_exclusive_event = 2;
stim_protocols.exclusive_event = 3;
stim_protocols.any_event = 4;
stim_protocols.probabilistic = 5;
stim_protocols.m1_radius_excluding_inner_rect = 6;
stim_protocols.m2_radius_excluding_inner_rect = 7;

ids.monkey = monk_ids;
ids.roi = roi_ids;
ids.stim_params = stim_params;
ids.stim_protocols = stim_protocols;

end