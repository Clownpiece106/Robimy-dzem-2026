extends Sprite2D

@export_enum("FOREGROUND", "BACKGROUND") var plane 

func _ready():
	match plane:
		0:
			z_index = 2
		1:
			z_index = 0
	print("table z index is "+str(z_index))

func _process(delta):
	#print("table z index is "+str(z_index))
	pass
	
