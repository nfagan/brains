function opts = setup()

%   SETUP -- Prepare to run the task.
%
%     Opens windows; initializes serial, tcp, and eyelink connections (as
%     appropriate); creates stimuli; starts task timers; etc.
%
%     OUT:
%       - `opts` (struct) -- Options struct modified to include open
%         windows, EyeTracker, constructed stimuli, etc.

import brains.util.assert__file_does_not_exist;

%   load the config file
opts = brains.config.load();

IO =        opts.IO;
SCREEN =    opts.SCREEN;
TIMINGS =   opts.TIMINGS;
STIMULI =   opts.STIMULI;
IMAGES =    opts.IMAGES;
SOUNDS =    opts.SOUNDS;
INTERFACE = opts.INTERFACE;
SERIAL =    opts.SERIAL;
TCP =       opts.TCP;
ROIS =      opts.ROIS;

addpath( genpath(fullfile(IO.repo_folder, 'ptb_helpers')) );
addpath( genpath(fullfile(IO.repo_folder, 'arduino', 'communicator')) );

if ( INTERFACE.save_data && ~INTERFACE.allow_overwrite )
  assert__file_does_not_exist( fullfile(IO.data_folder, IO.data_file) );
  assert__file_does_not_exist( fullfile(IO.data_folder, IO.edf_file) );
end

PsychDefaultSetup( 1 );
ListenChar();

is_master_arduino = INTERFACE.is_master_arduino;

is_m1 = INTERFACE.IS_M1;

if ( is_m1 )
  M_str = 'M1';
else
  M_str = 'M2';
end

% - WINDOW - %
bg_color =  SCREEN.background_color;
scr_rect =  SCREEN.rect.(M_str);
scr_index = SCREEN.index;
[windex, wrect] = Screen( 'OpenWindow', scr_index, bg_color, scr_rect );

WINDOW.center = round( [mean(wrect([1 3])), mean(wrect([2 4]))] );
WINDOW.index = windex;
WINDOW.rect = wrect;

% - TRACKER - %
TRACKER = EyeTracker( IO.edf_file, IO.edf_folder, WINDOW.index );
TRACKER.bypass = ~INTERFACE.use_eyelink;

success = TRACKER.init();
assert( success, 'Eyelink initialization failed.' );

% - TIMER - %
time_in = TIMINGS.time_in;
TIMER = Timer();
TIMER.register( time_in );

% - Serial - %
serial_comm_ = brains.arduino.get_serial_comm();

serial_comm_.bypass = ~INTERFACE.use_arduino;
serial_comm_.start();

% - TCP - %
if ( is_master_arduino )
  tcp_comm_constructor = @brains.server.Server;
  address = TCP.client_address;
else
  tcp_comm_constructor = @brains.server.Client;
  address = TCP.server_address;
end

tcp_port = TCP.port;
tcp_comm = tcp_comm_constructor( address, tcp_port );
tcp_comm.bypass = ~INTERFACE.require_synch;
tcp_comm.start();

COMMUNICATORS.serial_comm = serial_comm_;
COMMUNICATORS.tcp_comm = tcp_comm;

% - ROIS - %
ROIS = structfun( @(x) Target( TRACKER, x, Inf ), ROIS, 'un', false );

stimuli_setup = STIMULI;

% - STIMULI - %
stim_fs = fieldnames( STIMULI );
for i = 1:numel(stim_fs)
  stim = STIMULI.(stim_fs{i});
  switch ( stim.class )
    case 'Rectangle'
      stim_ = Rectangle( windex, wrect, stim.size );
    case 'Image'
      image_path = fullfile( IO.stimuli_path, stim.image_file );
      im = imread( image_path );
      stim_ = Image( windex, wrect, stim.size, im );
  end
  stim_.color = stim.color;
  stim_.put( stim.placement );
  if ( isfield(stim, 'pen_width') )
    stim_.pen_width = stim.pen_width;
  end
  if ( stim.has_target )
    duration = stim.target_duration;
    padding = stim.target_padding;
    stim_.make_target( TRACKER, duration );
    stim_.targets{1}.padding = padding;
    %   update X target bounds to account for non-fullscreen window.
    if ( ~INTERFACE.use_eyelink )
      x_offset = scr_rect(1);
      y_offset = 0;
    else
      x_offset = stim.target_offset(1);
      y_offset = stim.target_offset(2);
    end
    stim_.targets{1}.x_offset = x_offset;
    stim_.targets{1}.y_offset = y_offset;
  end
  STIMULI.(stim_fs{i}) = stim_;
end

STIMULI.setup = stimuli_setup;

% - load images
fs = fieldnames( IMAGES );
for i = 1:numel(fs)
  img_path = IMAGES.(fs{i});
  img_files = brains.util.dirnames( img_path, 'png' );
  img_files = [ img_files, brains.util.dirnames(img_path, 'jpg') ];
  assert( numel(img_files) > 0, 'No .png or .jpg files found in %s.', img_path );
  full_img_files = cellfun( @(x) fullfile(img_path, x), img_files, 'un', false );
  img_matrices = cellfun( @imread, full_img_files, 'un', false );
  IMAGES.(fs{i}) = struct( ...
      'filenames', {img_files} ...
    , 'matrices', {img_matrices} ...
  );
end

% - load sounds

fs = fieldnames( SOUNDS );
for i = 1:numel(fs)
  audio = [];
  sr = [];
  sound_path = SOUNDS.(fs{i});
  if ( exist(sound_path, 'file') > 0 )
    [audio, sr] = audioread( sound_path );
  end
  SOUNDS.(fs{i}) = struct( ...
      'audio', audio ...
    , 'fs', sr ...
  );
end

% - export
opts.SCREEN =         SCREEN;
opts.WINDOW =         WINDOW;
opts.COMMUNICATORS =  COMMUNICATORS;
opts.TRACKER =        TRACKER;
opts.TIMER =          TIMER;
opts.ROIS =           ROIS;
opts.STIMULI =        STIMULI;
opts.IMAGES =         IMAGES;
opts.SOUNDS =         SOUNDS;

end