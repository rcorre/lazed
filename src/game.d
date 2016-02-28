module game;

import entitysysd;
import allegro5.allegro;

import events;
import systems;
import entities;
import components;

abstract class Game : EntitySysD {
    this() {
        super();

        // common systems
        systems.register(new MotionSystem);
        systems.register(new TimerSystem);
        systems.register(new PickupSystem);

        entities.createMap("content/map0.json");
    }

    abstract void update(Duration dt);

    abstract void process(in ALLEGRO_EVENT ev);
}

class ClientGame : Game {
    private ALLEGRO_BITMAP* _spritesheet;

    this() {
        import std.stdio;
        writeln("client");
        super();

        _spritesheet = al_load_bitmap("content/spritesheet.png");

        auto player = entities.createPlayer;

        systems.register(new NetClientSystem);
        systems.register(new InputSystem(events));
        systems.register(new NetClientSystem);
        systems.register(new RenderSystem(_spritesheet, player));
        systems.register(new LineRenderSystem(player));
        systems.register(new AnimationSystem);

        entities.createMap("content/map0.json");
    }

    ~this() {
        al_destroy_bitmap(_spritesheet);
    }

override:
    void update(Duration dt) {
        al_clear_to_color(al_map_rgb(0,0,0));
        systems.run(dt);
        al_flip_display();
    }

    void process(in ALLEGRO_EVENT ev) {
        events.emit!AllegroEvent(ev);
    }
}

class ServerGame : Game {
    this() {
        // TODO: remove me!
        import std.stdio;
        writeln("server");
        super();
        systems.register(new NetServerSystem);
        entities.createMap("content/map0.json");
    }

override:
    void update(Duration dt) {
        systems.run(dt);
    }

    void process(in ALLEGRO_EVENT ev) { }
}
