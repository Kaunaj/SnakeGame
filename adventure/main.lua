-- Dimensions
TILE_SIZE = 32
WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 640

-- No. of tiles on game window
MAX_TILES_X = WINDOW_WIDTH / TILE_SIZE
MAX_TILES_Y = WINDOW_HEIGHT / TILE_SIZE

-- What's in a particular tile
TILE_EMPTY = 0
TILE_SNAKE_HEAD = 1
TILE_SNAKE_BODY = 2
TILE_APPLE = 3
TILE_STONE = 4

local level = 1

-- How fast the snake moves
SNAKE_SPEED = math.max(0.06, (0.21 - level * 0.03))

local largeFont = love.graphics.newFont(32)
local hugeFont = love.graphics.newFont(128)

local appleSound = love.audio.newSource('apple.wav', 'static')
local newLevelSound = love.audio.newSource('newlevel.wav', 'static')
local gameOverSound = love.audio.newSource('gameover.wav', 'static')

local score = 0
local gameOver = false
local gameStart = true
local newLevel = true
local gameFinish = false

-- Create an empty table
local tileGrid = {}

-- Default values of some variables that change later
local snakeMoving = 'right'
local snakeX, snakeY = 1, 1
local snakeTimer = 0

-- Snake data structure
snakeTiles = {
    {snakeX, snakeY},
}

function love.load()
    love.window.setTitle("Serpent's feast")
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false
    })
    love.graphics.setFont(largeFont)
    math.randomseed(os.time())

    initializeGrid()
    initializeSnake()

    tileGrid[snakeTiles[1][1]][snakeTiles[1][2]] = TILE_SNAKE_HEAD
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
    if not gameOver then
        if key == 'left' and snakeMoving ~= 'right' then
            snakeMoving = 'left'
        elseif key == 'right' and snakeMoving ~= 'left' then
            snakeMoving = 'right'
        elseif key == 'up' and snakeMoving ~= 'down' then
            snakeMoving = 'up'
        elseif key == 'down' and snakeMoving ~= 'up' then
            snakeMoving = 'down'
        end
    end

    if newLevel then
        if key == 'space' then
            newLevel = false
        end
    end

    if gameStart or gameOver or gameFinish then
        if key == 'enter' or key == 'return' then
            score = 0
            level = 1
            SNAKE_SPEED = math.max(0.06, (0.21 - level * 0.03))
            initializeGrid()
            initializeSnake()
            gameStart = false
            gameOver = false
            gameFinish = false
        end
    end
end

