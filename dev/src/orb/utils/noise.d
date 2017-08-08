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

module orb.utils.noise;

import std.math;

/*
 * Derived from SimplexNoise1234 by Stefan Gustavson stegu@itn.liu.se
 * That was licenced in the public domain.
 *
 * Quote:
 * "This implementation is "Simplex Noise" as presented by
 * Ken Perlin at a relatively obscure and not often cited course
 * session "Real-Time Shading" at Siggraph 2001 (before real
 * time shading actually took on), under the title "hardware noise".
 * The 3D function is numerically equivalent to his Java reference
 * code available in the PDF course notes, although I re-implemented
 * it from scratch to get more readable code. The 1D, 2D and 4D cases
 * were implemented from scratch by me from Ken Perlin's text."
 */

// Simple skewing factors for the 2D/3D/4D case
enum F2 = 0.5f * (sqrt(3.0f) - 1.0f);
enum G2 = (3.0f - sqrt(3.0f)) / 6.0f;
enum F3 = 1.0f / 3.0f;
enum G3 = 1.0f / 6.0f;
enum F4 = (sqrt(5.0f) - 1.0f) / 4.0f;
enum G4 = (5.0f - sqrt(5.0f)) / 20.0f;

private int fastFloor(T)(T v)
{
    return v > 0 ? cast(int)v : cast(int)v - 1;
}

/*
 * Permutation table. This is just a random jumble of all numbers 0-255,
 * repeated twice to avoid wrapping the index at 255 for each lookup.
 * This needs to be exactly the same for all instances on all platforms,
 * so it's easiest to just keep it as static explicit data.
 * This also removes the need for any initialisation of this class.
 */
private immutable(ubyte)[512] perm = [151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
  151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180];

/*
 * Gradient tables. These could be programmed the Ken Perlin way with
 * some clever bit-twiddling, but this is more clear, and not really slower.
 */
private immutable(float)[2][8] grad2lut = [
  [ -1.0f, -1.0f ], [ 1.0f, 0.0f ] , [ -1.0f, 0.0f ] , [ 1.0f, 1.0f ] ,
  [ -1.0f, 1.0f ] , [ 0.0f, -1.0f ] , [ 0.0f, 1.0f ] , [ 1.0f, -1.0f ]
];

/*
 * Gradient directions for 3D.
 * These vectors are based on the midpoints of the 12 edges of a cube.
 * A larger array of random unit length vectors would also do the job,
 * but these 12 (including 4 repeats to make the array length a power
 * of two) work better. They are not random, they are carefully chosen
 * to represent a small, isotropic set of directions.
 */

private immutable(float)[3][16] grad3lut = [
  [ 1.0f, 0.0f, 1.0f ], [ 0.0f, 1.0f, 1.0f ], // 12 cube edges
  [ -1.0f, 0.0f, 1.0f ], [ 0.0f, -1.0f, 1.0f ],
  [ 1.0f, 0.0f, -1.0f ], [ 0.0f, 1.0f, -1.0f ],
  [ -1.0f, 0.0f, -1.0f ], [ 0.0f, -1.0f, -1.0f ],
  [ 1.0f, -1.0f, 0.0f ], [ 1.0f, 1.0f, 0.0f ],
  [ -1.0f, 1.0f, 0.0f ], [ -1.0f, -1.0f, 0.0f ],
  [ 1.0f, 0.0f, 1.0f ], [ -1.0f, 0.0f, 1.0f ], // 4 repeats to make 16
  [ 0.0f, 1.0f, -1.0f ], [ 0.0f, -1.0f, -1.0f ]
];

private immutable(float)[4][32] grad4lut = [
  [ 0.0f, 1.0f, 1.0f, 1.0f ], [ 0.0f, 1.0f, 1.0f, -1.0f ], [ 0.0f, 1.0f, -1.0f, 1.0f ], [ 0.0f, 1.0f, -1.0f, -1.0f ], // 32 tesseract edges
  [ 0.0f, -1.0f, 1.0f, 1.0f ], [ 0.0f, -1.0f, 1.0f, -1.0f ], [ 0.0f, -1.0f, -1.0f, 1.0f ], [ 0.0f, -1.0f, -1.0f, -1.0f ],
  [ 1.0f, 0.0f, 1.0f, 1.0f ], [ 1.0f, 0.0f, 1.0f, -1.0f ], [ 1.0f, 0.0f, -1.0f, 1.0f ], [ 1.0f, 0.0f, -1.0f, -1.0f ],
  [ -1.0f, 0.0f, 1.0f, 1.0f ], [ -1.0f, 0.0f, 1.0f, -1.0f ], [ -1.0f, 0.0f, -1.0f, 1.0f ], [ -1.0f, 0.0f, -1.0f, -1.0f ],
  [ 1.0f, 1.0f, 0.0f, 1.0f ], [ 1.0f, 1.0f, 0.0f, -1.0f ], [ 1.0f, -1.0f, 0.0f, 1.0f ], [ 1.0f, -1.0f, 0.0f, -1.0f ],
  [ -1.0f, 1.0f, 0.0f, 1.0f ], [ -1.0f, 1.0f, 0.0f, -1.0f ], [ -1.0f, -1.0f, 0.0f, 1.0f ], [ -1.0f, -1.0f, 0.0f, -1.0f ],
  [ 1.0f, 1.0f, 1.0f, 0.0f ], [ 1.0f, 1.0f, -1.0f, 0.0f ], [ 1.0f, -1.0f, 1.0f, 0.0f ], [ 1.0f, -1.0f, -1.0f, 0.0f ],
  [ -1.0f, 1.0f, 1.0f, 0.0f ], [ -1.0f, 1.0f, -1.0f, 0.0f ], [ -1.0f, -1.0f, 1.0f, 0.0f ], [ -1.0f, -1.0f, -1.0f, 0.0f ]
];

// A lookup table to traverse the simplex around a given point in 4D.
// Details can be found where this table is used, in the 4D noise method.
private immutable(ubyte)[4][64] simplex =
    [[0,1,2,3],[0,1,3,2],[0,0,0,0],[0,2,3,1],[0,0,0,0],[0,0,0,0],[0,0,0,0],[1,2,3,0],
     [0,2,1,3],[0,0,0,0],[0,3,1,2],[0,3,2,1],[0,0,0,0],[0,0,0,0],[0,0,0,0],[1,3,2,0],
     [0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],
     [1,2,0,3],[0,0,0,0],[1,3,0,2],[0,0,0,0],[0,0,0,0],[0,0,0,0],[2,3,0,1],[2,3,1,0],
     [1,0,2,3],[1,0,3,2],[0,0,0,0],[0,0,0,0],[0,0,0,0],[2,0,3,1],[0,0,0,0],[2,1,3,0],
     [0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],
     [2,0,1,3],[0,0,0,0],[0,0,0,0],[0,0,0,0],[3,0,1,2],[3,0,2,1],[0,0,0,0],[3,1,2,0],
     [2,1,0,3],[0,0,0,0],[0,0,0,0],[0,0,0,0],[3,1,0,2],[0,0,0,0],[3,2,0,1],[3,2,1,0]];

