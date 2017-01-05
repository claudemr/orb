ORB - Benchmarks
================

CPU 1
-----

Nb cpu      : 4
Model name  : Intel(R) Core(TM) i5 CPU         650  @ 3.20GHz
CPU MHz     : 1199.000 3333.000 3333.000 1199.000
Cache size  : 4096 KB

GPU 1
-----

Detected OpenGL:
* Version: 3.0 Mesa 11.1.0-devel (git-dd05ffe 2015-11-18 trusty-oibaf-ppa)
* Vendor: X.Org
* Renderer: Gallium 0.4 on AMD RV710 (DRM 2.36.0, LLVM 3.6.2)
* GLSL version: 1.30

CPU 2
-----

Nb cpu      : 2
Model name  : AMD Phenom(tm) II X2 555 Processor
CPU MHz		: 3210.967
Cache size	: 512 KB

GPU 2
-----

Detected OpenGL:
* Version: 4.4.13374 Compatibility Profile Context 15.20.1013
* Vendor: ATI Technologies Inc.
* Renderer: AMD Radeon HD 5800 Series
* GLSL version: 4.40

Benchmarks
==========

Tag: v0.2.0-dev11

Comments
--------

Unloading of chunks does not take much time (_Unld_ benchmark proves it).
Chunk loading management has been greatly improved using a red-black tree. All operation are done O(log n) instead of the O(n) insertion.

Now, chunk "population" and "mesh" have to be optimized. But it means we should rather think about the chunk data structure for storing blocks and think ahead about multi-element management.


On CPU1:
--------

Loaded chunks: 258 (unload: 0)
  Mng stats:  16µs(30µs) [0 144]
  Unld stats:  0µs(0µs) [0 0]
  Pop stats:  989µs(372µs) [483 2089]
  Mesh stats: 1198µs(628µs) [108 3347]
All: 16602µs (2936|26463)
    - TerrainSystem@5200: 1409µs (2|12834)
    - RenderSystem@b300: 1191µs (18|1938)

Playback start
Loaded chunks: 258 (unload: 0)
  Mng stats:  1µs(0µs) [0 4]
  Unld stats:  0µs(0µs) [0 0]
  Pop stats:  0µs(0µs) [0 0]
  Mesh stats: 0µs(0µs) [0 0]
All: 16670µs (12782|19405)
    - TerrainSystem@5200: 3µs (1|6)
    - RenderSystem@b300: 1519µs (602|2616)

Loaded chunks: 262 (unload: 26)
  Mng stats:  6µs(85µs) [1 1484]
  Unld stats:  160µs(0µs) [160 160]
  Pop stats:  512µs(2µs) [508 516]
  Mesh stats: 841µs(583µs) [468 3914]
All: 16909µs (13282|86095)
    - TerrainSystem@5200: 238µs (2|70175)
    - RenderSystem@b300: 1361µs (628|2384)

Loaded chunks: 396 (unload: 100)
  Mng stats:  37µs(191µs) [1 1686]
  Unld stats:  131µs(23µs) [98 160]
  Pop stats:  833µs(390µs) [486 1982]
  Mesh stats: 898µs(532µs) [69 4748]
All: 17543µs (6250|84784)
    - TerrainSystem@5200: 1994µs (2|68646)
    - RenderSystem@b300: 1315µs (560|2607)

Loaded chunks: 533 (unload: 96)
  Mng stats:  45µs(221µs) [1 2048]
  Unld stats:  187µs(29µs) [148 222]
  Pop stats:  895µs(398µs) [487 2064]
  Mesh stats: 968µs(527µs) [107 3549]
All: 17553µs (3655|86775)
    - TerrainSystem@5200: 2273µs (2|70804)
    - RenderSystem@b300: 1472µs (620|2640)

Loaded chunks: 799 (unload: 166)
  Mng stats:  63µs(266µs) [1 2402]
  Unld stats:  252µs(49µs) [168 287]
  Pop stats:  961µs(396µs) [489 2108]
  Mesh stats: 1094µs(777µs) [116 6840]
