module geometry;

import gfm.math;

/**
 * Determine if and where two rays intersect.
 *
 * If the rays are identical, returns the first point they meet.
 *
 * Params:
 * a = first ray
 * b = second ray
 *
 * Returns:
 * The point of intersection,
 */
auto intersect(ray2f a, ray2f b) {

    /*
     * y - ya = ma(x - xa)
     * y - yb = mb(x - xb)
     *--------------------
     * -ya + yb = max - maxa - mbx + mbxb
     * yb - ya = x(ma - mb) + mbxb - maxa
     * yb - ya - mbxb + maxa = x(ma - mb)
     * x = (yb - ya + maxa - mbxb) / (ma - mb)
     *
     * ...
     *
     * y = ma(x - xa) + ya
     */

    immutable xa = a.orig.x, // sample x point on a
              xb = b.orig.x, // sample x point on b
              ya = a.orig.y, // sample y point on a
              yb = b.orig.y, // sample y point on b
              ma = a.dir,    // slope of a
              mb = b.dir;    // slope of b

    if (ma == mb) { // parallel -- check if they are the same ray
        auto disp = b.orig - a.orig;
        auto slope = disp.y / disp.x;
        if (a.orig - b.orig
        return (a.orig == b.orig) ? intersection(a.orig) : noIntersection;
    }


    immutable x = yb - ya + ma*xa + mb*xb / (ma - mb);
    immutable y = ma*(x - xa) + ya;

    // ensure (x,y) lies on both of the rays
    return ((x > xa && ma > 0 || x < xa && ma < 0) &&
            (x > xb && mb > 0 || x < xb && mb < 0)) ?
        intersection(vec2f(x, y)) : noIntersection;
}

unittest {
    bool test(int[2] o1, int[2] m1, int[2] o2, int[2] m2, ) {
    }

    assert((pt = ray2i(
}

bool intersect(ray2f ray, box2f box, out vec2f point) {
}

private:
struct IntersectResult {
    private bool _ok;
    vec2f _point;

    alias _point this; // behave like a vector
    bool opCast(T : bool)() { return _ok; }
}

auto intersection(vec2f point) { return IntersectResult(true, point); }
auto noIntersection() { return IntersectResult(false); }
