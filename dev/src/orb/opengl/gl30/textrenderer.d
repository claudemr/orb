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

module orb.opengl.gl30.textrenderer;

public import orb.render.renderer;
public import orb.opengl.gl30.textmesh;

import orb.opengl.shader;
import orb.opengl.texture;
import orb.utils.exception;
import derelict.opengl3.gl3;


class Gl30TextRenderer : ITextRenderer
{
public:
    this(string vertexShaderCode, string fragmentShaderCode)
    {
        mProgram = loadShaders(fragmentShaderCode, vertexShaderCode);
    }

    ~this()
    {
        foreach (const Font fnt, Texture tex; mTexPerFont)
        {
            destroy(tex);
            mTexPerFont[fnt] = null;
        }
        destroy(mProgram);
    }

    ITextMesh createMesh(in vec2f[] points,
                         in vec2f[] texCoords,
                         in uint[] indices)
    {
        return cast(ITextMesh)new Gl30TextMesh(points, texCoords, indices,
                                               mProgram.attributeLayout);
    }

    void load(in Font font)
    {
        if (font in mTexPerFont)
            return;

        mTexPerFont[font] = new Texture;
        auto atlas = font.atlas;
        mTexPerFont[font].set2dRgbaUncomp(atlas.data,
                                          atlas.width,
                                          atlas.height);
    }

    void prepare()
    {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDisable(GL_DEPTH_TEST);
        mProgram.use();
        mProgram.uniforms.texId = 0;    // Always use GL_TEXTURE0
    }

    void enable(in Font font)
    {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, mTexPerFont[font].glId);
    }

    void render(ITextMesh tm, vec2f position, vec4f color)
    {
        auto gl30tm = cast(Gl30TextMesh)tm;

        mProgram.uniforms.position = position;
        // Discard alpha component of color at the moment...
        mProgram.uniforms.color = vec3f(color.r, color.g, color.b);
        gl30tm.vao.bind();

        glDrawElements(GL_TRIANGLES, cast(GLsizei)gl30tm.vboIndices.length,
                       gl30tm.vboIndices.glElementType, null);

        gl30tm.vao.unbind();

    }

    void unprepare()
    {
        glDisable(GL_BLEND);
        glEnable(GL_DEPTH_TEST);
    }

private:
    ShaderProgram       mProgram;
    Texture[const Font] mTexPerFont;
}