#include "eyelink.h"

#define __DEBUG__

struct IDS
{
    const char eol = '\n';
    const char init = '*';
    const char bounds = 'o';
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

char BUFFER[32];

//
//  main
//

el_manager *m1_gaze = NULL;
el_manager *m2_gaze = NULL;

void handle_serial_comm()
{
    if (!Serial.available())
        return;
        
    char identifier = Serial.read();
    if (identifier == ids.bounds)
    {
        handle_new_bounds();
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

    //
    //  compare here
    //

    // if (m1f && m2f)
}

void handle_new_bounds()
{
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

    int roi_index = -1;

    if (roi_id == ids.screen)
        roi_index = ROI_INDICES::screen;
    else if (roi_id == ids.face)
        roi_index = ROI_INDICES::face;
    else if (roi_id == ids.eyes)
        roi_index = ROI_INDICES::eyes;
    else if (roi_id == ids.mouth)
        roi_index = ROI_INDICES::mouth;
    else
        Serial.print(ids.error);

    if (roi_index == -1)
        return;

    el_manager *manager = NULL;

    long value = atol(BUFFER);
    int roi_element_index = atoi(rect_indices);

    if (m_id == ids.m1)
        manager = m1_gaze;
    else if (m_id == ids.m2)
        manager = m2_gaze;
    else
        Serial.print(ids.error);

    if (!manager) 
      return;

    manager->set_rect_element(roi_index, roi_element_index, value);

    Serial.print(ids.ack);
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
    handle_serial_comm();

    m1_gaze->update();
    m2_gaze->update();

    gaze_check();
}
