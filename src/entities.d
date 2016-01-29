module entities;

import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;

import components;

private:
enum spriteSize = 32; // size of grid in spritesheet

enum SpriteRect {
    player = spriteAt(3, 2)
}

auto spriteAt(int row, int col) {
    return box2i(col       * spriteSize,
                 row       * spriteSize,
                 (col + 1) * spriteSize,
                 (row + 1) * spriteSize);
}

public:
void createPlayer(EntityManager em) {
    enum speed = 100; // px / sec

    auto ent = em.create();

    ent.register!Transform(vec2f(400, 400));
    ent.register!Velocity();
    ent.register!Sprite(SpriteRect.player);

    auto input = ent.register!InputListener();

    input.keyDown = (em, self, key) {
        switch(key) {
            case ALLEGRO_KEY_W: self.component!Velocity.linear.y -= speed; break;
            case ALLEGRO_KEY_S: self.component!Velocity.linear.y += speed; break;
            case ALLEGRO_KEY_A: self.component!Velocity.linear.x -= speed; break;
            case ALLEGRO_KEY_D: self.component!Velocity.linear.x += speed; break;
            default:
        }
    };

    input.keyUp = (em, self, key) {
        switch(key) {
            case ALLEGRO_KEY_W: self.component!Velocity.linear.y += speed; break;
            case ALLEGRO_KEY_S: self.component!Velocity.linear.y -= speed; break;
            case ALLEGRO_KEY_A: self.component!Velocity.linear.x += speed; break;
            case ALLEGRO_KEY_D: self.component!Velocity.linear.x -= speed; break;
            default:
        }
    };

    // face the mouse
    input.mouseMoved = (em, self, pos) {
        import std.math : atan2;
        auto disp = pos - self.component!Transform.pos;
        self.component!Transform.angle = atan2(disp.y, disp.x);
    };

    // fire a laser
    input.mouseDown = (em, self, pos, button) {
        em.createLaser(self.component!Transform.pos, pos);
    };
}

void createLaser(EntityManager em, vec2f start, vec2f end) {
    immutable color = al_map_rgb(255, 0, 0);
    enum thickness = 4;
    enum fadePerSec = 2f; // fade 100% over 0.5s

    auto laser = em.create();

    auto line = laser.register!Line([ start, end ], color, thickness);

    auto timer = laser.register!Timer(0f);
    timer.onTick = (em, self, elapsed) {
        // fade over time, destroy self when totally faded
        auto line = self.component!Line;
        line.color.r -= elapsed * fadePerSec;
        if (line.color.r <= 0) self.destroy();
    };
}
