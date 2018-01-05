function bounds = face_top_only(calibration_data, key_map, padding_info, const)

import brains.arduino.calino.get_coord;

facetl = key_map( 'facetl' );
facetr = key_map( 'facetr' );

facetl_coord = get_coord( calibration_data, facetl );
facetr_coord = get_coord( calibration_data, facetr );

width_px = facetr_coord(1) - facetl_coord(1);
width_cm = const.FACE_WIDTH_CM;

ratio = width_px / width_cm;

mean_y_px = mean( [facetl_coord(2), facetr_coord(2)] );
bottom_px = mean_y_px + (ratio * const.FACE_HEIGHT_CM);

facel = facetl_coord(1) - (padding_info.face.x * ratio);
faceb = mean_y_px - (padding_info.face.y * ratio);
facer = facetr_coord(1) + (padding_info.face.x * ratio);
facet = bottom_px + (padding_info.face.y * ratio);

bounds = [ facel, faceb, facer, facet ];

end
