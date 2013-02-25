--[[
Mod "shared_autoban" is meant for use with minetest v0.4.4 and later.
Compatibility with previous versions of MineTest weren't tested, but still might work.

Copyright (c) 2013, 4aiman Konsorumaniakku 4aiman@inbox.ru

Permission to use, copy, modify, and/or distribute this software for any purpose without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
The author preserves the right to demand a fee and/or change this license as he likes.
THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

Special thanks to all authors and modders of the "protector" mod.
]]--

-- some settings:
-- one can disable some messages by setting this to false
local show_messages = true
-- defines whether infotext should be set on_after_place
-- if true, then all blocks would have "Owner is USERNAME" tip. Handy, but annoying.
local set_infotext = false

-- some lists:
-- used for storing number of griefing attempt
local bans = {}
-- used for storing list of permitted areas
local exceptions = {}
-- used for storing pos1 & pos2 (those are used to make exceptions)
local ex_pos = {}

-- some messages:
-- 1-3 is hint
-- 4-6 is notion
-- 7-9 is warning
-- 10 = ban
-- now even with fast tools any player should be able to notice messages...
function hinting_message(target,count)
  if count < 4 then	
     return "\nThe owner of this (or adjacent) area is " .. target .. ".\nAsk him/her for permission to change anyting here!"
  elseif (count > 3) and (count <7) then
     return "\nYou should'n mess with other people's stuff.\nThis one (or adjacent) belongs to " .. target .. ".\nNote, that you may be punished for this attempt."	
  elseif (count > 6) and (count <10) then
     return "\nDo NOT mess up with what isn't yours.\nThis is " .. target .. "'s place.\nWarning! One more time and you'll be BANNED!"	
  elseif count >=10 
     return "\nYou were banned just now.\nIf the owner would forgive you, then you may return to this server."
  end
end


-- save this mod's tables
function save_stuff()
    local output = io.open(minetest.get_modpath('shared_autoban').."/stuff.txt", "w")
    if output then
       output:write(minetest.serialize(exceptions).. "\n")			
       output:write(minetest.serialize(bans)      .. "\n")			
       output:write(minetest.serialize(ex_pos)           )			
       io.close(output)
    end

end

-- save this mod's tables
function load_stuff()
    local input = io.open(minetest.get_modpath('shared_autoban').."/stuff.txt", "r")
    if input then
       local r = input:read("*l")			                 
          exceptions = minetest.deserialize(r)       
       r = input:read("*l")			
           bans = minetest.deserialize(r)
       
       r = input:read("*l")						
           ex_pos = minetest.deserialize(r)       
       io.close(input)
    end    
end

-- check for ownership at given pos only
function check_ownership_once(pos, pl)   
   local meta = minetest.env:get_meta(pos)
   if meta:get_string("owner") == pl:get_player_name()
   or meta:get_string("owner") == nil
   or meta:get_string("owner") == ""
   or minetest.env:get_node(pos).name == "air"
   or check_exception(meta:get_string("owner"), pl:get_player_name(), pos)
   then
      return true -- if it's not ours
   else
      return false  -- if it IS ours
   end 
end

-- check for ownership at positions adjacent to pos
-- no diagonal, though - it would be unjust to claim those too
function check_ownership(pos, placer)
    local phoney_pos_left = {x = pos.x-1, y = pos.y, z = pos.z}
    local phoney_pos_righ = {x = pos.x+1, y = pos.y, z = pos.z}
    local phoney_pos_back = {x = pos.x, y = pos.y-1, z = pos.z}
    local phoney_pos_forv = {x = pos.x, y = pos.y+1, z = pos.z}
    local phoney_pos_bott = {x = pos.x, y = pos.y, z = pos.z-1}
	local phoney_pos_uppe = {x = pos.x, y = pos.y, z = pos.z+1}

    if  check_ownership_once(phoney_pos_left, placer)
	and check_ownership_once(phoney_pos_righ, placer)
    and check_ownership_once(phoney_pos_back, placer)
    and check_ownership_once(phoney_pos_forv, placer)
    and check_ownership_once(phoney_pos_uppe, placer)
    and check_ownership_once(phoney_pos_bott, placer)
	then return true
	else return false
	end
end

