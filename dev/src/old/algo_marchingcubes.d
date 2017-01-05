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

module orb.algo.marchingcubes;

/*
 * http://users.polytech.unice.fr/~lingrand/MarchingCubes/algo.html
 * http://paulbourke.net/geometry/polygonise/
 */

import std.array;
import std.math;
import std.stdio;

import dlib.math.matrix;
import dlib.math.vector;

import orb.algo.marchingcubestable;
import orb.exception;



alias Density = float;

/* The density threshold is 0. All negative value are considered to be "empty"
   and all positive value are considered to be "full". */
enum Density densityEpsilon   = 0.00001f;

immutable(int)[3] p0 = [-1, -1, -1];
immutable(int)[3] p1 = [1, -1, -1];
immutable(int)[3] p2 = [-1, 1, -1];
immutable(int)[3] p3 = [1, 1, -1];
immutable(int)[3] p4 = [-1, -1, 1];
immutable(int)[3] p5 = [1, -1, 1];
immutable(int)[3] p6 = [-1, 1, 1];
immutable(int)[3] p7 = [1, 1, 1];

immutable(int)[3] va = [0, -1, -1];
immutable(int)[3] vb = [-1, 0, -1];
immutable(int)[3] vc = [1, 0, -1];
immutable(int)[3] vd = [0, 1, -1];
immutable(int)[3] ve = [-1, -1, 0];
immutable(int)[3] vf = [1, -1, 0];
immutable(int)[3] vg = [-1, 1, 0];
immutable(int)[3] vh = [1, 1, 0];
immutable(int)[3] vi = [0, -1, 1];
immutable(int)[3] vj = [-1, 0, 1];
immutable(int)[3] vk = [1, 0, 1];
immutable(int)[3] vl = [0, 1, 1];


/**
 * Tesselate 3D space using the marching-cube algorithm.
 */
