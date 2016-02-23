module events;

import std.meta;

import constants;

import gfm.math;
import entitysysd;
import allegro5.allegro;

alias NetMsgTypes = AliasSeq!(MotionRequest, LookRequest);

@event:

/// Wraps an allegro-generated event to pass it through the ECS event framework
struct AllegroEvent {
    ALLEGRO_EVENT ev;
    alias ev this;
}

/// A player is requesting to set their velocity (e.g. WASD input)
struct MotionRequest {
    NetId id;
    vec2f velocity;
}

/// A player is requesting to set their angle (mouse moved)
struct LookRequest {
    NetId id;
    float angle;
}
