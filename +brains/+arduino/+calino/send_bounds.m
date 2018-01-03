function send_bounds(comm, m_id, roi_id, bounds)

import shared_utils.assertions.*;

assert__isa( comm, 'serial', 'the serial comm' );
assert__isa( m_id, 'char', 'monkey id' );
assert__isa( roi_id, 'char', 'roi id' );
assert__isa( bounds, 'double', 'the bounds' );
assert( numel(bounds) == 4, 'Specify bounds as a 4-element rect.' );
arrayfun( @validate_bound, bounds );

ids = brains.arduino.calino.get_ids();

bounds_id = ids.bounds;

cmd = bounds_id;

if ( ~isfield(ids.monkey, m_id) )
  error( 'Unrecognized monkey id ''%s''.', m_id );
end

cmd = sprintf( '%s%s', cmd, ids.monkey.(m_id) );

if ( ~isfield(ids.roi, roi_id) )
  error( 'Unrecognized roi id ''%s''.', roi_id );
end

cmd = sprintf( '%s%s', cmd, ids.roi.(roi_id) );

for i = 1:numel(bounds)
  full_cmd = sprintf( '%s%d%d', cmd, i-1, bounds(i) );  
  fprintf( comm, full_cmd );
  brains.arduino.calino.await_char( comm, ids.ack, 'Bounds acknowledgement timed out.' );
end

end

function validate_bound(bound)

assert( mod(bound, 1) == 0, 'Specify integer inputs only.' );

end