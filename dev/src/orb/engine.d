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

module orb.engine;

public import orb.event;
public import orb.input.inputsystem;
public import orb.render.rendersystem;
public import orb.scene.scene;
public import orb.utils.singleton;

import std.string;
import entitysysd;


class Engine : EntitySysD
{
    mixin Singleton;

public:

    void initSingleton()
    {
        // not available with ldc (compiles but does not link)
        version (DigitalMars)
        {
            // Stack trace on linux for "segmentation fault"
            import etc.linux.memoryerror;
            static if (is(typeof(registerMemoryErrorHandler)))
                registerMemoryErrorHandler();
        }
    }

    auto createRenderSystem()
    {
        mRenderSystem = new RenderSystem();
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

    auto createScene()
    {
        mScene = new Scene(this);
        return mScene;
    }

    void run()
    {
        // prepare, run and unprepare the systems of the CES engine
        systems.runFull(dur!"usecs"(16667));
    }

private:
    RenderSystem  mRenderSystem;
    InputSystem   mInputSystem;
    Scene         mScene;
}
