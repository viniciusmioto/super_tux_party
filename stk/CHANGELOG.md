# Releases

## Alpha Version - v0.9 - 2021-04-19

### Improved / Changed
- Redesigned the minigame end screen
- New cake design
- Enabled hidpi support
- Add a timer for Dungeon Parkour and Forest Run
- Fix AI getting stuck in Escape from Lava minigame
- Minigame QoL changes:
	- Decreased the time for plant selection in "Harvest Food" minigame from 10 seconds to 8 seconds
	- Spawn less Bombs in "Boat Rally" minigame
	- Added pre-start countdown in "Escape from Lava", "Harvest Food" and "Hurdle" minigames
	- Updated minigame screenshots
	- Provide better default keybindings
- Fixed Beastie's and Godette's character model clipping into the ground
- Screenshot creation on Windows works now
- New Main Menu design and animations
- New Pre-minigame screen
- UI theme improvements
- Credits menu now properly obeys the theme
- Fixed "Harvest Food" minigame listing the ability to jump, while the minigame doesn't allow it
- Show the controls to flip a card in the "Memory" minigame
- Reworked the "Kernel compiling minigame"
	- The visual style now matches the desired cartoony look
	- In the 2v2 version, team players now fill the same bar instead of seperate bars
- Player icons now show up correctly in the "Memory" minigame
- Fixed some buggy behavior when flipping a card faceup in the "Memory" minigame
- The "Memory" minigame now does not return instantly to the minigame end screen, but gives you a bit of time to look at the stats
- Use Liberation Sans instead of Noto Sans as fallback font
- Show the total number of turns on the board
- The Background music on the test board loops now
- The game now plays a sound when you pass a space on the board

## Alpha Version - v0.8 - 2020-11-02

### New features

- Screenshot key (Default: F2)
- Show licenses for shaders in the credits screen
- New 2v2 minigame: Memory
  - Find matching card pairs!
- Added Sarah as the boards' host
  - Gives tutorial on first start, explaining the basic mechanics
    - Can be skipped
  - Announces what happens on the board (e.g. the cake is bought and moves to another space)
- Translation progress from our project on [Hosted Weblate](hosted.weblate.org/projects/super-tux-party)
  - Added Translation for Norwegian Bokmål (98% complete) to the game
  - Added Translation for Russian (100% complete) to the game
  - Added Translation for Turkish (100% complete) to the game

### Improved / Changed

- Lots of visual improvements
  - New Harvest Food minigame background
  - Added furniture to Haunted Dreams minigame
  - Added a bowling alley theme to the Bowling minigame
    - Boxes fall from the sky, stunning players hit, while also blocking the bowling ball
    - Easier movement controls for the solo player
  - Better and gamepad type agnostic control icons
  - Cell shaded everything
  - Hexagon board spaces
  - New character splash art
  - Fixed floating spaces on the KDEValley board
  - Better Shop UI
- Reorganized the control mapping menu
  - Makes it easier to navigate the options with a gamepad
- Fixed a bug that caused newly added human players to become AI players after leaving and starting a new game
- The randomization algorithms avoids playing the same minigame multiple times in a row
  - Doesn't work between sessions
- The main menu music now starts to play _after_ the audio volume options are loaded

## Alpha Version - v0.7 - 2020-04-01

### New features

- Added loading screens
- Added music to "Haunted Dreams" minigame
- Added Graphic options
  - Requires game restart
- Added victory screen with game summary
- Added 3 new minigame types:
  - Gnu Solo: Single player challenge that is rewarded with an item
  - Nolok Solo: Single player challenge to avoid a cake getting stolen
  - Nolok Coop: All players have to work together to win the minigame or loose 10 cookies each
- Added 3 new minigames:
  - Forest Run: Jump and run platformer (Gnu Solo minigame)
  - Dungeon Parcour: Jump and run platformer (Nolok Solo minigame)
  - Boat Rally: Steer a boat through rocks and avoid getting hit by falling bombs (Nolok Coop)
- Added Credits screen

### Improved / Changed

