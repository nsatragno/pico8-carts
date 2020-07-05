pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- space kludge
-- by kat and nina

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
    x = 64,
    y = 80,
    dx = 0,
    dy = 0.2,
    facing = 1,
    inventory = {},
    show_inventory = false,
    equipped_item = nil,
    hp = 6,

    -- the number of frames you can hold the jump button to go higher
    jump_ticks = 0,

    draw = function(self)
      -- todo draw proper death animation
      if self.hp > 0 then
        spr(0, self.x, self.y, 1, 2)
      end
    end,  -- player:draw

    update = function(self)
      if self.hp <= 0 then
        return
      end

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
        if btn(➡️) then
          self.dx = 1
          self.facing = 1
        elseif btn(⬅️) then
          self.dx = -1
          self.facing = -1
        else
          self.dx = 0
        end

        if btnp(⬇️) then
          for actor in all(g_actors) do
            if actor.activatable and
               colliding_p_r({x = self.x + 4, y = self.y + 8}, actor) then
              actor:activate()
              return
            end
          end
        end
      end

      local points = {
        { x = self.x, y = self.y + 15 },
        { x = self.x + 7, y = self.y + 15 },
        { x = self.x, y = self.y + 7 },
        { x = self.x + 7, y = self.y + 7 },
        { x = self.x, y = self.y },
        { x = self.x + 7, y = self.y },
      }
      local on_floor = false
      for point in all(points) do
        -- vertical collisions
        if g_map:is_solid(point.x, point.y + sgn(self.dy)) then
          local tile_y = g_map:clamp(point.x, point.y + sgn(self.dy)).y
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
        if g_map:is_solid(point.x + sgn(self.dx), point.y) then
          self.dx = 0
        end

        -- pick up items
        local item = g_map:get_item(point.x, point.y)
        if item then
          add(self.inventory, item)
          self.equipped_item = item
        end
      end

      if not on_floor then
        -- downwards acceleration
        self.dy = min(self.dy + 0.1, 3)
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
      rectfill(18, 28, 120, 100, 0)
      rect(17, 27, 121, 101, 1)
      print("inventory", 40, 30, 7)
      for i = 1, #self.inventory do
        print(self.inventory[i].name, 40, 30 + i * 10, 7)
        if i == self.selected_index then
          spr(0, 22, 30 + i * 10)
        end
        if self.equipped_item == self.inventory[i] then
          print("e", 32, 30 + i * 10, 8)
        end
      end
      if #self.inventory <= 0 then
        print("[empty]", 40, 40, 7)
      end
      camera(g_camera.x, g_camera.y)
    end,  -- player:draw_inventory

    take_damage = function(self, damage)
      self.hp -= damage
      self.dy = -1
    end,  -- player:take_damage
  }
end  -- create_player

function create_dialog(messages)
  return {
    ticks = 0,
    messages = messages,

    update = function(self)
      self.ticks += 1
      self.current_message = sub(messages[1].text, 0, self.ticks / 10)
      if self.ticks / 10 > #messages[1].text + 12 then
        self.ticks = 0
        deli(messages, 1)
        if #messages <= 0 then
          return true
        end
      end
    end,  -- dialog:update

    draw = function(self)
      camera()
      rectfill(0, 0, 127, 15, 12)
      print(self.current_message, 18, 2, 7)
      spr(messages[1].sprite, 0, 0, 2, 2)
      camera(g_camera.x, g_camera.y)
    end,  -- dialog:draw
  }
end  -- create_dialog

function create_extinguisher()
  return {
    name = "fire extinguisher",
    use = function()
      local x_offset = 0
      if g_player.facing == 1 then
        x_offset = 8
      end
      add(g_actors, {
        x = g_player.x + x_offset,
        y = g_player.y + 8,
        dx = g_player.facing + rnd(2) - 1,
        dy = rnd(1),
        life = 30,
        color = flr(rnd(2)) + 6,

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

          for actor in all(g_actors) do
            if actor.name == "fire" then
              if colliding_p_r(self, actor) then
                actor:take_damage(1)
                return true
              end
            end
          end
        end,  -- extinguisher_particle:update

        draw = function(self)
          pset(self.x, self.y, self.color)
        end,  -- extinguisher_particle:draw
      })
    end,  -- extinguisher:use
  }
end  -- create_extinguisher

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

