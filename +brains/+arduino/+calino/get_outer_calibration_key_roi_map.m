function map = get_outer_calibration_key_roi_map()

keys = { 'eyel', 'eyer', 'facebl', 'facetl', 'facebr', 'facetr', 'mouth' };
values = { 8, 12, 14, 4, 6, 10, 2 };

map = containers.Map( keys, values );

end