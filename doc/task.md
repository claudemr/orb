ORB - Main targets
==================

Version 1
---------

Main goals:
* Rendering based on OpenGL3.0 - voxel world. High precision, far rendering. No texture, light, proper shadows.
* World generated as a ball (with noise for terrain features)
* Basic physic engine, collision detection.
* Can walk, jump, fly.
* Have entities that move around (simple movement).
* Have a GUI.
* Basic particle system, billboards etc.

Version 2
---------

Main goals:
* Client/server architecture.
* Multiplayer features.
* Allow to dig and fill terrain, have items. (Crafting?)
* AI for entities, can move around.
* Water, fluid handling, proper physics.
* (Building system?)

Version 3
---------

Main goals:
* Integrate Villagecraft ideas? Implement AI's... Make a proper game anyway...

ORB - Work Progress
==================

Step 1 (Testing step) done
--------------------------

* Cube drawn with OpenGL3.0 and SDL2.0 with D language, using Derelict binding library.
* Some basic class made around some OpenGL calls (Hardware Buffer, Shader management).
* Matrix, vector tools done.
* Camera class added.
* OpenGL Exception class.
* Make the basis of a scene manager.
* Allow to have some text overlays.
* Integrate a FPS counter.
* Make a "marching-cube" algorithm generator.
* Implement noise function.

Step 2 (terrain step) in progress
---------------------------------

Done:
* Implement directional lighting.
* Improvement of marching-cube algo: generate normal vectors.
* Integrate mouse input, simple fly mode.
* Embryo of octree and terrain generation.
* Make proper rendering classes (fairly ready for integrating OpenGL3.3, or maybe Vulkan).
* Integrate proper fonts.
* Use some kind of benchmarking to check CPU load.

Todo:
* Octree/terrain rendering:
  1. ~~Draw one chunk.~~
  2. ~~Draw several chunks.~~
  3. ~~Optimize chunk rendering (smaller mesh data per chunk).~~
  4. ~~Start optimizing by loading and displaying only the visible chunks (notion rendering distance).~~
  5. ~~Increase rendering distance as much as possible.~~
  6. ~~Make sure cpu load is constant when travelling (bug in octree).~~
  7. ~~Drop BallVoxelIterator, use a list of chunks to load/unload.~~
  8. ~~Get rid of octree (red-black-tree of loaded chunks seems to be the solution).~~
  9. ~~Do proper benchmark: load-chunk, build-mesh, data-structure overheads.~~
  10. ~~Reduce chunk loading by not loading those that are invisible (below ground).~~
  11. ~~Have a circular buffer of chunks.~~

Current state (vx=voxel): Ball radius=500vx (or higher, it's ok), camera depth=40vx (should be a lot higher). Camera movement speed = 1vx/frame = 60vx/s = 216kvx/h (in Minecraft a "sprint"=5.6m/s = 20km/h).

More todo:
* Terrain rendering optimization:
  1. Avoid vbo/vao generation, use older unused ones. Same for vertices.
  2. Optimize population time (the Generator class adds a lot of overhead, if I copy the ballGen function math function within Chunk.populate, chunk pop time decreases from 900µs to 600µs).
  3. Optimize population time using parallelism on several CPU cores?
  4. Optimize mesh number of points/normals/indices by using those that are shared across voxels.
  5. Smooth blocks switching from binary density to a rational one.
  6. Implement 3D textures.
* Improve game-loop.

Background work
---------------

* Simple GUI (text/box widgets, KB/mouse control assignment, simple menu, debug toggle).
* Make a proper noise class (init function to fill the random table, with a seed).
* Improve terrain generation.

Step 3 (entities/physics)
-------------------------

* Basic physic engine, collision detection.
* Can jump, fly.
* Have entities moving around.

Step 4 (shadows/lights/rendering)
---------------------------------

* Basically implement nice shadows and dynamic lighting system.
* Implement sky-map.
* Make everything look pretty.

