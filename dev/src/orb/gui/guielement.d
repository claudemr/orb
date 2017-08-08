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

module orb.gui.guielement;

public import gfm.math.vector;


interface IGuiElement
{
    // properties
    vec2f position()  @property const;
    vec2f size()      @property const;
    int   order()     @property const;

    // methods
    void     render();
}


class GuiElement : IGuiElement
{
public:
    vec2f position()  @property const
    {
        return mPosition;
    }

    vec2f size()  @property const
    {
        return mSize;
    }

    int order() @property const
    {
        return mOrder;
    }

    void render()
    {
    }

protected:
    vec2f mPosition, mSize;
    int   mOrder;
}