void tesselate(DensityMap : Density[SizeX][SizeY][SizeZ],
               int SizeX, int SizeY, int SizeZ)
              (in ref DensityMap    densityMap,
               ref Vector3f[]       points)
        if (SizeX > 1 && SizeY > 1 && SizeZ > 1)
{
    auto vertexArray = appender!(Vector3f[])();

    Vector3f[12]    edges;

    // for each cube of the map
    for (int z = 0; z < SizeZ - 1; z++)
        for (int y = 0; y < SizeY - 1; y++)
            for (int x = 0; x < SizeX - 1; x++)
            {
                uint mapIndex = 0x00;

                void updateMapIndex(int X, int Y, int Z)()
                {
//                    if (densityMap[z+Z][y+Y][x+X] != 0)
                    if (densityMap[z+Z][y+Y][x+X] >= 0.0f)
                        mapIndex |= 1 << (X + Y * 2 + Z * (2 * 2));
                    //writef("e[%d,%d,%d]=%d ", z+Z, y+Y, x+X, densityMap[z+Z][y+Y][x+X]);
                }
                updateMapIndex!(0, 0, 0)();
                updateMapIndex!(1, 0, 0)();
                updateMapIndex!(0, 1, 0)();
                updateMapIndex!(1, 1, 0)();
                updateMapIndex!(0, 0, 1)();
                updateMapIndex!(1, 0, 1)();
                updateMapIndex!(0, 1, 1)();
                updateMapIndex!(1, 1, 1)();
                //writef("\n");
                //writefln("  cube[%d][%d][%d]=0x%02x", z, y, x, mapIndex);

                ushort edgeMap = edgeBitfields[mapIndex];

                // no vertices to interpolate, so next cube
                if (edgeMap == 0x000)
                    continue;

                //writefln("cube[%d][%d][%d]=0x%03x/%d", z, y, x, edgeMap, mapIndex);

                // for each active edge
                if (edgeMap & (0x001 << 0))
                {
                    edges[0].x = cast(float)x;
                    edges[0].y = cast(float)y;
                    edges[0].z = cast(float)z;
                    Density d0 = densityMap[z][y][x];
                    Density d1 = densityMap[z][y][x+1];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[0].x += d0 / (d0 - d1);
                    /*writefln("a[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x, y, z, d0,
                        x+1, y, z, d1,
                        edges[0].x, edges[0].y, edges[0].z);*/
                }
                if (edgeMap & (0x001 << 1))
                {
                    edges[1].x = cast(float)x;
                    edges[1].y = cast(float)y;
                    edges[1].z = cast(float)z;
                    Density d0 = densityMap[z][y][x];
                    Density d1 = densityMap[z][y+1][x];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[1].y += d0 / (d0 - d1);
                    /*writefln("b[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x, y, z, d0,
                        x, y+1, z, d1,
                        edges[1].x, edges[1].y, edges[1].z);*/
                }
                if (edgeMap & (0x001 << 2))
                {
                    edges[2].x = cast(float)x + 1.0f;
                    edges[2].y = cast(float)y;
                    edges[2].z = cast(float)z;
                    Density d0 = densityMap[z][y][x+1];
                    Density d1 = densityMap[z][y+1][x+1];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[2].y += d0 / (d0 - d1);
                    /*writefln("c[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x+1, y, z, d0,
                        x+1, y+1, z, d1,
                        edges[2].x, edges[2].y, edges[2].z);*/
                }
                if (edgeMap & (0x001 << 3))
                {
                    edges[3].x = cast(float)x;
                    edges[3].y = cast(float)y + 1.0f;
                    edges[3].z = cast(float)z;
                    Density d0 = densityMap[z][y+1][x];
                    Density d1 = densityMap[z][y+1][x+1];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[3].x += d0 / (d0 - d1);
                    /*writefln("d[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x, y+1, z, d0,
                        x+1, y+1, z, d1,
                        edges[3].x, edges[3].y, edges[3].z);*/
                }

                if (edgeMap & (0x001 << 4))
                {
                    edges[4].x = cast(float)x;
                    edges[4].y = cast(float)y;
                    edges[4].z = cast(float)z;
                    Density d0 = densityMap[z][y][x];
                    Density d1 = densityMap[z+1][y][x];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[4].z += d0 / (d0 - d1);
                    /*writefln("e[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x, y, z, d0,
                        x, y, z+1, d1,
                        edges[4].x, edges[4].y, edges[4].z);*/
                }
                if (edgeMap & (0x001 << 5))
                {
                    edges[5].x = cast(float)x + 1.0f;
                    edges[5].y = cast(float)y;
                    edges[5].z = cast(float)z;
                    Density d0 = densityMap[z][y][x+1];
                    Density d1 = densityMap[z+1][y][x+1];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[5].z += d0 / (d0 - d1);
                    /*writefln("f[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x+1, y, z, d0,
                        x+1, y, z+1, d1,
                        edges[5].x, edges[5].y, edges[5].z);*/
                }
                if (edgeMap & (0x001 << 6))
                {
                    edges[6].x = cast(float)x;
                    edges[6].y = cast(float)y + 1.0f;
                    edges[6].z = cast(float)z;
                    Density d0 = densityMap[z][y+1][x];
                    Density d1 = densityMap[z+1][y+1][x];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[6].z += d0 / (d0 - d1);
                    /*writefln("g[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x, y+1, z, d0,
                        x, y+1, z+1, d1,
                        edges[6].x, edges[6].y, edges[6].z);*/
                }
                if (edgeMap & (0x001 << 7))
                {
                    edges[7].x = cast(float)x + 1.0f;
                    edges[7].y = cast(float)y + 1.0f;
                    edges[7].z = cast(float)z;
                    Density d0 = densityMap[z][y+1][x+1];
                    Density d1 = densityMap[z+1][y+1][x+1];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[7].z += d0 / (d0 - d1);
                    /*writefln("h[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x+1, y+1, z, d0,
                        x+1, y+1, z+1, d1,
                        edges[7].x, edges[7].y, edges[7].z);*/
                }

                if (edgeMap & (0x001 << 8))
                {
                    edges[8].x = cast(float)x;
                    edges[8].y = cast(float)y;
                    edges[8].z = cast(float)z + 1.0f;
                    Density d0 = densityMap[z+1][y][x];
                    Density d1 = densityMap[z+1][y][x+1];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[8].x += d0 / (d0 - d1);
                    /*writefln("i[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x, y, z+1, d0,
                        x+1, y, z+1, d1,
                        edges[8].x, edges[8].y, edges[8].z);*/
                }
                if (edgeMap & (0x001 << 9))
                {
                    edges[9].x = cast(float)x;
                    edges[9].y = cast(float)y;
                    edges[9].z = cast(float)z + 1.0f;
                    Density d0 = densityMap[z+1][y][x];
                    Density d1 = densityMap[z+1][y+1][x];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[9].y += d0 / (d0 - d1);
                    /*writefln("j[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x, y, z+1, d0,
                        x, y+1, z+1, d1,
                        edges[9].x, edges[9].y, edges[9].z);*/
                }
                if (edgeMap & (0x001 << 10))
                {
                    edges[10].x = cast(float)x + 1.0f;
                    edges[10].y = cast(float)y;
                    edges[10].z = cast(float)z + 1.0f;
                    Density d0 = densityMap[z+1][y][x+1];
                    Density d1 = densityMap[z+1][y+1][x+1];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[10].y += d0 / (d0 - d1);
                    /*writefln("k[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x+1, y, z+1, d0,
                        x+1, y+1, z+1, d1,
                        edges[10].x, edges[10].y, edges[10].z);*/
                }
                if (edgeMap & (0x001 << 11))
                {
                    edges[11].x = cast(float)x;
                    edges[11].y = cast(float)y + 1.0f;
                    edges[11].z = cast(float)z + 1.0f;
                    Density d0 = densityMap[z+1][y+1][x];
                    Density d1 = densityMap[z+1][y+1][x+1];
                    if(abs(d0 - d1) > densityEpsilon)
                        edges[11].x += d0 / (d0 - d1);
                    /*writefln("l[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f]",
                        x, y+1, z+1, d0,
                        x+1, y+1, z+1, d1,
                        edges[11].x, edges[11].y, edges[11].z);*/
                }

                for (int e = 0; triangleMeshes[mapIndex][e] != -1; e++)
                {
                    int triangleEdge = cast(int)triangleMeshes[mapIndex][e];
                    vertexArray.put(edges[triangleEdge]);
                    /*writefln("New[%.2f %.2f %.2f] %2d",
                        edges[triangleEdge].x, edges[triangleEdge].y, edges[triangleEdge].z, e);*/
                }
            }

    points = vertexArray.data;

    /*foreach (ref area; densityMap)
    {
        writef("[ ");
        foreach (ref line; area)
        {
            writef("[ ");
            foreach (densityVal; line)
                writef("%d ", cast(int)densityVal);
            writef("] ");
        }
        writefln("]");
    }*/
}

