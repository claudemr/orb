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

module orb.text.textelement;

public import orb.text.font;
import std.typecons;


enum Type
{
    word,
    space,
    line
}


int lineSize(in Font font)
{
    return font.lineHeight;
}

int yAdvance(in Font font)
{
    return font.lineHeight
         - font.padding(Padding.top) - font.padding(Padding.bottom)
         + font.spacing(Spacing.y);
}

int charSize(in Font font, char c)
{
    return font[cast(size_t)c].width;
}

int xAdvance(in Font font, char c)
{
    auto fntChar = font[cast(size_t)c];
    return fntChar.xadvance
         - font.padding(Padding.left) - font.padding(Padding.right)
         + font.spacing(Spacing.x);
}


/**
 * Basic text element. Word, spaces, or lines.
 */
private class TextElement
{
public:
    this()
    {
        mNext = mPrev = this;
        mWidth = mCursor = mNbChar = 0;
    }

    this(in Font font, char c)
    {
        this();
        add(font, c);
        setType(c);
    }

    ~this()
    {
        mNext.mPrev = mPrev;
        mPrev.mNext = mNext;
        mNext = mPrev = null;
    }

    /**
     * Calculate the extended width of the line if we add a new character to it.
     */
    uint widthExtended(in Font font, char c)
    {
        auto fntChar = font[cast(size_t)c];
        auto addedWidth = fntChar.xoffset + fntChar.width;
        return mCursor + (addedWidth < 0 ? 0 : addedWidth);
    }

    Type type() @property
    {
        return mType;
    }

    uint width() @property
    {
        return mWidth;
    }

    uint cursor() @property
    {
        return mCursor;
    }

    uint nbChar() @property
    {
        return mNbChar;
    }

    bool wrapped() @property
    {
        return mWrapped;
    }

    void wrapped(bool flag) @property
    {
        mWrapped = flag;
    }

protected:
    void insert(TextElement newElem, Flag!"Before" place = No.Before)
    {
        if (place == No.Before)
        {
            newElem.mNext = this.mNext;
            newElem.mPrev = this;
            this.mNext.mPrev = newElem;
            this.mNext = newElem;
        }
        else
        {
            newElem.mPrev = this.mPrev;
            newElem.mNext = this;
            this.mPrev.mNext = newElem;
            this.mPrev = newElem;
        }
    }

    void remove()
    {
        mNext.mPrev = mPrev;
        mPrev.mNext = mNext;
        mNext = mPrev = this;
    }

private:
    void setType(char c)
    {
        switch (c)
        {
        case ' ':
        case '\t':
        case '\n':
            mType = Type.space;
            break;

        default:
            mType = Type.word;
        }
    }

    void add(in Font font, char c)
    {
        mWidth = widthExtended(font, c);
        mCursor += xAdvance(font, c);
        mNbChar++;
    }

    TextElement mNext = void, mPrev = void;
    Type        mType = void;
    uint        mWidth;
    uint        mCursor;
    uint        mNbChar;
    bool        mWrapped;
}


/**
 * Individual span of text.
 *
 * Depending of the $(D Type), either composed of:
 * - letters composing words (alphanumeric + punctuation).
 * - spaces, tabulations and new-lines.
 */
class TextSpan : TextElement
{
public:
    this(in Font font, char c)
    {
        mStr ~= c;
        super(font, c);
    }

    ~this()
    {
        if (isFirstSpan)
        {
            if (mNext == this)
                mLine.mFirstSpan = null;
            else
                mLine.mFirstSpan = cast(TextSpan)mNext;
        }
        mLine = null;
    }

    void insert(in Font font, char c)
    {
        mStr ~= c;
        add(font, c);
        mLine.add(font, c);
    }

    alias insert = TextElement.insert;

