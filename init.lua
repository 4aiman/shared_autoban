-- check for ownership at given pos only
function check_ownership_once(pos, placer)   
   local meta = minetest.env:get_meta(pos)
   if meta:get_string("owner") == placer:get_player_name()
   or meta:get_string("owner") == nil
   or minetest.env:get_node(pos).name == "air"
   then
        minetest.chat_send_player(placer:get_player_name(), "ours: " .. minetest.serialize(pos))      
      return true -- if it's not ours
   else
        minetest.chat_send_player(placer:get_player_name(), "not ours: " .. minetest.serialize(pos))      
      return false  -- if it IS ours
   end 
end

-- check for ownership at given pos and adjasent ones
-- no diagonal, though - it would be unjust to claim those too
function check_ownership(pos, placer)
    local phoney_pos_left = pos
    local phoney_pos_righ = pos    
    local phoney_pos_back = pos
    local phoney_pos_forv = pos
    local phoney_pos_bott = pos
	local phoney_pos_uppe = pos
	
    phoney_pos_left.x = phoney_pos_left.x - 1
    phoney_pos_righ.x = phoney_pos_righ.x + 1    
    phoney_pos_back.z = phoney_pos_back.z - 1
	phoney_pos_forv.z = phoney_pos_forv.z + 1
    phoney_pos_bott.y = phoney_pos_bott.y - 1
	phoney_pos_uppe.y = phoney_pos_uppe.y + 1
	
    if
--check_ownership_once(pos, placer)
--	and 
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
        minetest.chat_send_player(placer:get_player_name(), "Area not protected, claiming!")
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





