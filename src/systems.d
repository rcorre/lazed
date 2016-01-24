module systems;


import std.container.slist;

import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;

import events;
import entities;
import components;

class RenderSystem : System {
    private ALLEGRO_BITMAP* _spritesheet;

    this(ALLEGRO_BITMAP* spritesheet) {
        _spritesheet = spritesheet;
    }

    override void run(EntityManager entities, EventManager events, Duration dt) {
        al_clear_to_color(al_map_rgb(0,0,0));

        // store old transformation to restore later.
        ALLEGRO_TRANSFORM oldTrans;
        al_copy_transform(&oldTrans, al_get_current_transform());

        // holding optimizes multiple draws from the same spritesheet
        al_hold_bitmap_drawing(true);

        foreach (entity; entities.entitiesWith!(Sprite, Transform)) {
            auto trans = entity.component!Transform.allegroTransform;
            al_use_transform(&trans);

            auto r = entity.component!Sprite.rect;
            al_draw_bitmap_region(_spritesheet, r.min.x, r.min.y, r.width,
                                  r.height, 0, 0, 0);
        }

        al_hold_bitmap_drawing(false);

        // restore previous transform
        al_use_transform(&oldTrans);

        al_flip_display();
    }
}

class MotionSystem : System {
    override void run(EntityManager entities, EventManager events, Duration dt) {
        foreach (entity; entities.entitiesWith!(Transform, Velocity)) {
            auto linear = entity.component!Velocity.linear;
            auto time = dt.total!"msecs" / 1000f;
            auto trans = entity.component!Transform;

            trans.pos = trans.pos + linear * time;
        }
    }
}

class InputSystem : System, Receiver!KeyboardEvent {
    SList!KeyboardEvent _queue;

    this(EventManager events) {
        events.subscribe!KeyboardEvent(this);
    }

    override void run(EntityManager es, EventManager events, Duration dt) {
        while(!_queue.empty) {
            auto ev = _queue.front;
            _queue.removeFront();

            foreach (ent; es.entitiesWith!InputListener) {
                if (ev.type == ALLEGRO_EVENT_KEY_DOWN)
                    ent.component!InputListener.keyDown(ent, ev.key);
                else if (ev.type == ALLEGRO_EVENT_KEY_UP)
                    ent.component!InputListener.keyUp(ent, ev.key);
            }
        }
    }

    void receive(KeyboardEvent ev) {
        _queue.insertFront(ev);
    }
}
