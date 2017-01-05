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

module orb.terrain;

import dlib.math.vector;

import std.string;
import std.typecons;

/* Terrain is divided into chunks of voxels. Each voxel has some soil feature
and density. */

enum SurfaceGen
{
    block,  // Generate minecraft-like cubes
    smooth  // Generate smoothed colored triangles-mesh
}

class Soil
{
    string name;
    Vector3f color; // todo define a proper color structure
    //todo add some texture feature
    float  density; // in kg/m³
}

struct Voxel
{
    Soil  soil;
    union
    {
        bool  solid;        // Used with SurfaceGen.block
        float volumeRatio;  // Used with SurfaceGen.smooth
    }
}

struct Chunk(int SIZE)
{
    Voxel[SIZE][SIZE][SIZE] voxels;
}

struct TerrainMesh
{
    int[]       vertexPointIds;
    Vector3f[]  vertexNormals;
    Vector3f[]  vertexColor;
    Vector3f[]  points;
    int[4][]    triangleSpans;

    //todo later, we'll need to add neighbours when implementing octrees
    void generate(int SIZE, SurfaceGen GEN=solid)(in ref Chunk!SIZE chunk)
    {
        BitArray vertexMap;
        vertexMap.length = (SIZE + 1) * (SIZE + 1) * (SIZE + 1);
        void generateVoxel(int x, int y, int z)
        {
            if (x == 0 || chunk.voxels[x - 1][y][z].solid){}

        }

        for (x = 0; x < SIZE; x++)
            for (y = 0; y < SIZE; y++)
                for (z = 0; z < SIZE; z++)
                {
                    // If voxel is void
                    if (!chunk.voxels[x][y][z].solid)
                        continue;
                    generateVoxel(x, y, z);
                }
    }
}



/+
study in case we implement hermite stuff, but that's not the case

import std.meta:allSatisfy;

struct QefParam
{
    float[6] coefsAta;  // 3x3 symetric matrix of AT.A
    float[3] coefsAtb;  // 3d vector from AT.b
    float    coefsBtb;  // scalar value result of bT.b
}

bool isVector3f(V) = is(typeof(V) == Vector3f);

void calcQefParam(Args...)(out ref QefParam param,
                           in Args pointsNormals)
    if (Args.length % 2 == 0 && Args.length >= 6 &&
        allSatisfy!(isVector3f, Args))
{
    foreach (argArgsparam.coefsAta[0] =
}
+/