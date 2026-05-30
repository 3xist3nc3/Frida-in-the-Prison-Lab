pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
------------------------------------------------------------
-- tab 0: main
------------------------------------------------------------

-- dev start
dev_start=false
dev_room_id="1-3"
dev_spawn_tx=2
dev_spawn_ty=28


-- constants / settings
grav=0.45
max_fall=4
acc=0.25
fric_ground=0.50
fric_air=0.92
max_dx=2
jump_v=-4

jump_hold_max=6
jump_hold_boost=0.35
jump_cut=-1.2

tile=8

crate_tile=76
crate_broken_tile=92

spike_tile=126
safe_floor_tile=65

-- screen
scr_w=128
scr_h=128

-- ui
ui_h=16
view_h=scr_h-ui_h

-- lives
start_lives=3
lives=3

-- hp
start_hp=6
hp=6
max_hp=6

-- damage / invulnerability
hurt_cooldown=0
hurt_cooldown_len=20

-- debug (hold o+x to toggle)
debug_hitbox=false
debug_hold=0
debug_hold_frames=30

-- camera
cam_x=0
cam_y=0

-- transition
transition_active=false
transition_t=0
transition_len=30
transition_switch_t=18
transition_target_room_id=nil

-- arrival effect
arrival_fx_t=0
arrival_fx_len=16

-- death / game over states
app_state="play" -- "play","death_respawn","game_over","quit"
death_timer=0
death_respawn_len=90 -- 3 sec @ 30fps
game_over_sel=1 -- 1=restart, 2=quit

-- saved map state for full reset
saved_map_tiles={}

-- room data
rooms={
 {
  id="1-1",
  x=0,
  y=0,
  w=46,
  h=16,
  spawn_tx=2,
  spawn_ty=4
 },

 {
  id="1-2",
  x=48,
  y=0,
  w=16,
  h=16,
  spawn_tx=50,
  spawn_ty=12
 },

 {
  id="1-3",
  x=0,
  y=16,
  w=31,
  h=16,
  spawn_tx=2,
  spawn_ty=28
 }
}

current_room=rooms[1]

-- death zones
death_zones={
 {
  room_id="1-1",
  tx=19,
  ty=16,
  w=4,
  h=1
 }
}

-- door sprites (world 1)
door_w1_closed_spr=112
door_w1_open_spr=113

-- transition door sprites
transition_door_closed_spr=121
transition_door_open_spr=122

-- button sprites
button_off_spr=124
button_on_spr=125

-- doors
doors={
 {
  id="door_1",
  room_id="1-1",
  tx=43,
  ty=1,
  closed_spr=door_w1_closed_spr,
  open_spr=door_w1_open_spr,
  is_open=false,
  kind="normal"
 },

 {
  id="door_2",
  room_id="1-1",
  tx=28,
  ty=5,
  closed_spr=door_w1_closed_spr,
  open_spr=door_w1_open_spr,
  is_open=false,
  kind="normal"
 },

 {
  id="transition_door_1",
  room_id="1-1",
  tx=1,
  ty=13,
  closed_spr=transition_door_closed_spr,
  open_spr=transition_door_open_spr,
  is_open=false,
  kind="transition",
  target_room_id="1-2"
 },

 {
  id="transition_door_2",
  room_id="1-2",
  tx=63,
  ty=12,
  closed_spr=transition_door_closed_spr,
  open_spr=transition_door_open_spr,
  is_open=false,
  kind="transition",
  target_room_id="1-3"
 }
}

-- buttons
buttons={
 {
  id="button_1",
  room_id="1-1",
  tx=37,
  ty=1,
  off_spr=button_off_spr,
  on_spr=button_on_spr,
  is_on=false,
  action="open_door",
  target_door_id="door_1"
 },

 {
  id="button_2",
  room_id="1-1",
  tx=10,
  ty=9,
  off_spr=button_off_spr,
  on_spr=button_on_spr,
  is_on=false,
  action="open_door",
  target_door_id="door_2"
 },

 {
  id="button_3",
  room_id="1-1",
  tx=30,
  ty=5,
  off_spr=button_off_spr,
  on_spr=button_on_spr,
  is_on=false,
  action="replace_tiles",

  target_area_x=19,
  target_area_y=15,
  target_area_w=4,
  target_area_h=1,

  from_tile=spike_tile,
  to_tile=safe_floor_tile
 },

 {
  id="button_4",
  room_id="1-1",
  tx=6,
  ty=10,
  off_spr=button_off_spr,
  on_spr=button_on_spr,
  is_on=false,
  action="open_door",
  target_door_id="transition_door_1"
 },

 {
  id="button_5",
  room_id="1-2",
  tx=62,
  ty=2,
  off_spr=button_off_spr,
  on_spr=button_on_spr,
  is_on=false,
  action="raise_block",
  target_block_id="block_1_2_door",
  target_door_id="transition_door_2"
 }
}

-- moving blocks / mechanisms
moving_blocks={
 {
  id="block_1_2_door",
  room_id="1-2",
  tx=60,
  ty=11,
  w=3,
  h=3,
  target_ty=8,
  y=11*8,
  active=false,
  done=false,
  tiles={}
 }
}

function apply_dev_start()
 if not dev_start then return end

 local r=find_room_by_id(dev_room_id)
 if r then
  current_room=r
 end

 respawn_player()

 p.x=dev_spawn_tx*8
 p.y=dev_spawn_ty*8
 p.dx=0
 p.dy=0

 cam_x=current_room.x*8
 cam_y=current_room.y*8
end

function find_room_by_id(id)
 for r in all(rooms) do
  if r.id==id then
   return r
  end
 end
 return nil
end

function save_initial_map_state()
 saved_map_tiles={}

 for r in all(rooms) do
  for yy=0,r.h-1 do
   for xx=0,r.w-1 do
    local tx=r.x+xx
    local ty=r.y+yy
    add(saved_map_tiles,{
     x=tx,
     y=ty,
     t=mget(tx,ty)
    })
   end
  end
 end
end

function restore_initial_map_state()
 for cell in all(saved_map_tiles) do
  mset(cell.x,cell.y,cell.t)
 end
end

function reset_world_state()
 for d in all(doors) do
  d.is_open=false
 end

 for b in all(buttons) do
  b.is_on=false
 end

 for mb in all(moving_blocks) do
  mb.y=mb.ty*8
  mb.active=false
  mb.done=false
  mb.tiles={}
 end

 restore_initial_map_state()
end

function respawn_player()
 p.x=current_room.spawn_tx*8
 p.y=current_room.spawn_ty*8
 p.dx=0
 p.dy=0
 p.jump_hold=0
 p.coyote=0
 p.on_ground=false
 p.anim="idle"
 p.anim_t=0
 p.attack_type=""
 p.attack_t=0
 p.attack_lock=0
 p.has_sword=false

 hp=start_hp
 hurt_cooldown=0

 transition_active=false
 transition_t=0
 transition_target_room_id=nil

 arrival_fx_t=0

 clear_particles()

 cam_x=current_room.x*8
 cam_y=current_room.y*8
end

function enter_room(room_id)
 local r=find_room_by_id(room_id)
 if not r then return end

 current_room=r

 p.x=current_room.spawn_tx*8
 p.y=current_room.spawn_ty*8
 p.dx=0
 p.dy=0
 p.jump_hold=0
 p.coyote=0
 p.on_ground=false
 p.anim="idle"
 p.anim_t=0
 p.attack_type=""
 p.attack_t=0
 p.attack_lock=0

 cam_x=current_room.x*8
 cam_y=current_room.y*8

 arrival_fx_t=arrival_fx_len
end

function start_room_transition(room_id)
 if transition_active then return end
 transition_active=true
 transition_t=0
 transition_target_room_id=room_id
end

function update_transition()
 if not transition_active then return end

 transition_t += 1

 if transition_t == transition_switch_t then
  enter_room(transition_target_room_id)
 end

 if transition_t >= transition_len then
  transition_active=false
  transition_t=0
  transition_target_room_id=nil
 end
end

function update_arrival_fx()
 if arrival_fx_t > 0 then
  arrival_fx_t -= 1
 end
end

function update_hurt_cooldown()
 if hurt_cooldown > 0 then
  hurt_cooldown -= 1
 end
end

function draw_transition_overlay()
 if not transition_active then return end

 local t=transition_t

 -- blackout
 if t >= 16 then
  rectfill(0,0,127,127,0)
 end

 -- white flash right before room switch
 if t==transition_switch_t-1 then
  rectfill(0,0,127,127,7)
 end
end

function start_death_respawn()
 app_state="death_respawn"
 death_timer=death_respawn_len

 transition_active=false
 transition_t=0
 transition_target_room_id=nil
 clear_particles()
end

function update_death_respawn()
 if death_timer > 0 then
  death_timer -= 1
 end

 if death_timer <= 0 then
  init_enemies()
  respawn_player()
  app_state="play"
 end
end

