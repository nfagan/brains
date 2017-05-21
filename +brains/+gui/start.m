function varargout = start(varargin)

config = brains.config.load();

F = figure;
N = 4;    %   n panels
W = .9;
L = 1 / N;
X = (1 - W) / 2;
Y = 0;

set( F, 'resize', 'off' );
set( F, 'menubar', 'none' );
set( F, 'toolbar', 'none' );
set( F, 'units', 'normalized' );

% - INTERFACE - %
panels.interface = uipanel( F ...
  , 'Title', 'Interface' ...
  , 'Position', [ X, Y, W, L ] ...
);

% - Check boxes
interface_fs = fieldnames( config.INTERFACE );
excludes = [ config.INTERFACE.gui_fields.exclude, {'gui_fields'} ];
interface_fs = exclude_values( interface_fs, excludes ); 

w = .5;
l = 1 / numel(interface_fs);
x = 0;
y = 0;

for i = 1:numel(interface_fs)
  check_name = interface_fs{i};
  position = [ x, y, w, l ];
  uicontrol( panels.interface ...
    , 'Style', 'checkbox' ...
    , 'String', check_name ...
    , 'Units', 'normalized' ...
    , 'Position', position ...
    , 'Value', config.INTERFACE.(check_name) ...
    , 'Callback', @handle_checkbox ...
  );
  y = y + l;
end
% - Port specifiers
panels.tcp_comm = uipanel( panels.interface ...
  , 'Title', 'TCP/IP' ...
  , 'Position', [ .5, .5, .5, .5 ] ...
);
tcp_fs = fieldnames( config.TCP );

w = .5;
l = 1 / numel(tcp_fs);
x = 0;
y = 0;

for i = 1:numel( tcp_fs )
  tcp_name = tcp_fs{i};
  if ( isequal(tcp_name, 'port') )
    is_num = true; 
  else
    is_num = false;
  end
  position = [ x, y, w, l ];
  uicontrol( panels.tcp_comm ...
    , 'Style', 'text' ...
    , 'String', tcp_name ...
    , 'Units', 'normalized' ...
    , 'Position', position ...
  );    
  position = [ x+w, y, w, l ];
  uicontrol( panels.tcp_comm ...
    , 'Style', 'edit' ...
    , 'String', config.TCP.(tcp_name) ...
    , 'UserData', struct( ...
          'config_field', 'TCP' ...
        , 'subfields', {{tcp_name}} ...
        , 'is_numeric', is_num ...
      ) ...
    , 'Units', 'normalized' ...
    , 'Position', position ...
    , 'Callback', @handle_textfields ...
  );
  y = y + l;
end

% - Serial port specifiers
panels.serial = uipanel( panels.interface ...
  , 'Title', 'Serial' ...
  , 'Position', [ .5, 0, .5, .5 ] ...
);
serial_fs = fieldnames( config.SERIAL.ports );

w = .5;
l = 1 / numel(serial_fs);
x = 0;
y = 0;

for i = 1:numel( serial_fs )
  serial_name = serial_fs{i};
  position = [ x, y, w, l ];
  uicontrol( panels.serial ...
    , 'Style', 'text' ...
    , 'String', serial_name...
    , 'Units', 'normalized' ...
    , 'Position', position ...
  );    
  position = [ x+w, y, w, l ];
  uicontrol( panels.serial ...
    , 'Style', 'edit' ...
    , 'String', config.SERIAL.ports.(serial_name) ...
    , 'UserData', struct( ...
          'config_field', 'SERIAL' ...
        , 'subfields', {{'ports', serial_name}} ...
        , 'is_numeric', false ...
        ) ...
    , 'Units', 'normalized' ...
    , 'Position', position ...
    , 'Callback', @handle_textfields ...
  );
  y = y + l;
end

Y = Y + L;

% - STIMULI - %
panels.stimuli = uipanel( F ...
  , 'Title', 'Stimuli' ...
  , 'Position', [ X, Y, W, L ] ...
);

% - pop ups
stimuli_fs = fieldnames( config.STIMULI );
handle_stimuli_popup();

Y = Y + L;

% - TASK TIMES

panels.time_in = uipanel( F ...
  , 'Title', 'Time in states' ...
  , 'Position', [ X, Y, W, L ] ...
);

time_fs = fieldnames( config.TIMINGS.time_in );

w = .5;
l = 1 / numel(time_fs);
x = 0;
y = 0;

for i = 1:numel( time_fs )
  time_name = time_fs{i};
  position = [ x, y, w, l ];
  uicontrol( panels.time_in ...
    , 'Style', 'text' ...
    , 'String', time_name...
    , 'Units', 'normalized' ...
    , 'Position', position ...
  );    
  position = [ x+w, y, w, l ];
  uicontrol( panels.time_in ...
    , 'Style', 'edit' ...
    , 'String', config.TIMINGS.time_in.(time_name) ...
    , 'UserData', struct( ...
          'config_field', 'TIMINGS' ...
        , 'subfields', {{'time_in', time_name}} ...
        , 'is_numeric', true ...
        ) ...
    , 'Units', 'normalized' ...
    , 'Position', position ...
    , 'Callback', @handle_textfields ...
  );
  y = y + l;
end

Y = Y + L;

% - Buttons
panels.run = uipanel( F ...
  , 'Title', 'Run' ...
  , 'Position', [ X, Y, W, L ] ...
);

funcs = { 'reset to default', 'clean-up', 'calibrate', 'start' };
w = 1;
l = 1 / numel(funcs);
x = 0;
y = 0;