function create_switch(x, y)
  return {
    x = x,
    y = y,
    on = false,
    activatable = true,

    update = function(self)
    end,  -- switch:update

    draw = function(self)
      if self.on then
        pal({[8] = 11})
      end
      spr(3, self.x, self.y)
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
      clip(x - flr(g_camera.x), y - flr(g_camera.y), 8, 8 * size)
      for i = 0, (size - 1) do
        spr(2, x, y + i * 8 - self.pixels_up)
      end
      clip()
    end,  -- door:draw

    collides_with = function(self, x, y)
      for i = 0, (size - 1) do
        if colliding_p_r({x = x, y = y}, {x = self.x, y = self.y + i * 8}) then
          return true
        end
      end
    end,  -- door:collides_with_player

    toggle = function(self, on)
      if on then
        self.direction = -1
      else
        self.direction = 1
      end
    end,  -- door:toggle
  }
end  -- create_door

function create_fire(x, y)
  local fire = create_enemy(x, y, "fire", 12)

  fire.draw = function(self)
    local sprite
    if self.hp > 8 then
      sprite = 108
    elseif self.hp > 4 then
      sprite = 109
    else
      sprite = 110
    end
    if flr(time() * 10) % 2 == 0 then
      sprite += 16
    end
    spr(sprite, self.x, self.y)
  end  -- fire:draw
  return fire
end  -- create_fire

function _init()
  g_player = create_player()
  g_actors = { g_player }

  g_map = {
    draw = function(self)
      map(0, 0, 0, 0, 128, 64)
    end,  -- map:draw

    get_sprite = function(self, x, y)
      return mget(x \ 8, y \ 8)
    end,  -- map:get_sprite

    is_solid = function(self, x, y)
      if fget(self:get_sprite(x, y), 0) then
        return true
      end
      for actor in all(g_actors) do
        if actor.is_solid and actor:collides_with(x, y) then
          return true
        end
      end
    end,  -- map:is_solid

    clamp = function(self, x, y)
      return { x = (x \ 8) * 8, y = (y \ 8) * 8 }
    end,  -- map:coordinates_for

    get_item = function(self, x, y)
      local sprite = self:get_sprite(x, y)
      if not fget(sprite, 1) then
        return nil
      end
      mset(x \ 8, y \ 8, 0)
      if sprite == 127 then
        -- fire extinguisher
        return create_extinguisher()
      else
        stop("unknown object with sprite "..sprite)
      end
    end,  -- map:get_item
  }

  g_camera = {
    x = 0,
    y = 0,

    update = function(self, player)
      if player.dx > 0 and player.x - self.x > 30 then
        -- the player is moving to the right
        if player.x - self.x - player.dx - 1 <= 30 then
          self.x = player.x - 30
        else
          self.x += player.dx + 1
        end
      elseif player.dx < 0 and player.x - self.x < 98 then
        -- the player is moving to the left
        if player.x - self.x - player.dx + 1 >= 98 then
          self.x = player.x - 98
        else
          self.x += player.dx - 1
        end
      end

      self.y = player.y - 64
    end,  -- camera:update
  }

  add(g_actors, create_dialog({
    {
      text = "hello world!\nwith two lines!",
      sprite = 32,
    },
    {
      text = "i love you kat!",
      sprite = 34,
    },
  }))

  local switches = {}
  local doors = {}
  for i = 0, 127 do
    for j = 0, 63 do
      local sprite = mget(i, j)
      local x = i * 8
      local y = j * 8
      if sprite == 108 then
        mset(i, j, 0)
        add(g_actors, create_fire(x, y))
      elseif sprite == 3 then
        mset(i, j, 0)
        local switch = create_switch(x, y)
        add(g_actors, switch)
        add(switches, switch)
      elseif sprite ==  2 then
        local index = j
        while mget(i, index) == 2 do
          mset(i, index, 0)
          index += 1
        end
        local door = create_door(x, y, index - j)
        add(g_actors, door)
        add(doors, door)
      end
    end
  end

  -- associate switches to doors
  for switch in all(switches) do
    switch.target = doors[1]
    for door in all(doors) do
      if abs(door.x - switch.x) +
         abs(door.y - switch.y) <
         abs(switch.target.x - switch.x) +
         abs(switch.target.y - switch.y) then
        switch.target = door
      end
    end
  end
end  -- _init()

function _update60()
  for actor in all(g_actors) do
    if actor:update() then
      del(g_actors, actor)
    end
  end
end  -- _update60

function _draw()
  cls()
  g_camera:update(g_player)
  camera(g_camera.x, g_camera.y)
  g_map:draw()
  for actor in all (g_actors) do
    actor:draw()
  end
  if g_player.show_inventory then
    g_player:draw_inventory()
  end