unittest
{
/+    Density[4][4][4] densityMap =
/*            [[[0,0,0,0], [0,0,1,0], [0,1,0,0], [0,0,0,0]],
             [[0,1,1,0], [0,2,2,0], [0,2,2,0], [0,0,1,0]],
             [[0,1,1,0], [0,2,2,0], [0,2,1,0], [0,0,0,0]],
             [[0,0,0,0], [0,1,0,0], [0,0,0,0], [0,0,0,0]]];*/
            [[[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]],
             [[0,0,0,0], [0,2,2,0], [0,2,2,0], [0,0,0,0]],
             [[0,0,0,0], [0,2,2,0], [0,2,2,0], [0,0,0,0]],
             [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]];

    Vector3i[] pts;

    tesselate(densityMap, pts);

    writefln("%d", pts.length);+/

    /*// Create the edge mapping for vertex calculation
    for (int i = 0; i < 256; i++)
    {
        ushort vertexIndex = 0x000;
        if (!(i & 0x01) != !(i & 0x02))
            vertexIndex |= 0x001;
        if (!(i & 0x01) != !(i & 0x04))
            vertexIndex |= 0x002;
        if (!(i & 0x02) != !(i & 0x08))
            vertexIndex |= 0x004;
        if (!(i & 0x04) != !(i & 0x08))
            vertexIndex |= 0x008;

        if (!(i & 0x01) != !(i & 0x10))
            vertexIndex |= 0x010;
        if (!(i & 0x02) != !(i & 0x20))
            vertexIndex |= 0x020;
        if (!(i & 0x04) != !(i & 0x40))
            vertexIndex |= 0x040;
        if (!(i & 0x08) != !(i & 0x80))
            vertexIndex |= 0x080;

        if (!(i & 0x10) != !(i & 0x20))
            vertexIndex |= 0x100;
        if (!(i & 0x10) != !(i & 0x40))
            vertexIndex |= 0x200;
        if (!(i & 0x20) != !(i & 0x80))
            vertexIndex |= 0x400;
        if (!(i & 0x40) != !(i & 0x80))
            vertexIndex |= 0x800;

        if ((i & 0x7) == 0x0)
            writef("\n");
        writef("0x%03x, ", vertexIndex);
    }*/

    /*// Create the triangle mapping
    for (int i = 0; i < 256; i++)
    {
        ushort vertexIndex = 0x000;
        if (!(i & 0x01) != !(i & 0x02))
            vertexIndex |= 0x001;
        if (!(i & 0x01) != !(i & 0x04))
            vertexIndex |= 0x002;
        if (!(i & 0x02) != !(i & 0x08))
            vertexIndex |= 0x004;
        if (!(i & 0x04) != !(i & 0x08))
            vertexIndex |= 0x008;

        if (!(i & 0x01) != !(i & 0x10))
            vertexIndex |= 0x010;
        if (!(i & 0x02) != !(i & 0x20))
            vertexIndex |= 0x020;
        if (!(i & 0x04) != !(i & 0x40))
            vertexIndex |= 0x040;
        if (!(i & 0x08) != !(i & 0x80))
            vertexIndex |= 0x080;

        if (!(i & 0x10) != !(i & 0x20))
            vertexIndex |= 0x100;
        if (!(i & 0x10) != !(i & 0x40))
            vertexIndex |= 0x200;
        if (!(i & 0x20) != !(i & 0x80))
            vertexIndex |= 0x400;
        if (!(i & 0x40) != !(i & 0x80))
            vertexIndex |= 0x800;

        if ((i & 0x7) == 0x0)
            writef("\n");
        writef("0x%03x, ", vertexIndex);
    }*/
}

