function s = get_square_centered_on(r, sz)

cx = ((r(3) - r(1)) / 2) + r(1);
cy = ((r(4) - r(2)) / 2) + r(2);

sz2 = sz / 2;

s = [ cx - sz2, cy - sz2, cx + sz2, cy + sz2 ];

end