//---------------------------------------------------------------------

/*
 * Helper functions to compute gradients-dot-residualvectors (1D to 4D)
 * Note that these generate gradients of more than unit length. To make
 * a close match with the value range of classic Perlin noise, the final
 * noise values need to be rescaled to fit nicely within [-1,1].
 * (The simplex noise functions as such also have different scaling.)
 * Note also that these noise functions are the most practical and useful
 * signed version of Perlin noise. To return values according to the
 * RenderMan specification from the SL noise() and pnoise() functions,
 * the noise values need to be scaled and offset to [0,1], like this:
 * float SLnoise = (noise(x,y,z) + 1.0) * 0.5;
 */

private float grad(int hash, float x)
{
    int h = hash & 15;
    float grad = 1.0f + (h & 7);    // Gradient value 1.0, 2.0, ..., 8.0
    if (h & 0x8)
        grad = -grad;               // Set a random sign for the gradient
    return grad * x;                // Multiply the gradient with the distance
}

private float grad(int hash, float x, float y)
{
    int h = hash & 7;      // Convert low 3 bits of hash code
    float u = h < 4 ? x : y;  // into 8 simple gradient directions,
    float v = h < 4 ? y : x;  // and compute the dot product with (x,y).
    return ((h & 1) ? -u : u) + ((h & 2) ? -2.0f * v : 2.0f * v);
}

private float grad(int hash, float x, float y , float z)
{
    int h = hash & 15;     // Convert low 4 bits of hash code into 12 simple
    float u = h < 8 ? x : y; // gradient directions, and compute dot product
    float v = h < 4 ? y : h == 12 || h == 14 ? x : z; // Fix repeats at h = 12 to 15
    return ((h & 1)? -u : u) + ((h & 2)? -v : v);
}

private float grad(int hash, float x, float y, float z, float t)
{
    int h = hash & 31;      // Convert low 5 bits of hash code into 32 simple
    float u = h < 24 ? x : y; // gradient directions, and compute dot product.
    float v = h < 16 ? y : z;
    float w = h < 8 ? z : t;
    return ((h & 1)? -u : u) + ((h & 2)? -v : v) + ((h & 4)? -w : w);
}


/* Those grad() functions are used for noise functions
   returning normal vectors */
private void gradN(int hash, out float gx)
{
    int h = hash & 15;
    gx = 1.0f + (h & 0x7);   // Gradient value is one of 1.0, 2.0, ..., 8.0
    if (h & 0x8)
        gx = -gx;   // Make half of the gradients negative
}

private void gradN(int hash, out float gx, out float gy)
{
    int h = hash & 7;
    gx = grad2lut[h][0];
    gy = grad2lut[h][1];
}

private void gradN(int hash, out float gx, out float gy, out float gz)
{
    int h = hash & 15;
    gx = grad3lut[h][0];
    gy = grad3lut[h][1];
    gz = grad3lut[h][2];
}

private void gradN(int hash, out float gx, out float gy,
                             out float gz, out float gw)
{
    int h = hash & 31;
    gx = grad4lut[h][0];
    gy = grad4lut[h][1];
    gz = grad4lut[h][2];
    gw = grad4lut[h][3];
}



// 1D simplex noise
float noise(float x)
{

  int i0 = fastFloor(x);
  int i1 = i0 + 1;
  float x0 = x - i0;
  float x1 = x0 - 1.0f;

  float n0, n1;

  float t0 = 1.0f - x0 * x0;
//  if(t0 < 0.0f) t0 = 0.0f;
  t0 *= t0;
  n0 = t0 * t0 * grad(perm[i0 & 0xff], x0);

  float t1 = 1.0f - x1*x1;
//  if(t1 < 0.0f) t1 = 0.0f;
  t1 *= t1;
  n1 = t1 * t1 * grad(perm[i1 & 0xff], x1);
  // The maximum value of this noise is 8*(3/4)^4 = 2.53125
  // A factor of 0.395 would scale to fit exactly within [-1,1], but
  // we want to match PRMan's 1D noise, so we scale it down some more.
  return 0.25f * (n0 + n1);

}

// 2D simplex noise
float noise(float x, float y)
{
    float n0, n1, n2; // Noise contributions from the three corners

    // Skew the input space to determine which simplex cell we're in
    float s = (x+y)*F2; // Hairy factor for 2D
    float xs = x + s;
    float ys = y + s;
    int i = fastFloor(xs);
    int j = fastFloor(ys);

    float t = cast(float)(i+j)*G2;
    float X0 = i-t; // Unskew the cell origin back to (x,y) space
    float Y0 = j-t;
    float x0 = x-X0; // The x,y distances from the cell origin
    float y0 = y-Y0;

    // For the 2D case, the simplex shape is an equilateral triangle.
    // Determine which simplex we are in.
    int i1, j1; // Offsets for second (middle) corner of simplex in (i,j) coords
    if(x0>y0) {i1=1; j1=0;} // lower triangle, XY order: (0,0)->(1,0)->(1,1)
    else {i1=0; j1=1;}      // upper triangle, YX order: (0,0)->(0,1)->(1,1)

    // A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
    // a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
    // c = (3-sqrt(3))/6

    float x1 = x0 - i1 + G2; // Offsets for middle corner in (x,y) unskewed coords
    float y1 = y0 - j1 + G2;
    float x2 = x0 - 1.0f + 2.0f * G2; // Offsets for last corner in (x,y) unskewed coords
    float y2 = y0 - 1.0f + 2.0f * G2;

    // Wrap the integer indices at 256, to avoid indexing perm[] out of bounds
    int ii = i & 0xff;
    int jj = j & 0xff;

    // Calculate the contribution from the three corners
    float t0 = 0.5f - x0*x0-y0*y0;
    if(t0 < 0.0f) n0 = 0.0f;
    else {
      t0 *= t0;
      n0 = t0 * t0 * grad(perm[ii+perm[jj]], x0, y0);
    }

    float t1 = 0.5f - x1*x1-y1*y1;
    if(t1 < 0.0f) n1 = 0.0f;
    else {
      t1 *= t1;
      n1 = t1 * t1 * grad(perm[ii+i1+perm[jj+j1]], x1, y1);
    }

    float t2 = 0.5f - x2*x2-y2*y2;
    if(t2 < 0.0f) n2 = 0.0f;
    else {
      t2 *= t2;
      n2 = t2 * t2 * grad(perm[ii+1+perm[jj+1]], x2, y2);
    }

    // Add contributions from each corner to get the final noise value.
    // The result is scaled to return values in the interval [-1,1].
    return 40.0f * (n0 + n1 + n2); // TODO: The scale factor is preliminary!
  }

