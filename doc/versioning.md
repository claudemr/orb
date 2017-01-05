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

During the "dev" phase, the git "tags" will have the following conventions:

`0.X.Y-devZ`

* X corresponds to the _step_ (as defined in _task.md_).
* Y corresponds to different bug fixes upon a _step_.
* Z is incremented once a _feature_ is added (as defined in the list of each steps in _task.md_). It may be of the form _A.B_ with B being a number starting from 1, used to indicate bug-fixes.

Once the _prealpha_, _alpha_ or _beta_ gets ready, the _dev_ keyword will be replaced by the corresponding keyword.

For releases, the `-betaZ` is dropped and proper versioning as defined in http://semver.org/ is used.
For release-candidate, the version will be in the form `X.Y.Z-rcW`
