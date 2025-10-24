# 3D Particle System Player <!-- omit from toc -->

Spawn and manually play any effect from 3D Particle System Base

## Table of Contents <!-- omit from toc -->

- [Description](#description)
  - [Features](#features)
  - [Rational](#rational)
- [Disclaimer](#disclaimer)
- [Pull Requests](#pull-requests)

## Description

![preview](/media/preview.png)

This adds the "3D Particle System Player" tool, which allows you to spawn 3D Particle Systems (3DPs) from any addon which contains them.

### Features

- **Particle System explorer**: 3DPs are categorized by addon. If 3DPs exist in the data folder, those will be listed, too
  - The user can refresh the explorer to add new particle systems without reloading the server
- **Play on keypress**: The user can bind a key to play a 3DP. Naturally, the animator can control 3DPs with this tool
- **More playback controls**: Similar to the Advanced Particle Controller, any 3DP spawned by this tool can loop playback
- **Dupe/save support (NOT TESTED)**: The user can return to a session of 3DPs and still play them back
- **Familiar UI**: The UI closely resembles the Advanced Particle Controller

### Rational

As of October 23, 2025, no tool exists which allows the user to spawn *and* control 3DPs. While the 3D Particle Effects Editor allows the user to create and play back their 3DPs, it cannot arbitrarily spawn them. This tool exists to improve from these drawbacks.

This tool was intentionally developed for animators (and postermakers) to control the playback of 3DPs.

## Disclaimer

**This tool has been tested in singleplayer.** Although this tool may function in multiplayer, please expect bugs and report any that you observe in the issue tracker.

## Pull Requests

When making a pull request, make sure to confine to the style seen throughout. Try to add types for new functions or data structures. I used the default [StyLua](https://github.com/JohnnyMorganz/StyLua) formatting style.