// 3D simplex noise
float noise(float x, float y, float z)
{
    float n0, n1, n2, n3; // Noise contributions from the four corners

    // Skew the input space to determine which simplex cell we're in
    float s = (x + y + z) * F3; // Very nice and simple skew factor for 3D
    float xs = x+s;
    float ys = y+s;
    float zs = z+s;
    int i = fastFloor(xs);
    int j = fastFloor(ys);
    int k = fastFloor(zs);

    float t = cast(float)(i + j + k) * G3;
    float X0 = i-t; // Unskew the cell origin back to (x,y,z) space
    float Y0 = j-t;
    float Z0 = k-t;
    float x0 = x - X0; // The x,y,z distances from the cell origin
    float y0 = y - Y0;
    float z0 = z - Z0;

    // For the 3D case, the simplex shape is a slightly irregular tetrahedron.
    // Determine which simplex we are in.
    int i1, j1, k1; // Offsets for second corner of simplex in (i,j,k) coords
    int i2, j2, k2; // Offsets for third corner of simplex in (i,j,k) coords

    if (x0 >= y0)
    {
        // X Y Z order
        if (y0 >= z0)
        {
            i1=1; j1=0; k1=0;
            i2=1; j2=1; k2=0;
        }
        // X Z Y order
        else if (x0 >= z0)
        {
            i1=1; j1=0; k1=0;
            i2=1; j2=0; k2=1;
        }
        // Z X Y order
        else
        {
            i1=0; j1=0; k1=1;
            i2=1; j2=0; k2=1;
        }
    }
    // x0 < y0
    else
    {
        // Z Y X order
        if (y0<z0)
        {
            i1=0; j1=0; k1=1;
            i2=0; j2=1; k2=1;
        }
        // Y Z X order
        else if(x0<z0)
        {
            i1=0; j1=1; k1=0;
            i2=0; j2=1; k2=1;
        }
        // Y X Z order
        else
        {
            i1=0; j1=1; k1=0;
            i2=1; j2=1; k2=0;
        }
    }

    // A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
    // a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and
    // a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where
    // c = 1/6.
    float x1 = x0 - i1 + G3; // Offsets for second corner in (x,y,z) coords
    float y1 = y0 - j1 + G3;
    float z1 = z0 - k1 + G3;
    float x2 = x0 - i2 + 2.0f * G3; // Offsets for third corner in (x,y,z) coords
    float y2 = y0 - j2 + 2.0f * G3;
    float z2 = z0 - k2 + 2.0f * G3;
    float x3 = x0 - 1.0f + 3.0f * G3; // Offsets for last corner in (x,y,z) coords
    float y3 = y0 - 1.0f + 3.0f * G3;
    float z3 = z0 - 1.0f + 3.0f * G3;

    // Wrap the integer indices at 256, to avoid indexing perm[] out of bounds
    int ii = i & 0xff;
    int jj = j & 0xff;
    int kk = k & 0xff;

    // Calculate the contribution from the four corners
    float t0 = 0.6f - x0*x0 - y0*y0 - z0*z0;
    if (t0 < 0.0f)
    {
        n0 = 0.0f;
    }
    else
    {
        t0 *= t0;
        n0 = t0 * t0 * grad(perm[ii+perm[jj+perm[kk]]], x0, y0, z0);
    }

    float t1 = 0.6f - x1*x1 - y1*y1 - z1*z1;
    if (t1 < 0.0f)
    {
        n1 = 0.0f;
    }
    else
    {
        t1 *= t1;
        n1 = t1 * t1 * grad(perm[ii+i1+perm[jj+j1+perm[kk+k1]]], x1, y1, z1);
    }

    float t2 = 0.6f - x2*x2 - y2*y2 - z2*z2;
    if (t2 < 0.0f)
    {
        n2 = 0.0f;
    }
    else
    {
        t2 *= t2;
        n2 = t2 * t2 * grad(perm[ii+i2+perm[jj+j2+perm[kk+k2]]], x2, y2, z2);
    }

    float t3 = 0.6f - x3*x3 - y3*y3 - z3*z3;
    if (t3 < 0.0f)
    {
        n3 = 0.0f;
    }
    else
    {
        t3 *= t3;
        n3 = t3 * t3 * grad(perm[ii+1+perm[jj+1+perm[kk+1]]], x3, y3, z3);
    }

    // Add contributions from each corner to get the final noise value.
    // The result is scaled to stay just inside [-1,1]
    return 32.0f * (n0 + n1 + n2 + n3);
  }


