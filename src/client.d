import std.datetime;

import allegro5.allegro;
import allegro5.allegro_image;
import allegro5.allegro_primitives;
import derelict.enet.enet;

import game;
import constants;

void main() {
    if (!al_init()) assert(0, "al_init failed!");

    DerelictENet.load();
    if (enet_initialize()) assert(0, "enet_initialize failed");

    auto display = al_create_display(screenW, screenH);
    auto queue   = al_create_event_queue();

    al_install_keyboard();
    al_install_mouse();
    al_init_image_addon();
    al_init_primitives_addon();

    auto fpsTimer = al_create_timer(1.0 / 60);

    al_register_event_source(queue, al_get_display_event_source(display));
    al_register_event_source(queue, al_get_keyboard_event_source());
    al_register_event_source(queue, al_get_mouse_event_source());
    al_register_event_source(queue, al_get_timer_event_source(fpsTimer));

    // TODO: remove me!
    import std.stdio;
    writeln("client");
    auto game = new ClientGame();

    al_start_timer(fpsTimer);

    bool exit      = false;
    bool update    = false;
    auto timestamp = MonoTime.currTime;

    while(!exit) {
        ALLEGRO_EVENT event;
        al_wait_for_event(queue, &event);

        switch(event.type) {
            case ALLEGRO_EVENT_TIMER:
                update = update || (event.timer.source == fpsTimer);
                break;
            case ALLEGRO_EVENT_DISPLAY_CLOSE:
                exit = true;
                break;
            default:
        }

        game.process(event);

        if (update) {
            update = false;
            auto now = MonoTime.currTime;
            auto elapsed = now - timestamp;
            game.update(elapsed);
            timestamp = now;
        }
    }

    al_destroy_display(display);
    al_destroy_event_queue(queue);
}
