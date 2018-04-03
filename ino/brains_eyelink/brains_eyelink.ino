#include "eyelink.h"
#include "stimulation.h"

#define __DEBUG__
#define __PRINT_M1_GAZE__

namespace PROTOCOLS {
    enum PROTOCOLS
    {
        MUTUAL_EVENT = 0,
        M1_EXCLUSIVE_EVENT = 1,
        M2_EXCLUSIVE_EVENT = 2,
        EXCLUSIVE_EVENT = 3,
        ANY_EVENT = 4,
        PROBABILISTIC = 5
    };

    PROTOCOLS current_protocol = MUTUAL_EVENT;

    const int N_PROTOCOLS = 6;
}

struct IDS
{
    const char eol = '\n';
    const char init = '*';
    //	indicates that command will be a rect-bounds
    const char bounds = 'o';
    //	indicates that command will be a stimulation parameter
    const char stim_param = 't';
    const char stim_stop_start = 'r';
    const char global_stim_timeout = 'q';
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
    const int stimulation_trigger = 4;
} pins;

//
//	stimulation protocol
//

stimulation_protocol STIM_PROTOCOL(pins.stimulation_trigger);

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

//
//  protocol_probabilistic: Stimulate regardless of looking events.
//
void protocol_probabilistic()
{
    for (int i = 0; i < ROI_INDICES::N_ROI_INDICES; i++)
    {
        if (STIM_PROTOCOL.conditional_stimulate(i, timing::this_frame))
        {
            //  mark stimulating
        }
    }
}

//
//  protocol_gaze_event: Stimulate on gaze event
//
void protocol_gaze_event()
{   
    for (unsigned int i = 0; i < ROI_INDICES::N_ROI_INDICES; i++)
    {
        bool m1_in = m1_gaze->in_bounds((ROI_INDICES::ROI_INDICES) i);
        bool m2_in = m2_gaze->in_bounds((ROI_INDICES::ROI_INDICES) i);
        bool mut = m1_in && m2_in;
        bool any = m1_in || m2_in;

        switch (PROTOCOLS::current_protocol)
        {
            case PROTOCOLS::MUTUAL_EVENT:
                if (mut && STIM_PROTOCOL.conditional_stimulate(i, timing::this_frame))
                {
                    //
                }
                break;
            case PROTOCOLS::M1_EXCLUSIVE_EVENT:
                if (m1_in && STIM_PROTOCOL.conditional_stimulate(i, timing::this_frame))
                {
                    //
                }
                break;
            case PROTOCOLS::M2_EXCLUSIVE_EVENT:
                if (m2_in && STIM_PROTOCOL.conditional_stimulate(i, timing::this_frame))
                {
                    //
                }
                break;
            case PROTOCOLS::EXCLUSIVE_EVENT:
                if (!mut && STIM_PROTOCOL.conditional_stimulate(i, timing::this_frame))
                {
                    //
                }
                break;
            case PROTOCOLS::ANY_EVENT:
                if (any && STIM_PROTOCOL.conditional_stimulate(i, timing::this_frame))
                {
                    //
                }
                break;
            default:
                break;
        }
    }
}

void handle_new_stim_param()
{
	char id;
	int roi_index;
	int param;

	get_stimulation_parami(&id, &roi_index, &param);

	if (roi_index < 0 || param < 0 || id == ids.error || roi_index >= ROI_INDICES::N_ROI_INDICES)
	{
		Serial.print(ids.error);
		return;
	}

	char response = ids.ack;

    if (id == ids.protocol)
    {
        if (param >= PROTOCOLS::N_PROTOCOLS)
        {
            response = ids.error;
        }
        else
        {
            PROTOCOLS::current_protocol = (PROTOCOLS::PROTOCOLS) param;
        }
    }
	else if (id == ids.probability)
	{
        bool status = STIM_PROTOCOL.set_probability(roi_index, param);

        if (!status)
        {
            response = ids.error;
        }
	}
	else if (id == ids.frequency)
	{
		bool status = STIM_PROTOCOL.set_frequency(roi_index, param);

        if (!status)
        {
            response = ids.error;
        }
	}
  else if (id == ids.global_stim_timeout)
  {
    if (param == 0)
    {
      STIM_PROTOCOL.set_is_global_stimulation_timeout(false);
    }
    else if (param == 1)
    {
      STIM_PROTOCOL.set_is_global_stimulation_timeout(true);
    }
    else
    {
      response = ids.error;
    }
  }
	else if (id == ids.stim_stop_start)
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

    manager->set_rect_element((ROI_INDICES::ROI_INDICES) roi_index, roi_element_index, value);

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
    randomSeed(analogRead(0));
    
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

    STIM_PROTOCOL.update(timing::delta);

    if (PROTOCOLS::current_protocol != PROTOCOLS::PROBABILISTIC)
    {
        protocol_gaze_event();
    }
    else
    {
        protocol_probabilistic();
    }

    timing::last_frame = timing::this_frame;
}