All: 17718µs (3334|83569)
    - TerrainSystem@5200: 2978µs (3|67305)
    - RenderSystem@b300: 1624µs (722|2515)

Loaded chunks: 994 (unload: 251)
  Mng stats:  71µs(314µs) [1 2956]
  Unld stats:  377µs(68µs) [290 460]
  Pop stats:  1003µs(430µs) [484 2067]
  Mesh stats: 1030µs(665µs) [186 5809]
All: 17543µs (6906|87186)
    - TerrainSystem@5200: 2758µs (2|71459)
    - RenderSystem@b300: 1927µs (787|3640)

Loaded chunks: 1160 (unload: 442)
  Mng stats:  73µs(322µs) [1 4127]
  Unld stats:  470µs(11µs) [458 485]
  Pop stats:  991µs(394µs) [483 1955]
  Mesh stats: 1096µs(778µs) [151 7803]
All: 17248µs (6191|86017)
    - TerrainSystem@5200: 2659µs (2|70398)
    - RenderSystem@b300: 2151µs (887|3765)

Loaded chunks: 1163 (unload: 435)
  Mng stats:  68µs(237µs) [1 2378]
  Unld stats:  455µs(31µs) [416 493]
  Pop stats:  975µs(392µs) [489 1793]
  Mesh stats: 1130µs(885µs) [73 7738]
All: 17680µs (4370|67671)
    - TerrainSystem@5200: 2744µs (2|52005)
    - RenderSystem@b300: 2397µs (1151|4341)

Loaded chunks: 1162 (unload: 413)
  Mng stats:  73µs(314µs) [1 3762]
  Unld stats:  522µs(21µs) [497 550]
  Pop stats:  985µs(386µs) [483 2048]
  Mesh stats: 1078µs(758µs) [112 7128]
All: 18394µs (5464|75728)
    - TerrainSystem@5200: 2837µs (2|55951)
    - RenderSystem@b300: 2475µs (1005|4777)

Loaded chunks: 1249 (unload: 407)
  Mng stats:  85µs(310µs) [1 3197]
  Unld stats:  604µs(42µs) [552 656]
  Pop stats:  1026µs(419µs) [484 2174]
  Mesh stats: 1043µs(777µs) [91 7815]
All: 19062µs (7474|85948)
    - TerrainSystem@5200: 3218µs (3|66780)
    - RenderSystem@b300: 2511µs (1160|4897)

Loaded chunks: 1283 (unload: 394)
  Mng stats:  74µs(300µs) [1 3019]
  Unld stats:  464µs(81µs) [355 549]
  Pop stats:  1043µs(421µs) [486 2040]
  Mesh stats: 1140µs(940µs) [66 7390]
All: 18990µs (6898|81091)
    - TerrainSystem@5200: 3157µs (2|66973)
    - RenderSystem@b300: 2541µs (1216|4153)

Loaded chunks: 1174 (unload: 197)
  Mng stats:  47µs(256µs) [1 3320]
  Unld stats:  432µs(64µs) [368 496]
  Pop stats:  1004µs(393µs) [493 1778]
  Mesh stats: 1024µs(680µs) [115 3252]
All: 17221µs (4930|79650)
    - TerrainSystem@5200: 1633µs (3|60561)
    - RenderSystem@b300: 2576µs (1236|4519)

Loaded chunks: 980 (unload: 0)
  Mng stats:  3µs(25µs) [0 392]
  Unld stats:  0µs(0µs) [0 0]
  Pop stats:  0µs(0µs) [0 0]
  Mesh stats: 0µs(0µs) [0 0]
All: 16749µs (14469|34279)
    - TerrainSystem@5200: 6µs (1|394)
    - RenderSystem@b300: 2209µs (1164|3226)

Loaded chunks: 980 (unload: 0)
  Mng stats:  1µs(0µs) [0 2]
  Unld stats:  0µs(0µs) [0 0]
  Pop stats:  0µs(0µs) [0 0]
  Mesh stats: 0µs(0µs) [0 0]
All: 16732µs (8731|26594)
    - TerrainSystem@5200: 3µs (2|6)
    - RenderSystem@b300: 2136µs (890|3350)

