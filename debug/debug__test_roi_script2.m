import brains.util.gaze.*;

gaze_info = struct();
gaze_info.dist_to_monitor_cm = 62.5;
gaze_info.x_dist_to_monitor_cm = 50;
gaze_info.y_dist_to_monitor_cm = 12.5;
gaze_info.screen_dims_cm = [111.3, 30.5];
gaze_info.dist_to_roi_cm = 140;

x_roi_shift = 0;
y_roi_shift = -2;

% roi1_local_verts = [0.7, 1.5, 14.7, 6.6]; % eyes
roi1_local_verts = [6, 7.5, 10.5, 10.6];  % nose
% roi1_local_verts = [0, 0, 16, 16];  % image
% roi1_local_verts = [3.9, 11.8, 12.2, 16]; % mouth

roi_info = struct();
% roi_info.eye_origin_far_img_rect = [-8+x_roi_shift, -8+y_roi_shift, 8+x_roi_shift, 8+y_roi_shift];
roi_info.eye_origin_far_img_rect = [1.5, -11, 17.5, 5];
roi_info.local_verts = roi1_local_verts;
roi_info.stim_width_cm = 16;
roi_info.stim_height_cm = 16;
roi_info.local_fractional_verts = ...
  get_fractional_vertices( roi_info.local_verts, [roi_info.stim_width_cm, roi_info.stim_height_cm] );
roi_info.eye_origin_far_verts = ...
  get_pixel_verts_from_fraction( roi_info.eye_origin_far_img_rect, roi_info.local_fractional_verts );

scr_index = 0;
manager = ScreenManager();
win = manager.open_window( scr_index, [0, 0, 0], [0, 0, 10, 10] );

reported_win_rect = [0, 0, 3072, 768];

tracker = EyeTracker('a.edf', cd, win.index );
tracker.bypass = false;
assert( tracker.link_gaze() );
tracker.start_recording();

while ( true )
  [key_pressed, ~, key_code] = KbCheck();
  if ( key_pressed )
    if ( key_code(conf.INTERFACE.stop_key) ), break; end;
  end 
  
  tracker.update_coordinates();
  pixel_coords = tracker.coordinates;
  if ( isempty(pixel_coords) ), continue; end;
  
%   disp( pixel_coords );
  
  in_bounds = debug__test_roi_2( pixel_coords, reported_win_rect, roi_info.eye_origin_far_verts, gaze_info );
  
  if ( ~in_bounds )
    disp( '-' );
  end
  
%   if ( in_bounds )
%     disp( 'IN BOUNDS!' );
%   else
%     disp( '--' );
%   end
end

tracker.stop_recording();
win.close();