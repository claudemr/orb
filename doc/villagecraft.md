Village Craft
============

Ideas for a Village AI (could be a plugin of Minecraft).

Ideas
-----

Bukkit plugin API wiki for Minecraft:
http://wiki.bukkit.org/Plugin_Tutorial

Requirements
------------

This Village AI works in a sandbox 2D/3D world (like Minecraft).

It requires a "world" with blocks (voxels) and resources.
Resources may be things like trees, water, stone, coal, iron etc.

This world would be populated with one or several concurrent/cooperative villages.
Villages are habited with villagers, that may perform tasks like breed, gather resources, build houses, make tools etc.
Villages are meant to grow, thus requiring more natural resources, and expand their territories. They also may conflict with each other.
If the world is unlimited (like Minecraft), the villages may grow endlessly (which may not be a good idea in term of memory/cpu resource consumption). Otherwise, they will be limited by space, so have limited resources, and therefore may have to fight against each other.

Several classes:
* Village class
* Villager class
* Building class

Village class
-------------


    class Village
    {
        Coord villageCenter;
        List villagers;          // List of villagers belonging to the village
        List buildings;          // List of buildings belonging to the village
        List resourcesAvailable; // with if of villagers/building where the resource may be found
        List resourcesRequired;	 // with urgency in the requirement
        List skillsRequired;     // with urgency in the requirement
        List buildingsRequired;  // with urgency in the requirement
        List feelings;           // feelings about other villages
    };

The `feelings` globally grow if the village goes well, or get negative if the village naturally struggles.
A specific feeling may change toward another village, positively if some trades are successfully performed, or negatively if a village attacks another.