-- allows owner to grant "interact" within his/her territory 
-- (has nothing to do with "interact" priv)
function create_exception(owner, player, pos1, pos2)
    if exceptions == nil
	then 
	    exceptions = {}
	end   
	
	if exceptions[player] == nil
	then 
        exceptions[player] = {}
	end
	
	if exceptions[player].data == nil
	then
	    exceptions[player].data = {}
	end
	
	if exceptions[player].data[owner] == nil
	then
        exceptions[player].data[owner] = {}
	end

    local d = {p1 = pos1, p2 = pos2}
    table.insert(exceptions[player].data[owner],d)	   
    save_stuff()     
end;

-- checks for an exception at the given pos
-- return true if owner has granted player to build/break at pos
-- otherwise returns false
function check_exception(owner, player, pos)
    if exceptions == nil
	then 
	     return false
	end   
	
	if owner == nil 
	then
	    return true
	end
	
	if player == nil 
	then
	    return false
	end
	
	if pos == nil 
	then
	    return false
	end

	for q,w in pairs (exceptions) do
	    if q == owner then
           for i,v in pairs(w.data) do
               if i == player then    
                  for j,m in pairs(v) do
                      if  (math.min(m.p1.x,m.p2.x)<=pos.x) 
                      and (pos.x<=math.max(m.p1.x,m.p2.x))
                      and (math.min(m.p1.y,m.p2.y)<=pos.y) 
                      and (pos.y<=math.max(m.p1.y,m.p2.y))
                      and (math.min(m.p1.z,m.p2.z)<=pos.z) 
                      and (pos.z<=math.max(m.p1.z,m.p2.z))
                      then 
                          return true 
                      end
                  end 
               end
           end
        end 
	end
return false
end;

-- removes "interact" granted by owner to a player 
-- deletes ANY exception rule for player within 
-- min(pos1,pos2) to max(pos1,pos2)
function remove_exception(owner, player, pos1, pos2)
    if exceptions == nil then minetest.debug("exceptions is nil") return end   	
	if owner == nil      then minetest.debug("owner is nil     ") return end	
	if player == nil     then minetest.debug("playername is nil") return end	
	if pos1 == nil       then minetest.debug("pos1 is nil      ") return end
	if pos2 == nil       then minetest.debug("pos2 is nil      ") return end
	for q,w in pairs (exceptions) do
        if q == owner then	      
           for i,v in pairs(w.data) do
               if i == player then    
                  for j,m in pairs(v) do                      

                   local maxposx = math.max(pos1.x,pos2.x)
                   local minposx = math.min(pos1.x,pos2.x) 
                   local maxposy = math.max(pos1.y,pos2.y)
                   local minposy = math.min(pos1.y,pos2.y) 
                   local maxposz = math.max(pos1.z,pos2.z)
                   local minposz = math.min(pos1.z,pos2.z) 

                   local maxpx = math.max(m.p1.x,m.p2.x)
                   local minpx = math.min(m.p1.x,m.p2.x) 
                   local maxpy = math.max(m.p1.y,m.p2.y)
                   local minpy = math.min(m.p1.y,m.p2.y) 
                   local maxpz = math.max(m.p1.z,m.p2.z)
                   local minpz = math.min(m.p1.z,m.p2.z) 
                   
                      if  maxposx >= maxpx
                      and maxposy >= maxpy
                      and maxposz >= maxpz
                      and minposx >= minpx
                      and minposy >= minpy
                      and minposz >= minpz
                      then    
                          exceptions[q].data[i][j] =nil 
                          save_stuff()
                          return
                      end
                  end 

               end
           end
        end 
	end
	
end

-- checks for how many attempts to build/destroy at owner's place
-- were made by a certain player
-- returns a message and a boolean value, showing
-- whether that player should be banned or not yet
function give_a_warning_or_ban(player,owner)    
    local f = {message = "player name is nil!", ban = false}
    if player == nil then 
       return f
    end

    local x = {}          
    local count = -1
    if owner=="" 
    or owner == nil 
    then owner = "someone"
    end
    
    local found = false
    if bans == nil 
    then bans = {} 
    end
    if bans[player] == nil then
       table.insert(bans, player)
       bans[player] =  {}
    end
    if bans[player].data == nil then
       bans[player].data = {}
       local d = {own = owner, cou = 0}  
       table.insert(bans[player].data, d)
       count = 0
       found = true
    end

    if not found then
       for key, value in ipairs(bans[player].data) do
           if value["own"] == owner then  
              value["cou"] = value["cou"] + 1
              count = value["cou"]
              bans[player].data[key] = value
              found = true
              break
           end
       end       
   end

   if not found then
       local d = {own = owner, cou = 0}  
       table.insert(bans[player].data, d)
       count = 0

   end
   
   local b = false
   if count>=10 then
      b = true
   end

   x = {message = hinting_message(owner,count), ban = b}
   save_stuff()
   return x 