// 4D simplex noise
float noise(float x, float y, float z, float w)
{
    float n0, n1, n2, n3, n4; // Noise contributions from the five corners

    // Skew the (x,y,z,w) space to determine which cell of 24 simplices we're in
    float s = (x + y + z + w) * F4; // Factor for 4D skewing
    float xs = x + s;
    float ys = y + s;
    float zs = z + s;
    float ws = w + s;
    int i = fastFloor(xs);
    int j = fastFloor(ys);
    int k = fastFloor(zs);
    int l = fastFloor(ws);

    float t = (i + j + k + l) * G4; // Factor for 4D unskewing
    float X0 = i - t; // Unskew the cell origin back to (x,y,z,w) space
    float Y0 = j - t;
    float Z0 = k - t;
    float W0 = l - t;

    float x0 = x - X0;  // The x,y,z,w distances from the cell origin
    float y0 = y - Y0;
    float z0 = z - Z0;
    float w0 = w - W0;

    // For the 4D case, the simplex is a 4D shape I won't even try to describe.
    // To find out which of the 24 possible simplices we're in, we need to
    // determine the magnitude ordering of x0, y0, z0 and w0.
    // The method below is a good way of finding the ordering of x,y,z,w and
    // then find the correct traversal order for the simplex were in.
    // First, six pair-wise comparisons are performed between each possible pair
    // of the four coordinates, and the results are used to add up binary bits
    // for an integer index.
    int c1 = (x0 > y0) ? 32 : 0;
    int c2 = (x0 > z0) ? 16 : 0;
    int c3 = (y0 > z0) ? 8 : 0;
    int c4 = (x0 > w0) ? 4 : 0;
    int c5 = (y0 > w0) ? 2 : 0;
    int c6 = (z0 > w0) ? 1 : 0;
    int c = c1 + c2 + c3 + c4 + c5 + c6;

    int i1, j1, k1, l1; // The integer offsets for the second simplex corner
    int i2, j2, k2, l2; // The integer offsets for the third simplex corner
    int i3, j3, k3, l3; // The integer offsets for the fourth simplex corner

    // simplex[c] is a 4-vector with the numbers 0, 1, 2 and 3 in some order.
    // Many values of c will never occur, since e.g. x>y>z>w makes x<z, y<w and x<w
    // impossible. Only the 24 indices which have non-zero entries make any sense.
    // We use a thresholding to set the coordinates in turn from the largest magnitude.
    // The number 3 in the "simplex" array is at the position of the largest coordinate.
    i1 = simplex[c][0]>=3 ? 1 : 0;
    j1 = simplex[c][1]>=3 ? 1 : 0;
    k1 = simplex[c][2]>=3 ? 1 : 0;
    l1 = simplex[c][3]>=3 ? 1 : 0;
    // The number 2 in the "simplex" array is at the second largest coordinate.
    i2 = simplex[c][0]>=2 ? 1 : 0;
    j2 = simplex[c][1]>=2 ? 1 : 0;
    k2 = simplex[c][2]>=2 ? 1 : 0;
    l2 = simplex[c][3]>=2 ? 1 : 0;
    // The number 1 in the "simplex" array is at the second smallest coordinate.
    i3 = simplex[c][0]>=1 ? 1 : 0;
    j3 = simplex[c][1]>=1 ? 1 : 0;
    k3 = simplex[c][2]>=1 ? 1 : 0;
    l3 = simplex[c][3]>=1 ? 1 : 0;
    // The fifth corner has all coordinate offsets = 1, so no need to look that up.

    float x1 = x0 - i1 + G4; // Offsets for second corner in (x,y,z,w) coords
    float y1 = y0 - j1 + G4;
    float z1 = z0 - k1 + G4;
    float w1 = w0 - l1 + G4;
    float x2 = x0 - i2 + 2.0f*G4; // Offsets for third corner in (x,y,z,w) coords
    float y2 = y0 - j2 + 2.0f*G4;
    float z2 = z0 - k2 + 2.0f*G4;
    float w2 = w0 - l2 + 2.0f*G4;
    float x3 = x0 - i3 + 3.0f*G4; // Offsets for fourth corner in (x,y,z,w) coords
    float y3 = y0 - j3 + 3.0f*G4;
    float z3 = z0 - k3 + 3.0f*G4;
    float w3 = w0 - l3 + 3.0f*G4;
    float x4 = x0 - 1.0f + 4.0f*G4; // Offsets for last corner in (x,y,z,w) coords
    float y4 = y0 - 1.0f + 4.0f*G4;
    float z4 = z0 - 1.0f + 4.0f*G4;
    float w4 = w0 - 1.0f + 4.0f*G4;

    // Wrap the integer indices at 256, to avoid indexing perm[] out of bounds
    int ii = i & 0xff;
    int jj = j & 0xff;
    int kk = k & 0xff;
    int ll = l & 0xff;

    // Calculate the contribution from the five corners
    float t0 = 0.6f - x0*x0 - y0*y0 - z0*z0 - w0*w0;
    if(t0 < 0.0f) n0 = 0.0f;
    else {
      t0 *= t0;
      n0 = t0 * t0 * grad(perm[ii+perm[jj+perm[kk+perm[ll]]]], x0, y0, z0, w0);
    }

   float t1 = 0.6f - x1*x1 - y1*y1 - z1*z1 - w1*w1;
    if(t1 < 0.0f) n1 = 0.0f;
    else {
      t1 *= t1;
      n1 = t1 * t1 * grad(perm[ii+i1+perm[jj+j1+perm[kk+k1+perm[ll+l1]]]], x1, y1, z1, w1);
    }

   float t2 = 0.6f - x2*x2 - y2*y2 - z2*z2 - w2*w2;
    if(t2 < 0.0f) n2 = 0.0f;
    else {
      t2 *= t2;
      n2 = t2 * t2 * grad(perm[ii+i2+perm[jj+j2+perm[kk+k2+perm[ll+l2]]]], x2, y2, z2, w2);
    }

   float t3 = 0.6f - x3*x3 - y3*y3 - z3*z3 - w3*w3;
    if(t3 < 0.0f) n3 = 0.0f;
    else {
      t3 *= t3;
      n3 = t3 * t3 * grad(perm[ii+i3+perm[jj+j3+perm[kk+k3+perm[ll+l3]]]], x3, y3, z3, w3);
    }

   float t4 = 0.6f - x4*x4 - y4*y4 - z4*z4 - w4*w4;
    if(t4 < 0.0f) n4 = 0.0f;
    else {
      t4 *= t4;
      n4 = t4 * t4 * grad(perm[ii+1+perm[jj+1+perm[kk+1+perm[ll+1]]]], x4, y4, z4, w4);
    }

    // Sum up and scale the result to cover the range [-1,1]
    return 27.0f * (n0 + n1 + n2 + n3 + n4); // TODO: The scale factor is preliminary!
}





/** 1D simplex noise with derivative.
 */
float noise(float x, out float dx)
{
  int i0 = fastFloor(x);
  int i1 = i0 + 1;
  float x0 = x - i0;
  float x1 = x0 - 1.0f;

  float gx0, gx1;
  float n0, n1;
  float t20, t40, t21, t41;

  float x20 = x0*x0;
  float t0 = 1.0f - x20;
//  if(t0 < 0.0f) t0 = 0.0f; // Never happens for 1D: x0<=1 always
  t20 = t0 * t0;
  t40 = t20 * t20;
  gradN(perm[i0 & 0xff], gx0);
  n0 = t40 * gx0 * x0;

  float x21 = x1*x1;
  float t1 = 1.0f - x21;
//  if(t1 < 0.0f) t1 = 0.0f; // Never happens for 1D: |x1|<=1 always
  t21 = t1 * t1;
  t41 = t21 * t21;
  gradN(perm[i1 & 0xff], gx1);
  n1 = t41 * gx1 * x1;

/* Compute derivative according to:
 *  dx = -8.0f * t20 * t0 * x0 * (gx0 * x0) + t40 * gx0;
 *  dx += -8.0f * t21 * t1 * x1 * (gx1 * x1) + t41 * gx1;
 */
  dx = t20 * t0 * gx0 * x20;
  dx += t21 * t1 * gx1 * x21;
  dx *= -8.0f;
  dx += t40 * gx0 + t41 * gx1;
  dx *= 0.25f; /* Scale derivative to match the noise scaling */

  // The maximum value of this noise is 8*(3/4)^4 = 2.53125
  // A factor of 0.395 would scale to fit exactly within [-1,1], but
  // to better match classic Perlin noise, we scale it down some more.
  return 0.25f * (n0 + n1);
}


/** 2D simplex noise with derivatives.
 */
