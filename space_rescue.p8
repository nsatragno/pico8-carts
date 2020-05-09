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

function normalize(x, y)
 local l = sqrt(x * x + y * y)
 return { x = x / l, y = y / l }
end

function vector_to_player(element)
 return normalize(x - element.x, y - element.y)
end

function update(elements)
 for element in all(elements) do
  element.x += element.dx
  element.y += element.dy
  if element.x >= 1023 then
   element.x = 0
  elseif element.x < 0 then
   element.x = 1023
  end
  if element.y >= 511 then
   element.y = 0
  elseif element.x < 0 then
   element.y = 511
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

function update_kill(enemies, explodes)
 for enemy in all(enemies) do
  if colliding(
       enemy,
       { x = x, y = y}) and enemy.state != "dead" then
   hp -= enemy.dmg
   kill_enemy(enemy, explodes)
   if hp <= 0 then
    state = "dead"
    sfx(2)
    time_death = 54
   end
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
function colliding(e1, e2)
 return abs(e1.x - e2.x) <= 4
    and abs(e1.y - e2.y) <= 4
end

-- returns the explosion sprite for |life|
function explosion_for(life)
 return 22 + 6 - life \ 9
end

function spawn_coordinates(list)
 local loops = 0
 while true do
  local nx = rnd(900) + 50
  local ny = rnd(400) + 50

  if abs(nx - x) >= 64 and
     abs(ny - y) >= 64 then
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
 hp = 8
 x = 500
 dx = 0
 y = 250
 dy = 0
 a = 0
 s = 0
 camera_x = x - 56 + dx * 30
 camera_y = y - 56 + dy * 30
 fire = false
 parts = {}
 shots = {}

 stars = {}
 for i = 1, 300 do
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
  stars[i] = { x = rnd(1024),
               y = rnd(512),
               color = color }
 end

 astros = {}
 for i = 1, 2 + level * 3 do
  local c = spawn_coordinates(astros)
  astros[i] = { x = c.x,
                y = c.y,
                dx = 0,
                dy = 0 }
 end

 debris = {}
 for i = 1, 6 + level * 3 do
  local c = spawn_coordinates(debris)
  debris[i] = { x = c.x,
                y = c.y,
                dx = rnd(1) - 0.5,
                dy = rnd(1) - 0.5,
                sp = flr(rnd(6)) + 16,
                dmg = 3 }
 end

 octopi = {}
 --for i = 1, 10 + level * 2 do
 for i = 1, 10 + level * 2 do
  local c = spawn_coordinates(octopi)
  octopi[i] = { x = c.x,
                y = c.y,
                dx = rnd(0.3) - 0.15,
                dy = rnd(0.3) - 0.15,
                cd = 0,
                dmg = 2 }
 end

 chompers = {}
 for i = 1, 10 do
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
                  dmg = 3 }
 end

 eyes = {}
 for i = 1, 10 do
 --for i = 1, (level - 2) * 3 do
  local c = spawn_coordinates(eyes)
  local a = clamp(rnd(1))
  eyes[i] = { x = c.x,
              y = c.y,
              dx = sin(a) * 0.1,
              dy = cos(a) * 0.1,
              cd = 0,
              state = "idle",
              dmg = 4 }
 end

 lookouts = {}
 missiles = {}
 for i = 1, 10 do
 --for i = 1, (level - 2) * 2 do
  local c = spawn_coordinates(lookouts)
  lookouts[i] = { x = c.x,
                  y = c.y,
                  dx = rnd(0.3) - 0.15,
                  dy = rnd(0.3) - 0.15,
                  cd = 0,
                  dmg = 2,
                  state = "charged",
                  a = 0 }
 end

 healthpacks = {}
 for i = 1, rnd(3) + 1 do
  local c = spawn_coordinates(lookouts)
  healthpacks[i] = { x = c.x,
                     y = c.y,
                     dx = 0,
                     dy = 0 }
 end


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
  })
 end
end