end

-- bans a player by the name "name" after 5 seconds 
function ban_him_or_her(name)
    minetest.after(5000, minetest.ban_player(name))    
end


-- remember good old minetest.item_place 
old_place = minetest.item_place

-- 'cause we would override that to set "ownership"
function minetest.item_place(itemstack, placer, pointed_thing)    
--	if placer:get_wielded_item():is_empty() then return end				
    local pos = pointed_thing.above
    if check_ownership(pos, placer)
	then	    
		local count = itemstack:get_count()
	 	local name = itemstack:get_name()

        old_place(itemstack, placer, pointed_thing)
        local meta = minetest.env:get_meta(pos)
        meta:set_string("owner",placer:get_player_name())
        if set_infotext then meta:set_string("infotext","Owned by " .. placer:get_player_name()) end
		return itemstack
	else
           local pos = pointed_thing.under
           local meta = minetest.env:get_meta(pos)
           local owner = meta:get_string("owner") or "someone"     
           local name = placer:get_player_name()
           local x = give_a_warning_or_ban(name,owner)
           if show_messages then
               minetest.chat_send_player(name,x.message)
           end 
           if x.ban then
              ban_him_or_her(name)                        
           end
           
		return 
    end			
end

-- checks whether digger can dig at pos
-- useless alias to check_ownership_once ;)
function can_break(pos,digger)
    if check_ownership_once(pos, digger) then
       return true
    else
        return false
    end  
end

-- warns with red splash & possible (by a glitch, but still) health dropdown
minetest.register_on_punchnode( function (pos, node, puncher)    
    if not check_ownership_once(pos, puncher) then
    local hp = puncher:get_hp()
    if hp>1 then
       puncher:set_hp(hp - 1)   
       minetest.after(0.05, function()
          puncher:set_hp(hp)
       end)       
    end
    end
end
)

-- remember good old minetest.node_dig 
local do_dig_node = minetest.node_dig 

-- 'cause we would override that to add some checks 
-- and prohibit to dig if necessary
function minetest.node_dig(pos, node, digger)
   if not can_break(pos,digger) 
   then 
       local meta = minetest.env:get_meta(pos)
       local name = digger:get_player_name()
       local owner = meta:get_string("owner") or "someone"
       local x= give_a_warning_or_ban(name,owner)
           if show_messages then
               minetest.chat_send_player(name,x.message)
           end 
          if x.ban then 
             ban_him_or_her(name) 
          end        
       return 
   else 
       do_dig_node(pos, node, digger)
   end
end

-- nodebox for a control PC
local nodebox_PC = {
	--screen back
    {-0.4, -0.2, 0.3, 0.4, 0.3, 0.4},
	--screen front
    {-0.5, -0.3, 0.2 , 0.5, 0.5, 0.3},
	--stand
    {-0.1, -0.4, 0.3, 0.1, -0.2, 0.4},
	--stand holder
    {-0.2, -0.5, 0.2, 0.2, -0.4, 0.5},
	--keyboard
    {-0.5, -0.5, -0.4,  0.5, -0.4, 0.1},
}

