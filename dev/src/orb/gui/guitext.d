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

module orb.gui.guitext;

public import orb.gui.guielement;
public import std.typecons;

import orb.text.font;
import orb.render.mesh;
import orb.render.rendersystem;
import orb.text.text;
import dlib.image.color;
import std.ascii;
import std.exception;
import std.math : floor, ceil;

    import std.stdio;


enum AlignmentH
{
    left,
    right,
    centered,
    //justified // not supported yet
}

enum AlignmentV
{
    top,
    bottom,
    centered
}

/*enum CursorMove // not supported yet
{
    begin,
    end,
    nextChar,
    prevChar,
    nextWord,
    prevWord,
    nextLine,
    prevLine
}*/


// TODO lineHeight ratio
// TODO support UTF/UNICODE (only linux ASCII at the moment)

/**
 * Creates a new text, loads the text's quads into a VAO, and adds the text
 * to the screen.
 *
 * @param text
 *            - the text.
 * @param fontSize
 *            - the font size of the text, where a font size of 1 is the
 *            default size.
 * @param font
 *            - the font that this text should use.
 * @param pos
 *            - the position on the screen where the top left corner of the
 *            text should be rendered. The top left corner of the screen is
 *            (0, 0) and the bottom right is (1, 1).
 * @param size
 *            - size of the box containing the text in terms of screen
 *            width (1 is full screen width, 0.5 is half the width of the
 *            screen, etc.) Text cannot go off the edge of the page, so if
 *            the text is longer than this length it will go onto the next
 *            line. When text is centered it is centered into the middle of
 *            the line, based on this line length value.
 * @param alignment
 *            - whether the text should be centered or not.
 */
class GuiText : GuiElement
{
public:
    this(string text,
         in Font font, float fontSize,
         Vector2f pos, Vector2f size,
         Flag!"Wrap" wrapped = No.Wrap,
         AlignmentH alignmentH = AlignmentH.left,
         AlignmentV alignmentV = AlignmentV.top)
    {
        enforce(text.length != 0);

        // Basic fields
        mStr        = text.idup;
        mFont       = font;
        mFontSize   = fontSize / mFont.size;    // normalized
        mPosition   = pos;
        mSize       = size;
        mWrapped    = wrapped;
        mAlignmentH = alignmentH;
        mAlignmentV = alignmentV;

        // Build the text layout, the vertices and the texture coordinates
        buildTextLayout();

        mTextMesh = RenderSystem.renderer!ITextMesh.createMesh(mVertices,
                                                               mTexCoords,
                                                               mIndices);
    }

    ~this()
    {
    }

    Color4f color(Color4f c) @property
    {
        mColor = c;
        return c;
    }

    Color4f color() @property const
    {
        return mColor;
    }

    const(Font) font() @property const
    {
        return mFont;
    }

    override void render()
    {
        auto textRndr = RenderSystem.renderer!ITextMesh;
        textRndr.render(mTextMesh, mPosition, mColor);

        /*GL30.glBindVertexArray(text.getMesh());
        GL20.glEnableVertexAttribArray(0);
        GL20.glEnableVertexAttribArray(1);
        shader.loadColour(text.getColour());
        shader.loadTranslation(text.getPosition());
        GL11.glDrawArrays(GL11.GL_TRIANGLES, 0, text.getVertexCount());
        GL20.glDisableVertexAttribArray(0);
        GL20.glDisableVertexAttribArray(1);
        GL30.glBindVertexArray(0);*/
    }


private:
    /**
     * This builds the text layout depending on the font, its size, the square
     * box containing the text, the alignement and wrapping options.
     *
     * It fills the array of vertices and texture coordinates (in the font
     * texture atlas) for the pairs of triangles that represent each character
     * of the text.
     */
    void buildTextLayout()
    {
        // Get text layout
        mText = Text(mStr, mFont,
                     mWrapped ? cast(uint)(mSize.x / mFontSize) : uint.max);

        uint cursorX = 0, cursorY = 0;
        int   xPreOffset,  yPreOffset;
        float xPostOffset, yPostOffset;
        int truncTop, truncBot, truncLf, truncRg;

        void buildSpan(TextSpan span)
        {
            foreach (chr; span.str)
            {
                auto fntChr = mFont[cast(size_t)chr];

                if (isVisible(cursorX, fntChr, span.line,
                              xPreOffset, xPostOffset,
                              truncLf, truncRg))
                {
                    makeCharMesh(fntChr,
                                 cursorX + xPreOffset, xPostOffset,
                                 truncLf,  truncRg,
                                 cursorY + yPreOffset, yPostOffset,
                                 truncTop, truncBot);
                }
                cursorX += xAdvance(mFont, chr);
            }
        }

        void buildLine(TextLine line)
        {
            foreach (span; TextSpanRange(line))
            {
                if (isVisible(cursorX, span, line, xPreOffset, xPostOffset))
                    buildSpan(span);
                else
                    cursorX += span.cursor;
            }
        }

        foreach (line; TextLineRange(mText.lines))
        {
            if (isVisible(cursorY, yPreOffset, yPostOffset, truncTop, truncBot))
                buildLine(line);

            cursorX = 0;
            cursorY += yAdvance(mFont);
        }
    }

