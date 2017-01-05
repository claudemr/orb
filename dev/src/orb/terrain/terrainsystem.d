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

module orb.terrain.terrainsystem;

public import orb.terrain.terrain;

import orb.event;
import orb.utils.benchmark;
import orb.utils.ring;
import std.container.rbtree;
import std.math;

import std.stdio;


alias BmStat = orb.utils.benchmark.Stat;
alias CktlTree = RedBlackTree!(ChunkToLoad,
                               "a.d2 < b.d2 ||"
                               "(a.d2 == b.d2 &&"
                               " a.mortonId < b.mortonId)",
                               true); // Allow duplicates


private immutable Duration defaultUnloadTimout = seconds(5);

private enum State
{
    init = 0,
    unloading,
    loading,
    done
}


private struct ChunkToLoad
{
    ulong       mortonId;   // mortonId of the chunk to load
    Vector3i    pos;        // Position of the chunk to load
    int         d2;         // Squared distance of the chunk to load
    Chunk       neighbor;   // Neighbor chunk requesting the load
    Axis        axis;       // Axis of neighboring
    Side        side;       // The chunk to load is on that side of the neighbor
}


class TerrainSystem : System, IReceiver!CameraUpdatedEvent, IReceiver!StatEvent
{
public:
    this(Terrain terrain, Camera camera)
    {
        mTerrain       = terrain;
        mUnloadTimeout = defaultUnloadTimout;
        mToLoadList    = new CktlTree;
        setMaxDistance2(camera);
        setCenterChunk(camera);
        mState = State.init;
    }

protected:
    void receive(CameraUpdatedEvent event)
    {
        auto camPos = event.camera.position();

        Vector3f delta;
        delta.x = abs(mCenterChunk.x * chunkSize + chunkSize / 2 - camPos.x);
        delta.y = abs(mCenterChunk.y * chunkSize + chunkSize / 2 - camPos.y);
        delta.z = abs(mCenterChunk.z * chunkSize + chunkSize / 2 - camPos.z);

        if (delta.x > chunkSize || delta.y > chunkSize || delta.z > chunkSize)
        {
            setCenterChunk(event.camera);
            mState = State.unloading;
        }
    }

    void receive(StatEvent event)
    {
        import std.stdio;

        writefln("Loaded chunks: %d (unload: %d)",
                 mTerrain.nbLoadedChunks, mUnloadList.length);
        writefln("  Mng stats:  %dµs(%dµs) [%d %d]",
                 mBmMng.average.total!"usecs", mBmMng.deviation.total!"usecs",
                 mBmMng.min.total!"usecs", mBmMng.max.total!"usecs");
        writefln("  Unld stats:  %dµs(%dµs) [%d %d]",
                 mBmUnld.average.total!"usecs", mBmUnld.deviation.total!"usecs",
                 mBmUnld.min.total!"usecs", mBmUnld.max.total!"usecs");
        writefln("  Pop stats:  %dµs(%dµs) [%d %d]",
                 mBmPop.average.total!"usecs", mBmPop.deviation.total!"usecs",
                 mBmPop.min.total!"usecs", mBmPop.max.total!"usecs");
        writefln("  Mesh stats: %dµs(%dµs) [%d %d]",
                 mBmMesh.average.total!"usecs", mBmMesh.deviation.total!"usecs",
                 mBmMesh.min.total!"usecs", mBmMesh.max.total!"usecs");
        mBmPop.reset();
        mBmMesh.reset();
        mBmMng.reset();
        mBmUnld.reset();
    }

    override void run(EntityManager es, EventManager events, Duration dt)
    {
        mBmMng.start();

        // Unload chunks that are beyond sight
        if (mState == State.unloading)
        {
            fillUnloadList();
            mState = State.init;
        }

        // Unload expired chunks
        checkUnloadList();

        // Load as many chunks as possible
        int nbLoadRemaining = mLoadPerFrame;

        if (mState == State.init)
        {
            manageStateInit(nbLoadRemaining);
            mState = State.loading;
        }

        manageStateLoad(nbLoadRemaining);

        if (nbLoadRemaining == 0)
            mState = State.done;

        mBmMng.stop();
    }

private:

