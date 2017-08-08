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

module orb.render.viewport;

public import orb.scene.camera;
public import orb.scene.scene;

import orb.component;
import orb.event;
import orb.render.rendersystem;
import std.math : sqrt;


private string vtxCoord(int a)
{
    switch (a)
    {
    case 0:
        return "vec3f(0.0, 0.5, 0.5)";
    case 1:
        return "vec3f(-0.5, -0.5, 0.5)";
    case 2:
        return "vec3f(0.0, -0.5, -0.5)";
    case 3:
        return "vec3f(0.5, -0.5, 0.5)";
    default:
        return "";
    }
}

private string nrmCoord(int a)
{
    switch (a)
    {
    case 0: // 0 1 3
        return "vec3f(0.0, 0.0, 1.0)";
    case 1: // 1 2 3
        return "vec3f(0.0, -1.0, 0.0)";
    case 2: // 0 3 2
        return "vec3f(sqrt(6.0)/6, sqrt(6.0)/3, -sqrt(6.0)/6)";
    case 3: // 0 2 1
        return "vec3f(-sqrt(6.0)/6, sqrt(6.0)/3, -sqrt(6.0)/6)";
    default:
        return "";
    }
}

immutable vec3f[12] points = [
                mixin(vtxCoord(0)),
                mixin(vtxCoord(1)),
                mixin(vtxCoord(3)),

                mixin(vtxCoord(1)),
                mixin(vtxCoord(2)),
                mixin(vtxCoord(3)),

                mixin(vtxCoord(0)),
                mixin(vtxCoord(3)),
                mixin(vtxCoord(2)),

                mixin(vtxCoord(0)),
                mixin(vtxCoord(2)),
                mixin(vtxCoord(1))
            ];
immutable vec3f[12] normals = [
                mixin(nrmCoord(0)),
                mixin(nrmCoord(0)),
                mixin(nrmCoord(0)),

                mixin(nrmCoord(1)),
                mixin(nrmCoord(1)),
                mixin(nrmCoord(1)),

                mixin(nrmCoord(2)),
                mixin(nrmCoord(2)),
                mixin(nrmCoord(2)),

                mixin(nrmCoord(3)),
                mixin(nrmCoord(3)),
                mixin(nrmCoord(3))
            ];

immutable uint[12] indices = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ];



/**
 * This handles all the organization of the rendering of a 3D scene (terrain,
 * entities) onto a RenderTarget.
 */
class Viewport : GuiElement
{
public:
    this(Scene scene, Camera camera)
    {
        mCamera = camera;
        mScene  = scene;
        mModelMesh = RenderSystem.renderer!"Model".createMesh(points,
                                                              normals,
                                                              indices);
    }

    void render(vec2f pos)
    {
        auto dirLight = mScene.dirLight;
        auto lightVec = mCamera.matrixView * dirLight.direction;

        auto modelRndr = RenderSystem.renderer!"Model";
        modelRndr.setDirLight(lightVec, dirLight.color);
        modelRndr.setCamera(mCamera);

        // render entities
        modelRndr.setMesh(mModelMesh);
        foreach (ett, p; mScene.entities.entitiesWith!Position)
        {
            modelRndr.setModelMatrix(mat4f.translation(p.pos));
            modelRndr.render();
        }

        // render terrain
        if (mScene.terrain !is null)
        {
            import gfm.math.matrix;

            auto chunkRndr = RenderSystem.renderer!"Chunk";
            chunkRndr.setDirLight(lightVec, dirLight.color);
            chunkRndr.setCamera(mCamera);

            foreach (chunk; mScene.terrain[])
            {
                if (chunk.mesh is null)
                    continue;

                if (!chunk.isVisible(mCamera))
                    continue;

                chunkRndr.setMesh(chunk.mesh, vec3f(chunk.pos) * chunkSize);
                chunkRndr.render();
            }
        }
    }

private:
    Camera  mCamera;
    Scene   mScene;
    IModelMesh   mModelMesh; //todo hack

}

