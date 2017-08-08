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

module orb.render.rendersystem;

public import orb.render.renderer;
public import orb.render.window;
public import orb.utils.singleton;
public import entitysysd;

import orb.event;
import orb.gui.guielement;
import orb.utils.exception;
import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.image;


/* OpenGL renderer for now */
class RenderSystem : System, IReceiver!InputRegistrationEvent
{
    mixin Singleton;

public:
    this()()
    {
        // Load the SDL 2 library
        DerelictSDL2.load();
        scope(failure) DerelictSDL2.unload();

        //todo make those calls dependant on StrRenderer
        // Load OpenGL versions 1.0 and 1.1.
        DerelictGL3.load();
        scope(failure) DerelictGL3.unload();

        // Load the SDL2_image library
        DerelictSDL2Image.load();
        scope(failure) DerelictSDL2Image.unload();

        mGui.init();
    }

    ~this()
    {
        DerelictSDL2Image.unload();
        DerelictGL3.unload();
        DerelictSDL2.unload();

        mGui.shutdown();
    }

    static void lookupRenderers(string RndrMod, Args...)(Args args)
    {
        mRenderers = initialize!RndrMod(args);
    }

    auto createWindow(string title,
                      uint posX, uint posY,
                      uint width, uint height,
                      vec4f backgroundColor)
    {
        mWin = new Window(title, posX, posY, width, height, backgroundColor);
        return mWin;
    }

    void insert(TGui : IGuiElement)(TGui gui/*,
                      vec2f pos = vec2f(0, 0)*/)
    {
        mGui.insert(null, cast(IGuiElement)gui, vec2f(0, 0)/*pos*/);
    }

    void remove(IGuiElement gui)
    {
        mGui.remove(gui);
    }

    static auto renderer(string Rndr)() @property
    {
        import std.format : format;
        mixin(q{
            return cast(I%sRenderer)mRenderers["%s"];
        }.format(Rndr, Rndr));
    }

protected:

    override void prepare(EntityManager es, EventManager events, Duration dt)
    {
        // clear the color and depth buffers
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // checkout events to get a SDL_EXIT on the window
        // (else done by input system)
        if (!mInputEnabled)
            SDL_PumpEvents();
    }

    override void run(EntityManager es, EventManager events, Duration dt)
    {
        // todo: only one render target at the moment
        RenderTarget target = mWin;

        // render all gui elements
        foreach (guiChild; mGui[])
        {
            guiChild.element.render(guiChild.position);
        }
    }

    override void unprepare(EntityManager es, EventManager events, Duration dt)
    {
        mWin.swapBuffer();
    }

    void receive(InputRegistrationEvent event)
    {
        mInputEnabled = event.enabled;
    }

private:
    Window      mWin;    // single default window/target.
    bool        mInputEnabled;
    GuiFamily   mGui;

    static IRenderer[string] mRenderers;
}
