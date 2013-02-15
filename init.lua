-- check for ownership at given pos only
function check_ownership_once(pos, placer)   
   local meta = minetest.env:get_meta(pos)
   if meta:get_string("owner") == placer:get_player_name()
   or meta:get_string("owner") == nil
   or meta:get_string("owner") == ""
   or minetest.env:get_node(pos).name == "air"
   then
     --   minetest.chat_send_player(placer:get_player_name(), "ours: " .. minetest.serialize(pos))      
      return true -- if it's not ours
   else
   --     minetest.chat_send_player(placer:get_player_name(), "not ours: " .. minetest.serialize(pos))      
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
	
--[[
minetest.chat_send_player(placer:get_player_name(), "left " ..
minetest.serialize(phoney_pos_left) .. "\nright " ..
minetest.serialize(phoney_pos_righ) .. "\nforv " ..
minetest.serialize(phoney_pos_forv) .. "\nback " ..
minetest.serialize(phoney_pos_back) .. "\nupper " ..
minetest.serialize(phoney_pos_uppe) .. "\n bottom " ..
minetest.serialize(phoney_pos_bott))      
]]--
	
    if  --check_ownership_once(pos, placer) --	and 
        check_ownership_once(phoney_pos_left, placer)
	and check_ownership_once(phoney_pos_righ, placer)
    and check_ownership_once(phoney_pos_back, placer)
    and check_ownership_once(phoney_pos_forv, placer)
    and check_ownership_once(phoney_pos_uppe, placer)
    and check_ownership_once(phoney_pos_bott, placer)
	then return true
	else return false
	end
end

local do_place = minetest.item_place

function minetest.item_place(itemstack, placer, pointed_thing)
    local pos = pointed_thing.above
    if check_ownership(pos, placer)
	then
		local count = itemstack:get_count()
	 	local name = itemstack:get_name()
		
		itemstack:clear()
        itemstack:replace(name .. " " .. count)		
       	-- do_place(itemstack, placer, pointed_thing)
        local meta = minetest.env:get_meta(pos)
        meta:set_string("owner",placer:get_player_name())
        meta:set_string("infotext","Owned by " .. placer:get_player_name())        
		return do_place(itemstack, placer, pointed_thing)
	else
		return 
    end		
end



function can_break(pos)
    if check_ownership(pos, placer) then
       return true
    else
        return false
    end  
end

-- set ownership register

minetest.register_on_punchnode(
function (pos, node, puncher)
    local meta = minetest.env:get_meta(pos)
    minetest.chat_send_player(puncher:get_player_name(), "The owner is '" .. meta:get_string("owner") .. "'!")       
end
)