-- The calculations happen here
-- dt = delta time; the time between two frames
function love.update(dt)
    if not gameOver and not newLevel and not gameFinish then
        snakeTimer = snakeTimer + dt
        local priorHeadX, priorHeadY = snakeX, snakeY

        if snakeTimer >= SNAKE_SPEED then
            if snakeMoving == 'up' then
                if snakeY <= 1 then
                    snakeY = MAX_TILES_Y
                else
                    snakeY = snakeY - 1
                end
            elseif snakeMoving == 'down' then
                if snakeY >= MAX_TILES_Y then
                    snakeY = 1
                else
                    snakeY = snakeY + 1
                end
            elseif snakeMoving == 'left' then
                if snakeX <= 1 then
                    snakeX = MAX_TILES_X
                else
                    snakeX = snakeX - 1
                end
            elseif snakeMoving == 'right' then
                if snakeX >= MAX_TILES_X then
                    snakeX = 1
                else
                    snakeX = snakeX + 1
                end
            end

            -- Push a new head element onto the snake data structure (the model)
            table.insert(snakeTiles, 1, {snakeX, snakeY})

            -- Game over if snake runs into itself or a stone
            if tileGrid[snakeX][snakeY] == TILE_SNAKE_BODY or 
                tileGrid[snakeX][snakeY] == TILE_STONE then

                gameOver = true
                gameOverSound:play()

            end

            -- Now we need to update tileGrid (the view)

            -- If snake ate an apple
            if tileGrid[snakeX][snakeY] == TILE_APPLE then
                -- Increment score by 1
                score = score + 1

                -- Play apple sound
                appleSound:play()

                -- Increase level if player reaches a certain score
                if score == (level * 10) then
                    if level < 5 then
                        level = level + 1
                    else
                        gameFinish = true
                    end
                    SNAKE_SPEED = math.max(0.06, (0.21 - level * 0.03))
                    newLevel = true
                    initializeGrid()
                    initializeSnake()
                    newLevelSound:play()

                    return
                end

                -- Spawn a new apple somewhere else
                generateThing(TILE_APPLE)

                -- Don't pop off the tail
            
            -- Otherwise, snake moves normally
            else
                -- Pop off the tail in tileGrid (the view)
                local tail = snakeTiles[#snakeTiles]
                tileGrid[tail[1]][tail[2]] = TILE_EMPTY
                
                -- Remove the tail from the snake data structure (the model)
                table.remove(snakeTiles) -- by default, removes the last element in table
            end

        -- If snake is longer than 1 tile
            if #snakeTiles > 1 then
                -- Set prior head to a body value (to see color change)
                tileGrid[priorHeadX][priorHeadY] = TILE_SNAKE_BODY
            end
            -- Update snake head at new location
            tileGrid[snakeX][snakeY] = TILE_SNAKE_HEAD

            snakeTimer = 0
        end
    end
end

function love.draw()
    if gameStart then
        love.graphics.setFont(hugeFont)
        love.graphics.printf(
            "SNAKE",
            0, WINDOW_HEIGHT/2 - 96,
            WINDOW_WIDTH, 'center'
        )
        love.graphics.setFont(largeFont)
            love.graphics.printf(
            'Press Enter to begin', 
            0, WINDOW_HEIGHT/2 + 96,
            WINDOW_WIDTH, 'center'
        )
    elseif gameFinish then
        drawGameFinish()
    else
        drawGrid()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Score: " .. tostring(score), 10, 10)
        love.graphics.printf("Level: " .. tostring(level), 0, 10, WINDOW_WIDTH - 10, 'right')
        
        if newLevel then
            love.graphics.setFont(hugeFont)
            love.graphics.printf(
                "LEVEL " .. tostring(level),
                0, WINDOW_HEIGHT/2 - 96,
                WINDOW_WIDTH, 'center'
            )
            love.graphics.setFont(largeFont)
            love.graphics.printf(
                'Press Space to continue', 
                0, WINDOW_HEIGHT/2 + 96,
                WINDOW_WIDTH, 'center'
            )
        elseif gameOver then
            drawGameOver()
        end
    end
end

function drawGameFinish()
    love.graphics.setFont(hugeFont)
    love.graphics.printf(
        'Congrats!', 
        0, WINDOW_HEIGHT/2 - 96, 
        WINDOW_WIDTH, 'center'
    )
    
    love.graphics.setFont(largeFont)
    love.graphics.printf(
        'Thanks human, me full now ^-^', 
        0, WINDOW_HEIGHT/2 + 96,
        WINDOW_WIDTH, 'center'
    )

    love.graphics.setFont(largeFont)
    love.graphics.printf(
        'Press Enter to start new game', 
        0, WINDOW_HEIGHT/2 + 160,
        WINDOW_WIDTH, 'center'
    )
end

function drawGameOver()
    love.graphics.setFont(hugeFont)
    love.graphics.printf(
        'GAME OVER', 
        0, WINDOW_HEIGHT/2 - 96, 
        WINDOW_WIDTH, 'center'
    )
    
    love.graphics.setFont(largeFont)
    love.graphics.printf(
        'God dammit! Me hungry still ._.', 
        0, WINDOW_HEIGHT/2 + 96,
        WINDOW_WIDTH, 'center'
    )

    love.graphics.setFont(largeFont)
    love.graphics.printf(
        'Press Enter to restart', 
        0, WINDOW_HEIGHT/2 + 160,
        WINDOW_WIDTH, 'center'
    )
end

function drawGrid()
    for x = 1, MAX_TILES_X do
        for y = 1, MAX_TILES_Y do
            -- do nothing on empty tiles
            if tileGrid[x][y] == TILE_EMPTY then
                -- pass
            
            -- cyanish color for snake head
            elseif tileGrid[x][y] == TILE_SNAKE_HEAD then
                love.graphics.setColor(0, 1, 0.5, 1)
                love.graphics.rectangle(
                    'fill', 
                    (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE, 
                    TILE_SIZE, TILE_SIZE
                )
                -- Snake Eyes
                love.graphics.setColor(0, 0, 0, 1)

                if snakeMoving == 'right' or snakeMoving == 'left' then
                    love.graphics.circle(
                        'fill', 
                        (x - 0.5) * TILE_SIZE, (y - 0.8) * TILE_SIZE,
                        3
                    )
                    love.graphics.circle(
                        'fill', 
                        (x - 0.5) * TILE_SIZE, (y - 0.2) * TILE_SIZE,
                        3
                    )
                
                elseif snakeMoving == 'up' or snakeMoving == 'down' then
                    love.graphics.circle(
                        'fill', 
                        (x - 0.2) * TILE_SIZE, (y - 0.5) * TILE_SIZE,
                        3
                    )
                    love.graphics.circle(
                        'fill', 
                        (x - 0.8) * TILE_SIZE, (y - 0.5) * TILE_SIZE,
                        3
                    )
                end

            -- a slightly dark green body color
            elseif tileGrid[x][y] == TILE_SNAKE_BODY then
                love.graphics.setColor(0, 0.7, 0.2, 0.7)
                love.graphics.rectangle(
                    'fill', 
                    (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE, 
                    TILE_SIZE, TILE_SIZE
                )
            
            -- red filling for tile with apple
            elseif tileGrid[x][y] == TILE_APPLE then
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.rectangle(
                    'fill',
                    (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE,
                    TILE_SIZE, TILE_SIZE
                )

            -- grayish filling for tile with stone
            elseif tileGrid[x][y] == TILE_STONE then
                love.graphics.setColor(0.7, 0.7, 0.7, 1)
                love.graphics.rectangle(
                    'fill',
                    (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE,
                    TILE_SIZE, TILE_SIZE
                )
            end
        end
    end
end

function generateThing(thing)
    -- The thing could be an apple or a stone
    local thingX, thingY

    repeat
        thingX, thingY = math.random(MAX_TILES_X), math.random(MAX_TILES_Y)
    until tileGrid[thingX][thingY] == TILE_EMPTY

    tileGrid[thingX][thingY] = thing
end

function initializeSnake()
    snakeMoving = 'right'
    snakeX, snakeY = 1, 1
    snakeTiles = {
        {snakeX, snakeY}
    }
    tileGrid[snakeTiles[1][1]][snakeTiles[1][2]] = TILE_SNAKE_HEAD
end

function initializeGrid()
    tileGrid = {}
    for x = 1, MAX_TILES_X do
        table.insert(tileGrid, {})
        for y = 1, MAX_TILES_Y do
            table.insert(tileGrid[x], TILE_EMPTY)
        end
    end

    for i = 1, math.min(20, level * 4) do
        generateThing(TILE_STONE)
    end
    generateThing(TILE_APPLE)
end