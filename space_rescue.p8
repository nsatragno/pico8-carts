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

function vector_to_player(element)
 local bdx = x - element.x
 local bdy = y - element.y
 local l = sqrt(bdx * bdx + bdy * bdy)
 return { dx = bdx / l, dy = bdy / l }
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
  sfx(2, 1)
  enemy.life = 54
 else
  sfx(24, 1)
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
    sfx(2, 1)
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
   x = 0,
   y = 128,
   dx = 0,
   dy = -0.2,
   text = center("it is the year 21xx"),
   life = 800,
  },
  {
   x = 0,
   y = 148,
   dx = 0,
   dy = -0.2,
   text = center("humans are losing the war"),
   life = 800,
  },
  {
   x = 0,
   y = 168,
   dx = 0,
   dy = -0.2,
   text = center("pilots of the 2nd galactic squad"),
   life = 800,
  },
  {
   x = 0,
   y = 178,
   dx = 0,
   dy = -0.2,
   text = center("are stranded"),
   life = 800,
  },
  {
   x = 0,
   y = 198,
   dx = 0,
   dy = -0.2,
   text = center("your mission:"),
   life = 800,
  },
  {
   x = 0,
   y = 218,
   dx = 0,
   dy = -0.2,
   text = center("space  rescue"),
   life = 800,
  },
 }
end

