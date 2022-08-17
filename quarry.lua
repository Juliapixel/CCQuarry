-- positive x is to the east
-- positive z is to the north
-- y is upside-down for ease of handling
-- turtle starts up facing y+ and at coords (1, 1, 1)
-- 1 = z+
-- 2 = x+
-- 3 = z-
-- 4 = x-

CurrentStatus = {
  pos = {
    x = 1,
    y = 1,
    z = 1,
  },
  cur_direction = 1,
  cur_action = "",
  target_pos = {
    x = 1,
    y = 1,
    z = 1,
  },
}

-- the file is used to recover from program stopping due to server restarts or
-- chunk unloading caused by players not being present nearby.
-- it is structured not to be human-readable, but somehow minimally
-- understandable by someone who reads this file.
-- its basic structure is laid out here:
local function updateFile(status_file)
  status_file.write(textutils.serialize(CurrentStatus))
  status_file.flush()
end

-- power loss recovery and status file initialization
local status_file

if fs.exists("/quarry_status.txt") then
  status_file = fs.open("/quarry_status.txt", "r")
  CurrentStatus = textutils.unserialize(status_file.ReadAll())
  status_file.close()
  status_file = fs.open("/quarry_status.txt", "w")
else
  status_file = fs.open("/quarry_status.txt", "w")
  -- TODO: ask for user input to initialize the quarry
  updateFile(status_file)
end

if arg[1] == "debug" then
  print(textutils.serialize(CurrentStatus))
end

-- definition of movement functions
local function turnTo(direction)
  local delta  = direction - CurrentStatus.cur_direction
  if delta == -1 or delta == 3 then
    turtle.turnLeft()
  else
    for i = 1, delta do
      turtle.turnRight()
    end
  end
end

local function moveUp()
  if turtle.up() then
    CurrentStatus.pos.y = CurrentStatus.pos.y - 1
  else
    --TODO: deal with movement errors
  end
end

local function moveDown()
  if turtle.down() then
    CurrentStatus.pos.y = CurrentStatus.pos.y + 1
  else
    --TODO: deal with movement errors
  end
end

local function moveForward()
  if turtle.forward() then
    if CurrentStatus.cur_direction == 1 then
      CurrentStatus.pos.y = CurrentStatus.pos.z + 1
    elseif CurrentStatus.cur_direction == 2 then
      CurrentStatus.pos.y = CurrentStatus.pos.x + 1
    elseif CurrentStatus.cur_direction == 3 then
      CurrentStatus.pos.y = CurrentStatus.pos.z - 1
    elseif CurrentStatus.cur_direction == 4 then
      CurrentStatus.pos.y = CurrentStatus.pos.x - 1
    end
  else
    --TODO: deal with movement errors
  end
end

local function moveBackward()
  if turtle.up() then
    if CurrentStatus.cur_direction == 1 then
      CurrentStatus.pos.y = CurrentStatus.pos.z - 1
    elseif CurrentStatus.cur_direction == 2 then
      CurrentStatus.pos.y = CurrentStatus.pos.x - 1
    elseif CurrentStatus.cur_direction == 3 then
      CurrentStatus.pos.y = CurrentStatus.pos.z + 1
    elseif CurrentStatus.cur_direction == 4 then
      CurrentStatus.pos.y = CurrentStatus.pos.x + 1
    end
  else
    --TODO: deal with movement errors
  end
end

-- used for big movements, such as refuelling, storing, returning to start, etc.
local function moveTo(x, y, z)
  local delta_x = x - CurrentStatus.pos.x
  local delta_y = y - CurrentStatus.pos.y
  local delta_z = z - CurrentStatus.pos.z
  if delta_y < 0 then
    for i = 1, math.abs(delta_y), 1 do
      moveUp()
    end
  end
  if delta_x < 0 then
    turnTo(4)
    for i = 1, math.abs(delta_x) do
      moveForward()
    end
  elseif delta_x > 0 then
    turnTo(2)
    for i = 1, delta_x do
      moveForward()
    end
  end
  if delta_z < 0 then
    turnTo(3)
    for i = 1, math.abs(delta_z) do
      moveForward()
    end
  elseif delta_z > 0 then
    turnTo(1)
    for i = 1, delta_z do
      moveForward()
    end
  end
  if delta_y > 0 then
    for i = 1, delta_y, 1 do
      moveDown()
    end
  end
end