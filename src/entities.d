module entities;

import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;

import components;

private:
enum spriteSize = 16; // size of grid in spritesheet


enum SpriteRect {
    player = box2i(spriteSize * 0, spriteSize * 0, spriteSize, spriteSize)
}

public:
void createPlayer(EntityManager entities) {
    enum speed = 100; // px / sec

    auto ent = entities.create();

    ent.register!Transform(vec2f(400, 400));
    ent.register!Velocity();
    ent.register!Sprite(SpriteRect.player);

    auto input = ent.register!InputListener();

    input.keyDown = (self, key) {
        switch(key) {
            case ALLEGRO_KEY_W: self.component!Velocity.linear.y -= speed; break;
            case ALLEGRO_KEY_S: self.component!Velocity.linear.y += speed; break;
            case ALLEGRO_KEY_A: self.component!Velocity.linear.x -= speed; break;
            case ALLEGRO_KEY_D: self.component!Velocity.linear.x += speed; break;
            default:
        }
    };

    input.keyUp = (self, key) {
        switch(key) {
            case ALLEGRO_KEY_W: self.component!Velocity.linear.y += speed; break;
            case ALLEGRO_KEY_S: self.component!Velocity.linear.y -= speed; break;
            case ALLEGRO_KEY_A: self.component!Velocity.linear.x += speed; break;
            case ALLEGRO_KEY_D: self.component!Velocity.linear.x -= speed; break;
            default:
        }
    };

    // face the mouse
    input.mouseMoved = (self, pos) {
        import std.math : atan2;
        auto disp = pos - self.component!Transform.pos;
        self.component!Transform.angle = atan2(disp.y, disp.x);
    };
}
