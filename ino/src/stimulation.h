#pragma once

#include "rois.h"

struct stimulation_params
{
	stimulation_params();
	~stimulation_params();

	void update(unsigned long delta);
	bool can_stimulate() const;
	void mark_stimulation_onset();

	int frequency;
	int probability;

	unsigned long ms_remaining;
};

class stimulation_protocol
{
public:
	stimulation_protocol(int pin);
	~stimulation_protocol();

	bool set_probability(unsigned int index, int probability);
	bool set_frequency(unsigned int index, int frequency);
	void set_is_global_stimulation_timeout(bool state);

	void update(unsigned long delta);
  bool ellapsed(unsigned int index);

	void allow_stimulation(unsigned int index);
	void disallow_stimulation(unsigned int index);
	bool conditional_stimulate(unsigned int index, unsigned long current_time);

private:
	static const int STIM_PULSE_DURATION = 10;

	int m_stimulation_pin;
	long m_stim_pulse_ms_remaining;

	int m_allow_stimulation[ROI_INDICES::N_ROI_INDICES];

	stimulation_params m_stimulation_params[ROI_INDICES::N_ROI_INDICES];

	unsigned long m_last_stimulation_time;
	int m_last_stimulation_duration;
	int m_last_stimulation_index;

	bool m_is_global_stimulation_timeout;
};