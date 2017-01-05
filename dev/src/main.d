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

import controller;
import orb.engine;


class LightSystem : System
{
public:
    this(Scene scene)
    {
        mInitLight = vectorf(0.0f, 0.0f, 1.0f, 0.0f);
        mDirLightx = mDirLighty = 0.0f;
        mLight = scene.createDirLight(mInitLight,
                                      color4(0xFF_FF_90_FF));

    }

    override void run(EntityManager entities, EventManager events, Duration dt)
    {
        import std.math : PI;
        import dlib.math.affine;
        import dlib.math.utils;
        Matrix4f matRotLight;

        mDirLightx += PI / 60 / 2;
        mDirLighty += PI / 110 / 2;
        matRotLight = rotationMatrix(Axis.y, mDirLighty)
                    * rotationMatrix(Axis.x, mDirLightx);
        mLight.direction = mInitLight * matRotLight;
    }

private:
    immutable Vector4f mInitLight;
    float mDirLightx, mDirLighty;
    DirLight mLight;
}

struct BallGen
{
public
    this(Vector3f o, float radius)
    {
        mCenter = o;
        mRadius = radius;
    }

    float opIndex(int x, int y, int z)
    {
        Vector3f p = vectorf(x, y, z);
        p = p - mCenter;
        import orb.utils.math : sqrt;
        return mRadius - sqrt(p.lengthsqr);
    }

private:
    Vector3f mCenter;
    float    mRadius;
}


void main()
{
    enum uint vpWidth   = 640;
    enum uint vpHeight  = 480;
    enum int  planetRadius = 500;
    enum int  worldSize    = 1024;
    static assert(planetRadius * 2 < worldSize);

    // ORB Engine init
    auto engine = Engine.singleton;

    // Renderer init
    auto renderSys = engine.createRenderSystem();

    auto win = renderSys.createWindow("Orb",                // title
                                      10, 10,               // position
                                      vpWidth, vpHeight,    // width/height
                                      color3(0x00_00_70));  // background color

    import orb.opengl.gl30.meshrenderer;
    import orb.opengl.gl30.textrenderer;
    renderSys.renderer!IMesh = new Gl30MeshRenderer(import("scene_vertex.glsl"),
                                                    import("scene_fragment.glsl"));
    renderSys.renderer!ITextMesh = new Gl30TextRenderer(import("text_vertex.glsl"),
                                                        import("text_fragment.glsl"));

    // Scene/camera preparation
    auto scene = engine.createScene();

    auto camera = scene.createCamera();
    camera.position = vectorf(worldSize/2,
                              worldSize/2,
                              worldSize/2 - planetRadius - 10);
    camera.fov   = 45.0;
    camera.ratio = cast(float)vpWidth / vpHeight;
    camera.near  = 0.1;
    camera.far   = 40.0;

    camera.lookAt(vectorf(worldSize/2, worldSize/2, worldSize/2));

    // Manage directional light
    auto lightSys = new LightSystem(scene);
    engine.systems.register(lightSys);

    // Generate terrain features (just a ball)
    auto ball = BallGen(vectorf(worldSize/2, worldSize/2, worldSize/2),
                        planetRadius);
    auto generator = new Generator;

    generator.register(&ball.opIndex);
    scene.terrain = new Terrain(generator,
                                worldSize);

    // Prepare viewport for the scene, and canvas for the GUI
    win.attach(new Viewport(scene, camera));

    auto canvas = new Canvas;
    win.attach(canvas);

    // Load the font and make a text
    auto font = new Font("font/ubuntu_mono.fnt");
    renderSys.renderer!ITextMesh.load(font);

    auto text = new GuiText("Hello world!", font, 0.1,
                            vectorf(0.25f, 0.25f), vectorf(0.5f, 0.5f),
                            Yes.Wrap, AlignmentH.left, AlignmentV.top);
    text.color = color3(0xA0_80_10);
    //canvas.attach(text);

    // Input management
    auto controller = new Controller(engine.createInputSystem(win));
    engine.systems.register(controller);

    // Run main loop
    while (!win.stopping())
    {
        engine.run();
    }
    // http://gameprogrammingpatterns.com/game-loop.html
    // http://entropyinteractive.com/2011/02/game-engine-design-the-game-loop/
}