    void setCenterChunk(Camera cam)
    {
        auto camPos = cam.position();
        mCenterChunk.x = cast(int)camPos.x / chunkSize;
        mCenterChunk.y = cast(int)camPos.y / chunkSize;
        mCenterChunk.z = cast(int)camPos.z / chunkSize;
    }

    void setMaxDistance2(Camera cam)
    {
        float d = cam.far() / cos(cam.fov());
        if (cam.ratio() > 1)
            d *= cam.ratio();
        assert(d >= 1.0);
        // Square the distance to avoid sqrt()
        mMaxDistance2 = cast(int)ceil(d / chunkSize);
        mMaxDistance2 *= mMaxDistance2;
    }

    Chunk loadChunk(Vector3i p, ulong mortonId, ref int nbLoadRemaining)
    out (chunk)
    {
        assert(chunk !is null);
    }
    body
    {
        auto chunk = mTerrain.loadChunk(p, mortonId);
        if (!chunk.populated)
        {
            nbLoadRemaining--;
            mBmPop.start();
            mTerrain.populate(chunk);
            mBmPop.stop();

            // Management benchmark should not take populating into account
            mBmMng -= mBmPop;
        }

        return chunk;
    }

    void buildMesh(Chunk chunk)
    {
        if (chunk.empty)
            return;
        if (chunk.mesh !is null)
            return;
        mBmMesh.start();
        mTerrain.buildMesh(chunk);
        mBmMesh.stop();

        // Management benchmark should not take meshing into account
        mBmMng -= mBmMesh;
    }

    void fillUnloadList()
    {
        mBmUnld.start();

        if (mUnloadList.length + 256 > mUnloadList.capacity)
            mUnloadList.reserve(mUnloadList.capacity + 512);

        // Check loaded chunks are still visible
        foreach (chunk; mTerrain[])
        {
            if (chunk.unloading || chunk.timestamp != MonoTime.zero)
                continue;
            auto d2 = distancesqr(chunk.pos, mCenterChunk);
            if (d2 >= mMaxDistance2)
            {
                chunk.unloading = true;
                chunk.timestamp = mBmMng.timestamp;
                mUnloadList.insertBack(chunk);
            }
        }

        // Clear previous chunks to load
        mToLoadList.clear();

        mBmUnld.stop();
        // Management benchmark should not take unloading into account
        mBmMng -= mBmUnld;
    }

    void checkUnloadList()
    {
        // Check if it is time to unload any chunks
        while (!mUnloadList.empty)
        {
            auto chunk = mUnloadList.front;

            // If timestamp is reset, that chunk must not be removed anymore
            if (chunk.timestamp == MonoTime.zero)
            {
                mUnloadList.removeFront();
                chunk.unloading = false;
                continue;
            }

            // Timeout has elapsed, unload the chunk
            if (chunk.timestamp + mUnloadTimeout <= mBmMng.timestamp)
            {
                mUnloadList.removeFront();
                chunk.unloading = false;
                mTerrain.unloadChunk(chunk);
            }
            else
                break;
        }
    }

    void manageStateInit(ref int nbLoadRemaining)
    {
        // Load initial chunks in case we start from scratch
        auto chunk = loadChunk(mCenterChunk, morton(mCenterChunk),
                               nbLoadRemaining);

//writefln("Init loaded: %s", mCenterChunk.toString);

        foreach (axis, side; mCenterChunk.neighbors)
        {
            auto pos = getNeighbor(mCenterChunk, axis, side);
            if (!mTerrain.isInside(pos))
                continue;

            // The side is full and totally covers the neighbor
            if (chunk.fullSide[axis][side])
            {
                // Pretend it is loaded (so do not link)
                chunk.hiddenNeighbor = true;
                chunk.loadedNgb.setNgbId(axis, side);
                if (chunk.loadedNgb.areAllNgbLoaded)
                    buildMesh(chunk);
                continue;
            }

//writefln("Init to-load: %s", pos.toString);
            mToLoadList.insert(ChunkToLoad(morton(pos), pos,
                                           1, chunk, axis, side));
        }
    }

