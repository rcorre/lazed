module entities;

import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;

import components;

void createPlayer(EntityManager entities, ALLEGRO_BITMAP* spritesheet) {
    enum moveSpeed = 100; // px / sec

    auto ent = entities.create();

    auto trans  = ent.register!Transform(vec2f(400, 400));
    auto vel    = ent.register!Velocity();
    auto input  = ent.register!InputListener();
    auto sprite = ent.register!Sprite();

    input.keyDown = (self, key) {
        switch(key) {
            case ALLEGRO_KEY_W: self.component!Velocity.linear.y -= 1; break;
            case ALLEGRO_KEY_S: self.component!Velocity.linear.y += 1; break;
            case ALLEGRO_KEY_A: self.component!Velocity.linear.x -= 1; break;
            case ALLEGRO_KEY_D: self.component!Velocity.linear.x += 1; break;
            default:
        }
    };

    input.keyUp = (self, key) {
        switch(key) {
            case ALLEGRO_KEY_W: self.component!Velocity.linear.y += 1; break;
            case ALLEGRO_KEY_S: self.component!Velocity.linear.y -= 1; break;
            case ALLEGRO_KEY_A: self.component!Velocity.linear.x += 1; break;
            case ALLEGRO_KEY_D: self.component!Velocity.linear.x -= 1; break;
            default:
        }
    };

    sprite.bmp = spritesheet;
}
