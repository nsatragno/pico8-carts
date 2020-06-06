pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- space rescue
-- by kat and nina
-- centers a string by adding padding to it
function center(string)
 for i = 1, (31 - #string) / 2 do
  string = " "..string
 end
 return string
end

-- pads a number to the right so it takes |length| spaces
function pad(num, length)
 local string = tostr(abs(num))
 for i = #string, length - 1 do
  if i == length - 1 and num < 0 then
   string = "-"..string
  else
   string = "0"..string
  end
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
  add_explosion(enemy.x, enemy.y)
 end
 enemy.life = 0
end

function damage_player(dmg)
 hit = 18
 if dmg > 1 and difficulty == 0 then
  dmg /= 2
 elseif difficulty == 2 then
  dmg *= 2
 end
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
  if not enemy_nearby and
     abs(enemy.x - x + 4) <= 40 and
     abs(enemy.y - y + 4) <= 40 then
   enemy_nearby = true
  end
  if colliding(
       { x = enemy.x, y = enemy.y },
       { x = x + 4, y = y + 4}) and enemy.state != "dead" then
   damage_player(enemy.dmg)
   kill_enemy(enemy, explodes)
  end
 end
end

function collide_enemies(enemies, explodes)
  for enemy in all(enemies) do
   -- shots are always close to the player ship, only check for collisions
   -- around it to save processing time
   if abs(enemy.x - x) <= 128 and abs(enemy.y - y) <= 128 then
    for shot in all(shots) do
     if colliding(enemy, shot) and
        enemy.state != "dead" then
      if not enemy.invuln then
       kill_enemy(enemy, explodes)
       score += 10
      end
      enemy.dx += shot.dx * 0.05
      enemy.dy += shot.dy * 0.05
      del(shots, shot)
     end
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
 return 22 + (54 - life) \ 9
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
 if music_on then music(-1, 0, 14) end
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
 has_triple_shot = true
 state = "intro"

 intro_messages = {
  {
   text = center("a human federation base, for"),
   delay = 0,
  },
  {
   text = center("outreach and extraction,"),
   delay = 1,
  },
  {
   text = center("was just destr0yed by denuvos."),
   delay = 2,
  },
  {
   text = center("while the loss of property"),
   delay = 4,
  },
  {
   text = center("is tragic, we are obliged to"),
   delay = 5,
  },
  {
   text = center("outsource a space rescue"),
   delay = 6,
  },
  {
   text = center("seeking temp to extract workers"),
   delay = 8,
  },
  {
   text = center("no prior heroism required"),
   delay = 9,
  },
  {
   text = center("federation not responsible for"),
   delay = 10,
  },
  {
   text = center("denuvo presence or hostility"),
   delay = 11,
  },
  {
   text = center("best of luck with your"),
   delay = 14,
  },
  {
   text = center("space  rescue"),
   delay = 16,
  },
 }
end

function restart()
 -- difficulty goes 0, 1, 2
 difficulty = 1
 music_on = true
 screen_shake_on = true
 current_message = nil
 current_message_color = nil
 message_timer = 0
 score = 0
 level = 1
 state = "menu"
 max_hp = 8
 start()
 toggle_music(true)
end

function start()
 if level == 1 then
  map_width = 500
  map_height = 250
 elseif level == 2 or level == 3 then
  map_width = 1000
  map_height = 500
 elseif level == 4 then
  map_width = 256
  map_height = 128
 end

 hp = max_hp
 x = map_width / 2
 dx = 0
 y = map_height / 2
 dy = 0
 a = 0
 s = 0
 hit = 0
 camera_x = x - 56 + dx * 30
 camera_y = y - 56 + dy * 30
 fire = false
 fire_charge = 0

 parts = {}
 shots = {}

 stars = {}
 local palette
 if level == 1 then
  palette = {5, 6, 7, 13}
 elseif level == 2 then
  palette = {4, 10, 9, 15}
 else
  palette = {2, 9, 14}
 end
 for i = 1, map_height / 100 * map_width / 10 do
  local r = flr(rnd(4))
  stars[i] = { x = rnd(map_width),
               y = rnd(map_height),
               color = palette[r] }
 end

 astros = {}
 local astro_num = 0
 if level != 4 then
  astro_num = min(20, 10 + (level - 1) * 5)
 end

 for i = 1, astro_num do
  local c = spawn_coordinates(astros)
  astros[i] = { x = c.x,
                y = c.y,
                dx = 0,
                dy = 0,
                loops = true,
                form = flr(rnd(4)) }
 end

 debris = {}
 local debris_num = 0
 if level != 4 then
  debris_num = 10 * level
 end
 for i = 1, debris_num do
  local c = spawn_coordinates(debris)
  debris[i] = { x = c.x,
                y = c.y,
                dx = rnd(1) - 0.5,
                dy = rnd(1) - 0.5,
                sp = flr(rnd(6)) + 16,
                dmg = 3,
                loops = true,
                invuln = true }
 end

 octopi = {}
 if level != 4 then
  for i = 1, 12 do
   local c = spawn_coordinates(octopi)
   octopi[i] = { x = c.x,
                 y = c.y,
                 dx = rnd(0.3) - 0.15,
                 dy = rnd(0.3) - 0.15,
                 cd = 0,
                 dmg = 2,
                 loops = true }
  end
 end

 chompers = {}
 local chompers_num = 0
 if level >= 2 and level != 4 then
  chompers_num = 12
 end
 for i = 1, chompers_num do
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
 local eyes_num = 0
 if level >= 2 and level != 4 then
  eyes_num = level * 5
 end
 for i = 1, eyes_num do
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
 local lookouts_num = 0
 if level == 3 then
  lookouts_num = 12
 end
 for i = 1, lookouts_num do
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
 local shells_num = 0
 if level == 3 then
  shells_num = 12
 end
 for i = 1, shells_num do
  local c = spawn_coordinates(shells)
  shells[i] = { x = c.x,
                y = c.y,
                dx = rnd(0.06) - 0.03,
                dy = rnd(0.06) - 0.03,
                cd = 10,
                dmg = 3,
                bullets_fired = 0,
                state = "closed",
                invuln = true,
                loops = true }
 end

 healthpacks = {}
 if level != 4 then
  for i = 1, flr(rnd(3)) + 1 do
   local c = spawn_coordinates(lookouts)
   healthpacks[i] = { x = c.x,
                      y = c.y,
                      dx = 0,
                      dy = 0,
                      loops = true }
  end
 end

 if level != 4 and max_hp < 16 then
  local c = spawn_coordinates({})
  hp_booster = { x = c.x,
                 y = c.y,
                 dx = 0,
                 dy = 0,
                 loops = true }
 end

 if level == 2 or level == 3 and not has_triple_shot then
  local c = spawn_coordinates({})
  triple_shot = { x = c.x,
                  y = c.y,
                  dx = 0,
                  dy = 0,
                  loops = true }
 end

 boss_max_hp = 30
 if level == 4 then
  boss = {
   x = map_width / 2,
   y = -24,
   dx = 0,
   dy = 0.1,
   state = "intro",
   dmg = 99,
   hp = boss_max_hp,
   hit = false,
   invuln = true,
   cd = 0,
   shots_fired = 0,
   explosions = {},
   astros = {},
   flames = {},
   loops = false,
  }
 else
  boss = nil
 end

 bullets = {}
 explosions = {}
end

function add_explosion(x, y)
 sfx(2)
 add(explosions, {
  x = x,
  y = y,
  dx = 0,
  dy = 0,
  life = 54,
 })
end

function get_boss_phase()
 local r = flr(rnd(3))
 if r == 0 then
  return "astrofire_position"
 elseif r == 1 then
  return "laser_position"
 else
  return "flamethrower_position"
 end
end

function particle_for(x, y, dx, dy, color, life)
 if not life then life = flr(rnd(10) + 10) end
 if flr((time() * 1000) % 2) == 0 then
  add(parts, {
   x = flr(x) - dx + 4,
   y = flr(y) - dy + 4,
   dx = -dx + rnd(.6) - .3,
   dy = -dy + rnd(.6) - .3,
   life = life,
   color = color,
   loops = false,
  })
 end
end

function toggle_music(is_menu)
 music(-1)
 if not music_on then return end

 if is_menu then
  music(10, 200)
 elseif level == 4 then
  music(16, 2000)
 else
  music(0, 2000)
 end
end

function maybe_next_level()
 if #astros <= 0 then
  music(-1)
  if level >= 4 then
   start()
   state = "win"
  else
   state = "next level"
   message_timer = 0
   current_message = nil
  end
  return
 end
end

function shoot(directions)
 for i in all(directions) do
  add(shots, {
   x = x + 4,
   y = y + 4,
   dx = sin(clamp(a) + i * 0.02 - .25) * 3,
   dy = cos(clamp(a) + i * 0.02 - .25) * 3,
   life = 35,
   loops = false,
  })
 end
 sfx(0)
end

function _update60()
 -- global actions
 -- i'm sorry for having to do this, i'll use oop next time
 enemy_nearby = false
 healthpack_nearby = false
 if hit > 0 then
  hit -= 1
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
   current_message = nil
   current_message_color = nil
   sfx(1)
   game_over_message = game_over_messages[flr(rnd(#game_over_messages)) + 1]
  end
  return
 end

 if state == "menu" then
  if btnp(🅾️) then
   -- XXX don't fire when starting the game
   fire = true
   state = "alive"
   toggle_music(false)
  end
  if btnp(❎) then
   sfx(0)
   state = "options"
   selected_option = 1
  end
  return
 end

 if state == "options" then
  if btnp(🅾️) or btnp(➡️) or btnp(⬅️) then
   sfx(0)
   if selected_option == 1 then
    -- difficulty
    if btnp(⬅️) then
     difficulty -= 1
    else
     difficulty += 1
    end
    difficulty %= 3
   end
   if selected_option == 2 then
    -- music
    music_on = not music_on
    toggle_music(true)
   end
   if selected_option == 3 then
    -- screen shake
    screen_shake_on = not screen_shake_on
   end
   if selected_option == 4 then
    -- level select
    if btnp(⬅️) then
     level -= 1
    else
     level += 1
    end
    level = mid(1, level, 4)
    start()
   end
   if selected_option == 5 then
    -- help
    state = "help"
   end
   if selected_option == 6 then
    -- help
    state = "menu"
   end
  elseif btnp(❎) then
   sfx(24)
   state = "menu"
  elseif btnp(⬇️) then
   sfx(24)
   selected_option += 1
  elseif btnp(⬆️) then
   sfx(24)
   selected_option -= 1
  end
  selected_option = mid(1, selected_option, 6)
  return
 end

 if state == "help" then
  if btnp(❎) then
   sfx(24)
   state = "options"
  end
  return
 end

 if state == "next level" then
  if btnp(🅾️) then
   level += 1
   toggle_music(false)
   start()
   -- XXX don't fire when starting the game
   fire = true
   state = "alive"
  end
  return
 end

 if state == "game over" then
  if btnp(🅾️) then
   start()
   toggle_music(false)
   score = 0
   -- XXX don't fire when starting the game
   fire = true
   state = "alive"
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

 if state == "win" then
  if not win_started then
   x = -20
   y = 0
   a = 0
   dx = 1
   dy = 0
   stars = {}
   parts = {}
   astros = {
    {
     x = 40,
     y = 100,
     dx = 0.2,
     dy = 0.2,
     loops = true,
     form = 1,
    },
    {
     x = 60,
     y = 100,
     dx = 0.2,
     dy = -0.2,
     loops = true,
     form = 1,
    },
    {
     x = 80,
     y = 100,
     dx = 0.2,
     dy = 0.2,
     loops = true,
     form = 1,
    },
   }
   win_started = true
  end
  if flr((time() * 2000) % 2) == 0 then
   add(parts, {
    x = x - dx + 4,
    y = y - dy + 4,
    dx = -dx + rnd(.6) - .3,
    dy = -dy + rnd(.6) - .3,
    life = flr(rnd(20) + 20),
    color = flr(rnd(16)),
    loops = false,
   })
  end
  update(parts)
  update(astros)

  for astro in all(astros) do
   if astro.y > 103 then
     astro.dy = -0.2
   elseif astro.y < 97 then
     astro.dy = 0.2
   end
   add(parts, {
    x = astro.x - astro.dx + 4,
    y = astro.y - astro.dy + 5,
    dx = -astro.dx + rnd(.3) - .15,
    dy = -astro.dy + rnd(.3) - .15,
    life = flr(rnd(5) + 10),
    color = flr(rnd(16)),
    loops = false,
   })
  end
  if astros[3].x > 100 then
   for astro in all(astros) do
    astro.dx = -0.2
    astro.form = 0
   end
  elseif astros[1].x < 20 then
   for astro in all(astros) do
    astro.dx = 0.2
    astro.form = 1
   end
  end
  x += dx
  y += dy
  if x > 130 then
   a = 0.5
   dx = -0.7
   y = rnd(20)
  elseif x < -30 then
   a = 0
   dx = 0.7
   y = rnd(20)
  end
  if btnp(🅾️) and btnp(❎) then
   restart()
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
  local steering = 0.018 * (1.7 - s)
  if btnp(❎) then
   state = "radar"
  end
  if btn(⬅️) then
   if did_tap_left then
    a -= steering
   else
    a = clamp(a)
    a -= 0.001
   end
   did_tap_right = false
   did_tap_left = true
  elseif btn(➡️) then
   if did_tap_right then
    a += steering
   else
    a += 0.125
   end
   did_tap_right = true
   did_tap_left = false
  else
   did_tap_right = false
   did_tap_left = false
   a = clamp(a)
  end
  if btn(⬆️) then
   s += .03
  end
  if btn(⬇️) then
   s -= .03
  end
  did_fire = false
  if btn(🅾️) then
   if fire then
    -- player is holding fire
    fire_charge += 1

    if fire_charge == 30 then
     sfx(5)
    end
    if fire_charge >= 30 then
     if fire_charge < 120 or fire_charge % 4 == 0 then
      particle_for(x, y, -(sin(clamp(a) - .25) + dx), -(cos(clamp(a) - .25) + dy), 12, 12)
     end
    end
   else
    did_fire = true
    -- player pushed fire for the first time
    fire = true
    if has_triple_shot then
     shoot({-1, 0, 1})
    else
     shoot({0})
    end
   end
  elseif not btn(🅾️) then
   if fire_charge > 120 then
    -- super shot
    local directions = {}
    local multiplier
    if has_triple_shot then
     multiplier = 2
    else
     multiplier = 1
    end
    for i = -2 * multiplier, 2 * multiplier, 0.25 do
     add(directions, i)
    end
    shoot(directions)
   end
   fire = false
   fire_charge = 0
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
  if x >= map_width + 10 then
   x = -20
  elseif x < -20 then
   x = map_width + 10
  end
  if y >= map_height + 10 then
   y = -20
  elseif y < -20 then
   y = map_height + 10
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
    maybe_next_level()
   end
  end

  -- get healthpacks
  for healthpack in all(healthpacks) do
   if not healthpack_nearby and
    abs(healthpack.x - x + 4) <= 40 and
    abs(healthpack.y - y + 4) <= 40 then
    healthpack_nearby = true
   end
   if colliding(
        healthpack,
        { x = x + 4, y = y + 4 }) and
      healthpack.state != "dead" then
    del(healthpacks, healthpack)
    current_message = "shield energy refilled"
    current_message_color = 12
    message_timer = 180
    hp = max_hp
    sfx(3)
   end
  end

  -- get hp booster
  if hp_booster and colliding(
       hp_booster,
       { x = x + 4, y = y + 4 }) and
     hp_booster.state != "dead" then
   hp_booster = nil
   current_message = "shields upgraded"
   current_message_color = 12
   message_timer = 180
   max_hp += 4
   hp = max_hp
   sfx(3)
  end

  -- get triple shot
  if triple_shot and colliding(
       triple_shot,
       { x = x + 4, y = y + 4 }) and
     triple_shot.state != "dead" then
   triple_shot = nil
   current_message = "acquired triple shot"
   current_message_color = 12
   message_timer = 180
   has_triple_shot = true
   sfx(3)
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
     add_explosion(missile.x, missile.y)
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
     shell.invuln = false
     shell.cd = min(shell.cd, 20)
    elseif abs(shell.x - x) >= 50 and
           abs(shell.y - y) >= 50 and
           shell.state == "open" then
     shell.state = "closed"
     shell.invuln = true
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
     shell.invuln = true
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

 -- update the boss
 if boss then
  -- update all the boss' elements
  update(boss.explosions)
  update_kill(boss.astros, true)
  collide_enemies(boss.astros, true)
  update(boss.astros)
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
    add_explosion(boss.x + rnd(16), boss.y + rnd(16))
   else
    boss.state = "dead"
    score += 10000
    for i = 1, 10 do
     add(astros, {
      x = boss.x + 8,
      y = boss.y + 8,
      dx = rnd() * 2 - 1,
      dy = rnd() * 2 - 1,
      loops = true,
      form = flr(rnd(2)),
     })
    end
   end
  end

  -- drift the astronauts
  if boss.state == "dead" then
   for astro in all(astros) do
    astro.dx *= 0.98
    astro.dy *= 0.98
   end
  end

  if boss.cd > 0 then boss.cd -= 1 end
  if boss.hit then boss.hit = false end

  -- bring the boss into the screen
  if boss.state == "intro" then
   if boss.y >= map_height / 4 then
    boss.state = get_boss_phase()
    boss.dx = 0
    boss.dy = 0
    boss.shots_fired = 0
    boss.invuln = false
    boss.loops = true
   end
  end

  -- position to fire astronauts
  if boss.state == "astrofire_position" then
   -- pick a random point near the middle
   boss.corner = {
    x = (map_width / 2 - 12) + rnd(30) - 15,
    y = (map_height / 2 - 12) + rnd(30) - 15,
   }
   local v =
    normalize(boss.corner.x - boss.x, boss.corner.y - boss.y)
   boss.dx = v.x * 0.5
   boss.dy = v.y * 0.5
   boss.state = "astrofire_positioning"
  end

  if boss.state == "astrofire_positioning" and
     abs(boss.x - boss.corner.x) <= 1 and
     abs(boss.y - boss.corner.y) <= 1 then
   boss.dx = 0
   boss.dy = 0
   boss.state = "astrofire"
   boss.cd = 80
  end

  -- fire astronauts
  if boss.state == "astrofire" then
   if boss.cd <= 0 then
    local v = vector_to_player(boss)
    local angle_diff = boss.shots_fired / 2 + 0.25
    local dv = normalize(v.x + sin(angle_diff) * 0.75,
                         v.y + cos(angle_diff) * 0.75)
    if rnd() < 0.02 * (max_hp - hp) then
     add(healthpacks, {
      x = boss.x + 8,
      y = boss.y + 8,
      dx = dv.x * 0.5,
      dy = dv.y * 0.5,
      life = 400,
      loops = true,
     })
    else
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
    end
    boss.cd = 80
    boss.shots_fired += 1
    if boss.shots_fired >= 4 then
     boss.state = get_boss_phase()
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
   boss.dx = v.x * 0.5
   boss.dy = v.y * 0.5
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
   if boss.cd <= 0 then
    if abs(boss.x - boss.corner.x) >= 1 and
      boss.x + 6 <= x and x <= boss.x + 10 or
      abs(boss.y - boss.corner.y) >= 1 and
      boss.y + 6 <= y and y <= boss.y + 10 then
    damage_player(2)
    sfx(24)
    boss.cd = 30
    end
   end

   -- restart once we get to the corner
   if abs(boss.x - boss.corner.x) <= 1 and
      abs(boss.y - boss.corner.y) <= 1 then
    boss.shots_fired += 1

    if boss.shots_fired >= 4 then
     boss.shots_fired = 0
     boss.state = get_boss_phase()
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
   boss.dx = v.x * 0.5
   boss.dy = v.y * 0.5
   boss.state = "flamethrower_positioning"
  end

  if boss.state == "flamethrower_positioning" and
     abs(boss.x - (map_width / 2 - 12)) <= 1 and
     abs(boss.y - (map_height / 2 - 12)) <= 1 then
   boss.dx = 0
   boss.dy = 0
   boss.state = "flamethrower"
   boss.cd = 600
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
    boss.state = get_boss_phase()
   end
  end

  -- collide shots with the boss
  if boss.state != "dying" and boss.state != "dead" then
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
 collide_enemies(shells, true)
 collide_enemies(debris, false)

 -- collide shots with astronauts
 for shot in all(shots) do
  for astro in all(astros) do
  if colliding(astro, shot) and
     astro.state != "dead" then
   add_explosion(astro.x, astro.y)
   score -= 200
   del(shots, shot)
   del(astros, astro)
   current_message = astro_dead_messages[flr(rnd(#astro_dead_messages)) + 1]
   current_message_color = 8
   message_timer = 180
   maybe_next_level()
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
 update(explosions)
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
 print(center("start           🅾️ / z"), 0, 50, color)
 print(center("options / help  ❎ / x"), 0, 60, color)
end

function radar_x(x)
 if x < 0 or x > map_width then return -99 end
 return x / (map_width / 109) + 9
end

function radar_y(y)
 if y < 0 or y > map_height then return -99 end
 return y / (map_height / 53) + 33
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

 -- options menu
 if state == "options" then
  print(center("options"), 0, 30, 7)
  local options = { "   difficulty",
                    "        music",
                    "      shaking",
                    "        level",
                    "         help",
                    "         back" }
  if difficulty == 0 then
   options[1] = options[1].." < zapp   (easy) >"
  elseif difficulty == 1 then
   options[1] = options[1].." < kirk (normal) >"
  elseif difficulty == 2 then
   options[1] = options[1].." < joker  (hard) >"
  end

  if music_on then
   options[2] = options[2].." < blast my ears >"
  else
   options[2] = options[2].." <      off      >"
  end

  if screen_shake_on then
   options[3] = options[3].." < shake it baby >"
  else
   options[3] = options[3].." <      off      >"
  end

  options[4] = options[4].." <       "..level.."       >"

  for i = 1, #options do
   local c = 6
   if i == selected_option then
    c = 7
    spr(1, 0, 28 + i * 10)
   end
   print(options[i], 0, 30 + i * 10, c)
  end

  print(center("back ❎ / x"), 0, 30 + (#options + 2) * 10, 7)
  return
 end

 -- help menu
 if state == "help" then
  print("mission: rescue all astronauts", 8)
  print("controls:", 12)
  print(" ⬆️ ⬇️  thrusters", 7)
  print(" ⬅️ ➡️  maneuver", 7)
  print(" 🅾️ / z fire", 7)
  print(" ❎ / x radar\n", 7)
  print("radar:", 10)
  pset(3, 50, 10)
  print("  your ship", 7)
  pset(3, 56, 7)
  print("  astronaut", 7)
  pset(3, 62, 12)
  print("  shield energy recharge", 7)
  pset(3, 68, 14)
  print("  power-up\n", 7)
  print("made with \135 by:", 8)
  print(" art & music: kat at", 7)
  print(" programming: nina", 7)
  print("     testing: moon retri toby\n              sandrul puga nani\n", 7)

  print(center("back ❎ / x", 7))
  return
 end

 -- play the intro
 if state == "intro" then
  if #intro_messages <= 1 then
   print_with_color_delay("         s", 8, 27)
   print_with_color_delay("          p", 8, 27.1)
   print_with_color_delay("           a", 8, 27.2)
   print_with_color_delay("            c", 8, 27.3)
   print_with_color_delay("             e", 8, 27.4)
   print_with_color_delay("                r", 12, 27.5)
   print_with_color_delay("                 e", 12, 27.6)
   print_with_color_delay("                  s", 12, 27.7)
   print_with_color_delay("                   c", 12, 27.8)
   print_with_color_delay("                    u", 12, 27.9)
   print_with_color_delay("                     e", 12, 28)
   spr(1, (time() - 26.3) * 44, 37)

   if time() > 31 then
    state = "menu"
    print_menu(7)
   elseif time() > 30.5 then
    print_menu(6)
   elseif time() > 30 then
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
 camera_x = flr(mid(-4, camera_x, map_width - 124))
 if state == "win" then
  camera_x = 0
  camera_y = 0
 end
 -- allow the camera to go up 8 pixels to make room for the HUD.
 camera_y = flr(mid(-12, camera_y, map_height - 124))

 -- shake the camera
 if screen_shake_on then
  if hit > 0 then
   local choice = flr(hp % 4)
   if choice == 0 then
    camera_x += 3 - (hit % 6)
   elseif choice == 1 then
    camera_x -= 3 - (hit % 6)
   elseif choice == 3 then
    camera_y += 3 - (hit % 6)
   else
    camera_y -= 3 - (hit % 6)
   end
  elseif state == "alive" and s > 1.2 and flr(time() * 20) % 4 == 0 then
   camera_x += rnd(2) - 1
   camera_y += rnd(2) - 1
  elseif state == "alive" and did_fire then
   camera_x += -shots[#shots].dx * 0.5
   camera_y += -shots[#shots].dy * 0.5
  end
 end

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

   if boss.state != "dying" and boss.state != "dead" then
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
    sp = 132 + (astro.seed + time() * 3) % 4
    if flr(time() * 4) % 2 == 0 then
     sp += 16
    end
    spr(sp, astro.x, astro.y)
   end
  end

  -- draw the ship
  if state == "alive" or state == "next level" or state == "menu" or
     state == "win" then
   if hit > 0 and hit % 2 == 0 then
    pal({[6] = 8, [8] = 2}, 0)
   end
   if fire_charge > 120 then
    pal({[6] = 12}, 0)
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
   local flip
   if astro.form % 2 == 0 then
    flip = true
   end
   spr(9 + astro.form \ 2, astro.x, astro.y, 1, 1, flip, false)
  end

  -- draw the healthpacks
  for healthpack in all(healthpacks) do
   spr(43, healthpack.x, healthpack.y)
  end

  -- draw the hp boosters
  if hp_booster then
   -- rotate colors 8 through 13
   local shift = flr(time() * 10) % 5
   local colors = {}
   for i = 8, 13 do
    if i + shift >= 13 then
     colors[21 - i] = (i + shift) % 13 + 8
    else
     colors[21 - i] = i + shift
    end
   end
   pal(colors)
   spr(42, hp_booster.x, hp_booster.y)
   pal()
  end

  -- draw the triple shot
  if triple_shot then
   spr(44 + flr(time() * 4) % 4, triple_shot.x, triple_shot.y)
  end

  -- draw the debris
  for debri in all(debris) do
   spr(debri.sp, debri.x, debri.y)
  end

  -- draw the octopi
  for octopus in all(octopi) do
   if flr(time() * 5) % 2 == 0 then
    sp = 32
   else
    sp = 48
   end
   spr(sp, octopus.x, octopus.y)
  end

  -- draw the chompers
  for chomper in all(chompers) do
   if flr(time() * 5) % 2 == 0 then
    sp = 33 + atan2(chomper.dx, -chomper.dy) * 8
   else
    sp = 49 + atan2(chomper.dx, -chomper.dy) * 8
   end
   spr(sp, chomper.x, chomper.y)
  end

  -- draw the eyes
  for eye in all(eyes) do
   if eye.state == "charging" then
    sp = 57
   else
    sp = 41
   end
   spr(sp, eye.x, eye.y)
  end

  -- draw the lookouts
  for lookout in all(lookouts) do
   if lookout.state == "charged" then
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
   if shell.state == "closed" then
    sp = 77
   else
    sp = 76
   end
   spr(sp, shell.x, shell.y)
  end

  -- draw the missiles
  for missile in all(missiles) do
   spr(80 + atan2(missile.dx, -missile.dy) * 8, missile.x, missile.y)
  end

  -- draw the bullets
  for bullet in all(bullets) do
   pset(bullet.x + 4,
        bullet.y + 4, 8)
  end

  -- draw the explosions
  for explosion in all(explosions) do
   spr(explosion_for(explosion.life), explosion.x, explosion.y)
  end
 end -- state != "radar"

 camera()

 -- draw the radar
 if state == "radar" then
  spr(192, 0, 24)
  for i = 1, 14 do
    spr(193, 8 * i, 24)
  end
  spr(192, 120, 24, 1, 1, true, false)

  spr(192, 0, 88, 1, 1, false, true)
  for i = 1, 14 do
    spr(193, 8 * i, 88, 1, 1, false, true)
  end
  spr(192, 120, 88, 1, 1, true, true)

  for i = 1, 7 do
    spr(208, 0, 24 + 8 * i, 1, 1, false, false)
    spr(208, 120, 24 + 8 * i, 1, 1, true, false)
  end

  spr(240, 0, 96, 16, 1)

  if enemy_nearby and flr(time() * 10) % 2 == 0 then
   spr(235, 88, 96, 2, 1)
  end
  if healthpack_nearby and flr(time() * 10) % 2 == 0 then
   spr(234, 80, 96)
  elseif not healthpack_nearby and #healthpacks > 0 then
   spr(234, 80, 96)
  end

  if has_triple_shot then
   spr(233, 72, 96)
  end

  for astro in all(astros) do
   pset(radar_x(astro.x), radar_y(astro.y), 7)
  end
  for healthpack in all(healthpacks) do
   pset(radar_x(healthpack.x), radar_y(healthpack.y), 12)
  end
  if boss and boss.state != "dead" then
   pset(radar_x(boss.x), radar_y(boss.y), 8)
  end
  if hp_booster and hp_booster.state != "dead" then
   pset(radar_x(hp_booster.x), radar_y(hp_booster.y), 14)
  end
  if triple_shot and triple_shot.state != "dead" then
   pset(radar_x(triple_shot.x), radar_y(triple_shot.y), 14)
  end
  if flr(time() * 3) % 2 == 0 then
   pset(radar_x(x), radar_y(y), 10)
  end
 end

 -- draw the hud
 if state == "game over" then
  rectfill(10, 44, 110, 80, 0)
  print(center("game  over"), 0, 48, 8)
  print(center("score: "..pad(score, 5)), 0, 56, 11)
  print(center(game_over_message), 0, 64, 11)
  print(center("press 🅾️ / z to restart level"), 0, 72, 7)
 elseif state == "next level" then
  rectfill(10, 44, 110, 80, 0)
  print(center("level complete"), 0, 48, 8)
  print(center("score: "..pad(score, 5)), 0, 56, 11)
  print(center("press 🅾️ / z to continue"), 0, 72, 7)
 elseif state == "win" then
  print(center("you rescued all the pilots"), 0, 48, 8)
  print(center("humanity can fight again"), 0, 56, 12)
  print(center("thanks to you"), 0, 64, 12)
  print(center("final score: "..pad(score, 5)), 0, 72, 7)
  print(center("🅾️ / z + ❎ / x restart"), 0, 120, 7)
 else
  rectfill(0, 0, 127, 8, 0)
  if boss then
   if boss.state == "intro" then
    print(center("warning"), 0, 100, 8)
    print(center("existential threat detected"), 0, 110, 8)
    print(center("no refuge"), 0, 120, 8)
   else
    -- draw the boss hp bar
    if boss.hp > 0 then
     print("denuvo", 0, 120, 8)
     rectfill(0, 126, (boss.hp * 127 / boss_max_hp), 126, 8)
    end
   end
  end
  if current_message then
   rectfill(0, 121, 127, 127, 0)
   print(current_message, 2, 122, current_message_color)
  end
  print("p1 "..pad(score, 5), 2, 2, 7)
  -- draw the HP bar
  local hp_width = 32
  local bar_width = (hp_width - max_hp - 2) \ max_hp
  for i = 0, hp - 1 do
   rectfill(46 + i * (bar_width + 2), 1,
            46 + i * (bar_width + 2) + bar_width, 7,
            8 + i \ (max_hp \ 4))
  end
  print("left: "..pad(#astros, 2), 95, 2, 7)
  rect(0, 0, 127, 8)
 end
end
__gfx__
000000000800000000608800006006000088060000000080cc000000000cc000000000cc0067700000000000000000007755555666666655cccccccccccccccc
000000000880000000068800886666880088600000000880c6600000000660000000066c006f7000000680000000000055777766666666655766666c5766666c
0070070066680000606668000866668000866606000086660666888800066000888866600866600006866660000000007777776cccccddd5566f66cc566f66cc
000770000666666c066668000086680000866660c66666600066668800066000886666000666000006666f7000000000777222cccccccddd5fff4fcc5fff4fcc
000770000666666c886666000006600000666688c6666660008666600086680006666800086cc000666c6770000000007a222cccccccccdd5ff44fcc5ff44fcc
00700700666800008888666000066000066688880000866600866606086666806066680006660000600c000000000000aa222224444444445f999ffc55999ffc
00000000088000000000066c00066000c66000000000088000886000886666880006880000666000c000000000000000aa22222444f44444559ff9f5559449f5
0000000008000000000000cc000cc000cc000000000000800088060000600600006088000000c0000000000000000000aaa222fffff4ff445669996656699966
000000000000440000006460000006004400044644440000000000000008000000888800088000800000000000000000aaa222ffff44fff422222affff44fff4
05555000000440000006464600455660000446504455500400088000008988000888998080aa9a88000090000a00000a2aaa22fffffffff4222222fffffffff4
04445550005440000004646404545566044655004556604008089800808999808899a8800a9aa998900009090000000022aa222ffffffff4222222afff555ff4
044444450054400506064006454540064655004045600650008999800899a998899aa9899aaaaaaa0900a0a0a0000aa0222aa222ffffff44222222aaffffff44
04440044045444500464640044545400550004654560066500899800089aa98099aaaa98a9aaaaa90a0aaa90000000002222aa28ffff4888222222a8ffff4888
004440000454400056464600064545400040655504566565000880008999998089aa99800aaaaa98900a00a90000000022222aa88844888822222aa888448888
00044000440440005564600006645400046550040040066400800800088988000889988080aa9a08000000000a00000022222666688886662222266668888666
00000000400044006550000000044000445500400000554400000000800800808008808808800080090090000000a00022226666668866662222666666886666
b00b000b002bb3000002bb00003b3b00003b330003b3b30000a3b300033a0a30003b3a0000bbb3000880088000000000066886600668866006688660066cc660
00bb3b000bb2bb3303bb2b3003bbb3b00bbbbb303a3a3b30000a3bb003a000a30bb3a0000bb3bbb08880088800c66c0066688666666886666668866666688666
0b0333b0b3b3a3a33b3bb3b33b333bb23b3bb3b0a0a0a3b3a000a3b33b3a0a3b3b3a000ab3bbbb3b999999990c6886c08668866886688668866cc668c668866c
000323003b3a0a0a3bbb3a33b3a0a32bb3a3bbb2000003bb3a003bbbbba000a3bbb300a39a2222abaaaaaaaa068888608668866886688668c668866c86688668
00032300bb300000bbb300a33a000abb3a003b2ba0a0a3b333a3bbb3b23a0a3b3bbb3a333aa22aa3bbbbbbbb0688886068688686686cc6866868868668688686
003333303b3a0a0a3b3a000ab3a0a3b3a000a3bb3a3a3b3b3b3bb3b32bb333b33b3bb3b3b39aaab30cccccc00c6886c0686886866c6886c66868868668688686
00b0b0b003b3a3a30bb3a0003a000a30000a3b3033bb2bb003b2bb300b3bbb3003bb2b3003b3333000dddd0000c66c0066888866668888666688886666888866
03003003003b3b30003b3a0003a0a33000a33300003bb20000bb200000b3b3000002bb000033b300000dd00000000000066cc660066886600668866006688660
0bb33bb0002bb0000002b000003b3b000003b330000bb20000a3b3000033aa30003b3a0003bbbb30000000000000000000000000000000000000000000000000
000333000b22b300032b2b0003bbb3b000bbbbb3003b22b00a0a3bb0003a00a30bb3a0a00b9aa9b000000000066cc66000000000000000000000000000000000
00032300b3b2bb333b32bb303b333b2203b3bb3233bb2b3b33a0a3b303b3aa3b3b3a0a33baa22aab0000000066c66c6600000000000000000000000000000000
000323003b33a3a33bbb33b0b3aa322b2b3a3b2b3a3a33b33b3a3bbbbbba00a3bbb3a3b39aa22a9b000000006c6886c600000000000000000000000000000000
00333330bb3a0a0abbb3a3b33a00abbbb3a0a3b2a0a0a3bb0b33bbb3b223aa3b3bbb33b03a922aa3000000006c6886c600000000000000000000000000000000
00b0b0b03b3a0a0a3b3a0a33b3aa3b300a0a33bba0a0a3b303bb23b322b333b33b32bb30b3aaaab30000000066c66c6600000000000000000000000000000000
0300303003b3a3a30bb3a0a03a00a30000a3bb303a3a3b3000b2b2300b3bbb30032b2b0003b3333000000000066cc66000000000000000000000000000000000
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
99999aaaaaaaaaaa0000000000000000770000000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000
999aa555555555550000000000000000070000000000770077700000000000000000000000000000000000000000000000000000000000000000000000000000
99aa5444444444440000000000000000007700000077000000770000000000000000000000000000000000000000000000000000000000000000000000000000
9aa54999999999990000000000000000000700007770000000077707000000000000000000000000000000000000000000000000000000000000000000000000
9a549aaaaaaaaaaa0000000000000000000777770000000000000777000000000000000000000000000000000000000000000000000000000000000000000000
a549aa55555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9549a559999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9549a59aaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9549a59a777777777777777777777777777777777777777777777777777777777777777700000000000000000000000000000000665666567777777700000000
9549a59a777777777777777777777777777777777777777777777777777777777777777700000000000000000000000000000000665666567777777700000000
9549a59a777777777777777777777777777777777777777777777777777777777777777700000000000000000000000000000000665666567777777700000000
9549a59a777777777777777777777777777777777777777777777777777777777777777700000000000000000000000000000000665666567777777700000000
9549a59a777777777777777777777777777777777777777777777777777777777777777700000000000000000000000000000000665666567777777700000000
9549a59a777777777777777777777777777777777777777777777777777777777777777700000000000000000000000000000000665666567777777700000000
9549a59a777777777777777777777777777777777777777777777777777777777777777700000000000000000000000000000000665666567777777700000000
9549a59a777777777777777777777777777777777777777777777777777777777777777766666666666666666666666666666666665666567777777700000000
00000000000000000000000000000000000000000000000000000000000000000000000066666666666666666666666666666666000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000056666866666cc6666aaaaaaaaaaaaaa6000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000006566686666c66c666a999999999999a6000000000000000000000000
000000000000000000000000000050000000000000000000000000000000000000000000566868686c6886c6a92282288228229a000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000656868686c6886c69822822882272289000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000005668888866c66c669882882882887889000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000065668886666cc6669888888888888889000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000066666866666666666999999999999996000000000000000000000000
99999999999999996655658888886666666666666666666666666666666666666666666666666666666666666666666666666666666655569999999999999999
999999999999996655666599999986666555556666666666666666666666666aa666666556666566666556666aaaaaaaaaaaaaa6676666656699999999999999
9999999999996665666665aaaaa99666566566556666666aa6611766661116aa9a66665665666566665665666a999999999999a6777686c65666999999999999
999999999966655666666533333aa66565555566666666a9aa111176617717779a7666655665656565655656a92252255225229a777666666556669999999999
9999999966655c66c6c665cccc33366556656655666667a9977118866cc117779a776656656565656565565695225225522722595756c686c665566699999999
999999666556666666666522dcccc666655555666666777977718116aa1c11a99977666556655555665665669552552552557559545666666666655666999999
99996655566cc6cc6cc665666dddd6655665665566667777776666aaaaa6677779777656656655566665566695555555555555595456886cc688666555669999
99665566666666666666656666666666666666666667777777766aaaaaa667777777766666666566666666666999999999999996666666666666666666556699
__label__
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
70000000000000000000000000000000000000000000008880888099909990aaa0aaa0bbb0bbb000000000000000000000000000000000000000000000000007
70777077000000777077707770777077700000000000008880888099909990aaa0aaa0bbb0bbb000000000000000000700077707770777000000000770077707
70707007000000707070707070707070700000000000008880888099909990aaa0aaa0bbb0bbb000000000000000000700070007000070007000000070070007
70777007000000707070707070707070700000000000008880888099909990aaa0aaa0bbb0bbb000000000000000000700077007700070000000000070077707
70700007000000707070707070707070700000000000008880888099909990aaa0aaa0bbb0bbb000000000000000000700070007000070007000000070000707
70700077700000777077707770777077700000000000008880888099909990aaa0aaa0bbb0bbb000000000000000000777077707000070000000000777077707
70000000000000000000000000000000000000000000008880888099909990aaa0aaa0bbb0bbb000000000000000000000000000000000000000000000000007
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa00aa000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaa00aaa00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999999900000000
00000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008888888800000000
0000455660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc00000000
00045455660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbb000000000
004545400600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa0000000000
0044545400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa00000000000
00064545400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
666860000000000000000000000000000000000000000000bb33bb00000000000000000000000000000000000000000000000000000000000000000000000000
f6666000000000000000000000000000000000000000000000333000000000000000000000000000000000000000000000000000000000000000000000000000
76c66600000000000000000000000000000000000000000000323000000000000000000000000000000000000000000000000000000000000000000000000000
00c00600000000000000000000000000000000000000000000323000000000000000000000000000000000000000000000000000000000000000000000000000
00000c00000000000000000000000000000000000000000003333300000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000b0b0b00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000030030300000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000b00bb000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000860000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000066668600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000007f666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000776c6660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000c0060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000008800900000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000086660000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000c66666600000080000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000c66666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000086660009000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000008800000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000
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
00000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000680000
00000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068666600
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666f700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666c67700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600c00000
00000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000c00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000bb33bb00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000333000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000070000000000000000000000000323000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000323000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000003333300000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000b0b0b00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000030030300000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000b00bb000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000006770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000006f70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000086660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000066600000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000
00000000000086cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

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
0112000000204002041d5541c5541d5541c5541d554185041850418504215541f554215641f5542156418504185041850421554185542156418554215641850418504185041a554235541a564235542656400204
01120000297352d745297352d745297352d7452973528725297352d745297352d745297352d7452a7352b7452f7552b7452f7552b7452f7552b7452a73529745287552b745287552b745347352b7552874528745
011200002d555005053455532555345553255534555005052b55500505325552f555325552f555325550050535555005003555534555355553555535555005053755537555375550050535555345553255530555
011200002d555005053455532555345553255534555005052b55500505325552f555325552f55532555005053555500500355553455535555355553555500505375553555532555305552f5552d5552b55528555
011200001174216702117520c702117420c7021174212752137520c702137420c702137420c7021373214752157520c702157320c702157420c70215742167521776213702177420c70217752007001775200000
01120000187551870518745187551874518705187351d7451a7551c7051a7551a7451a755187051a7451a7551a7651c7051a7451a7551a765187051a745197551876518705187451875518755187451873518735
0112000015750157501575000700007000070000700007001f7501f7501f750007000070000700007000070015750157501575000700007000070000700007001f7501f7501f7500070000700007000070000700
011200000c053000030c0030a0030c053020030c003020030c053000030c003000000c0530c003010030c053000030c003000030c053000030c003010000c053000030c0030c0532b7540c0532b7542b75400000
011200000070400704007040070400704007040070429754007040070400704007040070400704007041c754007040070400704007040070400704007041e7540070400704007040070400704007040070424754
011200000c053000030c0030a0030c053020030c0031d7540c053000030c0030c053000000c053005041c7540c053000030c0030a0030c05300504005041e7540c053000030c0030c053000000c0530050423752
011200200c053000030c0030a0030c053020030c003020030c053000030c0030c053000000c0530c003010030c053000030c003000030c053000030c003010030c05300000000030c0530c0000c0530c0000c000
01100000116020f6021260206602106020f60211602086021060212602106020c602116021161213622116121161210622116121363213642106321165213632176521a642186521763217642186521a6621c672
001000201d6721c662186521764215632016020160201602016020160201602016020160200602006020060200602006020160201602026020260202602026020260203602036020360200000000000000000000
001000200060200202006020060201602026020260202602026020160201602016020160201602016020160201602006020060200602006020060201602016020260202602026020260202602036020360203602
010600001555318553095000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000000
010d000018052180001c0001c0001a052000021d0001c0521d0521d05200000000001c0521c052130001f00018052150021d0001c0021d052000021f0001c0521d0521d0521d0521d0521f0001f0001f00200002
010d00001f0521a50021000210002105200000000001f0521c0521c0521c0521c0521c0521c00000000000001d052000001f052000001d052000001f0521f052210521c05200000210521c052000000000000000
01180000181551815518155181051815518155181051d175201552015520155181052015520155181051f105181551815518155181051815518155181051a1551c1551c1551c1551d1051c1551c1551810518105
0118000029575000002b5002957500000295752a5552b5552c0552c0000000026055280552605528055260552805500000000002b0552a0552905528055260552805500000000002a0552b055360553705500000
011800001c1451c1351c1451c1051c1451c1451810521105181351813518135181051814518145181051a1351c1351c1351c1351c1051c1451c1451c105181051e1351e1351e135181051f1451f1451810518105
011800002b5552b5052b5052b5752b5052b555245052657527555275052755527505275552755500005245052b5552b5052b5052b5552b5052b5552b5052d5552f555000052f5552f5553055530545305352f525
01180000221552215522155181052215522155181051f155201552015520155181052015520155181051f105221552215522155181052215522155181051a1551c1551c1551c1551d1051c1551c1551810518105
011800000c5750c505105750c5050c575105750c505155050c5750c5750f5750c5050c5750f5750c5051a1000c5750c505105750c5050c575105750c5051550510575105750f5750c505105751f5550710013500
011800000c5750c505105750c5050c575105750c505155050c5750c5750f5750c5050c5750f5750c505155050c5750c505105750c5050c575105750c505155050c5751a5001a5751050010572115751357500000
000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002d5322d5322d5322d5322d5322d53224500245002f5322f5322f5322f5322f5322f53224500245002d5322d5322d5322d5322d5322d53224500245002f5322f5322f5322f5322f5322f5322450024500
010c00002d5522d552245022450224552245022f5522450224502245022f552245022f552245022d552245022b5522b55224502245022d5522d55224502245022f5522f5522f5522f50224502245022450224502
010c00002d5522d552000000000000000000002d5522d552245522455224552245520000000000000000000026552265520000000000000000000026552265522855228552285522855228552000000000000000
010c00002655226552000000000000000000002455224552245002450024552245522f5522f552000000000026552265520000000000275522755200000000002855228552285522855228552000000000000000
010c00002d5522d552000000000000000000002d5522d5522f5522f5522f5522f552000000000000000000003055230552000000000000000000002f5522f5523055230552305523055230552245000000000000
010c000029552295522b5522b552000000000029552295522855228552285520000000000000002955229552285522855200000000002b5522b55200000000002b5522b5522b5522b5522b5522b5520000000000
000c000029552295520000000000000000000030552305002f5522f500000000000030552305002f5520000030552305523055230552305520000000000000000000000000000000000000000000000000000000
010c00001c0551c0051f005180051d055180051d0551800518005180051c055180051d055180051c055180051c0551c0051f005180051d055180051d0551800518005180051c055180051d055180051c05518005
010c00001c0551c0051f005180051d055180051d0551800518005180051c055180051d055180051c055180051c0551c0051f005180051d055180051c0551c0001b0551a055190551805523055230551800518000
010c00001c0501c05000000000001d030000001c0500000000000000001c030000001d040000001c050000001c0501c05000000000001d030000001c0500000000000000001c030000001d040000001c05000000
010c00000c7500c7000c75000700376250070037625007000c7500c7000c75000700376250070037625007000c7500c7000c75000700376250070037600007000c7500c7000c7500070037625376003762500700
010c00001c0501c05000000000001d030000001c0500000000000000001c030000001d040000001c050000001d0501d05000000000001c030000001a0500000000000000001a030000001c040000001a05000000
010c0000180501805000000000001a030000001a05000000000000000018030000001a0400000018050000001c0501c05000000000001a030000001c0500000000000000001c030000001a040000001c05000000
010c00001c0501c05000000000001d030000001c0500000000000000001c030000001d040000001c050000001c0501c05000000000001d030000001c050000001b0501a050190501805017050160501505015050
010c00001d0501d05000000000001c030000001d0500000000000000001c030000001d040000001c050000001a0501a05000000000001c050000001a0500000000000000001a050000001c050000001a05000000
010c00001a0501a0500000000000190500000018050000001705000000180500000017050000000c0501705018050180501805018050180501805018050180501800000000000000000000000000000000000000
__music__
01 0e4a1440
00 0b0f1444
00 0b140f40
00 0b110f51
00 0c101244
00 0d101347
00 0b140f51
00 0b0f1151
00 0a0e1454
02 0b0f1151
01 605e1e60
01 1b1d5e60
00 1b1d5e20
00 1f1d5e20
00 1b1d1e20
02 1f1d1c20
01 632c5444
01 232c4344
00 24302d44
00 252e2d44
00 262f2d44
00 272e2d44
00 262f2d44
00 252e2d44
00 262f2d44
00 272c2d44
00 26304344
00 28314344
02 29322d44
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

