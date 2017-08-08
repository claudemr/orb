module orb.terrain.generator;

public import gfm.math.vector;

alias GenFunction = float delegate(int x, int y, int z);

/* XXX this is very unoptimized, generator function result should be cached,
as it is called several for the same point before doing the density calculation.
*/
class Generator
{
public:
    void register(GenFunction genFnc)
    {
        mGenFunctions ~= genFnc;
    }

    bool /*float*/ opIndex(int x, int y, int z)
    {
        bool isEmpty;
        bool isFull;
        uint density;

        float p = 0.0;
        foreach (genFnc; mGenFunctions)
            p += genFnc(x, y, z);

        p += 0.5;

        if (p <= 0)
        {
            isEmpty = true;
            density = 0;
        }
        else if (p >= 1)
        {
            isFull = true;
            density = 256;
        }
        else
        {
            density = cast(uint)(p * 256);
        }

        return !isEmpty;
    }

private:
    GenFunction[] mGenFunctions;
}