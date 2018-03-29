#pragma once

#include "rois.h"

namespace PROTOCOLS {
	enum PROTOCOLS {
		EVENT = 0,
		RANDOM = 1
	};
}

struct stimulation_params
{
	stimulation_params();
	~stimulation_params();

	void update(unsigned long delta);
	bool should_stimulate();

	int frequency;
	int probability;
	unsigned int protocol;

	unsigned long ms_remaining;
};

class stimulation_protocol
{
public:
	stimulation_protocol();
	~stimulation_protocol();

	void set_probability(unsigned int index, int probability);
	void set_frequency(unsigned int index, int frequency);
	void set_protocol(unsigned int index, unsigned int protocol);
	void update(unsigned long delta);

	void allow_stimulation(unsigned int index);
	void disallow_stimulation(unsigned int index);

private:
	int m_allow_stimulation[ROI_INDICES::N_ROI_INDICES];
	m_stimulation_params[ROI_INDICES::N_ROI_INDICES] stim_params;
};