--[[
Mod "shared_autoban" is meant for use with minetest v0.4.4 and later.
Compatibility with previous versions of MineTest weren't tested, but still might work.

Copyright (c) 2013, 4aiman Konsorumaniakku 4aiman@inbox.ru

Permission to use, copy, modify, and/or distribute this software for any purpose without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
The author preserves the right to demand a fee and/or change this license as he likes.
THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

Special thanks to all authors and modders of the "protector" mod.
Also thanks to Rubenwardy from minetest.net, who made a function to check whether a player exist or not.
]]--

-- some settings:
-- one can disable some messages by setting this to false
local show_messages = true
-- defines whether infotext should be set on_after_place
-- if true, then all blocks would have "Owner is USERNAME" tip. Handy, but annoying.
local set_infotext = true
-- if true, then player will be banned.
-- otherwise server owner & trusted players will be notified
local really_ban = false
-- if true, then player will be unbanned immediately after last person forgives him
-- otherwise server owner & trusted players will be notified
local really_unban = false
-- value in percent, which determines minimum percent of votes,
-- needed by a player to use super pickaxes
local min_trust_level = 80
-- this value shows how many times one will be warned before banned 
local warnings_before_ban = 100000

-- some lists:
-- used for storing number of griefing attempt
bans = {}
-- used for storing list of permitted areas
exceptions = {}
-- used for storing pos1 & pos2 (those are used to make exceptions)
ex_pos = {}
-- used for storing votes
trusted = {}
-- we don't want anyone vote for anyone countless times, do we?
votes = {}

-- Rubenwardy's function to check whether a player exist or not.
-- Didn't want to depend on anything, but default, so just copied this from his library
-- and added a check for "name <> nil" and a message
function player_exists(name)
    if name == nil then return false end
	local privs = minetest.get_player_privs(name);
	if not privs then
		return false;
	else
		return true;
	end
end

-- returna a table with registered users names
function get_registred_players()     
    local list = {}	
    local input = io.open(minetest.get_worldpath().."/auth.txt", "r")
    if input then	   	
	   while true do
          local r = input:read("*l")
          if r == nil then break end
          i = string.find(r, "::")
          r = string.sub(r, 1, i-1)
	      table.insert(list,r)     
       end       
       io.close(input)
    end   
	return list
end

-- checks whether "who" can vote for "for_who"
function can_vote(who,for_who)
   if votes == nil then votes = {} end
   if votes[who] == nil then votes[who] = {} end
   for i,v in pairs (votes[who]) do
       if v==for_who then
          return false
       end                
   end
   return true                   
end

-- some messages:
--  1-30% is hint
-- 31-60% is notion
-- 61-99% is warning
--   100% == ban
-- now even with fast tools any player should be able to notice messages...
-- calculations aren't precise, though
function hinting_message(target,count)
  if count/warnings_before_ban < 0.31 then	
     return "\nThe owner of this (or adjacent) area is " .. target .. ".\nAsk him/her for permission to change anyting here!"
  elseif (count/warnings_before_ban > 0.3) and (count/warnings_before_ban <0.61) then
     return "\nYou should'n mess with other people's stuff.\nThis one (or adjacent) belongs to " .. target .. ".\nNote, that you may be punished for this attempt."	
  elseif (count/warnings_before_ban > 0.6) and (count/warnings_before_ban <1) then
     return "\nDo NOT mess up with what isn't yours.\nThis is " .. target .. "'s place.\nWarning! ".. tostring(10-count).." more times and you'll be BANNED!"	
  elseif count/warnings_before_ban >=1 then
     if really_ban then 
        return "\nYou were banned just now.\nIf the owner would forgive you, then you may return to this server."
	 else
	    return "\nYou won't be banned, however, those-who-should-be-notified will be notified." 
	 end
  end
end


