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


private struct Morton
{
    ulong mortonId;

    size_t toHash() const /*@safe does not like pointer slicing*/ pure nothrow @nogc
    {
        import std.digest.murmurhash;
        return *(cast(uint*)digest!(MurmurHash3!32)((&mortonId)[0..1]));
    }

    bool opEquals(ref const Morton m) const @safe pure nothrow @nogc
    {
        return mortonId == m.mortonId;
    }
}

class Terrain
{
public:
    /**
     * Define a terrain, using a shape generator and the size of the bounding
     * box.
     */
    this(int size, float planetRadius)
    {
        // Make sure size is a multiple of chunkSize
        mSize = (size + chunkSize - 1) / chunkSize;

        mPopulator = new Populator(vec3f(size/2, size/2, size/2),
                                   planetRadius);
    }

    Chunk loadChunk(vec3i p, ulong mortonId)
    {
        // Is it already loaded?
        auto loadedChunk = Morton(mortonId) in mLoadedChunks;
        if (loadedChunk !is null)
        {
            // reset timestamp (hence stop unloading)
            loadedChunk.timestamp = MonoTime.zero;

            // reset neighboring, it may have an opportunity to be complete
            if (loadedChunk.hiddenNeighbor)
            {
                loadedChunk.resetNeighbors();
                setEdgeNeighbors(*loadedChunk);
            }
            return *loadedChunk;
        }

        auto chunk = mChunkPool.alloc(p);

        setEdgeNeighbors(chunk);
        mLoadedChunks[Morton(mortonId)] = chunk;

        return chunk;
    }

    void unloadChunk(Chunk chunk)
    {
        auto check = mLoadedChunks.remove(Morton(morton(chunk.pos)));
        assert(check);
        mChunkPool.free(chunk);
    }

    void populate(Chunk chunk)
    {
        chunk.populate(mPopulator);
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

                foreach (loadedChunk; terrain.mLoadedChunks.byValue())
                {
                    ret = dg(loadedChunk);
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
        auto loadedChunk = Morton(morton(p)) in mLoadedChunks;
        return loadedChunk is null ? null : *loadedChunk;
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

    uint          mSize;  // in chunks
    Populator     mPopulator;
    Pool!Chunk    mChunkPool;
    Chunk[Morton] mLoadedChunks;
}