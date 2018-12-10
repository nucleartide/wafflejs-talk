pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- https://itch.io/jam/retro-platformer-jam

--[[

  todo:

    - [ ] parallax scrolling
    - [ ] curried text functions
    - [ ] enemies, since you are passing in `btn`
    - [ ] mass-based physics
    - [ ] inertia, guy on twitter had this as a field

]]

--
-- game loop.
--

do
  local g

  function _init()
    g = game()
  end

  function _update60()
    g = game_update(g)
  end

  function _draw()
    game_draw(g)
  end
end

--
-- game entity.
--

-- game :: game
function game()
  return {
    airship = airship(),
    player  = player(),
  }
end

-- game_update :: game -> game
function game_update(g)
  g.airship = airship_update(g.airship)
  g.player  = player_update(btn, g.player)
  return g
end

-- game_draw :: game -> io ()
function game_draw(g)
  cls(13)
  airship_draw(g.airship)
  player_draw(g.player)

  local p_bounds = player_bounds(g.player)
  local a_bounds = airship_bounds(g.airship)

  rect(p_bounds.top_left.x, p_bounds.top_left.y, p_bounds.bottom_right.x, p_bounds.bottom_right.y, 7)
  -- rect(a_bounds.top_left.x, a_bounds.top_left.y, a_bounds.bottom_right.x, a_bounds.bottom_right.y, 7)

  print(collides(player_bounds(g.player), airship_bounds(g.airship)))
  vec2_print(p_bounds.top_left)
  vec2_print(p_bounds.bottom_right)
  vec2_print(a_bounds.top_left)
  vec2_print(a_bounds.bottom_right)
end

--
-- player entity.
--

-- player :: player
function player()
  return {
    pos       = vec2(),
    vel       = vec2(),
    acc       = vec2(0, .1),
    move_vel  = 1,
    move_lerp = 0.4,
    max_vel   = vec2(2, 2.5),
    min_vel   = vec2(-2, -2),
    w         = 3,
    h         = 4,
  }
end

-- player_update :: btn_state -> player -> player
function player_update(btn_state, p)
  local desired_vel =
    btn_state(0) and -p.move_vel or
    btn_state(1) and p.move_vel  or
    0

  -- update x-component of velocity
  p.vel.x = lerp(p.vel.x, desired_vel, p.move_lerp)

  -- update y-component of velocity
  vec2_add_to(p.acc, p.vel)

  -- clamp velocity
  vec2_clamp_between(p.vel, p.min_vel, p.max_vel)

  -- update position
  vec2_add_to(p.vel, p.pos)

  return p
end

-- player_bounds :: player -> bound
function player_bounds(p)
  return {
    top_left     = p.pos,
    bottom_right = vec2(p.pos.x + p.w, p.pos.y + p.h),
  }
end

-- player_draw :: player -> io ()
function player_draw(p)
  -- rectfill(p.pos.x, p.pos.y, p.pos.x+p.w-1, p.pos.y+p.h-1, 7)
end

--
-- vec2 util.
--

-- vec2 :: float -> float -> vec2
function vec2(x, y)
  return {
    x = x or 0,
    y = y or 0,
  }
end

-- vec2_print :: vec2 :: io ()
function vec2_print(v)
  print(v.x .. ', ' .. v.y)
end

-- vec2_add_to :: vec2 -> vec2 -> ?
function vec2_add_to(a, b)
  local ax, ay = a.x, a.y
  local bx, by = b.x, b.y
  b.x = ax + bx
  b.y = ay + by
end

-- vec2_mul_by :: vec2 -> float -> vec2
function vec2_mul_by(v, s)
  v.x *= s
  v.y *= s
  return v
end

-- vec2_clamp :: vec2 -> vec2 -> vec2 -> ?
function vec2_clamp_between(v, lower, upper)
  local lx, ly = lower.x, lower.y
  local vx, vy = v.x, v.y
  local ux, uy = upper.x, upper.y
  v.x = clamp_between(vx, lx, ux)
  v.y = clamp_between(vy, ly, uy)
