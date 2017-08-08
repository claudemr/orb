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

module orb.render.rendertarget;

public import orb.gui.canvas;
public import orb.render.viewport;

/**
 * The render-target is a frame-buffer of some sort receiving the 2-D rendering.
 * It may be a window or a texture.
 */
//todo it is not used much currently, we have to find a purose, maybe when we
// will be using FBO's?
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

private:
    string      mTitle;
    uint        mWidth;
    uint        mHeight;
    vec4f       mBackgroundColor;
}

