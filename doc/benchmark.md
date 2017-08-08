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

Tag: v0.2.0-dev13

Comments
--------

Smooth voxels are successfully now implemented.

However, as expected, the meshing layer takes 2.5x as much time as before.

The IMesh interface has been changed so we can add vertices and faces one by one, but this could be improved a lot. Some architecture rework could be done as well in the chunk buildMesh() (quite big now).

Previous notes:
We can also use a chunk size of 32, so the ratio between face voxels and the whole chunk voxels is lower (and so is the populating redundancy).

The unloading could also be improved.

After all that is done, maybe we can study LOD management.

On CPU1:
--------

Loaded chunks: 266 (unload: 0)
  Mng stats:  44µs(422µs) [0 7273]
  Unld stats:  0µs(0µs) [0 0]
  Pop stats:  849µs(350µs) [472 1962]
  Mesh stats: 2146µs(1830µs) [303 18278]
All: 16851µs (7297|39365)
    - TerrainSystem@7200: 1885µs (1|25400)
    - RenderSystem@d300: 1484µs (72|2862)

Loaded chunks: 266 (unload: 0)
  Mng stats:  0µs(1µs) [0 6]
  Unld stats:  0µs(0µs) [0 0]
  Pop stats:  0µs(0µs) [0 0]
  Mesh stats: 0µs(0µs) [0 0]
All: 16955µs (4229|34702)
    - TerrainSystem@7200: 3µs (1|8)
    - RenderSystem@d300: 1617µs (664|3021)

Loaded chunks: 292 (unload: 26)
  Mng stats:  8µs(90µs) [0 1519]
  Unld stats:  97µs(0µs) [97 97]
  Pop stats:  692µs(333µs) [473 1400]
  Mesh stats: 1635µs(1779µs) [313 18813]
All: 17251µs (8735|135663)
    - TerrainSystem@7200: 688µs (1|119689)
    - RenderSystem@d300: 1524µs (650|2877)

Loaded chunks: 410 (unload: 102)
  Mng stats:  42µs(206µs) [0 1700]
  Unld stats:  122µs(8µs) [111 134]
  Pop stats:  747µs(318µs) [472 1439]
  Mesh stats: 1757µs(2337µs) [288 33011]
All: 19170µs (5125|144949)
    - TerrainSystem@7200: 3450µs (1|129376)
    - RenderSystem@d300: 1656µs (742|3125)

Loaded chunks: 545 (unload: 101)
  Mng stats:  159µs(1818µs) [0 29414]
  Unld stats:  210µs(21µs) [183 242]
  Pop stats:  790µs(335µs) [474 1852]
  Mesh stats: 1700µs(1501µs) [278 27774]
All: 18946µs (4071|159867)
    - TerrainSystem@7200: 3741µs (0|144039)
    - RenderSystem@d300: 1661µs (703|3448)

Loaded chunks: 760 (unload: 171)
  Mng stats:  180µs(1970µs) [0 32024]
  Unld stats:  235µs(25µs) [196 267]
  Pop stats:  814µs(358µs) [473 1475]
  Mesh stats: 1832µs(1965µs) [278 35381]
All: 18769µs (5367|133792)
    - TerrainSystem@7200: 4087µs (1|118247)
    - RenderSystem@d300: 1767µs (830|3621)

Loaded chunks: 1000 (unload: 207)
  Mng stats:  221µs(2469µs) [0 40794]
  Unld stats:  378µs(24µs) [348 407]
  Pop stats:  868µs(348µs) [473 1790]
  Mesh stats: 1909µs(2044µs) [275 33318]
All: 18222µs (5472|170516)
    - TerrainSystem@7200: 3873µs (1|155038)
    - RenderSystem@d300: 2019µs (908|4299)

Loaded chunks: 1190 (unload: 327)
  Mng stats:  60µs(264µs) [1 2967]
  Unld stats:  450µs(25µs) [431 487]
  Pop stats:  879µs(389µs) [471 1975]
  Mesh stats: 1800µs(2453µs) [276 40252]
All: 17932µs (2651|127493)
    - TerrainSystem@7200: 3346µs (2|112696)
    - RenderSystem@d300: 2408µs (1077|5060)

Loaded chunks: 1324 (unload: 458)
  Mng stats:  72µs(238µs) [1 2529]
  Unld stats:  462µs(65µs) [378 539]
  Pop stats:  898µs(391µs) [473 1967]
  Mesh stats: 1897µs(3023µs) [274 49542]
All: 18331µs (5795|136915)
    - TerrainSystem@7200: 3758µs (1|121110)
    - RenderSystem@d300: 2654µs (1231|5305)

Loaded chunks: 1312 (unload: 437)
  Mng stats:  65µs(253µs) [1 2713]
  Unld stats:  499µs(98µs) [360 575]
  Pop stats:  866µs(351µs) [474 1852]
  Mesh stats: 1689µs(1310µs) [275 6503]
All: 18459µs (4222|97104)
    - TerrainSystem@7200: 3389µs (1|80935)
    - RenderSystem@d300: 2940µs (1431|5769)

Loaded chunks: 1278 (unload: 419)
  Mng stats:  67µs(292µs) [1 3087]
  Unld stats:  470µs(127µs) [361 650]
  Pop stats:  895µs(390µs) [473 1983]
  Mesh stats: 1823µs(3564µs) [273 59117]
All: 19040µs (4213|118571)
    - TerrainSystem@7200: 3425µs (2|103362)
    - RenderSystem@d300: 3025µs (1339|5639)

Loaded chunks: 1335 (unload: 519)
  Mng stats:  83µs(337µs) [1 3194]
  Unld stats:  550µs(69µs) [444 640]
  Pop stats:  855µs(384µs) [473 1974]
  Mesh stats: 1768µs(2941µs) [275 54689]
All: 19361µs (5745|166464)
    - TerrainSystem@7200: 4317µs (2|150417)
    - RenderSystem@d300: 3024µs (1453|5834)

Loaded chunks: 1187 (unload: 200)
  Mng stats:  50µs(254µs) [1 3130]
  Unld stats:  527µs(54µs) [473 582]
  Pop stats:  948µs(379µs) [473 1960]
  Mesh stats: 1758µs(1301µs) [274 7045]
All: 17714µs (8621|103017)
    - TerrainSystem@7200: 2524µs (2|86654)
    - RenderSystem@d300: 3108µs (1383|5414)

