pico-8 cartridge // http://www.pico-8.com
version 23
__lua__
-- centers a string by adding padding to it
function center(string)
 for i = 1, (31 - #string) / 2 do
  string = " "..string
 end
 return string
end

-- pads a number to the right so it takes |length| spaces
function pad(num, length)
 local string = tostr(num)
 for i = #string, length - 1 do
  string = "0"..string
 end
 return string
end

function clamp(a)
 return flr(a * 8) / 8
end

k_max_safe_number = sqrt(0x7fff)
function normalize(x, y)
 local l
 -- prevent overflow
 if x >= k_max_safe_number or
    x <= -k_max_safe_number or
    y >= k_max_safe_number or
    y <= -k_max_safe_number then
  local nx = x * 0x0.01
  local ny = y * 0x0.01
  l = sqrt(nx * nx + ny * ny) * 0x100
 else
  l = sqrt(x * x + y * y)
 end

 return { x = x / l, y = y / l }
end

function vector_to_player(element)
 return normalize(x - element.x, y - element.y)
end

function get_random_corner()
 local corner = flr(rnd(4))
 if corner == 0 then
  -- top left
  return { x = 0, y = 0 }
 elseif corner == 1 then
  -- top right
  return { x = map_width - 24, y = 0 }
 elseif corner == 2 then
  -- bottom right
  return { x = map_width - 24, y = map_height - 24 }
 else
  -- bottom left
  return { x = 0, y = map_height - 24 }
 end
end

function update(elements)
 for element in all(elements) do
  element.x += element.dx
  element.y += element.dy

  if element.loops then
   if element.x > map_width + 4 then
    element.x = -3
   elseif element.x < -4 then
    element.x = map_width - 3
   end
   if element.y > map_height then
    element.y = -3
   elseif element.y < -4 then
    element.y = map_height - 3
   end
  end


  if element.life then
   element.life -= 1
   if element.life <= 0 then
    del(elements, element)
   end
  end
 end
end

function kill_enemy(enemy, explodes)
 if explodes then
  sfx(2)
  enemy.life = 54
 else
  sfx(24)
  enemy.life = 0
 end
 enemy.state = "dead"
 enemy.dx = 0
 enemy.dy = 0
end

function damage_player(dmg)
 hit = true
 hp -= dmg
 if hp <= 0 then
  state = "dead"
  music(-1)
  sfx(2)
  time_death = 54
 end
end

function update_kill(enemies, explodes)
 for enemy in all(enemies) do
  if colliding(
       { x = enemy.x, y = enemy.y },
       { x = x + 4, y = y + 4}) and enemy.state != "dead" then
   damage_player(enemy.dmg)
   kill_enemy(enemy, explodes)
  end
 end
end

function collide_enemies(enemies, explodes)
 for shot in all(shots) do
  for enemy in all(enemies) do
   if colliding(enemy, shot) and
      enemy.state != "dead" then
    kill_enemy(enemy, explodes)
    score += 10
    del(shots, shot)
   end
  end
 end
end

-- returns whether |e1| and |e2| are colliding
function colliding(entity, shot)
 return entity.x <= shot.x and shot.x <= entity.x + 8 and
        entity.y <= shot.y and shot.y <= entity.y + 8
end

-- returns the explosion sprite for |life|
function explosion_for(life)
 return 22 + 6 - life \ 9
end

function spawn_coordinates(list)
 local loops = 0
 while true do
  local nx = rnd(map_width - 20) + 10
  local ny = rnd(map_height - 20) + 10

  if abs(nx - x) >= map_width / 16 and
     abs(ny - y) >= map_height / 16 then
   if loops > 1000 then return { x = nx, y = ny } end
   local good = true
   for element in all(list) do
    if abs(element.x - nx) <= 10 or
       abs(element.y - ny) <= 10 then
     good = false
     break
    end
   end
   if good then return { x = nx, y = ny } end
  end
  loops += 1
 end
end

function _init()
 -- reserve channels 1, 2 and 3 for music
 music(-1, 0, 14)
 game_over_messages = {
  "hahaha, git good scrub",
  "you suuuuuuuck",
  "git good, noob",
  "l2p  scrub",
  "get duuuuuuuunked on",
 }
 astro_dead_messages = {
  "you're supposed to rescue them",
  "you suck at your job",
  "actually i never liked them",
  "are you blind or something?",
  "how did you get your license?",
  "bruh, not cool man",
  "you were the chosen one!",
 }
 messages = {
  "i saw an alien eat a man whole",
  "i thought i wasn't making it",
  "i'm glad you came for me",
  "it's too bad they didn't live",
  "i miss my girlfriend",
  "my oxygen was running low",
  "i was so scared",
  "i thought i was going to die",
  "thank you fellow 'human'!",
  "actually i wanted to die",
  "took you long enough",
  "this ship is too small, mate",
  "this scrap you call ship?",
  "spaaaaaaaaaaaace",
  "no te molestes en traducir esto",
  "beam me up scotty",
  "start the lazarus project",
  "save the animals!!!",
  "i'm definitely not a cylon",
  "the force is strong in you",
  "you only do this for the points",
  "good news everyone!",
  "need saving? why not zoidberg?",
  "rocket maaaaaaaaaan!",
 }
 restart()
 state = "intro"

 intro_messages = {
  {
   text = center("it is the year 21xx"),
   delay = 0,
  },
  {
   text = center("humans are losing the war"),
   delay = 2,
  },
  {
   text = center("pilots of the galactic squad"),
   delay = 4,
  },
  {
   text = center("are stranded"),
   delay = 5,
  },
  {
   text = center("your mission:"),
   delay = 7.
  },
  {
   text = center("space  rescue"),
   delay = 9,
  },
 }
end

function restart()
 current_message = nil
 current_message_color = nil
 message_timer = 0
 score = 0
 level = 1
 state = "menu"
 start()
end

function start()
 map_width = 256
 map_height = 128
 hp = 8
 x = map_width / 2
 dx = 0
 y = map_height / 2
 dy = 0
 a = 0
 s = 0
 camera_x = x - 56 + dx * 30
 camera_y = y - 56 + dy * 30
 fire = false

 parts = {}
 shots = {}

 stars = {}
 for i = 1, map_height / 100 * map_width / 10 do
  local r = flr(rnd(4))
  local color
  if r == 0 then
   color = 6
  elseif r == 1 then
   color = 7
  elseif r == 2 then
   color = 10
  else
   color = 15
  end
  stars[i] = { x = rnd(map_width),
               y = rnd(map_height),
               color = color }
 end

 astros = {}
 --for i = 1, 2 + level * 3 do
 for i = 1, 0 do
  local c = spawn_coordinates(astros)
  astros[i] = { x = c.x,
                y = c.y,
                dx = 0,
                dy = 0,
                loops = true, }
 end

 debris = {}
 --for i = 1, 6 + level * 3 do
 for i = 1, 0 do
  local c = spawn_coordinates(debris)
  debris[i] = { x = c.x,
                y = c.y,
                dx = rnd(1) - 0.5,
                dy = rnd(1) - 0.5,
                sp = flr(rnd(6)) + 16,
                dmg = 3,
                loops = true }
 end

 octopi = {}
 --for i = 1, 10 + level * 2 do
 for i = 1, 0 do
  local c = spawn_coordinates(octopi)
  octopi[i] = { x = c.x,
                y = c.y,
                dx = rnd(0.3) - 0.15,
                dy = rnd(0.3) - 0.15,
                cd = 0,
                dmg = 2,
                loops = true }
 end

 chompers = {}
 for i = 1, 0 do
 --for i = 1, (level - 1) * 2 do
  local c = spawn_coordinates(chompers)
  local a = clamp(rnd(1))
  chompers[i] = { x = c.x,
                  y = c.y,
                  dx = sin(a) * 0.25,
                  dy = cos(a) * 0.25,
                  cd = 0,
                  state = "idle",
                  speed = 0.25,
                  dmg = 3,
                  loops = true }
 end

 eyes = {}
 for i = 1, 0 do
 --for i = 1, (level - 2) * 3 do
  local c = spawn_coordinates(eyes)
  local a = clamp(rnd(1))
  eyes[i] = { x = c.x,
              y = c.y,
              dx = sin(a) * 0.1,
              dy = cos(a) * 0.1,
              cd = 0,
              state = "idle",
              dmg = 4,
              loops = true }
 end

 lookouts = {}
 missiles = {}
 for i = 1, 0 do
 --for i = 1, (level - 2) * 2 do
  local c = spawn_coordinates(lookouts)
  lookouts[i] = { x = c.x,
                  y = c.y,
                  dx = rnd(0.3) - 0.15,
                  dy = rnd(0.3) - 0.15,
                  cd = 0,
                  dmg = 2,
                  state = "charged",
                  a = 0,
                  loops = true }
 end

 shells = {}
 for i = 1, 0 do
 --for i = 1, (level - 3) * 2 do
  local c = spawn_coordinates(shells)
  shells[i] = { x = c.x,
                y = c.y,
                dx = rnd(0.06) - 0.03,
                dy = rnd(0.06) - 0.03,
                cd = 10,
                dmg = 3,
                bullets_fired = 0,
                state = "closed",
                loops = true }
 end

 healthpacks = {}
 for i = 1, rnd(3) + 1 do
  local c = spawn_coordinates(lookouts)
  healthpacks[i] = { x = c.x,
                     y = c.y,
                     dx = 0,
                     dy = 0,
                     loops = true }
 end

 boss = {
  x = map_width / 2,
  y = 20,
  dx = 0,
  dy = 0.1,
  state = "intro",
  dmg = 99,
  hp = 4,
  --hp = 30,
  hit = false,
  invuln = true,
  cd = 0,
  shots_fired = 0,
  explosions = {},
  astros = {},
  flames = {},
  loops = false,
 }


 bullets = {}
end

function particle_for(x, y, dx, dy, color)
 if flr((time() * 1000) % 2) == 0 then
  add(parts, {
   x = x - dx + 4,
   y = y - dy + 4,
   dx = -dx + rnd(.6) - .3,
   dy = -dy + rnd(.6) - .3,
   life = flr(rnd(10) + 10),
   color = color,
   loops = false,
  })
 end
end

function _update60()
 -- global actions

 if message_timer > 0 then
  message_timer -= 1
  if message_timer <= 0 then
   current_message = nil
   current_message_color = nil
  end
 end

 if state == "dead" then
  time_death -= 1
  if time_death <= 0 then
   state = "game over"
   sfx(1)
   game_over_message = game_over_messages[flr(rnd(#game_over_messages)) + 1]
  end
  return
 end

 if state == "menu" then
  if btnp(🅾️) then
   state = "alive"
   music(0)
  end
  return
 end

 if state == "next level" then
  if btnp(🅾️) then
   level += 1
   music(0)
   start()
   state = "alive"
  end
  return
 end

 if state == "game over" then
  if btnp(🅾️) then
   restart()
  end
  return
 end

 -- intro
 if state == "intro" then
  if btnp(🅾️) then
   state = "menu"
  end
  return
 end

 -- actions when game is running

 -- control the player

 -- radar controls
 if state == "radar" then
  if btnp(❎) then
   state = "alive"
  end

 -- flight controls
 elseif state == "alive" then
  if btnp(❎) then
   state = "radar"
  end
  if btn(⬅️) then
    a -= .02
  end
  if btn(➡️) then
   a += .02
  end
  if btn(⬆️) then
   s += .03
  end
  if btn(⬇️) then
   s -= .03
  end
  if btn(🅾️) and fire == false then
   fire = true
   local l =
    sqrt(dx * dx + dy * dy)
   add(shots, {
    x = x + 4,
    y = y + 4,
    dx = dx / l * 3,
    dy = dy / l * 3,
    life = 20,
    loops = false,
   })
   sfx(0)
  elseif not btn(🅾️) then
   fire = false
  end
 end

 if state == "alive" or state == "radar" then
  -- move the ship
  s = mid(0.3, s, 1.3)
  if a >= 1 then a -= 1 end
  if a < 0 then a += 1 end
  dx = sin(clamp(a) - .25) * s
  dy = cos(clamp(a) - .25) * s
  x += dx
  y += dy
  if x >= map_width + 40 then
   x = -60
  elseif x < -60 then
   x = map_width + 40
  end
  if y >= map_height + 40 then
   y = -60
  elseif y < -60 then
   y = map_height + 40
  end

  -- rescue astronauts
  for astro in all(astros) do
   if colliding(
        astro,
        { x = x + 4, y = y + 4 }) and
      astro.state != "dead" then
    del(astros, astro)
    score += 100
    sfx(3)
    current_message = messages[flr(rnd(#messages)) + 1]
    current_message_color = 12
    message_timer = 180
    if #astros <= 0 then
     music(-1)
     state = "next level"
     return
    end
   end
  end

  -- get healthpacks
  for healthpack in all(healthpacks) do
   if colliding(
        healthpack,
        { x = x + 4, y = y + 4 }) and
      healthpack.state != "dead" then
    del(healthpacks, healthpack)
    hp = 8
    sfx(3)
   end
  end

  -- have some octopi fire
  for octopus in all(octopi) do
   if abs(octopus.x - x) <= 50 and
      abs(octopus.y - y) <= 50 and
      octopus.state != "dead" and
      octopus.cd <= 0 then
    local v = vector_to_player(octopus)
    add(bullets, {
     x = octopus.x,
     y = octopus.y,
     dx = v.x * 1.2,
     dy = v.y * 1.2,
     life = 100,
     dmg = 2,
     loops = false,
    })
    octopus.cd = rnd(40) + 50
   elseif octopus.cd > 0 then
    octopus.cd -= 1
   end
  end

  -- make chompers chase the player
  for chomper in all(chompers) do
   if abs(chomper.x - x) <= 40 and
      abs(chomper.y - y) <= 40 and
      chomper.state != "dead" then
    local v = vector_to_player(chomper)
    local a = clamp(atan2(v.x, v.y))
    chomper.dx = cos(a) * chomper.speed
    chomper.dy = sin(a) * chomper.speed
    if chomper.state == "idle" then
     chomper.state = "chasing"
     chomper.burst = 120 + rnd(120)
     chomper.speed = 1
    else
     chomper.burst -= 1
     if chomper.burst <= 0 then
      chomper.speed = 0.25
     end
    end
   elseif chomper.state == "chasing" then
    local a = clamp(rnd(1))
    chomper.dx = sin(a) * 0.25
    chomper.dy = cos(a) * 0.25
    chomper.state = "idle"
   end
  end

  -- make eyes fire
  for eye in all(eyes) do
   if abs(eye.x - x) <= 50 and
      abs(eye.y - y) <= 50 then
    if eye.state == "idle" and eye.cd <= 0 then
     eye.state = "charging"
     eye.cd = 40
    elseif eye.state == "charging" and eye.cd <= 0 then
     -- fire
     for i = 1, 8 do
      add(bullets, {
       x = eye.x,
       y = eye.y,
       dx = sin(i / 8),
       dy = cos(i / 8),
       life = 100,
       dmg = 2,
       loops = false,
      })
     end
     eye.state = "idle"
     eye.cd = 120
    end
   end
   if eye.cd > 0 then
    eye.cd -= 1
   end
  end

  -- make lookouts fire their missiles
  for lookout in all(lookouts) do
   local v = vector_to_player(lookout)
   lookout.a = clamp(atan2(v.x, -v.y))
   if abs(lookout.x - x) <= 50 and
      abs(lookout.y - y) <= 50 and
      lookout.state == "charged" then
    lookout.state = "charging"
    add(missiles, {
     x = lookout.x,
     y = lookout.y,
     dx = 0,
     dy = 0,
     life = 650,
     dmg = 4,
     speed = 0.15,
     loops = false,
    })
    lookout.cd = 400
   elseif lookout.state == "charging" and lookout.cd >= 0 then
    lookout.cd -= 1
    if lookout.cd <= 0 then
     lookout.state = "charged"
    end
   end
  end

  -- update missiles
  for missile in all(missiles) do
   if missile.state != "dead" then
    if missile.life <= 1 then
     missile.state = "dead"
     missile.life = 54
     sfx(2)
    elseif missile.life <= 150 then
     missile.speed = max(0.05, missile.speed - 0.01)
    else
     local v = vector_to_player(missile)
     missile.a = clamp(atan2(v.x, v.y))
     missile.speed = min(1.32, missile.speed + 0.0025)
     particle_for(missile.x, missile.y, missile.dx, missile.dy, 11)
    end
    missile.dx = cos(missile.a) * missile.speed
    missile.dy = sin(missile.a) * missile.speed
   end
  end

  -- make shells fire
  for shell in all(shells) do
   if shell.cd > 0 then
    shell.cd -= 1
   end

   if shell.state != "dead" then
    if abs(shell.x - x) <= 50 and
       abs(shell.y - y) <= 50 and
       shell.cd <= 0 and
       shell.state == "closed" then
     shell.bullets_fired = 0
     shell.state = "open"
     shell.cd = min(shell.cd, 20)
    elseif abs(shell.x - x) >= 50 and
           abs(shell.y - y) >= 50 and
           shell.state == "open" then
     shell.state = "closed"
    elseif shell.state == "open" and
           shell.bullets_fired <= 24 and
           shell.cd <= 0 then
     shell.bullets_fired += 1
     if shell.bullets_fired > 24 then
      shell.cd = 200
     else
      shell.cd = 5
     end
     local v = vector_to_player(shell)
     local angle_diff = (shell.bullets_fired - 6) / 8
     local dv = normalize(v.x + sin(angle_diff) * 0.3,
                          v.y + cos(angle_diff) * 0.3)
     add(bullets, {
      x = shell.x,
      y = shell.y,
      dx = dv.x * 1.2,
      dy = dv.y * 1.2,
      life = 100,
      dmg = 1,
      loops = false,
     })
    elseif shell.state == "open" and
           shell.cd <= 0 and
           shell.bullets_fired > 24 then
     shell.bullets_fired = 0
     shell.state = "closed"
     shell.cd = 300
    end
   end
  end

  -- collide with enemies
  update_kill(debris, true)
  update_kill(octopi, true)
  update_kill(bullets, false)
  update_kill(chompers, true)
  update_kill(eyes, true)
  update_kill(lookouts, true)
  update_kill(missiles, true)
  update_kill(shells, true)

  -- maybe create a new particle
  particle_for(x, y, dx, dy, 9)
 end  -- end if state == "alive" or state == "radar"

 -- collide shots with debris
 for shot in all(shots) do
  for debri in all(debris) do
  if colliding(debri, shot) then
   del(shots, shot)
   end
  end
 end

 -- collide shots with closed shells
 for shot in all(shots) do
  for shell in all(shells) do
  if colliding(shell, shot) and shell.state == "closed" then
   del(shots, shot)
   end
  end
 end

 -- update the boss
 if boss then
  -- update all the boss' elements
  update(boss.explosions)
  update(boss.astros)
  update_kill(boss.astros, true)
  collide_enemies(boss.astros, true)
  update(boss.flames)
  update_kill(boss.flames, false)

  for astro in all(boss.astros) do
   if astro.state != "dead" then
    if astro.life <= 1 then
     astro.state = "dead"

     for i = 1, 8 do
      add(bullets, {
       x = astro.x,
       y = astro.y,
       dx = sin(i / 8),
       dy = cos(i / 8),
       life = 300,
       dmg = 2,
       loops = false,
      })
     end
    end
   end
  end

  -- collide the boss with the player
  if boss.state != "dying" and boss.state != "dead" and
     boss.x - 8 <= x and x <= boss.x + 24 and
     boss.y - 8 <= y and y <= boss.y + 24 then
   -- colliding with the boss instantly kills the player :)
   damage_player(9999)
  end

  -- handle the boss death animation
  if boss.state == "dying" then
   if boss.cd > 0 then
    sfx(2)
    add(boss.explosions, {
     life = 54,
     x = boss.x + rnd(16),
     y = boss.y + rnd(16),
     dx = 0,
     dy = 0,
     loops = false,
    })
   else
    boss.state = "dead"
   end
  end

  if boss.cd > 0 then boss.cd -= 1 end
  if boss.hit then boss.hit = false end

  -- bring the boss into the screen
  if boss.state == "intro" then
   if boss.y >= map_height / 4 then
    -- TODO: revert this change
    --boss.state = "astrofire"
    boss.state = "flamethrower_position"
    boss.dx = 0
    boss.dy = 0
    boss.shots_fired = 0
    boss.invuln = false
   end
  end

  -- fire astronauts
  if boss.state == "astrofire" then
   if boss.cd <= 0 then
    local v = vector_to_player(boss)
    local angle_diff = boss.shots_fired / 2 + 0.25
    local dv = normalize(v.x + sin(angle_diff) * 0.75,
                         v.y + cos(angle_diff) * 0.75)
    add(boss.astros, {
     x = boss.x + 8,
     y = boss.y + 8,
     dx = dv.x * 0.5,
     dy = dv.y * 0.5,
     life = 90 + rnd(20),
     dmg = 3,
     seed = rnd(4),
     loops = false,
    })
    boss.cd = 80
    boss.shots_fired += 1
    if boss.shots_fired >= 4 then
     boss.state = "laser_position"
     boss.shots_fired = 0
     boss.cd = 0
    end
   end
  end

  if boss.state == "laser_position" then
   -- pick a random corner to go to
   boss.corner = get_random_corner()
   local v =
    normalize(boss.corner.x - boss.x, boss.corner.y - boss.y)
   boss.dx = v.x * 0.8
   boss.dy = v.y * 0.8
   boss.state = "laser_positioning"
  end

  if boss.state == "laser_positioning" then
   if abs(boss.x - boss.corner.x) <= 1 and
      abs(boss.y - boss.corner.y) <= 1 then
    -- pick a different corner to go to
    while true do
     local corner = get_random_corner()
     if abs(corner.x - boss.corner.x) <= 2 or
        abs(corner.y - boss.corner.y) <= 2 then
      boss.corner = corner
      break
     end
    end

    boss.state = "laser_charging"
    boss.cd = 30
    boss.dx = 0
    boss.dy = 0
   end
  end

  if boss.state == "laser_charging" and boss.cd <= 0 then
   boss.state = "laser_firing"
   local v =
    normalize(boss.corner.x - boss.x, boss.corner.y - boss.y)
   boss.dx = v.x * 0.8
   boss.dy = v.y * 0.8
  end

  if boss.state == "laser_firing" then
   if boss.cd <= 0 and
      abs(boss.x - boss.corner.x) >= 1 and
      boss.x + 6 <= x and x <= boss.x + 10 or
      abs(boss.y - boss.corner.y) >= 1 and
      boss.y + 6 <= y and y <= boss.y + 10 then
    damage_player(1)
    sfx(24)
    boss.cd = 3
   end

   -- restart once we get to the corner
   if abs(boss.x - boss.corner.x) <= 1 and
      abs(boss.y - boss.corner.y) <= 1 then
    boss.shots_fired += 1

    --if boss.shots_fired >= 4 then
    if boss.shots_fired >= 40 then
     boss.shots_fired = 0
     boss.state = "flamethrower_position"
    else
     boss.state = "laser_positioning"
     boss.dx = 0
     boss.dy = 0
    end
   end
  end

  if boss.state == "flamethrower_position" then
   local v =
    normalize((map_width / 2 - 12) - boss.x, (map_height / 2 - 12) - boss.y)
   boss.dx = v.x * 0.8
   boss.dy = v.y * 0.8
   boss.state = "flamethrower_positioning"
  end

  if boss.state == "flamethrower_positioning" and
     abs(boss.x - (map_width / 2 - 12)) <= 1 and
     abs(boss.y - (map_height / 2 - 12)) <= 1 then
   boss.dx = 0
   boss.dy = 0
   boss.state = "flamethrower"
   boss.loops = true
   boss.cd = 600
   --boss.cd = 100
   boss.speed = 0.05
  end

  if boss.state == "flamethrower" then
  -- collide the fire around the boss with the player
   if boss.x - 16 <= x and x <= boss.x + 32 and
      boss.y - 16 <= y and y <= boss.y + 32 then
    damage_player(1)
   end

   -- chase the player
   local v = vector_to_player(boss)
   if boss.cd <= 100 then
    boss.speed -= 0.02
   else
    boss.speed += 0.002
   end

   boss.speed = mid(0, boss.speed, 1.2)

   if boss.cd <= 0 then
    boss.state = "flamethrower_explosion"
    boss.loops = false
   else
    boss.dx = v.x * boss.speed
    boss.dy = v.y * boss.speed
   end
  end

  if boss.state == "flamethrower_explosion" and boss.cd <= 0 then
   boss.cd = 4
   boss.shots_fired += 1
   -- explode the flames
   local flame = {
    x = boss.x - 8 + rnd(24),
    y = boss.y - 8 + rnd(24),
    dx = rnd() - 0.5,
    dy = rnd() - 0.5,
    life = 500,
    dmg = 2,
    loops = false,
   }
   local r = rnd()
   if r < 0.25 then
    -- flames on top
    flame.y = boss.y - 8
   elseif r < 0.5 then
    -- flames on right
    flame.x = boss.x + 24
   elseif r < 0.75 then
    -- flames on bottom
    flame.y = boss.y + 24
   else
    -- flames on left
    flame.x = boss.x - 8
   end
   add(boss.flames, flame)
   boss.dx = 0
   boss.dy = 0

   if boss.shots_fired >= 100 then
    boss.shots_fired = 0
    boss.state = "astrofire"
   end
  end

  -- collide shots with the boss
  if boss.state != "dying" then
   for shot in all(shots) do
    if boss.x <= shot.x and shot.x <= boss.x + 24 and
       boss.y <= shot.y and shot.y <= boss.y + 24 then
     del(shots, shot)
     if not boss.invuln then
      boss.hp -= 1
      if boss.hp <= 0 then
       music(-1)
       boss.state = "dying"
       boss.dx *= 0.3
       boss.dy *= 0.3
       boss.cd = 120
      else
       boss.hit = true
      end
     end
    end
   end
  end
 end

 -- collide shots with enemies
 collide_enemies(octopi, true)
 collide_enemies(chompers, true)
 collide_enemies(eyes, true)
 collide_enemies(lookouts, true)
 collide_enemies(missiles, true)
 collide_enemies(healthpacks, true)
 collide_enemies(boss, true)

 local open_shells = {}
 for shell in all(shells) do
  if shell.state == "open" then
   add(open_shells, shell)
  end
 end
 collide_enemies(open_shells, true)

 -- collide shots with astronauts
 for shot in all(shots) do
  for astro in all(astros) do
  if colliding(astro, shot) and
     astro.state != "dead" then
   sfx(2)
   astro.state = "dead"
   astro.life = 54
   astro.dx = 0
   astro.dy = 0
   score -= 200
   del(shots, shot)
   current_message = astro_dead_messages[flr(rnd(#astro_dead_messages)) + 1]
   current_message_color = 8
   message_timer = 180
   end
  end
 end


 update(parts)
 update(shots)
 update(debris)
 update(octopi)
 update(bullets)
 update(chompers)
 update(astros)
 update(eyes)
 update(lookouts)
 update(missiles)
 update(shells)
 update(healthpacks)
 if boss then update({boss}) end
end

function print_with_color_delay(string, color, delay)
 local c
 if time() > delay then
  c = color
 else
  c = 7
 end
 print(string, 0, 27, c)
end

function print_menu(color)
 print(center("press 🅾️ to start"), 0, 37, color)
end

function radar_x(x)
 return x / (map_width / 112) + 9
end

function radar_y(y)
 return y / (map_height / 56) + 33
end

function clrspr(x, y)
 rectfill(x, y, x + 7, y + 7, 0)
end

function _draw()
 cls()

 if state == "menu" then
  print("         space  ", 0, 27, 8)
  print("                rescue", 0, 27, 12)
  print_menu(7)
  return
 end

 -- play the intro
 if state == "intro" then
  if #intro_messages <= 1 then
   print_with_color_delay("         s", 8, 20)
   print_with_color_delay("          p", 8, 20.1)
   print_with_color_delay("           a", 8, 20.2)
   print_with_color_delay("            c", 8, 20.3)
   print_with_color_delay("             e", 8, 20.4)
   print_with_color_delay("                r", 12, 20.5)
   print_with_color_delay("                 e", 12, 20.6)
   print_with_color_delay("                  s", 12, 20.7)
   print_with_color_delay("                   c", 12, 20.8)
   print_with_color_delay("                    u", 12, 20.9)
   print_with_color_delay("                     e", 12, 21)
   spr(1, (time() - 19.3) * 44, 37)

   if time() > 24 then
    state = "menu"
   elseif time() > 23.5 then
    print_menu(6)
   elseif time() > 23 then
    print_menu(5)
   end
  else
   for message in all(intro_messages) do
    local time_alive = (time() - message.delay) * 10
    local color = 7
    if time_alive > 120 then
     del(intro_messages, message)
     color = 0
    elseif time_alive > 110 then
     color = 5
    elseif time_alive > 100 then
     color = 6
    else
     color = 7
    end
    print(message.text, 0, 128 - time_alive, color)
   end
  end
  return
 end

 -- center the camera
 if state == "alive" then
  camera_dx = flr(mid(-60, dx * 70, 60))
  camera_dy = flr(mid(-60, dy * 70, 60))
 else
  camera_dx = 0
  camera_dy = 0
 end
 camera_x = (x - 56 + camera_dx) * 0.05
          + (camera_x * 0.95)
 camera_y = (y - 56 + camera_dy) * 0.05
          + (camera_y * 0.95)
 camera_x = flr(mid(0, camera_x, map_width - 128))
 -- allow the camera to go up 8 pixels to make room for the HUD.
 camera_y = flr(mid(-8, camera_y, map_height - 128))

 camera(camera_x, camera_y)

 -- draw the stars
 if state != "radar" then
  for star in all(stars) do
   pset(star.x, star.y, star.color)
  end

  -- draw the particles
  for part in all(parts) do
   pset(part.x, part.y, part.color)
  end

  -- draw the boss
  if boss then
   -- draw the launched flames
   for flame in all(boss.flames) do
    spr(23, flame.x, flame.y)
   end

   if boss.state == "flamethrower" or
      boss.state == "flamethrower_explosion" then
    -- draw the flames around the boss

    -- bottom
    spr(176, boss.x, boss.y + 24, 4, 1)

    -- top
    spr(176, boss.x - 8, boss.y - 8, 4, 1, true, true)

    -- left
    spr(131, boss.x - 8, boss.y, 1, 4, true, false)

    -- right
    spr(131, boss.x + 24, boss.y - 8, 1, 4, false, true)
   end

   if boss.hit then
    -- palette shift when hit
    pal({1,1,5,5,5,6,7,13,6,7,7,6,13,6,7}, 0)
   end

   if boss.state == "laser_charging" or
      boss.state == "laser_firing" then
    local maybe_animate = 0
    if boss.state == "laser_firing" and
       flr(time() * 8) % 2 == 0 then
     maybe_animate = 1
    end

    -- animate the laser cannons
    if abs(boss.x - boss.corner.x) >= 1 then
     -- boss is moving horizontally, fire below and above
     if boss.state == "laser_firing" then
      for i = 0, map_height, 8 do
       spr(166 + maybe_animate, boss.x + 8, i)
      end
     end
     spr(137 + maybe_animate * 16, boss.x + 8, boss.y - 8 + boss.cd / 10)
     spr(139 + maybe_animate * 16, boss.x + 8, boss.y + 24 - boss.cd / 10)
    end
    if abs(boss.y - boss.corner.y) >= 1 then
     if boss.state == "laser_firing" then
      for i = 0, map_width, 8 do
       spr(164 + maybe_animate, i, boss.y + 8)
      end
     end
     -- boss is moving vertically, fire sideways
     spr(136 + maybe_animate * 16, boss.x + 24 - boss.cd / 10, boss.y + 8)
     spr(138 + maybe_animate * 16, boss.x - 8 + boss.cd / 10, boss.y + 8)
    end
   end

   if boss.state != "dead" then
    spr(128, boss.x, boss.y, 3, 3)
   end

   if boss.state == "dying" or boss.state == "dead" then
    -- animate the explosions
    for explosion in all(boss.explosions) do
     spr(explosion_for(explosion.life), explosion.x, explosion.y)
    end
   else
    -- animate the engines
    if flr(time() * 10) % 2 == 0 then
     clrspr(boss.x, boss.y)
     spr(186, boss.x, boss.y)
     clrspr(boss.x, boss.y + 16)
     spr(185, boss.x, boss.y + 16)
     clrspr(boss.x + 16, boss.y)
     spr(183, boss.x + 16, boss.y)
     clrspr(boss.x + 16, boss.y + 16)
     spr(184, boss.x + 16, boss.y + 16)
    end
   end

   if boss.state == "astrofire" then
    -- animate the mouth opening for the astronauts
    if boss.cd < 60 then
      spr(180 + (60 - boss.cd) / 20, boss.x + 8, boss.y + 8)
    end
   end

   pal()

   -- draw the boss' launched astronauts
   for astro in all(boss.astros) do
    if astro.state == "dead" then
     sp = explosion_for(astro.life)
    else
     sp = 132 + (astro.seed + time() * 3) % 4
     if flr(time() * 4) % 2 == 0 then
      sp += 16
     end
    end
    spr(sp, astro.x, astro.y)
   end
  end

  -- draw the ship
  if state == "alive" or state == "next level" or state == "menu" then
   if hit then
    pal({[6] = 8, [8] = 2}, 0)
    hit = false
   end
   spr(a * 8 + 1, x, y)
   pal()
  elseif state == "dead" then
   spr(explosion_for(time_death), x, y)
  end

  -- draw the shots
  for shot in all(shots) do
   pset(shot.x, shot.y, 12)
  end

  -- draw the astronauts
  for astro in all(astros) do
   if astro.state == "dead" then
    sp = explosion_for(astro.life)
   else
    sp = 9
   end
   spr(sp, astro.x, astro.y)
  end

  -- draw the healthpacks
  for healthpack in all(healthpacks) do
   if healthpack.state == "dead" then
    sp = explosion_for(healthpack.life)
   else
    sp = 43
   end
   spr(sp, healthpack.x, healthpack.y)
  end

  -- draw the debris
  for debri in all(debris) do
   if debri.state == "dead" then
    sp = explosion_for(debri.life)
   else
    sp = debri.sp
   end
   spr(sp, debri.x, debri.y)
  end

  -- draw the octopi
  for octopus in all(octopi) do
   if octopus.state == "dead" then
    sp = explosion_for(octopus.life)
   elseif flr(time() * 5) % 2 == 0 then
    sp = 32
   else
    sp = 48
   end
   spr(sp, octopus.x, octopus.y)
  end

  -- draw the chompers
  for chomper in all(chompers) do
   if chomper.state == "dead" then
    sp = explosion_for(chomper.life)
   elseif flr(time() * 5) % 2 == 0 then
    sp = 33 + atan2(chomper.dx, -chomper.dy) * 8
   else
    sp = 49 + atan2(chomper.dx, -chomper.dy) * 8
   end
   spr(sp, chomper.x, chomper.y)
  end

  -- draw the eyes
  for eye in all(eyes) do
   if eye.state == "dead" then
    sp = explosion_for(eye.life)
   elseif eye.state == "charging" then
    sp = 57
   else
    sp = 41
   end
   spr(sp, eye.x, eye.y)
  end

  -- draw the lookouts
  for lookout in all(lookouts) do
   if lookout.state == "dead" then
    sp = explosion_for(lookout.life)
   elseif lookout.state == "charged" then
    sp = 71 + flr(time() * 3) % 2
   else
    sp = 73 + lookout.cd / 133
   end
   spr(sp, lookout.x, lookout.y)
   if lookout.state == "charged" then
    spr(80 + lookout.a * 8, lookout.x, lookout.y)
   end
  end

  -- draw the shells
  for shell in all(shells) do
   if shell.state == "dead" then
    sp = explosion_for(shell.life)
   elseif shell.state == "closed" then
    sp = 77
   else
    sp = 76
   end
   spr(sp, shell.x, shell.y)
  end

  -- draw the missiles
  for missile in all(missiles) do
   if missile.state == "dead" then
    sp = explosion_for(missile.life)
   else
    sp = 80 + atan2(missile.dx, -missile.dy) * 8
   end
   spr(sp, missile.x, missile.y)
  end

  -- draw the bullets
  for bullet in all(bullets) do
   pset(bullet.x + 4,
        bullet.y + 4, 8)
  end
 end -- state != "radar"

 camera()

 -- draw the radar
 if state == "radar" then
  spr(192, 0, 24, 16, 1)
  spr(224, 0, 88, 16, 2)
  rect(8, 32, 120, 88, 7)
  for astro in all(astros) do
   pset(radar_x(astro.x), radar_y(astro.y), 7)
  end
  for healthpack in all(healthpacks) do
   pset(radar_x(healthpack.x), radar_y(healthpack.y), 12)
  end
  if flr(time() * 3) % 2 == 0 then
   pset(radar_x(x), radar_y(y), 10)
  end
 end

 -- draw the hud
 if state == "game over" then
  print(center("game  over"), 0, 48, 8)
  print(center("score: "..pad(score, 5)), 0, 56, 11)
  print(center(game_over_message), 0, 64, 11)
  print(center("press 🅾️ to try again"), 0, 72, 7)
 elseif state == "next level" then
  print(center("level complete"), 0, 48, 8)
  print(center("score: "..pad(score, 5)), 0, 56, 11)
  print(center("press 🅾️ to continue"), 0, 72, 7)
 else
  rectfill(0, 0, 127, 8, 0)
  if current_message then
   print(current_message, 2, 2, current_message_color)
  else
   print("p1 "..pad(score, 5), 2, 2, 7)
   for i = 0, hp - 1 do
    rectfill(46 + i * 4, 1,
             48 + i * 4, 7,
             8 + i \ 2)
   end
   print("left: "..pad(#astros, 2), 95, 2, 7)
  end
  rect(0, 0, 127, 8)
 end
end
__gfx__
000000000800000000608800006006000088060000000080cc000000000cc000000000cc00677000000000000000000000000000000000000000000000000000
000000000880000000068800886666880088600000000880c6600000000660000000066c006f7000000680000000000000000000000000000000000000000000
00700700666800006066680008666680008666060000866606668888000660008888666008666000068666600000000000000000000000000000000000000000
000770000666666c066668000086680000866660c66666600066668800066000886666000666000006666f700000000000000000000000000000000000000000
000770000666666c886666000006600000666688c6666660008666600086680006666800086cc000666c67700000000000000000000000000000000000000000
00700700666800008888666000066000066688880000866600866606086666806066680006660000600c00000000000000000000000000000000000000000000
00000000088000000000066c00066000c66000000000088000886000886666880006880000666000c00000000000000000000000000000000000000000000000
0000000008000000000000cc000cc000cc000000000000800088060000600600006088000000c000000000000000000000000000000000000000000000000000
00000000000044000000646000000600440004464444000000000000000800000088880008800080000000000000000000000000000000000000000000000000
05555000000440000006464600455660000446504455500400088000008988000888998080aa9a88000090000a00000a00000000000000000000000000000000
04445550005440000004646404545566044655004556604008089800808999808899a8800a9aa998900009090000000000000000000000000000000000000000
044444450054400506064006454540064655004045600650008999800899a998899aa9899aaaaaaa0900a0a0a0000aa000000000000000000000000000000000
04440044045444500464640044545400550004654560066500899800089aa98099aaaa98a9aaaaa90a0aaa900000000000000000000000000000000000000000
004440000454400056464600064545400040655504566565000880008999998089aa99800aaaaa98900a00a90000000000000000000000000000000000000000
00044000440440005564600006645400046550040040066400800800088988000889988080aa9a08000000000a00000000000000000000000000000000000000
00000000400044006550000000044000445500400000554400000000800800808008808808800080090090000000a00000000000000000000000000000000000
b00b000b002bb3000002bb00003b3b00003b330003b3b30000a3b300033a0a30003b3a0000bbb300088008800000000000000000000000000000000000000000
00bb3b000bb2bb3303bb2b3003bbb3b00bbbbb303a3a3b30000a3bb003a000a30bb3a0000bb3bbb08880088800c66c0000000000000000000000000000000000
0b0333b0b3b3a3a33b3bb3b33b333bb23b3bb3b0a0a0a3b3a000a3b33b3a0a3b3b3a000ab3bbbb3b999999990c6886c000000000000000000000000000000000
000323003b3a0a0a3bbb3a33b3a0a32bb3a3bbb2000003bb3a003bbbbba000a3bbb300a39a2222abaaaaaaaa0688886000000000000000000000000000000000
00032300bb300000bbb300a33a000abb3a003b2ba0a0a3b333a3bbb3b23a0a3b3bbb3a333aa22aa3bbbbbbbb0688886000000000000000000000000000000000
003333303b3a0a0a3b3a000ab3a0a3b3a000a3bb3a3a3b3b3b3bb3b32bb333b33b3bb3b3b39aaab30cccccc00c6886c000000000000000000000000000000000
00b0b0b003b3a3a30bb3a0003a000a30000a3b3033bb2bb003b2bb300b3bbb3003bb2b3003b333300022220000c66c0000000000000000000000000000000000
03003003003b3b30003b3a0003a0a33000a33300003bb20000bb200000b3b3000002bb000033b300000220000000000000000000000000000000000000000000
0bb33bb0002bb0000002b000003b3b000003b330000bb20000a3b3000033aa30003b3a0003bbbb30000000000000000000000000000000000000000000000000
000333000b22b300032b2b0003bbb3b000bbbbb3003b22b00a0a3bb0003a00a30bb3a0a00b9aa9b0000000000000000000000000000000000000000000000000
00032300b3b2bb333b32bb303b333b2203b3bb3233bb2b3b33a0a3b303b3aa3b3b3a0a33baa22aab000000000000000000000000000000000000000000000000
000323003b33a3a33bbb33b0b3aa322b2b3a3b2b3a3a33b33b3a3bbbbbba00a3bbb3a3b39aa22a9b000000000000000000000000000000000000000000000000
00333330bb3a0a0abbb3a3b33a00abbbb3a0a3b2a0a0a3bb0b33bbb3b223aa3b3bbb33b03a922aa3000000000000000000000000000000000000000000000000
00b0b0b03b3a0a0a3b3a0a33b3aa3b300a0a33bba0a0a3b303bb23b322b333b33b32bb30b3aaaab3000000000000000000000000000000000000000000000000
0300303003b3a3a30bb3a0a03a00a30000a3bb303a3a3b3000b2b2300b3bbb30032b2b0003b33330000000000000000000000000000000000000000000000000
0b00bb00003b3b30003b3a0003aa33000003300003b3b300000b200000b3b3000002b0000033b300000000000000000000000000000000000000000000000000
003bb00000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000b00b000003a0000000000000000000
003ab000000320000000000000000a000003300000033000000330000003300000033000000330000003300000033000a0bbbb0a003a3a000000000000000000
0233300003233330a000bab00000aba000333300003ba300003ab300003333000033330000333300003ba300003ab3003a2bb2a303a3a3a00000000000000000
0333000003333ab00baba22a000aba0a03abaa3003baba3003b22a3003aaaa3003aaaa3003abaa3003baba3003b22a30a30bb03a0a3a3a300000000000000000
023aa000333a3bb00abab22b0baba000033ab33003abab3003a22b30032aa320023aa230033ab33003abab3003a22b300a33a3a003a3a3a00000000000000000
03330000300a0000a000aba0a22a000002233220022ab220022ba220032333200233323002233220022ab220022ba220303a3a0300333a000000000000000000
00333000a000000000000000b22b0000003333000033330000333300003333000033330000333300003333000033330030000003330000330000000000000000
0000a00000000000000000000ab00000000330000003300000033000000330000003300000033000000330000003300000000000000000000000000000000000
00000000000a000000a00a000000a000000000000ba00000000ab000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a00000000ba00000000a0000000000a22b000000b22a00000000000000000000000000000000000000000000000000000000000000000000000000
a000bab00aba0000000ab0000000aba00bab000ab22a000000a22b00000000000000000000000000000000000000000000000000000000000000000000000000
0baba22aa0aba000000ba000000aba0aa22abab00baba00000baba00000000000000000000000000000000000000000000000000000000000000000000000000
0abab22b000abab000baba000baba000b22baba0000aba0a000ba000000000000000000000000000000000000000000000000000000000000000000000000000
a000aba00000a22b00a22b00a22a00000aba000a0000aba0000ab000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000b22a00b22a00b22b00000000000000000a00000ba000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000ab0000ab0000ab00000000000000000a00000a00a00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001b11110000008800899988000806770080800800c0008800000000000000000000000000000000002a22a2000000000000000000000000000000000
8088800002232230000888000899880080086f708988880006608998776c006c2a00000000000000000000a20a2aa2a000000000000000000000000000000000
888998002222b2b200899880089880000889666089999808006699807f66c660a2a000000000000000000a2a00aaaa0000000000000000000000000000000000
089911003222b3220011998008998800089666c00896698000c66988666666002aa000000000000000000aa20000000000000000000000000000000000000000
08912b20bb22322b022219800899988088966c00006666660c666980089669802aa000000000000000000aa20000000000000000000000000000000000000000
008123b223b2bb3222bb18000898800008996600066c66f70666988080899998a2a0000000aaaa0000000a2a0000000000000000000000000000000000000000
0000223322bb3b2233b200000899880089980660c600c67707f68008008888982a0000000a2aa2a0000000a20000000000000000000000000000000000000000
0000022bb3b3bb3bb220000008999880088000c00000000007760800080080800000000002a22a20000000000000000000000000000000000000000000000000
0022b2223b33b3b3222b32000899988008806770800800800c000008000000000000000000000000000000000aaaaaa000000000000000000000000000000000
13b22323b38a8abb323b22210899880089986f7008898898066098807760c06ca2000000000000000000002a02a22a2000000000000000000000000000000000
12232b2b3b8a8a3bbbb2222b089880000899666008999998006699807f66c660aa20000000000000000002aa002aa20000000000000000000000000000000000
122b3b3bb88a8a833b2222310899880008966600099669800cc6699866666600a2a000000000000000000a2a0000000000000000000000000000000000000000
122322b338a8a88bb3b3bb210899988089966cc0006666660066698008966990a2a000000000000000000a2a0000000000000000000000000000000000000000
1bb22bbbbba8a833bbb232210898800008996600066c66f70666998089999980aa200000002aa200000002aa0000000000000000000000000000000000000000
1222bb23b3a8a8bb32322b310899880008890660c60c067707f6899889889880a200000002a22a200000002a0000000000000000000000000000000000000000
002bb2223bb3b3b3222b220008999880800000c0000000000776088008008008000000000aaaaaa0000000000000000000000000000000000000000000000000
0000022bb3bb3b32b32000000899988000000000000000000aa77aa00aa77aa00000000000000000000000000000000000000000000000000000000000000000
00002b3322b3bb2223230000089988002aaa2aa2a2aaa2a20aa772a00aa772a00000000000000000000000000000000000000000000000000000000000000000
0081bb2223b23b322bb2180008988000aa2aaaaaaaa2aa2a0a277aa002a77aa00000000000000000000000000000000000000000000000000000000000000000
08912220b222b2bb022219800899880077777777777777770aa77aa00aa77aa00000000000000000000000000000000000000000000000000000000000000000
08991100223bb2230011998008999880777777777777777702a77aa00a277aa00000000000000000000000000000000000000000000000000000000000000000
088998002b2b22220089988808988000a2aaaa2aa2aaaa2a0aa77a200aa77a200000000000000000000000000000000000000000000000000000000000000000
008880000322322000088808089988002aaa2aa2aaa2a2aa0aa772a00aa77aa00000000000000000000000000000000000000000000000000000000000000000
0880000001111b10000000000899988000000000000000000aa77a2002a77aa00000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000889999803bbb3bb33b3bb3b33b33b3b300000000b32000000000022b088000008899998000000000000000000000000000000000
88888888888888888888888889999880b3b3b3bbbbbb3bbbb38a8abb000880082323000000002b33008880008999988000000000000000000000000000000000
999999999999999999999999999988003b33b33b33b3b3bb388a8a8b008998882bb218000081bb22088998009999880000000000000000000000000000000000
99899899998998999989989999998000b88a8a83bb83b833b8888883001199800222198008912220089911009889980000000000000000000000000000000000
9889888998898889988988898899988038a8a88b3383b83b3888888b02221980001199800899110008912b208008998000000000000000000000000000000000
88088088880880888808808980899980b333bb33bbb3b3b3b8a8a88322bb18000089988088899800008123b28000888000000000000000000000000000000000
80080008800800088008000880088800bbb3b3bbbbbb3bbbb3a8a8bb33b200000008880080888000000022330008880000000000000000000000000000000000
000000000000000000000000000000003bbb3bb33b3bbbb33bb3b3b3b220000000000880000000000000022b0000000000000000000000000000000000000000
00000000000000000000000000000007770000000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000777070000000000770077700000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000700000777700007700000077000000770000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077777007700000000700007770000000077707000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007770007770000000000777770000000000000777000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000
00000000777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000
00000000777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000
00000000777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000
00000000777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000
00000000777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000
00000000777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000
00000000777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000077000000000007000000000770000000000000007000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000077000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000777700000000770000000000000070000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000700700000000700000000000000070000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007700000007000700000000700000000000000070000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000007000700000000770000000000000770000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000770000070000000770000000000000700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000070007700000070000000770000000000007700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000070077000000007000000777700000000777000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077770000000007700007700777700007700000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007700000000000770007000000777777000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000070077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000077070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00050000243302b340240300c6000f600154001a30000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c0000285601d530195301853028500285000050015050150501304017300153001730000000000000000000000000000000000000000001630000000000000000000000000000000000000000000000000000
000800001b3401d3302f6402c670266701f670266701f650266501c640146400f6300d63006620036200061000610066000360000600006000000000000000000000000000000000000000000000000000000000
0010000026550280502d0502b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000917309555052050060528055283542863516625286002870028600166000060500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500000
0010000015500155000020000000140001c7001f700140001400020500185000050000500150001600017000180001a0001b00012000130001500016000000000000000000000000000000000000000000000000
000800002115624753291002220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00000c0430000000000000001f6250000000000000000c043000000c043000001f6250000000000000000c0430000000000000001f6250000000000000000c043000000c043000001f625000000000000000
011002000e755007050e7550e70511765007050e7450e745107551376515745007051373510745157550070517745107051774500705157550070513755007051774517755007051175513745157550070500000
0110000010252152521025215252102520020211252172021f2520020218202152021f25200202182020020200202002020020200202002020020200202002020020200202002020020200202002020020200202
01120000002040020429554285542955428554295540050400504005042d5542b5542d5642b5542d5640050400504005042155424554215642455421564005040050400504265542355432564235543256400204
01120000290352d045290352d045290352d0452903528025290352d045290352d045290352d0452a0352b0452f0552b0452f0552b0452f0552b0452a03529045280552b045280552b045340352b0552804528045
011200002d555005053455532555345553255534555005052b55500505325552f555325552f555325550050535555005003555534555355553555535555005053755537555375550050535555345553255530555
011200002d555005053455532555345553255534555005052b55500505325552f555325552f55532555005053555500500355553455535555355553555500505375553555532555305552f5552d5552b55528555
011200001174216702117520c702117420c7021174212752137520c702137420c702137420c7021373214752157520c702157320c702157420c70215742167521776213702177420c70217752177521775200702
01120000187551870518745187551874518705187351d7451a7551c7051a7551a7451a755187051a7451a7551a7651c7051a7451a7551a765187051a745197551876518705187451875518755187451873518735
0112000015750157501575000700007000070000700007001f7501f7501f750007000070000700007000070015750157501575000700007000070000700007001f7501f7501f7500070000700007000070000700
011200000c053000030c0030a0030c053020030c003020030c053000030c003000000c0530c003010030c053000030c003000030c053000030c003010030c053000030c0030c0532b7540c0532b7542b75400000
011200000070400704007040070400704007040070429754007040070400704007040070400704007041c754007040070400704007040070400704007041e7540070400704007040070400704007040070424754
011200000c053000030c0030a0030c053020030c0031d7540c053000030c0030c053000000c053005041c7540c053000030c0030a0030c05300504005041e7540c053000030c0030c053000000c0530050423752
011200200c053000030c0030a0030c053020030c003020030c053000030c0030c053000000c0530c003010030c053000030c003000030c053000030c003010030c053000030c0030c053000000c0530c00303003
00100000116020f6021260206602106020f60211602086021060212602106020c602116021161213622116121161210622116121363213642106321165213632176521a642186521763217642186521a6621c672
001000201d6721c662186521764215632016020160201602016020160201602016020160200602006020060200602006020160201602026020260202602026020260203602036020360200000000000000000000
001000200060200202006020060201602026020260202602026020160201602016020160201602016020160201602006020060200602006020060201602016020260202602026020260202602036020360203602
010600001555318553095000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000000
__music__
00 0e0a1440
01 0b0f1444
00 0b140f40
00 0b110f51
00 0c101244
00 0d101347
00 0b140f51
00 0b0f1151
00 0a0e1454
02 0b0f1151
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 05424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 14424344
00 40424344