float noise(float x, float y, out float dx, out float dy)
{
    float n0, n1, n2; /* Noise contributions from the three simplex corners */
    float gx0, gy0, gx1, gy1, gx2, gy2; /* Gradients at simplex corners */

    /* Skew the input space to determine which simplex cell we're in */
    float s = ( x + y ) * F2; /* Hairy factor for 2D */
    float xs = x + s;
    float ys = y + s;
    int i = fastFloor( xs );
    int j = fastFloor( ys );

    float t = cast(float) ( i + j ) * G2;
    float X0 = i - t; /* Unskew the cell origin back to (x,y) space */
    float Y0 = j - t;
    float x0 = x - X0; /* The x,y distances from the cell origin */
    float y0 = y - Y0;

    /* For the 2D case, the simplex shape is an equilateral triangle.
     * Determine which simplex we are in. */
    int i1, j1; /* Offsets for second (middle) corner of simplex in (i,j) coords */
    if( x0 > y0 ) { i1 = 1; j1 = 0; } /* lower triangle, XY order: (0,0)->(1,0)->(1,1) */
    else { i1 = 0; j1 = 1; }      /* upper triangle, YX order: (0,0)->(0,1)->(1,1) */

    /* A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
     * a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
     * c = (3-sqrt(3))/6   */
    float x1 = x0 - i1 + G2; /* Offsets for middle corner in (x,y) unskewed coords */
    float y1 = y0 - j1 + G2;
    float x2 = x0 - 1.0f + 2.0f * G2; /* Offsets for last corner in (x,y) unskewed coords */
    float y2 = y0 - 1.0f + 2.0f * G2;

    /* Wrap the integer indices at 256, to avoid indexing perm[] out of bounds */
    int ii = i % 256;
    int jj = j % 256;

    /* Calculate the contribution from the three corners */
    float t0 = 0.5f - x0 * x0 - y0 * y0;
    float t20, t40;
    if( t0 < 0.0f ) t40 = t20 = t0 = n0 = gx0 = gy0 = 0.0f; /* No influence */
    else {
      gradN( perm[ii + perm[jj]], gx0, gy0 );
      t20 = t0 * t0;
      t40 = t20 * t20;
      n0 = t40 * ( gx0 * x0 + gy0 * y0 );
    }

    float t1 = 0.5f - x1 * x1 - y1 * y1;
    float t21, t41;
    if( t1 < 0.0f ) t21 = t41 = t1 = n1 = gx1 = gy1 = 0.0f; /* No influence */
    else {
      gradN( perm[ii + i1 + perm[jj + j1]], gx1, gy1 );
      t21 = t1 * t1;
      t41 = t21 * t21;
      n1 = t41 * ( gx1 * x1 + gy1 * y1 );
    }

    float t2 = 0.5f - x2 * x2 - y2 * y2;
    float t22, t42;
    if( t2 < 0.0f ) t42 = t22 = t2 = n2 = gx2 = gy2 = 0.0f; /* No influence */
    else {
      gradN( perm[ii + 1 + perm[jj + 1]], gx2, gy2 );
      t22 = t2 * t2;
      t42 = t22 * t22;
      n2 = t42 * ( gx2 * x2 + gy2 * y2 );
    }

    /* Add contributions from each corner to get the final noise value.
     * The result is scaled to return values in the interval [-1,1]. */
    float noise = 40.0f * ( n0 + n1 + n2 );

    /*  A straight, unoptimised calculation would be like:
     *    dx = -8.0f * t20 * t0 * x0 * ( gx0 * x0 + gy0 * y0 ) + t40 * gx0;
     *    dy = -8.0f * t20 * t0 * y0 * ( gx0 * x0 + gy0 * y0 ) + t40 * gy0;
     *    dx += -8.0f * t21 * t1 * x1 * ( gx1 * x1 + gy1 * y1 ) + t41 * gx1;
     *    dy += -8.0f * t21 * t1 * y1 * ( gx1 * x1 + gy1 * y1 ) + t41 * gy1;
     *    dx += -8.0f * t22 * t2 * x2 * ( gx2 * x2 + gy2 * y2 ) + t42 * gx2;
     *    dy += -8.0f * t22 * t2 * y2 * ( gx2 * x2 + gy2 * y2 ) + t42 * gy2;
     */
    float temp0 = t20 * t0 * ( gx0* x0 + gy0 * y0 );
    dx = temp0 * x0;
    dy = temp0 * y0;
    float temp1 = t21 * t1 * ( gx1 * x1 + gy1 * y1 );
    dx += temp1 * x1;
    dy += temp1 * y1;
    float temp2 = t22 * t2 * ( gx2* x2 + gy2 * y2 );
    dx += temp2 * x2;
    dy += temp2 * y2;
    dx *= -8.0f;
    dy *= -8.0f;
    dx += t40 * gx0 + t41 * gx1 + t42 * gx2;
    dy += t40 * gy0 + t41 * gy1 + t42 * gy2;
    dx *= 40.0f; /* Scale derivative to match the noise scaling */
    dy *= 40.0f;

    return noise;
}



/** 3D simplex noise with derivatives.
 */
