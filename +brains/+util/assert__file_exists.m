function assert__file_exists( file )

%   ASSERT__FILE_EXISTS -- Ensure a file exists.
%
%     IN:
%       - `file` (char)

brains.util.assert__isa( file, 'char', 'the filename' );
assert( exist(file, 'file') == 2, 'The file ''%s'' does not exist.', file );

end