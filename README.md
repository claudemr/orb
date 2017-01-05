ORB
===

3D engine work to display voxelized planets.

Programming language: **D**

Graphic/multimedia library: **SDL2.0**

OpenGL version: **3.0** *(GLSL: 1.30)*

Developer installation
======================

On a freshly installed Debian based GNU/linux system.

General tools
-------------

```
sudo apt-get install git gitk libcurl3
```

SDL2 resources
-------------

```
sudo apt-get install libsdl2-2.0-0 libsdl2-gfx-1.0-0 libsdl2-image-2.0-0 libsdl2-mixer-2.0-0 libsdl2-net-2.0-0 libsdl2-ttf-2.0-0
```

D resources
-----------

DMD compiler:
> http://dlang.org/download.html

DUB build tool, package manager:
> http://code.dlang.org/about

Install rpm files:
```
sudo apt-get install alien dpkg-dev debhelper build-essential
# For Debian 64-bit
sudo alien --target=amd64 dub_x.x.x-x_arch.rpm
# For Debian 32-bit
sudo alien --target=i386 dub_x.x.x-x_arch.rpm
sudo alien dub_x.x.x-x_arch.rpm
sudo dpkg -i dub_x.x.x-x_arch.deb
```

Or else copy `dub` in `usr/bin`
