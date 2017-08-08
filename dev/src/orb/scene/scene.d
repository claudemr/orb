/* ORB - 3D/physics/AI engine
   Copyright (C) 2015-2017 Claude

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

public import orb.scene.camera;
public import orb.scene.light;
public import orb.terrain.terrain;

import orb.component;
import orb.event;
import gfm.math.matrix;
import gfm.math.vector;

class Scene : IReceiver!SpawnEvent
{
public:
    this(EntityManager em)
    {
        mEm = em;
    }

    auto createCamera()
    {
        mCamera = new Camera;
        return mCamera;
    }

    auto createTerrain(Args...)(Args args)
    {
        assert(mTerrain is null);
        mTerrain = new Terrain(args);
        return mTerrain;
    }

    auto createDirLight(vec4f direction, vec4f color)
    {
        mDirLight = new DirLight(direction, color);
        return mDirLight;
    }

    auto dirLight() @property
    {
        return mDirLight;
    }

    auto terrain() @property
    {
        return mTerrain;
    }

    auto entities() @property
    {
        return mEm;
    }

protected:
    void receive(SpawnEvent event)
    {
        auto ett = mEm.create();
        ett.register!Position(event.position);
        ett.register!Velocity(true, event.velocity);
        ett.register!Mass(2.0); //2 kg
        ett.register!Collidable(event.position);
    }

private:
    EntityManager   mEm;
    Camera          mCamera;    //todo use array of cameras
    DirLight        mDirLight;  //todo use array of dirlight
    Terrain         mTerrain;
}
