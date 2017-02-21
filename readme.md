This set of script files is a Lua HUD for TASing Monster World IV.


## Index
1. Building
2. Using
4. Features
3. Changelog

## 1 Building
You need have a Unix environment with bash, plus Lua, GD tools (specifically,
png2gd) and 7z in order to build the HUD. If you have none of this, you can't
build it at the moment.

After installing all required tools, edit 'make.sh' so that the environment
variables it sets have the correct locations.

## 2 Using
Extract all the contents of the distributed package somewhere you like. Open a
supported ROM in Gens, then start 'mw4-hud.lua'.

## 3 Features
- **basic information display:**position (down to subpixels) and speed (for both
Asha and Pepe), hearts (including blue), life drops, gold, post-hit
invulnerability counter and Pepe's level.
- **infinite jump automation:** with Pepe one frame away from being grabbed,
leave A in auto-hold and hold down left mouse button on double arrow button as
you frame advance; Pepe will be once again one frame away from being grabbed,
and you can chain this. The sequence was chosen that maximizes average speed.
- **hitbox display:** shows collision box (in white), interaction box (in
various colors, generally smaller), Asha's sword hurtbox, the base offset of the
object (top two digits), hit counter and invulnerability timer (for enemies),
gold range (for gold) and collection delay (for general treasure, including gold).
- **jump prediction:** what Asha's speed will be like after pressing **C** for
the next two frames.
- **terrain solidity:** a colored overlay over the different solidity types.
Top solid = green, right solid = maroon, top and right solid = olive,
left solid = blue, top and left solid = teal, right and left solid = purple,
all but bottom solid = gray, all solid = white.

## 4 Changelog
**Jan 31/2017:**
* Forked from sonic-gens-hud.

