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

module orb.utils.benchmark;

public import std.datetime;


enum Stat : uint
{
    none      = 0b000,
    minmax    = 0b001,
    average   = 0b010,
    deviation = 0b100,
    all       = 0b111
}

struct Benchmark(Stat stat)
{
public:
    void start() nothrow @nogc @safe
    {
        mTimestamp = MonoTime.currTime;
        mDelay     = seconds(0);
    }

    void stop() nothrow @nogc @safe
    in
    {
        // It must have started
        assert(mTimestamp != MonoTime.zero);
    }
    body
    {
        mDelay += MonoTime.currTime - mTimestamp;
        mTimestamp = MonoTime.zero;
        mCount++;
        static if (stat & Stat.minmax)
        {
            if (mDelay < mMin)
                mMin = mDelay;
            if (mDelay > mMax)
                mMax = mDelay;
        }
        static if (stat & Stat.average || stat & Stat.deviation)
        {
            auto delayUsecs = cast(ulong)mDelay.total!"usecs";
            mSum += delayUsecs;

            static if (stat & Stat.deviation)
            {
                mSum2 += delayUsecs * delayUsecs;
            }
        }
    }

    void opOpAssign(string op)(Benchmark bmRhs)
        if (op == "-" || op == "+")
    {
        static if (op == "-")
            mDelay -= bmRhs.mDelay;
        else // static if (op == "+")
            mDelay += bmRhs.mDelay;
    }

    void reset() nothrow @nogc @safe
    {
        mTimestamp = MonoTime.zero;
        mDelay     = seconds(0);
        mCount     = 0;
        static if (stat & Stat.minmax)
        {
            mMin = Duration.max;
            mMax = Duration.min;
        }
        static if (stat & Stat.average || stat & Stat.deviation)
        {
            mSum = 0;
            static if (stat & Stat.deviation)
            {
                mSum2 = 0;
            }
        }
    }

    // Getters
    MonoTime timestamp() @property const pure nothrow @nogc @safe
    {
        return mTimestamp;
    }

    Duration delay() @property const pure nothrow @nogc @safe
    {
        return mDelay;
    }

    uint count() @property const pure nothrow @nogc @safe
    {
        return mCount;
    }

    static if (stat & Stat.minmax)
    {
        Duration min() @property const pure nothrow @nogc @safe
        {
            return mMin == Duration.max ? seconds(0) : mMin;
        }

        Duration max() @property const pure nothrow @nogc @safe
        {
            return mMax == Duration.min ? seconds(0) : mMax;
        }
    }
    static if (stat & Stat.average)
    {
        Duration average() @property const pure nothrow @nogc @safe
        {
            return mCount == 0 ? seconds(0) : usecs(mSum / mCount);
        }
    }
    static if (stat & Stat.deviation)
    {
        Duration deviation() @property const pure nothrow @nogc @safe
        {
            if (mCount == 0)
                return seconds(0);
            if (mSum >= (1UL << 32))
                return Duration.max;
            ulong avgSq = mSum2 / mCount;
            ulong sqAvg = (mSum * mSum) / (mCount * mCount);
            import std.math : sqrt;
            return usecs(cast(long)sqrt(cast(double)(avgSq - sqAvg)));
        }
    }

private:
    MonoTime mTimestamp;
    Duration mDelay;
    uint     mCount;
    static if (stat & Stat.minmax)
    {
        Duration mMin = Duration.max;
        Duration mMax = Duration.min;
    }
    static if (stat & Stat.average || stat & Stat.deviation)
    {
        ulong mSum;
    }
    static if (stat & Stat.deviation)
    {
        ulong mSum2;
    }
}