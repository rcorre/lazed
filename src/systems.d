module systems;

import std.range;
import std.container.slist;

import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;
import allegro5.allegro_primitives;

import events;
import entities;
import components;

class RenderSystem : System {
    private ALLEGRO_BITMAP* _spritesheet;

    this(ALLEGRO_BITMAP* spritesheet) {
        _spritesheet = spritesheet;
    }

    override void run(EntityManager em, EventManager events, Duration dt) {
        // store old transformation to restore later.
        ALLEGRO_TRANSFORM oldTrans;
        al_copy_transform(&oldTrans, al_get_current_transform());

        // holding optimizes multiple draws from the same spritesheet
        al_hold_bitmap_drawing(true);

        ALLEGRO_TRANSFORM trans;
        foreach (entity; em.entitiesWith!(Sprite, Transform)) {
            auto entityTrans = entity.component!Transform.allegroTransform;
            auto r = entity.component!Sprite.rect;

            al_identity_transform(&trans);
            // place the origin of the sprite at its center
            al_translate_transform(&trans, -r.width / 2, -r.height / 2);
            al_compose_transform(&trans, &entityTrans);
            al_use_transform(&trans);

            al_draw_bitmap_region(_spritesheet,
                                  r.min.x, r.min.y, r.width, r.height,
                                  0, 0,
                                  0);
        }

        al_hold_bitmap_drawing(false);

        // restore previous transform
        al_use_transform(&oldTrans);
    }
}

class MotionSystem : System {
    override void run(EntityManager em, EventManager events, Duration dt) {
        foreach (entity, trans, vel; em.entitiesWith!(Transform, Velocity)) {
            auto time = dt.total!"msecs" / 1000f;
            trans.pos = trans.pos + vel.linear * time;
        }
    }
}

class InputSystem : System, Receiver!AllegroEvent {
    SList!AllegroEvent _queue;

    this(EventManager events) {
        events.subscribe!AllegroEvent(this);
    }

    override void run(EntityManager es, EventManager events, Duration dt) {
        auto pos(ALLEGRO_EVENT ev) {
            return vec2f(ev.mouse.x, ev.mouse.y);
        }

        while(!_queue.empty) {
            auto ev = _queue.front;
            _queue.removeFront();

            foreach (ent, listener; es.entitiesWith!InputListener) {
                switch (ev.type) {
                    case ALLEGRO_EVENT_KEY_DOWN:
                        listener.keyDown(es, ent, ev.keyboard.keycode);
                        break;
                    case ALLEGRO_EVENT_KEY_UP:
                        listener.keyUp(es, ent, ev.keyboard.keycode);
                        break;
                    case ALLEGRO_EVENT_MOUSE_AXES:
                        listener.mouseMoved(es, ent, pos(ev));
                        break;
                    case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
                        listener.mouseDown(es, ent, pos(ev), ev.mouse.button);
                        break;
                    case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
                        listener.mouseUp(es, ent, pos(ev), ev.mouse.button);
                        break;
                    default:
                }
            }
        }
    }

    void receive(AllegroEvent ev) {
        _queue.insertFront(ev);
    }
}

class LineRenderSystem : System {
    override void run(EntityManager em, EventManager events, Duration dt) {
        foreach (line; em.components!Line)
            foreach (start, end ; line.nodes.lockstep(line.nodes.drop(1)))
                al_draw_line(start.x, start.y, end.x, end.y, line.color, line.thickness);
    }
}

class TimerSystem : System {
    override void run(EntityManager em, EventManager events, Duration dt) {
        foreach (ent, timer; em.entitiesWith!Timer) {
            immutable elapsed = dt.total!"msecs" / 1000f;

            if ((timer.countdown -= elapsed) < 0) {
                timer.countdown = timer.duration;
                timer.onTick(em, ent, elapsed);
            }
        }
    }
}

class AnimationSystem : System {
    private enum maxFrame = 8;  // all animations have 8 frames

    override void run(EntityManager em, EventManager events, Duration dt) {
        foreach (ent, ani, sprite; em.entitiesWith!(Animator, Sprite)) {
            immutable elapsed = dt.total!"msecs" / 1000f;

            if (ani.run && (ani.countdown -= elapsed) < 0) {
                ani.countdown = ani.duration;
                ani.frame = (ani.frame + 1) % maxFrame;
            }

            sprite.rect = ani.start.translate(ani.offset * ani.frame);
        }
    }
}
