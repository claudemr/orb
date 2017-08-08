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

module orb.engine;

public import orb.event;
public import orb.input.inputsystem;
public import orb.render.rendersystem;
public import orb.terrain.terrainmanager;
public import orb.utils.singleton;

import orb.physics.collisionsystem;
import orb.physics.physicssystem;
import entitysysd;
import std.string;


class Engine : EntitySysD
{
    mixin Singleton;

public:

    void initSingleton()
    {
        // Not available with ldc (compiles but does not link)
        version (DigitalMars)
        {
            // Stack trace on linux for "segmentation fault"
            import etc.linux.memoryerror;
            static if (is(typeof(registerMemoryErrorHandler)))
                registerMemoryErrorHandler();
        }

        import orb.utils.logger;
        import std.stdio : stderr;
        sharedLog = new FileExtLogger(stderr);

        // Register systems
        mPhysicsSystem = new PhysicsSystem;
        systems.register(mPhysicsSystem, Order.first);
        mCollisionSystem = new CollisionSystem;
        systems.register(mCollisionSystem);
        mTerrainManager = new TerrainManager;
        systems.register(mTerrainManager);
    }

    auto createRenderSystem()
    {
        mRenderSystem = new RenderSystem;
        systems.register(mRenderSystem);
        return mRenderSystem;
    }

    auto createInputSystem(Window win)
    {
        mInputSystem = new InputSystem(win);
        systems.register(mInputSystem);
        events.emit!InputRegistrationEvent(true);
        return mInputSystem;
    }

    Scene createScene()
    {
        mScene = new Scene(entities);
        events.subscribe!SpawnEvent(mScene);
        mPhysicsSystem.scene   = mScene;
        mCollisionSystem.scene = mScene;
        return mScene;
    }

    void activate(Camera camera)
    {
        //todo we should get the scene from the camera, if we happen to have
        // multiple scenes
        mTerrainManager.set(mScene.terrain, camera);
    }


    void run()
    {
        // prepare, run and unprepare the systems of the CES engine
        //todo timestamp is weird, use proper one
        systems.runFull(dur!"usecs"(16667));
        // http://gameprogrammingpatterns.com/game-loop.html
        // http://entropyinteractive.com/2011/02/game-engine-design-the-game-loop/
    }

private:
    InputSystem     mInputSystem;
    PhysicsSystem   mPhysicsSystem;
    CollisionSystem mCollisionSystem;
    TerrainManager  mTerrainManager;
    RenderSystem    mRenderSystem;
    Scene           mScene;
}
