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

void stimulation_params::update(unsigned long delta)
{
	if (ms_remaining == 0)
	{
		return;
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

bool m_stimulation_params::should_stimulate()
{

}

//
//	stim protocol
//

stimulation_protocol::stimulation_protocol()
{
	for (int i = 0; i < ROI_INDICES::N_ROI_INDICES; i++)
	{
		m_allow_stimulation[i] = 0;
	}

	m_protocol = PROTOCOLS::EVENT;
	m_allow_stimulation = 0;
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

void stimulation_protocol::update(unsigned long delta)
{
	for (int i = 0; i < ROI_INDICES::N_ROI_INDICES; i++)
	{
		m_stimulation_params[i].update(delta);
	}
}

void stimulation_protocol::set_probability(unsigned int index, int probability)
{
	m_stimulation_params[index].probability = probability;
}

void stimulation_protocol::set_frequency(unsigned int index, int frequency)
{
	m_stimulation_params[index].frequency = frequency;
}

void stimulation_protocol::set_protocol(unsigned int index, unsigned int protocol)
{
	m_stimulation_params[index].protocol = protocol;
}