/* ORB - 3D/physics/AI engine
   Copyright (C) 2015-2017 Claude

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

module orb.utils.math;

/*
For inverse square-root:
http://en.wikipedia.org/wiki/Fast_inverse_square_root

How to calculate the magic-number CC...
Where rho is a constant within [0, 1[ ; B = 127  and L = 2^23 for single-float
                                        B = 1023 and L = 2^52 for double-float

For square-root:
Iy = 3 / 2 * L * (B - rho) - Ix / 2
So the constant is:
CC = 3 / 2 * L * (B - rho)

For cube-root:
Iy = 4 / 3 * L * (B - rho) - Ix / 3
So the constant is:
CC = 4 / 3 * L * (B - rho)

Using brute-force other a certain target range and accuracy to determine the
best CC for different "Precision" (Newton-Raphson passes), and therefore rho.
//int CC;
//ulong CC;
*/


// Fast square-root implementation
pure nothrow @safe @nogc
T sqrt(T = float, uint Precision = 3)(T v)
{
    return v * invsqrt!(T, Precision)(v);
}


/*
Inverse square-root

Newton-Raphson:
  x(n+1) = x(n) * (3/2 - a/2 * x(n)²)
*/
pure nothrow @safe @nogc
T invsqrt(T = float, uint Precision = 3)(T v)
    if (is(T == float) || is(T == double))
{
    T vHalf;
    union U
    {
        T f;
        static if (is(T == float))
            int  i;
        else
            long i;
    }
    U u;

    vHalf = v * 0.5F;
    u.f = v;
    static if (is(T == float))
        u.i = 0x5f32c7b5 - (u.i >> 1);
    else
        u.i = 0x5fe6eb50c7b537a9 - (u.i >> 1);

    foreach (i; 0 .. Precision)
        u.f = u.f * (1.5f - (vHalf * u.f * u.f));

    return u.f;
}


// Fast cube-root implementation
pure nothrow @safe @nogc
T cbrt(T = float, uint Precision = 3)(T v)
    if (is(T == float) || is(T == double))
{
    T invcbrtV = invcbrt!(T, Precision)(v);
    return v * invcbrtV * invcbrtV;
}


/*
Inverse cube-root

Newton-Raphson:
  x(n+1) = x(n) * (4/3 - a/3 * x(n)³)
*/
pure nothrow @safe @nogc
T invcbrt(T = float, uint Precision = 3)(T v)
    if (is(T == float) || is(T == double))
{
    T vThird;
    union U
    {
        T f;
        static if (is(T == float))
            int  i;
        else
            long i;
    }
    U u;

    vThird = v * (1.0 / 3.0);   // less accurate than a division, but faster
    u.f = v;
    //todo replace the "/ 3" by a fixed-point mul
    //     64-bit mul for float (easy), a bit trickier for double
    static if (is(T == float))
        u.i = 0x54a33f3f - (u.i / 3);
    else
        u.i = 0x553ef33421e00240 - (u.i / 3);

    foreach (i; 0 .. Precision)
        u.f = u.f * ((4.0 / 3.0) - (vThird * u.f * u.f * u.f));

    return u.f;
}


unittest
{
    version (math_cbrt_const)
    {
        import std.math;
        import std.stdio;

        enum uint PRECISION = 5;
        /*enum uint ITER = 100000000;
        enum float DIV = 100000;*/
        enum uint ITER = 10000000;
        enum float DIV = 10000;

        double sumDiff(uint n, double divisor)
        {
            double sum = 0;
            double d;
            for (int i = 0 ; i < n; i++)
            {
                double f = i/divisor;
                //d = std.math.sqrt(f) - orb.math.sqrt!(float, PRECISION)(f);
                d = std.math.cbrt(f) - orb.math.cbrt!(double, PRECISION)(f);
                sum += abs(d);
            }
            return sum;
        }

        //ulong CC = 0x54000000;
        //ulong CC = 0x5f000000;
        ulong CC = 0x5540000000000000;
        ulong bestCC;
        //uint s = 23;
        uint s = 52;
        double bestSum = double.max, sum;

        bestSum = sumDiff(ITER, DIV);
        bestCC = CC;

        while (true)
        {
            CC = bestCC;
            CC += 0x1UL << s;
            sum = sumDiff(ITER, DIV);
            writef("CC=0x%08x sum=%f + ", CC, sum);
            if (sum < bestSum)
            {
                bestCC = CC;
                bestSum = sum;
                writefln("Match");
            }
            else
                writefln("");

            CC -= 0x2UL << s;
            sum = sumDiff(ITER, DIV);
            writef("CC=0x%08x sum=%f - ", CC, sum);
            if (sum < bestSum)
            {
                bestCC = CC;
                bestSum = sum;
                writefln("Match");
            }
            else
                writefln("");
            if (s == 0)
                break;
            s--;
        }
        writefln("Best(precision=%d) CC=0x%016x sum=%f", PRECISION, bestCC, bestSum);
    }
}

/*
enum uint ITER = 100000000;
enum float DIV = 100000;

sqrt!(float)

Best(precision=0) CC=0x5f33cd20 sum=36875323.250499
Best(precision=1) CC=0x5f3529fe sum=1530632.749620
Best(precision=2) CC=0x5f363c22 sum=3184.116633
Best(precision=3) CC=0x5f32c7b5 sum=74.548130


enum uint ITER = 10000000;
enum float DIV = 10000;

cbrt!(float)

Best(precision=0) CC=0x54a06140 sum=1847829.867111
Best(precision=1) CC=0x54a169fc sum=82947.527493
Best(precision=2) CC=0x54a234c4 sum=237.592472
Best(precision=3) CC=0x54a33f3f sum=4.177020

cbrt!(double)

enum uint PRECISION = 0;
enum uint ITER = 10000000;
enum float DIV = 10000;

Best(precision=0) CC=0x553eb6d21580226f sum=1847829.866842
Best(precision=1) CC=0x553ed7e988086718 sum=82947.519585
Best(precision=2) CC=0x553ef12cbf17dff8 sum=236.906886
Best(precision=3) CC=0x553ef33421e00240 sum=0.003498
Best(precision=4) CC=0x553f126f7c000600 sum=0.000000
Best(precision=5) CC=0x5540066000f80008 sum=0.000000

*/