#pragma once

#include "eyelink.h"

class fixation_detection
{
public:
	fixation_detection(int threshold);
	~fixation_detection();

	void update(coord new_coord);

private:
	static const unsigned int N_SAMPLES = 50;
	coord m_coords[N_SAMPLES];
	int m_place_coord_index;

private:
	void insert_coord(coord new_coord);
	void shift_left();
	float get_dispersion();
};