-- PC node definition
minetest.register_node("shared_autoban:rule_em_all_node", {
    drawtype = "nodebox",
    tile_images = {"top.png","sides.png","sides.png","sides.png","back.png","front.png"},    
    paramtype = "light",        
    paramtype2 = "facedir",  
    walkable = true,
    inventory_image = "default_cobble.png",
    groups = {dig_immediate=2, bouncy=100},
    description = "Permissions ruler!",
		selection_box = {
			type = "fixed",
			fixed = nodebox_PC,
            },
		node_box = {
			type = "fixed",
			fixed = nodebox_PC,
            },
		
   after_place_node = function(pos, placer, itemstack)
   local meta = minetest.env:get_meta(pos)
           meta:set_string("formspec",
                           "size[6,4]"..	            
			               "field[0.5,1;3,1;p_1;Pos1:;]"..
			               "field[0.5,2;3,1;p_2;Pos2:;]"..
			               "field[0.5,3;3,1;username;Playername:;]"..
			               "button[3.5,1.7;2,1;grant;Grant]"..
			               "button[3.5,2.7;2,1;revoke;Revoke]"
			              )	 
   end, 
				
   on_punch = function(pos, node, puncher)        
 		local meta = minetest.env:get_meta(pos)
        local name = puncher:get_player_name()
        if name ~= "" then
           if ex_pos[name] == nil then
              return
           end
		   
		   if (ex_pos[name].pos1  == nil) 
		   or (ex_pos[name].pos1 == nil) 
		   then return
		   end

           meta:set_string("formspec",
                           "size[6,4]"..	            
			               "field[0.5,1;3,1;p_1;Pos1:;".. minetest.pos_to_string(ex_pos[name].pos1) .. "]"..
			               "field[0.5,2;3,1;p_2;Pos2:;".. minetest.pos_to_string(ex_pos[name].pos2) .. "]"..
			               "field[0.5,3;3,1;username;Playername:;]"..
			               "button[3.5,1.7;2,1;grant;Grant]"..
			               "button[3.5,2.7;2,1;revoke;Revoke]"
			              )				
        end        
   end,
   
   on_receive_fields = function(pos, formname, fields, sender)
      if (fields.p_1 == nil) 
	  or (fields.p_1 == nil) 
	  then 
	      return
	  end
	  
	  if fields.username == nil 
	  then 
	      return 
	  end
      
      local name = sender:get_player_name()
      
      if fields.grant then
         create_exception(fields.username, name, minetest.string_to_pos(fields.p_1), minetest.string_to_pos(fields.p_2)) 
	  end	  
      
      if fields.revoke then
         remove_exception(name, fields.username, minetest.string_to_pos(fields.p_1), minetest.string_to_pos(fields.p_2)) 
      end
      
   end,			   
})

-- markup pencil definition
minetest.register_item("shared_autoban:markup_pencil", {
	type = "none",
	wield_image = "pencil.png",
    inventory_image = "pencil.png",
	wield_scale = {x=1,y=1,z=1},
	tool_capabilities = {
		full_punch_interval = 0.1,
		max_drop_level = 0,
        stack_max = 99,
        liquids_pointable = false,        
	},

	on_use = function(itemstack, user, pointed_thing)		
		pos = pointed_thing.under
        if pos == nil then return end  
        
        if user.first 
        then user:set_properties{pos1 = n,}
        else user:set_properties{pos2 = n,}
        end
        
        local name = user:get_player_name()
        if name ~= "" then
           if ex_pos[name] == nil then
              ex_pos[name] = {}
              ex_pos[name].first = true
           end   
           if ex_pos[name].first then
              ex_pos[name].pos1 = pos              
              minetest.chat_send_player(name,'Start pos set to ' .. minetest.pos_to_string(pos))
			  ex_pos[name].first = not ex_pos[name].first
           else
              ex_pos[name].pos2 = pos               
              minetest.chat_send_player(name,'End pos set to ' .. minetest.pos_to_string(pos))
			  ex_pos[name].first = not ex_pos[name].first
           end           
        end

	end,
})

-- crafting recipe for a pencil
minetest.register_craft({
	output = 'shared_autoban:markup_pencil',
	recipe = {
		{'',              'shared_autoban:coal_dust',   ''},
		{'default:stick', 'shared_autoban:coal_dust', 'default:stick'},
		{'default:stick', 'shared_autoban:coal_dust', 'default:stick'},
	}
})

-- crafting recipe for a PC
minetest.register_craft({
	output = 'shared_autoban:rule_em_all_node',
	recipe = {
		{'default:cobble',  'default:cobble',               'default:cobble'},
		{'default:cobble',  'shared_autoban:markup_pencil', 'default:cobble'},
		{'default:cobble',  'default:cobble',               'default:cobble'},
	}
})
	

-- crafting recipe for coal dust (needed to craft pencils)
minetest.register_craft({
	output = 'shared_autoban:coal_dust',
	recipe = {
		{'default:coal_lump'},
	}
})

-- coal dust definition
minetest.register_craftitem("shared_autoban:coal_dust", {
	description = "Coal Dust",
	inventory_image = "coal_dust.png",
})

load_stuff()