    bool isVisible(int y,
                   ref int yPreOffset, ref float yPostOffset,
                   out int truncTop, out int truncBot)
    {
        float lineY0, lineY1;
        int y0 = y;
        int y1 = y + mFont.lineHeight;

        switch (mAlignmentV)
        {
        case AlignmentV.top:
            yPreOffset  = 0;
            yPostOffset = 0;
            lineY0 = y0 * mFontSize;
            lineY1 = y1 * mFontSize;
            break;
        case AlignmentV.bottom:
            yPreOffset  = -cast(int)mText.height;
            yPostOffset = mSize.y;
            break;
        case AlignmentV.centered:
            yPreOffset  = -(cast(int)mText.height / 2);
            yPostOffset = mSize.y / 2;
            break;
        default:
            assert(false);
        }

        lineY0 = (y0 + yPreOffset) * mFontSize + yPostOffset;
        lineY1 = (y1 + yPreOffset) * mFontSize + yPostOffset;

        /*writefln("isVisible line %d,%d %3.3f,%3.3f",
            y0, y1, lineY0, lineY1);*/

        // Totally outside the box
        if (lineY1 < 0 || lineY0 > mSize.y)
            return false;
        // Totally inside the box (no truncation)
        if (lineY0 >= 0 && lineY1 <= mSize.y)
            return true;
        // Truncation required
        if (lineY0 < 0)
            truncTop = cast(int)floor(-lineY0 / mFontSize);
        if (lineY1 > mSize.y)
            truncBot = cast(int)ceil((lineY1 - mSize.y) / mFontSize);
        return true;
    }

    bool isVisible(int x, TextSpan span, TextLine line,
                   ref int xPreOffset, ref float xPostOffset)
    {
        if (span.type == Type.space)
            return false;

        float lineX0, lineX1;
        int x0 = x + mFont[cast(size_t)span.str[0]].xoffset;
        int x1 = x + span.width;

        switch (mAlignmentH)
        {
        case AlignmentH.left:
            xPreOffset  = 0;
            xPostOffset = 0;
            break;
        case AlignmentH.right:
            xPreOffset  = -cast(int)line.width;
            xPostOffset = mSize.x;
            break;
        case AlignmentH.centered:
            xPreOffset  = -(cast(int)line.width / 2);
            xPostOffset = mSize.x / 2;
            break;
        default:
            assert(false);
        }

        lineX0 = (x0 + xPreOffset) * mFontSize + xPostOffset;
        lineX1 = (x1 + xPreOffset) * mFontSize + xPostOffset;

        /*writefln("isVisible span %d,%d %3.3f,%3.3f",
            x0, x1, lineX0, lineX1);*/

        // Totally outside the box
        if (lineX1 < 0 || lineX0 > mSize.x)
            return false;

        return true;
    }

    bool isVisible(int x, in FontChar* chrPtr, TextLine line,
                   int xPreOffset, float xPostOffset,
                   out int truncLf, out int truncRg)
    {
        if (chrPtr.width == 0 || chrPtr.height == 0)
            return false;

        float lineX0, lineX1;
        int x0 = x + chrPtr.xoffset;
        int x1 = x0 + chrPtr.width;

        lineX0 = (x0 + xPreOffset) * mFontSize + xPostOffset;
        lineX1 = (x1 + xPreOffset) * mFontSize + xPostOffset;

        /*writefln("isVisible '%c' %d,%d %3.3f,%3.3f",
            chrPtr.id, x0, x1, lineX0, lineX1);*/

        // Totally outside the box
        if (lineX1 < 0 || lineX0 > mSize.x)
            return false;
        // Totally inside the box (no truncation)
        if (lineX0 >= 0 && lineX1 <= mSize.x)
            return true;
        // Truncation required
        if (lineX0 < 0)
            truncLf = cast(int)floor(-lineX0 / mFontSize);
        if (lineX1 > mSize.x)
            truncRg = cast(int)ceil((lineX1 - mSize.x) / mFontSize);

        return true;
    }

