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
  is_near_bedrock = false,
}

-- the file is used to recover from program stopping due to server restarts or
-- chunk unloading caused by players not being present nearby.
-- it is merely a serialization of the CurrentStatus table.
local status_file

local function updateFile()
  status_file.write(textutils.serialize(CurrentStatus))
  status_file.flush()
end

if fs.exists("/quarry_status.txt") then
  status_file = fs.open("/quarry_status.txt", "r")
  CurrentStatus = textutils.unserialize(status_file.readAll())
  status_file.close()
  status_file = fs.open("/quarry_status.txt", "w")
else
  status_file = fs.open("/quarry_status.txt", "w")
  write("Desired width: ")
  CurrentStatus.target_pos.x = tonumber(read())
  write("Desired length: ")
  CurrentStatus.target_pos.z = tonumber(read())
  write("Desired depth: ")
  CurrentStatus.target_pos.y = tonumber(read())
  updateFile()
end

local function deleteJob()
  fs.delete("/quarry_status.txt")
  os.exit()
end

-- definition of movement functions
local function turnTo(direction)
  local delta  = direction - CurrentStatus.cur_direction
  if delta == -1 or delta == 3 then
    turtle.turnLeft()
    local temp_dir = CurrentStatus.cur_direction - 1
    if temp_dir == 0 then
      CurrentStatus.cur_direction = 4
    else
      CurrentStatus.cur_direction = temp_dir
    end
  else
    for i = 1, math.abs(delta) do
      turtle.turnRight()
      local temp_dir = CurrentStatus.cur_direction + 1
      if temp_dir == 5 then
        CurrentStatus.cur_direction = 1
      else
        CurrentStatus.cur_direction = temp_dir
      end
    end
  end
end

local function moveUp()
  if turtle.up() then
    CurrentStatus.pos.y = CurrentStatus.pos.y - 1
  else
    --TODO: deal with movement errors
  end
  updateFile()
end

local function moveDown()
  if turtle.down() then
    CurrentStatus.pos.y = CurrentStatus.pos.y + 1
  else
    --TODO: deal with movement errors
  end
  updateFile()
end

local function moveForward()
  if turtle.forward() then
    if CurrentStatus.cur_direction == 1 then
      CurrentStatus.pos.z = CurrentStatus.pos.z + 1
    elseif CurrentStatus.cur_direction == 2 then
      CurrentStatus.pos.x = CurrentStatus.pos.x + 1
    elseif CurrentStatus.cur_direction == 3 then
      CurrentStatus.pos.z = CurrentStatus.pos.z - 1
    elseif CurrentStatus.cur_direction == 4 then
      CurrentStatus.pos.x = CurrentStatus.pos.x - 1
    end
    updateFile()
  else
    --TODO: deal with movement errors
  end
end

local function moveBackward()
  if turtle.up() then
    if CurrentStatus.cur_direction == 1 then
      CurrentStatus.pos.z = CurrentStatus.pos.z - 1
    elseif CurrentStatus.cur_direction == 2 then
      CurrentStatus.pos.x = CurrentStatus.pos.x - 1
    elseif CurrentStatus.cur_direction == 3 then
      CurrentStatus.pos.z = CurrentStatus.pos.z + 1
    elseif CurrentStatus.cur_direction == 4 then
      CurrentStatus.pos.x = CurrentStatus.pos.x + 1
    end
    updateFile()
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
    for i = 1, math.abs(delta_y) do
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
    for i = 1, delta_y do
      moveDown()
    end
  end
end

-- does default mining stuffs while respecting the zone boundaries
local function mineForward()
  local is_facing_border = (
    (
      CurrentStatus.cur_direction == 1 and CurrentStatus.pos.z == CurrentStatus.target_pos.z
    ) or (
      CurrentStatus.cur_direction == 3 and CurrentStatus.pos.z == 1
    ) or (
      CurrentStatus.cur_direction == 2 and CurrentStatus.pos.x == CurrentStatus.target_pos.x
    ) or (
      CurrentStatus.cur_direction == 4 and CurrentStatus.pos.x == 1
    )
  )
  if not is_facing_border then
    turtle.dig()
  end
  if not CurrentStatus.pos.y == CurrentStatus.target_pos.y then
    turtle.digDown()
  end
  if not CurrentStatus.pos.y == 1 then
    turtle.digUp()
  end
end

if arg[1] == "debug" then
  print(textutils.serialize(CurrentStatus))
elseif arg[1] == "test" then
  moveTo(3, 3, 3)
  sleep(1)
  moveTo(1, 1, 1)
  turnTo(1)
  deleteJob()
end
