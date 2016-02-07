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

        auto player = entities.createPlayer;

        systems.register(new RenderSystem(_spritesheet, player));
        systems.register(new MotionSystem);
        systems.register(new InputSystem(events));
        systems.register(new LineRenderSystem(player));
        systems.register(new TimerSystem);
        systems.register(new AnimationSystem);

        entities.createMap("content/map0.json");
    }

    ~this() {
        al_destroy_bitmap(_spritesheet);
    }

    void update(Duration dt) {
        al_clear_to_color(al_map_rgb(0,0,0));
        systems.run(dt);
        al_flip_display();
    }

    void process(in ALLEGRO_EVENT ev) {
        events.emit!AllegroEvent(ev);
    }
}
