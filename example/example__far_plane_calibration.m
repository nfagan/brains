function example__far_plane_calibration()

conf = brains.config.load();
data_dir = fullfile( brains.util.get_latest_data_dir_path(), 'calibration' );
calib_n = brains.util.get_far_plane_calibration_number();
key_filename = sprintf( 'far_plane_calibration%d.mat', calib_n );
calibration_type = conf.CALIBRATION.far_plane_type;

save_data = true;

if ( save_data && exist(data_dir, 'dir') ~= 7 ), mkdir( data_dir ); end

light_dur = 1000;

switch ( calibration_type )
  case 'outer'
    key_map = brains.arduino.calino.get_outer_key_code_led_index_map();
  case 'inner'
    key_map = brains.arduino.calino.get_inner_key_code_led_index_map();
  otherwise
    error( 'Unrecognized calibration type "%s".', calibration_type );
end

keys = brains.calibrate.calibrate_far_plane( key_map, light_dur );

if ( save_data )
  save( fullfile(data_dir, key_filename), 'keys', 'key_map', 'conf' );
end