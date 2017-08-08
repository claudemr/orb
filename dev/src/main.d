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

import controller;
import player;
import orb.engine;


class LightSystem : System
{
public:
    this(Scene scene)
    {
        mInitLight = vec4f(0.0f, 0.0f, 1.0f, 0.0f);
        mDirLightx = mDirLighty = 0.0f;
        mLight = scene.createDirLight(mInitLight, vec4f(1, 1, 0.6, 1));

    }

    override void run(EntityManager entities, EventManager events, Duration dt)
    {
        import std.math : PI;
        mat4f matRotLight;

        mDirLightx += PI / 60 / 2;
        mDirLighty += PI / 110 / 2;
        matRotLight = mat4f.rotateY(mDirLighty) * mat4f.rotateX(mDirLightx);
        mLight.direction = matRotLight * mInitLight;
    }

private:
    immutable vec4f mInitLight;
    float mDirLightx, mDirLighty;
    DirLight mLight;
}


void main()
{
    enum uint vpWidth   = 640;
    enum uint vpHeight  = 480;
    enum int  worldSize      = 1024;
    enum float planetRadius  = 500;
    enum float planetGravity = 9.8;
    static assert(planetRadius * 2 < worldSize);

    // ORB Engine init
    auto engine = Engine.singleton;

    // Renderer init
    auto renderSys = engine.createRenderSystem();
    auto win = renderSys.createWindow("Orb",                // title
                                      10, 10,               // position
                                      vpWidth, vpHeight,    // width/height
                                      vec4f(0, 0, 0.4, 1)); // background color
    // -> orb is launched in orb/dev, which is the current directory
    renderSys.lookupRenderers!"opengl.gl30"("shader");

    // Scene/terrain/camera preparation
    auto scene = engine.createScene();
    scene.createTerrain(worldSize, planetRadius, planetGravity);

    auto camera = scene.createCamera();
    camera.position = vec3f(worldSize/2,
                            worldSize/2,
                            worldSize/2 - planetRadius - 10);
    camera.fov   = 45.0;
    camera.ratio = cast(float)vpWidth / vpHeight;
    camera.near  = 0.1;
    camera.far   = 40.0;
    camera.lookAt(vec3f(worldSize/2, worldSize/2, worldSize/2));

    engine.activate(camera);

    // Manage directional light
    auto lightSys = new LightSystem(scene);
    engine.systems.register(lightSys);

    // Prepare viewport for the scene, and canvas for the GUI
    renderSys.insert(new Viewport(scene, camera));

    /*auto canvas = new Canvas;
    renderSys.insert(canvas);

    // Load the font and make a text
    auto font = new Font("font/ubuntu_mono.fnt");
    renderSys.renderer!ITextMesh.load(font);

    auto text = new GuiText("Hello world!", font, 0.1,
                            vec2f(0.5f, 0.5f),
                            Yes.Wrap, AlignmentH.left, AlignmentV.top);
    text.color = vec4f(0.8, 0.5, 0.1, 1.0);
    canvas.insert(text, vec2f(0.25f, 0.25f));*/

    // Input management
    auto controller = new Controller(engine.createInputSystem(win));
    engine.systems.register(controller);

    // Player management
    auto player = new Player(camera, engine.events);
    engine.systems.register(player);

    // Run main loop
    while (!win.stopping())
    {
        engine.run();
    }
}