-- save this mod's tables
-- nothing more then de-serializing
-- but still effective and easy ;)
function save_stuff()
    local output = io.open(minetest.get_modpath('shared_autoban').."/stuff.lua", "w")
    if output then
	   o  = minetest.serialize(bans)
       i  = string.find(o, "return")
       o1 = string.sub(o, 1, i-1)
	   o2 = string.sub(o, i-1, -1)
	   output:write(o1 .. "\n")			
       output:write("bans = minetest.deserialize('" .. o2       .. "')\n")			
	   
	   o  = minetest.serialize(ex_pos)
       i  = string.find(o, "return")
       o1 = string.sub(o, 1, i-1)
	   o2 = string.sub(o, i-1, -1)
	   output:write(o1 .. "\n")			
       output:write("ex_pos = minetest.deserialize('" .. o2    .. "')\n" )			
       
	   o  = minetest.serialize(trusted)
       i  = string.find(o, "return")
       o1 = string.sub(o, 1, i-1)
	   o2 = string.sub(o, i-1, -1)
	   output:write(o1 .. "\n")			
       output:write("trusted = minetest.deserialize('" .. o2   .. "')\n" )			

	   o  = minetest.serialize(exceptions)
       i  = string.find(o, "return")
       o1 = string.sub(o, 1, i-1)
	   o2 = string.sub(o, i, -1)
	   output:write(o1 .. "\n")			
       output:write("exceptions = minetest.deserialize('" .. o2 .. "')\n")	
              
	   o  = minetest.serialize(votes)
       i  = string.find(o, "return")
       o1 = string.sub(o, 1, i-1)
	   o2 = string.sub(o, i, -1)
	   output:write(o1 .. "\n")			
       output:write("votes = minetest.deserialize('" .. o2 .. "')\n")	
              
       io.close(output)       
    end
end

-- check whether super tool is in the player's hands...
function check_for_super_tool(player)    
	if (player:get_wielded_item():get_name()== "shared_autoban:admin_pick_wood")
	or (player:get_wielded_item():get_name()== "shared_autoban:admin_pick_stone")
	or (player:get_wielded_item():get_name()== "shared_autoban:admin_pick_steel")
	or (player:get_wielded_item():get_name()== "shared_autoban:admin_pick_mese")
	then 	
	    local pl_num = table.getn(get_registred_players())	
	    player = player:get_player_name() 
	    if trusted[player] ~= nil 
	    and (trusted[player]) >= pl_num*min_trust_level/100 then
	        return true 
		else
            return false	        	
		end  
	else
	    return false
	end
end

-- check for ownership at given pos only
function check_ownership_once(pos, pl)   
   local pos1 = pos
   if pos1 == nil then minetest.chat_send_all("check_ownership_once pos is nil??!") return end
   local meta = minetest.env:get_meta(pos1)
   if meta == nil then return true end
   if meta:get_string("owner") == pl:get_player_name()
   or meta:get_string("owner") == nil
   or meta:get_string("owner") == ""
   or minetest.env:get_node(pos1).name == "air"
   or check_exception(meta:get_string("owner"), pl:get_player_name(), pos)
   or check_for_super_tool(pl)
   then
      return true -- if it's not ours
   else
      return false,meta:get_string("owner")  -- if it IS ours
   end 
end

