#include "pulse.h"
#include <arduino.h>

util::pulse::pulse(unsigned int pin)
{
	m_pin = pin;
	m_ms_remaining = 0;

	pinMode(pin, OUTPUT);
}

util::pulse::~pulse()
{
	//
}

bool util::pulse::ellapsed() const
{
	return m_ms_remaining == 0;
}

void util::pulse::deliver(unsigned long duration)
{
	//	if the last pulse had yet to finish, 
	//	insert a 1ms delay between next pulse
	if (m_ms_remaining > 0)
	{
		digitalWrite(m_pin, LOW);
		delay(1);
	}

	m_ms_remaining = duration;

	digitalWrite(m_pin, HIGH);
}

void util::pulse::update(unsigned long delta)
{
	if (m_ms_remaining == 0)
	{
		return;
	}

	unsigned long res = m_ms_remaining - delta;

	//	check for underflow
	if (res > m_ms_remaining || res == 0)
	{
		digitalWrite(m_pin, LOW);
		m_ms_remaining = 0;
	}
	else
	{
		m_ms_remaining = res;
	}
}