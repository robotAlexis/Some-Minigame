extends Node2D
class_name SomeCell

@onready var polygon: Polygon2D = $Polygon2D

func  set_active(is_active: bool):
	polygon.color = Color(.5,.5,.5) if is_active else Color(.8,.8,.8)

func set_final():
	polygon.color = Color(0.6, .95, .95, 1.0)

func set_final_win():
	polygon.color = Color(0.5, 0.9, 0.75, 1.0)


func set_current():
	polygon.color = Color(.9,.9,.9)
