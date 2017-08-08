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

module orb.opengl.shader;

public import orb.opengl.attribute;
public import orb.opengl.vao;

import orb.opengl.uniform;
import orb.opengl.utils;
import orb.utils.exception;
import derelict.opengl3.gl3;
import gfm.math.matrix;
import gfm.math.vector;
import std.string;


enum ShaderBlock
{
    fragment = 0,
    vertex,
    geometry
}

private GLenum[ShaderBlock.max + 1] glToTypes =
        [ ShaderBlock.fragment : GL_FRAGMENT_SHADER,
          ShaderBlock.vertex   : GL_VERTEX_SHADER,
          ShaderBlock.geometry : GL_GEOMETRY_SHADER ];
private string[ShaderBlock.max + 1] typeString =
        [ ShaderBlock.fragment : "fragment",
          ShaderBlock.vertex   : "vertex",
          ShaderBlock.geometry : "geometry"];

private struct Shader
{
    GLuint  glId;
    string  code;
    GLint   compileResult;       // GL_TRUE if it compiled correctly
    char[]  compileLog;
}


// Exception class specialized towards GL errors
class ShaderException : Exception
{
    string log;

     @safe nothrow
    this(char[] shaderLog, string msg, string file = null, size_t line = 0)
    {
        log = shaderLog.idup;
        super("[Shader] "~msg, file, line);
    }
}


ShaderProgram[string] lookupShaders(string path)
{
    import std.file : dirEntries, readText, SpanMode;
    import std.regex : ctRegex, matchFirst;

    static struct ShaderFile
    {
        string fragment;
        string vertex;
    }

    // make a database of the shaders
    ShaderFile[string] shaderFiles;
    auto shaderMatch = ctRegex!(`(?P<type>\w+)_(?P<stage>\w+)\.glsl$`);
    foreach (string shaderFilename; dirEntries(path, SpanMode.shallow))
    {
        auto matchRet = matchFirst(shaderFilename, shaderMatch);
        if (matchRet.length != 3 || matchRet["type"].length < 1)
            continue;
        auto shaderFile = matchRet["type"] in shaderFiles;
        if (shaderFile is null)
        {
            shaderFiles[matchRet["type"]] = ShaderFile("", "");
            shaderFile = &shaderFiles[matchRet["type"]];
        }
        if (matchRet["stage"] == "fragment")
            shaderFile.fragment = shaderFilename;
        else if (matchRet["stage"] == "vertex")
            shaderFile.vertex   = shaderFilename;
    }

    ShaderProgram[string] programs;

    // build each shader program
    foreach (string name, ref ShaderFile sf; shaderFiles)
    {
        enforceOrb(sf.fragment != "", "Missing fragment shader for " ~ name);
        enforceOrb(sf.vertex != "",   "Missing vertex shader for " ~ name);
        import orb.utils.logger;
        infof("Loading shader '%s' (%s, %s)", name, sf.vertex, sf.fragment);
        programs[name] = loadShaders(readText(sf.vertex),
                                     readText(sf.fragment));
    }

    return programs;
}

ShaderProgram loadShaders(string vertexShaderCode, string fragmentShaderCode)
{
    //*** Load the shaders ***
    auto program = new ShaderProgram();

    try
    {
        program.setShader(ShaderBlock.vertex,   vertexShaderCode);
        program.setShader(ShaderBlock.fragment, fragmentShaderCode);

        program.link();
    }
    catch (ShaderException e)
    {
        import orb.utils.logger;
        error("Shader exception. Log:\n%s", e.log);
        throw e;
    }

    return program;
}


class ShaderProgram
{
public:
    this()
    {
        mIdProgram = glCreateProgram();
        enforceGl("Could not create program");
    }

    ~this()
    {
        foreach(shader; shaders)
        {
            glDetachShader(mIdProgram, shader.glId);
            glDeleteShader(shader.glId);
        }

        glDeleteProgram(mIdProgram);
    }

    void setShader(ShaderBlock type, in string code)
    {
        GLint compileLogLength;
        immutable(char)* pCode;

        // create a new shaders if required and fill it
        if (type !in shaders)
            shaders[type] = Shader(glCreateShader(glToTypes[type]));
        shaders[type].code = code.dup;

        // bind the code and compile
        pCode = toStringz(shaders[type].code);
        glShaderSource(shaders[type].glId, 1, &pCode, null);
        glCompileShader(shaders[type].glId);

        // get the result
        glGetShaderiv(shaders[type].glId, GL_COMPILE_STATUS,
                      &shaders[type].compileResult);
        glGetShaderiv(shaders[type].glId, GL_INFO_LOG_LENGTH,
                      &compileLogLength);
        shaders[type].compileLog = new char[compileLogLength];
        glGetShaderInfoLog(shaders[type].glId,
                           compileLogLength,
                           null,
                           shaders[type].compileLog.ptr);
        if (!shaders[type].compileResult)
            throw new ShaderException(shaders[type].compileLog,
                              typeString[type]~" shader compilation failed");

        // attach the shader to the main program
        glAttachShader(mIdProgram, shaders[type].glId);
    }

