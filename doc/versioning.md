ORB versioning rules
====================

Phases
------

The development will go through different phases:
* dev - Prototyping, making the skeletton of the soft, nothing really special or to be shown.
* (prealpha) - The soft has no special features and is still under early devlopment, but it can be shown to close relatives or friends for test or demo purposes.
* alpha - The soft is mature enough and is ready to be shown adn tested to the outside world. Alot of features are missing.
* beta - A serious test phase, aiming to make the software shipable and safe to use, maybe ready for sale. Things are meant to be serious.
* release - Release of the software. It must be mature and - if possible - contain zero known bugs (use "release candidate" - To be tested before proper release).

Versioning
----------

The previous versionning scheme does not really make sense. The "phase" should be the first item in the version tag.

The git "tags" will have the following conventions (as defined in http://semver.org/):

`vX.Y.Z`

* X corresponds to the phase of the project. "0" means the project is still in "dev" state. Once the project is in a more stable shape, the X number may be incremented
* Y corresponds to the _step_ (as defined in _task.md_).
* Z is incremented once a _feature_ is added (as defined in the list of each steps in _task.md_).