int getEdgeId(int x, int y, int z)
{
    if (x == 0 && y == -1 && z == -1) // A
        return 0;
    if (x == -1 && y == 0 && z == -1) // B
        return 1;
    if (x == 1 && y == 0 && z == -1) // C
        return 2;
    if (x == 0 && y == 1 && z == -1) // D
        return 3;

    if (x == -1 && y == -1 && z == 0) // E
        return 4;
    if (x == 1 && y == -1 && z == 0) // F
        return 5;
    if (x == -1 && y == 1 && z == 0) // G
        return 6;
    if (x == 1 && y == 1 && z == 0) // H
        return 7;

    if (x == 0 && y == -1 && z == 1) // I
        return 8;
    if (x == -1 && y == 0 && z == 1) // J
        return 9;
    if (x == 1 && y == 0 && z == 1) // K
        return 10;
    if (x == 0 && y == 1 && z == 1) // L
        return 11;

    return -1;
}


int getVertexId(int x, int y, int z)
{
    if (x == -1 && y == -1 && z == -1)
        return 0;
    if (x == 1 && y == -1 && z == -1)
        return 1;
    if (x == -1 && y == 1 && z == -1)
        return 2;
    if (x == 1 && y == 1 && z == -1)
        return 3;

    if (x == -1 && y == -1 && z == 1)
        return 4;
    if (x == 1 && y == -1 && z == 1)
        return 5;
    if (x == -1 && y == 1 && z == 1)
        return 6;
    if (x == 1 && y == 1 && z == 1)
        return 7;

    return -1;
}


struct MCubesMesh
{
    int          nbDensityPoints;
    int[3][4]    densityPoints;
    int          nbMeshTriangles;
    int[3][3][4] meshTriangles;
}

