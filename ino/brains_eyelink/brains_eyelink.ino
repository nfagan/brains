#include "eyelink.h"
#include "stimulation.h"

#define __DEBUG__
#define __PRINT_M1_GAZE__

struct IDS
{
    const char eol = '\n';
    const char init = '*';
    //	indicates that command will be a rect-bounds
    const char bounds = 'o';
    //	indicates that command will be a stimulation parameter
    const char stim_param = 't';
    const char stim_stop_start = 'r';
	const char probability = 'y';
	const char frequency = 'u';
	const char protocol = 'i';
    const char screen = 's';
    const char eyes = 'e';
    const char mouth = 'm';
    const char face = 'f';
    const char error = '!';
    const char ack = 'a';
    const char m1 = 'j';
    const char m2 = 'k';
    const char print_gaze = 'p';
} ids;

struct PINS
{
    const int m1_x = 0;
    const int m1_y = 1;
    const int m2_x = 2;
    const int m2_y = 3;
} pins;

//
//	stimulation protocol
//

stimulation_protocol STIM_PROTOCOL;

//
//  main
//

el_manager* m1_gaze = NULL;
el_manager* m2_gaze = NULL;

//
// timing info
//

namespace timing {
	unsigned long last_frame = 0;
	unsigned long this_frame = 0;
	unsigned long delta = 0;
}

void handle_serial_comm()
{
    if (!Serial.available())
    {
    	return;
    }
        
    char identifier = Serial.read();

    if (identifier == ids.bounds)
    {
        handle_new_bounds();
    }
    else if (identifier == ids.stim_param)
    {
    	handle_new_stim_param();
    }
    else if (identifier == ids.print_gaze)
    {
        debug_print();
        Serial.read();
    }
    else
    {
        Serial.print(ids.error);
    }
}

void debug_print()
{
    m1_gaze->print_gaze();
    m1_gaze->print_bounds();
    m2_gaze->print_gaze();
    m2_gaze->print_bounds();
}

void gaze_check()
{   
    bool m1f = m1_gaze->in_bounds(ROI_INDICES::face);
    bool m2f = m2_gaze->in_bounds(ROI_INDICES::face);

    bool m1e = m1_gaze->in_bounds(ROI_INDICES::eyes);
    bool m2e = m2_gaze->in_bounds(ROI_INDICES::eyes);

    bool m1m = m1_gaze->in_bounds(ROI_INDICES::mouth);
    bool m2m = m2_gaze->in_bounds(ROI_INDICES::mouth);

    if (m1f && m2f)
    {
        Serial.println("BOTH IN BOUNDS");
    }

    if (m1f)
    {
        Serial.println("M1 IN BOUNDS");
    }

    if (m2f)
    {
        Serial.println("M2 IN BOUNDS");
    }

    //
    //  compare here
    //

    // if (m1f && m2f)
}

void handle_new_stim_param()
{
	char id;
	int roi_index;
	int param;

	get_stimulation_parami(&id, &roi_index, &param);

	if (roi_index == -1 || param == -1 || id == ids.error || roi_index > ROI_INDICES::N_ROI_INDICES)
	{
		Serial.print(ids.error);
		return;
	}

	char response = ids.ack;

	if (id == ids.probability)
	{
		STIM_PROTOCOL.set_probability(roi_index, param);
	}
	else if (id == ids.frequency)
	{
		STIM_PROTOCOL.set_frequency(roi_index, param);
	}
	else if (id == ids.protocol)
	{
		STIM_PROTOCOL.set_protocol(roi_index, param);	
	}
	else if (id == ids.begin_stim)
	{
		if (param == 0)
		{
			STIM_PROTOCOL.disallow_stimulation(roi_index);
		}
		else if (param == 1)
		{
			STIM_PROTOCOL.allow_stimulation(roi_index);
		}
		else
		{
			response = ids.error;
		}
	}
	else
	{
		response = ids.error;
	}

	Serial.print(response);
}

void handle_new_bounds()
{
	char BUFFER[32];

    static const int n_ids = 3;
    static char identifiers[n_ids] = { 'a', 'a', 'a' };
    static char rect_indices[2] = { 'a', 'a' };
    int n_read;

    n_read = Serial.readBytes(&identifiers[0], n_ids);

    if (n_read != n_ids)
    {
        Serial.print(ids.error);
        return;
    }

    n_read = Serial.readBytesUntil(ids.eol, BUFFER, sizeof(BUFFER)-1);

    if (n_read == 0)
    {
        Serial.print(ids.error);
        return;
    }

    BUFFER[n_read] = '\0';

    char m_id = identifiers[0];
    char roi_id = identifiers[1];

    rect_indices[0] = identifiers[2];
    rect_indices[1] = '\0';

    int roi_index = get_roi_index_from_id(roi_id);

    if (roi_index == -1)
    {
    	Serial.print(ids.error);
        return;
    }

    el_manager* manager = NULL;

    long value = atol(BUFFER);
    int roi_element_index = atoi(rect_indices);

    if (m_id == ids.m1)
        manager = m1_gaze;
    else if (m_id == ids.m2)
        manager = m2_gaze;
    else
        Serial.print(ids.error);

    if (!manager)
    {
    	return;
    }

    manager->set_rect_element(roi_index, roi_element_index, value);

    Serial.print(ids.ack);
}

int get_roi_index_from_id(char roi_id)
{
	if (roi_id == ids.screen) return ROI_INDICES::screen;
    else if (roi_id == ids.face) return ROI_INDICES::face;
    else if (roi_id == ids.eyes) return ROI_INDICES::eyes;
    else if (roi_id == ids.mouth) return ROI_INDICES::mouth;
    return -1;
}

void get_stimulation_parami(char* id, int* roi_idx, int* param)
{
	char param_buffer[32];
    char identifiers[2] = { 'a', 'a' };
    int n_ids = sizeof(identifiers);
    int n_read;

    *roi_idx = -1;
    *param = -1;
    *id = ids.error;

    n_read = Serial.readBytes(&identifiers[0], n_ids);

    if (n_read != n_ids)
    {
        return;
    }

    n_read = Serial.readBytesUntil(ids.eol, param_buffer, sizeof(param_buffer)-1);

    if (n_read == 0)
    {
        return;
    }

    param_buffer[n_read] = '\0';

    char param_id = identifiers[0];
    char roi_id = identifiers[1];

    *id = param_id;
    *roi_idx = get_roi_index_from_id(roi_id);
    *param = atoi(param_buffer);
}

void setup()
{
    
    while (!Serial)
    {
        //
    }

    Serial.begin(9600);
    
    Serial.print(ids.init);

    m1_gaze = new el_manager(&Serial, pins.m1_x, pins.m1_y);
    m2_gaze = new el_manager(&Serial, pins.m2_x, pins.m2_y);

    m1_gaze->init_pins();
    m2_gaze->init_pins();

    m1_gaze->set_name("M1");
    m2_gaze->set_name("M2");
}

void loop() 
{  
	timing::this_frame = millis();
	timing::delta = timing::this_frame - timing::last_frame;

    handle_serial_comm();

    m1_gaze->update();
    m2_gaze->update();

    STIM_PROTOCOL->update(timing::delta);

    gaze_check();

    timing::last_frame = timing::this_frame;
}
