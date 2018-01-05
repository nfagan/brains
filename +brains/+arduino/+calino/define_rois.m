function rois = define_rois(calibration_data, key_map, padding_info, funcs)

import shared_utils.assertions.*;

const = brains.arduino.calino.define_calibration_target_constants();

assert__isa( calibration_data, 'struct', 'the calibration key file' );
assert__isa( key_map, 'containers.Map', 'the roi key map' );

eye_bounds = funcs.eyes( calibration_data, key_map, padding_info, const );
face_bounds = funcs.face( calibration_data, key_map, padding_info, const );

rois = struct();
rois.eyes = eye_bounds;
rois.face = face_bounds;
% rois.mouth = mouth_bounds;

end