function restart()
 stars = {}
 current_message = nil
 current_message_color = nil
 message_timer = 0
 for i = 1, rnd(700) + 300 do
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
 for i = 1, (level - 1) * 2 do
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
 for i = 1, (level - 2) * 3 do
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

 bullets = {}
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
   sfx(1, 2)
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
  update(intro_messages)
  if #intro_messages == 0 or btnp(🅾️) then
   state = "menu"
  end
 end

 -- actions when game is running

 -- control the player
 if state == "alive" then
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
   sfx(0, 1)
  elseif not btn(🅾️) then
   fire = false
  end
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
        { x = x, y = y}) and
      astro.state != "dead" then
    del(astros, astro)
    score += 100
    sfx(3, 2)
    current_message = messages[flr(rnd(#messages)) + 1]
    current_message_color = 12
    message_timer = 180
    if #astros <= 0 then
     state = "next level"
     return
    end
   end
  end

  -- have some octopi fire
  for octopus in all(octopi) do
   if abs(octopus.x - x) <= 40 and
      abs(octopus.y - y) <= 40 and
      octopus.state != "dead" and
      octopus.cd <= 0 then
    local v = vector_to_player(octopus)
    add(bullets, {
     x = octopus.x,
     y = octopus.y,
     dx = v.dx,
     dy = v.dy,
     life = 100,
     dmg = 2
    })
    octopus.cd = rnd(100) + 60
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
    local a = clamp(atan2(v.dx, -v.dy))
    chomper.dx = sin(a) * chomper.speed
    chomper.dy = cos(a) * chomper.speed
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
       life = 100
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


  -- collide with enemies
  update_kill(debris, true)
  update_kill(octopi, true)
  update_kill(bullets, false)
  update_kill(chompers, true)
  update_kill(eyes, true)

  -- maybe create a new particle
  if flr((time() * 1000) % 2) == 0 then
   add(parts, {
    x = x - dx + 4,
    y = y - dy + 4,
    dx = -dx + rnd(.6) - .3,
    dy = -dy + rnd(.6) - .3,
    life = flr(rnd(10) + 10)
   })
  end
 end  -- end if state == "alive"

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

 -- collide shots with astronauts
 for shot in all(shots) do
  for astro in all(astros) do
  if colliding(astro, shot) and
     astro.state != "dead" then
   sfx(2, 1)
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
end

function _draw()
 cls()

 -- play the intro
 if state == "intro" then
  for message in all(intro_messages) do
   print(message.text, message.x, message.y, 7)
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
  pset(part.x, part.y, 9)
 end

 -- draw the ship
 if state == "alive" or state == "menu" or state == "next level" then
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

 -- draw the bullets
 for bullet in all(bullets) do
  pset(bullet.x + 4,
       bullet.y + 4, 8)
 end

 -- draw the hud
 camera()
 if state == "menu" then
  print(center("space  rescue"), 0, 44, 7)
  print(center("press 🅾️ to start"), 0, 76, 7)
 elseif state == "game over" then
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
000000000880000000068800886666880088600000000880c6600000000660000000066c006f7000000000000000000000000000000000000000000000000000
00700700666800006066680008666680008666060000866606668888000660008888666008666000000000000000000000000000000000000000000000000000
000770000666666c066668000086680000866660c666666000666688000660008866660006660000000000000000000000000000000000000000000000000000
000770000666666c886666000006600000666688c6666660008666600086680006666800086cc000000000000000000000000000000000000000000000000000
00700700666800008888666000066000066688880000866600866606086666806066680006660000000000000000000000000000000000000000000000000000
00000000088000000000066c00066000c66000000000088000886000886666880006880000666000000000000000000000000000000000000000000000000000
0000000008000000000000cc000cc000cc000000000000800088060000600600006088000000c000000000000000000000000000000000000000000000000000
00000000000044000000646000000600440004464444000000000000000800000088880008800080000000000000000000000000000000000000000000000000
05555000000440000006464600455660000446504455500400088000008988000888998080aa9a88000090000a00000a00000000000000000000000000000000
04445550005440000004646404545566044655004556604008089800808999808899a8800a9aa998900009090000000000000000000000000000000000000000
044444450054400506064006454540064655004045600650008999800899a998899aa9899aaaaaaa0900a0a0a0000aa000000000000000000000000000000000
04440044045444500464640044545400550004654560066500899800089aa98099aaaa98a9aaaaa90a0aaa900000000000000000000000000000000000000000
004440000454400056464600064545400040655504566565000880008999998089aa99800aaaaa98900a00a90000000000000000000000000000000000000000
00044000440440005564600006645400046550040040066400800800088988000889988080aa9a08000000000a00000000000000000000000000000000000000
00000000400044006550000000044000445500400000554400000000800800808008808808800080090090000000a00000000000000000000000000000000000
b00b000b002bb3000002bb00003b3b00003b330003b3b30000a3b300033a0a30003b3a0000bbb300000000000000000000000000000000000000000000000000
00bb3b000bb2bb3303bb2b3003bbb3b00bbbbb303a3a3b30000a3bb003a000a30bb3a0000bb3bbb0000000000000000000000000000000000000000000000000
0b0333b0b3b3a3a33b3bb3b33b333bb23b3bb3b0a0a0a3b3a000a3b33b3a0a3b3b3a000ab3bbbb3b000000000000000000000000000000000000000000000000
000323003b3a0a0a3bbb3a33b3a0a32bb3a3bbb2000003bb3a003bbbbba000a3bbb300a39a2222ab000000000000000000000000000000000000000000000000
00032300bb300000bbb300a33a000abb3a003b2ba0a0a3b333a3bbb3b23a0a3b3bbb3a333aa22aa3000000000000000000000000000000000000000000000000
003333303b3a0a0a3b3a000ab3a0a3b3a000a3bb3a3a3b3b3b3bb3b32bb333b33b3bb3b3b39aaab3000000000000000000000000000000000000000000000000
00b0b0b003b3a3a30bb3a0003a000a30000a3b3033bb2bb003b2bb300b3bbb3003bb2b3003b33330000000000000000000000000000000000000000000000000
03003003003b3b30003b3a0003a0a33000a33300003bb20000bb200000b3b3000002bb000033b300000000000000000000000000000000000000000000000000
0bb33bb0002bb0000002b000003b3b000003b330000bb20000a3b3000033aa30003b3a0003bbbb30000000000000000000000000000000000000000000000000
000333000b22b300032b2b0003bbb3b000bbbbb3003b22b00a0a3bb0003a00a30bb3a0a00b9aa9b0000000000000000000000000000000000000000000000000
00032300b3b2bb333b32bb303b333b2203b3bb3233bb2b3b33a0a3b303b3aa3b3b3a0a33baa22aab000000000000000000000000000000000000000000000000
000323003b33a3a33bbb33b0b3aa322b2b3a3b2b3a3a33b33b3a3bbbbbba00a3bbb3a3b39aa22a9b000000000000000000000000000000000000000000000000
00333330bb3a0a0abbb3a3b33a00abbbb3a0a3b2a0a0a3bb0b33bbb3b223aa3b3bbb33b03a922aa3000000000000000000000000000000000000000000000000
00b0b0b03b3a0a0a3b3a0a33b3aa3b300a0a33bba0a0a3b303bb23b322b333b33b32bb30b3aaaab3000000000000000000000000000000000000000000000000
0300303003b3a3a30bb3a0a03a00a30000a3bb303a3a3b3000b2b2300b3bbb30032b2b0003b33330000000000000000000000000000000000000000000000000
0b00bb00003b3b30003b3a0003aa33000003300003b3b300000b200000b3b3000002b0000033b300000000000000000000000000000000000000000000000000
00000000000000000000000000000000003b3a0000000000003b3a00000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000200060200602006020060201602026020260202602026020160201602016020160201602016020160201602006020060200602006020060201602016020260202602026020260202602036020360203602
001000000060200602006020060201602026020260202602026020160201602016020160201602016020160201602006020060200602006020060201602016020260202602026020260202602036020360203602
001000200060200602006020060201602026020260202602026020160201602016020160201602016020160201602006020060200602006020060201602016020260202602026020260202602036020360203602
001000200060200202006020060201602026020260202602026020160201602016020160201602016020160201602006020060200602006020060201602016020260202602026020260202602036020360203602
010600001555318553095000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000000
__music__
00 08424340
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

