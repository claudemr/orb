module orb.terrain.populator;

public import gfm.math.vector;

/* XXX this is very unoptimized, generator function result should be cached,
as it is called several for the same point before doing the density calculation.
*/
class Populator
{
public:
    this(vec3f o, float radius)
    {
        mCenter = o;
        mRadius = radius;
    }

    float opIndex(int x, int y, int z)
    {
        import orb.utils.math : sqrt;
        import orb.utils.noise : noise;
        auto p = vec3f(x, y, z) - mCenter;
        return sqrt(p.squaredLength) - mRadius +
               noise(x/40.0f, y/40.0f, z/40.0f) * 5;
    }

private:
    vec3f mCenter;
    float mRadius;
}