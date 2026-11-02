extends RefCounted
## Procedural pixel art, drawn with native Godot CanvasItem primitives.
const COLORS = {
	"bg":Color(0.035,0.043,0.065),"stone":Color(0.12,0.14,0.19),"edge":Color(0.25,0.29,0.36),
	"ink":Color(0.065,0.08,0.12),"text":Color(0.88,0.88,0.82),"dim":Color(0.46,0.51,0.57),
	"gold":Color(1,0.74,0.32),"red":Color(0.96,0.31,0.36),"green":Color(0.44,0.85,0.64),
	"I":Color(0.34,0.81,0.86),"O":Color(0.98,0.76,0.32),"T":Color(0.70,0.48,0.86),
	"S":Color(0.45,0.75,0.46),"Z":Color(0.91,0.37,0.40),"J":Color(0.38,0.54,0.88),"L":Color(0.93,0.57,0.30)}
var target: CanvasItem
var font: Font
var time = 0.0
func _init(node: CanvasItem):
	target = node
	font = ThemeDB.fallback_font
func col(value, alpha: float = 1.0) -> Color:
	var c = COLORS.get(value,Color.WHITE) if value is String else value
	c.a = alpha
	return c
func rect(x, y, w, h, c, alpha: float = 1.0):
	target.draw_rect(Rect2(floor(x),floor(y),w,h),col(c,alpha))
func text(s, x, y, size: int = 12, c = "text", width: float = -1, align: int = HORIZONTAL_ALIGNMENT_LEFT):
	target.draw_string(font,Vector2(floor(x),floor(y)+size),str(s),align,width,size,col(c))
func panel(x,y,w,h):
	rect(x,y,w,h,"edge")
	rect(x+2,y+2,w-4,h-4,"ink")
	rect(x+4,y+4,w-8,1,Color(0.18,0.21,0.27))
func torch(x,y):
	rect(x-3,y+6,6,17,Color(0.29,0.19,0.15))
	rect(x-5,y+4,10,4,"edge")
	var flick = floor(sin(time*13+x)*2)
	rect(x-7,y-6,14,15,"L",0.15)
	rect(x-4,y-4+flick,8,11-flick,"L")
	rect(x-2,y-6+flick,4,12-flick,"gold")
	rect(x-1,y,2,5,Color(1,0.94,0.66))
func hero(x,y,running = false):
	var step = int(time*9)%2 if running else 0
	y += step if running else sin(time*3)*0.6
	rect(x-12,y+24,26,4,Color.BLACK,0.35)
	rect(x-9,y+3,8,20,Color(0.51,0.16,0.24))
	rect(x-9,y+17,6,8,Color(0.66,0.22,0.28))
	rect(x-4,y+17,5,8+step*2,"edge")
	rect(x+4,y+17,5,10-step*2,"edge")
	rect(x-5,y+4,15,15,Color(0.43,0.55,0.62))
	rect(x-3,y+5,10,4,Color(0.67,0.75,0.77))
	rect(x-5,y-9,15,14,Color(0.68,0.74,0.75))
	rect(x-3,y-11,10,3,Color(0.82,0.85,0.79))
	rect(x+2,y-4,9,3,"ink")
	rect(x+6,y-4,2,2,"gold")
	rect(x+9,y+8,5,7,Color(0.79,0.63,0.45))
	rect(x+15,y-5,3,22,Color(0.77,0.84,0.84))
	rect(x+11,y+12,11,3,"gold")
