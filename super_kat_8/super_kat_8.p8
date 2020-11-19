pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
 state = "menu"
 i = 0
 player = {
  x = 64 - 10,
  y = 100,
  cd = 5,
  state = "alive",
 }
 nina = {
  x = 64 + 10,
  y = 100,
  state = "show",
  sprite = 32,
 }
 calculate_player_rect()
 stars = {}
 shots = {}
 bullets = {}
 brushes = {}

 events = {
  {
   x = 20,
   y = -10,
   spawn = "brush",
   offset = 2,
  },
  {
   x = 107,
   y = -10,
   spawn = "brush",
   offset = 3,
  },
  {
   x = 60,
   y = -10,
   spawn = "brush",
   offset = 5,
  }
 }

 particles = {}
end

function create_dialog(messages)
  return {
    ticks = 0,
    messages = messages,

    set = function(self, messages)
      self.ticks = 0
      self.messages = messages
    end,  -- dialog:set

    update = function(self)
      if #self.messages <= 0 then
        return
      end
      self.ticks += 1
      self.current_message = sub(self.messages[1].text, 0, self.ticks / 5)
      if self.ticks / 5 > #self.messages[1].text + 30
         and not self.messages[1].persistent then
        self.ticks = 0
        deli(self.messages, 1)
      end
    end,  -- dialog:update

    draw = function(self)
      if #self.messages <= 0 then
        return
      end
      rectfill(0, 120, 127, 127, 1)
      print(self.current_message, 18, 122, 7)
      spr(self.messages[1].sprite, 0, 120, 1, 1)
    end,  -- dialog:draw
  }
end  -- create_dialog

function normalize(x, y)
 length = sqrt(x * x + y * y)
 return {
  x = x / length,
  y = y / length,
 }
end

function collides(bullet, rect)
 return bullet.x >= rect.x0 and
        bullet.x <= rect.x1 and
        bullet.y >= rect.y0 and
        bullet.y <= rect.y1
end

function collides_rect(r1, r2)
 return r1.x0 <= r2.x1 and
        r1.x1 >= r2.x0 and
        r1.y0 <= r2.y1 and
        r1.y1 >= r2.y0
end

function kill_player()
 if player.state != "alive" then
  return
 end
 player.state = "dead"
 player.respawn_cd = 200
 for s = 0.25, 1, 0.25 do
  for i = 1, 32 do
   local colour
   if i < 6 then
    colour = 4
   elseif i < 11 then
    colour = 8
   elseif i < 20 then
    colour = 4
   elseif i < 30 then
    colour = 1
   else
    colour = 4
   end
   add(particles, {
    x = player.x,
    y = player.y,
    life = 200,
    dx = cos(i / 32) * s,
    dy = sin(i / 32) * s,
    colour = colour,
   })
  end
 end
end

function explode(target)
 for i = 0, 8 do
  add(particles, {
   x = target.x,
   y = target.y,
   life = 30,
   dx = cos(i / 8),
   dy = sin(i / 8),
   colour = 2,
  })
 end
end

function shoot(from, to, speed)
 d = normalize(to.x - from.x, to.y - from.y)
 add(bullets, {
  x = from.x,
  y = from.y,
  dx = d.x * speed,
  dy = d.y * speed,
 })
end

function calculate_player_rect()
 player.rect = {
  x0 = player.x - 1,
  x1 = player.x + 1,
  y0 = player.y - 2,
  y1 = player.y + 0,
 }
end

