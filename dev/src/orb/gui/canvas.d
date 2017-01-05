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

module orb.gui.canvas;

public import orb.gui.guitext;

import orb.render.rendersystem;


/**
 * This handles all the organization of the rendering of GUI elements onto a
 * RenderTarget.
 */
class Canvas
{
public:
    void attach(GuiText gui)
    {
        mGui = cast(IGuiElement)gui;

        auto font = gui.font;
        mTextsPerFont[font] ~= gui;
    }

    void render()
    {
        //todo only render text at the moment... buttons etc, later.
        renderText();
    }

private:
    void renderText()
    {
        auto textRndr = RenderSystem.renderer!ITextMesh;

        textRndr.prepare();

        foreach (font, texts; mTextsPerFont)
        {
            textRndr.enable(font);
            foreach (text; texts)
                text.render();
        }

        textRndr.unprepare();
    }

    IGuiElement           mGui;
    GuiText[][const Font] mTextsPerFont;
}
