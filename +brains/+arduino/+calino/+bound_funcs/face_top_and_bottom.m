function bounds = face_top_and_bottom(calibration_data, key_map, padding_info, const)

facebl = key_map( 'facebl' );
facetl = key_map( 'facetl' );
facebr = key_map( 'facebr' );
facetr = key_map( 'facetr' );

facebl = brains.arduino.calino.get_coord( calibration_data, facebl );
facetl = brains.arduino.calino.get_coord( calibration_data, facetl );
facebr = brains.arduino.calino.get_coord( calibration_data, facebr );
facetr = brains.arduino.calino.get_coord( calibration_data, facetr );

x1 = facebl(1);
x2 = facebr(1);
x3 = facetl(1);
x4 = facetr(1);

y1 = facebl(2);
y2 = facebr(2);
y3 = facetl(2);
y4 = facetr(2);

width_px = mean( [x2-x1, x3-x4] );
width_cm = const.FACE_WIDTH_CM;
ratio = width_px / width_cm;

x0 = mean( [x1, x3] );
x1 = mean( [x2, x4] );

y0 = mean( [y1, y3] );
y1 = mean( [y2, y4] );

x0 = x0 - (padding_info.face.x * ratio);
x1 = x1 + (padding_info.face.x * ratio);

y0 = y0 - (padding_info.face.y * ratio);
y1 = y1 + (padding_info.face.y * ratio);

bounds = [ x0, y0, x1, y1 ];

end