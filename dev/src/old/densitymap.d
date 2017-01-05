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

module orb.densitymap;

import std.array;
import std.math;
import std.stdio;

import dlib.math.vector;

import orb.algo.marchingcubestable;


/* The density threshold is 0. All negative value are considered to be "empty"
   and all positive value are considered to be "full". */
enum float DENSITY_EPSILON = 0.00001f;

enum NormalGeneration
{
    TRIANGLE_NORMALS = 0,
    VERTEX_NORMALS
}

struct VertexId
{
    int pointId;
    int normalId;
}

alias Edge = VertexId;

class DensityMap(int SizeX, int SizeY, int SizeZ)
        if (SizeX > 1 && SizeY > 1 && SizeZ > 1)
{
private:
    // input data
    float[SizeX][SizeY][SizeZ]      mMap;
    NormalGeneration                mNormalsGeneration;
    // intermediate data
    Edge[SizeX-1][SizeY][SizeZ]     mEdgeX;
    Edge[SizeY-1][SizeZ][SizeX]     mEdgeY;
    Edge[SizeZ-1][SizeX][SizeY]     mEdgeZ;
    // output data
    Appender!(Vector3f[])           mPoints;
    Appender!(Vector3f[])           mNormals;
    Appender!(VertexId[])           mVertexIds;

    void tesselateCube(int x, int y, int z, NormalGeneration normalsGeneration)
    {
        uint vertexBitfield = 0x00;

        void updateVertexBitfield(int X, int Y, int Z)()
        {
            if (mMap[z+Z][y+Y][x+X] >= 0.0f)
                vertexBitfield |= 1 << (X + Y * 2 + Z * (2 * 2));
            //writef("e[%d,%d,%d]=%d ", z+Z, y+Y, x+X, mMap[z+Z][y+Y][x+X]);
        }
        updateVertexBitfield!(0, 0, 0)();
        updateVertexBitfield!(1, 0, 0)();
        updateVertexBitfield!(0, 1, 0)();
        updateVertexBitfield!(1, 1, 0)();
        updateVertexBitfield!(0, 0, 1)();
        updateVertexBitfield!(1, 0, 1)();
        updateVertexBitfield!(0, 1, 1)();
        updateVertexBitfield!(1, 1, 1)();

        ushort edgeBitfield = edgeBitfields[vertexBitfield];

        //writefln("### VertexBit=0x%02x Edge=0x%03x ###", vertexBitfield, edgeBitfield);

        // no vertices to interpolate, so next cube
        if (edgeBitfield == 0x000)
            return;

        Edge*[12] edges;

        void interpolateEdge(int I, int C)
                            (int x0, int y0, int z0,
                             int x1, int y1, int z1,
                             Edge *edge)
        {
            //writefln("%d %d/%d %d %d/%d %d %d", I, C, x0, y0, z0, x1, y1, z1);
            // is there any vertex on that edge?
            if (edgeBitfield & (0x001 << I))
            {
                // is vertex not defined yet?
                if (edge.normalId == 0)
                {
                    Vector3f v;
                    v.x = cast(float)x0;
                    v.y = cast(float)y0;
                    v.z = cast(float)z0;
                    float d0 = mMap[z0][y0][x0];
                    float d1 = mMap[z1][y1][x1];
                    if(abs(d0 - d1) > DENSITY_EPSILON)
                        v.arrayof[C] += d0 / (d0 - d1);
                    mPoints.put(v);
                    edge.pointId = cast(int)mPoints.data.length - 1;
                    //writefln("a[%d %d %d]%.2f--[%d %d %d]%.2f=[%.2f %.2f %.2f] PtId=%d",
                    //         x0, y0, z0, d0, x1, y1, z1, d1, v.x, v.y, v.z, I);
                }
                edges[I] = edge;
            }
        }

        interpolateEdge!(0,  0)(x,     y,     z,     x + 1, y,     z    , &mEdgeX[z]  [y]  [x]);
        interpolateEdge!(1,  1)(x,     y,     z,     x,     y + 1, z    , &mEdgeY[x]  [z]  [y]);
        interpolateEdge!(2,  1)(x + 1, y,     z,     x + 1, y + 1, z    , &mEdgeY[x+1][z]  [y]);
        interpolateEdge!(3,  0)(x,     y + 1, z,     x + 1, y + 1, z    , &mEdgeX[z]  [y+1][x]);
        interpolateEdge!(4,  2)(x,     y,     z,     x,     y,     z + 1, &mEdgeZ[y]  [x]  [z]);
        interpolateEdge!(5,  2)(x + 1, y,     z,     x + 1, y,     z + 1, &mEdgeZ[y]  [x+1][z]);
        interpolateEdge!(6,  2)(x,     y + 1, z,     x,     y + 1, z + 1, &mEdgeZ[y+1][x]  [z]);
        interpolateEdge!(7,  2)(x + 1, y + 1, z,     x + 1, y + 1, z + 1, &mEdgeZ[y+1][x+1][z]);
        interpolateEdge!(8,  0)(x,     y,     z + 1, x + 1, y,     z + 1, &mEdgeX[z+1][y]  [x]);
        interpolateEdge!(9,  1)(x,     y,     z + 1, x,     y + 1, z + 1, &mEdgeY[x]  [z+1][y]);
        interpolateEdge!(10, 1)(x + 1, y,     z + 1, x + 1, y + 1, z + 1, &mEdgeY[x+1][z+1][y]);
        interpolateEdge!(11, 0)(x,     y + 1, z + 1, x + 1, y + 1, z + 1, &mEdgeX[z+1][y+1][x]);

        // tesselate the cube by getting the ids of the triangles
        for (int e = 0; e < 15 && triangleMeshes[vertexBitfield][e] != -1; e += 3)
        {
            Vector3f v0, v1, v;
            // get triangle tesselation
            int triEdge0 = cast(int)triangleMeshes[vertexBitfield][e];
            int triEdge1 = cast(int)triangleMeshes[vertexBitfield][e + 1];
            int triEdge2 = cast(int)triangleMeshes[vertexBitfield][e + 2];
            int ptId0 = edges[triEdge0].pointId;
            int ptId1 = edges[triEdge1].pointId;
            int ptId2 = edges[triEdge2].pointId;
            // save vertex
            VertexId vtx0, vtx1, vtx2;
            vtx0.pointId = ptId0;
            vtx1.pointId = ptId1;
            vtx2.pointId = ptId2;
            //writefln("PtId=[%d %d %d] NormId=%d (%.2f %.2f %.2f)",
            //         ptId0, ptId1, ptId2, vtx0.normalId, v.x, v.y, v.z);
            // calculate normal vector of the triangle
            v  = mPoints.data[ptId0];
            v0 = mPoints.data[ptId1];
            v1 = mPoints.data[ptId2];
            v0 -= v;
            v1 -= v;
            v = cross(v0, v1);
            if (normalsGeneration == NormalGeneration.TRIANGLE_NORMALS)
            {
                mNormals.put(v);
                edges[triEdge0].normalId = 1;
                edges[triEdge1].normalId = 1;
                edges[triEdge2].normalId = 1;
                vtx0.normalId = cast(int)mNormals.data.length - 1;
                vtx1.normalId = cast(int)mNormals.data.length - 1;
                vtx2.normalId = cast(int)mNormals.data.length - 1;
                //writefln("TriEdge=%d %d %d nbnorm=%d %d %d", triEdge0, triEdge1, triEdge2, edges[triEdge0].nbNormal, edges[triEdge1].nbNormal, edges[triEdge2].nbNormal);
            }
            else
            {
                v /=  v.lengthsqr;
                if (edges[triEdge0].normalId == 0)
                {
                    mNormals.put(v);
                    edges[triEdge0].normalId = cast(int)mNormals.data.length;
                }
                else
                    mNormals.data[edges[triEdge0].normalId - 1] += v;
                if (edges[triEdge1].normalId == 0)
                {
                    mNormals.put(v);
                    edges[triEdge1].normalId = cast(int)mNormals.data.length;
                }
                else
                    mNormals.data[edges[triEdge1].normalId - 1] += v;
                if (edges[triEdge2].normalId == 0)
                {
                    mNormals.put(v);
                    edges[triEdge2].normalId = cast(int)mNormals.data.length;
                }
                else
                    mNormals.data[edges[triEdge2].normalId - 1] += v;
                vtx0.normalId = edges[triEdge0].normalId - 1;
                vtx1.normalId = edges[triEdge1].normalId - 1;
                vtx2.normalId = edges[triEdge2].normalId - 1;
                //writefln("normalId=%d %d %d", vtx0.normalId, vtx1.normalId, vtx2.normalId);
            }
            mVertexIds.put(vtx0);
            mVertexIds.put(vtx1);
            mVertexIds.put(vtx2);
        }
    }

public:
    /*** ACCESSORS ***/
    @property
    void map(in float[SizeX][SizeY][SizeZ] mapArray)
    {
        mMap = mapArray;
    }

    @property
    ref float[SizeX][SizeY][SizeZ] map()
    {
        return mMap;
    }

    @property
    Vector3f[] points()
    {
        return mPoints.data;
    }
    @property
    Vector3f[] normals()
    {
        return mNormals.data;
    }
    @property
    VertexId[] vertexIds()
    {
        return mVertexIds.data;
    }

    /*** API FUNCTIONS ***/
    void tesselate(NormalGeneration normalsGeneration)
    {
        Vector3f[12]    edges;

        // for each cube of the map
        for (int z = 0; z < SizeZ - 1; z++)
            for (int y = 0; y < SizeY - 1; y++)
                for (int x = 0; x < SizeX - 1; x++)
                    tesselateCube(x, y, z, normalsGeneration);
    }
}