function _update60()
 -- global actions

 -- play / stop playing the engine sfx
 if state == "alive" then
  sfx(flr(20 + (s - 0.3) * 3), 0)
 else
  sfx(-1, 0)
 end

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
  end
  return
 end

 if state == "next level" then
  if btnp(🅾️) then
   level += 1
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
    x = x,
    y = y,
    dx = dx / l * 3,
    dy = dy / l * 3,
    life = 64
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
  if x >= 1084 then
   x = -60
  elseif x < -60 then
   x = 1084
  end
  if y >= 572 then
   y = -60
  elseif y < -60 then
   y = 572
  end

  -- rescue astronauts
  for astro in all(astros) do
   if colliding(
        astro,
        { x = x, y = y }) and
      astro.state != "dead" then
    del(astros, astro)
    score += 100
    sfx(3)
    current_message = messages[flr(rnd(#messages)) + 1]
    current_message_color = 12
    message_timer = 180
    if #astros <= 0 then
     state = "next level"
     return
    end
   end
  end

  -- get healthpacks
  for healthpack in all(healthpacks) do
   if colliding(
        healthpack,
        { x = x, y = y }) and
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
     dmg = 2
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
    chomper.dy = sin(a) * 0.25
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
       dmg = 2
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

  -- collide with enemies
  update_kill(debris, true)
  update_kill(octopi, true)
  update_kill(bullets, false)
  update_kill(chompers, true)
  update_kill(eyes, true)
  update_kill(lookouts, true)
  update_kill(missiles, true)

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

 -- collide shots with enemies
 collide_enemies(octopi, true)
 collide_enemies(chompers, true)
 collide_enemies(eyes, true)
 collide_enemies(lookouts, true)
 collide_enemies(missiles, true)
 collide_enemies(healthpacks, true)

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
 return x / 9.6 + 9
end

function radar_y(y)
 return y / 9.6 + 38
end

function _draw()
 cls()

 if state == "menu" then
  print("         space  ", 0, 27, 8)
  print("                rescue", 0, 27, 12)
  print_menu(7)
  return
 end

 -- draw the radar
 if state == "radar" then
  rect(8, 37, 117, 90, 7)
  for astro in all(astros) do
   pset(radar_x(astro.x), radar_y(astro.y), 7)
  end
  for healthpack in all(healthpacks) do
   pset(radar_x(healthpack.x), radar_y(healthpack.y), 12)
  end
  if flr(time() * 3) % 2 == 0 then
   pset(radar_x(x), radar_y(y), 10)
  end
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
 camera_x = flr(mid(0, camera_x, 1024 - 128))
 -- allow the camera to go up 8 pixels to make room for the HUD.
 camera_y = flr(mid(-8, camera_y, 512 - 128))

 camera(camera_x, camera_y)

 -- draw the stars
 for star in all(stars) do
  pset(star.x, star.y, star.color)
 end

 -- draw the particles
 for part in all(parts) do
  pset(part.x, part.y, part.color)
 end

 -- draw the ship
 if state == "alive" or state == "next level" or state == "menu" then
  spr(a * 8 + 1, x, y)
 elseif state == "dead" then
  spr(explosion_for(time_death), x, y)
 end

 -- draw the shots
 for shot in all(shots) do
  pset(shot.x + 4, shot.y + 4, 12)
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

 -- draw the hud
 camera()
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
0000000001b11110000008800000000000806770080800800c0008800000000000000000000000000000000002a22a2000000000000000000000000000000000
8088800002232230000888000000000080086f708988880006608998776c006c2a00000000000000000000a20a2aa2a000000000000000000000000000000000
888998002222b2b200899880000000000889666089999808006699807f66c660a2a000000000000000000a2a00aaaa0000000000000000000000000000000000
089911003222b3220011998000000000089666c00896698000c66988666666002aa000000000000000000aa20000000000000000000000000000000000000000
08912b20bb22322b022219800000000088966c00006666660c666980089669802aa000000000000000000aa20000000000000000000000000000000000000000
008123b223b2bb3222bb18000000000008996600066c66f70666988080899998a2a0000000aaaa0000000a2a0000000000000000000000000000000000000000
0000223322bb3b2233b200000000000089980660c600c67707f68008008888982a0000000a2aa2a0000000a20000000000000000000000000000000000000000
0000022bb3b3bb3bb220000000000000088000c00000000007760800080080800000000002a22a20000000000000000000000000000000000000000000000000
0022b2223b33b3b3222b32000899988008806770800800800c000008000000000000000000000000000000000aaaaaa000000000000000000000000000000000
13b22323b38a8abb323b22210899880089986f7008898898066098807760c06ca2000000000000000000002a02a22a2000000000000000000000000000000000
12232b2b3b8a8a3bbbb2222b089880000899666008999998006699807f66c660aa20000000000000000002aa002aa20000000000000000000000000000000000
122b3b3bb88a8a833b2222310899880008966600099669800cc6699866666600a2a000000000000000000a2a0000000000000000000000000000000000000000
122322b338a8a88bb3b3bb210899988089966cc0006666660066698008966990a2a000000000000000000a2a0000000000000000000000000000000000000000
1bb22bbbbba8a833bbb232210898800008996600066c66f70666998089999980aa200000002aa200000002aa0000000000000000000000000000000000000000
1222bb23b3a8a8bb32322b310899880008890660c60c067707f6899889889880a200000002a22a200000002a0000000000000000000000000000000000000000
002bb2223bb3b3b3222b220008999880800000c0000000000776088008008008000000000aaaaaa0000000000000000000000000000000000000000000000000
0000022bb3bb3b32b320000008999880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002b3322b3bb2223230000089988002aaa2aa2a2aaa2a200000000000000000000000000000000000000000000000000000000000000000000000000000000
0081bb2223b23b322bb2180008988000aa2aaaaaaaa2aa2a00000000000000000000000000000000000000000000000000000000000000000000000000000000
08912220b222b2bb0222198008998800777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
08991100223bb2230011998008999880777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
088998002b2b22220089988808988000a2aaaa2aa2aaaa2a00000000000000000000000000000000000000000000000000000000000000000000000000000000
008880000322322000088808089988002aaa2aa2aaa2a2aa00000000000000000000000000000000000000000000000000000000000000000000000000000000
0880000001111b100000000008999880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000889999803bbb3bb33b3bb3b33b33b3b300000000b32000000000022b088000008899998000000000000000000000000000000000
88888888888888888888888889999880b3b3b3bbbbbb3bbbb38a8abb000880082323000000002b33008880008999988000000000000000000000000000000000
999999999999999999999999999988003b33b33b33b3b3bb388a8a8b008998882bb218000081bb22088998009999880000000000000000000000000000000000
99899899998998999989989999998000b88a8a83bb83b833b8888883001199800222198008912220089911009889980000000000000000000000000000000000
9889888998898889988988898899988038a8a88b3383b83b3888888b02221980001199800899110008912b208008998000000000000000000000000000000000
88088088880880888808808980899980b333bb33bbb3b3b3b8a8a88322bb18000089988088899800008123b28000888000000000000000000000000000000000
80080008800800088008000880088800bbb3b3bbbbbb3bbbb3a8a8bb33b200000008880080888000000022330008880000000000000000000000000000000000
000000000000000000000000000000003bbb3bb33b3bbbb33bb3b3b3b220000000000880000000000000022b0000000000000000000000000000000000000000
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
01100000000050000535055340553505534055350550000500005000052d0552b0552d0552b0552d0550000500005000052d055300552d055300552d055000050000500005320552f055320552f0553205500005
01100000290552d055290552d055290552d0552905528055290552d055290552d055290552d0552a0552b0552f0552b0552f0552b0552f0552b0552a05529055280552b055280552b055340552b0552805528055
011000002d555005053455532555345553255534555005052b55500505325552f555325552f555325550050535555005003555534555355553555535555005053755537555375550050535555345553255530555
001000002d555005053455532555345553255534555005052b55500505325552f555325552f55532555005053555500500355553455535555355553555500505375553555532555305552f5552d5552b55528555
011000001d352163021d352003021d352003021d3521e3521f352003021f352003021f352003021f352203522135200302213520030221352003022135222352233521f302233520030223352233522335200302
010d0000183551830518355183551835518305183551d3551a3551c3051a3551a3551a355183051a3551a3551a3551c3051a3551a3551a355183051a355193551835518305183551835518352183521835200000
010f000015350153501535000000000000000000000000001f3521f3521f352000000000000000000000000015350153501535000000000000000000000000001f3521f3521f3520000000000000000000000000
01100000000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000022b052000002b0522b052
011000000050400504005040050400504005040050429554005040050400504005040050400504005041c554005040050400504005040050400504005041e5540050400504005040050400504005040050424554
001000000050400504005040050400504005040050429554005040050400504005040050400504005041c554005040050400504005040050400504005041e5540050400504005040050400504005040050423554
011000200c754007020c754007020c7540270202702027020c7540070200702007020c754017020c754017020c754007020c754007020c7540070201702017020c7540070200702007020c754037020c75403702
001000000060200602006020060201602026020260202602026020160201602016020160201602016020160201602006020060200602006020060201602016020260202602026020260202602036020360203602
001000200060200602006020060201602026020260202602026020160201602016020160201602016020160201602006020060200602006020060201602016020260202602026020260202602036020360203602
001000200060200202006020060201602026020260202602026020160201602016020160201602016020160201602006020060200602006020060201602016020260202602026020260202602036020360203602
010600001555318553095000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000000
__music__
00 0a424340
00 41424344
00 41424344
00 41424344
00 04424344
00 04050607
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

