function example__far_plane_calibration()

conf = brains.config.load();
data_dir = fullfile( brains.util.get_latest_data_dir_path(), 'calibration' );
calib_n = brains.util.get_far_plane_calibration_number();
key_filename = sprintf( 'far_plane_calibration%d.mat', calib_n );

save_data = true;

if ( save_data && exist(data_dir, 'dir') ~= 7 ), mkdir( data_dir ); end

% targets = [ 1, 2 ];
targets = [ 1:7 ];
light_dur = 1000;

keys = brains.calibrate.calibrate_far_plane( targets, light_dur );

if ( save_data )
  save( fullfile(data_dir, key_filename), 'keys' );
end