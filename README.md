# LuaSTG Bullet Style Library

LuaSTG Bullet Style Library is a next-generation bullet encapsulation library for LuaSTG.

This library is written to follow the directive of separating following terms:
* Iteration (not implemented in this library but in Advanced Repeat in Sharp)
* Bullet Motion (decomposed into Motion Module and Motion Curve)
* Bullet Style

Most of these terms are expressed by tables in a fixed schema,
making bullets can be quickly modified both by human and coding.

**WARNING: THIS REPOSITORY IS CURRENTLY UNSTABLE,
SCHEMA OF THE TABLES MAY CHANGE OVER TIME**

# Installation
* Clone this repository
* Put this folder at `THlib/`
* Write the following code at the end of `THlib/THlib.lua`:
```
Include 'THlib\\[FOLDER NAME]\\StyleLib.lua'
```

# Dependencies
* LuaSTG object in LuaSTG Executable
* plus.Class

**Note: this library does not and will not support legacy LuaSTG Task**

# To-do List
* Handle the Event-like writting pattern, such as "after the bullet hit somewhere, begin to execute something".
This may be written in state-machine in the future.