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
===================

Step 1 (testing step) done
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

Step 2 (terrain step) done
--------------------------

Done:
* Implement directional lighting.
* Improvement of marching-cube algo: generate normal vectors.
* Integrate mouse input, simple fly mode.
* Embryo of octree and terrain generation.
* Make proper rendering classes (fairly ready for integrating OpenGL3.3, or maybe Vulkan).
* Integrate proper fonts.
* Use some kind of benchmarking to check CPU load.
* Draw one chunk.
* Draw several chunks.
* Optimize chunk rendering (smaller mesh data per chunk).
* Start optimizing by loading and displaying only the visible chunks (notion rendering distance).
* Increase rendering distance as much as possible.
* Make sure cpu load is constant when travelling (bug in octree).
* Drop BallVoxelIterator, use a list of chunks to load/unload.
* Get rid of octree (red-black-tree of loaded chunks seems to be the solution).
* Do proper benchmark: load-chunk, build-mesh, data-structure overheads.
* Reduce chunk loading by not loading those that are invisible (below ground).
* Have a circular buffer of chunks.
* Optimize population time (the Generator class adds a lot of overhead, if I copy the ballGen function math function within Chunk.populate, chunk pop time decreases from 900µs to 600µs).
* Smooth blocks switching from binary density to a rational one.
* Launch an entity when clicking mouse left button.
* Apply gravity to entity (components: mass, velocity, position, collidable).
* Check entity collision.

Notes on current state: Ball radius=500Vx (or higher, it's ok), camera depth=40Vx (should be a lot higher). Camera movement speed = 1Vx/frame = 60Vx/s = 216kVx/h (in Minecraft a "sprint"=5.6m/s = 20km/h).


Step 3 (entities/physics)
-------------------------

Terrain optimization:
* Avoid vbo/vao generation, use older unused ones. Same for vertices.
* Optimize population time using OpenCL (check on a new dev-test branch).
* Optimize mesh time using OpenCL.
* Optimize mesh size using some way to have longest triangle strips.
* Implement 3D textures (done on branch dev-test-tesselate).
* Use different colors for various terrain soils.
* Implement LOD.
* Compress terrain features with binary space partitioning, per chunk.
* Improve LOD so that further entities still have full resolution LOD.

Physics:
* Implement walking on the ground (first person view).
* Jump.
* Have entities moving around.
* Have tree of elements.
* Collision of entities with terrain.
* Collision of entities with themselves.

GUI:
* Simple GUI (text/box widgets, KB/mouse control assignment, simple menu, debug toggle).
* Make a proper noise class (init function to fill the random table, with a seed).

Miscellaneous:
* Improve game-loop.
* Have an ambient light.
* Implement sky-box.
* Have a day/night cycle.



Step 4 (shadows/lights/rendering)
---------------------------------

* Basically implement nice shadows and dynamic lighting system.
* Implement sky-map.
* Make everything look pretty.

