%%  required measurements
%
% a) bounding-box vertices with M1 eye as origin, in real units
% b) roi vertices relative to bounding-box, in real units, with top-left as
%   origin
% c) x-distance from left-edge of monitor to eye, in real units
% d) y-distance from top-edge of monitor to eye, in real units
% e) z-distance from eye to monitor, in real units
% f) z-distance from eye to bounding-box (m2), in real units
% g) dimensions of screen, in real units
%   
%   
% h) dimensions of screen, in pixels
% 

%%

import brains.util.gaze.*;

scr_index = 0;
manager = ScreenManager();
win = manager.open_window( scr_index, [0, 0, 0], [0, 0, 800, 600] );

%

screen_dims_cm = [8.375, 6.125];
z_near_cm = 10;
z_far_cm = 50;

stim_width_cm = 5;
stim_height_cm = 5;

roi1_local_verts = [1, .5, 4.5, 1.5];
roi2_local_verts = [1, 3, 2, 5];
% roi1_local_verts = [ 1, 1, 4, 4 ];

opts = struct();

opts.dist_to_monitor_cm = z_near_cm;
opts.dist_to_roi_cm = z_far_cm;
opts.x_dist_to_monitor_cm = screen_dims_cm(1) / 2;
opts.y_dist_to_monitor_cm = screen_dims_cm(2) / 2;
opts.screen_dims_cm = screen_dims_cm;

dims = get_reprojected_dimensions(stim_width_cm, stim_height_cm, z_far_cm, z_near_cm);
pixel_dims = get_pixel_coords_from_dimensions(dims, screen_dims_cm, win.rect);
img_verts = get_rect_verts_from_dimensions( pixel_dims, win.rect );

full_img = win.Rectangle( 0 );
full_img.vertices = img_verts;
full_img.color = [255, 0, 0];

roi1_verts = get_fractional_vertices( roi1_local_verts, [stim_width_cm, stim_height_cm] );
roi2_verts = get_fractional_vertices( roi2_local_verts, [stim_width_cm, stim_height_cm] );

% all_rois = { roi1_verts, roi2_verts };
% all_local_rois = { roi1_local_verts, roi2_local_verts };

all_rois = { roi1_verts };
all_local_rois = { roi1_local_verts };

eye_origin_far_roi_rects = cell( size(all_rois) );
roi_rects = cell( size(all_rois) );

eye_origin_far_img_rect = [-stim_width_cm/2, -stim_height_cm/2, stim_width_cm/2, stim_height_cm/2];

for i = 1:numel(roi_rects)
  current = all_rois{i};
  current_local = all_local_rois{i};
  current_rect = get_pixel_verts_from_fraction( img_verts, current );
  roi_rects{i} = win.Rectangle( 0 );
  roi_rects{i}.color = [ 0, 0, 255 ];
  roi_rects{i}.vertices = current_rect;
  
  eye_origin_local_roi = get_pixel_verts_from_fraction( eye_origin_far_img_rect, current );
  
  eye_origin_far_roi_rects{i} = get_pixel_verts_from_fraction( eye_origin_far_img_rect, current );
end

did_draw = false;
pixel_coords = zeros( 1, 2 );

while ( true )
  [key_pressed, ~, key_code] = KbCheck();
  if ( key_pressed )
    if ( key_code(conf.INTERFACE.stop_key) ), break; end;
  end 
  
  [pixel_coords(1), pixel_coords(2)] = GetMouse();
  
  in_bounds = debug__test_roi_2( pixel_coords, win.rect, eye_origin_far_roi_rects{1}, opts );
  
  if ( in_bounds )
    disp( 'IN BOUNDS!' );
  else
    disp( '--' );
  end
  
  if ( ~did_draw )
    full_img.draw();
    cellfun( @draw, roi_rects );
    Screen( 'Flip', win.index );
    did_draw = true;
  end
end

win.close();