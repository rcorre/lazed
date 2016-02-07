module systems;

import std.range;
import std.algorithm;
import std.container.slist;

import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;
import allegro5.allegro_primitives;

import events;
import geometry;
import entities;
import constants;
import components;

class RenderSystem : System {
    private ALLEGRO_BITMAP* _spritesheet;
    private Entity _camera;

    this(ALLEGRO_BITMAP* spritesheet, Entity camera) {
        _spritesheet = spritesheet;
        _camera = camera;
    }

    override void run(EntityManager em, EventManager events, Duration dt) {
        assert(_camera.valid && _camera.isRegistered!Transform);

        // store old transformation to restore later.
        ALLEGRO_TRANSFORM oldTrans;
        al_copy_transform(&oldTrans, al_get_current_transform());

        // holding optimizes multiple draws from the same spritesheet
        al_hold_bitmap_drawing(true);

        ALLEGRO_TRANSFORM trans, baseTrans;

        auto cameraPos = _camera.component!Transform.pos;

        // set up the camera offset
        al_identity_transform(&baseTrans);
        al_translate_transform(&baseTrans,
                               -cameraPos.x + screenW / 2,
                               -cameraPos.y + screenH / 2);

        foreach (entity; em.entitiesWith!(Sprite, Transform)) {
            auto entityTrans = entity.component!Transform.allegroTransform;
            auto r = entity.component!Sprite.rect;

            // reset the current drawing transform
            al_identity_transform(&trans);

            // place the origin of the sprite at its center
            al_translate_transform(&trans, -r.width / 2, -r.height / 2);

            // apply the transform of the current entity
            al_compose_transform(&trans, &entityTrans);

            // finally, translate everything by the camera
            al_compose_transform(&trans, &baseTrans);

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
        auto walls = em.components!Collider
            .array
            .map!(x => x.rect.edges)
            .joiner;

        foreach (ent, trans, vel; em.entitiesWith!(Transform, Velocity)) {
            auto time = dt.total!"msecs" / 1000f;
            auto end = trans.pos + vel.linear * vel.speed * time;

            auto coll = ent.component!PlayerCollider;

            if (coll !is null) {
                auto closer(vec2f a, vec2f b) {
                    return a.squaredDistanceTo(trans.pos) <
                           b.squaredDistanceTo(trans.pos);
                }

                auto disp = seg2f(trans.pos, end);
                auto hits = walls
                    .map!(wall => wall.intersect(disp)) // intersect wall and displacement
                    .filter!(x => x)                    // remove non-hits
                    .minPos!((a,b) => closer(a,b));     // take the closest hit

                if (hits.empty) trans.pos = end;
            }
            else {
                trans.pos = end;
            }
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