    void manageStateLoad(ref int nbLoadRemaining)
    {
        // Browse through the toLoadlist
        while (nbLoadRemaining > 0 && !mToLoadList.empty)
        {
            auto cktl = mToLoadList.front;
            auto pos  = cktl.pos;

            auto chunk = loadChunk(pos, cktl.mortonId, nbLoadRemaining);

            void processNeighbor(ref ChunkToLoad c)
            in
            {
                assert(c.neighbor !is null);
            }
            body
            {
                // Link chunk to its neighbor
                c.neighbor.link(c.axis, c.side, chunk);
                // The neighbor is likely to be ready to be meshed
                if (c.neighbor.loadedNgb.areAllNgbLoaded)
                    buildMesh(c.neighbor);
                // Check neighbor id's of current chunk
                // And try to build mesh in case it could be at a corner of the
                // terrain.
                if (chunk.loadedNgb.areAllNgbLoaded)
                    buildMesh(chunk);

                mToLoadList.removeFront();
            }

            // Neighbor linking
            processNeighbor(cktl);

            if (!mToLoadList.empty)
            {
                auto nextCktl = mToLoadList.front;
                if (nextCktl.pos == pos)
                {
                    processNeighbor(nextCktl);

                    if (!mToLoadList.empty)
                    {
                        nextCktl = mToLoadList.front;
                        if (nextCktl.pos == pos)
                            processNeighbor(nextCktl);
                    }
                }
            }

            // Loop to insert neighbors in to-load list
            foreach (axis, side, isNearest3; pos.neighbors(mCenterChunk))
            {
                // Nearest neighbors from the center
                if (isNearest3)
                {
                    // The nearest neighbor may not be set if it is hidden
                    if (!chunk.loadedNgb.isNgbIdSet(axis, side))
                    {
                        chunk.hiddenNeighbor = true;
                        chunk.loadedNgb.setNgbId(axis, side);
                        if (chunk.loadedNgb.areAllNgbLoaded)
                            buildMesh(chunk);
                    }
                    continue;
                }

                // Process chunks further from center
                auto ngbPos = getNeighbor(pos, axis, side);

                // Do not process if it's outisde the terrain boundaries
                if (!mTerrain.isInside(ngbPos))
                    continue;

                // Do not process if it's out of sight range
                auto d2 = distancesqr(mCenterChunk, ngbPos);
                if (d2 >= mMaxDistance2)
                    continue;

                // The side is full and totally covers the neighbor
                if (chunk.fullSide[axis][side])
                {
                    // Pretend it is loaded (so do not link)
                    chunk.hiddenNeighbor = true;
                    chunk.loadedNgb.setNgbId(axis, side);
                    if (chunk.loadedNgb.areAllNgbLoaded)
                        buildMesh(chunk);
                    continue;
                }

                // Put it into the list of chunks to load
                mToLoadList.insert(ChunkToLoad(morton(ngbPos), ngbPos,
                                               d2, chunk, axis, side));
            }
        }
    }


    immutable int mLoadPerFrame = 4;
    Terrain  mTerrain;
    State    mState;
    Vector3i mCenterChunk;
    int      mMaxDistance2;
    Duration mUnloadTimeout;

    CktlTree   mToLoadList;
    Ring!Chunk mUnloadList;

    // benchmark
    Benchmark!(BmStat.all) mBmPop;
    Benchmark!(BmStat.all) mBmMesh;
    Benchmark!(BmStat.all) mBmMng;
    Benchmark!(BmStat.all) mBmUnld;
}
