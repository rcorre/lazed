import std.datetime;

import allegro5.allegro;
import allegro5.allegro_image;
import allegro5.allegro_primitives;

import game;
import constants;

void main() {
    if (!al_init()) assert(0, "al_init failed!");

    auto queue   = al_create_event_queue();

    auto fpsTimer = al_create_timer(1.0 / 60);

    al_register_event_source(queue, al_get_timer_event_source(fpsTimer));

    auto game = new ServerGame();

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

    al_destroy_event_queue(queue);
}