-- check for ownership at positions adjacent to pos
-- no diagonal, though - it would be unjust to claim those too
function check_ownership(pos, placer)
    local phoney_pos_01 = {x = pos.x-1, y = pos.y-1, z = pos.z-1}
    local phoney_pos_02 = {x = pos.x  , y = pos.y-1, z = pos.z-1}
    local phoney_pos_03 = {x = pos.x+1, y = pos.y-1, z = pos.z-1}
    local phoney_pos_04 = {x = pos.x-1, y = pos.y-1, z = pos.z  }
    local phoney_pos_05 = {x = pos.x  , y = pos.y-1, z = pos.z  }
    local phoney_pos_06 = {x = pos.x+1, y = pos.y-1, z = pos.z  }
    local phoney_pos_07 = {x = pos.x-1, y = pos.y-1, z = pos.z+1}
    local phoney_pos_08 = {x = pos.x  , y = pos.y-1, z = pos.z+1}
    local phoney_pos_09 = {x = pos.x+1, y = pos.y-1, z = pos.z+1}
	
    local phoney_pos_10 = {x = pos.x-1, y = pos.y  , z = pos.z-1}
    local phoney_pos_11 = {x = pos.x  , y = pos.y  , z = pos.z-1}
    local phoney_pos_12 = {x = pos.x+1, y = pos.y  , z = pos.z-1}
    local phoney_pos_13 = {x = pos.x-1, y = pos.y  , z = pos.z  }
    -- local phoney_pos_14 = {x = pos.x  , y = pos.y  , z = pos.z  } - no need
    local phoney_pos_15 = {x = pos.x+1, y = pos.y  , z = pos.z  }
    local phoney_pos_16 = {x = pos.x-1, y = pos.y  , z = pos.z+1}
    local phoney_pos_17 = {x = pos.x  , y = pos.y  , z = pos.z+1}
    local phoney_pos_18 = {x = pos.x+1, y = pos.y  , z = pos.z+1}
	
    local phoney_pos_19 = {x = pos.x-1, y = pos.y+1, z = pos.z-1}
    local phoney_pos_20 = {x = pos.x  , y = pos.y+1, z = pos.z-1}
    local phoney_pos_21 = {x = pos.x+1, y = pos.y+1, z = pos.z-1}
    local phoney_pos_22 = {x = pos.x-1, y = pos.y+1, z = pos.z  }
    local phoney_pos_23 = {x = pos.x  , y = pos.y+1, z = pos.z  }
    local phoney_pos_24 = {x = pos.x+1, y = pos.y+1, z = pos.z  }
    local phoney_pos_25 = {x = pos.x-1, y = pos.y+1, z = pos.z+1}
    local phoney_pos_26 = {x = pos.x  , y = pos.y+1, z = pos.z+1}
    local phoney_pos_27 = {x = pos.x+1, y = pos.y+1, z = pos.z+1}
	

    local list = {}    	
    phoney_pos_01,_01 = check_ownership_once(phoney_pos_01, placer)
	if phoney_pos_01 == nil then minetest.debug("check_ownership pos is nil??!") return end		    
	phoney_pos_02,_02 = check_ownership_once(phoney_pos_02, placer)
    phoney_pos_03,_03 = check_ownership_once(phoney_pos_03, placer)
    phoney_pos_04,_04 = check_ownership_once(phoney_pos_04, placer)
    phoney_pos_05,_05 = check_ownership_once(phoney_pos_05, placer)
    phoney_pos_06,_06 = check_ownership_once(phoney_pos_06, placer)
    phoney_pos_07,_07 = check_ownership_once(phoney_pos_07, placer)
    phoney_pos_08,_08 = check_ownership_once(phoney_pos_08, placer)
    phoney_pos_09,_09 = check_ownership_once(phoney_pos_09, placer)
    phoney_pos_10,_10 = check_ownership_once(phoney_pos_10, placer)
    phoney_pos_11,_11 = check_ownership_once(phoney_pos_11, placer)
    phoney_pos_12,_12 = check_ownership_once(phoney_pos_12, placer)
    phoney_pos_13,_13 = check_ownership_once(phoney_pos_13, placer)