func monster(kind,x,y):
	y += floor(sin(time*3)*2)
	rect(x-17,y+24,36,5,Color.BLACK,0.4)
	if kind not in ["rat","slime","wraith","skeleton","warden"]:
		preload("res://scripts/enemy_art.gd").draw(self,kind,x,y)
		return
	match kind:
		"rat":
			rect(x-13,y+5,26,16,Color(0.43,0.36,0.48))
			rect(x-21,y+9,12,9,Color(0.54,0.45,0.56))
			rect(x-14,y-1,7,9,Color(0.68,0.48,0.52))
			rect(x-19,y+11,3,3,"red")
			rect(x+12,y+11,13,3,Color(0.61,0.4,0.46))
			rect(x-10,y+20,5,5,"dim")
			rect(x+7,y+20,5,5,"dim")
		"slime":
			rect(x-19,y+11,38,13,Color(0.21,0.48,0.37))
			rect(x-15,y+2,30,17,"green")
			rect(x-9,y-2,18,5,"green")
			rect(x-10,y+8,4,5,"ink")
			rect(x+5,y+8,4,5,"ink")
			rect(x-6,y+2,7,3,Color(0.7,0.96,0.67))
		"wraith":
			var robe = Color(0.31,0.24,0.47)
			rect(x-13,y-8,27,32,robe)
			rect(x-9,y-14,19,9,Color(0.42,0.32,0.59))
			rect(x-19,y+6,8,14,robe)
			rect(x+12,y+5,8,17,robe)
			rect(x-7,y-3,16,10,"ink")
			rect(x-5,y,4,3,"T")
			rect(x+3,y,4,3,"T")
			for i in range(4): rect(x-13+i*7,y+22,4,6-floor(sin(time*6+i)*3),robe)
		_:
			var boss = kind == "warden"
			var bone = Color(0.48,0.49,0.57) if boss else Color(0.79,0.76,0.64)
			rect(x-10,y-13,21,17,bone)
			rect(x-7,y-8,5,5,"ink")
			rect(x+3,y-8,5,5,"ink")
			rect(x-4,y+1,12,3,"ink")
			rect(x-3,y+5,6,15,bone)
			for i in range(3): rect(x-10,y+6+i*5,20,2,bone)
			rect(x-9,y+20,5,8,bone)
			rect(x+5,y+20,5,8,bone)
			rect(x-17,y+7,5,14,bone)
			rect(x+14,y+5,5,16,bone)
			if boss:
				rect(x-15,y+4,30,7,"edge")
				rect(x-13,y-17,5,7,"gold")
				rect(x+8,y-17,5,7,"gold")
				rect(x-7,y-8,4,3,"red")
				rect(x+4,y-8,4,3,"red")
			rect(x-23,y-3,3,29,"dim")
			rect(x-29,y-3,15,7,"dim")
func block(x,y,kind,ghost = false):
	var c = COLORS[kind]
	if ghost:
		target.draw_rect(Rect2(x+3,y+3,18,18),col(c,0.45),false,1)
		rect(x+9,y+9,7,7,c,0.18)
		return
	rect(x+1,y+1,23,23,c.darkened(0.55))
	rect(x+2,y+2,21,19,c)
	rect(x+3,y+3,19,3,c.lightened(0.25))
	rect(x+4,y+7,2,11,Color.WHITE,0.14)
	rect(x+19,y+8,2,12,Color.BLACK,0.13)
	rect(x+9,y+10,7,7,Color.BLACK,0.12)
	rect(x+11,y+12,3,3,Color.WHITE,0.22)
func preview(kind,x,y):
	if kind == "":
		text("--",x+14,y+10,14,"dim")
		return
	for c in preload("res://scripts/run.gd").SHAPES[kind]:
		rect(x+c[0]*15+1,y+c[1]*15+1,13,13,kind)
		rect(x+c[0]*15+2,y+c[1]*15+2,11,2,Color.WHITE,0.3)
func bricks(x,y,w,h,scroll = 0.0):
	rect(x,y,w,h,Color(0.09,0.10,0.14))
	for row in range(int(h/26)+1):
		for column in range(-1,int(w/56)+1):
			var bx = x+column*56-fmod(scroll,56)+(row%2)*28
			var left = maxf(x,bx)
			var right = minf(x+w,bx+54)
			if right > left:
				rect(left,y+row*26,right-left,minf(24,y+h-(y+row*26)),Color(0.13,0.145,0.18))

func destination_icon(kind,x,y):
	rect(x,y,56,54,"bg")
	match kind:
		"halls":
			for i in range(3): rect(x+5,y+5+i*14,46,11,"stone")
			torch(x+28,y+18)
		"crypts":
			rect(x+10,y+17,18,28,Color(0.36,0.35,0.48))
			rect(x+14,y+11,10,9,Color(0.36,0.35,0.48))
			rect(x+18,y+22,3,17,"T")
			rect(x+13,y+28,13,3,"T")
			rect(x+34,y+28,12,17,"dim")
		"lava":
			rect(x+5,y+35,46,12,"L")
			for i in range(3):
				rect(x+10+i*13,y+18-i*4,9,25,"L")
				rect(x+13+i*13,y+24-i*4,3,17,"gold")
		"sewers":
			rect(x+7,y+8,37,10,"edge")
			rect(x+34,y+8,10,22,"edge")
			rect(x+37,y+28,4,9,"green")
			rect(x+6,y+40,44,7,"green")
			rect(x+16,y+35,6,6,"S")
		"courtyard":
			rect(x+26,y+7,4,39,"I")
			rect(x+9,y+24,38,4,"I")
			for i in range(4):
				rect(x+13+i*8,y+12+i*8,4,4,"text")
				rect(x+13+i*8,y+36-i*8,4,4,"text")
		"throne":
			rect(x+10,y+25,37,16,"gold")
			for i in range(3): rect(x+10+i*15,y+12,7,22,"gold")
			rect(x+25,y+30,7,7,"T")

