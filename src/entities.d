module entities;

import dtiled;
import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;

import components;

private:
enum spriteSize = 32; // size of grid in spritesheet
enum animationOffset = vec2i(32 * 4, 0); // space between animation frames

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
    ent.register!Animator(0.1f, SpriteRect.player, animationOffset);

    auto input = ent.register!InputListener();

    input.keyDown = (em, self, key) {
        auto ref vel() { return self.component!Velocity.linear; }

        switch(key) {
            case ALLEGRO_KEY_W: vel.y -= speed; break;
            case ALLEGRO_KEY_S: vel.y += speed; break;
            case ALLEGRO_KEY_A: vel.x -= speed; break;
            case ALLEGRO_KEY_D: vel.x += speed; break;
            default:
        }

        self.component!Animator.run = vel.length > 0; // animate if moving
    };

    input.keyUp = (em, self, key) {
        auto ref vel() { return self.component!Velocity.linear; }

        switch(key) {
            case ALLEGRO_KEY_W: vel.y += speed; break;
            case ALLEGRO_KEY_S: vel.y -= speed; break;
            case ALLEGRO_KEY_A: vel.x += speed; break;
            case ALLEGRO_KEY_D: vel.x -= speed; break;
            default:
        }

        self.component!Animator.run = vel.length > 0; // animate if moving
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

void createMap(EntityManager em, string path) {
  auto mapData = MapData.load(path);
  auto tileset = mapData.tilesets[0];
  immutable tw = tileset.tileWidth;
  immutable th = tileset.tileHeight;

  foreach(idx, gid ; mapData.getLayer("walls").data) {
      if (!gid) continue;

      auto pos = vec2f((idx % mapData.numCols) * tw + tw / 2,
                       (idx / mapData.numCols) * th + th / 2);

      auto region = box2i(tileset.tileOffsetX(gid),
                          tileset.tileOffsetY(gid),
                          tileset.tileOffsetX(gid) + tileset.tileWidth,
                          tileset.tileOffsetY(gid) + tileset.tileHeight);

      auto ent = em.create();
      ent.register!Transform(pos);
      ent.register!Sprite(region);
  }
}