--
    phoney_pos_15,_15 = check_ownership_once(phoney_pos_14, placer)
    phoney_pos_16,_16 = check_ownership_once(phoney_pos_16, placer)
    phoney_pos_17,_17 = check_ownership_once(phoney_pos_17, placer)
    phoney_pos_18,_18 = check_ownership_once(phoney_pos_18, placer)
    phoney_pos_19,_19 = check_ownership_once(phoney_pos_19, placer)
    phoney_pos_20,_20 = check_ownership_once(phoney_pos_20, placer)
    phoney_pos_21,_21 = check_ownership_once(phoney_pos_21, placer)
    phoney_pos_22,_22 = check_ownership_once(phoney_pos_22, placer)
    phoney_pos_23,_23 = check_ownership_once(phoney_pos_23, placer)
    phoney_pos_24,_24 = check_ownership_once(phoney_pos_24, placer)
    phoney_pos_25,_25 = check_ownership_once(phoney_pos_25, placer)
    phoney_pos_26,_26 = check_ownership_once(phoney_pos_26, placer)
    phoney_pos_27,_27 = check_ownership_once(phoney_pos_27, placer)
	
	list[01] = _01
	list[02] = _02
	list[03] = _03
	list[04] = _04
	list[05] = _05
	list[06] = _06
	list[07] = _07
	list[08] = _08
	list[09] = _09
	list[10] = _10
	list[11] = _11
	list[12] = _12
	list[13] = _13
--	
	list[15] = _15
	list[16] = _16
	list[17] = _17
	list[18] = _18
	list[19] = _19
	list[20] = _20
	list[21] = _21
	list[22] = _22
	list[23] = _23
	list[24] = _24
	list[25] = _25
	list[26] = _26
    list[27] = _27
	
    if  phoney_pos_left
	and phoney_pos_righ
    and phoney_pos_back
    and phoney_pos_forv
    and phoney_pos_uppe
    and phoney_pos_bott
	then return true, list
	else return false,list
	end
end

-- allows owner to grant "interact" within his/her territory 
-- (has nothing to do with "interact" priv)
function create_exception(owner, player, pos1, pos2)
    if not player_exists(player)
	then	    
	    return
	end

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
    if not player_exists(player)
	then	    
	    return
	end
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
    if not player_exists(player)
	then	    
	    return
	end
    if exceptions == nil then return end   	
	if owner == nil      then return end	
	if player == nil     then return end	
	if pos1 == nil       then return end
	if pos2 == nil       then return end
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
                          exceptions[q].data[i][j] = nil 
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
     --  table.insert(bans, player)
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

-- counts total violations
function get_violations_count(player)
    local count = 0
       for key, value in ipairs(bans[player].data) do
           count = count + value["cou"]
       end       
    return count
end

-- notify trusted about player being nasty...
function notify_trusted(message)
   local l = minetest.get_connected_players()
   local pl_num = table.getn(get_registred_players())
   for i,x in pairs(l) do
       local name = x:get_player_name()
       if trusted[name] ~= nil 
       and (trusted[name]) >= pl_num*min_trust_level/100 then	       
           minetest.chat_send_player(name, message)            
       end
   end
end

-- bans a player by the name "name" after 5 seconds 
function ban_him_or_her(name)
    if really_ban then 
       minetest.after(5000, minetest.ban_player(name))    
	else
	   local times = get_violations_count(name)
	   local message = name .. " annoys other players. Total: " .. times .. " time(s)."
	   notify_trusted(message)
	end
end

-- set property violation level to 0
-- player = violator, owner = rightful owner
function forgive(owner,player)   
   if not player_exists(player)
   then	    
	    return
   end
   if bans == nil 
   then       
       return false 
   end
   if bans[player] == nil 
   then       
	   return false 
   end   
   if bans[player].data == nil 
   then       
	   return false 
   end
   
   for i,v in pairs (bans[player].data) do      
	  if v.own == owner 
	  then
	      bans[player].data[i].cou = 0
		  check_for_unban_possibility(player)
		  save_stuff()
	      return true
	  end
   end    
end

