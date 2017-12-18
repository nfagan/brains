conf = brains.config.load();
date_dir = datestr( now, 'mmddyy' );
data_dir = fullfile( conf.IO.repo_folder, 'brains', 'data', date_dir, 'calibration' );
key_file_name = 'far_plane_calibration.mat';

if ( exist(data_dir, 'dir') ~= 7 ), mkdir( data_dir ); end

targets = [ 1, 2 ];

keys = brains.calibrate.calibrate_far_plane( targets );

%%

save( fullfile(data_dir, key_file_name), 'keys' );