MCubesMesh[14] mCubesMesh;

static this()
{
    // CCW
    //
    mCubesMesh[0].nbDensityPoints = 1;
    mCubesMesh[0].densityPoints[0] = p0;
    mCubesMesh[0].nbMeshTriangles = 1;
    mCubesMesh[0].meshTriangles[0][0] = ve;
    mCubesMesh[0].meshTriangles[0][1] = va;
    mCubesMesh[0].meshTriangles[0][2] = vb;
    //
    mCubesMesh[1].nbDensityPoints = 2;
    mCubesMesh[1].densityPoints[0] = p0;
    mCubesMesh[1].densityPoints[1] = p1;
    mCubesMesh[1].nbMeshTriangles = 2;
    mCubesMesh[1].meshTriangles[0][0] = ve;
    mCubesMesh[1].meshTriangles[0][1] = vf;
    mCubesMesh[1].meshTriangles[0][2] = vb;
    mCubesMesh[1].meshTriangles[1][0] = vb;
    mCubesMesh[1].meshTriangles[1][1] = vf;
    mCubesMesh[1].meshTriangles[1][2] = vc;
    //
    mCubesMesh[2].nbDensityPoints = 2;
    mCubesMesh[2].densityPoints[0] = p0;
    mCubesMesh[2].densityPoints[1] = p3;
    mCubesMesh[2].nbMeshTriangles = 2;
    mCubesMesh[2].meshTriangles[0][0] = ve;
    mCubesMesh[2].meshTriangles[0][1] = va;
    mCubesMesh[2].meshTriangles[0][2] = vb;
    mCubesMesh[2].meshTriangles[1][0] = vd;
    mCubesMesh[2].meshTriangles[1][1] = vc;
    mCubesMesh[2].meshTriangles[1][2] = vh;
    //
    mCubesMesh[3].nbDensityPoints = 2;
    mCubesMesh[3].densityPoints[0] = p0;
    mCubesMesh[3].densityPoints[1] = p7;
    mCubesMesh[3].nbMeshTriangles = 2;
    mCubesMesh[3].meshTriangles[0][0] = ve;
    mCubesMesh[3].meshTriangles[0][1] = va;
    mCubesMesh[3].meshTriangles[0][2] = vb;
    mCubesMesh[3].meshTriangles[1][0] = vl;
    mCubesMesh[3].meshTriangles[1][1] = vh;
    mCubesMesh[3].meshTriangles[1][2] = vk;
    //
    mCubesMesh[4].nbDensityPoints = 3;
    mCubesMesh[4].densityPoints[0] = p0;
    mCubesMesh[4].densityPoints[1] = p1;
    mCubesMesh[4].densityPoints[2] = p4;
    mCubesMesh[4].nbMeshTriangles = 3;
    mCubesMesh[4].meshTriangles[0][0] = vj;
    mCubesMesh[4].meshTriangles[0][1] = vc;
    mCubesMesh[4].meshTriangles[0][2] = vb;
    mCubesMesh[4].meshTriangles[1][0] = vj;
    mCubesMesh[4].meshTriangles[1][1] = vi;
    mCubesMesh[4].meshTriangles[1][2] = vc;
    mCubesMesh[4].meshTriangles[2][0] = vc;
    mCubesMesh[4].meshTriangles[2][1] = vi;
    mCubesMesh[4].meshTriangles[2][2] = vf;
    //
    mCubesMesh[5].nbDensityPoints = 3;
    mCubesMesh[5].densityPoints[0] = p0;
    mCubesMesh[5].densityPoints[1] = p1;
    mCubesMesh[5].densityPoints[2] = p6;
    mCubesMesh[5].nbMeshTriangles = 3;
    mCubesMesh[5].meshTriangles[0][0] = ve;
    mCubesMesh[5].meshTriangles[0][1] = vf;
    mCubesMesh[5].meshTriangles[0][2] = vb;
    mCubesMesh[5].meshTriangles[1][0] = vb;
    mCubesMesh[5].meshTriangles[1][1] = vf;
    mCubesMesh[5].meshTriangles[1][2] = vc;
    mCubesMesh[5].meshTriangles[2][0] = vl;
    mCubesMesh[5].meshTriangles[2][1] = vj;
    mCubesMesh[5].meshTriangles[2][2] = vg;
    //
    mCubesMesh[6].nbDensityPoints = 3;
    mCubesMesh[6].densityPoints[0] = p1;
    mCubesMesh[6].densityPoints[1] = p2;
    mCubesMesh[6].densityPoints[2] = p4;
    mCubesMesh[6].nbMeshTriangles = 3;
    mCubesMesh[6].meshTriangles[0][0] = va;
    mCubesMesh[6].meshTriangles[0][1] = vf;
    mCubesMesh[6].meshTriangles[0][2] = vc;
    mCubesMesh[6].meshTriangles[1][0] = vg;
    mCubesMesh[6].meshTriangles[1][1] = vb;
    mCubesMesh[6].meshTriangles[1][2] = vd;
    mCubesMesh[6].meshTriangles[2][0] = vj;
    mCubesMesh[6].meshTriangles[2][1] = vi;
    mCubesMesh[6].meshTriangles[2][2] = ve;
    //
    mCubesMesh[7].nbDensityPoints = 4;
    mCubesMesh[7].densityPoints[0] = p0;
    mCubesMesh[7].densityPoints[1] = p1;
    mCubesMesh[7].densityPoints[2] = p4;
    mCubesMesh[7].densityPoints[3] = p5;
    mCubesMesh[7].nbMeshTriangles = 2;
    mCubesMesh[7].meshTriangles[0][0] = vb;
    mCubesMesh[7].meshTriangles[0][1] = vj;
    mCubesMesh[7].meshTriangles[0][2] = vc;
    mCubesMesh[7].meshTriangles[1][0] = vc;
    mCubesMesh[7].meshTriangles[1][1] = vj;
    mCubesMesh[7].meshTriangles[1][2] = vk;
    //
    mCubesMesh[8].nbDensityPoints = 4;
    mCubesMesh[8].densityPoints[0] = p0;
    mCubesMesh[8].densityPoints[1] = p1;
    mCubesMesh[8].densityPoints[2] = p2;
    mCubesMesh[8].densityPoints[3] = p4;
    mCubesMesh[8].nbMeshTriangles = 4;
    mCubesMesh[8].meshTriangles[0][0] = vg;
    mCubesMesh[8].meshTriangles[0][1] = vj;
    mCubesMesh[8].meshTriangles[0][2] = vd;
    mCubesMesh[8].meshTriangles[1][0] = vd;
    mCubesMesh[8].meshTriangles[1][1] = vj;
    mCubesMesh[8].meshTriangles[1][2] = vc;
    mCubesMesh[8].meshTriangles[2][0] = vc;
    mCubesMesh[8].meshTriangles[2][1] = vj;
    mCubesMesh[8].meshTriangles[2][2] = vi;
    mCubesMesh[8].meshTriangles[3][0] = vc;
    mCubesMesh[8].meshTriangles[3][1] = vi;
    mCubesMesh[8].meshTriangles[3][2] = vf;
    //
    mCubesMesh[9].nbDensityPoints = 4;
    mCubesMesh[9].densityPoints[0] = p0;
    mCubesMesh[9].densityPoints[1] = p2;
    mCubesMesh[9].densityPoints[2] = p5;
    mCubesMesh[9].densityPoints[3] = p7;
    mCubesMesh[9].nbMeshTriangles = 4;
    mCubesMesh[9].meshTriangles[0][0] = vg;
    mCubesMesh[9].meshTriangles[0][1] = ve;
    mCubesMesh[9].meshTriangles[0][2] = vd;
    mCubesMesh[9].meshTriangles[1][0] = vd;
    mCubesMesh[9].meshTriangles[1][1] = ve;
    mCubesMesh[9].meshTriangles[1][2] = va;
    mCubesMesh[9].meshTriangles[2][0] = vl;
    mCubesMesh[9].meshTriangles[2][1] = vh;
    mCubesMesh[9].meshTriangles[2][2] = vi;
    mCubesMesh[9].meshTriangles[3][0] = vi;
    mCubesMesh[9].meshTriangles[3][1] = vh;
    mCubesMesh[9].meshTriangles[3][2] = vf;
    //
    mCubesMesh[10].nbDensityPoints = 4;
    mCubesMesh[10].densityPoints[0] = p0;
    mCubesMesh[10].densityPoints[1] = p1;
    mCubesMesh[10].densityPoints[2] = p3;
    mCubesMesh[10].densityPoints[3] = p4;
    mCubesMesh[10].nbMeshTriangles = 4;
    mCubesMesh[10].meshTriangles[0][0] = vb;
    mCubesMesh[10].meshTriangles[0][1] = vj;
    mCubesMesh[10].meshTriangles[0][2] = vi;
    mCubesMesh[10].meshTriangles[1][0] = vb;
    mCubesMesh[10].meshTriangles[1][1] = vi;
    mCubesMesh[10].meshTriangles[1][2] = vh;
    mCubesMesh[10].meshTriangles[2][0] = vd;
    mCubesMesh[10].meshTriangles[2][1] = vb;
    mCubesMesh[10].meshTriangles[2][2] = vh;
    mCubesMesh[10].meshTriangles[3][0] = vh;
    mCubesMesh[10].meshTriangles[3][1] = vi;
    mCubesMesh[10].meshTriangles[3][2] = vf;
    //
    mCubesMesh[11].nbDensityPoints = 4;
    mCubesMesh[11].densityPoints[0] = p0;
    mCubesMesh[11].densityPoints[1] = p1;
    mCubesMesh[11].densityPoints[2] = p4;
    mCubesMesh[11].densityPoints[3] = p7;
    mCubesMesh[11].nbMeshTriangles = 4;
    mCubesMesh[11].meshTriangles[0][0] = vj;
    mCubesMesh[11].meshTriangles[0][1] = vc;
    mCubesMesh[11].meshTriangles[0][2] = vb;
    mCubesMesh[11].meshTriangles[1][0] = vj;
    mCubesMesh[11].meshTriangles[1][1] = vi;
    mCubesMesh[11].meshTriangles[1][2] = vc;
    mCubesMesh[11].meshTriangles[2][0] = vc;
    mCubesMesh[11].meshTriangles[2][1] = vi;
    mCubesMesh[11].meshTriangles[2][2] = vf;
    mCubesMesh[11].meshTriangles[3][0] = vl;
    mCubesMesh[11].meshTriangles[3][1] = vh;
    mCubesMesh[11].meshTriangles[3][2] = vk;
    //
    mCubesMesh[12].nbDensityPoints = 4;
    mCubesMesh[12].densityPoints[0] = p0;
    mCubesMesh[12].densityPoints[1] = p3;
    mCubesMesh[12].densityPoints[2] = p5;
    mCubesMesh[12].densityPoints[3] = p6;
    mCubesMesh[12].nbMeshTriangles = 4;
    mCubesMesh[12].meshTriangles[0][0] = ve;
    mCubesMesh[12].meshTriangles[0][1] = va;
    mCubesMesh[12].meshTriangles[0][2] = vb;
    mCubesMesh[12].meshTriangles[1][0] = vk;
    mCubesMesh[12].meshTriangles[1][1] = vf;
    mCubesMesh[12].meshTriangles[1][2] = vi;
    mCubesMesh[12].meshTriangles[2][0] = vl;
    mCubesMesh[12].meshTriangles[2][1] = vj;
    mCubesMesh[12].meshTriangles[2][2] = vg;
    mCubesMesh[12].meshTriangles[3][0] = vd;
    mCubesMesh[12].meshTriangles[3][1] = vc;
    mCubesMesh[12].meshTriangles[3][2] = vh;
    //
    mCubesMesh[13].nbDensityPoints = 4;
    mCubesMesh[13].densityPoints[0] = p0;
    mCubesMesh[13].densityPoints[1] = p1;
    mCubesMesh[13].densityPoints[2] = p2;
    mCubesMesh[13].densityPoints[3] = p5;
    mCubesMesh[13].nbMeshTriangles = 4;
    mCubesMesh[13].meshTriangles[0][0] = ve;
    mCubesMesh[13].meshTriangles[0][1] = vi;
    mCubesMesh[13].meshTriangles[0][2] = vg;
    mCubesMesh[13].meshTriangles[1][0] = vg;
    mCubesMesh[13].meshTriangles[1][1] = vi;
    mCubesMesh[13].meshTriangles[1][2] = vc;
    mCubesMesh[13].meshTriangles[2][0] = vg;
    mCubesMesh[13].meshTriangles[2][1] = vc;
    mCubesMesh[13].meshTriangles[2][2] = vd;
    mCubesMesh[13].meshTriangles[3][0] = vc;
    mCubesMesh[13].meshTriangles[3][1] = vi;
    mCubesMesh[13].meshTriangles[3][2] = vk;
}