func dungeon_background(kind,scroll):
	var floor_color = Color(0.18,0.18,0.22)
	match kind:
		"halls":
			bricks(18,55,464,106,scroll)
			torch(59,95)
			torch(445,95)
		"crypts":
			rect(18,55,464,106,Color(0.075,0.065,0.12))
			for i in range(7):
				var x = 27+i*66
				rect(x,64,45,94,Color(0.13,0.115,0.18))
				rect(x+7,73,31,85,"bg")
			for x in [70,225,423]:
				rect(x,123,25,38,Color(0.32,0.31,0.39))
				rect(x+5,116,15,10,Color(0.32,0.31,0.39))
				rect(x+11,128,3,24,"T",0.5)
				rect(x+5,136,15,3,"T",0.5)
			for i in range(9): rect(23+i*50,147+sin(time+i)*4,52,4,"T",0.08)
			floor_color = Color(0.16,0.14,0.20)
		"lava":
			rect(18,55,464,106,Color(0.14,0.055,0.065))
			for i in range(8):
				var x = 22+i*58
				rect(x,55,38,22,Color(0.25,0.12,0.13))
				rect(x+8,77,22,17,Color(0.25,0.12,0.13))
				rect(x+13,94,10,13,Color(0.25,0.12,0.13))
			for i in range(6):
				rect(36+i*77,120,3,40,"L",0.5)
				rect(39+i*77,135,15,3,"L",0.5)
			for i in range(18): rect(22+fmod(i*27+time*13,454),90+fposmod(i*19-time*18,65),2,3,"gold",0.65)
			floor_color = Color(0.26,0.11,0.12)
		"sewers":
			bricks(18,55,464,106,scroll)
			rect(18,55,464,106,Color(0.24,0.39,0.10),0.22)
			rect(18,67,464,10,Color(0.31,0.36,0.27))
			for x in [50,262,437]:
				rect(x,67,18,57,"edge")
				rect(x+4,77,10,47,Color(0.24,0.30,0.22))
				rect(x+5,123,8,5,"ink")
				rect(x+7,131+fmod(time*21+x,24),3,5,"green")
				rect(x-9,145,37,10,"green",0.2)
			floor_color = Color(0.15,0.21,0.13)
		"courtyard":
			rect(18,55,464,106,Color(0.075,0.13,0.22))
			rect(337,66,22,22,Color(0.76,0.84,0.85))
			rect(345,63,16,20,Color(0.075,0.13,0.22))
			for i in range(7):
				var x = 26+i*67
				rect(x+12,80,8,73,Color(0.14,0.23,0.29))
				for j in range(3): rect(x+8-j*5,88+j*17,16+j*10,12,Color(0.19,0.30,0.36))
				rect(x,148,44,13,Color(0.37,0.48,0.57))
			for i in range(33): rect(20+fposmod(i*47-time*7,459),56+fposmod(i*31+time*18,102),2,2,Color(0.78,0.90,1),0.7)
			floor_color = Color(0.40,0.51,0.59)
		"throne":
			bricks(18,55,464,106,scroll)
			rect(18,55,464,106,Color(0.29,0.11,0.24),0.23)
			for x in [39,188,338,464]:
				rect(x,59,13,102,Color(0.46,0.38,0.28))
				rect(x-3,59,19,6,"gold")
				rect(x-3,152,19,9,"gold")
			for x in [83,246,392]:
				rect(x,60,34,67,Color(0.40,0.13,0.29))
				rect(x,60,34,4,"gold")
				rect(x+15,73,4,33,"gold")
				rect(x+7,87,20,4,"gold")
				rect(x+8,121,18,11,Color(0.40,0.13,0.29))
			floor_color = Color(0.27,0.22,0.25)
	rect(18,161,464,33,floor_color)
	rect(18,161,464,3,"edge")
	if kind == "lava":
		rect(18,165,464,7,"L")
		for i in range(21): rect(19+i*22,166,14,2,"gold",0.6+sin(time*4+i)*0.3)
	elif kind == "sewers":
		rect(18,165,464,7,"green",0.65)
		for i in range(12): rect(23+i*38,166,18,2,"gold",0.3)
	elif kind == "courtyard":
		rect(18,161,464,6,Color(0.84,0.91,0.93))
	elif kind == "throne":
		rect(18,166,464,7,Color(0.43,0.12,0.24))
		rect(18,166,464,1,"gold")
	else:
		for i in range(17): rect(18+i*28,181,22,2,Color(0.25,0.24,0.27))