function _update60()
 if state == "menu" then
  if btnp(❎) or btnp(🅾️ ) then
   start_time = time()
   state = "intro"
   dialog = create_dialog({
    {
     text = "come hang out this weekend",
     sprite = 32,
    },
    {
     text = "i'm busy with art, sorry",
     sprite = 0,
    },
    {
     text = "just ignore it",
     sprite = 32,
    },
    {
     text = "what could go wrong?",
     sprite = 32,
    },
    {
     text = "don't be irresponsible",
     sprite = 0,
    },
    {
     text = "there's a lot at stake",
     sprite = 0,
    },
    {
     text = "?",
     sprite = 32,
    },
    {
     text = "bad things will happen",
     sprite = 0,
    },
    {
     text = "like what?",
     sprite = 32,
    },
    {
     text = "well anything",
     sprite = 0,
    },
    {
     text = "we are in a game after all",
     sprite = 0,
    },
    {
     text = "and i can't skip this intro",
     sprite = 0,
    },
    {
     text = "i made it unskippable",
     sprite = 32,
    },
    {
     text = "because i know you <3",
     sprite = 32,
    },
    {
     text = ">:(",
     sprite = 0,
    },
    {
     text = "anyway what's that?",
     sprite = 0,
    },
    {
     text = "your drawing tablet",
     sprite = 32,
    },
    {
     text = "sorry i can't draw",
     sprite = 32,
    },
    {
     text = "help!!!",
     sprite = 32,
    },
    {
     text = "i'm coming!",
     sprite = 0,
    },
    {
     text = "hahaha she said i'm coming",
     sprite = 68,
    },
    {
     text = "you'll never catch me!",
     sprite = 68,
    },
   })
   return
  end
  return
 end
 if state == "intro" then
  dialog:update()
  if #dialog.messages == 0 then
   state = "game"
  end
  return
 end


 -- game state
 offset = time() - start_time
 if player.state == "dead" then
  player.respawn_cd -= 1
  if player.respawn_cd <= 0 then
   player.state = "invulnerable"
   player.invulnerable_cd = 120
  end
 end
 if player.state == "invulnerable" then
  player.invulnerable_cd -= 1
  if player.invulnerable_cd <= 0 then
   player.state = "alive"
  end
 end
 if player.state != "dead" then
  player.sprite = (time() * 5) % 4
  if btn(⬅️) then
   player.x -= 1
  end
  if btn(➡️) then
   player.x += 1
  end
  if btn(⬇️) then
   player.y += 1
  end
  if btn(⬆️) then
   player.y -= 1
  end
  if player.cd <= 0 and btn(🅾️ ) then
   player.cd = 10
   add(shots, {
    x = player.x,
    y = player.y - 1
   })
  end
  player.x = mid(0, player.x, 127)
  player.y = mid(0, player.y, 127)
  player.cd = max(0, player.cd - 1)
 end
 calculate_player_rect()
 if flr(rnd() * 20) == 0 then
   add(stars, {
     x = rnd(127),
     y = 0,
     colour = 5,
   })
 end

 event = events[1]
 while event and event.offset <= offset do
  del(events, event)
  if event.spawn == "brush" then
   add(brushes, {
    x = event.x,
    y = event.y,
    hp = 5,
    dmg = false,
    cd = flr(rnd(30)) + 120,
   })
  end
  offset = 0
  start_time = time()
  event = events[1]
 end

 for star in all(stars) do
   star.y += 1
   if star.y > 128 then
    del(stars, star)
   end
 end

 for brush in all(brushes) do
  local brush_rect = {
   x0 = brush.x - 2,
   x1 = brush.x + 1,
   y0 = brush.y - 3,
   y1 = brush.y + 4,
  }
  if collides_rect(player.rect, brush_rect) then
   kill_player()
  end
  if brush.cd % 5 == 0 then
   add(particles, {
    x = brush.x,
    y = brush.y,
    life = 20,
    dx = -0.1 + rnd(0.2),
    dy = -0.7,
    colour = 12,
   })
  end
  brush.dmg = false
  brush.y += 0.2
  if brush.y > 160 then
   del(brushes, brush)
  end
  brush.cd -= 1
  if brush.cd <= 0 then
   brush.cd = 120
   shoot(brush, player, 1)
  end
  for shot in all(shots) do
   if collides(shot, brush_rect) then
    del(shots, shot)
    brush.dmg = true
    brush.hp -= 1
    if brush.hp <= 0 then
     explode(brush)
     del(brushes, brush)
    end
   end
  end
 end

 for shot in all(shots) do
  shot.y -= 3
  if shot.y < 0 then
   del(shots, shot)
  end
 end

 for bullet in all(bullets) do
  bullet.x += bullet.dx
  bullet.y += bullet.dy
  if not collides(bullet, { x0 = 0, x1 = 128, y0 = 0, y1 = 128 }) then
   del(bullets, bullet)
  end
  if player.state == "alive" and
     collides(bullet, player.rect) then
   del(bullets, bullet)
   kill_player()
  end
 end

 for particle in all(particles) do
  particle.x += particle.dx
  particle.y += particle.dy
  particle.life -= 1
  if particle.life <= 0 then
   del(particles, particle)
  end
 end
end

