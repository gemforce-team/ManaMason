# ManaMason

## Description
ManaMason is a game modification for GCFW.

It allows you to quickly place arbitrary groups of structures, spending mana accordingly. These groups are loaded from blueprints that you specify. Building ghosts are displayed for ease of use when you are in building mode.

![Like so](https://i.imgur.com/pSykXwo.png)
![Another example](https://i.imgur.com/T5cqKv6.png)

Starting with v1.1 you can also specify gems to automatically create and socket into your buildings! This also supports Gemsmith recipes. Check **Detailed features** below for more information!

This is a time saving and QOL mod, exactly the same results can be achieved without it. Mana expenditure stats and achievements should be tracked appropriately, [submit an issue](https://github.com/gemforce-team/ManaMason/issues) if you find that something's off!


## Changelog
https://github.com/gemforce-team/ManaMason/blob/master/Changelog.txt


## Known issues
* Rotating\flipping the blueprints is a bit weird
* Hotkeys aren't configurable
* Line endings are expected to be system-appropriate (\r\n for Windows, \n for Linux and MacOS)


# Mod files
ManaMason keeps all its files in the game's Local Store folder. It's located in `%AppData%\com.giab.games.gcfw.steam\Local Store\ManaMason` and it's generated on first launch.

That folder is referred to as **ManaMason folder** in this readme.


## Features
* You can create blueprints that specify the type and position of structures. Every buildable structure can be placed with ManaMason. These blueprints are defined in a certain format, detailed further below.

* The blueprints are loaded from a `blueprints` folder in your ManaMason folder, you can have as many as you need and switch between them with hotkeys. 

* Only buildings that you have unlocked (either have the skill or allowed in your current trial) are placeable, no cheating!

* You can specify gems to be socketed into your buildings

* Press Ctrl + `R` to **reload your blueprints**.

* ManaMason keeps a log of the last session in `%AppData%\com.giab.games.gcfw.steam\Local Store\Bezel Mod Loader\Bezel_log.log`. If you see a floating message saying that an error has occured, there might be more information in there.


## Installing the mod
### Important warning! ManaMason depends on [Bezel Mod Loader](https://github.com/gemforce-team/BezelModLoader).

**To install the mod** grab a release (links below) for your game version. Drop `ManaMason-x.x-for-y.y.y.swf` into the `Mods` folder in the game's folder (To navigate to the game's folder: rightclick the game in steam -> Manage -> Browse local files).

**If there is no `Mods` folder**, you need to first install Bezel Mod Loader (link above).


# Uninstalling the mod
Delete `ManaMason-x.x-for-y.y.y.swf` from the `Mods` folder.


## Releases
[Link to the latest release](https://github.com/gemforce-team/ManaMason/releases/latest)

Release history: [Releases](https://github.com/gemforce-team/ManaMason/releases)


# Detailed features
## Blueprints
Inside your ManaMason folder you'll find a `blueprints` subfolder. There you can store `.txt` files that hold your blueprints.

Expected blueprint format is:
* A rectangular grid of lowercase letters:
```
'-' - air
'a' - amplifier
't' - tower
'l' - lantern
'p' - pylon
'w' - wall
'r' - trap
```
* All 2x2 structures should be represented by a 2x2 of letters

* One line per line of game tiles

* The blueprint may be followed by lines describing gems to be socketed into your buildings. See below for the format.


**Gem section should be structured as follows:**
```
Gems:
Id=[y|yellow,o|orange,r|red,p|purple,g|green,b|blue] grade [targetPriorityId] [rangePercentage]
Id=[y|yellow,o|orange,r|red,p|purple,g|green,b|blue] gs grade recipeName [targetPriorityId] [rangePercentage]
Id=[inv|inventory] inventorySlot [targetPriorityId] [rangePercentage]
```

An example blueprint will be generated in the `blueprints` folder on first launch, another example (including gems) below:
```
aaaaaa--
010201ww
--rr----
--03----
aaaaaaww
aaaaaa--
aattaa--
aa04aa--
Gems:
01=y,gs,11c,0,2,0.1
02=red,4,3
03=inv,0
04=inventory,1,4,0.1
```
TargetPriorityIds:
```
Nearest to orb = 0;   
Swarmlings = 1;
Giants = 2;
Random = 3;
Structure \ Least affected by specials = 4;
Highest banishment cost \ Special = 5;
Shielded \ Highest armor = 6;
Least hit points = 7;
```
Which results in
![Before](https://i.imgur.com/oXw4rbA.jpg)
![After](https://i.imgur.com/UGqFqTE.jpg)

Notice the conjured gems \ gems moved from the inventory.

**Pylon target priority is set in the blueprint part, instead of a gem id you specify the target priority id directly**
```
pppppp
0102pp
```
So the first two have a custom target priority, the last one is set to default, these are not gem ids since pylons can't hold gems. You can't adjust their range either so that's out as well.

## Hotkeys
By default ManaMason's hotkeys are:
```
Insert - enter\exit building mode
PageUp or UpArrow - previous blueprint
PageDown or DownArrow - next blueprint
R - rotate blueprint
F - flip blueprint horizontally
V - flip blueprint vertically
Ctrl + R - reload blueprints
```
Rebinding isn't available yet.


# Bug reports and feedback
Please submit an issue to [The issue tracker](https://github.com/gemforce-team/ManaMason/issues) if you encounter a bug and there isn't already an open issue about it.

You can find me on GemCraft's Discord server: https://discord.gg/ftyaJhx - Hellrage#5076


# Disclaimer
This is not an official modification.

GemCraft - Frostborn Wrath is developed and owned by [gameinabottle](http://gameinabottle.com/)


# Credits
ManaMason is developed by Hellrage

**Special thanks to**

12345ieee and Bill Wilson for helping with testing, ideas
