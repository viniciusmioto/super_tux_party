# Contributing

## Workflow

Super Tux Party now follows the [Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).
This means that:

- All merge requests should have their own branch
- That branch must have an appropiate name
- The `master` branch is our release branch
- No merge requests will be accepted into the `master` branch
- Merge requests must instead be merged into the `dev` branch
- Only core team members are allowed to push directly to `dev` branch

Additionally:

- All commits must be [signed-off](https://git-scm.com/docs/git-commit#git-commit--s), to certify that you wrote the patch
- Commit messages needs to be written in present tense
- If you add assets you need to update `LICENSE-ART.md` with appropiate licensing information
- Changelog should ideally also be updated if the change affects end-users

## Git

[git-lfs](https://git-lfs.github.com/) is used in this project for handling
asset files. Tutorial for git-lfs can be found [here](https://www.atlassian.com/git/tutorials/git-lfs).

Too clone the repository, simply run:

- `git clone https://gitlab.com/SuperTuxParty/SuperTuxParty.git`
- `git lfs pull`

If you want to merge changes into the repository you must first fork the
project, upload your changes there and then create a merge request on the main
repository.

## Tools

Super Tux Party is built in Godot 3.0.6 with GDscript.
3D models are exported from [Blender](https://www.blender.org/) with the
[godot-blender-exporter](https://github.com/godotengine/godot-blender-exporter)
add-on installed.

### File structure

- Assets should be placed in the same folder as the scene using them.
- Exception to that should be assets that are used a lot across multiple scenes,
  they should have their own folder
- Minigames should be placed in the corresponding folder under the `minigames`
  folder
- Boards should be placed under the `boards` folder in their own folder: the
  name must match the name of the board

## Coding style

- All file names are lowercase
- All function and variable names use snake_case
- No semicolons
