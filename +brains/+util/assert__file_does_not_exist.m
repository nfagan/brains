function assert__file_does_not_exist( file )

%   ASSERT__FILE_DOES_NOT_EXIST -- Ensure a file does not exist.
%
%     IN:
%       - `file` (char)

brains.util.assert__isa( file, 'char', 'the filename' );
assert( exist(file, 'file') ~= 2, 'The file ''%s'' already exists.', file );

end