function death_countdown_number()
 if death_timer <= 0 then return 0 end
 return flr((death_timer-1)/30)+1
end

function start_game_over()
 app_state="game_over"
 game_over_sel=1

 transition_active=false
 transition_t=0
 transition_target_room_id=nil
 clear_particles()
end

function update_game_over_menu()
 if btnp(2) or btnp(3) then
  if game_over_sel==1 then
   game_over_sel=2
  else
   game_over_sel=1
  end
 end

 if btnp(5) then
  if game_over_sel==1 then
   restart_game()
  else
   quit_game()
  end
 end
end

function restart_game()
 lives=start_lives
 current_room=rooms[1]
 reset_world_state()
 init_enemies()
 respawn_player()
 apply_dev_start()
 app_state="play"
end

function quit_game()
 app_state="quit"
end

function take_damage(dmg)
 if hurt_cooldown > 0 then return end
 if transition_active then return end
 if app_state~="play" then return end

 spawn_blood_particles(
  p.x+p.w/2,
  p.y+p.h/2,
  10
 )

 hp -= dmg
 hurt_cooldown = hurt_cooldown_len

 if hp <= 0 then
  lose_life()
 end
end

function lose_life()
 lives -= 1

 if lives < 0 then
  start_game_over()
 else
  start_death_respawn()
 end
end

function game_over()
 start_game_over()
end

function reset_player()
 respawn_player()
end

function _init()
 lives=start_lives
 hp=start_hp
 init_particles()
 init_enemies()
 save_initial_map_state()
 reset_world_state()
 respawn_player()
 apply_dev_start()
 app_state="play"
end

function _update()
 update_debug_toggle()

 if app_state=="play" then
  if transition_active then
   update_transition()
  else
   update_player()
   update_enemies()
   update_moving_blocks()
   update_room_transitions()
   update_arrival_fx()
   update_hurt_cooldown()
   update_hazards()
   update_particles()

   -- fall death: below current room
   local room_bottom_px=(current_room.y+current_room.h)*8
   if p.y > room_bottom_px+32 then
    lose_life()
   end
  end

 elseif app_state=="death_respawn" then
  update_death_respawn()

 elseif app_state=="game_over" then
  update_game_over_menu()

 elseif app_state=="quit" then
  -- intentionally idle
 end
end

function _draw()
 cls(0)

 if app_state=="play" then
  update_camera()

  draw_background()

  camera(cam_x, cam_y)
  map(
   current_room.x,
   current_room.y,
   current_room.x*8,
   current_room.y*8,
   current_room.w,
   current_room.h
  )
  draw_buttons()
  draw_doors()
  draw_moving_blocks()
  draw_enemies()
  draw_particles()
  draw_player()
  draw_arrival_fx()

  camera(0,0)
  draw_ui()
  draw_transition_overlay()

 elseif app_state=="death_respawn" then
  draw_death_respawn_screen()

 elseif app_state=="game_over" then
  draw_game_over_screen()

 elseif app_state=="quit" then
  draw_quit_screen()
 end
end

function update_debug_toggle()
 if btn(4) and btn(5) then
  debug_hold += 1
  if debug_hold == debug_hold_frames then
   debug_hitbox = not debug_hitbox
  end
 else
  debug_hold = 0
 end
end
-->8
------------------------------------------------------------
-- tab 1: player
------------------------------------------------------------

p={
 x=16,y=16,
 w=16,h=16,
 dx=0,dy=0,
 on_ground=false,
 face=1,

 -- variable jump
 jump_hold=0,

 -- idle frames
 spr_idle1=1,
 spr_idle2=3,
 spr_idlelook=5,

 idle_t=0,
 idle_frame=0,
 idle_special_t=0,
 look_t=0,

 -- coyote time
 coyote=0,

 -- hitbox
 hb_ox=4,
 hb_oy=0,
 hb_w=8,
 hb_h=16,

 -- animation
 anim="idle",
 anim_t=0,
 spr_walk1=3,
 spr_walk2=7,
 spr_walk3=9,

 -- jump/fall
 spr_jump_up=11,
 spr_fall=13,

 -- attack state
 has_sword=false,
 attack_type="",
 attack_t=0,
 attack_lock=0,

 -- kick frames
 spr_kick_start=33,
 spr_kick_end=35
}

function update_player()
 local left=btn(0)
 local right=btn(1)

 local jump_pressed=btnp(4)
 local jump_held=btn(4)
 local attack_pressed=btnp(5)

 if attack_pressed and not attack_active() then
  start_attack()
 end

 local can_move = (p.attack_lock <= 0)

 if can_move then
  if left then
   p.dx -= acc
   p.face=-1
  end

  if right then
   p.dx += acc
   p.face=1
  end
 end

 if p.dx > max_dx then p.dx=max_dx end
 if p.dx < -max_dx then p.dx=-max_dx end

 if (not left and not right) or not can_move then
  local f = p.on_ground and fric_ground or fric_air
  p.dx *= f
  if abs(p.dx) < 0.10 then p.dx=0 end
 end

 if p.on_ground then
  p.coyote=4
 else
  if p.coyote > 0 then p.coyote -= 1 end
 end

 if jump_pressed and (p.on_ground or p.coyote > 0) then
--  sfx(04)
  p.dy=jump_v
  p.on_ground=false
  p.coyote=0
  p.jump_hold=jump_hold_max
 end

 if p.jump_hold > 0 and jump_held and p.dy < 0 then
  p.dy -= jump_hold_boost
  p.jump_hold -= 1
 end

 if (not jump_held) and p.dy < jump_cut then
  p.dy=jump_cut
  p.jump_hold=0
 end

 p.dy += grav
 if p.dy > max_fall then p.dy=max_fall end

 move_x(p.dx)
 move_y(p.dy)

 update_attack()
 update_anim()
 update_idle_anim()
end

function update_anim()
 -- attack anim has highest priority
 if p.attack_type=="kick_ground" then
--  sfx(05)
  p.anim="kick_ground"
  return
 elseif p.attack_type=="kick_air" then
--  sfx(05)
  p.anim="kick_air"
  return
 elseif p.attack_type=="sword" then
  p.anim="sword"
  return
 end

 if not p.on_ground then
  if p.dy < 0 then
   p.anim="jump_up"
  else
   p.anim="fall"
  end
  return
 end

 p.anim_t += 1

 if abs(p.dx) > 0.15 then
  p.anim="walk"
 else
  p.anim="idle"
  p.anim_t=0
 end
end

function update_idle_anim()
 local no_input =
  not btn(0) and not btn(1) and
  not btn(2) and not btn(3) and
  not btn(4) and not btn(5)

 local still = abs(p.dx)<0.05 and abs(p.dy)<0.05 and p.on_ground

 if no_input and still then
  p.idle_special_t += 1

  if p.look_t > 0 then
   p.look_t -= 1
   return
  end

  if p.idle_special_t > 200 and rnd(1) < 0.08 then
   p.look_t=60
   p.idle_special_t=0
   return
  end

  p.idle_t += 1
  if p.idle_t % 20 == 0 then
   p.idle_frame = 1 - p.idle_frame
  end
 else
  p.idle_t=0
  p.idle_frame=0
  p.idle_special_t=0
  p.look_t=0
 end
end

function start_attack()
 if p.on_ground then
  if p.has_sword then
   p.attack_type="sword"
  else
   p.attack_type="kick_ground"
   spawn_kick_fx()
  end
  p.attack_t=0
  p.attack_lock=8
 else
  p.attack_type="kick_air"
  p.attack_t=0
  p.attack_lock=6
  spawn_kick_fx()
 end
end

function update_attack()
 if p.attack_type=="" then return end

 p.attack_t += 1

 if p.attack_lock > 0 then
  p.attack_lock -= 1
 end

 -- kick can hit world objects
 if p.attack_type=="kick_ground" or p.attack_type=="kick_air" then
  try_hit_attackables()
 end

 if p.attack_type=="kick_ground" then
  if p.attack_t >= 8 then
   p.attack_type=""
   p.attack_t=0
  end

 elseif p.attack_type=="kick_air" then
  if p.attack_t >= 6 then
   p.attack_type=""
   p.attack_t=0
  end

 elseif p.attack_type=="sword" then
  -- placeholder for later
  if p.attack_t >= 8 then
   p.attack_type=""
   p.attack_t=0
  end
 end
end

function attack_active()
 return p.attack_type ~= ""
end

function try_hit_attackables()
 local probe_y1=hb_y()+4
 local probe_y2=hb_y()+hb_h()-4

 for i=1,5 do
  local probe_x

  if p.face==1 then
   probe_x=p.x+p.w+i
  else
   probe_x=p.x-i
  end

  if hit_enemy_at(probe_x,probe_y1) then return true end
  if hit_enemy_at(probe_x,probe_y2) then return true end

  if activate_button_at(probe_x,probe_y1) then return true end
  if activate_button_at(probe_x,probe_y2) then return true end

  if break_crate_at(probe_x,probe_y1) then return true end
  if break_crate_at(probe_x,probe_y2) then return true end
 end

 return false
