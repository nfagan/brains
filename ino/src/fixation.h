#pragma once

#include "eyelink.h"

class fixation_detection
{
public:
	fixation_detection(float threshold);
	~fixation_detection();

	void update(coord new_coord);
  bool is_fixating() const;

private:
	static const unsigned int N_SAMPLES = 50;
	coord m_coords[N_SAMPLES];
	int m_place_coord_index;
  float m_threshold;
  float m_dispersion;

private:
	void insert_coord(coord new_coord);
	void shift_left();
	float get_dispersion();
};