for i = 1:numel(funcs)
  func_name = funcs{i};
  position = [ x, y, w, l ];
  uicontrol( panels.run ...
    , 'Style', 'pushbutton' ...
    , 'String', func_name ...
    , 'Units', 'normalized' ...
    , 'Position', position ...
    , 'Callback', @handle_button ...
  );
  y = y + l;
end

% - COMPLETE
set( F, 'position', [.25, 0, .5, .75] );

if ( nargout == 1 )
  varargout{1} = F;
elseif ( nargout == 2 )
  varargout{1} = F;
  varargout{2} = config;
end

%   EVENT HANDLERS

function handle_checkbox(source, event)

chk_name = source.String;
config.INTERFACE.(chk_name) = ~config.INTERFACE.(chk_name);
brains.config.save( config );

end

function handle_button(source, event)
  
  func = source.String;
  switch ( func )
    case 'start'
      func = str2func( 'brains.task.start' );
      args = {};
    case 'calibrate'
      func = str2func( 'brains.start_calibration' );
      args = {};
    case 'clean-up'
      func = str2func( 'brains.task.cleanup' );
      args = {};
    case 'reset to default'
      brains.config.create();
      delete( F );
      brains.gui.start();
      return;
    otherwise
      error( 'Unrecognized identifier ''%s''', source.String );
  end
  brains.config.save( config );
  func( args{:} );
end

% - COMMUNICATORS - % 
function handle_textfields(source, event)
  
  val = source.String;
  is_numeric = source.UserData.is_numeric;
  field = source.UserData.config_field;
  subfields = source.UserData.subfields;
  all_fields = [ {'config'}, {field}, subfields ];
  identifier = strjoin( all_fields, '.' );
  if ( is_numeric )
    eval( sprintf( '%s = %s;', identifier, val ) );  
  else
    eval( sprintf( '%s = ''%s'';', identifier, val ) );  
  end
  brains.config.save( config );
end

% - STIMULI - %

function handle_stimuli_popup(source, event)
  
  if ( nargin > 0  )
    panel_children = panels.stimuli.Children;
    stim_ind = source.Value;
    stim_name = source.String{ stim_ind };  
    delete( panel_children );
  else
    stim_ind = 1;
    stim_name = stimuli_fs{ stim_ind };
  end
  stim = config.STIMULI.(stim_name);
  props = fieldnames( stim );
  non_editable = [ stim.non_editable, {'non_editable'} ];
  props = exclude_values( props, non_editable );
  
  n_controls = numel( props ) + 1;
  w_ = .5;
  l_ = 1 / n_controls;
  x_ = 0;
  y_ = 0;
  
  position_ = [ x_, y_, w_, l_ ];
  uicontrol( panels.stimuli ...
    , 'Style',  'text' ...
    , 'String', 'Stimulus name' ...
    , 'Units',  'normalized' ...
    , 'Position', position_ ...
  );
  position_ = [ x_+w_, y_, w_, l_ ];
  uicontrol( panels.stimuli ...
    , 'Style',      'popup' ...
    , 'String',     stimuli_fs ...
    , 'Value',      stim_ind ...
    , 'Units',      'normalized' ...
    , 'Tag',        'stim_selector' ...
    , 'Position',   position_ ...
    , 'Callback',   @handle_stimuli_popup ...
  );
  y_ = y_ + l_;

  for ii = 2:n_controls
    position_ = [ x_, y_, w_, l_ ];    
    prop = props{ii-1};
    uicontrol( panels.stimuli ...
      , 'Style',    'text' ...
      , 'String',   prop ...
      , 'Units',    'normalized' ...
      , 'Position', position_ ...
    );
    prop_val = stim.(prop);
    original_class = class( prop_val );
    switch ( original_class )
      case { 'double', 'logical' }
        prop_val = num2str( prop_val );
      case 'char'
      otherwise
        error( 'Unsupported datatype ''%s''', original_class );
    end
    position_ = [ x_+w_, y_, w_, l_ ];
    uicontrol( panels.stimuli ...
      , 'Style', 'edit' ...
      , 'String', prop_val ...
      , 'UserData', struct( ...
            'prop', prop ...
          , 'class', original_class ...
          , 'stim_name', stim_name ...
          ) ...
      , 'Units', 'normalized' ...
      , 'Position', position_ ...
      , 'Callback', @handle_stimuli_textfield ...
    );
    y_ = y_ + l_;
  end
  function handle_stimuli_textfield(source, event)
    
    prop_name = source.UserData.prop;
    prop_val_ = source.String;
    orig_class = source.UserData.class;
    stim_name_ = source.UserData.stim_name;
    
    if ( isequal(orig_class, 'double') || isequal(orig_class, 'logical') )
      prop_val_ = strsplit( prop_val_, ' ' );
      prop_val_( strcmp(prop_val_, '') ) = [];
      prop_val_ = cellfun( @str2double, prop_val_ );
      if ( isequal(orig_class, 'logical') )
        prop_val_ = logical( prop_val_ );
      end
    end
    
    config.STIMULI.(stim_name_).(prop_name) = prop_val_;
    brains.config.save( config );
  end
end

end

function arr1 = exclude_values( arr1, arr2 )

%   EXCLUDE_VALUES -- Exclude char values in arr1 that are present in arr2.

if ( ~iscell(arr2) ), arr2 = { arr2 }; end;
to_rm = false( size(arr1) );
for i = 1:numel( arr1 )
  to_rm(i) = any( strcmp(arr2, arr1{i}) );
end

arr1(to_rm) = [];

end