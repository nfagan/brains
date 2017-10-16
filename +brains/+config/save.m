function save( opts, flag, varargin )

%   SAVE -- Save the config file.
%
%     Optionally pass in '-default' as a second argument to save the config
%     as the default config.
%
%     IN:
%       - `opts` (struct) -- Options struct / config file.
%       - `flag` (char) |OPTIONAL|

manual_fname = false;
use_default = false;
if ( nargin == 1 )
  flag = '';
  fname = 'config.mat';
else
  if ( strcmp(flag, '-default') )
    fname = 'default.mat';
    use_default = true;
  elseif ( strcmp(flag, '-file') )
    narginchk(3, 3);
    brains.util.assert__isa( varargin{1}, 'char' );
    manual_fname = true;
  else
    error( 'Unrecognized flag ''%s''.', flag );
  end
end
savepath = fileparts( which('brains.config.save') );
if ( use_default )
  file = 'default.mat';
  msg = 'Default config file saved';
elseif ( manual_fname )
  file = varargin{1};
  msg = sprintf( '%s file saved', file );
else
  file = 'config.mat';
  msg = 'Config file saved';
end

filename = fullfile( savepath, file );
save( filename, 'opts' );
disp( msg );

end