-- called on every /forgive command to unban a player
-- if there's no more "grave" violations left
function check_for_unban_possibility(player)
   local result = false
   if bans == nil 
   then 
       result = true
   end
   if bans[player] == nil 
   then       
	   result = true
   end   
   if bans[player].data == nil 
   then      
	   result = true
   end

   local count = 0  
   for i,v in pairs (bans[player].data) do      
       if bans[player].data[i].cou < warnings_before_ban
		  then 
              count = count+1
		  end		  	      	  
   end
   
   if #bans[player].data == count then
      result = true
   	  if really_unban then 
	     minetest.unban_player_or_ip(player)
	  else
		  local message = "No one seems to be against " .. player .. " anymore."
		  notify_trusted(message)
      end
   end
   return result
end

-- remember good old minetest.item_place 
old_place = minetest.item_place

-- 'cause we would override that to set "ownership"
function minetest.item_place(itemstack, placer, pointed_thing)  
--	if placer:get_wielded_item():is_empty() then return end				
	if pointed_thing.type ~= 'nothing' then
	   if pointed_thing.type == 'node' then
	      pos = pointed_thing.above
	   end
	end
	if pos == nil then minetest.chat_send_all("pos is nil??!") return end
	
	local can,adj = check_ownership(pos, placer)
    if can 
	then	    
		local count = itemstack:get_count()
	 	local name = itemstack:get_name()

        old_place(itemstack, placer, pointed_thing)
        local meta = minetest.env:get_meta(pos)
        meta:set_string("owner",placer:get_player_name())
        if set_infotext then meta:set_string("infotext","Owned by " .. placer:get_player_name()) end
		return itemstack
	else
	    local line = ""
		for i,v in ipairs(adj)  do		
	       line = line .. v .. ", "
		end   
		minetest.chat_send_all(line)
           local name = placer:get_player_name()
		   local meta = minetest.env:get_meta(pos)
		   local owner = meta:set_string("owner",placer:get_player_name())
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
    groups = {dig_immediate=2},
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

-- super picks craft definition
-- can dig any protected block

-- wooden:
minetest.register_craft({
	output = 'shared_autoban:admin_pick_wood',
	recipe = {
		{'default:pick_wood'},
		{'shared_autoban:markup_pencil'},		
	}
})

-- stone:
minetest.register_craft({
	output = 'shared_autoban:admin_pick_stone',
	recipe = {
		{'default:pick_stone'},
		{'shared_autoban:markup_pencil'},		
	}
})

-- steel:
minetest.register_craft({
	output = 'shared_autoban:admin_pick_steel',
	recipe = {
		{'default:pick_steel'},
		{'shared_autoban:markup_pencil'},		
	}
})

-- mese:
minetest.register_craft({
	output = 'shared_autoban:admin_pick_mese',
	recipe = {
		{'default:pick_mese'},
		{'shared_autoban:markup_pencil'},		
	}
})


-- super picks tool definition
-- can dig any protected block
-- if their wielder is trusted

-- wooden:
minetest.register_tool("shared_autoban:admin_pick_wood", {
	description = "Super Wooden Pickaxe",
	inventory_image = "default_tool_woodpick.png",
	tool_capabilities = {
		max_drop_level=0,
		groupcaps={
			cracky={times={[2]=2.00, [3]=1.20}, uses=10, maxlevel=1}
		}
	},
})

--stone
minetest.register_tool("shared_autoban:admin_pick_stone", {
	description = "Super Stone Pickaxe",
	inventory_image = "default_tool_stonepick.png",
	tool_capabilities = {
		max_drop_level=0,
		groupcaps={
			cracky={times={[1]=2.00, [2]=1.20, [3]=0.80}, uses=20, maxlevel=1}
		}
	},
})

-- steel
minetest.register_tool("shared_autoban:admin_pick_steel", {
	description = "Super Steel Pickaxe",
	inventory_image = "default_tool_steelpick.png",
	tool_capabilities = {
		max_drop_level=1,
		groupcaps={
			cracky={times={[1]=4.00, [2]=1.60, [3]=1.00}, uses=10, maxlevel=2}
		}
	},
})

