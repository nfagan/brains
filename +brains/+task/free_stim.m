function free_stim(calibration_data, key_map)

import brains.arduino.calino.send_bounds;
import brains.arduino.calino.send_stim_param;

conf = brains.config.load();

screen_rect = conf.CALIBRATION.full_rect;

stim_port = 'COM6';
stim_baud = 9600;

stim_comm = brains.arduino.calino.init_serial( stim_port, stim_baud );

own_eyes = get_eye_rect(calibration_data, key_map, padding_info, const);
own_face = get_face_rect();
own_mouth = get_mouth_rect();

is_master = conf.INTERFACE.is_master_arduino;

tcp_comm = brains.server.get_tcp_comm();

if ( is_master )
  other_eyes = await_rect( tcp_comm );
  other_face = await_rect( tcp_comm );
  other_mouth = await_rect( tcp_comm );
else
  send_rect( tcp_comm, own_eyes );
  send_rect( tcp_comm, own_face );
  send_rect( tcp_comm, own_mouth );
end

send_bounds( stim_comm, 'm1', 'screen', screen_rect );
send_bounds( stim_comm, 'm2', 'screen', screen_rect );

send_bounds( stim_comm, 'm1', 'eyes', own_eyes );
send_bounds( stim_comm, 'm2', 'eyes', other_eyes );

send_bounds( stim_comm, 'm1', 'face', own_face);
send_bounds( stim_comm, 'm2', 'face', other_face );

send_bounds( stim_comm, 'm1', 'mouth', own_mouth );
send_bounds( stim_comm, 'm2', 'mouth', other_mouth );

end

function send_rect( obj, rect )

send_when_ready( obj, rect(1:2) );
send_when_ready( obj, rect(3:4) );

end

function rect = await_rect( obj )

if ( obj.bypass )
  rect = zeros( 1, 4 ); 
  return; 
end

recta = await_data( obj, 'gaze' );
rectb = await_data( obj, 'gaze' );

rect = [ recta, rectb ];

end