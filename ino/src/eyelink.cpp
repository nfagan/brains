#include "eyelink.h"

//
//	bounds
//

bounds::bounds()
{
	for (unsigned i = 0; i < 4; i++)
	{
		rect[i] = 0;
	}
  
  state_changed = false;
}

void bounds::update(float x, float y)
{
    bool prev = in;
    check(x, y);
    state_changed = prev != in;
}

void bounds::check(float x, float y)
{
    bool in_x = x >= rect[0] && x <= rect[2];
    bool in_y = y >= rect[1] && y <= rect[3];
    in = in_x && in_y;
}

void bounds::print(HardwareSerial *serial) 
{
	String bounds_str;

	for (int i = 0; i < size; i++) 
	{
		bounds_str += rect[i];

		if (i < size-1)
		{
			bounds_str += ',';
		}
	}

	serial->println(bounds_str);
}

//
//	rois
//

rois::rois()
{
	for (unsigned i = 0; i < n_rects; ++i)
	{
		rects[i] = bounds();
	}
}

void rois::update(float x, float y)
{
	for (unsigned i = 0; i < n_rects; ++i)
	{
    rects[i].update(x, y);
	}
}

void rois::print(HardwareSerial *serial) 
{
	for (int i = 0; i < n_rects; i++) {
		rects[i].print(serial);
	}
}

//
//	eyelink manager
//

el_manager::el_manager(HardwareSerial *serial, int x_pin, int y_pin)
{
	this->serial = serial;
	this->pin_x	= x_pin;
	this->pin_y = y_pin;
	this->name = "";
}

el_manager::~el_manager()
{
	//
}

void el_manager::set_name(const char *name)
{
	this->name = String(name);
}

void el_manager::print_bounds()
{
	serial->println(name + ":");
	m_rois.print(serial);
}

void el_manager::print_gaze()
{
	serial->println(name + ":");
	String x = String(gaze_x);
	String y = String(gaze_y);
	String print_str = x + "," + y;
	serial->println(print_str);
}

void el_manager::init_pins() 
{
	pinMode(pin_x, INPUT);
	pinMode(pin_y, INPUT);
}

void el_manager::update()
{
	gaze_x = update_one(pin_x, 0, 2);	
	gaze_y = update_one(pin_y, 1, 3);
	m_rois.update(gaze_x, gaze_y);
}

coord el_manager::get_position() const
{
	coord res;
	res.x = gaze_x;
	res.y = gaze_y;
	return res;
}

float el_manager::update_one(int pin, int min_i, int max_i)
{
	int level = analogRead(pin);
	long min = m_rois.rects[ROI_INDICES::screen].rect[min_i];
	long max = m_rois.rects[ROI_INDICES::screen].rect[max_i];
	return el_manager::to_pixels(level, MAX_V, min, max);
}

float el_manager::to_pixels(int level, int denom, int screen_min, int screen_max)
{
	float v = (float)level;
    float max = (float)denom;
    float r = v / max;
    float px = (r * (screen_max - screen_min)) + screen_min;
    return px;
}

void el_manager::set_rect_element(ROI_INDICES::ROI_INDICES index, unsigned int element, long value)
{
	if (element > m_rois.rects[0].size-1)
	{
		serial->println('!');
		return;
	}
	m_rois.rects[index].rect[element] = value;
}

bool el_manager::state_changed(ROI_INDICES::ROI_INDICES index)
{
  return m_rois.rects[index].state_changed;
}

bool el_manager::in_bounds(ROI_INDICES::ROI_INDICES index) const
{
	return m_rois.rects[index].in;
}

bool el_manager::in_bounds_face(float dist) const
{    
	const long *rect = &m_rois.rects[ROI_INDICES::face].rect[0];
  const float r0 = (const float)rect[0];
  const float r1 = (const float)rect[1];
  const float r2 = (const float)rect[2];
  const float r3 = (const float)rect[3];
  
  const float cx = r0 + (r2-r0) / 2.0f;
  const float cy = r1 + (r3-r1) / 2.0f;
  
  const float x0 = cx - (dist/2.0f);
  const float y0 = cy - (dist/2.0f);
  
  const float x1 = cx + (dist/2.0f);
  const float y1 = cy + (dist/2.0f);
  
  bool res = gaze_x >= x0 && gaze_x <= x1 && gaze_y >= y0 && gaze_y <= y1;
  
  return res;
}

bool el_manager::in_bounds_radius(ROI_INDICES::ROI_INDICES index, float radius) const
{
  if (index != ROI_INDICES::eyes) return false;
  if (name != "M1") return false;
  
	const long *rect = &m_rois.rects[index].rect[0];
  const float r0 = (const float)rect[0];
  const float r1 = (const float)rect[1];
  const float r2 = (const float)rect[2];
  const float r3 = (const float)rect[3];
  
  const float cx = r0 + (r2-r0) / 2.0f;
  const float cy = r1 + (r3-r1) / 2.0f;
  
  const float x0 = cx - (radius/2.0f);
  const float y0 = cy - (radius/2.0f);
  
  const float x1 = cx + (radius/2.0f);
  const float y1 = cy + (radius/2.0f);
  
  bool res = gaze_x >= x0 && gaze_x <= x1 && gaze_y >= y0 && gaze_y <= y1;
  
//   serial->println("In bounds? ");
  serial->println(res);
//   serial->println(x0);
//   serial->println(y0);
//   serial->println(x1);
//   serial->println(y1);
  
  return res;

// 	const float w = (const float)(rect[2] - rect[0]);
// 	const float h = (const float)(rect[3] - rect[1]);
// 
// 	const float center_x = (const float)(rect[0]) + (w / 2.0f);
// 	const float center_y = (const float)(rect[1]) + (h / 2.0f);
// 
// 	float delta_x = gaze_x - center_x;
// 	float delta_y = gaze_y - center_y;
// 
// 	float delta_x2 = delta_x * delta_x;
// 	float delta_y2 = delta_y * delta_y;
// 
// 	float dist = sqrt(delta_x2 + delta_y2);
//   
//   serial->println("Name: ");
//   serial->println(name);
//   serial->println("Width: ");
//   serial->println(w);
//   serial->println("Height: ");
//   serial->println(h);
//   serial->println("Dist: ");
//   serial->println(dist);
//   serial->println("Radius: ");
//   serial->println(radius);
//   serial->println("X: ");
//   serial->println(gaze_x);
//   serial->println("Y: ");
//   serial->println(gaze_y);
//   serial->println("In bounds? ");
//   serial->println(dist <= radius);
// 
// 	return dist <= radius;
}