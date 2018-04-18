import brains.arduino.calino.send_bounds;
import brains.arduino.calino.get_ids;
import brains.arduino.calino.send_stim_param;

brains.arduino.calino.close_ports();

port = 'COM6';
baud = 9600;

comm = brains.arduino.calino.init_serial( port, baud );

conf = brains.config.load();
screen_rect = conf.CALIBRATION.cal_rect;

m1_eyes = [ 200, 200, 400, 400 ];
m2_eyes = [ 300, 300, 400, 400 ];

m1_eyes([1, 3]) = m1_eyes([1, 3]) + screen_rect(1);
m2_eyes([1, 3]) = m2_eyes([1, 3]) + screen_rect(1);

send_bounds( comm, 'm1', 'screen', screen_rect );
send_bounds( comm, 'm2', 'screen', screen_rect );
send_bounds( comm, 'm1', 'eyes', m1_eyes );
send_bounds( comm, 'm2', 'eyes', m2_eyes );
send_bounds( comm, 'm1', 'face', [1024, 0, 100, 200] );
send_bounds( comm, 'm2', 'mouth', [0, 0, 100, 200] );

%%


brains.util.el_draw_rect( round(m1_eyes), 2 );

%%

brains.util.draw_far_plane_rois( calibration_data.keys, 10, 4, false );

%%

import brains.arduino.calino.bound_funcs.both_eyes;

calibration_data = brains.util.get_latest_far_plane_calibration( [], false );
padding_info = brains.arduino.calino.define_padding();
consts = brains.arduino.calino.define_calibration_target_constants();
key_map = calibration_data.key_name_map;

padding_info.eyes.x = 2.75;
padding_info.eyes.y = 2.75;

calibration_data.keys = brains.arduino.calino.convert_key_struct( calibration_data.keys, calibration_data.key_map );

m1_eyes = both_eyes( calibration_data.keys, key_map, padding_info, consts );

send_bounds( comm, 'm1', 'eyes', round(m1_eyes) );
send_bounds( comm, 'm2', 'eyes', [1366, 316, 1460, 363] );
%%

ids = brains.arduino.calino.get_ids();

send_stim_param( comm, 'all', 'probability', 100 );
send_stim_param( comm, 'all', 'frequency', 1e3 );
send_stim_param( comm, 'all', 'stim_stop_start', 0 );
send_stim_param( comm, 'eyes', 'stim_stop_start', 1 );
send_stim_param( comm, 'all', 'protocol', ids.stim_protocols.probabilistic );
% send_stim_param( comm, 'all', 'protocol', ids.stim_protocols.m1_exclusive_event );
send_stim_param( comm, 'all', 'global_stim_timeout', 1 );

%%




%%

fprintf( comm, 'p' );

while ( comm.BytesAvailable == 0 )
end

s = {};

while ( comm.BytesAvailable > 0 )
  s{end+1} = fscanf( comm );
end

disp( strjoin(s, '\n') );