end

function draw_player()
 local flip_x = (p.face==-1)
 local s

 if p.anim=="walk" then
  local phase=flr((p.anim_t/6)%4)
  if phase==0 then
   s=p.spr_walk1
  elseif phase==1 then
   s=p.spr_walk2
  elseif phase==2 then
   s=p.spr_walk3
  else
   s=p.spr_walk2
  end

 elseif p.anim=="jump_up" then
  s=p.spr_jump_up

 elseif p.anim=="fall" then
  s=p.spr_fall

 elseif p.anim=="kick_ground" then
  if p.attack_t < 4 then
   s=p.spr_kick_start
  else
   s=p.spr_kick_end
  end

 elseif p.anim=="kick_air" then
  s=p.spr_kick_end

 elseif p.anim=="sword" then
  s=p.spr_idle1

 else
  if p.look_t > 0 then
   s=p.spr_idlelook
  else
   s=(p.idle_frame==1) and p.spr_idle2 or p.spr_idle1
  end
 end

 -- hurt blink / invulnerability flicker
 if hurt_cooldown > 0 then
  if flr(hurt_cooldown/2)%2==0 then
   return
  end
 end

 spr(s,p.x,p.y,2,2,flip_x,false)

 if debug_hitbox then
  rect(hb_x(),hb_y(),hb_x()+hb_w()-1,hb_y()+hb_h()-1,8)
 end
end

-->8
------------------------------------------------------------
-- tab 2: physics / collision
------------------------------------------------------------

function solid_at(px,py)
 if solid_door_at(px,py) then
  return true
 end

 if solid_moving_block_at(px,py) then
  return true
 end

 local tx=flr(px/tile)
 local ty=flr(py/tile)
 local t=mget(tx,ty)
 return fget(t,0)
end

function tile_at_px(px,py)
 local tx=flr(px/tile)
 local ty=flr(py/tile)
 return mget(tx,ty),tx,ty
end

function tile_is_spike(px,py)
 local t=tile_at_px(px,py)
 return t==spike_tile
end

function hit_spike()
 local x1=hb_x()
 local y1=hb_y()
 local x2=hb_x()+hb_w()-1
 local y2=hb_y()+hb_h()-1

 return tile_is_spike(x1,y1)
  or tile_is_spike(x2,y1)
  or tile_is_spike(x1,y2)
  or tile_is_spike(x2,y2)
end

function player_in_death_zone(z)
 if z.room_id~=current_room.id then return false end

 local zx1=z.tx*8
 local zy1=z.ty*8
 local zx2=zx1+z.w*8-1
 local zy2=zy1+z.h*8-1

 local px1=hb_x()
 local py1=hb_y()
 local px2=hb_x()+hb_w()-1
 local py2=hb_y()+hb_h()-1

 return rect_overlap(px1,py1,px2,py2,zx1,zy1,zx2,zy2)
end

function hit_death_zone()
 for z in all(death_zones) do
  if player_in_death_zone(z) then
   return true
  end
 end
 return false
end

function update_hazards()
 if hit_spike() then
--	sfx(02)
  take_damage(1)
 end

 if hit_death_zone() then
  lose_life()
 end
end

function point_in_closed_door(px,py,d)
 if d.is_open then return false end
 if d.room_id ~= current_room.id then return false end

 local dx=d.tx*8
 local dy=d.ty*8

 return px>=dx and px<=dx+7
  and py>=dy and py<=dy+15
end

function solid_door_at(px,py)
 for d in all(doors) do
  if point_in_closed_door(px,py,d) then
   return true
  end
 end
 return false
end

function solid_moving_block_at(px,py)
 for mb in all(moving_blocks) do
  if mb.room_id==current_room.id
  and (mb.active or mb.done) then
   local x1=mb.tx*8
   local y1=mb.y
   local x2=x1+mb.w*8-1
   local y2=y1+mb.h*8-1

   if px>=x1 and px<=x2
   and py>=y1 and py<=y2 then
    return true
   end
  end
 end

 return false
end

function rect_overlap(ax1,ay1,ax2,ay2,bx1,by1,bx2,by2)
 return ax1<=bx2 and ax2>=bx1
  and ay1<=by2 and ay2>=by1
end

function player_in_open_transition_door(d)
 if not d.is_open then return false end
 if d.kind~="transition" then return false end
 if d.room_id~=current_room.id then return false end

 local dx=d.tx*8
 local dy=d.ty*8

 local px1=dx+2
 local py1=dy+2
 local px2=dx+7
 local py2=dy+13

 local hx1=hb_x()
 local hy1=hb_y()
 local hx2=hb_x()+hb_w()-1
 local hy2=hb_y()+hb_h()-1

 return rect_overlap(hx1,hy1,hx2,hy2,px1,py1,px2,py2)
end

function update_room_transitions()
 for d in all(doors) do
  if player_in_open_transition_door(d) then
   start_room_transition(d.target_room_id)
   return
  end
 end
end

function break_crate_at(px,py)
 local t,tx,ty=tile_at_px(px,py)
 if t==crate_tile then
  mset(tx,ty,crate_broken_tile)
--		sfx(00)
  spawn_crate_particles(
   tx*8+4,
   ty*8+4,
   p.face,
   8
  )

  return true
 end
 return false
end

function point_in_button(px,py,b)
 if b.room_id ~= current_room.id then return false end

 local bx=b.tx*8
 local by=b.ty*8

 return px>=bx and px<=bx+7
  and py>=by and py<=by+7
end

function find_door_by_id(id)
 for d in all(doors) do
  if d.id==id then
   return d
  end
 end
 return nil
end

function replace_button_tiles(b)
 local x0=b.target_area_x
 local y0=b.target_area_y
 local w=b.target_area_w
 local h=b.target_area_h

 for yy=0,h-1 do
  for xx=0,w-1 do
   local tx=x0+xx
   local ty=y0+yy
   if mget(tx,ty)==b.from_tile then
    mset(tx,ty,b.to_tile)
   end
  end
 end
end

function activate_button_at(px,py)
 for b in all(buttons) do
  if point_in_button(px,py,b) then
   if not b.is_on then
    b.is_on=true

    if b.action=="open_door" then
--					sfx(01)
     local d=find_door_by_id(b.target_door_id)
     if d then
      d.is_open=true
     end

    elseif b.action=="replace_tiles" then
--    sfx(01)
--    sfx(03)
      replace_button_tiles(b)

    elseif b.action=="raise_block" then
--    sfx(01)
      start_moving_block(b.target_block_id)

      if b.target_door_id then
       local d=find_door_by_id(b.target_door_id)
       if d then
        d.is_open=true
       end
      end
    end
   end
   return true
  end
 end
 return false
end

function find_moving_block_by_id(id)
 for mb in all(moving_blocks) do
  if mb.id==id then
   return mb
  end
 end
 return nil
end

function start_moving_block(id)
 local mb=find_moving_block_by_id(id)
 if not mb then return end
 if mb.active or mb.done then return end

 mb.tiles={}

 for yy=0,mb.h-1 do
  for xx=0,mb.w-1 do
   local tx=mb.tx+xx
   local ty=mb.ty+yy
   local t=mget(tx,ty)

   add(mb.tiles,{
    x=xx,
    y=yy,
    t=t
   })

   mset(tx,ty,0)
  end
 end

 mb.y=mb.ty*8
 mb.active=true
end

function update_moving_blocks()
 for mb in all(moving_blocks) do
  if mb.active then
   mb.y-=0.5

   local target_y=mb.target_ty*8

   if mb.y<=target_y then
    mb.y=target_y
    mb.active=false
    mb.done=true
   end
  end
 end
end

function hb_x() return p.x + p.hb_ox end
function hb_y() return p.y + p.hb_oy end
function hb_w() return p.hb_w end
function hb_h() return p.hb_h end

------------------------------------------------------------
-- edge checks
------------------------------------------------------------

function solid_on_left(nx)
 local x=nx + p.hb_ox
 local y1=hb_y()
 local y2=hb_y()+flr(hb_h()/2)
 local y3=hb_y()+hb_h()-1
 return solid_at(x,y1)
  or solid_at(x,y2)
  or solid_at(x,y3)
end

function solid_on_right(nx)
 local x=nx + p.hb_ox + p.hb_w - 1
 local y1=hb_y()
 local y2=hb_y()+flr(hb_h()/2)
 local y3=hb_y()+hb_h()-1
 return solid_at(x,y1)
  or solid_at(x,y2)
  or solid_at(x,y3)
end

function solid_on_top(ny)
 local y=ny + p.hb_oy
 local x1=hb_x()
 local x2=hb_x()+hb_w()-1
 return solid_at(x1,y)
  or solid_at(x2,y)
end

function solid_on_bottom(ny)
 local y=ny + p.hb_oy + p.hb_h - 1
 local x1=hb_x()
 local x2=hb_x()+hb_w()-1
 return solid_at(x1,y)
  or solid_at(x2,y)
