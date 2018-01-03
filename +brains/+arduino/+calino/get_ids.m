function ids = get_ids()

%   See brains_eyelink.ino for mapping.

ids = struct();
ids.ack = 'a';
ids.bounds = 'o';

monk_ids = struct();
monk_ids.m1 = 'j';
monk_ids.m2 = 'k';

roi_ids = struct();
roi_ids.eyes = 'e';
roi_ids.mouth = 'm';
roi_ids.screen = 's';
roi_ids.face = 'f';

ids.monkey = monk_ids;
ids.roi = roi_ids;

end