float noise(float x, float y, float z,
            out float dx, out float dy, out float dz)
{
    float n0, n1, n2, n3; /* Noise contributions from the four simplex corners */
    float noise;          /* Return value */
    float gx0, gy0, gz0, gx1, gy1, gz1; /* Gradients at simplex corners */
    float gx2, gy2, gz2, gx3, gy3, gz3;

    /* Skew the input space to determine which simplex cell we're in */
    float s = (x+y+z)*F3; /* Very nice and simple skew factor for 3D */
    float xs = x+s;
    float ys = y+s;
    float zs = z+s;
    int i = fastFloor(xs);
    int j = fastFloor(ys);
    int k = fastFloor(zs);

    float t = cast(float)(i+j+k)*G3;
    float X0 = i-t; /* Unskew the cell origin back to (x,y,z) space */
    float Y0 = j-t;
    float Z0 = k-t;
    float x0 = x-X0; /* The x,y,z distances from the cell origin */
    float y0 = y-Y0;
    float z0 = z-Z0;

    /* For the 3D case, the simplex shape is a slightly irregular tetrahedron.
     * Determine which simplex we are in. */
    int i1, j1, k1; /* Offsets for second corner of simplex in (i,j,k) coords */
    int i2, j2, k2; /* Offsets for third corner of simplex in (i,j,k) coords */

    /* TODO: This code would benefit from a backport from the GLSL version! */
    if(x0>=y0) {
      if(y0>=z0)
        { i1=1; j1=0; k1=0; i2=1; j2=1; k2=0; } /* X Y Z order */
        else if(x0>=z0) { i1=1; j1=0; k1=0; i2=1; j2=0; k2=1; } /* X Z Y order */
        else { i1=0; j1=0; k1=1; i2=1; j2=0; k2=1; } /* Z X Y order */
      }
    else { // x0<y0
      if(y0<z0) { i1=0; j1=0; k1=1; i2=0; j2=1; k2=1; } /* Z Y X order */
      else if(x0<z0) { i1=0; j1=1; k1=0; i2=0; j2=1; k2=1; } /* Y Z X order */
      else { i1=0; j1=1; k1=0; i2=1; j2=1; k2=0; } /* Y X Z order */
    }

    /* A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
     * a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and
     * a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where
     * c = 1/6.   */

    float x1 = x0 - i1 + G3; /* Offsets for second corner in (x,y,z) coords */
    float y1 = y0 - j1 + G3;
    float z1 = z0 - k1 + G3;
    float x2 = x0 - i2 + 2.0f * G3; /* Offsets for third corner in (x,y,z) coords */
    float y2 = y0 - j2 + 2.0f * G3;
    float z2 = z0 - k2 + 2.0f * G3;
    float x3 = x0 - 1.0f + 3.0f * G3; /* Offsets for last corner in (x,y,z) coords */
    float y3 = y0 - 1.0f + 3.0f * G3;
    float z3 = z0 - 1.0f + 3.0f * G3;

    /* Wrap the integer indices at 256, to avoid indexing perm[] out of bounds */
    int ii = i % 256;
    int jj = j % 256;
    int kk = k % 256;

    /* Calculate the contribution from the four corners */
    float t0 = 0.6f - x0*x0 - y0*y0 - z0*z0;
    float t20, t40;
    if(t0 < 0.0f) n0 = t0 = t20 = t40 = gx0 = gy0 = gz0 = 0.0f;
    else {
      gradN( perm[ii + perm[jj + perm[kk]]], gx0, gy0, gz0 );
      t20 = t0 * t0;
      t40 = t20 * t20;
      n0 = t40 * ( gx0 * x0 + gy0 * y0 + gz0 * z0 );
    }

    float t1 = 0.6f - x1*x1 - y1*y1 - z1*z1;
    float t21, t41;
    if(t1 < 0.0f) n1 = t1 = t21 = t41 = gx1 = gy1 = gz1 = 0.0f;
    else {
      gradN( perm[ii + i1 + perm[jj + j1 + perm[kk + k1]]], gx1, gy1, gz1 );
      t21 = t1 * t1;
      t41 = t21 * t21;
      n1 = t41 * ( gx1 * x1 + gy1 * y1 + gz1 * z1 );
    }

    float t2 = 0.6f - x2*x2 - y2*y2 - z2*z2;
    float t22, t42;
    if(t2 < 0.0f) n2 = t2 = t22 = t42 = gx2 = gy2 = gz2 = 0.0f;
    else {
      gradN( perm[ii + i2 + perm[jj + j2 + perm[kk + k2]]], gx2, gy2, gz2 );
      t22 = t2 * t2;
      t42 = t22 * t22;
      n2 = t42 * ( gx2 * x2 + gy2 * y2 + gz2 * z2 );
    }

    float t3 = 0.6f - x3*x3 - y3*y3 - z3*z3;
    float t23, t43;
    if(t3 < 0.0f) n3 = t3 = t23 = t43 = gx3 = gy3 = gz3 = 0.0f;
    else {
      gradN( perm[ii + 1 + perm[jj + 1 + perm[kk + 1]]], gx3, gy3, gz3 );
      t23 = t3 * t3;
      t43 = t23 * t23;
      n3 = t43 * ( gx3 * x3 + gy3 * y3 + gz3 * z3 );
    }

    /*  Add contributions from each corner to get the final noise value.
     * The result is scaled to return values in the range [-1,1] */
    noise = 28.0f * (n0 + n1 + n2 + n3);

    /*  A straight, unoptimised calculation would be like:
     *    dx = -8.0f * t20 * t0 * x0 * dot(gx0, gy0, gz0, x0, y0, z0) + t40 * gx0;
     *    dy = -8.0f * t20 * t0 * y0 * dot(gx0, gy0, gz0, x0, y0, z0) + t40 * gy0;
     *    dz = -8.0f * t20 * t0 * z0 * dot(gx0, gy0, gz0, x0, y0, z0) + t40 * gz0;
     *    dx += -8.0f * t21 * t1 * x1 * dot(gx1, gy1, gz1, x1, y1, z1) + t41 * gx1;
     *    dy += -8.0f * t21 * t1 * y1 * dot(gx1, gy1, gz1, x1, y1, z1) + t41 * gy1;
     *    dz += -8.0f * t21 * t1 * z1 * dot(gx1, gy1, gz1, x1, y1, z1) + t41 * gz1;
     *    dx += -8.0f * t22 * t2 * x2 * dot(gx2, gy2, gz2, x2, y2, z2) + t42 * gx2;
     *    dy += -8.0f * t22 * t2 * y2 * dot(gx2, gy2, gz2, x2, y2, z2) + t42 * gy2;
     *    dz += -8.0f * t22 * t2 * z2 * dot(gx2, gy2, gz2, x2, y2, z2) + t42 * gz2;
     *    dx += -8.0f * t23 * t3 * x3 * dot(gx3, gy3, gz3, x3, y3, z3) + t43 * gx3;
     *    dy += -8.0f * t23 * t3 * y3 * dot(gx3, gy3, gz3, x3, y3, z3) + t43 * gy3;
     *    dz += -8.0f * t23 * t3 * z3 * dot(gx3, gy3, gz3, x3, y3, z3) + t43 * gz3;
     */
    float temp0 = t20 * t0 * ( gx0 * x0 + gy0 * y0 + gz0 * z0 );
    dx = temp0 * x0;
    dy = temp0 * y0;
    dz = temp0 * z0;
    float temp1 = t21 * t1 * ( gx1 * x1 + gy1 * y1 + gz1 * z1 );
    dx += temp1 * x1;
    dy += temp1 * y1;
    dz += temp1 * z1;
    float temp2 = t22 * t2 * ( gx2 * x2 + gy2 * y2 + gz2 * z2 );
    dx += temp2 * x2;
    dy += temp2 * y2;
    dz += temp2 * z2;
    float temp3 = t23 * t3 * ( gx3 * x3 + gy3 * y3 + gz3 * z3 );
    dx += temp3 * x3;
    dy += temp3 * y3;
    dz += temp3 * z3;
    dx *= -8.0f;
    dy *= -8.0f;
    dz *= -8.0f;
    dx += t40 * gx0 + t41 * gx1 + t42 * gx2 + t43 * gx3;
    dy += t40 * gy0 + t41 * gy1 + t42 * gy2 + t43 * gy3;
    dz += t40 * gz0 + t41 * gz1 + t42 * gz2 + t43 * gz3;
    dx *= 28.0f; /* Scale derivative to match the noise scaling */
    dy *= 28.0f;
    dz *= 28.0f;

    return noise;
}


/** 4D simplex noise with derivatives.
 */
