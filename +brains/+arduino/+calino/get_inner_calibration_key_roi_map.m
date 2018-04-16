function map = get_inner_calibration_key_roi_map()

keys = { 'eyel', 'eyer', 'facebl', 'facetl', 'facebr', 'facetr', 'mouth' };
% values = { 2, 6, 5, 3, 7, 4, 1 };
values = { 1, 13, 9, 5, 3, 11, 7 };

map = containers.Map( keys, values );

end