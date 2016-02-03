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
    float u, v;
    rayIntersectProgress(a, b, u, v);
    return (u > 0 && v > 0) ? intersection(a.progress(u)) : noIntersection;
}

unittest {
    // Validate that the ray (as, ad) intersects the ray (bs, bd) at p
    bool yes(float[2] as, float[2] ad, float[2] bs, float[2] bd, float[2] p) {
        import std.math : approxEqual;

        auto a = ray2f(vec2f(as), vec2f(ad));
        auto b = ray2f(vec2f(bs), vec2f(bd));
        auto res = intersect(a, b);

        return res && res.x.approxEqual(p[0]) && res.y.approxEqual(p[1]);
    }

    // Validate that the ray (as, ad) doesn't intersect the ray (bs, bd)
    bool no(float[2] as, float[2] ad, float[2] bs, float[2] bd) {
        auto r1 = ray2f(vec2f(as), vec2f(ad));
        auto r2 = ray2f(vec2f(bs), vec2f(bd));
        return !intersect(r1, r2);
    }

    //            as        ad        bs        bd        p
    assert(yes([ 0, 0 ], [ 1, 1 ], [ 0, 2 ], [ 1,-1 ], [ 1, 1 ]));
    assert(yes([ 0, 0 ], [ 4, 4 ], [ 0, 2 ], [ 8,-8 ], [ 1, 1 ]));
    assert(yes([ 0, 0 ], [ 2, 1 ], [ 4, 0 ], [ 0, 1 ], [ 4, 2 ]));
    assert(yes([ 0, 0 ], [ 2, 1 ], [ 3, 1 ], [ 1, 1 ], [ 4, 2 ]));
    assert(yes([ 0, 0 ], [ 2, 1 ], [ 5, 1 ], [-1, 1 ], [ 4, 2 ]));
    assert(yes([ 0, 0 ], [ 2, 1 ], [ 4, 5 ], [ 0,-1 ], [ 4, 2 ]));

    //            as        ad        bs        bd
    assert(no([ 0, 0 ], [ 2, 1 ], [-1,-1 ], [ 0, 1 ]));
    assert(no([ 0, 0 ], [-1,-1 ], [ 1, 1 ], [ 1, 1 ]));
    assert(no([ 0, 0 ], [-1,-1 ], [ 1, 1 ], [ 1, 0 ]));
    assert(no([ 0, 0 ], [-1,-1 ], [ 1, 1 ], [ 0, 1 ]));
    assert(no([ 0, 0 ], [ 1, 0 ], [ 1, 0 ], [ 1, 0 ])); // parallel
}

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
auto intersect(ray2f a, seg2f b) {
    float u, v;
    auto rb = ray2f(b.a, b.b - b.a);
    rayIntersectProgress(a, rb, u, v);
    return (u > 0 && v > 0 && v < 1) ? intersection(a.progress(u)) : noIntersection;
}

unittest {
    // Validate that the ray (as, ad) intersects the segment (ba, bb) at p
    bool yes(float[2] as, float[2] ad, float[2] ba, float[2] bb, float[2] p) {
        import std.math : approxEqual;

        auto a = ray2f(vec2f(as), vec2f(ad));
        auto b = seg2f(vec2f(ba), vec2f(bb));
        auto res = intersect(a, b);

        return res && res.x.approxEqual(p[0]) && res.y.approxEqual(p[1]);
    }

    // Validate that the ray (as, ad) doesn't intersect the segment (ba, bb)
    bool no(float[2] as, float[2] ad, float[2] ba, float[2] bb) {
        auto a = ray2f(vec2f(as), vec2f(ad));
        auto b = seg2f(vec2f(ba), vec2f(bb));
        return !intersect(a, b);
    }

    //            as        ad        ba        bb        p
    assert(yes([ 0, 0 ], [ 1, 1 ], [ 4, 0 ], [ 0, 4 ], [ 2, 2 ]));
    assert(yes([ 0, 0 ], [-4, 4 ], [-2, 0 ], [ 0, 2 ], [-1, 1 ]));

    //            as        ad        ba        bb
    assert(no([ 0, 0 ], [ 1, 1 ], [ 2, 1 ], [ 4, 1 ]));
    assert(no([ 0, 0 ], [-1,-1 ], [ 1, 1 ], [ 2, 2 ]));
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

/*
 * Helper reused for ray/segment intersection functions.
 * u,v are the progress along a,b at which the intersection occurs
 */
void rayIntersectProgress(ray2f a, ray2f b, out float u, out float v) {
    // algorithm from stack overflow answer:
    // http://stackoverflow.com/a/2932601/1435461
    immutable as = a.orig,
              bs = b.orig,
              ad = a.dir,
              bd = b.dir,
              dx = bs.x - as.x,
              dy = bs.y - as.y,
              det = bd.x * ad.y - bd.y * ad.x;

    u = (dy * bd.x - dx * bd.y) / det;
    v = (dy * ad.x - dx * ad.y) / det;
}