    void setUniform(T)(string name, T values)
    {
        enforceOrb(mLinkResult && mValidationResult,
                   "Shaders not linked and validated");
        enforceOrb(name in mUniforms,
                   format("Attribute %s is not declared", name));
        mUniforms[name].set(values);
    }

    auto uniforms() @property
    {
        static struct UniformRoot
        {
            ShaderProgram shader;

            static struct UniformField
            {
                import std.conv : to;
                ShaderProgram shader;
                string prefix;

                UniformField opDispatch(string name)() @property
                {
                    return UniformField(shader, prefix ~ "." ~ name);
                }

                void opDispatch(string name, T)(T val) @property
                {
                    shader.setUniform!T(prefix ~ "." ~ name, val);
                }

                UniformField opIndex(size_t i) @property
                {
                    return UniformField(shader,
                                        prefix ~ "[" ~ i.to!string ~ "]");
                }

                void opIndexAssign(T)(T val, size_t i) @property
                {
                    shader.setUniform(prefix ~ "[" ~ i.to!string ~ "]", val);
                }
            }

            UniformField opDispatch(string name)() @property
            {
                return UniformField(shader, name);
            }

            void opDispatch(string name, T)(T val) @property
            {
                shader.setUniform(name, val);
            }
        }

        return UniformRoot(this);
    }

    void enableAttribute(in string name)
    {
        mAttribLayout.enable(name);
    }

    void disableAttribute(in string name)
    {
        mAttribLayout.disable(name);
    }

    void setAttribute(string name, in Vbo vbo)
    {
        mAttribLayout.set(name, vbo);
    }

    const(AttributeLayout) attributeLayout() @property const
    {
        return mAttribLayout;
    }

    void link()
    {
        char[] getLog()
        {
            char[] log;
            GLint logLength;

            glGetProgramiv(mIdProgram, GL_INFO_LOG_LENGTH, &logLength);
            log = new char[logLength];
            glGetProgramInfoLog(mIdProgram, logLength, null, log.ptr);

            return log;
        }

        // link the shaders
        glLinkProgram(mIdProgram);
        glGetProgramiv(mIdProgram, GL_LINK_STATUS, &mLinkResult);
        mLinkLog = getLog();
        if (!mLinkResult)
            throw new ShaderException(mLinkLog,
                                      "Shaders linking failed");

        // validate the shaders
        glValidateProgram(mIdProgram);
        glGetProgramiv(mIdProgram, GL_VALIDATE_STATUS, &mValidationResult);
        mValidationLog = getLog();
        if (!mValidationResult)
            throw new ShaderException(mValidationLog,
                                      "Shaders validation failed");

        lookupUniforms();

        lookupAttributes();
    }

    void use()
    {
        glUseProgram(mIdProgram);
    }


private:
    void lookupUniforms()
    {
        GLint uniformCount;
        glGetProgramiv(mIdProgram, GL_ACTIVE_UNIFORMS, &uniformCount);

        GLchar[256] name;

        for (GLint i = 0; i < uniformCount; i++)
        {
            GLsizei typeSize, nameLen;
            GLenum type;

            glGetActiveUniform(mIdProgram, i, 255, &nameLen, &typeSize, cast(uint*)&type, name.ptr);
            enforceOrb(nameLen <= 255,
                       format("Uniform name too long %d", nameLen));
            name[nameLen] = '\0';

            GLint location = glGetUniformLocation(mIdProgram, name.ptr);

            string typeName = glStringType[type];
            string nameStr = name.ptr.fromStringz.idup;

            mUniforms[nameStr] = Uniform(location, type);

            import orb.utils.logger;
            infof("- Uniform %d (loc=%d): %s %s <Size: %d>",
                  i, location, typeName, nameStr, typeSize);
        }
    }

    void lookupAttributes()
    {
        GLint attributeCount;
        glGetProgramiv(mIdProgram, GL_ACTIVE_ATTRIBUTES, &attributeCount);

        GLchar[256] name;

        for (GLint i = 0; i < attributeCount; i++)
        {
            GLsizei nameLen;
            GLint typeSize;
            GLenum type;

            glGetActiveAttrib(mIdProgram, i, 255, &nameLen, &typeSize, &type, name.ptr);
            enforceOrb(nameLen <= 255,
                       format("Attribute name too long %d", nameLen));
            name[nameLen] = '\0';

            GLint location = glGetAttribLocation(mIdProgram, name.ptr);

            string typeName = glStringType[type];
            string nameStr = name.ptr.fromStringz.idup;

            mAttribLayout.attributes[nameStr] = Attribute(location, type);

            import orb.utils.logger;
            infof("- Attribute %d (loc=%d): %s %s <Size: %d>",
                  i, location, typeName, nameStr, typeSize);
        }
    }

    // shaders
    Shader[ShaderBlock]         shaders;

    // program
    GLuint              mIdProgram;
    GLint               mLinkResult;       // GL_TRUE if it linked correctly
    char[]              mLinkLog;
    GLint               mValidationResult; // GL_TRUE if it validated correctly
    char[]              mValidationLog;

    // attributes
    Uniform[string]     mUniforms;
    AttributeLayout     mAttribLayout;
}