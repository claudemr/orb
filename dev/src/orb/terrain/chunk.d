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

// todo build mesh using triangles spans.
// todo use a smooth terrain generation

module orb.terrain.chunk;

public import orb.terrain.populator;
public import orb.utils.geometry;

import orb.render.rendersystem;


/*
For a movement, the player/entity might move from a chunk to its 26
neighbors (in diagonal also).
So, at 30fps, an entity may have a maximum speed of 16voxels per 33.3ms, so
480Vx/s so 1728kVx/h, which is more than enough. Anything else should be
considered as teleportation.
*/
enum uint chunkSize    = 16;
 // Extended size: faces of chunks overlap so we can calculate mesh more easily
enum uint chunkSizeExt = chunkSize + 2;

alias Voxel = float;


private ubyte ngbId(Axis axis, Side side)
{
    return cast(ubyte)((side + 1) << (axis << 1));
}

bool isNgbIdSet(ubyte id, Axis axis, Side side)
{
    return !!(id & ngbId(axis, side));
}

void setNgbId(ref ubyte outId, Axis axis, Side side)
{
    outId |= ngbId(axis, side);
}

void clearNgbId(ref ubyte outId, Axis axis, Side side)
{
    outId &= ~ngbId(axis, side);
}

bool areAllNgbLoaded(ubyte id)
{
    return id == 0b11_11_11;
}

void resetNgbId(ref ubyte outId)
{
    outId = 0b00_00_00;
}


class Chunk
{
public:
    this(vec3i p)
    {
        pos            = p;
        timestamp      = MonoTime.zero;
        mEmpty         = true;
        mFull          = true;
        mFullSide      = [[true, true], [true, true], [true, true]];
    }

    ~this()
    {
        resetNeighbors();
    }

    Voxel opIndex(int x, int y, int z)
    {
        x++; y++; z++;
        return mVoxels[x][y][z];
    }

    Voxel opIndexAssign(Voxel v, int x, int y, int z)
    {
        x++; y++; z++;
        mVoxels[x][y][z] = v;
        return v;
    }

    void link(Axis a, Side s, Chunk neighbor)
    {
        auto sp = s == Side.front ? Side.back : Side.front;

        loadedNgb.setNgbId(a, s);
        neighbor.loadedNgb.setNgbId(a, sp);

        neighbors[a][s] = neighbor;
        neighbor.neighbors[a][sp] = this;
    }

    void unlink(Axis a, Side s)
    {
        auto sp = s == Side.front ? Side.back : Side.front;

        loadedNgb.clearNgbId(a, s);
        neighbors[a][s].loadedNgb.clearNgbId(a, sp);

        neighbors[a][s].neighbors[a][sp] = null;
        neighbors[a][s] = null;
    }

    void resetNeighbors()
    {
        // Unlink neighbors
        foreach (a; 0 .. 3)
        {
            if (neighbors[a][Side.front] !is null)
                unlink(cast(Axis)a, Side.front);
            if (neighbors[a][Side.back] !is null)
                unlink(cast(Axis)a, Side.back);
        }

        loadedNgb.resetNgbId();
        hiddenNeighbor = false;

        // It invalidates the mesh, so clean it
        if (mMesh !is null)
        {
            destroy(mMesh);
            mMesh = null;
        }

        mPoints.length = 0;
        mNormals.length = 0;
        mIndices.length = 0;
        mNbFace = 0;
    }

    void populate(Populator pop)
    {
        vec3i coord = pos * chunkSize;

        foreach (int z; -1 .. chunkSize + 1)
            foreach (int y; -1 .. chunkSize + 1)
                foreach (int x; -1 .. chunkSize + 1)
                {
                    // Get voxel density value
                    Voxel v = pop[coord.x + x, coord.y + y, coord.z + z];

                    // Update filling booleans
                    if (v < 0.0)
                    {
                        mEmpty = false;
                    }
                    else
                    {
                        mFull = false;
                        if (x == 0)
                            mFullSide[Axis.x][Side.back] = false;
                        else if (x == chunkSize - 1)
                            mFullSide[Axis.x][Side.front] = false;
                        if (y == 0)
                            mFullSide[Axis.y][Side.back] = false;
                        else if (y == chunkSize - 1)
                            mFullSide[Axis.y][Side.front] = false;
                        if (z == 0)
                            mFullSide[Axis.z][Side.back] = false;
                        else if (z == chunkSize - 1)
                            mFullSide[Axis.z][Side.front] = false;
                    }

                    // Update the 3D table
                    opIndexAssign(v, x, y, z);
                }
    }

