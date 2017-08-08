/* ORB - 3D/physics/IA engine
   Copyright (C) 2015 ClaudeMr

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>. */

module orb.utils.geometry;

public import gfm.math.vector;
import std.range;


enum Axis
{
    x = 0,
    y,
    z
}

enum Side
{
    back = 0,
    front
}


bool isAlmostZero(T, int N, float EPS = 1e-3)(Vector!(T, N) v)
    pure nothrow @safe @nogc
{
    foreach (i; 0 .. N)
    {
        if (v.v[i] < -EPS || v.v[i] > EPS)
            return false;
    }
    return true;
}


vec3i getNeighbor(in vec3i p, Axis axis, Side side)
{
    vec3i n = p;
    n[axis] += side * 2 - 1;
    return n;
}

private string neighborDg(int axis, int side)
    pure @safe nothrow
{
    import std.conv;
    return   "result = dg(cast(Axis)" ~ axis.to!string
           ~ ", cast(Side)" ~ side.to!string ~ "); if (result) return result;";
}

private string neighborSortDg(int axis, string side, bool isNearest3)
    pure @safe nothrow
{
    import std.conv;
    return   "result = dg(cast(Axis)" ~ axis.to!string
           ~ ", cast(Side)(" ~ side ~ "), " ~ isNearest3.to!string
           ~ "); if (result) return result;";
}


/**
 * Return neighbors of point P.
 */
auto neighbors(vec3i p) @property
{
    struct Apply
    {
        int opApply(int delegate(Axis, Side) dg)
        {
            int result;

            mixin(neighborDg(0, 0)); mixin(neighborDg(0, 1));
            mixin(neighborDg(1, 0)); mixin(neighborDg(1, 1));
            mixin(neighborDg(2, 0)); mixin(neighborDg(2, 1));

            return result;
        }
    }

    return Apply();
}


/**
 * Return neighbors of point P, sorted in order from nearest of O to furthest.
 *
 * It returns the relative position of the neighbor via axis and side.
 *
 * The third boolean parameter tells whether the neighbor is amongst the 3
 * nearest neighbors to O.
 */
auto neighbors(vec3i p, vec3i o) @property
{
    vec3i delta = p - o;

    struct Apply
    {
        int opApply(int delegate(Axis, Side, bool) dg)
        {
            int result;

            int neighborSortPole(int a, int b, int c)()
            {
                mixin(neighborSortDg(a, "delta[a] < 0 ? 1 : 0", 1));
                mixin(neighborSortDg(b, "0", 0));
                mixin(neighborSortDg(b, "1", 0));
                mixin(neighborSortDg(c, "0", 0));
                mixin(neighborSortDg(c, "1", 0));
                mixin(neighborSortDg(a, "delta[a] < 0 ? 0 : 1", 0));
                return result;
            }

            int neighborSortMeridian(int a, int b, int c)()
            {
                import std.math : abs;
                if (abs(delta[a]) < abs(delta[b]))
                {
                    mixin(neighborSortDg(b, "delta[b] < 0 ? 1 : 0", 1));
                    mixin(neighborSortDg(a, "delta[a] < 0 ? 1 : 0", 1));
                }
                else
                {
                    mixin(neighborSortDg(a, "delta[a] < 0 ? 1 : 0", 1));
                    mixin(neighborSortDg(b, "delta[b] < 0 ? 1 : 0", 1));
                }
                mixin(neighborSortDg(c, "0", 0));
                mixin(neighborSortDg(c, "1", 0));
                if (abs(delta[a]) < abs(delta[b]))
                {
                    mixin(neighborSortDg(a, "delta[a] < 0 ? 0 : 1", 0));
                    mixin(neighborSortDg(b, "delta[b] < 0 ? 0 : 1", 0));
                }
                else
                {
                    mixin(neighborSortDg(b, "delta[b] < 0 ? 0 : 1", 0));
                    mixin(neighborSortDg(a, "delta[a] < 0 ? 0 : 1", 0));
                }
                return result;
            }

            int neighborSortTriangle()
            {
                import std.math : abs;

                int mixinNeighbor(int r, int s, int t)()
                {
                    mixin(neighborSortDg(t, "delta[t] < 0 ? 1 : 0", 1));
                    mixin(neighborSortDg(s, "delta[s] < 0 ? 1 : 0", 1));
                    mixin(neighborSortDg(r, "delta[r] < 0 ? 1 : 0", 1));
                    mixin(neighborSortDg(r, "delta[r] < 0 ? 0 : 1", 0));
                    mixin(neighborSortDg(s, "delta[s] < 0 ? 0 : 1", 0));
                    mixin(neighborSortDg(t, "delta[t] < 0 ? 0 : 1", 0));
                    return result;
                }

                if (abs(delta[1]) < abs(delta[2]))
                {
                    if (abs(delta[0]) < abs(delta[1]))
                        return mixinNeighbor!(0, 1, 2)();
                    else if (abs(delta[0]) < abs(delta[2]))
                        return mixinNeighbor!(1, 0, 2)();
                    else
                        return mixinNeighbor!(1, 2, 0)();
                }
                else
                {
                    if (abs(delta[0]) < abs(delta[2]))
                        return mixinNeighbor!(0, 2, 1)();
                    else if (abs(delta[0]) < abs(delta[1]))
                        return mixinNeighbor!(2, 0, 1)();
                    else
                        return mixinNeighbor!(2, 1, 0)();
                }
            }

            // Is it a pole
            if (delta.x == 0 && delta.y == 0)
                result = neighborSortPole!(2, 0, 1)();
            else if (delta.y == 0 && delta.z == 0)
                result = neighborSortPole!(0, 1, 2)();
            else if (delta.x == 0 && delta.z == 0)
                result = neighborSortPole!(1, 2, 0)();
            // Is it a meridian
            else if (delta.x == 0)
                result = neighborSortMeridian!(1, 2, 0)();
            else if (delta.y == 0)
                result = neighborSortMeridian!(2, 0, 1)();
            else if (delta.z == 0)
                result = neighborSortMeridian!(0, 1, 2)();
            // Or on a triangle
            else
                result = neighborSortTriangle();

            return result;
        }
    }

    return Apply();
}

