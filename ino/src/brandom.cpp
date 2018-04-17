#include "brandom.h"
#include <arduino.h>

brandom::brandom(float p)
{
	set_probability(p);
}

brandom::brandom()
{
	set_probability(0.0f);
}

brandom::~brandom()
{
	//
}

void brandom::set_probability(float p)
{
	if (p < 0.0f)
	{
		p = 0.0f;
	}

	if (p > 1.0f)
	{
		p = 1.0f;
	}

	m_probability = p;
	m_block = 0;

	int n_true = floorf((float)BLOCK_SIZE * p);

	for (int i = 0; i < n_true; i++)
	{
		m_values[i] = true;
	}

	for (int i = n_true; i < BLOCK_SIZE; i++)
	{
		m_values[i] = false;
	}

	for (int i = 0; i < BLOCK_SIZE; i++)
	{
		m_indices[i] = i;
	}

	randomize();
}

bool brandom::next()
{
	if (m_block == BLOCK_SIZE)
	{
		randomize();
		m_block = 0;
	}

	int ind = m_indices[m_block++];

	return m_values[ind];
}

void brandom::randomize()
{
	for (int i = BLOCK_SIZE-1; i >= 0; --i)
	{
    	int j = random(i + 1);
    	int temp = m_indices[i];
    	m_indices[i] = m_indices[j];
    	m_indices[j] = temp;
	}
}


