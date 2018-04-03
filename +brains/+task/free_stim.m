function free_stim(calibration_data, key_map)

conf = brains.config.load();

screen_rect = conf.CALIBRATION.full_rect;

stim_port = 'COM6';
stim_baud = 9600;

stim_comm = brains.arduino.calino.init_serial( stim_port, stim_baud );

eye_rect = both_eyes(calibration_data, key_map, padding_info, const);

require_sync = conf.INTERFACE.require_synch;
is_master = conf.INTERFACE.is_master_arduino;

tcp_comm = brains.server.get_tcp_comm();

if ( is_master )
  m2_eyes = await_rect( tcp_comm );
  m2_face = await_rect( tcp_comm );
  m2_mouth = await_rect( tcp_comm );
else
  send_rect( tcp_comm, eye_rect );
  send_rect( tcp_comm, face_rect );
  send_rect( tcp_comm, mouth_rect );
end

send_bounds( stim_comm, 'm1', 'screen', screen_rect );
send_bounds( stim_comm, 'm2', 'screen', screen_rect );
send_bounds( stim_comm, 'm1', 'eyes', eye_rect );
send_bounds( stim_comm, 'm2', 'eyes', [100, 0, 101, 1024*3] );
send_bounds( stim_comm, 'm1', 'face', [1024, 0, 100, 200] );
send_bounds( stim_comm, 'm2', 'mouth', [0, 0, 100, 200] );

end

function send_rect( obj, rect )

send_when_ready( obj, rect(1:2) );
send_when_ready( obj, rect(3:4) );

end

function rect = await_rect( obj )

recta = await_data( obj, 'gaze' );
rectb = await_data( obj, 'gaze' );

rect = [ recta, rectb ];

end