unittest
{

    auto triMeshes = new byte[16][256];

    for (int i = 0; i < 256; i++)
    {
        // init triMesh
        foreach (ref j; triMeshes[i])
            j = -1;
    }

    // for each basic marching-cube meshes
    foreach (mesh; mCubesMesh)
        // for all the possible rotations
        for (int rx = 0; rx < 4; rx++)
        {
            Matrix3i mx;
            mx.rotationX(rx);
            for (int ry = 0; ry < 4; ry++)
            {
                Matrix3i my, mxy;
                my.rotationY(ry);
                mxy.multiply(mx, my);
                for (int rz = 0; rz < 4; rz++)
                {
                    // calculate the rotation matrix
                    Matrix3i mz, mxyz;
                    mz.rotationZ(rz);
                    mxyz.multiply(mxy, mz);

                    Vector3i vi, vo;
                    uint mapIndex = 0x00;

                    // calculate vertex map index
                    for (int i = 0; i < mesh.nbDensityPoints; i++)
                    {
                        vi = mesh.densityPoints[i];
                        multiply(vo, vi, mxyz);
                        writefln("%d %d %d", vi.x, vi.y, vi.z);
                        writefln("%d %d %d", vo.x, vo.y, vo.z);
                        int vId = getVertexId(vo.x, vo.y, vo.z);
                        assert(vId != -1, "Wrong vertex-id");
                        mapIndex |= 0x01 << vId;
                    }

                    assert(mapIndex != 0x00 && mapIndex != 0xff, "What??");

                    // check it is not already set
                    if (triMeshes[mapIndex][0] != -1)
                        continue;

                    // index the edges
                    for (int i = 0; i < mesh.nbMeshTriangles; i++)
                    {
                        int edgeId;
                        // 1st edge
                        vi = mesh.meshTriangles[i][0];
                        multiply(vo, vi, mxyz);
                        edgeId = getEdgeId(vo.x, vo.y, vo.z);
                        triMeshes[mapIndex][i*3+0]         = cast(byte)edgeId;
                        triMeshes[(~mapIndex)&0xff][i*3+0] = cast(byte)edgeId;
                        // 2nd edge
                        vi = mesh.meshTriangles[i][1];
                        multiply(vo, vi, mxyz);
                        edgeId = getEdgeId(vo.x, vo.y, vo.z);
                        triMeshes[mapIndex][i*3+1]         = cast(byte)edgeId;
                        triMeshes[(~mapIndex)&0xff][i*3+2] = cast(byte)edgeId;
                        // 3rd edge
                        vi = mesh.meshTriangles[i][2];
                        multiply(vo, vi, mxyz);
                        edgeId = getEdgeId(vo.x, vo.y, vo.z);
                        triMeshes[mapIndex][i*3+2]         = cast(byte)edgeId;
                        triMeshes[(~mapIndex)&0xff][i*3+1] = cast(byte)edgeId;
                    }
                }
            }
        }


    // display the result
    for (int i = 0; i < 256; i++)
    {
        writef("0x%02x[", i);
        // init triMesh
        foreach (ref j; triMeshes[i])
            writef("%2d, ", j);
        writefln("]");
    }

}
