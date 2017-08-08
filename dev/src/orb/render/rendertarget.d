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

module orb.render.rendertarget;

public import orb.gui.canvas;
public import orb.render.viewport;

/**
 * The render-target is a frame-buffer of some sort receiving the 2-D rendering.
 * It may be a window or a texture.
 */
abstract class RenderTarget
{
public:
    this(string title, uint width, uint height, vec4f backgroundColor)
    {
        mTitle  = title;
        mWidth  = width;
        mHeight = height;
        mBackgroundColor = backgroundColor;
    }

    @property @nogc nothrow uint width()
    {
        return mWidth;
    }

    @property @nogc nothrow uint height()
    {
        return mHeight;
    }

    // todo we may have to be able to attach several viewports if we want to
    // handle HUD.
    void attach(Viewport viewport)
    {
        mViewport = viewport;
    }

    void attach(Canvas canvas)
    {
        mCanvas = canvas;
    }

    void update()
    {
        // xxx Circular dependency, maybe rendertarget should be on its own,
        //     and canvas and viewport should depend on it.
        //     This has to be worked out when implementing FBO's.

        // todo fill background
        if (mViewport !is null)
            mViewport.render();
        //todo probably clear depth frame
        if (mCanvas !is null)
            mCanvas.render();
    }

private:
    string      mTitle;
    uint        mWidth;
    uint        mHeight;
    vec4f       mBackgroundColor;
    Viewport    mViewport;
    Canvas      mCanvas;
}

