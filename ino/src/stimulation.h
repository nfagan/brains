#pragma once

#include "rois.h"
#include "brandom.h"

namespace STIMULATION_MODES {
	enum STIMULATION_MODES
	{
		EVENT,
		INTERVAL
	};
}

struct stimulation_params
{
	stimulation_params();
	~stimulation_params();

	void update(unsigned long delta);
	void mark_stimulation_onset(bool is_sham);
	bool ellapsed() const;
	bool probability_check() const;
  bool number_check() const;
	void set_probability(int p);

	int frequency;
	int probability;

	STIMULATION_MODES::STIMULATION_MODES stimulation_mode;

	unsigned long ms_remaining;
  
  int n_stimulations;
  int max_n_stimulations;

	brandom randomizer;
};

class stimulation_protocol
{
public:
	stimulation_protocol(unsigned int pin);
	~stimulation_protocol();

	bool set_probability(unsigned int index, int probability);
	bool set_frequency(unsigned int index, int frequency);
	void set_is_global_stimulation_timeout(bool state);
	void set_stimulation_mode(unsigned int index, STIMULATION_MODES::STIMULATION_MODES to);
  void set_max_n_stimulations(unsigned int index, int max_n);

	void update(unsigned long delta);
  bool ellapsed(unsigned int index);
  
  unsigned long get_total_n_stim() const;

	void allow_stimulation(unsigned int index);
	void disallow_stimulation(unsigned int index);
	bool conditional_stimulate(unsigned int index, unsigned long current_time, bool* probability_rejected);

private:
	static const int STIM_PULSE_DURATION = 25;

	unsigned int m_stimulation_pin;
	long m_stim_pulse_ms_remaining;

	int m_allow_stimulation[ROI_INDICES::N_ROI_INDICES];

	stimulation_params m_stimulation_params[ROI_INDICES::N_ROI_INDICES];

	unsigned long m_last_stimulation_time;
	int m_last_stimulation_duration;
	int m_last_stimulation_index;

	bool m_is_global_stimulation_timeout;
};