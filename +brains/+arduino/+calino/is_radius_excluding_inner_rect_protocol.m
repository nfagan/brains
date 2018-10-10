function tf = is_radius_excluding_inner_rect_protocol(p)

ids = brains.arduino.calino.get_ids();

protocols = ids.stim_protocols;

tf = isequal(p, protocols.m1_radius_excluding_inner_rect) || ...
  isequal(p, protocols.m2_radius_excluding_inner_rect);

end