--mese
minetest.register_tool("shared_autoban:admin_pick_mese", {
	description = "Super Mese Pickaxe",
	inventory_image = "default_tool_mesepick.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=3,
		groupcaps={
			cracky={times={[1]=2.0, [2]=1.0, [3]=0.5}, uses=20, maxlevel=3},
			crumbly={times={[1]=2.0, [2]=1.0, [3]=0.5}, uses=20, maxlevel=3},
			snappy={times={[1]=2.0, [2]=1.0, [3]=0.5}, uses=20, maxlevel=3}
		}
	},
})

-- chat command to "forgive" a player
-- drops count of violations to 0
minetest.register_chatcommand("forgive", {
    params = "<playername> | leave playername empty to see help message",
    description = "Drops the property violation counter",
    privs = {},
    func = function(name, param)
        if param == "" then                        
            minetest.chat_send_player(name, "Usage: /forgive <playername>")
            return        
        else
            if not player_exists(param) 
            then 
                minetest.chat_send_player(name,"There's no player called by that name!")
                return 
            end                    
            forgive(name,param)
            minetest.chat_send_all(name .. " forgave " ..  param .. ".")
--            minetest.log("action", name .. " forgave " ..  param .. ".")
            return        
		end
    end
})

-- chat command to grant area interact to a player
-- does the same thing as the button "Grant" in the PC's formspec
minetest.register_chatcommand("area_grant", {
    params = "<playername> | leave playername empty to see help message",
    description = "Grant 'interact' to playername (only with blocks you own)",
    privs = {},
    func = function(name, param)	
        if param == "" then
            minetest.chat_send_player(name, "Usage: /area_grant <playername>")
            return        
        else
            if not player_exists(param) 
            then 
                minetest.chat_send_player(name,"There's no player called by that name!")
                return 
            end            
			local m = name .. " granted area interact to " ..  param .. " "..
			"(".. minetest.pos_to_string(ex_pos[name].pos1) .. " " .. minetest.pos_to_string(ex_pos[name].pos2) .. ")."
			create_exception(name, param, ex_pos[name].pos1, ex_pos[name].pos2)
            minetest.chat_send_all(m)
--            minetest.log("action", m)
            return        
		end
    end
})

-- chat command to revoke area interact from a player
-- does the same thing as the button "Revoke" in the PC's formspec
minetest.register_chatcommand("area_revoke", {
    params = "<playername> | leave playername empty to see help message",
    description = "Revoke playername's 'interact' granted by /grantarea",
    privs = {},
    func = function(name, param)
        if param == "" then
            minetest.chat_send_player(name, "Usage: /area_revoke <playername>")
            return        
        else
            if not player_exists(param) 
            then 
                minetest.chat_send_player(name,"There's no player called by that name!")
                return 
            end            
			local m = name .. " revoked area interact from " ..  param .. " "..
			"(".. minetest.pos_to_string(ex_pos[name].pos1) .. " " .. minetest.pos_to_string(ex_pos[name].pos2) .. ")."
            remove_exception(name, param, ex_pos[name].pos1, ex_pos[name].pos2)			
            minetest.chat_send_all(m)
--            minetest.log("action", m)
            return        
		end
    end
})

-- chat command to grant area interact to all players
minetest.register_chatcommand("area_grant_all", {
    params = "<playername> | Use --help switch see help message",
    description = "Grant 'interact' to all players (only with blocks you own)",
    privs = {},
    func = function(name, param)	
        if param == "--help" then
            minetest.chat_send_player(name, "Usage: /area_grant_all")
            return        
        else
		    if not player_exists(param) then return end            
			if ex_pos[name].pos1==nil or ex_pos[name].pos1==nil 
			then
			    minetest.chat_send_player(name, "To use this chat command you must set Start/End positions with markup pencil.")   
                return			
			end
            local list=get_registred_players()
			for i,v in ipairs(list) do
               create_exception(name, v, ex_pos[name].pos1, ex_pos[name].pos2)     			
			end
			local m = name .. " granted area interact to everyone "..
			"(".. minetest.pos_to_string(ex_pos[name].pos1) .. " " .. minetest.pos_to_string(ex_pos[name].pos2) .. ")."
            minetest.chat_send_all(m)
--            minetest.log("action", m)
            return        
		end
    end
})

