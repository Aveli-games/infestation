extends Node

signal resource_updated

enum InfestationType {NONE, AIR, WATER, GROUND}
enum ResourceType {NONE, FOOD, FUEL, PARTS, RESEARCH}

var base_infestation_rate = .1

var resources = {
	ResourceType.FOOD: 0,
	ResourceType.FUEL: 0,
	ResourceType.PARTS: 0,
	ResourceType.RESEARCH: 0
}

func add_resource(type: ResourceType, change: int):
	resources[type] += change
	resource_updated.emit(type)
