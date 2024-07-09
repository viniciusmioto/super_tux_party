## Base API for all character scenes
extends Node3D
class_name Character

## Path to the AnimationPlayer or AnimationTree that holds a character's
## animations
@export var animations: NodePath
## Path to the collision shape for a character
@export var collision_shape: NodePath

## Transitions to the given animation. [br]
## Support for animations depends on the plugin author. We [b]encourage[/b]
## characters to have these animations:[br]
##   - idle [br]
##   - walk [br]
##   - run [br]
##   - punch [br]
##   - kick [br]
##   - jump [br]
##   - happy [br]
##   - sad [br]
##   - stun [br]
##   - carry [br]
##   - run-carry [br]
func play_animation(anim_name: String):
	if animations:
		var player = get_node(animations)
		if player is AnimationPlayer:
			player.play(anim_name)
		elif player is AnimationTree:
			var state_machine = player["parameters/playback"]
			state_machine.travel(anim_name)

## Plays the given animation immediately without transition. [br]
## For a list of available animation names, see [method play_animation]
func jump_to_animation(anim_name: String):
	if animations:
		var player = get_node(animations)
		if player is AnimationPlayer:
			player.play(anim_name)
		elif player is AnimationTree:
			var state_machine = player["parameters/playback"]
			# We can't just start the animation with start(anim_name), because the default state
			# will replace our animation when the scene was just loaded
			# So we have to force it into the default state
			player.advance(0)
			# Godot doesn't check if such a animation exists
			# Which will cause an infinite error loop
			# That's why we need to check it
			# TODO: may remove this check once fixed in Godot
			if player.tree_root.has_node(anim_name):
				state_machine.start(anim_name)

## Pauses the current animation
func freeze_animation():
	if animations:
		var player = get_node(animations)
		if player is AnimationPlayer:
			player.playback_speed = 0
		elif player is AnimationTree:
			# Force an animation update or else it will get stuck in the default pose
			# when instantly frozen
			player.advance(0)
			player.active = false

## Resumes the animation previously paused with [method freeze_animation]
func resume_animation():
	if animations:
		var player = get_node(animations)
		if player is AnimationPlayer:
			player.playback_speed = 1
		elif player is AnimationTree:
			var state_machine = player["parameters/playback"]
			var current_animation = state_machine.get_current_node()
			player.active = true
			state_machine.start(current_animation)
