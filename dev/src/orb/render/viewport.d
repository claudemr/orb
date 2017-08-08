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

module orb.render.viewport;

public import orb.scene.camera;
public import orb.scene.scene;
import orb.render.rendersystem;


/**
 * This handles all the organization of the rendering of a 3D scene (terrain,
 * entities) onto a RenderTarget.
 */
class Viewport
{
public:
    this(Scene scene, Camera camera)
    {
        mCamera = camera;
        mScene  = scene;
    }

    void render()
    {
        auto meshRndr = RenderSystem.renderer!IMesh;
        auto dirLight = mScene.dirLights[0];
        auto lightVec = mCamera.matrixView * dirLight.direction;
        meshRndr.setDirLight(lightVec, dirLight.color);

        meshRndr.setCamera(mCamera);

        // render entities
        /*foreach (Entity entity; mEcs.entities.entitiesWith!MeshComponent)
        {
            meshRndr.setModelPlacement(mat4f.identity);
            meshRndr.setMesh(entity.component!MeshComponent.mesh);
            meshRndr.render();
        }*/

        // render terrain
        if (mScene.terrain !is null)
        {
            import gfm.math.matrix;

            foreach (chunk; mScene.terrain[])
            {
                if (chunk.mesh is null)
                    continue;

                auto chunkPos = chunk.pos;
                auto transVec = vec3f(chunkPos.x * chunkSize,
                                      chunkPos.y * chunkSize,
                                      chunkPos.z * chunkSize);
                meshRndr.setModelPlacement(mat4f.translation(transVec));
                meshRndr.setMesh(chunk.mesh);
                meshRndr.render();
            }
        }
    }

private:
    Camera          mCamera;
    Scene           mScene;
}