end  -- _draw
__gfx__
00909000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00994570445555440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99944550454554540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09444cf0455445540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9444fcf0455445540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04ffffff454554540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00fffff0445555440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0999ff00444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04449990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00455499000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00455449000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044cc440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044cc400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc5550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111110000000000000000000000000001100044444444444444444444444400000000000000000000000000000000000000000000000000000000
11161111116111110000000000000000000000000011510045555554455555544444444400000000000000000000000000000000000000000000000000000000
111611111161111100000000000000000000000001151110a4444449a44444494444444400000000000000000000000000000000000000000000000000000000
11161111116111110000eeee0ee000000000000001511b119447754a9447754a4444444400000000000000000000000000000000000000000000000000000000
1116111111611111000e000e0eee0000000000000911b110a4788859a47000594444444400000000000000000000000000000000000000000000000000000000
111111111111181100ee0000ee0ee00000000000009111409458a85a945b0b5a4444444400000000000000000000000000000000000000000000000000000000
811111611111181100e00000e000e0000000000000991440a4588859a450b0594444444400000000000000000000000000000000000000000000000000000000
811111611111181100e00000e000e00000000000099944409445554a9445554a4444444400000000000000000000000000000000000000000000000000000000
811111611111181100ee00000000e0000000000000000000a4455549a44444490000000000000000000000000000000000000000000000000000000000000000
8111111111111811000e00000000e00000000000000000009444444a9444444a0000000000000000000000000000000000000000000000000000000000000000
1811111111111811000e00000000e0000000000000000000a4444449a44444490000000000000000000000000000000000000000000000000000000000000000
18111111111181110000e000000ee00000000000000000009444444a9444444a0000000000000000000000000000000000000000000000000000000000000000
18811111111181110000ee00000e00000000000000000000a4444449a44444490000000000000000000000000000000000000000000000000000000000000000
118811111188111100000e0000ee000000000000000000009444444a9444444a0000000000000000000000000000000000000000000000000000000000000000
1111888888811111000000ee00e000000000000000000000a9a9a9a9a44444490000000000000000000000000000000000000000000000000000000000000000
11111111111111110000000eee00000000000000000000009a9a9a9a9444444a0000000000000000000000000000000000000000000000000000000000000000
84499448844994484994499449904994999999999999999905506664466605500000000099ddddd6000000000000000000000000000000000000000000000000
499449944994439444994499440944994444444444444444005565644656005500000000dddddddd000000000000000000000000000000000000000000000000
9448844994483333449944994499409940444404404444045005666446660005000000004ddddddd000000000000000000000000000000000000000000000000
499449944994433444994499449940994440044444400444555555544555555500000000dddddddd000000000000000000000000000000000000000000000000
8449944884499438944994499449940940444404404400046565656445656565000000004ddddddd000000000000000000000000000000000000000000000000
666666666666666666666666666666066666666666666666666666666666666600000000dddddddd000000000000000000000000000000000000000000000000
5656565656565656565656565656565056565656565656565656565656565656000000005ddddddd000000000000000000000000000000000000000000000000
55555555555555555555555555555555555555555555555555555555555555550000000055ddddd6000000000000000000000000000000000000000000000000
46660550055066645555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46560055005565645555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46665005500566645555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45555500550055545566666666666666666666550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46660550055066645666666666666666666666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46560055005565646666666666666666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46665005500566644646464646464646646464640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45555500550055544444444444444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dddddd6655dddd66dddddd66666666660ddddd66dddddd6600000066dddddd66dddddd600000000000000000000000000000000000000000000000000000000
dd6666dd555dd0dddddddddd66666666dd0ddddddddddddd6000ddd66dddddd660d0000600000000000000000000000000000000000000000000000000000000
d660066d5550dd0ddddd555566666666d5555ddddddddddd60ddd006600000066dddddd600000000000000000000000000000000000000000000000000000000
d600006d555d5555dddd555566a666a6ddd0dddddddddddd60d000066dddddd66ddd000600000000000000000000000000000000000000000000000000000000
d600006d0ddd5555dddd55556a666a66dddd0ddddddddddd6ddd00066dddddd6600d000600000000000000000000000000000000000000000000000000000000
d660066ddddd5555dddd0d0d66666666ddd5555ddddddddd6d0dd0066dddddd6600dddd600000000000000000000000000000000000000000000000000000000
dd6666dddddddd0ddddd0ddd66666666ddddd0dddddddddd6d0dd006600000066dddd00600000000000000000000000000000000000000000000000000000000
6dddddd66dddddd66ddd0dd6666666666dddd0d66dddddd66dddddd6600000066000000600000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999444a44aa44a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49994444aa4a94a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49944494a94a94a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49444994a9a999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44449994099999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44499994006995000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565600000000000000000000000000
__gff__
0001000000000000000000000000000000000000000000000000000000000000000000000001010100000000000000000000000000000101000000000000000001010101010101010100000000000000010100000000010000000000000000000000000000000000000000000000000001010000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656551525353535353545065656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656551636363636363635065656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656551636363636363632665656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565655051636363636363633665656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565654746404040404040406565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565655051525353535353546565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565656565650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
