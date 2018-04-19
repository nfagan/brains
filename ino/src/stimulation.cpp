#include <arduino.h>
#include "stimulation.h"

stimulation_params::stimulation_params()
{
	frequency = 0;
	probability = 0;
	ms_remaining = 0;
	stimulation_mode = STIMULATION_MODES::EVENT;
	randomizer.set_probability(0.0f);
}

stimulation_params::~stimulation_params()
{
	//
}

void stimulation_params::set_probability(int p)
{
	randomizer.set_probability((float)p / (float)100);
}

void stimulation_params::mark_stimulation_onset()
{
	ms_remaining = frequency;
}

bool stimulation_params::ellapsed() const
{
	return ms_remaining == 0;
}

void stimulation_params::update(unsigned long delta)
{
	if (ms_remaining == 0)
	{
		if (stimulation_mode == STIMULATION_MODES::INTERVAL)
		{
			ms_remaining = frequency;
		}
		else
		{
			return;
		}
	}

	unsigned long result = ms_remaining - delta;

	//	check for underflow
	if (result > ms_remaining)
	{
		ms_remaining = 0;
	}
	else
	{
		ms_remaining = result;
	}
}

bool stimulation_params::probability_check() const
{
	return randomizer.next();
}

//
//	stim protocol
//

stimulation_protocol::stimulation_protocol(unsigned int pin)
{
	for (int i = 0; i < ROI_INDICES::N_ROI_INDICES; i++)
	{
		m_allow_stimulation[i] = 0;
	}

	pinMode(pin, OUTPUT);

	m_last_stimulation_time = 0;
	m_last_stimulation_duration = 0;
	m_last_stimulation_index = -1;
	m_is_global_stimulation_timeout = true;

	m_stimulation_pin = pin;
	m_stim_pulse_ms_remaining = 0;
}

stimulation_protocol::~stimulation_protocol()
{
	//
}

void stimulation_protocol::allow_stimulation(unsigned int index)
{
	m_allow_stimulation[index] = 1;
}

void stimulation_protocol::disallow_stimulation(unsigned int index)
{
	m_allow_stimulation[index] = 0;
}


//	conditional_stimulate: deliver stimulation if probability and timing criteria
//		are satisifed. Return whether stimulation was triggered.
bool stimulation_protocol::conditional_stimulate(unsigned int index, unsigned long current_time, bool* probability_rejected)
{
	stimulation_params* params = &m_stimulation_params[index];
  
  *probability_rejected = false;

	if (!m_allow_stimulation[index] || !params->ellapsed())
	{
		return false;
	}

	//	make non-stimulated trials consistent with stimulated trials, 
	//	resetting the timer, despite not stimulating.
	if (!params->probability_check())
	{
		params->mark_stimulation_onset();
    *probability_rejected = true;
		return false;
	}

	if (m_is_global_stimulation_timeout)
	{
		if (current_time - m_last_stimulation_time < m_last_stimulation_duration)
		{
			return false;
		}
	}

	bool is_overlapping_stim = m_stim_pulse_ms_remaining > 0;

	m_last_stimulation_time = current_time;
	m_last_stimulation_duration = params->frequency;
	m_last_stimulation_index = index;
	m_stim_pulse_ms_remaining = STIM_PULSE_DURATION;

	//	if the current stimulation overlaps the previous one within
	//	STIM_PULSE_DURATION ms, terminate the previous stimulation pulse,
	//	wait 1 ms, then trigger stimulation. Otherwise, trigger 
	//	stimulation immediately
	if (is_overlapping_stim)
	{
		digitalWrite(m_stimulation_pin, LOW);
		delay(1);
		digitalWrite(m_stimulation_pin, HIGH);
	}
	else
	{
    digitalWrite(m_stimulation_pin, HIGH);
	}
  
  	params->mark_stimulation_onset();

	return true;
}

bool stimulation_protocol::ellapsed(unsigned int index)
{
  return m_stimulation_params[index].ellapsed();
}

void stimulation_protocol::update(unsigned long delta)
{
	for (int i = 0; i < ROI_INDICES::N_ROI_INDICES; i++)
	{
		m_stimulation_params[i].update(delta);
	}

	//	check whether to stop sending stimulation trigger pulse

	if (m_stim_pulse_ms_remaining == 0)
	{
		return;
	}

	m_stim_pulse_ms_remaining -= delta;

	if (m_stim_pulse_ms_remaining <= 0)
	{
		digitalWrite(m_stimulation_pin, LOW);
		m_stim_pulse_ms_remaining = 0;
	}
}

void stimulation_protocol::set_stimulation_mode(unsigned int index, STIMULATION_MODES::STIMULATION_MODES to)
{
	m_stimulation_params[index].stimulation_mode = to;
}

void stimulation_protocol::set_is_global_stimulation_timeout(bool state)
{
	m_is_global_stimulation_timeout = state;
}

bool stimulation_protocol::set_probability(unsigned int index, int probability)
{
	if (probability < 0 || probability > 100)
	{
		return false;
	}

	m_stimulation_params[index].set_probability(probability);

	return true;
}

bool stimulation_protocol::set_frequency(unsigned int index, int frequency)
{
	if (frequency < 0)
	{
		return false;
	}

	m_stimulation_params[index].frequency = frequency;

	return true;
}