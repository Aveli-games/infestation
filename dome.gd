extends Node2D

signal fully_infested

const DOME_SPRITES_PATH = "res://art/dome_sprites"
const INFESTATION_COUNTDOWN = 30

var infestation_percentage: float = 0.0
var infestation_stage: InfestationStage = InfestationStage.UNINFESTED
var infestation_type: Globals.InfestationType = Globals.InfestationType.NONE
var infestation_rate: float = 0.0
var infestation_modifier: float = 0.0
@export var resource_type: Globals.ResourceType = Globals.ResourceType.NONE
var is_hidden: bool = false
var connections: Dictionary = {}

enum InfestationStage {UNINFESTED, MINOR, MODERATE, MAJOR, FULL, LOST}

func _process(delta):
	# Process infestation progression inependently in dome's infestation check
	add_infestation((infestation_rate + infestation_modifier) * delta)
	
	$Building/InfestationProgress.value = infestation_percentage * 100

func _on_infestation_check_timer_timeout():
	
	# Then determine infestation level
	if infestation_percentage <= 0:
		if infestation_stage != InfestationStage.UNINFESTED:
			infestation_stage = InfestationStage.UNINFESTED
			$DomeStatus.text = "Safe"
			infestation_rate = 0.0
		if randf() < .1 && infestation_rate == 0: # Temp, infestation should be initiated by main eventually
				infestation_rate += .1
				$ResourceGenerationTimer.stop()
		else:
			$ResourceGenerationTimer.start(1)
	elif infestation_percentage <= .50:
		if infestation_stage != InfestationStage.MINOR:
			infestation_stage = InfestationStage.MINOR
			$DomeStatus.text = "Minor infestation"
	elif infestation_percentage <= .75:
		if infestation_stage != InfestationStage.MODERATE:
			infestation_stage = InfestationStage.MODERATE
			$DomeStatus.text = "Moderate infestiation!"
	elif infestation_percentage < 1:
		if infestation_stage != InfestationStage.MAJOR:
			infestation_stage = InfestationStage.MAJOR
			$DomeStatus.text = "Major infestation!"
	elif infestation_percentage >= 1:
		if infestation_stage != InfestationStage.FULL:
			infestation_stage = InfestationStage.FULL
		if $DomeLostCountdownTimer.is_stopped():
			$DomeStatus.text = "Fully infested: %s" % INFESTATION_COUNTDOWN
			fully_infested.emit()
		else:
			$DomeStatus.text = "Fully infested: %s" % int($DomeLostCountdownTimer.time_left)
	
	if infestation_stage < InfestationStage.FULL:
		$DomeLostCountdownTimer.stop()

func add_infestation(infestation_value: float):
	if infestation_stage != InfestationStage.LOST:
		infestation_percentage = clamp(infestation_percentage + infestation_value, 0, 1)
		
func add_infestation_modifier(change: float):
	infestation_modifier += change
	
func set_sprite(path: String):
	$Building/BuildingSprite.texture = load(path)

func generate_resource():
	if resource_type && resource_type != Globals.ResourceType.NONE:
		Globals.add_resource(resource_type, 1)

func set_resource_type(type: Globals.ResourceType):
	resource_type = type
	match resource_type:
		Globals.ResourceType.FOOD:
			set_sprite("res://art/dome_sprites/Dome_food_96.png")
		Globals.ResourceType.RESEARCH:
			set_sprite("res://art/dome_sprites/Dome_fuel_96.png")
		Globals.ResourceType.PARTS:
			set_sprite("res://art/dome_sprites/Dome_parts_96.png")
		Globals.ResourceType.FUEL:
			set_sprite("res://art/dome_sprites/Dome_science_96.png")

# Only called when becomes fully infested
func _on_fully_infested():
	$DomeLostCountdownTimer.start(INFESTATION_COUNTDOWN)

func _on_dome_lost_countdown_timer_timeout():
	$InfestationCheckTimer.stop()
	infestation_stage = InfestationStage.LOST
	$DomeStatus.text = "Lost"
	$Building/BuildingSprite.modulate = Color.DIM_GRAY

func _on_resource_generation_timer_timeout():
	if resource_type != Globals.ResourceType.RESEARCH:
		generate_resource()