end

function ground_below()
 local y=hb_y()+hb_h()
 local x1=hb_x()
 local x2=hb_x()+hb_w()-1
 return solid_at(x1,y)
  or solid_at(x2,y)
end

------------------------------------------------------------
-- move + collide (x)
------------------------------------------------------------

function move_x(dx)
 if dx == 0 then return end

 local step=sgn(dx)
 local nx=p.x+dx

 if step > 0 then
  if not solid_on_right(nx) then
   p.x=nx
   return
  end

  while not solid_on_right(p.x+step) do
   p.x += step
  end
 else
  if not solid_on_left(nx) then
   p.x=nx
   return
  end

  while not solid_on_left(p.x+step) do
   p.x += step
  end
 end

 p.dx=0
end

------------------------------------------------------------
-- move + collide (y)
------------------------------------------------------------

function move_y(dy)
 p.on_ground=false

 if dy == 0 then
  if ground_below() then
   p.on_ground=true
  end
  return
 end

 local step=sgn(dy)
 local ny=p.y+dy

 if step > 0 then
  if not solid_on_bottom(ny) then
   p.y=ny
   return
  end

  while not solid_on_bottom(p.y+step) do
   p.y += step
  end

  p.on_ground=true
  p.dy=0

 else
  if not solid_on_top(ny) then
   p.y=ny
   return
  end

  while not solid_on_top(p.y+step) do
   p.y += step
  end

  p.dy=0
 end
end
-->8
------------------------------------------------------------
-- tab 3: camera
------------------------------------------------------------

-- deadzone in screen coords
dz_top=40
dz_bottom=80

function update_camera()
 local room_px_x = current_room.x * 8
 local room_px_y = current_room.y * 8
 local room_px_w = current_room.w * 8
 local room_px_h = current_room.h * 8

 -- x follow
 cam_x = p.x + p.w/2 - scr_w/2

 local min_cam_x = room_px_x
 local max_cam_x = room_px_x + room_px_w - scr_w

 if max_cam_x < min_cam_x then
  max_cam_x = min_cam_x
 end

 cam_x = mid(min_cam_x, cam_x, max_cam_x)

 -- y deadzone follow
 local py_on_screen = (p.y + p.h/2) - cam_y

 if py_on_screen < dz_top then
  cam_y -= (dz_top - py_on_screen)
 elseif py_on_screen > dz_bottom then
  cam_y += (py_on_screen - dz_bottom)
 end

 local min_cam_y = room_px_y
 local max_cam_y = room_px_y + room_px_h - view_h

 if max_cam_y < min_cam_y then
  max_cam_y = min_cam_y
 end

 cam_y = mid(min_cam_y, cam_y, max_cam_y)
end

-->8
------------------------------------------------------------
-- tab 4: utils / particles
------------------------------------------------------------

particles={}

function sgn(v)
 if v < 0 then return -1 end
 return 1
end

function init_particles()
 particles={}
end

function clear_particles()
 particles={}
end

function add_particle(x,y,dx,dy,life,col,grav_amt)
 add(particles,{
  x=x,
  y=y,
  dx=dx,
  dy=dy,
  life=life,
  col=col,
  grav=grav_amt
 })
end

function spawn_blood_particles(x,y,n)
 for i=1,n do
  local ang=rnd(1)
  local dx=(rnd(2)-1)*1.4
  local dy=-(rnd(1.5))+0.2

  local col=8
  if rnd(1)<0.35 then col=2 end

  add_particle(
   x+rnd(6)-3,
   y+rnd(6)-3,
   dx,
   dy,
   8+flr(rnd(6)),
   col,
   0.12
  )
 end
end

function spawn_crate_particles(x,y,dir,n)
 for i=1,n do
  local dx=dir*(1+rnd(1.8)) + (rnd(0.4)-0.2)
  local dy=-(0.4+rnd(1.2))

  local col=4
  if rnd(1)<0.35 then col=9 end
  if rnd(1)<0.15 then col=15 end

  add_particle(
   x+rnd(6)-3,
   y+rnd(6)-3,
   dx,
   dy,
   10+flr(rnd(6)),
   col,
   0.14
  )
 end
end

function spawn_kick_fx()
 local dir=p.face
 local ox=(dir==1) and p.w-1 or 0
 local x=p.x+ox
 local y=p.y+9

 for i=-3,3 do
  local col=12
  if rnd(1)<0.45 then col=1 end

  add_particle(
   x,
   y,
   dir*(0.7+rnd(0.5)),
   i*0.18,
   6+flr(rnd(3)),
   col,
   0
  )
 end
end

function update_particles()
 for pfx in all(particles) do
  pfx.x += pfx.dx
  pfx.y += pfx.dy
  pfx.dy += pfx.grav
  pfx.dx *= 0.95
  pfx.life -= 1

  if pfx.life <= 0 then
   del(particles,pfx)
  end
 end
end

function draw_particles()
 for pfx in all(particles) do
  pset(pfx.x,pfx.y,pfx.col)
 end
end

-->8
------------------------------------------------------------
-- tab 5: background + ui
------------------------------------------------------------


-- sparse pillar layout for world 1
bg_pillars={
 24, 72, 128, 184, 248, 312
}

function draw_background()
 cls(0)

 -- transition rooms have their own lab style,
 -- so no world parallax background here
 if current_room.id=="1-2" then
  return
 end

 bg_ox=-flr((cam_x-current_room.x*8)*0.35)
 bg_oy=-flr((cam_y-current_room.y*8)*0.15)

 draw_bg_pillars()
 draw_bg_abyss()
end

function draw_bg_pillars()
 local top_y=8+bg_oy
 local bottom_y=view_h-1

 for px in all(bg_pillars) do
  local x=px+bg_ox

  if x > -32 and x < 160 then
   rectfill(x,top_y,x+7,bottom_y,1)
   rectfill(x+2,top_y,x+5,bottom_y,0)

   pset(x+1,top_y,5)
   pset(x+6,top_y,5)

   rectfill(x-1,top_y,x+8,top_y+2,5)
   rectfill(x,top_y+3,x+7,top_y+4,1)
  end
 end
end

function draw_bg_abyss()
 local abyss_y=view_h-40+bg_oy

 rectfill(-32,abyss_y,160,view_h+32,0)

 rectfill(-32,abyss_y-10,160,abyss_y-7,1)
 rectfill(-32,abyss_y-6,160,abyss_y-5,5)
 rectfill(-32,abyss_y-4,160,abyss_y-4,1)
end


function draw_moving_blocks()
 for mb in all(moving_blocks) do
  if mb.room_id==current_room.id
  and (mb.active or mb.done) then
   for c in all(mb.tiles) do
    spr(
     c.t,
     mb.tx*8+c.x*8,
     mb.y+c.y*8
    )
   end
  end
 end
end


function draw_buttons()
 for b in all(buttons) do
  if b.room_id==current_room.id then
   draw_button(b)
  end
 end
end

function draw_button(b)
 local s = b.is_on and b.on_spr or b.off_spr
 local x = b.tx*8
 local y = b.ty*8
 spr(s,x,y)
end

function draw_doors()
 for d in all(doors) do
  if d.room_id==current_room.id then
   draw_door(d)
  end
 end
end

function draw_door(d)
 local s = d.is_open and d.open_spr or d.closed_spr
 local x = d.tx*8
 local y = d.ty*8

 -- top half
 spr(s,x,y,1,1,false,false)

 -- bottom half
 spr(s,x,y+8,1,1,false,true)
end

function draw_arrival_fx()
 if arrival_fx_t <= 0 then return end

 local t=arrival_fx_t
 local cx=flr(p.x + p.w/2)
 local top=p.y-2
 local bot=p.y+p.h+2

 -- bright core first, then fades
 if t > 10 then
  rectfill(cx-2,top,cx+2,bot,7)
 elseif t > 6 then
  rectfill(cx-1,top,cx+1,bot,12)
 end

 -- flickering vertical beams
 if t > 0 then
  if t % 2 == 0 then
   line(cx-6,top+1,cx-6,bot-1,12)
   line(cx+6,top+1,cx+6,bot-1,12)
  end

  if t % 3 ~= 0 then
   line(cx-3,top,cx-3,bot,7)
   line(cx+3,top,cx+3,bot,7)
  end

  if t > 8 then
   line(cx,top-2,cx,bot+2,7)
  elseif t > 3 then
   line(cx,top,cx,bot,12)
  end
 end

 -- small spark pixels around body
 if t > 4 then
  pset(cx-5,p.y+2,7)
  pset(cx+5,p.y+5,12)
  pset(cx-4,p.y+10,7)
  pset(cx+4,p.y+13,12)
 end
end

ui_y=128-ui_h

ui_bg_col=1
ui_border_col=0
ui_inner_border_col=5
ui_inner_border_2_col=6

function draw_ui_box()
 rectfill(0,ui_y,127,127,ui_bg_col)
 rect(0,ui_y-1,127,127,ui_border_col)
 rect(22,ui_y+1,125,125,ui_inner_border_col)
 rect(1,ui_y,126,126,ui_inner_border_2_col)