    override void remove()
    {
        if (mLine is null)
            return;

        mLine.mNbSpan--;
        if (mType == Type.word)
            mLine.mNbWord--;

        mLine.mNbChar -= mNbChar;
        mLine.mCursor -= mCursor;

        // Adjust line width and cursor
        if (isFirstSpan)
        {
            if (mNext == this)
            {
                mLine.mWidth = 0;
                mLine.mFirstSpan = null;
            }
            else
            {
                mLine.mWidth -= mCursor;
                mLine.mFirstSpan = cast(TextSpan)this.mNext;
            }
        }
        else
        {
            if ((cast(TextSpan)mPrev).isFirstSpan)
                mLine.mWidth = mPrev.width;
            else
                mLine.mWidth = mPrev.mPrev.cursor + mPrev.width;
        }

        super.remove();
        mLine = null;
    }

    TextLine line() @property
    {
        return mLine;
    }

    string str() @property
    {
        return mStr;
    }

    bool isFirstSpan() @property
    {
        return mLine !is null
             ? mLine.mFirstSpan == this
             : false;
    }

    bool hasWrapped() @property
    {
        /* If it is not the first span of a line, it cannot have wrapped */
        if (!isFirstSpan)
            return false;
        /* Is the last span of the previous line wrapped?
           If it is the first line, the previous is the last line, the last span
           of which should never have wrapped (yet). */
        return (cast(TextLine)mLine.mPrev).mFirstSpan.mPrev.mWrapped;
    }

private:
    TextLine mLine;
    string   mStr;
}


/**
 * Line of text. Made of a DL-list of text-spans.
 */
class TextLine : TextElement
{
public:
    this()
    {
        mType = Type.line;
    }

    ~this()
    {
        while (mFirstSpan !is null)
            destroy(mFirstSpan);
        mFirstSpan = null;
    }

    void insert(TextSpan span)
    {
        if (mFirstSpan !is null)
            // Insert before the first element, to become the last one
            mFirstSpan.insert(span, Yes.Before);
        else
            // Very first element
            mFirstSpan = span;

        if (span.mType == Type.word)
            mNbWord++;
        mNbSpan++;

        // Adjust char/span info
        mWidth = mCursor + span.mWidth;
        mNbChar += span.mNbChar;
        mCursor += span.mCursor;

        // Link itself to the span
        span.mLine = this;
    }

    TextLine insert(TextLine nextLine)
    {
        super.insert(nextLine, No.Before);
        return nextLine;
    }

    alias insert = TextElement.insert;

    uint nbWord() @property
    {
        return mNbWord;
    }

    uint nbSpan() @property
    {
        return mNbSpan;
    }

    bool hasWrapped() @property
    {
        /* Is the previous line wrapped?
           If it is the first line, the previous is the last line, which should
           never have wrapped (yet). */
        return mPrev.mWrapped;
    }

private:
    TextSpan mFirstSpan;   // word or space
    uint     mNbWord;
    uint     mNbSpan;
}


struct TextLineRange
{
public:
    this(TextLine firstLine)
    {
        mLine = mFirstLine = firstLine;
        hasPopped = false;
    }

    TextLine front() @property
    {
        return mLine;
    }

    void popFront()
    {
        mLine = cast(TextLine)mLine.mNext;
        hasPopped = true;
    }

    bool empty() @property
    {
        return hasPopped && mLine == mFirstLine;
    }

    TextLineRange save()
    {
        TextLineRange r;
        r = this;
        return r;
    }

private:
    bool hasPopped;
    TextLine mLine, mFirstLine;
}

struct TextSpanRange
{
public:
    this(TextLine line)
    {
        mSpan = mFirstSpan = line.mFirstSpan;
        hasPopped = false;
    }

    TextSpan front() @property
    {
        return mSpan;
    }

    void popFront()
    {
        mSpan = cast(TextSpan)mSpan.mNext;
        hasPopped = true;
    }

    bool empty() @property
    {
        return hasPopped && mSpan == mFirstSpan;
    }

    TextSpanRange save()
    {
        TextSpanRange r;
        r = this;
        return r;
    }

private:
    bool hasPopped;
    TextSpan mSpan, mFirstSpan;
}
