#pragma once

#include "eyelink.h"

class fixation_detection
{
public:
	fixation_detection(float threshold);
	~fixation_detection();

	void update(coord new_coord);
  	bool is_fixating() const;
  	bool state_changed() const;

private:
	static const unsigned int N_SAMPLES = 50;
	coord m_coords[N_SAMPLES];
	int m_place_coord_index;
  	float m_threshold;
  	float m_dispersion;
  	bool m_is_fixating;
  	bool m_state_changed;

private:
	void insert_coord(coord new_coord);
	void shift_left();
	float get_dispersion();
};