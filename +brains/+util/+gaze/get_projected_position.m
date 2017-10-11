function pos = get_projected_position(angle, z_dist)

%   GET_PROJECTED_POSITION -- Get x, y position at a given angle and
%     z-distance.
%
%     IN:
%       - `angle` (2-element double) -- x, y angle, in radians.
%       - `z_dist` (double) -- Distance at which to evaluate position.
%     OUT:
%       - `pos` (2-element double)

pos = tan(angle) * z_dist;

% pos = zeros( 1, 2 );
% pos(1) = tan( angle(1) ) / z_dist;
% pos(2) = tan( angle(2) ) / z_dist;

end