end

function draw_ui_lives()
 spr(16,5,ui_y+3)
 print(lives,16,ui_y+5,9)
end

function draw_empty_heart(x,y)
 pal(8,1)
 pal(9,5)
 pal(10,6)
 pal(11,13)
 pal(12,1)
 pal(14,5)
 pal(15,6)
 spr(32,x,y)
 pal()
end

function draw_ui_hp()
 local hp_x=26
 local hp_y=ui_y+3
 local hp_step=10

 -- draw empty/used heart slots first
 for i=1,max_hp do
  draw_empty_heart(hp_x+(i-1)*hp_step,hp_y)
 end

 -- draw current hp on top
 for i=1,hp do
  spr(32,hp_x+(i-1)*hp_step,hp_y)
 end
end

function draw_ui()
 draw_ui_box()
 draw_ui_lives()
 draw_ui_hp()
end

function draw_centered_text(txt,y,col)
 local x=64-#txt*2
 print(txt,x,y,col)
end

function draw_death_respawn_screen()
 cls(0)

 draw_centered_text("ouch, you died!",54,8)

 local n=death_countdown_number()
 local txt="respawning in "..n.."..."
 draw_centered_text(txt,112,7)
end

function draw_game_over_screen()
 cls(0)

 draw_centered_text("you died completely.",48,8)

 local x1=22
 local y1=96
 local w1=36
 local h1=11

 local x2=70
 local y2=96
 local w2=36
 local h2=11

 rect(x1,y1,x1+w1,y1+h1,game_over_sel==1 and 3 or 5)
 rect(x2,y2,x2+w2,y2+h2,game_over_sel==2 and 8 or 5)

 print("restart",x1+5,y1+3,7)
 print("quit",x2+11,y2+3,7)
end

function draw_quit_screen()
 cls(0)
 draw_centered_text("game stopped.",56,8)
 draw_centered_text("reset cart to play again",112,7)
end

-->8
------------------------------------
-- tab 6: items
---------------------------------
-->8
------------------------------------------------------------
-- tab 7: enemies
------------------------------------------------------------

enemies={}

enemy_spawns={
{"imp","1-2",58,12,1},
{"imp","1-2",60,2,-1}
}

function init_enemies()
 enemies={}

 for s in all(enemy_spawns) do
  if s[1]=="imp" then
   add_imp(s[2],s[3],s[4],s[5])
  end
 end
end

function add_imp(room_id,tx,ty,dir)
 add(enemies,{
  type="imp",
  room_id=room_id,

  x=tx*8,
  y=ty*8,
  w=16,
  h=16,

  hb_ox=3,
  hb_oy=0,
  hb_w=10,
  hb_h=16,

  dir=dir,
  spd=0.35,

  hp=2,
  damage=1,

  anim_t=0,
  hurt_t=0,
  dead=false,

  atk_t=0,
  atk_cd=30,
  atk_hit=false,

  spr_walk1=128,
  spr_walk2=130,
  spr_attack=132,
  spr_dead=134
 })
end


function update_enemies()
 for e in all(enemies) do
  if e.room_id==current_room.id
  and not e.dead then
   if e.type=="imp" then
    update_imp(e)
   end
  end
 end
end

function update_imp(e)
 e.anim_t += 1

 if e.hurt_t > 0 then
  e.hurt_t -= 1
 end

 if e.atk_cd > 0 then
  e.atk_cd -= 1
 end

 if e.atk_t > 0 then
  update_imp_attack(e)
  imp_touch_player(e)
  return
 end

 local alerted=imp_notice_player(e)

 if alerted and imp_can_attack_player(e) and e.atk_cd<=0 then
  start_imp_attack(e)
  imp_touch_player(e)
  return
 end

 if alerted then
  -- face player, but don't walk into walls or pits
  if not imp_should_turn(e) then
   e.x += e.dir*e.spd
  end
 else
  -- normal patrol behavior
  if imp_should_turn(e) then
   e.dir *= -1
  end

  e.x += e.dir*e.spd

  if imp_should_turn(e) then
   e.x -= e.dir*e.spd
   e.dir *= -1
  end
 end

 imp_touch_player(e)
end

function start_imp_attack(e)
 e.atk_t=1
 e.atk_hit=false
 e.atk_cd=75+flr(rnd(31))
end

function update_imp_attack(e)
 e.atk_t += 1

 -- damage once, around the middle of the swing
 if e.atk_t==7 and not e.atk_hit then
  if imp_can_attack_player(e) then
   take_damage(e.damage)
  end
  e.atk_hit=true
 end

 if e.atk_t>=16 then
  e.atk_t=0
  e.atk_hit=false
 end
end

function imp_can_attack_player(e)
 local ecx=e.x+8
 local ecy=e.y+8
 local pcx=p.x+p.w/2
 local pcy=p.y+p.h/2

 if abs(pcy-ecy)>16 then return false end

 if e.dir==1 then
  return pcx>=ecx and pcx<=ecx+18
 else
  return pcx<=ecx and pcx>=ecx-18
 end
end

function imp_notice_player(e)
 local ecx=e.x+8
 local ecy=e.y+8
 local pcx=p.x+p.w/2
 local pcy=p.y+p.h/2

 if abs(pcy-ecy) > 18 then return false end
 if abs(pcx-ecx) > 32 then return false end

 -- face player when close
 if pcx < ecx then
  e.dir=-1
 else
  e.dir=1
 end

 return true
end

function imp_should_turn(e)
 return imp_wall_ahead(e)
  or not imp_ground_ahead(e)
end

function imp_wall_ahead(e)
 local ax

 if e.dir==1 then
  ax=e.x+e.hb_ox+e.hb_w
 else
  ax=e.x+e.hb_ox-1
 end

 local y1=e.y+e.hb_oy+3
 local y2=e.y+e.hb_oy+e.hb_h-3

 return solid_at(ax,y1)
  or solid_at(ax,y2)
end

function imp_ground_ahead(e)
 local ax

 if e.dir==1 then
  ax=e.x+e.hb_ox+e.hb_w
 else
  ax=e.x+e.hb_ox-1
 end

 local ay=e.y+e.hb_oy+e.hb_h+1

 return solid_at(ax,ay)
end

function imp_touch_player(e)
 local ex1=e.x+e.hb_ox-1
 local ey1=e.y+e.hb_oy
 local ex2=e.x+e.hb_ox+e.hb_w
 local ey2=e.y+e.hb_oy+e.hb_h-1

 local px1=hb_x()
 local py1=hb_y()
 local px2=hb_x()+hb_w()-1
 local py2=hb_y()+hb_h()-1

 if rect_overlap(ex1,ey1,ex2,ey2,px1,py1,px2,py2) then
  take_damage(e.damage)
 end
end

function hit_enemy_at(px,py)
 for e in all(enemies) do
  if e.room_id==current_room.id
  and not e.dead then
   if point_in_enemy(px,py,e) then
    damage_enemy(e,1)
    return true
   end
  end
 end

 return false
end

function point_in_enemy(px,py,e)
 local ex1=e.x+e.hb_ox
 local ey1=e.y+e.hb_oy
 local ex2=e.x+e.hb_ox+e.hb_w-1
 local ey2=e.y+e.hb_oy+e.hb_h-1

 return px>=ex1 and px<=ex2
  and py>=ey1 and py<=ey2
end

function damage_enemy(e,dmg)
 if e.hurt_t > 0 then
  return
 end

 e.hp -= dmg
 e.hurt_t=10
 e.atk_t=0

 spawn_blood_particles(e.x+8,e.y+8,6)

 if e.hp <= 0 then
  kill_enemy(e)
 end
end

function kill_enemy(e)
 e.dead=true
 e.atk_t=0

 spawn_blood_particles(
  e.x+8,
  e.y+8,
  14
 )
end

function draw_enemies()
 for e in all(enemies) do
  if e.room_id==current_room.id then
   if e.type=="imp" then
    draw_imp(e)
   end
  end
 end
end

function draw_imp(e)
 if e.dead then
  spr(e.spr_dead,e.x,e.y+8,2,1,e.dir==-1,false)
  return
 end

 if e.hurt_t > 0 then
  if flr(e.hurt_t/2)%2==0 then
   return
  end
 end

 local s

 if e.atk_t > 0 then
  s=e.spr_attack
 else
  local phase=flr((e.anim_t/12)%2)

  if phase==0 then
   s=e.spr_walk1
  else
   s=e.spr_walk2
  end
 end

 -- sprites face right, so flip when walking/attacking left
 local flip_x=(e.dir==-1)

 spr(s,e.x,e.y,2,2,flip_x,false)

 if debug_hitbox then
  rect(
   e.x+e.hb_ox,
   e.y+e.hb_oy,
   e.x+e.hb_ox+e.hb_w-1,
   e.y+e.hb_oy+e.hb_h-1,
   8
  )
 end
