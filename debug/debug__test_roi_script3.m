%%

screen_pixel_dimensions = [ 0, 0, 3072, 768 ];
screen_width_cm = 111.3;
screen_height_cm = 30.0;

x_dist_to_monitor_m2_cm = 60.0;
y_dist_to_ground_m2 = 69.1;
m2_z_dist_to_monitor = 52.7;
inter_monitor_gap_cm = 17;

% y_dist_to_ground_m1 = 74.3;
% y_dist_to_ground_m2 = 73.1;
y_dist_to_ground_m1 = 71.1;

screen_dist_to_ground_cm = 85.8;
x_dist_to_monitor_cm = 51.0;
y_dist_to_monitor_cm = screen_dist_to_ground_cm - y_dist_to_ground_m1;
z_dist_to_monitor_cm = 65.5;
z_dist_to_m2 = m2_z_dist_to_monitor + z_dist_to_monitor_cm + inter_monitor_gap_cm;

eye_relative_m2_left = screen_width_cm - ( x_dist_to_monitor_m2_cm + x_dist_to_monitor_cm );
eye_relative_m2_bottom = y_dist_to_ground_m2 - y_dist_to_ground_m1;
face_height_cm = 16;
face_width_cm = 16;

y_min = 10;
x_max = 12.9;
y_max = 13.1;
x_min = 2.5;

% roi = [ eye_relative_m2_left, eye_relative_m2_bottom, eye_relative_m2_left + face_width_cm, eye_relative_m2_bottom + face_height_cm ];

roi = [ eye_relative_m2_left+x_min, eye_relative_m2_bottom+y_min, eye_relative_m2_left+x_max, eye_relative_m2_bottom+y_max ];

%%
tracker = EyeTracker( '1.edf', cd, 0 );
tracker.bypass = false;
tracker.link_gaze();
tracker.start_recording();

while ( true )
  
  tracker.update_coordinates();
  
%   disp( tracker.coordinates );
  
  [key_down, ~, key_code] = KbCheck();
  
  if ( key_code(KbName('escape')) )
    fprintf( '\nDone' );
    break; 
  end
  
  if ( isempty(tracker.coordinates) ), continue; end
  
  screen_fractional_x = tracker.coordinates(1) / (screen_pixel_dimensions(3) - screen_pixel_dimensions(1));
  screen_fractional_y = tracker.coordinates(2) / (screen_pixel_dimensions(4) - screen_pixel_dimensions(2));

  screen_dist_x_cm = screen_width_cm * screen_fractional_x;
  screen_dist_y_cm = screen_height_cm * screen_fractional_y;

  eye_relative_x_cm = screen_dist_x_cm - x_dist_to_monitor_cm;
  eye_relative_y_cm = y_dist_to_monitor_cm - screen_dist_y_cm;

  projected_x_cm = ( eye_relative_x_cm * z_dist_to_m2 ) / z_dist_to_monitor_cm;
  projected_y_cm = ( eye_relative_y_cm * z_dist_to_m2 ) / z_dist_to_monitor_cm;

  coords = [ projected_x_cm, projected_y_cm ];
  
%   if ( coords(1) >= roi(1) && coords(1) <= roi(3) )
%     disp( 'in bounds x!' );
%   else
%     disp( '--' );
%   end
  if ( coords(2) >= roi(2) && coords(2) <= roi(4) )
    disp( 'in bounds y!' );
  else
    disp( '--' );
  end
  
end

tracker.stop_recording();