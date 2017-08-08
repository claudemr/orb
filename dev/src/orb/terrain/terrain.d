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

module orb.terrain.terrain;

public import orb.terrain.chunk;

import orb.utils.pool;
import orb.utils.ring;
import std.algorithm.comparison;
import std.algorithm.searching;
import std.container.rbtree;
import std.datetime;
import core.time;


private struct LoadedChunk
{
    ulong mortonId;
    Chunk chunk;
}

class Terrain
{
public:
    /**
     * Define a terrain, using a shape generator and the size of the bounding
     * box.
     */
    this(Generator gen, int size)
    {
        // Make sure size is a multiple of chunkSize
        mSize = (size + chunkSize - 1) >> chunkBitSize;

        mGen = gen;

        // Create chunk list
        mLoadedChunks = new RedBlackTree!(LoadedChunk,
                                          "a.mortonId < b.mortonId");
    }

    Chunk loadChunk(vec3i p, ulong mortonId)
    {
        auto loadedChunk = LoadedChunk(mortonId, null);

        // Is it already loaded?
        auto r = mLoadedChunks.equalRange(loadedChunk);
        if (!r.empty)
        {
            auto chunk = r.front.chunk;
            // reset timestamp (hence stop unloading)
            chunk.timestamp = MonoTime.zero;

            // reset neighboring, it may have an opportunity to be complete
            if (chunk.hiddenNeighbor)
            {
                chunk.resetNeighbors();
                setEdgeNeighbors(chunk);
            }
            return chunk;
        }

        auto chunk = mChunkPool.alloc(p);

        setEdgeNeighbors(chunk);
        loadedChunk.chunk = chunk;
        mLoadedChunks.insert(loadedChunk);

        return chunk;
    }

    void unloadChunk(Chunk chunk)
    {
        auto loadedChunk = LoadedChunk(morton(chunk.pos), null);
        auto n = mLoadedChunks.removeKey(loadedChunk);
        assert(n == 1);
        mChunkPool.free(chunk);
    }

    void populate(Chunk chunk)
    {
        chunk.populate(mGen);
    }

    /// Traversal of the chunks of the terrain
    auto opSlice()
    {
        struct Iterator
        {
            Terrain terrain;

            int opApply(int delegate(Chunk chunk) dg)
            {
                int ret = 0;

                foreach (loadedChunk; terrain.mLoadedChunks[])
                {
                    ret = dg(loadedChunk.chunk);
                    if (ret)
                        break;
                }

                return ret;
            }
        }

        return Iterator(this);
    }

    Chunk find(vec3i p)
    {
        auto loadedChunk = LoadedChunk(morton(p), null);
        auto r = mLoadedChunks.equalRange(loadedChunk);
        return r.empty ? null : r.front.chunk;
    }

    void buildMesh(Chunk chunk)
    in
    {
        assert(chunk.loadedNgb.areAllNgbLoaded);
    }
    body
    {
        Face getNeighborFace(Chunk chunk, Axis a, Side s)
        {
            auto ngbChunk = chunk.neighbors[a][s];
            // If it's not loaded, pretend the chunk is full
            // (to avoid having to create unseen quads)
            if (ngbChunk is null)
                return (x, y) => true;

            return ngbChunk.face(a, s == Side.front ? Side.back : Side.front);
        }

        chunk.buildMesh(getNeighborFace(chunk, Axis.x, Side.back),
                        getNeighborFace(chunk, Axis.x, Side.front),
                        getNeighborFace(chunk, Axis.y, Side.back),
                        getNeighborFace(chunk, Axis.y, Side.front),
                        getNeighborFace(chunk, Axis.z, Side.back),
                        getNeighborFace(chunk, Axis.z, Side.front));
    }

    bool isInside(vec3i p) const
    {
        if (p.x >= mSize || p.y >= mSize || p.z >= mSize)
            return false;
        if (p.x < 0 || p.y < 0 || p.z < 0)
            return false;
        return true;
    }

    uint size() @property const
    {
        return mSize;
    }

    uint nbLoadedChunks() @property const
    {
        return cast(uint)mLoadedChunks.length;
    }

private:
    void setEdgeNeighbors(Chunk chunk)
    {
        auto p = chunk.pos;

        // Pretend chunks on borders have loaded neighbors
        if (p.x == 0)
            chunk.loadedNgb.setNgbId(Axis.x, Side.back);
        else if (p.x == mSize - 1)
            chunk.loadedNgb.setNgbId(Axis.x, Side.front);
        if (p.y == 0)
            chunk.loadedNgb.setNgbId(Axis.y, Side.back);
        else if (p.y == mSize - 1)
            chunk.loadedNgb.setNgbId(Axis.y, Side.front);
        if (p.z == 0)
            chunk.loadedNgb.setNgbId(Axis.z, Side.back);
        else if (p.z == mSize - 1)
            chunk.loadedNgb.setNgbId(Axis.z, Side.front);
    }

    uint                                     mSize;  // in chunks
    Generator                                mGen;
    Pool!Chunk                               mChunkPool;
    RedBlackTree!(LoadedChunk,
                  "a.mortonId < b.mortonId") mLoadedChunks;
}