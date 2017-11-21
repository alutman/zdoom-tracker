tracker
=======
For ZDoom ports.

Provides a configurable kill/secrets/items counter;

Why? Not all huds support these counters and I don't like using the opaque map.

* Kill/secrets/items count
* Timer with par time
* Level names(s)
* Counts change color when full, timer changes colors as it approaches par time

See CVARINFO.txt for a list of options to configure

Dev
---
1. Compile `*.c` files with ACC
2. Package up all txt files and acc files to a zip
3. Rename zip to .pk3
4. Use like any doom addon

#### Misc
* Compiled with ACC 1.56 win
* Tested with GZDoom 3.2.1 and Zandorum 3.0

Changelog
---------
##### v1.1.0
* XY position options
* Fix par time of 0 bug
* Default to exclude par time

##### v1.0.0
* Initial version
