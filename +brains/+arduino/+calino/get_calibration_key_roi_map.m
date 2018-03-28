function map = get_calibration_key_roi_map()

keys = { 'eyel', 'eyer', 'facebl', 'facetl', 'facebr', 'facetr', 'mouth' };
% values = { 2, 6, 5, 3, 7, 4, 1 };
values = { 4, 1, 6, 5, 7, 3, 2 };

map = containers.Map( keys, values );

end