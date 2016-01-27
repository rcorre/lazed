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
    void function(Entity self, int key) keyDown;
    void function(Entity self, int key) keyUp;
    void function(Entity self, vec2f pos) mouseMoved;
}

struct Collider {
    box2f rect;
    bool reflective;
}

struct Velocity {
    vec2f linear = [0,0];
}

struct Timer {
    ALLEGRO_TIMER *timer;
    void function(Entity self) onTick;
}
