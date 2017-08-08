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

module orb.gui.canvas;

public import orb.gui.guitext;

import orb.render.rendersystem;


/**
 * This handles all the organization of the rendering of GUI elements onto a
 * RenderTarget.
 */
final class Canvas : GuiElement
{
public:

    void insert(GuiText gui, vec2f pos)
    {
        mGui = cast(IGuiElement)gui;

        auto font = gui.font;
        mTextsPerFont[font] ~= gui;
        mPos = pos;
    }

    void render(vec2f pos)
    {
        //todo only render text at the moment... buttons etc, later.
        renderText(pos);
    }

private:
    void renderText(vec2f pos)
    {
        auto textRndr = RenderSystem.renderer!"Text";

        textRndr.prepare();

        foreach (font, texts; mTextsPerFont)
        {
            textRndr.enable(font);
            foreach (text; texts)
                text.render(pos + mPos);
        }

        textRndr.unprepare();
    }

    IGuiElement           mGui;
    vec2f                 mPos;
    GuiText[][const Font] mTextsPerFont;
}