    void buildMesh()
    {
        import std.format;

        static struct Cube
        {
            ubyte   cornerMask;
            Vertex* vertex;
        }

        alias YRow = Cube[chunkSize + 1][chunkSize + 1];

        void generateVertex(ref Cube cube, vec3i p)
        {
            import std.math : sgn, abs;

            // Each bit tells whether there is an intersection on the edge
            ushort edgeIntersecBitmask = edgeTable[cube.cornerMask];

            vec3f sumPoint = [0, 0, 0];
            int numIntersec = 0;

            foreach (i; 0 .. 12)
            {
                if (!(edgeIntersecBitmask & (1 << i)))
                    continue;

                // Get indices of the 2 corners
                int c0 = intersections[i][0];
                int c1 = intersections[i][1];
                vec3i coord0 = cornerCoords[c0] + p;
                vec3i coord1 = cornerCoords[c1] + p;
                float density0 = mVoxels[coord0.x][coord0.y][coord0.z];
                float density1 = mVoxels[coord1.x][coord1.y][coord1.z];

                vec3f edgePoint;

                // If 1st point has density ~= 0, take it
                if (abs(density0) < 1e-3)
                    edgePoint  = cornerCoords[c0];
                // If 2nd point has density ~= 0, take it
                else if (abs(density1) < 1e-3)
                    edgePoint  = cornerCoords[c1];
                // If both point have density ~= 0, take average
                else if (abs(density0 - density1) < 1e-3)
                    edgePoint = vec3f(cornerCoords[c0] + cornerCoords[c1]) / 2;
                // Else get the intersection point
                else
                {
                    float d = (density0 / (density0 - density1));
                    edgePoint = vec3f(cornerCoords[c0]);
                    if (i >= 8)
                        edgePoint.z = d;
                    else if ((i & 0x1) == 0x1)
                        edgePoint.y = d;
                    else //if ((i & 0x1) == 0x0)
                        edgePoint.x = d;
                }

                sumPoint += edgePoint;
                numIntersec++;
            }

            sumPoint = vec3f(p) + sumPoint / cast(float)numIntersec;
            cube.vertex = mMesh.insertVertex(sumPoint);
        }

        void buildCube(vec3i p, ref Cube cube)
        {
            ubyte index = 0b00000000;

            /* Make a bitfield index from the density sign of corners
               Each bit corresponds to a corner, and is set to 1 if its
               density is positive (so outside the volume) */
            enum makeDensityIdx(int x, int y, int z, string op) =
                q{
                    if (mVoxels[p.x+%d][p.y+%d][p.z+%d] %s 0)
                        index |= (1 << cornerIds[%d][%d][%d]);
                }.format(x, y, z, op, x, y, z);

            mixin(makeDensityIdx!(0, 0, 0, ">="));
            mixin(makeDensityIdx!(1, 0, 0, ">="));
            mixin(makeDensityIdx!(1, 1, 0, ">"));
            mixin(makeDensityIdx!(0, 1, 0, ">="));
            mixin(makeDensityIdx!(0, 0, 1, ">="));
            mixin(makeDensityIdx!(1, 0, 1, ">"));
            mixin(makeDensityIdx!(1, 1, 1, ">"));
            mixin(makeDensityIdx!(0, 1, 1, ">"));

            if (edgeTable[index] == 0x000)
            {
                cube.cornerMask = 0x000;
                cube.vertex = null;
            }
            else
            {
                cube.cornerMask = index;
                generateVertex(cube, p);
            }
        }

        void buildFaces(YRow*[2] cubeRows)
        {
            import std.format : format;

            enum cubePtr(int xi, int yi, int zi) =
                q{
                    &(*cubeRows[%d])[x + %d][z + %d]
                }.format(yi, xi, zi);

            // for each cube of the x/z plane
            foreach (x; 0 .. chunkSize)
                foreach (z; 0 .. chunkSize)
                {
                    Cube*[4] cubes;
                    cubes[0] = mixin(cubePtr!(0,0,0));

                    // Edges 10, 6 and 5 all point toward corner 6
                    // So check if it is outside the volume
                    auto pointingOutward = (cubes[0].cornerMask & (1 << 6));

                    void createFace()
                    {
                        Vertex* p0, p1, p2;

                        p0 = cubes[0].vertex;

                        // 1st triangle
                        if (pointingOutward)
                        {
                            p1 = cubes[1].vertex;
                            p2 = cubes[2].vertex;
                        }
                        else
                        {
                            p1 = cubes[2].vertex;
                            p2 = cubes[1].vertex;
                        }

                        mMesh.insertFace(p0, p1, p2);

                        // 2nd triangle
                        if (pointingOutward)
                        {
                            p1 = cubes[2].vertex;
                            p2 = cubes[3].vertex;
                        }
                        else
                        {
                            p1 = cubes[3].vertex;
                            p2 = cubes[2].vertex;
                        }

                        mMesh.insertFace(p0, p1, p2);
                    }

                    int cube0_edgeInfo = edgeTable[cubes[0].cornerMask];

                    // check top left edge
                    if (cube0_edgeInfo & (1 << 10))
                    {
                        cubes[1] = mixin(cubePtr!(1,0,0));
                        cubes[2] = mixin(cubePtr!(1,1,0));
                        cubes[3] = mixin(cubePtr!(0,1,0));
                        createFace();
                    }
                    // check top back edge
                    if (cube0_edgeInfo & (1 << 6))
                    {
                        cubes[1] = mixin(cubePtr!(0,1,0));
                        cubes[2] = mixin(cubePtr!(0,1,1));
                        cubes[3] = mixin(cubePtr!(0,0,1));
                        createFace();
                    }
                    // check back left edge
                    if (cube0_edgeInfo & (1 << 5))
                    {
                        cubes[1] = mixin(cubePtr!(0,0,1));
                        cubes[2] = mixin(cubePtr!(1,0,1));
                        cubes[3] = mixin(cubePtr!(1,0,0));
                        createFace();
                    }
                }
        }

        // Create the mesh
        mMesh = RenderSystem.renderer!IMesh.createMesh();

        // Alternate between 2 y-row of cubes to build the faces of the mesh
        YRow[2] yRows;

        // Compute first y-raw of cubes
        foreach (x; 0 .. chunkSize + 1)
            foreach (z; 0 .. chunkSize + 1)
                buildCube(vec3i(x, 0, z), yRows[0][x][z]);

        foreach (y; 1 .. chunkSize + 1)
        {
            foreach (x; 0 .. chunkSize + 1)
                foreach (z; 0 .. chunkSize + 1)
                    buildCube(vec3i(x, y, z), yRows[y&1][x][z]);

            buildFaces([&yRows[(y-1)&1], &yRows[y&1]]);
        }

        mMesh.commit();
        //assert(false);
    }

