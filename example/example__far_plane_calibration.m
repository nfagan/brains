function example__far_plane_calibration()

conf = brains.config.load();
date_dir = datestr( now, 'mmddyy' );
data_dir = fullfile( conf.IO.repo_folder, 'brains', 'data', date_dir, 'calibration' );
key_filename = 'far_plane_calibration.mat';

save_data = true;

if ( save_data && exist(data_dir, 'dir') ~= 7 ), mkdir( data_dir ); end

% targets = [ 1, 2 ];
targets = [ 1:7 ];
light_dur = 1000;

keys = brains.calibrate.calibrate_far_plane( targets, light_dur );

if ( save_data )
  save( fullfile(data_dir, key_filename), 'keys' );
end