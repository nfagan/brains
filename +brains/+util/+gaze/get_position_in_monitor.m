function pos = get_position_in_monitor(pixel_xy, screen_rect, screen_dims)

%   GET_POSITION_IN_MONITOR -- Transform a pixel coordinate to a
%     real-unit (e.g., cm) coordinate relative to the top-left corner of a
%     monitor.
%
%     IN:
%       - `pixel_xy` (2-element double)
%       - `screen_rect` (4-element double) -- Pixel dimensions of screen.
%       - `screen_dims` (2-element double) -- Real-unit screen width, 
%         height.
%     OUT:
%       - `pos` (2-element double)

pixel_x = pixel_xy(1);
pixel_y = pixel_xy(2);

screen_width = screen_dims(1);
screen_height = screen_dims(2);

min_pixel_x = screen_rect(1);
max_pixel_x = screen_rect(3);
min_pixel_y = screen_rect(2);
max_pixel_y = screen_rect(4);

x_pos = (pixel_x - min_pixel_x) / (max_pixel_x - min_pixel_x) * screen_width;
y_pos = (pixel_y - min_pixel_y) / (max_pixel_y - min_pixel_y) * screen_height;

pos = [x_pos, y_pos];

end