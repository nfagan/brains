function save( opts )

%   SAVE -- Save the config file.
%
%     IN:
%       - `opts` (struct) -- Options struct / config file.

savepath = fileparts( which('brains.config.save') );
filename = fullfile( savepath, 'config.mat' );
save( filename, 'opts' );
disp( 'Config file saved' );

end