- Smoother player movement on boards
- Fixed roll button not clickable
- Fixed missing translations
- Improved outlines when selecting items/players
- Better dirt texture
- Cakes don't respawn at the same location (if possible)
- Fixed the ai diffculty setting in savegames
- Saving when prompted with a minigame will no longer skip said minigame after loading
- Fixed crash when loading the "Haunted Dreams" minigame
- Fixed the board turns setting being ignored

## Alpha Version - v0.6 - 2019-10-29

### New features

- New minigame: Haunted dreams
- Barebone implementation of Nolok and GNU spaces
- Added AI difficulty levels
- Board settings, such as Cake cost and number of turns can be overridden via the menu
- The current placement of players is shown in the UI
- Cake spaces get relocated, when the cake is collected
- Add italian translation
- Spaces can now be marked as invisible, which can be used to influence the walking path

### Improved / Changed

- Added a 3D cake model
- Improved water
- Fixed a bug that caused the 2v2 rewardscreen to play the wrong animation if Team1 wins
- Fixed the buy cake message not being translated
- Reworked the KDEValley board
- Fixed a bug that caused the game to get stuck, when a board event from a green space was not handled

## Alpha Version - v0.5 - 2019-08-02

### New features

- Support for localization in the minigame information screen
- Support for localization in minigame descriptions
- Translated minigames
- Improved the API for board events (green spaces)
- Add music to:
  - The test and KDEValley boards
  - The Escape from lava minigame

### Improved / Changed

- Fix French language not selectable
- Fixed the position of the minigame information screen to cover the full window
- Improved icon quality
- Fixed a bug that caused the cake icon on cake spots to disappear
- Fixed a crash when player landed on a trap
- Fixed a bug that caused the shop not to open when landing directly on it
- The characters in the knock off minigame now face the direction they are walking
- Made the options menu accessible from the pause menu look like in the main menu
- Improved the controller navigation in the options
- The characters in the harvest food minigame no longer spawn in the air
- Fixed the black outline on the green tux texture
- Fixed the descriptions in the main menu back buttons

## Alpha Version - v0.4 - 2019-06-08

### New features

- Support for localization (except plugins)
  - Currently supported languages:
    - English
    - Brazilian Portuguese
    - German
    - French
- Team indicator in 2v2 minigames

### Improved / Changed

- The main menu can now be navigated with keyboard/controller
- The board overlay now shows the items of each player
- Computer controlled characters now buy items in the shop
- Added Music in the main menu
- Fix a bug that made items not usable in games loaded from savegames
- Added textures for Harvest Food minigame and placement scene

Internally the project has switched to the new [Godot](https://godotengine.org) version 3.1

## Alpha Version - v0.3 - 2019-02-02

### New features

- KDEValley, a new board
- Escape from lava, a new minigame
- New background for main menu
- New scenery for 'test' board
- Added screenshot for 'Bowling minigame'
- Frame cap and VSync can now be set in options
- Items (e.g. Dice and traps)
- Items can be bought in Shop Spaces (purple color)

### Improved / Changed

- Each character can only be chosen once now
- New GUI theme
- Options can now be opened in-game
- Smooth rotations for board movement

Internally the project has been restructured and switched to the
[Git Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows).

## Alpha Version - v0.2 - 2018-10-31

### New features

- Godette, Godot's unofficial mascot, as a new playable character, !53
- Animations for all characters, !25
- Bowling minigame, one player tries to hit the other 3 players, !63
- Kernel Compiling minigame, press the correct buttons quickly, !52
- Harvest Food minigame, guessing game, !39
- Boards can now have multiple paths, players can choose which way to go, !26
- Minigame information screens, !28
- New gamemodes added such as, Duel, 1v3 and 2v2, !64
- Games can now be saved, !33

### Improved

- Options are now saved, !54
- Fixed a memory leak, !29
- Improved mesh and texture for ice in Knock Off minigame, !30, !34
- Hurdle minigame now has powerups and different hurdles, !38

## Demo Version - v0.1 - 2018-09-01

- 3 playable characters
- 2 minigames
- 2 reward systems, winner takes all and a linear one
- 1 board
- AI opponents
- Controller remapping
- Dynamic loading of boards & characters
