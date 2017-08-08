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

module orb.text.font;

import orb.utils.exception;
import derelict.sdl2.image;
import derelict.sdl2.sdl;
import std.algorithm;
import std.array;
import std.ascii;
import std.conv;
import std.exception;
import std.experimental.logger;
import std.file;
import std.range;
import std.stdio;
import std.string;

// It uses Hiero: https://github.com/libgdx/libgdx/wiki/Hiero
// java -jar runnable-hiero.jar

enum int maxChar = 128;

struct FontAtlas
{
public:
    int width() const @property
    {
        return mImage.w;
    }

    int height() const @property
    {
        return mImage.h;
    }

    const(void*) data() const @property
    {
        return mImage.pixels;
    }

private:
    this(const SDL_Surface* i)
    {
        mImage = i;
    }
    const SDL_Surface* mImage;
}

enum Padding : int
{
    top = 0,
    left,
    bottom,
    right
}

enum Spacing : int
{
    x = 0,
    y
}

struct FontChar
{
    char id;
    int x, y;
    int width, height;
    int xoffset, yoffset;
    int xadvance;
}


class Font
{
public:
    this(string filename)
    {
        // Open file
        File fntFile;
        auto fileExc = collectException(File(filename, "r"), fntFile);
        if (fileExc)
        {
            errorf("Cannot open %s\n", filename);
            return;
        }
        scope(failure) fntFile.close();

        parseFntFile(this, fntFile);

        fntFile.close();

        // Load the font atlas
        import std.path;
        string imageFileName = chainPath(dirName(filename), mFilename).array;
        mImage = IMG_Load(imageFileName.toStringz);
        enforceOrb(mImage !is null, "Image load failed: " ~ imageFileName);
    }

    ~this()
    {
        SDL_FreeSurface(mImage);
    }

    int size() @property const
    {
        return mSize;
    }

    int lineHeight() @property const
    {
        return mLineHeight;
    }

    int padding(Padding pad) const
    {
        return mPadding[pad];
    }

    int spacing(Spacing spa) const
    {
        return mSpacing[spa];
    }

    const(FontChar)* opIndex(size_t i) const
    {
        return &mCharset[i];
    }

    FontAtlas atlas() @property const
    {
        return FontAtlas(mImage);
    }

private:
    string mName;
    int    mSize;
    bool   mBold, mItalic;
    bool   mUnicode;
    int    mStretchH;
    bool   mSmooth;
    bool   mAa;
    int[4] mPadding;
    int[2] mSpacing;
    int    mLineHeight;
    int    mBase;
    int    mScaleW, mScaleH;
    string mFilename;

    FontChar[maxChar]   mCharset;

    SDL_Surface* mImage;
}


private void parseFntFile(F)(Font font, F file)
{
    // Read useful info in header
    auto fntLines = file.byLine();

    // Split 1st line
    auto fntLine = fntLines.takeOne.front;
    enforce(equal(fntLine[0 .. 5], "info "));
    fntLine = fntLine[5 .. $];

    font.mName     = fntLine.parseField!string("face");
    font.mSize     = fntLine.parseField!int("size");
    font.mBold     = fntLine.parseField!bool("bold");
    font.mItalic   = fntLine.parseField!bool("italic");
                     fntLine.parseField!string("charset");
    font.mUnicode  = fntLine.parseField!bool("unicode");
    font.mStretchH = fntLine.parseField!int("stretchH");
    font.mSmooth   = fntLine.parseField!bool("smooth");
    font.mAa       = fntLine.parseField!bool("aa");
    font.mPadding  = fntLine.parseField!(int[4])("padding");
    font.mSpacing  = fntLine.parseField!(int[2])("spacing");

    // 2nd line
    fntLines.popFront();
    fntLine = fntLines.takeOne.front;
    enforce(equal(fntLine[0 .. 7], "common "));
    fntLine = fntLine[7 .. $];

    font.mLineHeight = fntLine.parseField!int("lineHeight");
    font.mBase       = fntLine.parseField!int("base");
    font.mScaleW     = fntLine.parseField!int("scaleW");
    font.mScaleH     = fntLine.parseField!int("scaleH");

    // 3rd line
    fntLines.popFront();
    fntLine = fntLines.takeOne.front;
    enforce(equal(fntLine[0 .. 5], "page "));
    fntLine = fntLine[5 .. $];

                     fntLine.parseField!int("id");
    font.mFilename = fntLine.parseField!string("file");

    // 4th line
    fntLines.popFront();
    fntLine = fntLines.takeOne.front;
    enforce(equal(fntLine[0 .. 6], "chars "));
    fntLine = fntLine[6 .. $];

    auto count = fntLine.parseField!int("count");
    auto cs    = font.mCharset[0 .. $];

    // Parse line for each char
    for (int i = 0; i < count; i++)
    {
        fntLines.popFront();
        fntLine = fntLines.takeOne.front;
        enforce(equal(fntLine[0 .. 5], "char "));
        fntLine = fntLine[5 .. $];

        auto id         = fntLine.parseField!int("id");
        cs[id].id       = cast(char)id;
        cs[id].x        = fntLine.parseField!int("x");
        cs[id].y        = fntLine.parseField!int("y");
        cs[id].width    = fntLine.parseField!int("width");
        cs[id].height   = fntLine.parseField!int("height");
        cs[id].xoffset  = fntLine.parseField!int("xoffset");
        cs[id].yoffset  = fntLine.parseField!int("yoffset");
        cs[id].xadvance = fntLine.parseField!int("xadvance");
    }
}


private T parseField(T, S)(ref S str, string name)
    if (is(T == int) || is(T == bool) || is(T == string))
{
    str = str.stripLeft;
    enforce(str[0 .. name.length] == name);
    enforce(str[name.length] == '=');

    static if (is(T == int) || is(T == bool))
    {
        str = str[name.length + 1 .. $];
        auto idx = str.indexOfNeither(digits ~ "-");
        if (idx < 0)
            idx = str.length;
        T val = cast(T)str[0 .. idx].to!int;
        str = str[idx .. $];
        return val;
    }
    else static if (is(T == string))
    {
        enforce(str[name.length + 1] == '\"');
        str = str[name.length + 2 .. $];
        auto idx = str.indexOf('\"');
        enforce(idx >= 0);
        auto found = str[0 .. idx];
        str = str[idx + 1 .. $];
        return found.idup;
    }
    else
        static assert(0);
}

private T[N] parseField(T : T[N], size_t N, S)(ref S str, string name)
{
    str = str.stripLeft;
    enforce(str[0 .. name.length] == name);
    enforce(str[name.length] == '=');

    static if (is(T == int))
    {
        T[N] a;
        str = str[name.length + 1 .. $];
        for (int i = 0; i < N - 1; i++)
        {
            auto idx = str.indexOf(',');
            enforce(idx >= 0);
            a[i] = cast(T)str[0 .. idx].to!int;
            str = str[idx + 1 .. $];
        }

        auto idx = str.indexOfNeither(digits ~ "-");
        if (idx < 0)
            idx = str.length;
        a[N - 1] = cast(T)str[0 .. idx].to!int;
        str = str[idx .. $];
        return a;
    }
    else
        static assert(0);
}
