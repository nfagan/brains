#include <arduino.h>
#include "stimulation.h"

stimulation_params::stimulation_params()
{
	frequency = 0;
	probability = 0;
	ms_remaining = 0;
}

stimulation_params::~stimulation_params()
{
	//
}

void stimulation_params::mark_stimulation_onset()
{
	ms_remaining = frequency;
}

void stimulation_params::update(unsigned long delta)
{
	if (ms_remaining == 0)
	{
		ms_remaining = frequency;
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

bool stimulation_params::can_stimulate() const
{
	if (ms_remaining > 0)
	{
		return false;
	}

	//	integer in range [0, 99]
	int p = random(100) + 1;

	if (p >= (100 - probability))
	{
		return true;
	}
  
//   Serial.println("REJECTED");

	return false;
}

//
//	stim protocol
//

stimulation_protocol::stimulation_protocol(int pin)
{
	for (int i = 0; i < ROI_INDICES::N_ROI_INDICES; i++)
	{
		m_allow_stimulation[i] = 0;
	}

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

bool stimulation_protocol::conditional_stimulate(unsigned int index, unsigned long current_time)
{
	if (!m_allow_stimulation[index] || !m_stimulation_params[index].can_stimulate())
	{
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
	m_last_stimulation_duration = m_stimulation_params[index].frequency;
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
  
  m_stimulation_params[index].mark_stimulation_onset();

	return true;
}

bool stimulation_protocol::ellapsed(unsigned int index)
{
  return m_stimulation_params[index].ms_remaining == 0;
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

	m_stimulation_params[index].probability = probability;

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