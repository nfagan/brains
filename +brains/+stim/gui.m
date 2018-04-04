function gui()

F = figure( 1 );

F_W = .75;
F_L = .8;

N = 1;
W = .9;
Y = 0;
X = (1 - W) / 2;
L = (1 / N) - Y/2;

set( F, 'visible', 'off' );
set( F, 'resize', 'on' );
set( F, 'menubar', 'none' );
set( F, 'toolbar', 'none' );
set( F, 'units', 'normalized' );
set( F, 'name', 'stim GUI' );

% - PROPERTIES - %
panels.properties = uipanel( F ...
  , 'Title', 'Properties' ...
  , 'Position', [ X, Y, W, L ] ...
);





set( F, 'visible', 'on' );


end