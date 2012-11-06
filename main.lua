display.setStatusBar(display.HiddenStatusBar)

MAX_BUBBLES = 10
WIDTH = display.contentWidth
HEIGHT = display.contentHeight
START_DELAY = 2000
SPEED_INCREASE = 50
MIN_DELAY = 200
ALERT_THRESHOLD = 0.8
BAR_FONT_SIZE = 16
BIG_FONT_SIZE = 32
BAR_HEIGHT = 22

local rand = math.random
local dead = false

scorebar = display.newRect(0, 0, WIDTH, BAR_HEIGHT)
scorebar:setFillColor(0, 0, 120)
scoretext = display.newText('', 10, BAR_HEIGHT/2, native.systemFontBold, BAR_FONT_SIZE)
function scoretext:setScore (score)
	self.text = 'Score: ' .. score
	self.y = BAR_HEIGHT / 2
	self.x = (self.width / 2) + 10
end

bubblelimit = display.newText('', 10, BAR_HEIGHT/2, native.systemFontBold, BAR_FONT_SIZE)
function bubblelimit:setNum (used)
	local limit = MAX_BUBBLES
	self.y = BAR_HEIGHT / 2
	self.text = 'Bubbles: ' .. used .. '/' .. limit
	self.x = WIDTH - ((self.width / 2) + 10)
	if (used / limit >= ALERT_THRESHOLD) then self:setTextColor(255,0,0)
	else self:setTextColor(255,255,255) end
end

local physics = require "physics"
physics.start()
physics.setGravity(0,0)
--physics.setDrawMode( "hybrid" )
local bubbles = display.newGroup()
local score = 0
local radius_bonus = 0

local tapped = function (ev) 
	if not ev.target.active then return end
	ev.target.active = false
	if ev.target then
		transition.to(ev.target, {
			alpha = 0,
			time = 1000,
			xScale = 3,
			yScale = 3,
			transition = easing.outExpo,
			onComplete = function (target) if (target) then target:removeSelf() end end
		})
		if not dead then score = score + 10 end
		scoretext:setScore(score)
	end
end

local delay = START_DELAY
local topWall
local bottomWall
local leftWall
local rightWall
local add_walls =  function ()
	if topWall then topWall:removeSelf() end
	if bottomWall then bottomWall:removeSelf() end
	if leftWall then leftWall:removeSelf() end
	if rightWall then rightWall:removeSelf() end
	topWall = display.newRect( 0, 0, display.contentWidth, BAR_HEIGHT )
	topWall:setFillColor(0,0,120)
	topWall.alpha = 0
	bottomWall = display.newRect( 0, display.contentHeight - 1, display.contentWidth, 1 )
	bottomWall:setFillColor(0,0,120)
	leftWall = display.newRect( 0, 0, 1, display.contentHeight )
	leftWall:setFillColor(0,0,120)
	rightWall = display.newRect( display.contentWidth - 1, 0, 1, display.contentHeight )
	rightWall:setFillColor(0,0,120)
	
	-- make them physics bodies
	physics.addBody(topWall, "static", {density = 1.0, friction = 0, bounce = 1, isSensor = false})
	physics.addBody(bottomWall, "static", {density = 1.0, friction = 0, bounce = 1, isSensor = false})
	physics.addBody(leftWall, "static", {density = 1.0, friction = 0, bounce = 1, isSensor = false})
	physics.addBody(rightWall, "static", {density = 1.0, friction = 0, bounce = 1, isSensor = false})
end
	
local impulseSpeed = function()
	local scale = START_DELAY / delay
	scale = math.min(20, scale * 4)
	return rand(0, scale), rand(0, scale)
end

local make_bubble = function ()
	local basesz = ((WIDTH + HEIGHT) / 2) / 15
	local sz = rand(basesz * .7, basesz * 1.1) + radius_bonus
	local bubble = display.newCircle(rand(sz, WIDTH-sz), rand(sz + scorebar.height, HEIGHT-(sz+BAR_HEIGHT)), sz)
	bubble.active = true
	bubble:setFillColor(rand(50,200), rand(50,200), rand(50,200))
	bubble.strokeWidth = rand(0,basesz/10) + rand(0,basesz/10)
	bubble:setStrokeColor(rand(0,255), rand(0,255), rand(0,255))
	bubble:addEventListener('tap', tapped)
	bubbles:insert(bubble)
	bubblelimit:setNum(bubbles.numChildren)
	physics.addBody(bubble, "dynamic", {density=1.0, friction=0.3, bounce=1.0, radius=sz+2, isSensor=false})
	bubble:applyLinearImpulse(impulseSpeed())
end

local overlay = display.newGroup()
local start

local lose = function()
	local cover = display.newRect(0, 0, WIDTH, HEIGHT)
	cover:setFillColor(200,0,0)
	cover.alpha = 0.7

	local endtext = display.newText('GAME OVER', 0, 0, native.systemFontBold, BIG_FONT_SIZE)
	endtext.x = WIDTH / 2
	endtext.y = HEIGHT / 2 - 80

	local endscore = display.newText('SCORE: '..score, 0, 0, native.systemFontBold, BIG_FONT_SIZE)
	endscore.x = WIDTH / 2
	endscore.y = HEIGHT / 2 - 20

	local taptext = display.newText('Tap Screen to Play Again', 0, 0, native.systemFontBold, BIG_FONT_SIZE - 10)
	taptext.x = WIDTH / 2
	taptext.y = HEIGHT / 2 + 40
	taptext.alpha = 0

	overlay:insert(cover)
	overlay:insert(endtext)
	overlay:insert(endscore)
	overlay:insert(taptext)
	timer.performWithDelay(2000, function ()
		cover:addEventListener('tap', start)
		taptext.alpha = 1
	end)
end



local loop
loop  = function ()
	if (bubbles.numChildren >= MAX_BUBBLES) then
		dead = true
		lose()
		return
	end
	make_bubble()
	timer.performWithDelay(delay, loop, 1)
	delay = math.max(MIN_DELAY, delay - SPEED_INCREASE)
end

start = function (event) 
	dead = false
	while bubbles[1] do bubbles[1]:removeSelf() end
	while overlay[1] do overlay[1]:removeSelf() end
	delay = START_DELAY
	score = 0
	bubblelimit:setNum(0)
	scoretext:setScore(0)
	loop()
end


local flipped = function (evt)
	local xchange = display.contentWidth / WIDTH
	local ychange = display.contentHeight / HEIGHT

	WIDTH = display.contentWidth
	HEIGHT = display.contentHeight

	add_walls()

	scorebar.width = WIDTH + 200
	bubblelimit:setNum(bubbles.numChildren)
	for i=1, bubbles.numChildren do
		transition.to(bubbles[i], {
			x = bubbles[i].x * xchange, 
			y = bubbles[i].y * ychange,
			time = 200
		})
	end
	if overlay and overlay[1] then
		overlay[1].width = WIDTH
		overlay[1].height = HEIGHT
		for i=1, overlay.numChildren do
			transition.to(overlay[i], {
				x = overlay[i].x * xchange, 
				y = overlay[i].y * ychange,
				time = 20
			})
		end
	end
end

Runtime:addEventListener('orientation', flipped)

add_walls()
start()
