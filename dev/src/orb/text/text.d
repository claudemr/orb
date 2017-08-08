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

module orb.text.text;

public import orb.text.textelement;


private enum State
{
    newLine,
    word,
    space
}


/**
 * This structure aims at organizing a piece of text in terms of line/span/word.
 *
 * It is a DL-list of lines which contain DL-list of spans of text. A span may
 * be a word or a succession of spaces.
 * A line may have a maximum length (defined by maxWidth). So it will wrap
 * them, aiming to avoid word split as much as possible.
 * If a word cannot fit the maximum line size, it is split as well.
 */
struct Text
{
    /**
     * To disable wrapping set maxWidth to uint.max.
     */
    this(string text, in Font font, uint maxWidth = uint.max)
    {
        TextLine line = lines = new TextLine;
        TextSpan span;
        State    state = State.newLine;

        nbLine = 1;
        height = lineSize(font);

        void buildNewLine(char c)
        {
            // We ignore wrapping in this case as we start a new line anyway.
            // A line must have at least one character even if it does not fit
            // maxWidth.

            switch (c)
            {
            case ' ':
            case '\t':
                span = new TextSpan(font, c);
                line.insert(span);
                state = State.space;
                break;

            case '\n':
                span = new TextSpan(font, c);
                line.insert(span);
                line = line.insert(new TextLine);
                nbLine++;
                height += yAdvance(font);
                // Do not change state
                break;

            default:
                span = new TextSpan(font, c);
                line.insert(span);
                state = State.word;
            }
        }

        void buildWord(char c)
        {
            switch (c)
            {
            case ' ':
            case '\t':
                // Wrapping needed
                if (line.widthExtended(font, c) > maxWidth)
                {
                    line.wrapped = true;
                    // New line
                    line = line.insert(new TextLine);
                    nbLine++;
                    height += yAdvance(font);
                }
                span = new TextSpan(font, c);
                line.insert(span);
                state = State.space;
                break;

            case '\n':
                // Create a new space span for the new-line char
                span = new TextSpan(font, c);
                line.insert(span);
                // New line
                line = line.insert(new TextLine);
                nbLine++;
                height += yAdvance(font);
                state = State.newLine;
                break;

            default:
                // Wrapping needed
                if (line.widthExtended(font, c) > maxWidth)
                {
                    // Wrap line
                    line.wrapped = true;

                    // If it's the first span of a line,
                    // it has to be cut and wrapped
                    if (span.isFirstSpan)
                    {
                        // Wrap current word span
                        span.wrapped = true;
                        // New line
                        line = line.insert(new TextLine);
                        nbLine++;
                        height += yAdvance(font);
                        // New word for this line
                        span = new TextSpan(font, c);
                        line.insert(span);
                    }
                    // Else, the span has to be removed from the current
                    // line and put on the next line
                    else
                    {
                        // New line
                        line = line.insert(new TextLine);
                        nbLine++;
                        height += yAdvance(font);
                        // Remove span from previous line
                        span.remove();
                        // Insert char in span, and insert span in new line
                        line.insert(span);
                        span.insert(font, c);
                    }
                }
                else
                {
                    // Insert new character in the word span
                    span.insert(font, c);
                }
                // Do not change state
            }
        }

        void buildSpace(char c)
        {
            switch (c)
            {
            case ' ':
            case '\t':
                // Wrapping needed
                if (line.widthExtended(font, c) > maxWidth)
                {
                    // Wrap current space span
                    span.wrapped = true;
                    line.wrapped = true;
                    // New line
                    line = line.insert(new TextLine);
                    nbLine++;
                    height += yAdvance(font);
                    // New word for this line
                    span = new TextSpan(font, c);
                    line.insert(span);
                }
                else
                {
                    // Insert new character in the space span
                    span.insert(font, c);
                }
                // Do not change state
                break;

            case '\n':
                // Insert new-line char in the space span
                span.insert(font, c);
                // New line
                line = line.insert(new TextLine);
                nbLine++;
                height += yAdvance(font);
                state = State.newLine;
                break;

            default:
                // Wrapping needed
                if (line.widthExtended(font, c) > maxWidth)
                {
                    line.wrapped = true;
                    // New line
                    line = line.insert(new TextLine);
                    nbLine++;
                    height += yAdvance(font);
                }
                span = new TextSpan(font, c);
                line.insert(span);
                state = State.word;
            }
        }

        foreach (c; text)
        {
            switch (state)
            {
            case State.newLine:
                buildNewLine(c);
                break;
            case State.word:
                buildWord(c);
                break;
            case State.space:
                buildSpace(c);
                break;
            default:
                assert(false);
            }
            /*
            import orb.utils.logger;
            tracef("Line nb=%d nbWord=%d nbSpan=%d width=%d cursor=%d nbChar=%d hasWrapped=%d", nbLine, line.nbWord, line.nbSpan, line.width, line.cursor, line.nbChar, line.hasWrapped);
            tracef("  Span Type=%s str=\"%s\" width=%d cursor=%d nbChar=%d hasWrapped=%d", span.type, span.str, span.width, span.cursor, span.nbChar, span.hasWrapped);*/
        }
    }

    ~this()
    {
        if (lines is null)
            return;
        auto r = TextLineRange(lines);
        while (true)
        {
            auto rSaved = r.save();
            r.popFront();
            if (r.empty)
            {
                destroy(r.front);
                break;
            }
            destroy(r.front);
            r = rSaved;
        }
        lines = null;
    }

    TextLine lines;
    uint     maxWidth;
    uint     nbLine;
    uint     height;
}