end

__gfx__
0000000000009aa999a0000000009aa999a0000000009aa999a0a00000009aa999a000000000a0000000000000009aa999a0000000909aa999a0a000000bb000
0000000000099afffffa000000099afffffa000000099afffffa000000099afffffa00000a000aa999a0000000099afffffa00000a099afffffa0000000bb000
007007000099a97cf7c900000099a97cf7c900000099a9c7fc7900000099a97cf7c900000099a9fffff900000099a97cf7c900000099a97cf7c90a00000bb000
000770000009a9fffff900000009a9fffff900000909a9fffff990000909a9fffff900000909a97cf7c900000909a9fffff900000009a9fffff99000000bb000
00077000009aa9ffeef90000009aa9fffef90000000aa9feeff900000a9aa9fffee90000a09aa9fffff90000a09aa9ffeef90000909aa9ffeff9000000333300
00700700009af99fffdf9000009a999fffd90000009f99ffffdf9000a09af99fffd99000009af9fffee99000009a996feed0a000099a996fffd000f000033000
000000000009fd66d6df0900009afd9666df9000000fd66d66df090000909d66d66d9000090f9d6ffffd9000009afd6666df0000009afd66d6df002000033000
000000000090f5dddddf00000009fd66d6df0900009f5ddddd5f00000909f5ddddddf90090f09566d66d00f0090f0d66d6df0000000f0ddddddf0f0000000000
0a999a000000f0d6600f00000090f5dddddf0000000f0666600f000000000f666600f00000f905dddddd0200a0f005dddddf000000f005d6660ff00000000000
afffffa000002022e00200000000f022e00f000000f0022e2000f000000000f22e00f000002000222e0ff00000f00022e200f000000f0022e20000000003b000
97cf7c9a000ff566660f00000000256666020000f2005666650002f000000562f60002f000f0056666000000002000666662d20000002f666622d0000003b000
9fffff9000000d6d6d0f00000000fd6d6d0f00000000d6dd6d00000000000566ff00000000f00d66d6d000000f000022262220f000000052dd2220700003b000
9ffeef9000000220220000000000f220220f00000000220022000000000002222220000000000222222d000000000022d052000000000002220226000003b000
99fffdf9000002d02d000000000002d02d00000000002d002d000000000022d0022d000000052222022207000000005200067000000000002200500000333000
d96d6df00000022022000000000002202200000000002200220000000000520000220000000622d0002266000000000600000000000000005670000000033000
5dddddf0000005675670000000000567567000000000670056700000000066700056700000070000000560000000000070000000000000000000000000033000
0000000000009aa999a0000000009aa999a000000000000000000000000000000000000000009aa999a0000000009aa999a0000000009aa999a0000000000000
008e0e0000099afffffa00000a099afffffa0a000000000000000000000000000000000000099afffffa000000099afffffa00000a099afffffa000000000000
0888e8e00099a97cf7c9a0000099a97cf7c9a000000000000000000000000000000000000099a97cf7c900000099a97cf7c900000099a97cf7c9000000000000
88e8888e0909a9fffff900000009a9fffff900000000a9a999a0000000a0a9a999a000000a09a9fffff9000009a9a9fff119000009a9a9fffff90000000b0000
8888e88ea09aa9ffeef90000009aa9ffeef900000a09a9fffff900000009a9fffff90000009aa9ffeff900000a9aa9ffeef100000a9aa9ffeef9000000b3b000
088e88e0009a996fefdfa000009a996feedfa0f0009a997cf7c90000009a997cf7c90000009af99fffdf9000a09a996110001000a09a996fefd99000000b0000
00888e00009ad66d66df0000a09ad66666d0f020009a99fffff99000a09a99fffff990000009fd66d6df0900009a99f6d1000000009a99f6d6d0000000000000
0008e000090fdddddddf0000090fd66d66d00f0009a999fffefa900009a999ffeefa90000090f5dddddf00000909adfddd1000b00909a9f6d6d00f0000000000
00000000a0f000d66002f00000f0dddddd500000a099f96fffda0000a099f96feeda00000a00f0d6600f00000a0905f66f000b0000090dfddddf200000000000
00e8080000f0022e2000000000f0052e20000007090f9566d6d0f000090f9566d6d0000000032022e00200000090a2fe2000b0000090a0f22e00000000000000
088e8e80002005666d2d0000002005666222d226a0f095ddddd2f00000f095ddddd000b0000ff566660f000000a0566f030b00000a00056f6600000000000000
8e8888e800f00d6d62220000000f0d6d6220022502090222e2f0000002090222e2f2ff3b00333d6d6d0f00000000d66620300000000005662003000000b0b000
88e888e8000002200022070000000220000000000ff02d66660000000f002d66660000b0000b022022000000000022222f030000000002223f33bbbb00030000
08888e8000000d200002600000000222500000000f0022d2d22d000000f022d2d22d0000000b02d02d00000000002d003d000000000022d22d03000000b0b000
0088e800000000220005000000000d226000000000000220002200000000022000220000000b0220220000000000520022000000000022002200000000000000
000e80000000076500000000000000007000000000000567005670000000056700567000000b0567567000000000567056700000000056705670000000000000
005555555555555555555500001661111116611111166100009444444449944444444900001555555556655555555100095555900000000005555d1005555d10
05555555555555555555555001666166666666666616661009642222224884222222469001666566666666666656661094444449000000000055d1000055d100
55544444445444d444544555166d5d5dd55dd55dd5d5d66196200000000220000000026916667677777777777767666154d44d4500000000000d1000000d1000
5554d444445d44444454445566d155555551155555551d6644062222000000002222604456616777776666777776166554444445000000000005d00000051000
5555555555555555555555556655555555555555555555664202d44200000000244d202456767777776556777777676554444445000000000058810000588100
55444544344445444344445566555555555555555555556642024942000000002494202456777777776666777777776554d44d4500000000058a98d00d8a9810
5544454343444544444d445566555555555555555555556642024442000000002444202456777771116116111777776594444449000000000199a9d001a999d0
55444544444445444444445566d55d555551155555d55d664202222600000000622220245667777177622677177776650955559000000000000a90000009a000
55555555555555555535555511666166661dd1666616661142000000200220020000002411667771776886771777661100000000000000000000000000000000
55444444445444444354445566d55dd55d6556d55dd55d66420000000d0660d00000002456677771776886771777766500000000000000000000000000000000
55444434445444d44354445516555555556556555555556142200000009a89000000022416777561288888821657776100000000000000000000000070700000
554344444d54444434544455165555555515515555555561422000000098a9000000022416777561288888821657776100000000000000000000000007000000
553555555555555555555555165555555565565555555561420000000d0660d000000024167777717768867717777761040000050000000000000000f0000000
5544454444d43544444d445566d55dd55d6556d55dd55d6642000000200220020000002456677771776886771777766554000d45000000000000000007070777
5544d544444445344444445511666166661dd166661666114202222600000000622220241166777177622677177766119440444900000000000000000f0f0707
55444544444445445444445566d55d555551155555d55d6642024442000000002444202456677771116116111777766509555590000000000000000000f0ffff
5555555555555555555555556655555555555555555555664202494200000000249420245677777777666677777777650b00000b0000b00b0000000000000090
5544433434444544445d44556655555555555555555555664202d44200000000244d202456767777776556777777676500b0b0030b00003000008000000a0000
5544453444d4433444d4445566d155555551155555551d66440622220000000022226044566167777766667777761665b0b03030b00b03000000000009009000
5554454444d4354444544555166d5d5dd55dd55dd5d5d66196200000000220000000026916667677777777777767666130300330300300300090080008080800
055555d55d5555555555d5500166616666666666661666100964222222488422222246900166656666666666665666100330003b030030030800800000809080
0055d55555555555555555000016611111166111111661000094444444499444444449000015555555566555555551000300033003000330008988a009888980
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333000003330008a88898888a8a898
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000434000004340008898a8988a888888
0005500000000000111111110006600000000000000000000044440000000000000000000555555055000055155555510000000000000000000000008888a88a
0055550005000050111111110061160001000010000000000420024002000020000000005d6666d55d6006d555555555095555900a5555a0000000008a898888
054554505400004511d11d1100655600060000600000000042d00d242d0000d20000000056288265628008265555555505622650056666500080008088888988
54455445540000451111111166655666660000660000000040000004400000040000000056211265621001265555555505688650053bb3508080807058988885
6445544559000095111111116d51d5d6d1100ddd0000000040699604690000960000000056d11d656d1001d65555555505688650053bb3508070707058855a85
549559455400004511d11d1166555566665005660000000040000004400000040000000056211265621001265555555505622650056666508070707015555551
5445544554000045111111116d5115d6d11001160000000042d00d244d0000d4000000005d2112d56d1001d655555555095555900a5555a07878787801555510
55555555550000551111111166666666660000660000000044444444440000440000000055555555555005551555555100000000000000007777777700155100
06662242248866600000000000000000666624420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
087724a44a227770066622422488666078867444a000000000000766806670000000000000000000000000000000000000000000000000000000000000000000
0800288444220070080024a44a227770707772488000000000007700708078000055500000550000005000000000000000500000000000000000000000000000
07002417174200700800288444420070724222444000000000080082448408000550550000555500005555000000000000555500005000000050000000500000
0002411111120000070241171712007002244441700000000000088a44a400000055550000555500000000000000500000555500005555000055550000555500
00254417174520000005441717420000002224100000000000082817171880000005500000000000005000000000555500000000005555000055550000555500
00242882822420000244288282240000000084417000477805245824555845000000000000000000005555000000555500000000000000000000000000000000
00240885510420000240088551540000000088244404440088882686688658800000000000000000005555000000000000000000000000000000000000000000
06400856510046000440085651440000000024824444400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00400856110040006440085611400000000084880060000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00440865660440000400086566644000000286680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00740655160470000740065016047000000566560000000000500000005000000000000000500000000000000050000000000000005000000500000000050000
00700660660080000700160016000800000560566000000000555500005555000005000000555500000000000055550000050000005555000555500000055550
00000540540000000000260054080000000560056000000000555500005555000005555000555500000050000055550000055550005555000555500000055550
00000140140000000000440004800000000240005000000000000000000000000005555000000000000055550000000000055550000000000000000000000000
00000244288000000000044002000000000044002880000000000000000000000000000000000000000055550000000000000000000000000000000000000000
00009994442000000000999444200000080090040420000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00049999444200000004999944420000000409804442008000aa0a08000000000000000000000000000000000000000000000000000000000000000000000000
0094444994942000009444499494200000900400908480000a999090000000000000000000000000050000000000000000000000000000000000000000500000
099999949949420009999994994942008009900008498800a9888900005000000000000000000000055550000050000000000000000500000000000000555500
09aa8849aa88420009aa8849aa884200008a08408a884200a9889080005555000000000000000000055550000055550000000000000555500050000000555500
09a78849a7884200097a88497a884200000088097a8848000aa9000a005555000000500000000000000000000055550000005000000555500055550000000000
098884498884420009888449888442000088044988844200000a0a00000000000000555500000000000000000000000000005555000000000055550000000000
09444449444942000944444944494200094040490040428000000000000000000000555500000000000000000000000000005555000000000000000000000000
09949949494442000994994949944200000009094008420000000000000000000000000000000000000000000000000000000000000000000000000000000000
099949949994420009999999999942000000909909080208000a0a00000000000000000000000000000000000000000000000000000000000000000000000000
0999499999442200009991121944220008080112194082000a99a890000000000000000000000000000000000000000000000000000000000000000000000000
009911219442020000999222244200200000822228820020a9988900005000000050000000500000000000000000500000500000005000000500000000000000
009911119422020000999111142200028009901118220002a988890a005555000055550000555500005000000000555500555500005555000555500000000000
0090444944020000009094994420200000908489448020000aa09800005555000055550000555500005555000000555500555500005555000555500000500000
00900009040200000090094442000200009000484200020000009900000000000000000000000000005555000000000000000000000000000000000000555500
009000000400000000090000040000000009000004080000000000a0000000000000000000000000000000000000000000000000000000000000000000555500
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888eeeeee888eeeeee888eeeeee888eeeeee888777777888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88ee88eee88ee888ee88ee888ee88ee8e8ee88778887788888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee8eeee8eee8eeeee8ee8eeeee8ee8eee8e8ee87778777788888e88888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8eeee8eee8eee888ee8eeee88ee8eee888ee8777888778888eee8888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee8eeee8eee8eee8eeee8eeeee8ee8eeeee8ee87777787788888e88888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee8eee888ee8eee888ee8eee888ee8eeeee8ee877788877888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee877777777888888888888888888888888888888888888888888888888888888888888888888888888
161616661111161611111cc11c111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1616116111111616177711c11c111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1616116111111666111111c11ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1616116111111616177711c11c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
116616661666161611111ccc1ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161616661111161611111cc11ccc1ccc111116161666111116161111111111111111111111111111111111111111111111111111111111111111111111111111
1616116111111616177711c1111c1c1c111116161161111116161111111111111111111111111111111111111111111111111111111111111111111111111111
1616116111111666111111c11ccc1ccc177716161161111116661111111111111111111111111111111111111111111111111111111111111111111111111111
1616116111111116177711c11c111c1c111116161161111116161111111111111111111111111111111111111111111111111111111111111111111111111111
116616661666166611111ccc1ccc1ccc111111661666166616161111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16161666111116661166111111661166161111111cc111111111111111111111111111111ddd1ddd1d1d11dd1ddd1d1d1dd11dd111dd1ddd1ddd1ddd11dd1ddd
161611611111161616111111161116161611177711c111111111111111111111111111111d1d1d1d1d1d1d111d1d1d1d1d1d1d1d1d111d111d1d1d1d1d111d11
161611611111166116111111161116161611111111c111111111111111111ddd1ddd11111dd11ddd1dd11d111dd11d1d1d1d1d1d1ddd1dd11ddd1dd11d111dd1
161611611111161616161111161116161611177711c111111111111111111111111111111d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d111d1d111d1d1d1d1d1d1d11
11661666166616661666166611661661166611111ccc11111111111111111111111111111ddd1d1d1d1d1ddd1d1d11dd1d1d1d1d1dd11d111d1d1d1d1ddd1ddd
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161616661111166611661666166116661666111111661166161111111ccc11111111111111111ddd1ddd1ddd1ddd1ddd11111111111111111111111111111111
161611611111161616161616161616111616111116111616161117771c1c11111111111111111d1d1d1d1ddd1ddd1d1111111111111111111111111111111111
161611611111166116161661161616611661111116111616161111111c1c11111ddd1ddd11111dd11ddd1d1d1d1d1dd111111111111111111111111111111111
161611611111161616161616161616111616111116111616161117771c1c11111111111111111d1d1d1d1d1d1d1d1d1111111111111111111111111111111111
116616661666166616611616166616661616166611661661166611111ccc11111111111111111d1d1d1d1d1d1d1d1ddd11111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161616661111166616611661166616661111166611661666166116661666111111661166161111111ccc11111111111111111ddd1dd11dd11ddd1ddd11111dd1
161611611111116116161616161116161111161616161616161616111616111116111616161117771c11111111111111111111d11d1d1d1d1d1d1d1111111d1d
161611611111116116161616166116611111166116161661161616611661111116111616161111111ccc11111ddd1ddd111111d11d1d1d1d1dd11dd111111d1d
16161161111111611616161616111616111116161616161616161611161611111611161616111777111c111111111111111111d11d1d1d1d1d1d1d1111111d1d
116616661666166616161616166616161666166616611616166616661616166611661661166611111ccc11111111111111111ddd1d1d1ddd1d1d1ddd11111ddd
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16161666111116661661166116661666111116661166166616611666166611111666111111661166161111111ccc11111111111111111ddd1dd11dd11ddd1ddd
1616116111111161161616161611161611111616161616161616161116161111111611111611161616111777111c111111111111111111d11d1d1d1d1d1d1d11
1616116111111161161616161661166111111661161616611616166116611111166611111611161616111111111c11111ddd1ddd111111d11d1d1d1d1dd11dd1
1616116111111161161616161611161611111616161616161616161116161111161111111611161616111777111c111111111111111111d11d1d1d1d1d1d1d11
1166166616661666161616161666161616661666166116161666166616161666166616661166166116661111111c11111111111111111ddd1d1d1ddd1d1d1ddd
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116611666166616161111161616661111166611661616117111711111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616161616161111161611611111161616161616171111171111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116161661166616161111161611611111166116161161171111171111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616161616661111161611611111161616161616171111171111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661616161616661666116616661666166616611616117111711111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111ddd1ddd1d1d11dd1ddd1d1d1dd11dd111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111d1d1d1d1d1d1d111d1d1d1d1d1d1d1d11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ddd1ddd11111dd11ddd1dd11d111dd11d1d1d1d1d1d11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111ddd1d1d1d1d1ddd1d1d11dd1d1d1d1d11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111bbb1bbb11bb1bbb1bbb1bbb1b111b1111711ccc111111111616166611111616111111111cc11ccc1ccc111111111cc11ccc1ccc11111111161616661111
11111b1b1b111b1111b11b1111b11b111b1117111c1c1111111116161161111116161111111111c1111c111c1111111111c1111c111c11111111161611611111
11111bb11bb11b1111b11bb111b11b111b1117111c1c1111111116161161111116661111111111c11ccc111c1111111111c11ccc111c11111111161611611111
11111b1b1b111b1111b11b1111b11b111b1117111c1c1171111116161161111111161171111111c11c11111c1171111111c11c11111c11711111161611611111
11111b1b1bbb11bb11b11b111bbb1bbb1bbb11711ccc171111111166166616661666171111111ccc1ccc111c171111111ccc1ccc111c17111111116616661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111ddd1ddd1ddd1ddd1ddd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111d1d1d1d1ddd1ddd1d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ddd1ddd11111dd11ddd1d1d1d1d1dd111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111d1d1d1d1d1d1d1d1d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111d1d1d1d1d1d1d1d1ddd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111bbb1bbb11bb1bbb11711ccc111111111616166611111616111111111cc11ccc1ccc111111111cc11ccc1ccc111111111616166611111666116616661661
11111b1b1b111b1111b117111c1c1111111116161161111116161111111111c1111c111c1111111111c1111c111c111111111616116111111616161616161616
11111bb11bb11b1111b117111c1c1111111116161161111116661111111111c11ccc111c1111111111c11ccc111c111111111616116111111661161616611616
11111b1b1b111b1111b117111c1c1171111116161161111111161171111111c11c11111c1171111111c11c11111c117111111616116111111616161616161616
11111b1b1bbb11bb11b111711ccc171111111166166616661666171111111ccc1ccc111c171111111ccc1ccc111c171111111166166616661666166116161666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111ddd1dd11dd11ddd1ddd11111dd11ddd1d1111111ddd1d1d11111ddd1ddd1ddd1ddd1ddd1111111111111111111111111111111111111111
111111111111111111d11d1d1d1d1d1d1d1111111d1d1d111d1111111d1d1d1d11111d1d1d1d1ddd1ddd1d111111111111111111111111111111111111111111
11111ddd1ddd111111d11d1d1d1d1dd11dd111111d1d1dd11d1111111ddd1d1d11111dd11ddd1d1d1d1d1dd11111111111111111111111111111111111111111
111111111111111111d11d1d1d1d1d1d1d1111111d1d1d111d1111111d1d1ddd11111d1d1d1d1d1d1d1d1d111111111111111111111111111111111111111111
11111111111111111ddd1d1d1ddd1d1d1ddd11111ddd1ddd1ddd11111d1d11d111111d1d1d1d1d1d1d1d1ddd1111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111bbb1bbb11bb1bbb11711cc111111111161616661111161611111cc1111111111cc11ccc1c11111111111cc11ccc1c111111111116161666111116661661
11111b1b1b111b1111b1171111c1111111111616116111111616117111c11111111111c1111c1c111111111111c1111c1c111111111116161161111111611616
11111bb11bb11b1111b1171111c1111111111616116111111666177711c11111111111c11ccc1ccc1111111111c11ccc1ccc1111111116161161111111611616
11111b1b1b111b1111b1171111c1117111111616116111111116117111c11171111111c11c111c1c1171111111c11c111c1c1171111116161161111111611616
11111b1b1bbb11bb11b111711ccc17111111116616661666166611111ccc171111111ccc1ccc1ccc171111111ccc1ccc1ccc1711111111661666166616661616
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111ddd1dd11dd11ddd1ddd11111dd11ddd1d1111111ddd1d1d11111ddd1ddd1ddd1ddd1ddd1111111111111111111111111111111111111111
111111111111111111d11d1d1d1d1d1d1d1111111d1d1d111d1111111d1d1d1d11111d1d1d1d1ddd1ddd1d111111111111111111111111111111111111111111
11111ddd1ddd111111d11d1d1d1d1dd11dd111111d1d1dd11d1111111ddd1d1d11111dd11ddd1d1d1d1d1dd11111111111111111111111111111111111111111
111111111111111111d11d1d1d1d1d1d1d1111111d1d1d111d1111111d1d1ddd11111d1d1d1d1d1d1d1d1d111111111111111111111111111111111111111111
11111111111111111ddd1d1d1ddd1d1d1ddd11111ddd1ddd1ddd11111d1d11d111111d1d1d1d1d1d1d1d1ddd1111111111111111111111111111111111111111
11111111111111111111111188888111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111bbb1bbb11bb1bbb1171888881111616166611111616111111111cc11ccc1c11111111111cc11ccc1c111111111116161666111116661661166116661666
11111b1b1b111b1111b117118888811116161161111116161111111111c1111c1c111111111111c1111c1c111111111116161161111111611616161616111616
11111bb11bb11b1111b117118888811116161161111116661111111111c11ccc1ccc1111111111c11ccc1ccc1111111116161161111111611616161616611661
11111b1b1b111b1111b117118878811116161161111111161171111111c11c111c1c1171111111c11c111c1c1171111116161161111111611616161616111616
11111b1b1bbb11bb11b11171878881111166166616661666171111111ccc1ccc1ccc171111111ccc1ccc1ccc1711111111661666166616661616161616661616
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888828282828882822282228888888888888888888888888888888888888888888882288222822882228882822282288222822288866688
82888828828282888888828282828828828882828888888888888888888888888888888888888888888888288882882882828828828288288282888288888888
82888828828282288888822282228828822282828888888888888888888888888888888888888888888888288822882882228828822288288222822288822288
82888828828282888888888288828828888282828888888888888888888888888888888888888888888888288882882882828828828288288882828888888888
82228222828282228888888288828288822282228888888888888888888888888888888888888888888882228222822282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010101010101000000010101010101010101010101000000000101010101010101010101010000000000000001000001000001000001000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
40616161616161616161616161616161616161616161616161616161616161616161515150414141414141414142000000494a4a6a6a6a6a6a6a6a6a6a6a6a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500000000000000000000000000000000000000000000000000000000000000000007272507c00000000000000520000495a5a5b00000000000000000000005b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000000000000000006d6c000000004c0000004c4c00727250000000000000000052000059696a6b000000000000000000007c5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500000000000000000000000000000000000000040415150515051415141514151527272505152524c000050005200005900000000000000000000000000005b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500000000000000000000000000000000000000050515051415150514150415141527272727272504c0000500052000059004c4c0000494a4b494a4b494a4b5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000000040414141527272727272727200007c50515272727272725052724c507252000059494a4b0000595a5b696a6b595a5a6b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
506c6d00000000007e0000000000006c50527272727272727272727200000050505272725052725052724c5072520000695a5a5b0000696a6b000000595a5a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5041504141415041414141414150504152727272727272727272504150415050527272725052725052724c507252000000696a6b0000000000000000696a6b5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505152515151505272727250414152727200720072007200725050415151527272727250527250527250527252000000007e0000000000000000000000005b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50514152724c725052727c727272727272727272727272727272727272725052727272725052724c4c725052725200005f494a4b494a4a4a494b00000000005b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50727272724c7c50527272727272727272727272727272727272727200725052724172725052724c4c72505272520000495a5a5a6b6a6a694b5b00000000005b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50727272724c515041504141504141524150526c00006d5050505272727250514141504141415051415152527252000059696a6b00000000696b00004344455b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000007272727250514151525151414151525200000000505151527272726061616161616161616161616162005200005900000000000000000000005354550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500000007272727272727272727272727272720000000072727272727272000000006c000000006d00004c00005200005900000000494b00000000006364650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500000000072727272727272727272727272725f00000072727272727272724c727272727272727272724c6d6c520000594a4a4a4b595b494a4a4a4a4a4a4a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
506161616161616161616161616161616161427e7e7e7e40616161616161616161616161616161616161616161620000696a6a6a6a6b696a6a6a6a6a6a6a6a6b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500000000000000000000000000000000000004e00004e000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5020000000000000000000000000000000000000000000000000000000005200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5062000000000000000000000000000000000000000000000000000000005200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000000006c00000000000000005f0000000000000000000000000000005200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000404141420000000040514141414200000000000000000000005200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000605151620000000000616161616200000000000000000000005200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
506c6d0000006062000000000000000000000000000000000000000000005200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5041420000000000000000636500000000000000000000000000000000005200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5050527e7e7e7e7e7e7e7e7e7e7e7e7e7e7e7e7e7e6c6d6c6c6d6d6c6c4c5200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505151414141414141414141414141414141414141515151515151426d4c5200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
507272700000200050527272727272727272727272727272727272526c4c5200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
507272700020002050527c727272727272727272727272727272727272505200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50727250515151515151515151515152727b72727b72727b72727b7272725200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5072727272727272727272727272724c72727272727272727272727272725200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5072727272727272727272727272724c72727272727272727272727272725200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051515151515151515151515151515151515251515151525151515151515200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200002e610236201b620176300d6301362015620176201a6301a6201d6401e630176201d6201c6301963014630106100e61004630096100a60006600026000060000600006002360023600006000060034000
0001000000000053300a330093500a3500c3500135000350253501e350003502335023350233401a33014330133001c3001930017300153001130009300003000030000000000000000000000000000000000000
000400001b0500760016050076000760032050076002705007600076002605007600160000d050100503200006050260002560025600370002460023600110002360023600236002360024600146000e60000700
000400001262018630126300962008600086000b6200e6200f63014630136301f6501365004600136501c6501363013620136001f65012650126401262011600116501e640116201865011620206201161010610
000200000e1001211015120181201c1201f1201b120141200d1200812002110001002e10023100191001210000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001062015630186103160020600136001f6001f6001f6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000002960000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
