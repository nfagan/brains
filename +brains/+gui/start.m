function varargout = start(varargin)

config = brains.config.load();
interface_fs = fieldnames( config.INTERFACE );

F = figure;
W = 200;
L = 50;
X = 0;
Y = 0;

set( F, 'resize', 'off' );
set( F, 'menubar', 'none' );
set( F, 'toolbar', 'none' );

% - Check boxes
for i = 1:numel(interface_fs)
  check_name = interface_fs{i};
  position = [ X, Y, W, L ];
  uicontrol( F ...
    , 'Style', 'checkbox' ...
    , 'String', check_name ...
    , 'Position', position ...
    , 'Value', config.INTERFACE.(check_name) ...
    , 'Callback', @handle_checkbox ...
  );
  Y = Y + L;
end

% - Buttons
funcs = { 'clean-up', 'calibrate', 'start' };
for i = 1:numel(funcs)
  func_name = funcs{i};
  position = [ X, Y, W, L ];
  uicontrol( F ...
    , 'Style', 'pushbutton' ...
    , 'String', func_name ...
    , 'Position', position ...
    , 'Callback', @handle_button ...
  );
  Y = Y + L;
end

N = numel(interface_fs) + numel(funcs);
H = L*N;
sz = get( 0, 'screensize' );
sz = sz( 3:4 );
x = sz(1) - W;
y = sz(2) - H;
set( F, 'Position', [ x, y, W, H ] );

varargout{1} = F;

function handle_checkbox(source, event)

chk_name = source.String;
config.INTERFACE.(chk_name) = ~config.INTERFACE.(chk_name);

end

function handle_button(source, event)
  
  func = source.String;
  switch ( func )
    case 'start'
      func = str2func( 'brains.task.start' );
      args = { config.INTERFACE };
    case 'calibrate'
      func = str2func( 'brains.start_calibration' );
      args = {};
    case 'clean-up'
      func = str2func( 'brains.task.cleanup' );
      args = {};
    otherwise
      error( 'Unrecognized identifier ''%s''', source.String );
  end
  brains.config.save( config );
  func( args{:} );
end

end