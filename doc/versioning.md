ORB versioning rules
================

Stages
------

The development will go through different phases:
* dev - Prototyping, making the skeletton of the soft, nothing really special or to be shown.
* (prealpha) - The soft has no special features and is still under early devlopment, but it can be shown to close relatives or friends for test or demo purposes.
* alpha - The soft is mature enough and is ready to be shown adn tested to the outside world. Alot of features are missing.
* beta - A serious test phase, aiming to make the software shipable and safe to use, maybe ready for sale. Things are meant to be serious.
* (release candidate) - To be tested before proper release.
* release - Release of the software. It must be mature and - if possible - contain zero known bugs.

Versioning
----------

During the "dev" phase, the git "tags" will now have the following conventions:

`dev-X.Y.Z`

* X corresponds to the _version_ (as defined in _task.md_). Currently, it is 0 until a proper version can be shipped.
* Y corresponds to a _step_ (as defined in _task.md_).
* Z correspond to an improvement or bug-fixes upon a step.

Once the _prealpha_, _alpha_ or _beta_ gets ready, the _dev_ keyword will be replaced by the corresponding keyword.

It should basically follow the versioning as defined in http://semver.org/
