module components;

import std.typecons : Flag;

import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;

@component:

struct Transform {
    vec2f pos = [0,0];
    vec2f scale = [1,1];
    float angle = 0;

    /// Convert to an ALLEGRO_TRANSFORM.
    auto allegroTransform() {
        ALLEGRO_TRANSFORM trans;

        al_identity_transform(&trans);
        al_scale_transform(&trans, scale.x, scale.y);
        al_rotate_transform(&trans, angle);
        al_translate_transform(&trans, pos.x, pos.y);

        return trans;
    }
}

struct Sprite {
    box2i rect;
    ALLEGRO_BITMAP *bmp;
    ALLEGRO_COLOR tint = ALLEGRO_COLOR(1,1,1,1);
}

struct InputListener {
    void function(EntityManager em, Entity self, int key)               keyDown    = (a,b,c) { };
    void function(EntityManager em, Entity self, int key)               keyUp      = (a,b,c) { };
    void function(EntityManager em, Entity self, vec2f pos)             mouseMoved = (a,b,c) { };
    void function(EntityManager em, Entity self, vec2f pos, int button) mouseDown  = (a,b,c,d) { };
    void function(EntityManager em, Entity self, vec2f pos, int up)     mouseUp    = (a,b,c,d) { };
}

struct Collider {
    box2f rect;
    bool reflective;
}

struct PlayerCollider {
    float radius;
}

struct Velocity {
    float speed = 0f;
    vec2f linear = [0,0];
}

struct Timer {
    alias TickHandler = void function(EntityManager em, Entity self, float elapsed);

    float duration, countdown;
    TickHandler onTick;

    this(float duration) {
        this.duration = this.countdown = duration;
    }
}

struct Line {
    vec2f[] nodes;
    ALLEGRO_COLOR color;
    float thickness;
}

struct Animator {
    float duration, countdown;
    int frame;
    box2i start;
    vec2i offset;
    bool run;

    this(float duration, box2i start, vec2i offset) {
        this.duration = this.countdown = duration;
        this.start = start;
        this.offset = offset;
    }
}

struct Equipment {
    void function(Entity self, bool on) onToggle;
    bool on;
}

struct SpeedBoost {
    float factor = 1f;
}