end

--
-- clamp util.
--

-- clamp :: float -> float -> float -> float
function clamp_between(n, lower, upper)
  return min(max(lower, n), upper)
end

--
-- airship entity.
--

-- airship :: airship
function airship()
  return {
    pos     = vec2(),
    vel     = vec2(),
    acc     = vec2(0, .01),
    max_vel = vec2(2, .25),
    min_vel = vec2(-2, -2),
    sx      = 16,
    sy      = 0,
    sw      = 29,
    sh      = 20,

    colliders = {
      {
        -- ceiling
        top_left     = vec2_mul_by(vec2(1, 0), 5),
        bottom_right = vec2_mul_by(vec2(9, 2), 5),
      },
      {
        -- left wall
        top_left     = vec2_mul_by(vec2(0, 1), 5),
        bottom_right = vec2_mul_by(vec2(2, 7), 5),
      },
      {
        -- right wall
        top_left     = vec2_mul_by(vec2(8, 1), 5),
        bottom_right = vec2_mul_by(vec2(10, 7), 5),
      },
      {
        -- bottom wall
        top_left     = vec2_mul_by(vec2(1, 6), 5),
        bottom_right = vec2_mul_by(vec2(9, 8), 5),
      },
    },
  }
end

-- airship_to_world :: airship -> vec2
function airship_to_world(a)
end

-- airship_update :: airship -> airship
function airship_update(a)
  vec2_add_to(a.acc, a.vel)
  vec2_clamp_between(a.vel, a.min_vel, a.max_vel)
  vec2_add_to(a.vel, a.pos)
  return a
end

-- airship_draw :: airship -> io ()
function airship_draw(a)
  -- sspr(a.sx, a.sy, a.sw, a.sh, a.pos.x, a.pos.y, a.sw*2, a.sh*2)

  for i=1,#a.colliders do
    local wall = a.colliders[i]

    local v1 = vec2()
    local v2 = vec2()

    vec2_add_to(a.pos,         v1)
    vec2_add_to(wall.top_left, v1)

    vec2_add_to(a.pos,             v2)
    vec2_add_to(wall.bottom_right, v2)

    rect(
      v1.x,
      v1.y,
      v2.x,
      v2.y,
      7
    )
  end
end

--
-- lerp util.
--

-- lerp :: float -> float -> float -> float
function lerp(a, b, t)
  return (1-t)*a + t*b
end

--
-- aabb util.
--

-- determine whether 2 bounding boxes collide.
-- collides :: bound -> bound -> boolean
function collides(a, b)
  return not (false
    or a.bottom_right.x < b.top_left.x
    or a.top_left.x     > b.bottom_right.x
    or a.bottom_right.y < b.top_left.y
    or a.top_left.y     > b.bottom_right.y
  )
end

--
-- collide_floor util.
--

function collide_floor(entity)
end

--
-- test char.
--

function test_char()
  return {
    pos = vec2(), -- this should be at the center
    vel = vec2(),
    acc = vec2(),
    w   = 16,
    h   = 16,
  }
end

function test_char_bounds(t)
  return {
    top_left     = vec2(t.pos.x-t.w/2, t.pos.y-t.h/2),
    bottom_right = vec2(t.pos.x+t.w/2, t.pos.y+t.h/2),
  }
end
__gfx__
00000000eeeeeeee0000eeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeee000e000000000000000000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700eeeeeeee00e00000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000eeeeeeee0e00000eeeeeeeeeeeee0000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000eeeeeeeee000000eeeeeeeeeeeee00000000e00007000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700eeeeeeeee000000eeeeeeeeeeeee00000000e00077700000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeeee000000000000000000000000000e00007000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeeee000000000000000000000000000e00070700000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000e000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000e000000000000000000000eeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000e000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000e000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000e0000eeeeeee000eee0000000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000e0000eeeeeee000eee0000000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000e000000000000000000000ee0000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000e000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000e0000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000e000000000eeeeee00000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000e00000000eeeeee0000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000eeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010100000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000101010000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001010101010001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