function _draw()
 cls()

 if state == "menu" then
  print(" super kat 8 ", 36, 40, 7)
  print("press ❎ | 🅾️ ", 36, 60, 7)
  return
 end

 -- game
 for star in all(stars) do
  pset(star.x, star.y, star.colour)
 end

 for particle in all(particles) do
  -- todo make stars particles
  pset(particle.x, particle.y, particle.colour)
 end

 for brush in all(brushes) do
  if brush.dmg then
   pal({[12] = 8, [2] = 3})
  end
  spr(64 + flr(time() * 3) % 4, brush.x - 3, brush.y - 8, 1, 2)
  pal()
  --rectfill(brush.x - 2, brush.y - 3, brush.x + 1, brush.y + 4, 3)
 end

 for shot in all(shots) do
   pset(shot.x, shot.y, 2)
 end

 for bullet in all(bullets) do
  pset(bullet.x, bullet.y, 14 + flr(time() * 8) % 2)
 end

 if player.state == "alive" or
    (player.state == "invulnerable" and flr(time() * 8) % 2 == 0) then
  spr(player.sprite, player.x - 3, player.y - 8, 1, 2)
  --rectfill(player.rect.x0, player.rect.y0, player.rect.x1, player.rect.y1, 3)
 end

 if nina.state == "show" then
  spr(nina.sprite, nina.x - 3, nina.y - 7, 1, 2)
 end

 -- hud
 dialog:draw()
end
__gfx__
00888000008880000088800000888000000888000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000
088f8800088f8800088f8800088f88000088c880088c880000000000000000000000000000000000000000000000000000000000000000000000000000000000
08fff80008fff80008fff80008fff800088ccc8888ccc88000000000000000000000000000000000000000000000000000000000000000000000000000000000
88fff88008fff88088fff88088fff80088ccecc88ccecc8800000000000000000000000000000000000000000000000000000000000000000000000000000000
044444000444448004444400844444008cceeecccceeecc800000000000000000000000000000000000000000000000000000000000000000000000000000000
0f444f000f444f000f444f000f444f008cceeeeeeeeeecc800000000000000000000000000000000000000000000000000000000000000000000000000000000
0f444f000f444f000f444f000f444f0088cee777777eec8800000000000000000000000000000000000000000000000000000000000000000000000000000000
0f444f0000444f000f444f000f44400008ceee7777eeec8000000000000000000000000000000000000000000000000000000000000000000000000000000000
0044400000444f00004440000f44400008ccce7777eccc8000000000000000000000000000000000000000000000000000000000000000000000000000000000
004440000044400000444000004440000088cee77eec880000000000000000000000000000000000000000000000000000000000000000000000000000000000
001010000010100000101000001010000008cceeeecc800000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010100000101000001010000010100000088cceecc8800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00101000001010000010100000101000000088cccc88000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001010000010100000101000004010000000088cc880000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00404000001040000040400000001000000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004000000000000000004000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04fff400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04fff400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04eee400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4feeef40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4feeef40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0feeef00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001100000000000000110000555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
0111100001cc10000111100001cc1000556666666666666506000000000000000000000000000000000000000000000000000000000000000000000000000000
01cc100001cc100001cc110001cc1000d56666666666666566000000000000660000000000000000000000000000000000000000000000000000000000000000
1ccc100001cc100001ccc10001cc1000556666666666666566000000000000660000000000000000000000000000000000000000000000000000000000000000
1ccc100001cc100001ccc10001cc1000d56666666666666566000000000006600000000000000000000000000000000000000000000000000000000000000000
11661000016610000166110001661000556666666666666566000000000006600000000000000000000000000000000000000000000000000000000000000000
04994000049940000499400004994000d56666666666666566000000000066000000000000000000000000000000000000000000000000000000000000000000
04994000049940000499400004994000d56666666666666566000000000066000000000000000000000000000000000000000000000000000000000000000000
04994000049940000499400004994000d56666666666666566000000000660000000000000000000000000000000000000000000000000000000000000000000
04994000049940000499400004994000d56666666666666566000000000660000000000000000000000000000000000000000000000000000000000000000000
04994000049940000499400004994000556666666666666555000000005500000000000000000000000000000000000000000000000000000000000000000000
04994000049940000499400004994000d56666666666666555000000005500000000000000000000000000000000000000000000000000000000000000000000
04994000049940000499400004994000556666666666666555000000055000000000000000000000000000000000000000000000000000000000000000000000
04444000044440000444400004444000d56666666666666555000000055000000000000000000000000000000000000000000000000000000000000000000000
00440000004400000044000000440000556666666666666555000000550000000000000000000000000000000000000000000000000000000000000000000000
00440000004400000044000000440000555555555555555560000000600000000000000000000000000000000000000000000000000000000000000000000000
