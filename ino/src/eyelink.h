#pragma once

#include <arduino.h>
#include "rois.h"

struct bounds
{
	static const int size = ROI_INDICES::N_ROI_INDICES;
	long rect[size];
	bool in;

	bounds();
	void check(float x, float y);
	void print(HardwareSerial *serial);
};

struct rois
{
	static const int n_rects = ROI_INDICES::N_ROI_INDICES;
	bounds rects[n_rects];
	rois();
	void update(float x, float y);
	void print(HardwareSerial *serial);
};

struct coord
{
	float x;
	float y;
};

class el_manager
{
public:
	static const int MAX_V = 1023;

public:
	el_manager(HardwareSerial *serial, int x_pin, int y_pin);
	~el_manager();

	void update();
	void set_name(const char *name);
	void print_bounds();
	void print_gaze();
	void init_pins();
	void set_rect_element(ROI_INDICES::ROI_INDICES index, unsigned int element, long value);
	bool in_bounds(ROI_INDICES::ROI_INDICES index);

	coord get_position() const;

	static float to_pixels(int level, int denom, int screen_min, int screen_max);

private:
	HardwareSerial *serial;
	String name;
	rois m_rois;
	int pin_x;
	int pin_y;
	float gaze_x;
	float gaze_y;

private:
	float update_one(int pin, int min_i, int max_i);
};