/*int GetMortonNumber(vec3i v)
{
    return spreadBits(v.x, 0) | spreadBits(v.y, 1) | spreadBits(v.z, 2);
}

int spreadBits(int x, int offset)
{
    assert(x >= 0 && x < 1024);
    assert(offset >= 0 && offset <= 2);

    x = (x | (x << 10)) & 0x000F801F;
    x = (x | (x <<  4)) & 0x00E181C3;
    x = (x | (x <<  2)) & 0x03248649;
    x = (x | (x <<  2)) & 0x09249249;

    return x << offset;
}

uint64_t zorder3d(uint64_t x, uint64_t y, uint64_t z){
     static const uint64_t B[] = {0x00000000FF0000FF, 0x000000F00F00F00F,
                                    0x00000C30C30C30C3, 0X0000249249249249};
     static const int S[] =  {16, 8, 4, 2};
     static const uint64_t MAXINPUT = 65536;

     assert( ( (x < MAXINPUT) ) &&
      ( (y < MAXINPUT) ) &&
      ( (z < MAXINPUT) )
     );

     x = (x | (x << S[0])) & B[0];
     x = (x | (x << S[1])) & B[1];
     x = (x | (x << S[2])) & B[2];
     x = (x | (x << S[3])) & B[3];

     y = (y | (y << S[0])) & B[0];
     y = (y | (y << S[1])) & B[1];
     y = (y | (y << S[2])) & B[2];
     y = (y | (y << S[3])) & B[3];

     z = (z | (z <<  S[0])) & B[0];
     z = (z | (z <<  S[1])) & B[1];
     z = (z | (z <<  S[2])) & B[2];
     z = (z | (z <<  S[3])) & B[3];

     return ( x | (y << 1) | (z << 2) );
    }*/

unittest
{
    //import std.stdio;
    import std.random;

    vec3i o, p;

    foreach (i; 0..100)
    {
        int max;

        o.x = uniform(-10, 10);
        o.y = uniform(-10, 10);
        o.z = uniform(-10, 10);

        p.x = uniform(-10, 10);
        p.y = uniform(-10, 10);
        p.z = uniform(-10, 10);

        if (o == p)
            continue;

        foreach (axis, side, isNearer; p.neighbors(o))
        {
            auto r = p.getNeighbor(axis, side) - o;
            auto d2 = r.lengthsqr;
            assert(d2 >= max);
            max = d2;
        }
    }
}


ulong morton(vec3i p) pure /*nothrow*/ @safe /*@nogc*/ //toString...
{
    static immutable ulong[4] mask = [0x00000000FF0000FF, 0x000000F00F00F00F,
                                      0x00000C30C30C30C3, 0x0000249249249249];
    static immutable int[4] shift =  [16, 8, 4, 2];
    static immutable uint max = 65536;

    assert(cast(uint)p.x < max && cast(uint)p.y < max && cast(uint)p.z < max,
           p.toString);

    ulong x = p.x;
    ulong y = p.y;
    ulong z = p.z;

    x = (x | (x << shift[0])) & mask[0];
    x = (x | (x << shift[1])) & mask[1];
    x = (x | (x << shift[2])) & mask[2];
    x = (x | (x << shift[3])) & mask[3];

    y = (y | (y << shift[0])) & mask[0];
    y = (y | (y << shift[1])) & mask[1];
    y = (y | (y << shift[2])) & mask[2];
    y = (y | (y << shift[3])) & mask[3];

    z = (z | (z <<  shift[0])) & mask[0];
    z = (z | (z <<  shift[1])) & mask[1];
    z = (z | (z <<  shift[2])) & mask[2];
    z = (z | (z <<  shift[3])) & mask[3];

    return x | (y << 1) | (z << 2);
}

/**
 * Aera calculation squared.
 */
float area2()(auto ref const(vec3f) p0,
              auto ref const(vec3f) p1,
              auto ref const(vec3f) p2)
    pure nothrow @safe @nogc
{
        float a = (p0 - p1).length;
        float b = (p1 - p2).length;
        float c = (p2 - p0).length;
        float s = (a + b + c) / 2.0f;
        return s * (s - a) * (s - b) * (s - c);
}
