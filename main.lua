display.setStatusBar(display.HiddenStatusBar)

local MAX_BUBBLES = 10
local WIDTH = display.contentWidth
local HEIGHT = display.contentHeight
local ALERT_THRESHOLD = 0.8
local BAR_FONT_SIZE = 16
local BIG_FONT_SIZE = 32
local BAR_HEIGHT = 22

local physics = require "physics"
local rand = math.random
local dead = false
local so_far = 0
local dead_bubbles = 0
local score = 0
local radius_bonus = 0
local delay = START_DELAY

local bubbles = display.newGroup()
local overlay = display.newGroup()

local topWall
local bottomWall
local leftWall
local rightWall
local pops = {
	audio.loadSound("sounds/pop.wav"),
	audio.loadSound("sounds/pop2.wav"),
	audio.loadSound("sounds/pop3.wav"),
	audio.loadSound("sounds/pop4.wav"),
}

local start -- declared for later

-- returns delay, min_size, speed
local levels = function () 
	local basesz = ((WIDTH + HEIGHT) / 2) / 20

	if so_far < 10 then
		return 1000, basesz * 3.5, 15 
	elseif so_far < 20 then
		return 950, basesz * 3.4, 15 
	elseif so_far < 30 then
		return 900, basesz * 3.325, 16 
	elseif so_far < 40 then
		return 850, basesz * 3.25, 16 
	elseif so_far < 40 then
		return 800, basesz * 3.1, 17 
	elseif so_far < 50 then
		return 750, basesz * 3.0, 17 
	elseif so_far < 60 then
		return 700, basesz * 2.8, 18 
	elseif so_far < 70 then
		return 650, basesz * 2.6, 18 
	elseif so_far < 80 then
		return 600, basesz * 2.4, 19 
	elseif so_far < 90 then
		return 550, basesz * 2.2, 19 
	elseif so_far < 100 then
		return 500, basesz * 2.0, 20 
	else
		return 500, basesz * 1.75, 20 
	end
end

scorebar = display.newRect(0, 0, WIDTH, BAR_HEIGHT)
scorebar.alpha = 0.0
scorebar:setFillColor(0, 0, 120)
scoretext = display.newText('', 10, BAR_HEIGHT/2, native.systemFontBold, BAR_FONT_SIZE)
function scoretext:setScore (score)
	scorebar.alpha = 1.0
	self.text = 'Score: ' .. score
	self.y = BAR_HEIGHT / 2
	self.x = (self.width / 2) + 10
end

bubblelimit = display.newText('', 10, BAR_HEIGHT/2, native.systemFontBold, BAR_FONT_SIZE)
function bubblelimit:setNum ()
	local used = bubbles.numChildren - dead_bubbles
	local limit = MAX_BUBBLES
	self.y = BAR_HEIGHT / 2
	self.text = 'Bubbles: ' .. used .. '/' .. limit
	self.x = WIDTH - ((self.width / 2) + 10)
	if (used / limit >= ALERT_THRESHOLD) then self:setTextColor(255,0,0)
	else self:setTextColor(255,255,255) end
end

physics.start()
physics.setGravity(0,0)
--physics.setDrawMode( "hybrid" )

local tapped = function (ev) 
	if dead or not ev.target.active then return end
	dead_bubbles = dead_bubbles + 1
	bubblelimit:setNum()
	ev.target.active = false
	if ev.target then
		audio.play(pops[rand(1,table.maxn(pops))])
		transition.to(ev.target, {
			alpha = 0,
			time = 1000,
			xScale = 3,
			yScale = 3,
			transition = easing.outExpo,
			onComplete = function (target) 
				if target and target.removeSelf then target:removeSelf() end 
				dead_bubbles = dead_bubbles - 1
				bubblelimit:setNum()
			end
		})
		if not dead then score = score + 10 end
		scoretext:setScore(score)
	end
end

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
	
local make_bubble = function ()
	local delay, basesz, impulseSpeed = levels()
	local sz = rand(basesz * .5, basesz * 1) + radius_bonus
	local bubble = display.newCircle(rand(sz, WIDTH-sz), rand(sz + scorebar.height, HEIGHT-(sz+BAR_HEIGHT)), sz)
	bubble.active = true
	bubble:setFillColor(rand(50,200), rand(50,200), rand(50,200))
	bubble.strokeWidth = rand(0,basesz/10) + rand(0,basesz/10)
	bubble:setStrokeColor(rand(0,255), rand(0,255), rand(0,255))
	bubble:addEventListener('tap', tapped)
	bubbles:insert(bubble)
	bubblelimit:setNum()
	physics.addBody(bubble, "dynamic", {density=1.0, friction=0.3, bounce=1.0, radius=sz+2, isSensor=false})
	bubble:applyLinearImpulse(rand(0,impulseSpeed), rand(0,impulseSpeed))
	so_far = so_far + 1
end


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
	if ((bubbles.numChildren - dead_bubbles) >= MAX_BUBBLES) then
		dead = true
		lose()
		return
	end
	make_bubble()
	local delay, basesz, impulseSpeed = levels()
	timer.performWithDelay(delay, loop, 1)
end

start = function (event) 
	dead = false
	dead_bubbles = 0
	so_far = 0
	while bubbles[1] do bubbles[1]:removeSelf() end
	while overlay[1] do overlay[1]:removeSelf() end
	score = 0
	bubblelimit:setNum()
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
	bubblelimit:setNum()
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

img = display.newImage('Default.png')
img:addEventListener('tap', function (ev) 
	ev.target:removeSelf()
	add_walls()
	start()
end)
