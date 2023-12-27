extends Panel

var grids = [{}, {}]
var cells = {}
var cell_size = 16 # 20 cells by 15 given a 320x240
var alive_color: Color
var dead_color = Color(32)
var birth_nums = []
var survival_nums = []
var rng = RandomNumberGenerator.new()

func _ready():
	$CCell.hide()
	alive_color = $CCell.modulate
	start_life()
	print('starting life')

func _process(delta):
	pass
#	if $Timer.is_stopped():
#		$Timer.start()

func start_life():
	insert_soup()
#	set_rulestring([3],[2,3]) # Conways
#	set_rulestring([2],[]) # Seeds
#	set_rulestring([1,3,5,8],[0,2,4,7]) # Feux
#	set_rulestring([2],[0]) # Live Free or Die
#	set_rulestring([4,5,6,7,8],[2,3,4,5])# Walled Cities
#	set_rulestring([3,5],[2,3,6]) # Eppstein
#	set_rulestring([3,5,7],[1,3,5,8])# Amoeba; normally stabilizes, but continues in our unwrapped grid

#	set_rulestring([3,6,7,8],[1,3,5,6,7,8]) # Castles not good, fills the board bc of wrap
#	set_rulestring([3],[0,2,3]) # DotLife not good, stabilizes eventually	
#	set_rulestring([3,5],[2,3,4,5,7,8]) # Land Rush, like Walled Cities but more stable
	$GenTimer.start(0.15)
	
func set_rulestring(b,s):
	birth_nums = b
	survival_nums = s
	
func insert_soup():
	for x in range(0,20):
		for y in range(0,15):
			if rng.randi_range(1,2) == 1: add_new_cell(Vector2(x,y))

func insert_r_pentomino():
	add_new_cell(Vector2(10,5))
	add_new_cell(Vector2(9,5))
	add_new_cell(Vector2(11,4))
	add_new_cell(Vector2(10,4))
	add_new_cell(Vector2(10,6))

func insert_spaceship():
	add_new_cell(Vector2(10,5))
	add_new_cell(Vector2(11,5))
	add_new_cell(Vector2(12,5))
	add_new_cell(Vector2(10,4))
	add_new_cell(Vector2(11,3))

func add_new_cell(grid_pos_unbounded):
	var grid_pos = Vector2(grid_pos_unbounded.x as int % 20, grid_pos_unbounded.y as int % 15) 
	var pos = grid_pos * cell_size
	var cell = $CCell.duplicate()
	cell.position = pos
	add_child(cell)
	cell.show()
	cells[grid_pos] = cell
	grids[1][grid_pos] = true

func remove_cell(pos: Vector2):
	var key = get_grid_pos(mouse_pos_to_cam_pos(pos))
	# Check if user clicked in occupied position
	if cells.has(key):
		cells[key].queue_free()
		cells.erase(key)
		grids[1].erase(key)

func regenerate():
#	the cells key is its position, so iterate over every existing cell
	for key in cells.keys():
		var n = get_num_live_cells(key)
		if grids[0][key]: # Alive in current gen
			grids[1][key] = (survival_nums.has(n)) # in next gen, cell stays alive if enough neighbors
		else: # Dead
			grids[1][key] = (birth_nums.has(n)) # in next gen, dead cell becomes alive with enough neighbors

func update_cells():
	for key in cells.keys():
		cells[key].modulate = alive_color if grids[1][key] else dead_color

var to_check = []

# this checks the number of neighbors
func get_num_live_cells(pos: Vector2, first_pass = true):
	var num_live_cells = 0
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			if x != 0 or y != 0:
#				new_pos represents the current neighbor were viewing
				var new_pos_unbounded = pos + Vector2(x, y)
				
				var new_pos = Vector2(
					new_pos_unbounded.x + 20 as int % 20, 
					new_pos_unbounded.y + 15 as int % 15
					)
				# Check if the current neighbors position exists in the grid, avoid OUT_OF_BOUNDS err
				if grids[0].has(new_pos):
					if grids[0][new_pos]: # If alive
						num_live_cells += 1
#				if the neighbor's cell hasn't been created yet in the grid:
				else:
#					first_pass is true when this func is called from regen()
					if first_pass:
						to_check.append(new_pos)
	return num_live_cells

#ignore; this is for grids that aren't bounded and thus not pre-defined
func add_new_cells():
	for pos in to_check:
		var n = get_num_live_cells(pos, false)
#		if live neighbors is 3 and the cell is currently dead in the newest generation, make it alive
		if n == 3 and not grids[1].has(pos):
			add_new_cell(pos)
#	reset cells to check for next regen
	to_check = []

func _on_gen_timer_timeout():
	print("start new generation!")
	grids.reverse()
	grids[1].clear()
#	iterate over each cell and apply the rules of life to it
	regenerate()
#	then we add the neighbor cells that don't exist in the grid yet, and check them
	add_new_cells()
#	update the cells color based off its status in the grid
	update_cells()
	
#ignore
func get_grid_pos(pos: Vector2) -> Vector2:
	var pixels = 32.0 / $Camera2D.zoom.x
	return pos.snapped(Vector2(pixels, pixels)) / pixels

#ignore 
func start_stop():
	if $Timer.is_stopped() and cells.size() > 0:
		$Timer.start()
		$c/Running.show()
		$c/Stopped.hide()
	else:
		$Timer.stop()
		$c/Running.hide()
		$c/Stopped.show()

#ignore
func reset():
	$Timer.stop()
	$c/Running.hide()
	$c/Stopped.show()
	for key in cells.keys():
		cells[key].queue_free()
	grids[1].clear()
	cells.clear()

#ignore
func place_cell(pos: Vector2):
	# Convert mouse position to camera view coordinates
	pos = mouse_pos_to_cam_pos(pos)
	var grid_pos = get_grid_pos(pos)
	if not cells.has(grid_pos):
		add_new_cell(grid_pos)

#ignore
func mouse_pos_to_cam_pos(pos):
	return pos + $Camera2D.offset / $Camera2D.zoom - get_viewport_rect().size / 2

