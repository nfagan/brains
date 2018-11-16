function cmds = get_bounds_cmds(m_id, roi_id, bounds)

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

cmds = cell( numel(bounds), 1 );

for i = 1:numel(bounds)
  cmds{i} = sprintf( '%s%d%d', cmd, i-1, bounds(i) );
end

end