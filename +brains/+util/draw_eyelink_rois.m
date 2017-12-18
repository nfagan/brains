function draw_eyelink_rois(conf, tracker, dist_file, roi_file, screen_constants, other_monk, first_invoc)

if ( tracker.bypass ), return; end

if ( conf.INTERFACE.IS_M1 )
  win_rect = conf.SCREEN.rect.M1;
  dist_1 = dist_file.m1;
  dist_2 = dist_file.m2;
else
  win_rect = conf.SCREEN.rect.M2;
  dist_1 = dist_file.m2;
  dist_2 = dist_file.m1;
end

min_cm = -50;
max_cm = 50;

persistent adjusted_rois;

Eyelink( 'Command', 'clear_screen 0' );

pos = tracker.coordinates(:)';

if ( isempty(pos) ), return; end

fprintf( '\nX: %0.2f, Y: %0.2f', pos(1), pos(2) );

roi_m2_relative_m1 = roi_file.(other_monk);

[pos_m1_on_m2, origin_m2] = ...
  brains_analysis.gaze.process.get_projected_position_and_origin( dist_1, dist_2, pos, screen_constants );

frac_x = (pos_m1_on_m2(1) - min_cm) / (max_cm-min_cm);
frac_y = (pos_m1_on_m2(2) - min_cm) / (max_cm-min_cm);
frac_y = 1-frac_y;
pix_x = ((win_rect(3)-win_rect(1)) * frac_x);
pix_y = ((win_rect(4)-win_rect(2)) * frac_y);

rois_m2_rel_m1 = fieldnames( roi_m2_relative_m1 );

if ( isempty(adjusted_rois) || first_invoc )
  adjusted_rois = struct();
  
  for i = 1:numel(rois_m2_rel_m1)
    roi_name = rois_m2_rel_m1{i};
    bounds = roi_m2_relative_m1.(roi_name);
    bounds([1, 3]) = bounds([1, 3]) + origin_m2(1);
    bounds([2, 4]) = bounds([2, 4]) + origin_m2(2);

    frac_x = (bounds([1, 3]) - min_cm) ./ (max_cm-min_cm);
    frac_y = (bounds([2, 4]) - min_cm) ./ (max_cm-min_cm);
    frac_y = 1-frac_y;
    
    bounds([1, 3]) = (frac_x .* (win_rect(3)-win_rect(1)));
    bounds([2, 4]) = (frac_y .* (win_rect(4)-win_rect(2)));
    
    bounds = round( bounds );
    
    adjusted_rois.(roi_name) = bounds;
  end
end

for i = 1:numel(rois_m2_rel_m1)
  bounds = adjusted_rois.(rois_m2_rel_m1{i});
  Eyelink( 'Command', 'draw_filled_box %d %d %d %d %d' ...
    , bounds(1), bounds(2), bounds(3), bounds(4), i+1);
end


% Eyelink( 'Command', 'draw_cross %d %d %d' ...
%   , round(pix_x), round(pix_y), 15 );
px_sz = 20;
pix_rect = round([ pix_x-(px_sz/2), pix_y-(px_sz/2), pix_x+(px_sz/2), pix_y+(px_sz/2) ]);

Eyelink( 'Command', 'draw_filled_box %d %d %d %d %d' ...
  , pix_rect(1), pix_rect(2), pix_rect(3), pix_rect(4), 4 );

end