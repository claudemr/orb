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

module orb.utils.exception;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

import std.exception;
import std.string;

alias enforceOrb = enforceEx!OrbException;

// define and init an associative array to get text version of GL errors
string[GLenum] glErrorToStr;
// can only be initialized at run-time
static this()
{
    glErrorToStr =
        [ GL_INVALID_ENUM                  : "GL invalid enum",
          GL_INVALID_VALUE                 : "GL invalid value",
          GL_INVALID_OPERATION             : "GL invalid operation",
          GL_INVALID_FRAMEBUFFER_OPERATION : "GL invalid framebuffer operation",
          GL_OUT_OF_MEMORY                 : "GL out of memory"/*,
          GL_STACK_UNDERFLOW               : "GL stack underflow",
          GL_STACK_OVERFLOW                : "GL stack overflow",
          GL_TABLE_TOO_LARGE               : "GL table too large"*/ ];
}

// Exception class specialized towards GL errors
class GlException : Exception
{
    GLenum glError;

     @safe nothrow
    this(GLenum glErr, string msg, string file = null, size_t line = 0)
    {
        glError = glErr;
        super("[GL] "~msg~" ("~glErrorToStr[glError]~")", file, line);
    }
}

// Check GL errors, and throws a GlException if an error is encountered
GLenum enforceGl(lazy const(char)[] msg = null,
                 string file = __FILE__,
                 size_t line = __LINE__) @trusted
{
    GLenum glErr = glGetError();

    if (glErr != GL_NO_ERROR)
        throw new GlException(glErr, msg.idup, file, line);

    return glErr;
}

// Exception class specialized towards SDL errors
class SdlException : Exception
{
    string sdlErrorStr;

     @safe nothrow
    this(string strErr, string msg, string file = null, size_t line = 0)
    {
        sdlErrorStr = strErr;
        super("[SDL] "~msg~" ("~strErr~")", file, line);
    }
}

// Check SDL errors, and throws a SdlException if an error is encountered
T enforceSdl(T)(T value, lazy string msg = "",
                string file = __FILE__,
                size_t line = __LINE__) @trusted
{
    string sdlErrorStr = fromStringz(SDL_GetError()).idup;

    SDL_ClearError();

    if (!value && sdlErrorStr !is null)
        throw new SdlException(sdlErrorStr, msg.idup, file, line);

    return value;
}

// Exception class specialized towards ORB engine
class OrbException : Exception
{
    this(string msg, string file = null, size_t line = 0) @safe pure nothrow
    {
        super("[ORB] "~msg, file, line);
    }
}


void ensureNotInGC(string resourceName) nothrow
{
    import core.exception;
    try
    {
        // Functions that modify the GC state throw InvalidMemoryOperationError
        // when called during a collection.
        // Freeing memory not owned by the GC is otherwise ignored.
        import core.memory;
        cast(void) GC.malloc(1);
        return;
    }
    catch(InvalidMemoryOperationError e)
    {
        import core.stdc.stdio;
        fprintf(stderr, "Error: clean-up of %s incorrectly"
                        " depends on destructors called by the GC.\n",
                        resourceName.ptr);
        assert(false); // crash
    }
}