    auto points() @property const
    {
        return mPoints;
    }

    auto normals() @property const
    {
        return mNormals;
    }

    auto indices() @property const
    {
        return mIndices;
    }

    inout(IMesh) mesh() @property inout
    {
        return mMesh;
    }

    void mesh(IMesh mesh) @property
    {
        mMesh = mesh;
    }

    bool empty() @property const
    {
        return mEmpty;
    }

    bool[2][3] fullSide() @property const
    {
        return mFullSide;
    }

    bool populated() @property const
    {
        return !(mEmpty && mFull);
    }

    uint nbFace() @property const
    {
        return mNbFace;
    }

    override string toString() @property const
    {
        return pos.toString;
    }

public:
    // Chunk data
    vec3i       pos;
    ubyte       loadedNgb;
    Chunk[2][3] neighbors;
    bool        hiddenNeighbor;
    MonoTime    timestamp;
    bool        unloading;

private:
    // Mesh data
    Voxel[chunkSizeExt][chunkSizeExt][chunkSizeExt] mVoxels;
    bool                     mEmpty;
    bool                     mFull;
    bool[2][3]               mFullSide;
    vec3f[]                  mPoints;
    vec3f[]                  mNormals;
    uint[]                   mIndices;
    IMesh                    mMesh;
    uint                     mNbFace;
}


/*
Right-handed coordinate system


         top
          y
     left |
          |
back z----O   front
           \
        bott\m
             x
            right

Corner indices of a Cube

7------3
|\     |\
| \    | \
|  \  0|  \
4---6------2
 \  |   \  |
  \ |    \ |
   \|     \|
    5------1

Edge indices of a Cube

+--11--+
|\     |\
7 6    3 2
|  \   |  \
+--8+--10--+
 \  |   \  |
  4 5    0 1
   \|     \|
    +---9--+
*/

private immutable vec3i[8] cornerCoords = [vec3i(0, 0, 0),
                                           vec3i(1, 0, 0),
                                           vec3i(1, 1, 0),
                                           vec3i(0, 1, 0),
                                           vec3i(0, 0, 1),
                                           vec3i(1, 0, 1),
                                           vec3i(1, 1, 1),
                                           vec3i(0, 1, 1)];

// For each coordinate, give the corner id: cornerIds[x][y][z]
private enum int[2][2][2] cornerIds = [[[0, 4], [3, 7]],
                                       [[1, 5], [2, 6]]];

// For each edge, give a couple of corners ids
private enum int[2][12] intersections =
    [
        [0, 1], [1, 2], [3, 2], [0, 3], // Edge 0  1  2  3
        [4, 5], [5, 6], [7, 6], [4, 7], // Edge 4  5  6  7
        [0, 4], [1, 5], [2, 6], [3, 7]  // Edge 8  9 10 11
    ];

// For each corner sign bit, give intersected edges
private immutable ushort[256] edgeTable =
    [
        0x000, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
        0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
        0x190, 0x99 , 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
        0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
        0x230, 0x339, 0x33 , 0x13a, 0x636, 0x73f, 0x435, 0x53c,
        0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
        0x3a0, 0x2a9, 0x1a3, 0xaa , 0x7a6, 0x6af, 0x5a5, 0x4ac,
        0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
        0x460, 0x569, 0x663, 0x76a, 0x66 , 0x16f, 0x265, 0x36c,
        0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
        0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff , 0x3f5, 0x2fc,
        0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
        0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55 , 0x15c,
        0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
        0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc ,
        0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
        0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
        0xcc , 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
        0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
        0x15c, 0x55 , 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
        0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
        0x2fc, 0x3f5, 0xff , 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
        0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
        0x36c, 0x265, 0x16f, 0x66 , 0x76a, 0x663, 0x569, 0x460,
        0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
        0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa , 0x1a3, 0x2a9, 0x3a0,
        0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
        0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33 , 0x339, 0x230,
        0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
        0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99 , 0x190,
        0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
        0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x000
    ];

