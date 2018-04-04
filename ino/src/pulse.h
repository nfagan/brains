#pragma once

namespace util {

class pulse
{
public:
	pulse(unsigned int pin);
	~pulse();

	void update(unsigned long delta);
	bool ellapsed() const;
	void deliver(unsigned long duration);

private:
	unsigned int m_pin;
	unsigned long m_ms_remaining;
};

}