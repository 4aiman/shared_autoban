-- settings
local show_messages = true
local show_debug_messages = false
local set_infotext = false
local time_to_forgive = 30

-- some lists:
-- used for storing number of griefing attempt
local bans = {}
-- used for storing list of permitted areas
local exceptions = {}

-- messages
function hinting_message(target)
return "\nThe owner of this (or adjacent) area is " .. target .. ".\nAsk him/her for permission to change anyting here!"
end

function warning_message(target)
return "\nYou should'n mess with other people's stuff.\nThis one (or adjacent) belongs to " .. target .. ".\nNote, that you may be punished for this attempt."
end

function lastone_message(target)
return "\nDo NOT mess up with what isn't yours.\nThis is " .. target .. "'s place.\nWarning! One more time and you'll be BANNED!"
end

function banning_message(target)
return "\nYou were banned just now.\nIf the owner would forgive you, then you may return to this server.\nOtherwise you'll have to wait for " .. time_to_forgive .. " days before you'll be able to do so."
end

--[[ minetest.create_detached_inventory("", callbacks)

{
allow_move = func(inv, from_list, from_index, to_list, to_index, count, player),
    ^ Called when a player wants to move items inside the inventory
^ Return value: number of items allowed to move

    allow_put = func(inv, listname, index, stack, player),
    ^ Called when a player wants to put something into the inventory
^ Return value: number of items allowed to put
^ Return value: -1: Allow and don't modify item count in inventory
   
    allow_take = func(inv, listname, index, stack, player),
    ^ Called when a player wants to take something out of the inventory
^ Return value: number of items allowed to take
^ Return value: -1: Allow and don't modify item count in inventory

on_move = func(inv, from_list, from_index, to_list, to_index, count, player),
    on_put = func(inv, listname, index, stack, player),
    on_take = func(inv, listname, index, stack, player),
^ Called after the actual action has happened, according to what was allowed.
^ No return value
}
]]

-- check for ownership at given pos only
function check_ownership_once(pos, pl)   
   local meta = minetest.env:get_meta(pos)
   if meta:get_string("owner") == pl:get_player_name()
   or meta:get_string("owner") == nil
   or meta:get_string("owner") == ""
   or minetest.env:get_node(pos).name == "air"
   then
      if show_debug_messages then minetest.chat_send_player(placer:get_player_name(), "Ours: " .. minetest.serialize(pos)) end
      return true -- if it's not ours
   else
      if show_debug_messages then minetest.chat_send_player(placer:get_player_name(), "Not ours: " .. minetest.serialize(pos)) end
      return false  -- if it IS ours
   end 
end

-- check for ownership at given pos and adjasent ones
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

function create_exception(owner, player, pos1, pos2)
    if exceptions == nil
	then exceptions = {}
	end   
	
	if exceptions[player] == nil
	then --table.insert(exceptions,player)
	exceptions[player] = {}
	end
	
	if exceptions[player].data == nil
	then exceptions[player].data = {}
	end
	
	if exceptions[player].data[owner] == nil
	then --table.insert(exceptions[player].data,owner)
	exceptions[player].data[owner] = {}
	end

	for key, value in ipairs(exceptions[player].data[owner])
	local d = {p1 = pos1, p2 = pos2}
	table.insert(exceptions[player].data[owner],d)	
	
    minetest.debug("\n exceptions: " ..  minetest.serialize(exceptions[player].data))	
	minetest.chat_send_all("\n exceptions: " ..  minetest.serialize(exceptions[player].data))	
end;

function delete_exception(owner, player, pos1, pos2)

end

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
--   minetest.debug('player: ' .. player .. '  owner:' .. owner)
    if bans == nil 
    then bans = {} 
    end
--   minetest.debug("bans: " ..  minetest.serialize(bans))
    if bans[player] == nil then
       table.insert(bans, player)
       bans[player] =  {}
    end
--   minetest.debug("bans player: " ..  minetest.serialize(bans[player]))
    if bans[player].data == nil then
       bans[player].data = {}
       local d = {own = owner, cou = 0}  
       table.insert(bans[player].data, d)
       count = 0
       found = true
 --      minetest.debug("bans player data created ... " .. minetest.serialize(bans[player].data))
    end

if not found then
       for key, value in ipairs(bans[player].data) do
           if value["own"] == owner then  
              value["cou"] = value["cou"] + 1
              count = value["cou"]
              bans[player].data[key] = value
-- minetest.debug("bans player data found ... " .. minetest.serialize(value))
              found = true
              break
           end
       end       
end

if not found then
       local d = {own = owner, cou = 0}  
       table.insert(bans[player].data, d)
       count = 0
  --     minetest.debug("creating 2 ... " .. minetest.serialize(bans))

end

         if count <= 0 then x = {message = hinting_message(owner), ban = false}
    elseif count == 1 then x = {message = warning_message(owner), ban = false}
    elseif count == 2 then x = {message = lastone_message(owner), ban = false}
    elseif count  > 2 then x = {message = banning_message(owner), ban = true}
    end
    return x 
end

function ban_him_or_her(name)
  --  minetest.after(5000, minetest.ban_player(name))

    
end

-- overriding minetest.item_place to set "ownership"
function minetest.item_place(itemstack, placer, pointed_thing)
    
	create_exception("someone" ..  tostring(math.random (1,10)), 
	                 placer:get_player_name(), 
					 pointed_thing.under, 
					 {x=0,y=0,z=0}
					)

					
    local pos = pointed_thing.above
    if check_ownership(pos, placer)
	then
		local count = itemstack:get_count()
	 	local name = itemstack:get_name()
       	minetest.item_place_node(itemstack, placer, pointed_thing)
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

-- check for breaking possibility 
-- useless alias to check_ownership_once ;)
function can_break(pos,digger)
    if check_ownership_once(pos, digger) then
       return true
    else
        return false
    end  
end


minetest.register_on_punchnode(
function (pos, node, puncher)
    local meta = minetest.env:get_meta(pos)
end
)

local do_dig_node = minetest.node_dig 


function minetest.node_dig(pos, node, digger)
   if not can_break(pos,digger) 
   then 
       local meta = minetest.env:get_meta(pos)
       local name = digger:get_player_name()
       local owner = meta:get_string("owner") or "someone"
       local x= give_a_warning_or_ban(name,owner)

       if show_messages then             
          if x.ban then 
             minetest.chat_send_player(name,x.message) 
             ban_him_or_her(name) 
          else
            minetest.chat_send_player(name,x.message)              
          end        
       end
       return 
   else 
       do_dig_node(pos, node, digger)
   end
end


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

minetest.register_node("shared_autoban:rule_em_all_node", {
    drawtype = "nodebox",
    tile_images = {"top.png","sides.png","sides.png","sides.png","back.png","front.png"},    
    paramtype = "light",        
    paramtype2 = "facedir",  
    walkable = true,
    inventory_image = "default_cobble.png",
    groups = {dig_immediate=2},
    description = "Permissions ruler!",
		selection_box = {
			type = "fixed",
			fixed = nodebox_PC,
            },
		node_box = {
			type = "fixed",
			fixed = nodebox_PC,
            }			
})