    void makeCharMesh(in FontChar* chrPtr,
                      int x, float xPostOffset,
                      int truncLf,  int truncRg,
                      int y, float yPostOffset,
                      int truncTop, int truncBot)
    {
        int x0, x1, y0, y1;
        int texX0, texX1, texY0, texY1;

        /*writefln("Make '%c'(%d) x=%d y=%d (%d,%d) (%d,%d)",
            chrPtr.id, cast(int)chrPtr.id, x, y,
            truncLf, truncRg, truncTop, truncBot);*/

        x0 = x + chrPtr.xoffset + truncLf;
        x1 = x + chrPtr.xoffset + chrPtr.width - truncRg;
        texX0 = chrPtr.x + truncLf;
        texX1 = chrPtr.x + chrPtr.width - truncRg;

        if (chrPtr.yoffset >= truncTop)
        {
            y0    = y + chrPtr.yoffset;
            texY0 = chrPtr.y;
        }
        else
        {
            y0    = y + truncTop;
            texY0 = chrPtr.y + truncTop - chrPtr.yoffset;
        }
        y1 = y + chrPtr.yoffset + chrPtr.height;
        if (y1 > y + mFont.lineHeight - truncBot)
        {
            y1    = y + mFont.lineHeight - truncBot;
            texY1 = chrPtr.y + mFont.lineHeight - truncBot;
        }
        else
            texY1 = chrPtr.y + chrPtr.height;

        insertVertex(x0 * mFontSize + xPostOffset,
                     y0 * mFontSize + yPostOffset,
                     x1 * mFontSize + xPostOffset,
                     y1 * mFontSize + yPostOffset);
        insertTexCoord(texX0, texY0, texX1, texY1);
        insertIndex();
    }

    void insertVertex(float x0, float y0, float x1, float y1)
    {
        //writefln("    (%3.3f %3.3f) (%3.3f %3.3f)", x0, y0, x1, y1);
        mVertices ~= vectorf(x0, y0);
        mVertices ~= vectorf(x0, y1);
        mVertices ~= vectorf(x1, y1);
        mVertices ~= vectorf(x1, y0);
    }

    void insertTexCoord(float x0, float y0, float x1, float y1)
    {
        //writefln("    (%d %d) (%d %d)", x0, y0, x1, y1);
        //xxx dlib is not const friendly
        auto atlas = cast(FontAtlas)mFont.atlas;
        float w = atlas.width, h = atlas.height;
        mTexCoords ~= vectorf(x0 / w, y0 / h);
        mTexCoords ~= vectorf(x0 / w, y1 / h);
        mTexCoords ~= vectorf(x1 / w, y1 / h);
        mTexCoords ~= vectorf(x1 / w, y0 / h);
    }

    void insertIndex()
    {
        uint idx = cast(uint)mVertices.length - 4;
        // CW order as y axis will be inverted in shader
        // 1st triangle
        mIndices ~= idx + 0;
        mIndices ~= idx + 1;
        mIndices ~= idx + 2;
        // 2nd triangle
        mIndices ~= idx + 2;
        mIndices ~= idx + 3;
        mIndices ~= idx + 0;
        //writeln("    " ~ mIndices[$-6 .. $]);
    }

    string      mStr;
    const Font  mFont;
    float       mFontSize;
    Flag!"Wrap" mWrapped;
    AlignmentH  mAlignmentH;
    AlignmentV  mAlignmentV;
    Color4f     mColor;
    Text        mText;
    Vector2f[]  mVertices;
    Vector2f[]  mTexCoords;
    uint[]      mIndices;
    ITextMesh   mTextMesh;
}


/+unittest
{
    auto font = new Font("font/ubuntu_mono.fnt");
    auto gt = new GuiText("Hello world!", font, 0.1,
                          vectorf(0.0f, 0.0f), vectorf(0.5f, 0.5f),
                          Yes.Wrap, AlignmentH.left, AlignmentV.top);
}+/
