-- Cette ligne permet d'afficher des traces dans la console pendant l'éxécution
io.stdout:setvbuf('no')

-- Empèche Love de filtrer les contours des images quand elles sont redimentionnées
-- Indispensable pour du pixel art
love.graphics.setDefaultFilter("nearest")

-- Cette ligne permet de déboguer pas à pas dans ZeroBraneStudio
if arg[#arg] == "-debug" then require("mobdebug").start() end

local Tetros = {}

Tetros[1] = {}
Tetros[1].shape = { {
    {0,0,0,0},
    {1,1,1,1},
    {0,0,0,0},
    {0,0,0,0}
  },
  {
    {0,0,1,0},
    {0,0,1,0},
    {0,0,1,0},
    {0,0,1,0}
    } }
Tetros[1].color = {255,0,0}

Tetros[2] = {}
Tetros[2].shape = { {
    {0,0,0,0},
    {0,1,1,0},
    {0,1,1,0},
    {0,0,0,0}
    } }
Tetros[2].color = {0,71,222}

Tetros[3] = {}
Tetros[3].shape = { {
    {0,0,0},
    {1,1,1},
    {0,0,1},
  },
  {
    {0,1,0},
    {0,1,0},
    {1,1,0},
  },
  {
    {1,0,0},
    {1,1,1},
    {0,0,0},
  },
  {
    {0,1,1},
    {0,1,0},
    {0,1,0},
    } }
Tetros[3].color = {222,184,0}

Tetros[4] = {}
Tetros[4].shape = { {
    {0,0,0},
    {1,1,1},
    {1,0,0},
  },
  {
    {1,1,0},
    {0,1,0},
    {0,1,0},
  },
  {
    {0,0,1},
    {1,1,1},
    {0,0,0},
  },
  {
    {1,0,0},
    {1,0,0},
    {1,1,0},
  } }
Tetros[4].color = {222,0,222}

Tetros[5] = {}
Tetros[5].shape = { {
    {0,0,0},
    {0,1,1},
    {1,1,0},
  },
  {
    {0,1,0},
    {0,1,1},
    {0,0,1},
  },
  {
    {0,0,0},
    {0,1,1},
    {1,1,0},
  },
  {
    {0,1,0},
    {0,1,1},
    {0,0,1},
    } }
Tetros[5].color = {255,151,0}

Tetros[6] = {}
Tetros[6].shape = { {
    {0,0,0},
    {1,1,1},
    {0,1,0},
  },
  {
    {0,1,0},
    {1,1,0},
    {0,1,0},
  },
  {
    {0,1,0},
    {1,1,1},
    {0,0,0},
  },
  {
    {0,1,0},
    {0,1,1},
    {0,1,0},
  } }
Tetros[6].color = {71,184,0}

Tetros[7] = {}
Tetros[7].shape = { {
    {0,0,0},
    {1,1,0},
    {0,1,1},
  },
  {
    {0,1,0},
    {1,1,0},
    {1,0,0},
  },
  {
    {0,0,0},
    {1,1,0},
    {0,1,1},
  },
  {
    {0,1,0},
    {1,1,0},
    {1,0,0},
  } }
Tetros[7].color = {0,184,151}

local currentTetros = {}
currentTetros.shapeid = 1
currentTetros.rotation = 1
currentTetros.position = { x=0, y=0 }

local Grid = {}
Grid.offsetX = 0
Grid.width = 10 
Grid.height = 20
Grid.cellSize = 0
Grid.cells = {}

local dropSpeed = 1
local timerDrop = 0
pauseForceDrop = false

local sndMusicMenu
local sndMusicPlay
local sndMusicGameover
local gameState = ""

local score = 0
local level = 0
local lines = 0

local fontMenu
local fontScore
local menuSin = 0

local bag = {}

function InitBag()
	bag = {}
	for n=1, #Tetros do
		table.insert(bag, n)
		table.insert(bag, n)
		table.insert(bag, n)
		table.insert(bag, n)
	end
end

function SpawnTetros()
	local nBag = math.random(1, #bag)
	local new = bag[nBag]
	table.remove(bag, nBag)
	if #bag == 0 then
		InitBag()
	end
	currentTetros.shapeid = new
	currentTetros.rotation = 1
	--Calcul la taille du tetros sélectionné par rapport à la forme choisit et sa rotation
	local tetrosWidth = #Tetros[currentTetros.shapeid].shape[currentTetros.rotation][1]
	--Positionnement du Tetros de manière centrée sur le plateau de jeu
	currentTetros.position.x = (math.floor((Grid.width - tetrosWidth) / 2)) + 1
	currentTetros.position.y = 1
	pauseForceDrop = true
	timerDrop = dropSpeed

	if Collide() then
		StartGameover()
	end
end

function Transfer()
	local Shape = Tetros[currentTetros.shapeid].shape[currentTetros.rotation]
	for l=1, #Shape do
		for c=1, #Shape[l] do
			local cGrid = (c-1) + currentTetros.position.x
			local lGrid = (l-1) + currentTetros.position.y
			if Shape[l][c] ~= 0 then
				Grid.cells[lGrid][cGrid] = currentTetros.shapeid
			end
		end
	end
end

function RemoveLineGrid(pLine)
	-- On remonte du bas vers le haut
	for l=pLine,2,-1 do
		for c=1, Grid.width do
			Grid.cells[l][c] = Grid.cells[l-1][c]
		end
	end
end

function Collide()
	local Shape = Tetros[currentTetros.shapeid].shape[currentTetros.rotation]
	for l=1, #Shape do
		for c=1, #Shape[l] do
			local cGrid = (c-1) + currentTetros.position.x
			local lGrid = (l-1) + currentTetros.position.y
			if Shape[l][c] == 1 then
				-- Vérifie que le tetros ne sort pas de la grille sur les côtés
				if cGrid <= 0 or cGrid > Grid.width then
					return true
				end
				-- Vérifie que le tetros ne sort pas de la grille en bas
				if lGrid > Grid.height then
					return true
				end
				-- Vérifie que le tetros ne rentre pas en collision avec un autre tetros
				if Grid.cells[lGrid][cGrid] ~= 0 then
					return true
				end
			end
		end
	end
	return false
end

function InitGrid()
	local h = screen_height/Grid.height
	Grid.cellSize = h

	Grid.offsetX = ((screen_height/2) - (Grid.cellSize*Grid.width) / 2)

	Grid.cells = {}
	for l=1,Grid.height do
		Grid.cells[l] = {}
		for c=1,Grid.width do
			Grid.cells[l][c] = 0
		end
	end
end

function StartGame()
	love.graphics.setFont(fontScore)
	gameState = "play"
	dropSpeed = 1
	sndMusicMenu:stop()
	sndMusicPlay:play()
	InitBag()
	SpawnTetros()

	score = 0
	level = 1
	lines = 0
end

function StartMenu()
	love.graphics.setFont(fontMenu)
	gameState = "menu"
	sndMusicPlay:stop()
	sndMusicGameover:stop()
	sndMusicMenu:play()
end

function StartGameover()
	love.graphics.setFont(fontMenu)
	gameState = "gameover"
	sndMusicPlay:stop()
	sndMusicMenu:stop()
	sndMusicGameover:play()
end

function love.load()

	sndLevel = love.audio.newSource("levelup.wav", "static")
	sndLine = love.audio.newSource("line.wav", "static")

	sndMusicMenu = love.audio.newSource("tetris-gameboy-01.mp3", "stream")
	sndMusicMenu:setLooping(true)
	sndMusicPlay = love.audio.newSource("tetris-gameboy-02.mp3", "stream")
	sndMusicPlay:setLooping(true)
	sndMusicGameover = love.audio.newSource("tetris-gameboy-04.mp3", "stream")
	sndMusicGameover:setLooping(true)

	fontMenu = love.graphics.newFont("blocked.ttf", 50)
	fontScore = love.graphics.newFont("blocked.ttf", 30)
	love.graphics.setFont(fontMenu)

	love.keyboard.setKeyRepeat(true)
  
	screen_width = love.graphics.getWidth()
	screen_height = love.graphics.getHeight()

	InitGrid()
	StartMenu()
  
end

function UpdateMenu(dt)
	menuSin = menuSin + 60*5*dt
end

function ManageLevel()
	local newLevel = math.floor(lines/10)+1
	if newLevel <= 20 then
		if newLevel > level then
			sndLevel:play()
			level = newLevel
			dropSpeed = dropSpeed - 0.08
		end
	end
end

function UpdatePlay(dt)
	if love.keyboard.isDown("down") == false then
		pauseForceDrop = false
	end

	-- Chute du tetros
	timerDrop = timerDrop - dt
	-- Ligne suivante ?
	if timerDrop <= 0 then
		currentTetros.position.y = currentTetros.position.y + 1 
		timerDrop = dropSpeed
		if Collide() then
			currentTetros.position.y = currentTetros.position.y - 1
			Transfer()
			SpawnTetros()
		end
	end

	-- Teste si la ligne est complète
	local bLineComplete
	local nbLines = 0 
	for l=1, Grid.height do
		bLineComplete = true
		-- Parcours des colonnes de la ligne
		for c=1, Grid.width do
			if Grid.cells[l][c] == 0 then
				bLineComplete = false
				break
			end
		end
		-- Suppression de la ligne si elle est complète
		if bLineComplete == true then
			RemoveLineGrid(l)
			nbLines = nbLines + 1
		end
	end
	if nbLines > 0 then
		sndLine:play()
	end
	lines = lines + nbLines

	if nbLines == 1 then
		score = score + (100*level)
	elseif nbLines == 2 then
	    score = score + (300*level)
	elseif nbLines == 3 then
	    score = score + (400*level)
    elseif nbLines == 4 then
	    score = score + (800*level)
	end
	ManageLevel()
end

function UpdateGameover(dt)
	-- body
end

function love.update(dt)
	if gameState == "menu" then
		UpdateMenu(dt)
	elseif gameState == "play" then
	    UpdatePlay(dt)
	elseif gameState == "gameover" then
	    UpdateGameover(dt)
	end
end

function DrawGrid()
	local h = Grid.cellSize
	local w = h

	local x,y
	for l=1,Grid.height do
		for c=1,Grid.width do
			x = (c-1)*w
			y = (l-1)*h
			x = x + Grid.offsetX

			local id = Grid.cells[l][c]
			if id == 0 then
				love.graphics.setColor(255,255,255,50)
			else
				local color = Tetros[id].color
				love.graphics.setColor(color[1], color[2], color[3], 255)
			end
			love.graphics.rectangle("fill", x, y, w-1, h-1)
		end
	end
end

function DrawShape(pShape, pColor, pColumn, pLine)
	love.graphics.setColor(pColor[1], pColor[2], pColor[3], 255)

	for l=1,#pShape do 
		for c=1,#pShape[l] do
			--Calcul grille (colonnes,lignes)
			local x = (c-1)*Grid.cellSize
			local y = (l-1)*Grid.cellSize
			--Ajout position de la pièce 
			x = x + (pColumn-1)*Grid.cellSize
			y = y + (pLine-1)*Grid.cellSize
			--Ajout position de la grille
			x = x + Grid.offsetX
			--Affichage de la cellule
			if pShape[l][c] == 1 then
				love.graphics.rectangle("fill", x, y, Grid.cellSize-1, Grid.cellSize-1)
			end
		end
	end
end

function DrawMenu()
	local color
	local idColor = 1
	local sMessage = "TETRIS"
	local wMessage = fontMenu:getWidth(sMessage)
	local hMessage = fontMenu:getHeight(sMessage)
	local x = (screen_width - wMessage)/2
	local y = 0 

	for c=1, sMessage:len() do
		color = Tetros[idColor].color 
		love.graphics.setColor(color[1], color[2], color[3])
		local char = string.sub(sMessage, c, c)
		y = math.sin((x+menuSin)/50)*30
		love.graphics.print(char, x, y+(screen_height - hMessage)/2)
		x = x + fontMenu:getWidth(char)
		idColor = idColor+1
		if idColor > #Tetros then
			idColor = 1
		end
	end

end

function DrawPlay()
	local Shape = Tetros[currentTetros.shapeid].shape[currentTetros.rotation]
	DrawShape(Shape, Tetros[currentTetros.shapeid].color, currentTetros.position.x, currentTetros.position.y)

	love.graphics.setColor(255, 0, 0, 255)
	local y = 100
	local h = fontScore:getHeight("X")
	love.graphics.print("SCORE", 50, y)
	y = y + h
	love.graphics.print(tostring(score), 50, y)
	y = y + h
	y = y + h
	love.graphics.print("LEVEL", 50, y)
	y = y + h
	love.graphics.print(tostring(level), 50, y)
	y = y + h
	y = y + h
	love.graphics.print("LINES", 50, y)
	y = y + h
	love.graphics.print(tostring(lines), 50, y)
end

function DrawGameover()
	love.graphics.setColor(255, 255, 255, 255)
	local sMessage = "GAME OVER"
	local wMessage = fontMenu:getWidth(sMessage)
	local hMessage = fontMenu:getHeight(sMessage)
	love.graphics.print(sMessage, (screen_width - wMessage)/2, (screen_height - hMessage)/2)
end

function love.draw()
	DrawGrid()
	if gameState == "menu" then
		DrawMenu()
	elseif gameState == "play" then
	    DrawPlay()
	elseif gameState == "gameover" then
	    DrawGameover()
	end
end

function InputMenu(key)
	if key == "return" then
		StartGame()
	end
end

function InputPlay(key)
	-- Sauvegarder les valeurs courantes
	local oldX = currentTetros.position.x
	local oldY = currentTetros.position.y
	local oldRotation = currentTetros.rotation

	-- Déplacement du tetros
	if key == "right" then
		currentTetros.position.x = currentTetros.position.x + 1
	end

	if key == "left" then
		currentTetros.position.x = currentTetros.position.x - 1
	end

	-- Rotation du Tetros
	if key == "up" then
		currentTetros.rotation = currentTetros.rotation + 1
		if currentTetros.rotation > #Tetros[currentTetros.shapeid].shape then
			currentTetros.rotation = 1 
		end
	end
	if Collide() then
		currentTetros.position.x = oldX
		currentTetros.position.y = oldY
		currentTetros.rotation = oldRotation
	end
	if pauseForceDrop == false then
		if key == "down" then
			currentTetros.position.y = currentTetros.position.y + 1
			timerDrop = dropSpeed
		end
		if Collide() then
			currentTetros.position.y = oldY
			Transfer()
			SpawnTetros()
		end
	end

	-- Changement de Tetros
	if key == "t" then
		currentTetros.shapeid = currentTetros.shapeid + 1
		if currentTetros.shapeid > #Tetros then currentTetros.shapeid = 1 end
		currentTetros.rotation = 1
	end
end

function InputGameover(key)
	if key == "return" then
		StartMenu()
	end
end

function love.keypressed(key)
	if gameState == "menu" then
		InputMenu(key)
	elseif gameState == "play" then
	    InputPlay(key)
	elseif gameState == "gameover" then
	    InputGameover(key)
	end
end