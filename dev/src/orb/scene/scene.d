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

module orb.scene.scene;

public import orb.render.mesh;
public import orb.scene.camera;
public import orb.scene.light;
public import orb.terrain.terrainsystem;
public import entitysysd;

import orb.event;
import dlib.math.matrix;
import dlib.math.vector;


private Vector3f clamp(Vector3f newPos, Vector3f oldPos, uint size)
{
    import std.format;

    template clampCoord(string a, string comp, string lim)
    {
        enum string clampCoord = format("if (newPos.%s %s %s) newPos.%s = %s;",
                                        a, comp, lim, a, lim);
    }

    mixin (clampCoord!("x", "<", "0.5"));
    mixin (clampCoord!("y", "<", "0.5"));
    mixin (clampCoord!("z", "<", "0.5"));
    mixin (clampCoord!("x", ">", "size - 0.5"));
    mixin (clampCoord!("y", ">", "size - 0.5"));
    mixin (clampCoord!("z", ">", "size - 0.5"));

    return newPos;
}


class Node
{
public:
    this(Node parent, Entity entity)
    {
        mParent = parent;
        mEntity = entity;
    }

    Node addChild(Entity entity)
    {
        auto child = new Node(this, entity);
        mChilds ~= child;
        return child;
    }

private:
    Node    mParent;
    Node[]  mChilds;
    Entity  mEntity;
}


@component struct MeshComponent
{
    IMesh    mesh;
}


class Scene : IReceiver!MovementEvent
{
public:
    this(EntitySysD ecs)
    {
        mEcs = ecs;
        ecs.events.subscribe!MovementEvent(this);
    }

    auto createCamera()
    {
        mCameras.length++;
        mCameras[$ - 1] = new Camera;
        return mCameras[$ - 1];
    }

    auto createEntity()
    {
        Entity entity;
        entity = mEcs.entities.create();
        return entity;
    }

    /**
     * Create a directional light.
     * The direction is used for rendering.
     */
    auto createDirLight(Vector4f direction, Color4f color)
    {
        mDirLights.length++;
        mDirLights[$ - 1] = new DirLight(direction, color);
        return mDirLights[$ - 1];
    }

    void receive(MovementEvent event)
    {
        //todo use the active camera, it's a hack
        auto cam = mCameras[0];
        auto move   = event.movement;
        auto orient = event.orientation;
        cam.orientate(orient.x, orient.y, orient.z);
        auto oldPos = cam.position();
        cam.move(move.x, move.y, move.z);
        cam.position = clamp(cam.position(), oldPos, mTerrain.size * chunkSize);
        if (cam.position() != oldPos)
            mEcs.events.emit!CameraUpdatedEvent(cam);
    }

    auto dirLights() @property
    {
        return mDirLights;
    }

    Node rootNode() @property @safe pure
    {
        return mRootNode;
    }

    auto terrain() @property
    {
        return mTerrain;
    }

    void terrain(Terrain terrain) @property
    {
        if (mTerrain !is null)
            return;
        mTerrain = terrain;
        //todo use the active camera, it's a hack
        mEcs.systems.register(new TerrainSystem(terrain, mCameras[0]),
                              Order.first);
    }

private:
    Camera[]    mCameras;
    DirLight[]  mDirLights;

    EntitySysD  mEcs;
    Node        mRootNode;
    Terrain     mTerrain;
}
