module entities;

import std.range;
import std.algorithm;

import dtiled;
import gfm.math;
import entitysysd;
import allegro5.allegro;
import allegro5.allegro_color;

import geometry;
import constants;
import components;

private:
enum spriteSize = 32; // size of grid in spritesheet
enum animationOffset = vec2i(32, 0); // space between animation frames
enum maxLaserBounce = 5; // number of times a laser can reflect
enum pickupRespawnTime = 5; // seconds before a pickup respawns

struct SpriteRect {
    static immutable player = spriteAt(3, 0);
    static immutable speedPickup = spriteAt(4, 0);
    static immutable shieldPickup = spriteAt(4, 1);
}

auto spriteAt(int row, int col) {
    return box2i(col       * spriteSize,
                 row       * spriteSize,
                 (col + 1) * spriteSize,
                 (row + 1) * spriteSize);
}

public:
auto createPlayer(EntityManager em) {
    enum speed = 100; // px / sec

    auto ent = em.create();

    ent.register!Transform(vec2f(400, 400));
    ent.register!Velocity(speed);
    ent.register!Sprite(SpriteRect.player);
    ent.register!Animator(0.1f, SpriteRect.player, animationOffset);
    ent.register!PlayerCollider(12); // radius = 12

    auto input = ent.register!InputListener();

    input.keyDown = (em, self, key) {
        auto ref dir() { return self.component!Velocity.linear; }

        switch(key) {
            case ALLEGRO_KEY_W: dir.y -= 1; break;
            case ALLEGRO_KEY_S: dir.y += 1; break;
            case ALLEGRO_KEY_A: dir.x -= 1; break;
            case ALLEGRO_KEY_D: dir.x += 1; break;
            default:
        }

        self.component!Animator.run = dir.length > 0; // animate if moving
    };

    input.keyUp = (em, self, key) {
        auto ref dir() { return self.component!Velocity.linear; }

        switch(key) {
            case ALLEGRO_KEY_W: dir.y += 1; break;
            case ALLEGRO_KEY_S: dir.y -= 1; break;
            case ALLEGRO_KEY_A: dir.x += 1; break;
            case ALLEGRO_KEY_D: dir.x -= 1; break;
            default:
        }

        self.component!Animator.run = dir.length > 0; // animate if moving
    };

    // face the mouse
    input.mouseMoved = (em, self, pos) {
        import std.math : atan2;
        // for now, the player is always at the screen center
        // just use the offset from the center to the mouse
        auto disp = pos - vec2f(screenW, screenH) / 2;
        self.component!Transform.angle = atan2(disp.y, disp.x);
    };

    // fire a laser
    input.mouseDown = (em, self, pos, button) {

        if (button == 1) {
            // for now, the player is always at the screen center
            // compute direction from the screen center to the mouse
            auto heading = pos - vec2f(screenW, screenH) / 2 ;
            em.createLaser(self.component!Transform.pos, heading);
        }
        else if (self.isRegistered!Equipment) {
            auto item = self.component!Equipment;
            item.on = !item.on;
            item.onToggle(self, item.on);
        }
    };

    return ent;
}

void createLaser(EntityManager em, vec2f start, vec2f heading) {
    immutable color = al_map_rgb(255, 0, 0);
    enum thickness = 4;
    enum fadePerSec = 2f; // fade 100% over 0.5s

    // determine the path the laser takes
    auto nodes = [ start ];

    auto walls = em.components!Collider
        .array
        .map!(x => x.rect.edges)
        .joiner;

    foreach(i ; 0..maxLaserBounce) {
        auto ray = ray2f(nodes[$-1], heading);

        auto closer(vec2f a, vec2f b) {
            return a.squaredDistanceTo(ray.orig) < b.squaredDistanceTo(ray.orig);
        }

        import std.typecons : tuple;

        auto hits = walls
            .map!(seg => tuple(ray.intersect(seg), seg.normal)) // pair intersection with normal
            .filter!(x => x[0])                                 // remove non-hits
            .minPos!((a,b) => closer(a[0],b[0]));               // take the closest hit

        if (hits.empty) break; // we didn't hit anything

        nodes ~= hits.front[0];
        heading = heading.reflect(hits.front[1]);
    }

    auto laser = em.create();
    auto line = laser.register!Line(nodes, color, thickness);

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

  // create wall tiles
  foreach(idx, gid ; mapData.getLayer("walls").data) {
      if (!gid) continue; // ignore spaces with no tile

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

  // create colliders
  foreach(obj ; mapData.getLayer("collision").objects) {
      auto box = box2f(obj.x,
                       obj.y,
                       obj.x + obj.width,
                       obj.y + obj.height);

      bool reflective = obj.type == "reflect";

      auto ent = em.create();
      ent.register!Collider(box, reflective);
  }

  foreach(obj ; mapData.getLayer("pickup").objects)
      createPickup(em, vec2f(obj.x, obj.y), obj.name);
}

void createPickup(EntityManager em, vec2f pos, string name) {
    import std.conv : to;

    auto ent = em.create();
    ent.register!Transform(pos);

    auto timer = ent.register!Timer(pickupRespawnTime);
    auto sprite = ent.register!Sprite;
    auto pickup = ent.register!Pickup;

    sprite.tint = al_map_rgb(128, 128, 128); // dim the pickup until it spawns

    timer.onTick = (em, self, elapsed) {
        self.component!Pickup.spawned = true;
        self.component!Sprite.tint = al_map_rgb(255, 255, 255);
    };

    final switch (name.to!(Pickup.Type)) with (Pickup.Type) {
        case shield:
            sprite.rect = SpriteRect.shieldPickup;
            pickup.equipment.onToggle = (self, on) {
                self.component!Velocity.speed = speed * ((on) ? 2 : 1);
            };
            break;
        case speed:
            sprite.rect = SpriteRect.speedPickup;
            pickup.equipment.onToggle = (self, on) {
                self.component!Velocity.speed = speed * ((on) ? 2 : 1);
            };
            break;
    }
}
