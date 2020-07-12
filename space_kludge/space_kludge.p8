pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- space kludge
-- by kat and nina

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
 return normalize(g_player.x - element.x, g_player.y - element.y)
end

function colliding_p_r(point, rect)
  return point.x >= rect.x and point.x <= rect.x + 8 and
         point.y >= rect.y and point.y <= rect.y + 8
end  -- colliding

function colliding_r_r(rect1, rect2)
  return rect1.x <= rect2.x + 8 and
         rect1.x + 8 >= rect2.x and
         rect1.y <= rect2.y + 8 and
         rect1.y + 8 >= rect2.y
end

function colliding_r_player(rect)
  -- the player is two rectangles stacked on top of each other
  return colliding_r_r(g_player, rect) or
         colliding_r_r({x = g_player.x, y = g_player.y + 8}, rect)
end

function create_player()
  return {
    x = 40,
    y = 50,
    dx = 0,
    dy = 0.2,
    facing = 1,
    inventory = {},
    show_inventory = false,
    equipped_item = nil,
    -- todo find good number
    hp = 6000,

    -- the number of frames you can hold the jump button to go higher
    jump_ticks = 0,

    -- the number of frames the player held an arrow key
    movement_ticks = 0,

    draw = function(self)
      -- todo draw proper death animation
      if self.hp > 0 then
        local top_sprite = 0
        local bottom_sprite = 16 + self.movement_ticks / 5 % 4

        if self.jump_ticks > 0 then
          top_sprite = 4
          bottom_sprite = 20
        end

        spr(top_sprite, self.x, self.y, 1, 1, self.facing != 1)
        spr(bottom_sprite, self.x, self.y + 8, 1, 1, self.facing != 1)
      end
      if self.hint then
        local y = flr(get_sine_wave(flr(self.y) - 6, 1))
        rectfill(self.x, y + 1, self.x + 6, y + 3, 0)
        print(self.hint, self.x, y, 7)
      end
    end,  -- player:draw

    update = function(self)
      self.hint = nil
      if self.hp <= 0 then
        return
      end

      self.in_space = g_map:is_space(self.x + 4, self.y + 8)

      if btnp(❎) then
        self.show_inventory = not self.show_inventory
        self.selected_index = 0
      end

      if self.show_inventory then
        if btn(⬇️) then
          self.selected_index += 1
        elseif btn(⬆️) then
          self.selected_index -= 1
        elseif btnp(🅾️) then
          if self.equipped_item == self.inventory[self.selected_index] then
            self.equipped_item = nil
          else
            self.equipped_item = self.inventory[self.selected_index]
          end
        end
        self.selected_index = mid(1, self.selected_index, #self.inventory)
      else
        if not self.in_space then
          if btn(➡️) then
            self.movement_ticks += 1
            self.dx += 0.25
            self.facing = 1
          elseif btn(⬅️) then
            self.movement_ticks += 1
            self.dx -= 0.25
            self.facing = -1
          else
            self.movement_ticks = 0
            if self.dx > 0 then
              self.dx -= 0.125
            elseif self.dx < 0 then
              self.dx += 0.125
            end
          end
          self.dx = mid(-1, self.dx, 1)
        end

        for actor in all(g_actors) do
          if actor.activatable and
             colliding_p_r({x = self.x + 4, y = self.y + 8}, actor) then
            if btnp(⬇️) then
              actor:activate()
            end
            self.hint = "⬇️"
          end
        end
      end

      if not self.in_space then
        if btn(⬇️) then
          self.dy += 0.4
        end
        -- downwards acceleration (gravity)
        self.dy += 0.1
      end
      self.dy = min(self.dy, 3)

      local points = {
        { x = 0, y = 15 },
        { x = 7, y = 15 },
        { x = 0, y = 7 },
        { x = 7, y = 7 },
        { x = 0, y = 0 },
        { x = 7, y = 0 },
      }
      local on_floor = false
      for point in all(points) do
        -- vertical collisions
        if g_map:is_solid(point.x + self.x, point.y + self.dy + self.y) then
          local tile_y = g_map:clamp(
            point.x + self.x, point.y + self.dy + self.y).y
          if self.dy < 0 then
            -- hit a ceiling
            self.y = tile_y + 8
          else
            self.y = tile_y - 16
            -- hit a floor
            on_floor = true
          end
          self.dy = 0
        end

        -- horizontal collisions
        if g_map:is_solid(point.x + self.dx + self.x, point.y + self.y) then
          self.dx = 0
        end

        -- pick up items
        for actor in all(g_actors) do
          if actor.pickable and colliding_r_player(actor) then
            add(self.inventory, actor)
            del(g_actors, actor)
          end
        end
      end

      self.x += self.dx
      self.y += self.dy

      if not self.show_inventory then
        if btn(⬆️) and on_floor then
          -- jump
          self.jump_ticks = 15
        end

        if self.jump_ticks > 0 then
          self.jump_ticks -= 1
          if btn(⬆️) then
            self.dy = -1.8
          end
        end

        if btn(🅾️) then
          if self.equipped_item then
            self.equipped_item:use()
          end
        end
      end
    end,  -- player:update

    draw_inventory = function(self)
      camera()
      rectfill(8, 28, 120, 100, 0)
      rect(7, 27, 121, 101, 1)
      print("inventory", 46, 30, 7)
      for i = 1, #self.inventory do
        print(self.inventory[i].name, 30, 30 + i * 10, 7)
        if i == self.selected_index then
          print(">", 12, 30 + i * 10)
        end
        if self.equipped_item == self.inventory[i] then
          print("e", 22, 30 + i * 10, 8)
        end
      end
      if #self.inventory <= 0 then
        print("[empty]", 30, 40, 7)
      end
      camera(g_camera.x, g_camera.y)
    end,  -- player:draw_inventory

    take_damage = function(self, damage)
      self.hp -= damage
      self.dy = -0.5
    end,  -- player:take_damage
  }
end  -- create_player

function create_denuvo(x, y, dx, dy)
  return {
    x = x,
    y = y,
    dx = dx,
    dy = dy,
    state = "flying",
    damaged_points = {},

    update = function(self)
      if self.state == "flying" then
        self.x += self.dx
        self.y += self.dy
        -- todo remove when out of bounds
        local points = {
          {
            x = self.x + 4,
            y = self.y
          },
          {
            x = self.x + 8,
            y = self.y + 4
          },
          {
            x = self.x + 4,
            y = self.y + 8
          },
          {
            x = self.x,
            y = self.y + 4
          },
        }
        for point in all(points) do
          local sprite = g_map:get_sprite(point.x, point.y)
          if fget(sprite, 0) then
            self.state = "attached"
            self.attached_to = g_map:clamp(point.x, point.y)
          end
        end
      elseif self.state == "attached" then
        create_particle(self.x + 4, self.y + 4, rnd(2) - 1, rnd(2) - 1, 20, 2)
        if flr(time() * 10) % 2 == 0 then
          add(self.damaged_points, {
            x = self.attached_to.x + rnd(8), y = self.attached_to.y + rnd(8)
          })
          if #self.damaged_points >= 100 then
            self.state = "flying"
            self.dx = -dx
            self.dy = -dy
            mset(self.attached_to.x \ 8, self.attached_to.y \ 8, 0)
            add(g_actors, create_hull_puncture(
              self.attached_to.x, self.attached_to.y, self.dx, self.dy))
          end
        end
      end
    end,  -- denuvo:update

    draw = function(self)
      spr(32, self.x, self.y)
      if self.state == "attached" then
        for damaged_point in all(self.damaged_points) do
          pset(damaged_point.x, damaged_point.y, 0)
        end
      end
    end,  -- denuvo:draw
  }
end  -- create_denuvo

function create_hull_puncture(x, y, dx, dy)
  return {
    update = function()
      if flr(time() * 10) % 4 == 0 then
        local x_offset
        if dx == 0 then
          x_offset = rnd(50) - 25
        else
          x_offset = rnd(50) * -sgn(dx)
        end
        if dy == 0 then
          y_offset = rnd(50) - 25
        else
          y_offset = rnd(50) * -sgn(dy)
        end

        local particle = create_particle(
          x + rnd(8) + x_offset, y + rnd(8) + y_offset,
          dx, dy, 60, 7)
        particle._update = function(self)
          if g_map:is_solid(self.x, self.y) then
            return true
          end
          if g_map:is_space(self.x, self.y) then
            return
          end
          local vector = normalize(x - self.x + 4, y - self.y + 4)
          self.dx += vector.x * 0.1
          self.dy += vector.y * 0.1
        end
      end
      if not g_player.in_space and
         abs(g_player.x - x) < 50 and
         abs(g_player.y - y) < 50 then
        if dx == 0 and flr(g_player.x) != flr(x) then
          g_player.dx -= sgn(g_player.x - x) * 0.15
        else
          g_player.dx = dx
        end
        if dy == 0 then
          g_player.dy = sgn(g_player.y - y) * 0.2
        else
          g_player.dy = dy * 2
        end
      end
    end,  -- hull_puncture:update

    draw = function()
      -- todo draw a sprite
    end,  -- hull_puncture:draw
  }
end

function create_dialog(messages)
  return {
    ticks = 0,
    messages = messages,

    set = function(self, messages)
      self.messages = messages
      self.ticks = 0
    end,  -- dialog:set

    update = function(self)
      if #self.messages <= 0 then
        return true
      end
      self.ticks += 1
      self.current_message = sub(self.messages[1].text, 0, self.ticks / 5)
      if self.ticks / 5 > #self.messages[1].text + 12
         and not self.messages[1].persistent then
        self.ticks = 0
        deli(self.messages, 1)
      end
    end,  -- dialog:update

    draw = function(self)
      if #self.messages <= 0 then
        return
      end
      camera()
      rectfill(0, 0, 127, 15, 12)
      print(self.current_message, 18, 2, 7)
      palt(0, false)
      spr(self.messages[1].sprite, 0, 0, 2, 2)
      palt()
      camera(g_camera.x, g_camera.y)
    end,  -- dialog:draw
  }
end  -- create_dialog

function create_particle(x, y, dx, dy, life, color)
  local particle = {
    x = x,
    y = y,
    dx = dx,
    dy = dy,
    life = life,
    color = color,

    update = function(self)
      self.life -= 1
      if self.life <= 0 then
        return true
      end
      if g_map:is_solid(self.x + self.dx, self.y) then
        self.dx *= -1
      end
      if g_map:is_solid(self.x, self.y + self.dy) then
        self.dy *= -1
      end
      self.x += self.dx
      self.y += self.dy

      if self._update then
        return self:_update()
      end
    end,  -- particle:update

    draw = function(self)
      pset(self.x, self.y, self.color)
    end,  -- particle:draw
  }
  add(g_actors, particle)
  return particle
end  -- create_particle

function get_sine_wave(y, multiplier)
  return y + sin(time() / multiplier) * multiplier - multiplier + 0.5
end  -- get_sine_wave

function draw_item(item, sprite)
  spr(sprite, item.x, get_sine_wave(item.y, 2))
end  -- draw_item

function create_extinguisher(x, y)
  return {
    x = x,
    y = y,
    pickable = true,
    name = "fire extinguisher",
    draw = function(self)
      draw_item(self, 32)
    end,  -- extinguisher:draw
    use = function()
      local x_offset = 0
      if g_player.facing == 1 then
        x_offset = 8
      end
      local particle = create_particle(
        g_player.x + x_offset, g_player.y + 8,
        g_player.facing + rnd(2) - 1, rnd(1),
        30, flr(rnd(2)) + 6)
        particle._update = function(self)
          for actor in all(g_actors) do
            if actor.name == "fire" then
              if colliding_p_r(self, actor) then
                actor:take_damage(1)
                return true
              end
            end
          end
      end  -- extinguisher_particle:update
    end,  -- extinguisher:use
  }
end  -- create_extinguisher

function create_jetpack(x, y)
  return {
    x = x,
    y = y,
    fuel = 1000,
    pickable = true,
    name = "jetpack",
    draw = function(self)
      draw_item(self, 33)
    end,  -- jetpack:draw
    use = function(self)
      self.fuel -= 1
      if self.fuel <= 0 then
        return true
      end
      g_player.dy -= 0.12
      g_player.dy = min(-0.8, g_player.dy)
      local x_offset = 0
      if g_player.facing == -1 then
        x_offset = 8
      end

      create_particle(g_player.x + x_offset, g_player.y + 8,
                      -g_player.facing * rnd(0.3), 1.5 + rnd(0.5),
                      30, 2)
    end,  -- jetpack:use
  }
end  -- create_jetpack

function create_enemy(x, y, name, hp)
  return {
    x = x,
    y = y,
    dx = 0,
    dy = 0,
    name = name,
    hp = hp,
    damage = 1,

    update = function(self)
      if self.hp <= 0 then
        return true
      end

      self.x += self.dx
      self.y += self.dy

      if colliding_r_player(self) then
        g_player:take_damage(self.damage)
      end
    end,  -- enemy:update()

    take_damage = function(self, damage)
      self.hp -= damage
    end,  -- enemy:take_damage
  }
end  -- create_enemy

function create_switch(x, y, target)
  return {
    x = x,
    y = y,
    target = target,
    on = false,
    activatable = true,

    update = function(self)
    end,  -- switch:update

    draw = function(self)
      if self.on then
        pal({[8] = 11})
      end
      spr(48, self.x, self.y)
      pal()
    end,  -- switch:draw

    activate = function(self)
      self.on = not self.on
      self.target:toggle(self.on)
    end
  }
end

function create_door(x, y, size)
  return {
    x = x,
    y = y,
    size = size,
    status = "closing",
    is_solid = true,
    pixels_up = 0,
    direction = 1,

    get_rects = function(self)
      local rects = {}
      for i = 0, (size - 1) do
        add(rects, {x = self.x, y = self.y + i * 8})
      end
      return rects
    end,  -- door:get_rects

    update = function(self)
      if self.direction == -1 and self.pixels_up < size * 8 then
        self.pixels_up += 1
        if self.pixels_up >= size * 8 then
          self.is_solid = false
        end
      elseif self.direction == 1 and self.pixels_up > 0 then
        self.pixels_up -= 1
        self.is_solid = true
      end
    end,  -- door:update

    draw = function(self)
      palt(0, false)
      clip(x - flr(g_camera.x), y - flr(g_camera.y), 8, 8 * size)
      for i = 0, (size - 1) do
        local sprite = 38
        if i >= 1 then
          sprite += 16
        end
        spr(sprite, x, y + i * 8 - self.pixels_up)
      end
      clip()
      palt()
    end,  -- door:draw

    collides_with = function(self, x, y)
      for rect in all(self:get_rects()) do
        if colliding_p_r({x = x, y = y}, rect) then
          return true
        end
      end
    end,  -- door:collides_with_player

    toggle = function(self, on)
      if on then
        self.direction = -1
      else
        for rect in all(self:get_rects()) do
          if colliding_r_player(rect) then
            if g_player.x < rect.x + 4 then
              g_player.x = rect.x - 8
            else
              g_player.x = rect.x + 9
            end
          end
        end
        self.direction = 1
      end
    end,  -- door:toggle
  }
end  -- create_door

function create_fire(x, y)
  local fire = create_enemy(x, y, "fire", 8)

  fire.draw = function(self)
    local sprite = 56 + flr(time() * 10 + x) % 3
    clip(x - flr(g_camera.x), y - flr(g_camera.y), 8, 8)
    spr(sprite, self.x, self.y + 8 - self.hp)
    clip()
  end  -- fire:draw
  return fire
end  -- create_fire

function create_tutorial_script(messages, target)
  local first_time = true

  return {
    toggle = function(self, on)
      if first_time then
        g_dialog:set(messages)
        first_time = false
      end
      target:toggle(on)
    end,  -- switch.target:toggle
  }
end  -- create_tutorial_script

function _init()
  g_player = create_player()
  g_actors = {}

  g_background = {
    stars = {},

    update = function(self)
      for star in all(self.stars) do
        star.x -= .4 * star.scale
        if star.x < 0 then
          star.x = 1024
        end
      end
    end,  -- background:update

    draw = function(self)
      for star in all(self.stars) do
        pset(star.x, star.y, 7)
      end
    end,  -- background:draw
  }
  for i = 0, 500 do
    add(g_background.stars, {
      x = rnd(1024),
      y = rnd(512),
      scale = rnd(1)
    })
  end

  add(g_actors, create_door(80, 48, 2))
  add(g_actors, create_switch(72, 56, create_tutorial_script({
    {
      text = "jump (⬆️) to make it\nthrough the cargo",
      sprite = 5,
      persistent = true,
    }
  }, g_actors[#g_actors])))
  add(g_actors, create_switch(88, 56, g_actors[#g_actors - 1]))
  add(g_actors, create_door(512, 40, 3))
  add(g_actors, create_switch(504, 56, create_tutorial_script({
    {
      text = "make haste!\ni need to use that toilet!",
      sprite = 5,
    },
    {
      text = "use the teleporter to\nquickly get there",
      sprite = 5,
      persistent = true,
    },
  }, g_actors[#g_actors])))
  add(g_actors, create_door(554, 40, 3))
  add(g_actors, create_switch(562, 56, g_actors[#g_actors]))

  add(g_actors, create_extinguisher(50, 56))
  add(g_actors, create_jetpack(60, 56))

  add(g_actors, create_fire(120, 64))
  add(g_actors, create_fire(128, 64))
  add(g_actors, create_fire(136, 64))

  add(g_actors, create_denuvo(120, 0, 0, 0.2))

  g_map = {
    draw = function(self)
      palt(0, false)
      palt(14, true)
      map(0, 0, 0, 0, 128, 64)
      palt()
    end,  -- map:draw

    get_sprite = function(self, x, y)
      return mget(x \ 8, y \ 8)
    end,  -- map:get_sprite

    is_solid = function(self, x, y)
      if fget(self:get_sprite(x, y), 0) then
        return true
      end
      for solid in all(e_solids) do
        if solid:collides_with(x, y) then
          return true
        end
      end
    end,  -- map:is_solid

    is_space = function(self, x, y)
      return self:get_sprite(x, y) == 0
    end,  -- map:is_space

    clamp = function(self, x, y)
      return { x = (x \ 8) * 8, y = (y \ 8) * 8 }
    end,  -- map:coordinates_for
  }

  g_camera = {
    x = g_player.x - 64,
    y = g_player.y - 64,

    update = function(self)
      self.x = g_player.x - 64
      self.y = g_player.y - 64
    end,  -- camera:update
  }

  g_dialog = create_dialog({
    {
      text = "amber! amber! wake up!\nwe have an emergency!",
      sprite = 5,
    },
    {
      text = "the toilet in cargo bay c\nis clogged again!",
      sprite = 5,
    },
    {
      text = "can you go take a look?",
      sprite = 5,
    },
    {
      text = "open (⬇️) that door and get\nthere quick!",
      sprite = 5,
      persistent = true,
    },
  })
  add(g_actors, g_dialog)

  add(g_actors, g_player)
end  -- _init()

function _update60()
  g_background:update()
  for actor in all(g_actors) do
    if actor.update and actor:update() then
      del(g_actors, actor)
    end
  end
end  -- _update60

function _draw()
  cls()
  e_solids = {}
  for actor in all(g_actors) do
    if actor.is_solid then
      add(e_solids, actor)
    end
  end
  g_camera:update()
  camera(g_camera.x, g_camera.y)
  g_background:draw()
  g_map:draw()
  for actor in all(g_actors) do
    actor:draw()
  end
  if g_player.show_inventory then
    g_player:draw_inventory()
  end
  camera()
  print(stat(7), 0, 40, 7)
end  -- _draw
__gfx__
0090900000909000000990000090900000909000000000ffffff4466ddd1111dd1700000000007ff000000000000000000000000000000000000000000000000
009947500099475090994750009947500099475000000ffffffff466dd11111117000000000007f5000000000000000000000000000000000000000000000000
999445509994455009944550099445500994455000000f77ff77f446d1111111790000000055055f000000000000000000000000000000000000000000000000
09444cf009444ff009444cf009444fc099444cf000000744f74474461111119999900000005557f7000000000000000000000000000000000000000000000000
9444fcf09444fcf09444fcf09944ffcf9444fcff00000f00f400446f1111990000900000000bb577000000000000000000000000000000000000000000000000
04ffffff04ffffff04ffffff044ffff004fffff0000000fff4ff046f119999f00000000000555577000000000000000000000000000000000000000000000000
00fffff000fffff000fffff000ffff0000ffffc000000ffff44ff66fd9ff9fff00f0000000575777000000000000000000000000000000000000000000000000
00999f0000999f0000999f0000999f00009997cc00007fff444ff666d9ff9ffffff0000000557777000000000000000000000000000000000000000000000000
0947599009475990094759cc094759900947755c005507ffffff7666d99f9fffffff6666ffff6666000000000000000000000000000000000000000000000000
00455499004554990045599c00475c990045559000555555000f7766dd999fff9965656599656565000000000000000000000000000000000000000000000000
00455449004554490045549900455cc900444490000007fffff0f765777999ff9955555599555555000000000000000000000000000000000000000000000000
044ccc40044ccc0c04cc444000045cc0004444000000b7f777ff76555777999900dddddd999ddddd000000000000000000000000000000000000000000000000
044cc400044cc4cc04cc44400044444004444000000bb5777b776655d5577999999d8dcd999d8dcd000000000000000000000000000000000000000000000000
00444400054444cc00444cc00cc44440055cc000005555777b36655b57757779999ddddd7ddddddd000000000000000000000000000000000000000000000000
00cc55000550000000550ccc0cc40550055cc00000575777773655b3777755777ddd8d6d77dd8d6d000000000000000000000000000000000000000000000000
00ccc55005550000005550000c000555050c000000557777766555b37777775777dddddd570ddddd000000000000000000000000000000000000000000000000
00000000011001100000000000000000001111000011110066666666001111000000000000000000000000000000000000000000000000000000000000000000
000cc00001100110000110000000000001111110011111109555555a011111100000000000000000000000000000000000000000000000000000000000000000
5557cc000750075000017000000000000111111011555511a96666a9011111100000000000000000000000000000000000000000000000000000000000000000
00788cc0075775500055550007cccc0011555511157bbb519a44449a116666110000000000000000000000000000000000000000000000000000000000000000
0078800005555550008888007cc8cc10157bbb5157bbb335a94444a9167bbb610000000000000000000000000000000000000000000000000000000000000000
008880000550055000888800cc888110577bb3355bbbbb359a44449a677bb3360000000000000000000000000000000000000000000000000000000000000000
008880000880088000888800c118111057bb33355bb55bb5a94444a967bb33360000000000000000000000000000000000000000000000000000000000000000
008880000080080000555500011111005bb3ff355b5335b59a44449a6bb3ff360000000000000000000000000000000000000000000000000000000000000000
116666111166661111666611ffff55555333fff555333355a94444a96333fff60000000000000000000000000000000000000000000000000000000000000000
1607006116070061160600619955555555555555533333359a44449a666666660088000000080000000000000000000000000000000000000000000000000000
6078800660700b0660086006995555555111111553333335a94444a9511111150880000000080000008000000000000000000000000000000000000000000000
678a880667b00b06608a68069055555511111111153333519a44449a111111110880080000880880008800000007000000000000000000000000000000000000
608888066b0000b660868606999555551555555111533511a94444a9155555518888088008880088088808800007b00000000000000000000000000000000000
6008800660bbbb06600686068995555551111115555555559a44449a51111115898888808898888888888888007bb07000000000000000000000000000000000
160000611600006110600061775555550111111001111110a94444a90111111089988988899988988999898807bbb0bb00000000000000000000000000000000
1166661111666611116606117755555500111100001111009a44449a001111008999999889999998899999982222222200000000000000000000000000000000
444994444449944449944994499049949999999999999999e1111111000000000000000000000000000000000000000000000000000000000000000000000000
4994499449944394449944994409449944444444444444441aaaa444000000000000000000000000000000000000000000000000000000000000000000000000
944444499444333344994499449940994044440440444404aa444441000000000000000000000000000000000000000000000000000000000000000000000000
499449944994433444994499449940994440044444400444a444441a000000000000000000000000000000000000000000000000000000000000000000000000
444994444449943494499449944994094044440440444404444441aa000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666606666666666666666644441aa4000000000000000000000000000000000000000000000000000000000000000000000000
56565656565656565656565656565650565656565656565644414444000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000
44555544335555445d0000d55d0000d5e777777e0500005005000050050000500000000000000000000000000000000000000000000000000000000000000000
44455444335554445dd0ffd55dd00dd5111111110050050000500500008005000000000000000000000000000000000000000000000000000000000000000000
44455444434554445058550550555505111551110005500000055000000850000000000000000000000000000000000000000000000000000000000000000000
44455444555555555555855555555555115005110050050000500500005005000000000000000000000000000000000000000000000000000000000000000000
44555544345555445055550550555505150000510500005005000050050ff0500000000000000000000000000000000000000000000000000000000000000000
44555544334554445dd00dd55dd00dd5555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
45555554434554445d0000d55d0000d5454554544545545445455454454554540000000000000000000000000000000000000000000000000000000000000000
55555555535555555555555555555555444994444449944444499444444994440000000000000000000000000000000000000000000000000000000000000000
6dddddd6666dddd66dddddd6dddddddd60ddddd66dddddd66dddddd66dddddd6666666666dddddddddddddd66dddddd600000000000000000000000000000000
dd6666dd666dd0dddddddddddddddddddd0ddddd6dddddd660d000066dddddd6ccc77cacdd000000999119dddddddddd00000000000000000000000000000000
d66ee66d6660dd0ddddd6666ddddddddd6666ddd600000066dddddd660000006cc6ccc77d00000009991199ddddddddd00000000000000000000000000000000
d6eeee6d666d6666dddd6666ddadddadddd0dddd6dddddd66ddd00066dddddd6c686caccd00000009991199ddddddddd00000000000000000000000000000000
d6eeee6d0ddd6666dddd6666dadddadddddd0ddd6dddddd6600d00066dddddd63363a9add77003399911991ddddddddd00000000000000000000000000000000
d66ee66ddddd6666dddd0d0dddddddddddd6666d6dddddd6600dddd66dddddd633b33a33d77703399911991ddddddddd00000000000000000000000000000000
dd6666dddddddd0ddddd0dddddddddddddddd0dd600000066dddd0066000000633b33b33dd773399911991dddddddddd00000000000000000000000000000000
6dddddd66dddddd66ddd0dd6dddddddd6dddd0d6660000666600006666000066666666666dd33dddddddddd66dddddd600000000000000000000000000000000
4444444444444444d545454ddd5555dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999444a44aa44a54545454d994444d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49994444aa4a94a94444444499444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49944494a94a94a99999999994444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49444994a9a9999998989898d555555d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44449994d999999d8888888899944444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44499994dd6995dd4545484444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444ddd65dddd454545dd444444d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
1111111111111111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
1116111111611111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
1116111111611111cc777c7c7c777c777cccccc7ccc77777ccc7cccccc777cc77ccccc777c777c7c7c777ccccc777c777ccccccccccccccccccccccccccccccc
1116111111611111ccc7cc7c7c777c7c7ccccc7ccc777c777ccc7cccccc7cc7c7ccccc777c7c7c7c7c7cccccccc7ccc7cccccccccccccccccccccccccccccccc
1116111111611111ccc7cc7c7c7c7c777ccccc7ccc77ccc77ccc7cccccc7cc7c7ccccc7c7c777c77cc77ccccccc7ccc7cccccccccccccccccccccccccccccccc
1111111111111811ccc7cc7c7c7c7c7ccccccc7ccc77ccc77ccc7cccccc7cc7c7ccccc7c7c7c7c7c7c7cccccccc7ccc7cccccccccccccccccccccccccccccccc
8111116111111811cc77ccc77c7c7c7cccccccc7ccc77777ccc7ccccccc7cc77cccccc7c7c7c7c7c7c777ccccc777cc7cccccccccccccccccccccccccccccccc
8111116111111811cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
8111116111111811cc777c7c7c777cc77c7c7cc77c7c7ccccc777c7c7c777cccccc77c777c777cc77cc77ccccccccccccccccccccccccccccccccccccccccccc
8111111111111811ccc7cc7c7c7c7c7c7c7c7c7ccc7c7cccccc7cc7c7c7ccccccc7ccc7c7c7c7c7ccc7c7ccccccccccccccccccccccccccccccccccccccccccc
1811111111111811ccc7cc777c77cc7c7c7c7c7ccc777cccccc7cc777c77cccccc7ccc777c77cc7ccc7c7ccccccccccccccccccccccccccccccccccccccccccc
1811111111118111ccc7cc7c7c7c7c7c7c7c7c7c7c7c7cccccc7cc7c7c7ccccccc7ccc7c7c7c7c7c7c7c7ccccccccccccccccccccccccccccccccccccccccccc
1881111111118111ccc7cc7c7c7c7c77ccc77c777c7c7cccccc7cc7c7c777cccccc77c7c7c7c7c777c77cccccccccccccccccccccccccccccccccccccccccccc
1188111111881111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
1111888888811111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
1111111111111111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
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
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
6a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a66
a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666969666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666994576666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666699944556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
6a666a666a666a666a666a666a666a69444cfa666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a66
a666a666a666a666a666a666a666a69444fcf666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666a666
66666666666666666666666666666664ffffff666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666fffff6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
6666666666666666666666666666666999ff66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666664449996666666666666666666666666666666666666666666666444444444444444444444444444444446666666666666
66666666666666666666666666666666455499666666666666666666666666666666666666666666666499994444999944449999444499994446666666666666
66666666666666666666666666666666455449666666666666666666666666666666666666666666666499944444999444449994444499944446666666666666
6a666a666a666a666a666a666a666a644cc44a666a666a666a666a666a666a666a666a666a666a666a64994449449944494499444944994449466a666a666a66
a666a666a666a666a666a666a666a6644cc4a666a666a666a666a666a666a666a666a666a666a666a66494449944944499449444994494449946a666a666a666
66666666666666666666666666666666444466666666666666666666666666666666666666666666666444499944444999444449994444499946666666666666
66666666666666666666666666666666cc5566666666666666666666666666666666666666666666666444999944449999444499994444999946666666666666
66666666666666666666666666666666cc5556666666666666666666666666666666666666666666666444444444444444444444444444444446666666666666
66666666666666666664444444444444444444444444444444466666666666666666666666666666666444444444444444444444444444444446666666666666
66666666666666666664999944449999444499994444999944466666666666666666666666666666666499994444999944449999444499994446666666666666
66666666666666666664999444449994444499944444999444466666666666666666666666666666666499944444999444449994444499944446666666666666
6a666a666a666a666a64994449449944494499444944994449466a666a666a666a666a666a666a666a64994449449944494499444944994449466a666a666a66
a666a666a666a666a66494449944944499449444994494449946a666a666a666a666a666a666a666a66494449944944499449444994494449946a666a666a666
66666666666666666664444999444449994444499944444999466666666666666666666666666666666444499944444999444449994444499946666666666666
66666666666666666664449999444499994444999944449999466666666666666666666666666666666444999944449999444499994444999946666666666666
66666666666666666664444444444444444444444444444444466666666666666666666666666666666444444444444444444444444444444446666666666666
66666666666444444444444444444444444444444444444444444444444666666666666666666666666444444444444444444444444444444446666666666666
66666666666499994444999944449999444499994444999944449999444666666666666666666666666499994444999944449999444499994446666666666666
66666666666499944444999444449994444499944444999444449994444666666666666666666666666499944444999444449994444499944446666666666666
6a666a666a649944494499444944994449449944494499444944994449466a666a666a666a666a666a64994449449944494499444944994449466a666a666a66
a666a666a664944499449444994494449944944499449444994494449946a666a666a666a666a666a66494449944944499449444994494449946a666a666a666
66666666666444499944444999444449994444499944444999444449994666666666666666666666666444499944444999444449994444499946666666666666
66666666666444999944449999444499994444999944449999444499994666666666666666666666666444999944449999444499994444999946666666666666
66666666666444444444444444444444444444444444444444444444444666666666666666666666666444444444444444444444444444444446666666666666
44884499448844994488449944884499448844994488449944884499448844994488449944884499448844994488449944884499448844994488449944884499
99449944994499449944994499449944994499449944994499449944394499449944994499449944994499443944994439449944994499449944994499449944
44994488449944884499448844994488449944884499448844994483333944884499448844994488449944833339448333394488449944884499448844994483
99449944994499449944994499449944994499449944994499449944334499449944994499449944994499443344994433449944994499449944994499449944
44884499448844994488449944884499448844994488449944884499438844994488449944884499448844994388449943884499448844994488449944884499
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
65656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000100000000000000000001010101010101000000000000000000010101010101010100000000000000000000000000000000000000000000000001010101000000000000000000000000
0001000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000101000000010000000001010101010101010100000000000000010101010100000000000000000000000000000000000000000000000000000001010000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000545454545454545400545454545400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005454545454545454636363636363636350636363636350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005063636363636350636363636363636350636363636350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000050696a6363636350636363636363707050636363636350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000050696a6068636363636363636363636350636363636350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000050696a6363636363636370706363636363636363636350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005040404040404040637070706363636363636363636350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005000000000000000404040404040404040406363634050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000506b6b6b6b6b6b50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000506b6b6b6b6b6b50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000506b6b6b6b6b6b50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000506b6b6b6b6b6b50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000005050505050505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
