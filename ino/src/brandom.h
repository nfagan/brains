#pragma once

class brandom 
{
public:
	brandom(float p);
	brandom();
	~brandom();

	bool next();

	void set_probability(float p);

private:
	void randomize();

private:
	static const int BLOCK_SIZE = 4;

	float m_probability;
	bool m_values[BLOCK_SIZE];
	int m_indices[BLOCK_SIZE];
	int m_block;
};