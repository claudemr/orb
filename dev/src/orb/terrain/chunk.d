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

public import orb.terrain.generator;
public import orb.utils.geometry;

import orb.render.rendersystem;


/*
For a movement, the player/entity might move from a chunk to its 26
neighbors (in diagonal also).
So, at 30fps, an entity may have a maximum speed of 16voxels per 33.3ms, so
480vx/s so 1728kvx/h, which is more than enough. Anything else should be
considered as teleportation.
*/
enum uint chunkBitSize = 4;
enum uint chunkSize    = 1 << chunkBitSize;
alias Voxel = bool;

alias Face = Voxel delegate(int, int);


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
        return mVoxels[x + (y << chunkBitSize) + (z << (chunkBitSize * 2))];
    }

    Voxel opIndexAssign(Voxel v, int x, int y, int z)
    {
        mVoxels[x + (y << chunkBitSize) + (z << (chunkBitSize * 2))] = v;
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

    void populate(Generator gen)
    {
        vec3i coord = pos * chunkSize;

        foreach (int z; 0 .. chunkSize)
            foreach (int y; 0 .. chunkSize)
                foreach (int x; 0 .. chunkSize)
                {
                    auto v = gen[coord.x + x, coord.y + y, coord.z + z];
                    if (v)
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
                    opIndexAssign(v, x, y, z);
                }
    }

    void buildMesh(Face nxb, Face nxf, Face nyb, Face nyf, Face nzb, Face nzf)
    {
        void buildVoxel(vec3i p)
        {
            struct Neighbors
            {
                struct Axis
                {
                    bool b, f;
                }
                Axis x, y, z;
            }

            Neighbors neighbors;

            if (p.x > 0)
                neighbors.x.b = opIndex(p.x - 1, p.y, p.z);
            else if (nxb !is null)
                neighbors.x.b = nxb(p.y, p.z);
            if (p.x < chunkSize - 1)
                neighbors.x.f = opIndex(p.x + 1, p.y, p.z);
            else if (nxf !is null)
                neighbors.x.f = nxf(p.y, p.z);
            if (p.y > 0)
                neighbors.y.b = opIndex(p.x, p.y - 1, p.z);
            else if (nyb !is null)
                neighbors.y.b = nyb(p.x, p.z);
            if (p.y < chunkSize - 1)
                neighbors.y.f = opIndex(p.x, p.y + 1, p.z);
            else if (nyf !is null)
                neighbors.y.f = nyf(p.x, p.z);
            if (p.z > 0)
                neighbors.z.b = opIndex(p.x, p.y, p.z - 1);
            else if (nzb !is null)
                neighbors.z.b = nzb(p.x, p.y);
            if (p.z < chunkSize - 1)
                neighbors.z.f = opIndex(p.x, p.y, p.z + 1);
            else if (nzf !is null)
                neighbors.z.f = nzf(p.x, p.y);

            string ptCoord(int a)
            {
                auto s = "mPoints.length++;";
                switch (a)
                {
                case 0:
                    s ~= "mPoints[$-1] = vec3f(0.0f + p.x, 0.0f + p.y, 0.0f + p.z);";
                    break;
                case 1:
                    s ~= "mPoints[$-1] = vec3f(1.0f + p.x, 0.0f + p.y, 0.0f + p.z);";
                    break;
                case 2:
                    s ~= "mPoints[$-1] = vec3f(1.0f + p.x, 1.0f + p.y, 0.0f + p.z);";
                    break;
                case 3:
                    s ~= "mPoints[$-1] = vec3f(0.0f + p.x, 1.0f + p.y, 0.0f + p.z);";
                    break;
                case 4:
                    s ~= "mPoints[$-1] = vec3f(0.0f + p.x, 0.0f + p.y, 1.0f + p.z);";
                    break;
                case 5:
                    s ~= "mPoints[$-1] = vec3f(1.0f + p.x, 0.0f + p.y, 1.0f + p.z);";
                    break;
                case 6:
                    s ~= "mPoints[$-1] = vec3f(1.0f + p.x, 1.0f + p.y, 1.0f + p.z);";
                    break;
                case 7:
                    s ~= "mPoints[$-1] = vec3f(0.0f + p.x, 1.0f + p.y, 1.0f + p.z);";
                    break;
                default:
                    assert(false);
                }
                return s;
            }

            string nmCoord(int a)
            {
                auto s = "mNormals.length++;";
                switch (a)
                {
                case 0: // 0 1 2 3
                    s ~= "mNormals[$-1] = vec3f(0.0f, 0.0f, -1.0f);";
                    break;
                case 1: // 4 5 6 7
                    s ~= "mNormals[$-1] = vec3f(0.0f, 0.0f, 1.0f);";
                    break;
                case 2: // 0 3 7 4
                    s ~= "mNormals[$-1] = vec3f(-1.0f, 0.0f, 0.0f);";
                    break;
                case 3: // 1 2 6 5
                    s ~= "mNormals[$-1] = vec3f(1.0f, 0.0f, 0.0f);";
                    break;
                case 4: // 0 1 5 4
                    s ~= "mNormals[$-1] = vec3f(0.0f, -1.0f, 0.0f);";
                    break;
                case 5: // 2 3 7 6
                    s ~= "mNormals[$-1] = vec3f(0.0f, 1.0f, 0.0f);";
                    break;
                default:
                    assert(false);
                }
                return s;
            }

            int nbFace = 0;

            // clockwise
            if (!neighbors.z.b)
            {
                mixin(ptCoord(0)); mixin(ptCoord(2)); mixin(ptCoord(1));
                mixin(ptCoord(0)); mixin(ptCoord(3)); mixin(ptCoord(2));
                mixin(nmCoord(0)); mixin(nmCoord(0)); mixin(nmCoord(0));
                mixin(nmCoord(0)); mixin(nmCoord(0)); mixin(nmCoord(0));
                nbFace++;
            }

            if (!neighbors.z.f)
            {
                mixin(ptCoord(7)); mixin(ptCoord(5)); mixin(ptCoord(6));
                mixin(ptCoord(7)); mixin(ptCoord(4)); mixin(ptCoord(5));
                mixin(nmCoord(1)); mixin(nmCoord(1)); mixin(nmCoord(1));
                mixin(nmCoord(1)); mixin(nmCoord(1)); mixin(nmCoord(1));
                nbFace++;
            }

            if (!neighbors.x.b)
            {
                mixin(ptCoord(0)); mixin(ptCoord(7)); mixin(ptCoord(3));
                mixin(ptCoord(0)); mixin(ptCoord(4)); mixin(ptCoord(7));
                mixin(nmCoord(2)); mixin(nmCoord(2)); mixin(nmCoord(2));
                mixin(nmCoord(2)); mixin(nmCoord(2)); mixin(nmCoord(2));
                nbFace++;
            }

            if (!neighbors.x.f)
            {
                mixin(ptCoord(1)); mixin(ptCoord(6)); mixin(ptCoord(5));
                mixin(ptCoord(1)); mixin(ptCoord(2)); mixin(ptCoord(6));
                mixin(nmCoord(3)); mixin(nmCoord(3)); mixin(nmCoord(3));
                mixin(nmCoord(3)); mixin(nmCoord(3)); mixin(nmCoord(3));
                nbFace++;
            }

            if (!neighbors.y.b)
            {
                mixin(ptCoord(0)); mixin(ptCoord(5)); mixin(ptCoord(4));
                mixin(ptCoord(0)); mixin(ptCoord(1)); mixin(ptCoord(5));
                mixin(nmCoord(4)); mixin(nmCoord(4)); mixin(nmCoord(4));
                mixin(nmCoord(4)); mixin(nmCoord(4)); mixin(nmCoord(4));
                nbFace++;
            }

            if (!neighbors.y.f)
            {
                mixin(ptCoord(7)); mixin(ptCoord(2)); mixin(ptCoord(3));
                mixin(ptCoord(7)); mixin(ptCoord(6)); mixin(ptCoord(2));
                mixin(nmCoord(5)); mixin(nmCoord(5)); mixin(nmCoord(5));
                mixin(nmCoord(5)); mixin(nmCoord(5)); mixin(nmCoord(5));
                nbFace++;
            }

            if (nbFace == 0)
                return;
            mNbFace += nbFace;

            import std.range : iota;
            import std.array : array;
            // n faces of 2 triangles of 3 vertices
            mIndices ~= iota!uint(cast(uint)mPoints.length - 3 * 2 * nbFace,
                                  cast(uint)mPoints.length)
                        .array;
        }

        mNbFace = 0;

        // very naive way of building mesh
        for (uint x = 0; x < chunkSize; x++)
            for (uint y = 0; y < chunkSize; y++)
                for (uint z = 0; z < chunkSize; z++)
                {
                    auto v = opIndex(x, y, z);
                    if (!v)
                        continue;
                    buildVoxel(vec3i(x, y, z));
                }

        if (mNbFace == 0)
            return;

        mMesh = RenderSystem.renderer!IMesh.createMesh(mPoints,
                                                       mNormals,
                                                       mIndices);
        /*import std.stdio;
        writeln(mNbFace);*/
    }

    Face face(Axis axis, Side side)
    {
        if (mFullSide[axis][side])
            return (x, y) => true;

        switch (axis)
        {
        case Axis.x:
            if (side == side.back)
                return (x, y) => opIndex(0, x, y);
            else
                return (x, y) => opIndex(chunkSize - 1, x, y);
        case Axis.y:
            if (side == side.back)
                return (x, y) => opIndex(x, 0, y);
            else
                return (x, y) => opIndex(x, chunkSize - 1, y);
        case Axis.z:
            if (side == side.back)
                return (x, y) => opIndex(x, y, 0);
            else
                return (x, y) => opIndex(x, y, chunkSize - 1);
        default:
            assert(false);
        }
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
    bool                                        mEmpty;
    bool                                        mFull;
    Voxel[chunkSize * chunkSize * chunkSize]    mVoxels;
    bool[2][3]                                  mFullSide;
    vec3f[]                                     mPoints;
    vec3f[]                                     mNormals;
    uint[]                                      mIndices;
    IMesh                                       mMesh;
    uint                                        mNbFace;
}


