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

module orb.gui.guielement;

public import gfm.math.vector;

interface IGuiElement
{
    // properties
    vec2f              size()   @property const;

    inout(IGuiElement) parent() @property inout;
    void               parent(IGuiElement) @property;

    // methods
    void  render(vec2f pos);
}


abstract class GuiElement : IGuiElement
{
public:
    vec2f size()  @property const
    {
        return mSize;
    }

    inout(IGuiElement) parent() @property inout
    {
        return mParent;
    }

    void parent(IGuiElement p) @property
    {
        mParent = p;
    }

protected:
    IGuiElement mParent;
    vec2f       mSize;
}

struct GuiChild
{
    vec2f       position;
    IGuiElement element;
}


struct GuiFamily
{
    import std.container.dlist;
public:
    void init()
    {
        //mGuiChilds = DList!GuiChild;
    }

    void insert(IGuiElement parent, IGuiElement child,
                vec2f pos)
    {
        child.parent = parent;
        mGuiChilds.insertBack(GuiChild(pos, child));
    }

    void remove(IGuiElement child)
    {
        //todo
    }

    auto opSlice()
    {
        return mGuiChilds[];
    }

    void shutdown()
    {
        //todo
    }

private:
    DList!GuiChild    mGuiChilds;
}
