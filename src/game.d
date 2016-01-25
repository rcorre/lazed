module game;

import entitysysd;
import allegro5.allegro;

import events;
import systems;
import entities;
import components;

class Game : EntitySysD {
    private ALLEGRO_BITMAP* _spritesheet;

    this() {
        super();

        _spritesheet = al_load_bitmap("content/spritesheet.png");

        systems.register(new RenderSystem(_spritesheet));
        systems.register(new MotionSystem());
        systems.register(new InputSystem(events));

        entities.createPlayer;
    }

    ~this() {
        al_destroy_bitmap(_spritesheet);
    }

    void update(Duration dt) {
        systems.run(dt);
    }

    void process(in ALLEGRO_EVENT ev) {
        switch(ev.type) {
            case ALLEGRO_EVENT_KEY_DOWN:
            case ALLEGRO_EVENT_KEY_UP:
                events.emit!KeyboardEvent(ev.type, ev.keyboard.keycode);
                break;
            default:
        }
    }
}
