function n = get_far_plane_calibration_number()

p = brains.util.get_latest_data_dir_path();

full_p = fullfile( p, 'calibration' );

if ( exist(full_p, 'dir') ~= 7 )
  n = 0;
  return;
end

mats = shared_utils.io.dirnames( full_p, '.mat' );

n = numel( mats );

end