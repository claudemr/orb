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

module orb.render.window;

public import orb.render.rendertarget;

import orb.utils.exception;
import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.typecons;


private extern(C) /*@nogc*/ nothrow
int handleEvent(void* userdata,
                SDL_Event* event)
{
    Window win = cast(Window)userdata;

    if (event.type == SDL_QUIT)
        win.mStopping = true;

    return 1;
}

/**
 * Only one rendering context, one window, one implementation based on SDL
 * and OpenGL
 */
class Window : RenderTarget
{
public:
    this(string title, uint windowPosX, uint windowPosY,
         uint windowWidth, uint windowHeight, vec4f backgroundColor)
    {
        super(title, windowWidth, windowHeight, backgroundColor);

        auto ret = SDL_Init(SDL_INIT_EVERYTHING); //SDL_INIT_VIDEO
        scope(failure) SDL_Quit();
        enforceSdl(ret == 0, "SDL init failed");

        import std.string;  // for toStringz()
        mpWindow = SDL_CreateWindow(title.toStringz,
                                    windowPosX, windowPosY,
                                    windowWidth, windowHeight,
                                    SDL_WINDOW_OPENGL |
                                    /*SDL_WINDOW_RESIZABLE |*/
                                    SDL_WINDOW_SHOWN);
        scope(failure) SDL_DestroyWindow(mpWindow);
        enforceSdl(mpWindow !is null, "Window creation failed");

        mGlContext = SDL_GL_CreateContext(mpWindow);
        scope(failure) SDL_GL_DeleteContext(mGlContext);
        enforceSdl(mGlContext !is null, "Context creation failed");

        // Vertical-synchronization (todo disabled by default)
        mVsync = true;
        setSwapInterval_TryLateSwapTearing(Yes.vsync);

        import std.experimental.logger;
        infof("Detected OpenGL:\n" ~
              "* Version: %s\n" ~
              "* Vendor: %s\n" ~
              "* Renderer: %s\n" ~
              "* GLSL version: %s\n",
              glGetString(GL_VERSION).fromStringz,
              glGetString(GL_VENDOR).fromStringz,
              glGetString(GL_RENDERER).fromStringz,
              glGetString(GL_SHADING_LANGUAGE_VERSION).fromStringz);

        /* Load versions 1.2+ and all supported ARB and EXT extensions.
           Load 3.0 version, for vertex and fragment shaders.
           Upper version might not be fully supported by all
           graphic cards (AMD Radeon HD 5800 series for instance) */
        mGlVersion = DerelictGL3.reload(GLVersion.GL30, GLVersion.GL30);
        infof("Loaded OpenGL version: %d\n", mGlVersion);

        //Initialize PNG loading
        int imgFlags = IMG_INIT_PNG;
        imgFlags = IMG_Init(imgFlags);
        scope(failure) IMG_Quit();
        enforceSdl(imgFlags & IMG_INIT_PNG, "IMG_Init failed");

        GLint maxTexComUnits, maxTexUnits, maxTexSize;
        glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &maxTexComUnits);
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxTexUnits);
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTexSize);
        enforceGl();
        infof("Texture max units: %d/%d, max size: %d\n",
              maxTexComUnits, maxTexUnits, maxTexSize);

        glClearColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, 0);
        //glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
        glEnable(GL_DEPTH_TEST);
        glEnable(GL_CULL_FACE);
        glCullFace(GL_BACK);
        glFrontFace(GL_CCW);

        //glPointSize(5.0f);

        // Accept fragment if it closer to the camera than the former one
        glDepthFunc(GL_LESS);

        SDL_AddEventWatch(&handleEvent, cast(void*)this);
        //SDL_SetEventFilter(&handleEvent, cast(void*)this);
    }

    ~this()
    {
        IMG_Quit();
        SDL_GL_DeleteContext(mGlContext);
        SDL_DestroyWindow(mpWindow);
        SDL_Quit();
    }

    bool stopping() @property
    {
        return mStopping;
    }

    bool vsync() @property
    {
        return mVsync;
    }

    void vsync(bool flag) @property
    {
        mVsync = flag;
        setSwapInterval_TryLateSwapTearing(cast(Flag!"vsync")flag);
    }

    void swapBuffer()
    {
        SDL_GL_SwapWindow(mpWindow);
    }

private:

    void setSwapInterval_TryLateSwapTearing(Flag!"vsync" flag)
    {
        if (flag == Yes.vsync)
        {
            // try to enable late swap tearing if possible
            auto ret = SDL_GL_SetSwapInterval(-1);
            if (ret < 0)
                SDL_GL_SetSwapInterval(1);
        }
        else
            SDL_GL_SetSwapInterval(0);
    }

    SDL_Window*     mpWindow;
    SDL_GLContext   mGlContext;
    GLVersion       mGlVersion;
    bool            mStopping;
    bool            mVsync;
}