-- chat command to rovoke area interact from all players
minetest.register_chatcommand("area_revoke_all", {
    params = "<playername> | Use --help switch see help message",
    description = "Revoke 'interact' to all players (only with blocks you own)",
    privs = {},
    func = function(name, param)	
        if param == "--help" then
            minetest.chat_send_player(name, "Usage: /area_revoke_all")
            return        
        else
		    if not player_exists(param) then return end            
			if ex_pos[name].pos1==nil or ex_pos[name].pos1==nil 
			then
			    minetest.chat_send_player(name, "To use this chat command you must set Start/End positions with markup pencil.")   
                return			
			end
            local list=get_registred_players()
			for i,v in ipairs(list) do               
			   remove_exception(name, v, ex_pos[name].pos1, ex_pos[name].pos2)
			end
			local m = name .. " revoked area interact to everyone "..
			"(".. minetest.pos_to_string(ex_pos[name].pos1) .. " " .. minetest.pos_to_string(ex_pos[name].pos2) .. ")."
            minetest.chat_send_all(m)
--            minetest.log("action", m)
            return        
		end
    end
})

-- chat command for one to vote for someone
minetest.register_chatcommand("vote", {
    params = "<playername> | leave playername empty to see help message",
    description = "Gives one's vote for <playername>\nIf he/she will be trusted by at least ".. 
                   min_trust_level .."% of all players on this server,\n" ..
                   "then he/she will be able to use Super tools!",
    privs = {},
    func = function(name, param)
        if param == "" then                        
            minetest.chat_send_player(name, "Usage: /vote <playername>")
            return        
        else            
            if not player_exists(param) 
            then 
                minetest.chat_send_player(name,"There's no player called by that name!")
                return 
            end            
            if not can_vote(name,param) 
            then 
                minetest.chat_send_player(name,"You have voted already for that person.\n"..
                                               "There's nothing you can do, but 'withdraw' your vote...")            
                return 
            end            
            table.insert(votes[name],param)
            local x = 1
            if trusted == nil then trusted = {} end
            if trusted[param] ~= nil then
               x = trusted[param] + 1
               trusted[param]=x               
            else
               trusted[param]=1
            end            
            save_stuff()
            minetest.chat_send_all(name .. " voted for " ..  param .. ".")
--            minetest.log("action", name .. " voted for " ..  param .. ".")
            return        
		end
    end
})

-- chat command for withdraw one's vote for someone
minetest.register_chatcommand("devote", {
    params = "<playername> | leave playername empty to see help message",
    description = "Withdraws one's vote for <playername>\nIf his/her trust will drop below ".. 
                   min_trust_level .."% of all players on this server,\n" ..
                   "then he/she won't be able to use Super tools!",
    privs = {},
    func = function(name, param)
        if param == "" then                        
            minetest.chat_send_player(name, "Usage: /devote <playername>")
            return        
        else            
            if not player_exists(param) 
            then 
                minetest.chat_send_player(name,"There's no player called by that name!")
                return 
            end            
            if can_vote(name,param) 
            then 
                minetest.chat_send_player(name,"You didn't voted for that person.\n"..
                                               "There's nothing you can do, but vote...")            
                return 
            end            
            
            for i,v in pairs (votes[name]) do
                if v==param then
                   table.remove(votes[name],i)
                end                
            end
            save_stuff()
            minetest.chat_send_all(name .. " don't trust " ..  param .. " anymore.")
--            minetest.log("action", name .. " don't trust " ..  param .. " anymore.")
            return        
		end
    end
})

-- "loads" saved data by running stuff.lua
dofile(minetest.get_modpath('shared_autoban').."/stuff.lua")