float noise(float x, float y, float z, float w,
            out float dx, out float dy, out float dz, out float dw)
{
    float n0, n1, n2, n3, n4; // Noise contributions from the five corners
    float noise; // Return value
    float gx0, gy0, gz0, gw0, gx1, gy1, gz1, gw1; /* Gradients at simplex corners */
    float gx2, gy2, gz2, gw2, gx3, gy3, gz3, gw3, gx4, gy4, gz4, gw4;
    float t20, t21, t22, t23, t24;
    float t40, t41, t42, t43, t44;

    // Skew the (x,y,z,w) space to determine which cell of 24 simplices we're in
    float s = (x + y + z + w) * F4; // Factor for 4D skewing
    float xs = x + s;
    float ys = y + s;
    float zs = z + s;
    float ws = w + s;
    int i = fastFloor(xs);
    int j = fastFloor(ys);
    int k = fastFloor(zs);
    int l = fastFloor(ws);

    float t = (i + j + k + l) * G4; // Factor for 4D unskewing
    float X0 = i - t; // Unskew the cell origin back to (x,y,z,w) space
    float Y0 = j - t;
    float Z0 = k - t;
    float W0 = l - t;

    float x0 = x - X0;  // The x,y,z,w distances from the cell origin
    float y0 = y - Y0;
    float z0 = z - Z0;
    float w0 = w - W0;

    // For the 4D case, the simplex is a 4D shape I won't even try to describe.
    // To find out which of the 24 possible simplices we're in, we need to
    // determine the magnitude ordering of x0, y0, z0 and w0.
    // The method below is a reasonable way of finding the ordering of x,y,z,w
    // and then find the correct traversal order for the simplex were in.
    // First, six pair-wise comparisons are performed between each possible pair
    // of the four coordinates, and then the results are used to add up binary
    // bits for an integer index into a precomputed lookup table, simplex[].
    int c1 = (x0 > y0) ? 32 : 0;
    int c2 = (x0 > z0) ? 16 : 0;
    int c3 = (y0 > z0) ? 8 : 0;
    int c4 = (x0 > w0) ? 4 : 0;
    int c5 = (y0 > w0) ? 2 : 0;
    int c6 = (z0 > w0) ? 1 : 0;
    int c = c1 | c2 | c3 | c4 | c5 | c6; // '|' is mostly faster than '+'

    int i1, j1, k1, l1; // The integer offsets for the second simplex corner
    int i2, j2, k2, l2; // The integer offsets for the third simplex corner
    int i3, j3, k3, l3; // The integer offsets for the fourth simplex corner

    // simplex[c] is a 4-vector with the numbers 0, 1, 2 and 3 in some order.
    // Many values of c will never occur, since e.g. x>y>z>w makes x<z, y<w and x<w
    // impossible. Only the 24 indices which have non-zero entries make any sense.
    // We use a thresholding to set the coordinates in turn from the largest magnitude.
    // The number 3 in the "simplex" array is at the position of the largest coordinate.
    i1 = simplex[c][0]>=3 ? 1 : 0;
    j1 = simplex[c][1]>=3 ? 1 : 0;
    k1 = simplex[c][2]>=3 ? 1 : 0;
    l1 = simplex[c][3]>=3 ? 1 : 0;
    // The number 2 in the "simplex" array is at the second largest coordinate.
    i2 = simplex[c][0]>=2 ? 1 : 0;
    j2 = simplex[c][1]>=2 ? 1 : 0;
    k2 = simplex[c][2]>=2 ? 1 : 0;
    l2 = simplex[c][3]>=2 ? 1 : 0;
    // The number 1 in the "simplex" array is at the second smallest coordinate.
    i3 = simplex[c][0]>=1 ? 1 : 0;
    j3 = simplex[c][1]>=1 ? 1 : 0;
    k3 = simplex[c][2]>=1 ? 1 : 0;
    l3 = simplex[c][3]>=1 ? 1 : 0;
    // The fifth corner has all coordinate offsets = 1, so no need to look that up.

    float x1 = x0 - i1 + G4; // Offsets for second corner in (x,y,z,w) coords
    float y1 = y0 - j1 + G4;
    float z1 = z0 - k1 + G4;
    float w1 = w0 - l1 + G4;
    float x2 = x0 - i2 + 2.0f * G4; // Offsets for third corner in (x,y,z,w) coords
    float y2 = y0 - j2 + 2.0f * G4;
    float z2 = z0 - k2 + 2.0f * G4;
    float w2 = w0 - l2 + 2.0f * G4;
    float x3 = x0 - i3 + 3.0f * G4; // Offsets for fourth corner in (x,y,z,w) coords
    float y3 = y0 - j3 + 3.0f * G4;
    float z3 = z0 - k3 + 3.0f * G4;
    float w3 = w0 - l3 + 3.0f * G4;
    float x4 = x0 - 1.0f + 4.0f * G4; // Offsets for last corner in (x,y,z,w) coords
    float y4 = y0 - 1.0f + 4.0f * G4;
    float z4 = z0 - 1.0f + 4.0f * G4;
    float w4 = w0 - 1.0f + 4.0f * G4;

    // Wrap the integer indices at 256, to avoid indexing perm[] out of bounds
    int ii = i & 0xff;
    int jj = j & 0xff;
    int kk = k & 0xff;
    int ll = l & 0xff;

    // Calculate the contribution from the five corners
    float t0 = 0.6f - x0*x0 - y0*y0 - z0*z0 - w0*w0;
    if(t0 < 0.0f) n0 = t0 = t20 = t40 = gx0 = gy0 = gz0 = gw0 = 0.0f;
    else {
      t20 = t0 * t0;
      t40 = t20 * t20;
      gradN(perm[ii+perm[jj+perm[kk+perm[ll]]]], gx0, gy0, gz0, gw0);
      n0 = t40 * ( gx0 * x0 + gy0 * y0 + gz0 * z0 + gw0 * w0 );
    }

   float t1 = 0.6f - x1*x1 - y1*y1 - z1*z1 - w1*w1;
    if(t1 < 0.0f) n1 = t1 = t21 = t41 = gx1 = gy1 = gz1 = gw1 = 0.0f;
    else {
      t21 = t1 * t1;
      t41 = t21 * t21;
      gradN(perm[ii+i1+perm[jj+j1+perm[kk+k1+perm[ll+l1]]]], gx1, gy1, gz1, gw1);
      n1 = t41 * ( gx1 * x1 + gy1 * y1 + gz1 * z1 + gw1 * w1 );
    }

   float t2 = 0.6f - x2*x2 - y2*y2 - z2*z2 - w2*w2;
    if(t2 < 0.0f) n2 = t2 = t22 = t42 = gx2 = gy2 = gz2 = gw2 = 0.0f;
    else {
      t22 = t2 * t2;
      t42 = t22 * t22;
      gradN(perm[ii+i2+perm[jj+j2+perm[kk+k2+perm[ll+l2]]]], gx2, gy2, gz2, gw2);
      n2 = t42 * ( gx2 * x2 + gy2 * y2 + gz2 * z2 + gw2 * w2 );
   }

   float t3 = 0.6f - x3*x3 - y3*y3 - z3*z3 - w3*w3;
    if(t3 < 0.0f) n3 = t3 = t23 = t43 = gx3 = gy3 = gz3 = gw3 = 0.0f;
    else {
      t23 = t3 * t3;
      t43 = t23 * t23;
      gradN(perm[ii+i3+perm[jj+j3+perm[kk+k3+perm[ll+l3]]]], gx3, gy3, gz3, gw3);
      n3 = t43 * ( gx3 * x3 + gy3 * y3 + gz3 * z3 + gw3 * w3 );
    }

   float t4 = 0.6f - x4*x4 - y4*y4 - z4*z4 - w4*w4;
    if(t4 < 0.0f) n4 = t4 = t24 = t44 = gx4 = gy4 = gz4 = gw4 = 0.0f;
    else {
      t24 = t4 * t4;
      t44 = t24 * t24;
      gradN(perm[ii+1+perm[jj+1+perm[kk+1+perm[ll+1]]]], gx4, gy4, gz4, gw4);
      n4 = t44 * ( gx4 * x4 + gy4 * y4 + gz4 * z4 + gw4 * w4 );
    }

    // Sum up and scale the result to cover the range [-1,1]
    noise = 27.0f * (n0 + n1 + n2 + n3 + n4); // TODO: The scale factor is preliminary!

    /*  A straight, unoptimised calculation would be like:
     *    dx = -8.0f * t20 * t0 * x0 * dot(gx0, gy0, gz0, gw0, x0, y0, z0, w0) + t40 * gx0;
     *    dy = -8.0f * t20 * t0 * y0 * dot(gx0, gy0, gz0, gw0, x0, y0, z0, w0) + t40 * gy0;
     *    dz = -8.0f * t20 * t0 * z0 * dot(gx0, gy0, gz0, gw0, x0, y0, z0, w0) + t40 * gz0;
     *    dw = -8.0f * t20 * t0 * w0 * dot(gx0, gy0, gz0, gw0, x0, y0, z0, w0) + t40 * gw0;
     *    dx += -8.0f * t21 * t1 * x1 * dot(gx1, gy1, gz1, gw1, x1, y1, z1, w1) + t41 * gx1;
     *    dy += -8.0f * t21 * t1 * y1 * dot(gx1, gy1, gz1, gw1, x1, y1, z1, w1) + t41 * gy1;
     *    dz += -8.0f * t21 * t1 * z1 * dot(gx1, gy1, gz1, gw1, x1, y1, z1, w1) + t41 * gz1;
     *    dw = -8.0f * t21 * t1 * w1 * dot(gx1, gy1, gz1, gw1, x1, y1, z1, w1) + t41 * gw1;
     *    dx += -8.0f * t22 * t2 * x2 * dot(gx2, gy2, gz2, gw2, x2, y2, z2, w2) + t42 * gx2;
     *    dy += -8.0f * t22 * t2 * y2 * dot(gx2, gy2, gz2, gw2, x2, y2, z2, w2) + t42 * gy2;
     *    dz += -8.0f * t22 * t2 * z2 * dot(gx2, gy2, gz2, gw2, x2, y2, z2, w2) + t42 * gz2;
     *    dw += -8.0f * t22 * t2 * w2 * dot(gx2, gy2, gz2, gw2, x2, y2, z2, w2) + t42 * gw2;
     *    dx += -8.0f * t23 * t3 * x3 * dot(gx3, gy3, gz3, gw3, x3, y3, z3, w3) + t43 * gx3;
     *    dy += -8.0f * t23 * t3 * y3 * dot(gx3, gy3, gz3, gw3, x3, y3, z3, w3) + t43 * gy3;
     *    dz += -8.0f * t23 * t3 * z3 * dot(gx3, gy3, gz3, gw3, x3, y3, z3, w3) + t43 * gz3;
     *    dw += -8.0f * t23 * t3 * w3 * dot(gx3, gy3, gz3, gw3, x3, y3, z3, w3) + t43 * gw3;
     *    dx += -8.0f * t24 * t4 * x4 * dot(gx4, gy4, gz4, gw4, x4, y4, z4, w4) + t44 * gx4;
     *    dy += -8.0f * t24 * t4 * y4 * dot(gx4, gy4, gz4, gw4, x4, y4, z4, w4) + t44 * gy4;
     *    dz += -8.0f * t24 * t4 * z4 * dot(gx4, gy4, gz4, gw4, x4, y4, z4, w4) + t44 * gz4;
     *    dw += -8.0f * t24 * t4 * w4 * dot(gx4, gy4, gz4, gw4, x4, y4, z4, w4) + t44 * gw4;
     */
    float temp0 = t20 * t0 * ( gx0 * x0 + gy0 * y0 + gz0 * z0 + gw0 * w0 );
    dx = temp0 * x0;
    dy = temp0 * y0;
    dz = temp0 * z0;
    dw = temp0 * w0;
    float temp1 = t21 * t1 * ( gx1 * x1 + gy1 * y1 + gz1 * z1 + gw1 * w1 );
    dx += temp1 * x1;
    dy += temp1 * y1;
    dz += temp1 * z1;
    dw += temp1 * w1;
    float temp2 = t22 * t2 * ( gx2 * x2 + gy2 * y2 + gz2 * z2 + gw2 * w2 );
    dx += temp2 * x2;
    dy += temp2 * y2;
    dz += temp2 * z2;
    dw += temp2 * w2;
    float temp3 = t23 * t3 * ( gx3 * x3 + gy3 * y3 + gz3 * z3 + gw3 * w3 );
    dx += temp3 * x3;
    dy += temp3 * y3;
    dz += temp3 * z3;
    dw += temp3 * w3;
    float temp4 = t24 * t4 * ( gx4 * x4 + gy4 * y4 + gz4 * z4 + gw4 * w4 );
    dx += temp4 * x4;
    dy += temp4 * y4;
    dz += temp4 * z4;
    dw += temp4 * w4;
    dx *= -8.0f;
    dy *= -8.0f;
    dz *= -8.0f;
    dw *= -8.0f;
    dx += t40 * gx0 + t41 * gx1 + t42 * gx2 + t43 * gx3 + t44 * gx4;
    dy += t40 * gy0 + t41 * gy1 + t42 * gy2 + t43 * gy3 + t44 * gy4;
    dz += t40 * gz0 + t41 * gz1 + t42 * gz2 + t43 * gz3 + t44 * gz4;
    dw += t40 * gw0 + t41 * gw1 + t42 * gw2 + t43 * gw3 + t44 * gw4;

    dx *= 28.0f; /* Scale derivative to match the noise scaling */
    dy *= 28.0f;
    dz *= 28.0f;
    dw *= 28.0f;

    return noise;
}
