#include "fixation.h"

fixation_detection::fixation_detection()
{
	m_place_coord_index = 0;
}

void fixation_detection::update(coord new_coord)
{
	insert_coord(new_coord);
}

void fixation_detection::insert_coord(coord new_coord)
{
	if (m_place_coord_index < N_SAMPLES)
	{
		m_coords[m_place_coord_index++] = new_coord;
	}
	else
	{
		shift_left();
		m_coords[m_place_coord_index-1] = new_coord;
	}
}

void fixation_detection::shift_left()
{
	for (int i = 0; i < N_SAMPLES-1; i++)
	{
		m_coords[i] = m_coords[i+1];
	}
}

float fixation_detection::get_dispersion()
{
	coord maxs;

	bool first_iteration = true;

	for (int i = 0; i < m_place_coord_index-1; i++)
	{
		for (int j = i+1; j < m_place_coord_index; j++)
		{
			coord a = m_coords[i];
			coord b = m_coords[j];

			float dx = abs(a.x - b.x);
			float dy = abs(a.y - b.y);

			if (first_iteration || dx > maxs.x)
			{
				maxs.x = dx;
			}

			if (first_iteration || dy > maxs.y)
			{
				maxs.y = dy;
			}

			first_iteration = false;
		}
	}

	return (maxs.x + maxs.y) / 2;
}