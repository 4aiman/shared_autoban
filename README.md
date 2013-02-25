shared_autoban
==============

This mod adds autoban feature based on something that personally I call "land auto claim" along with 
the means of sharing parts of claimed land with different players.

Licence is inside init.lua, so if you would use this mod, you won't end up without it anyway.

How things work
---------------

Digging:
- a certain player places a block
- that block now belongs to that player
- if someone wants to destroy that block he won't succeed
- instead of removing that block he would receive a warning message
- he ignores that messages 3 times and the 4th would be last one - he would be banned in 5 seconds

Building:
- a certain player places a block
- that block now belongs to that player
- if someone wants to place his own block adjacent to the first one he won't succeed
- instead of placing that block he would receive a warning message
- he ignores that messages 3 times and the 4th would be last one - he would be banned within 5 seconds

Isn't that great? Sertainly it is ;)

Questions & Answers
-------------------

Q: If I can't place a block directly next to someone else's block, then where I can do that? 

A: You can't place blocks only at adjacent positions. Say, someone's block is placed at some "position".
   Then you can't place blocks only at the following positions: 
   
        - position = {position.x-1, position.y,   position.z  }; 
        
        - position = {position.x+1, position.y,   position.z  }; 
        
        - position = {position.x,   position.y-1, position.z  }; 
        
        - position = {position.x,   position.y+1, position.z  }; 
        
        - position = {position.x,   position.y,   position.z-1}; 
        
        - position = {position.z,   position.y,   position.z+1}. 
        
   That means you can place block diagonally at position like {position.x-1, position.y-1, position.z}.

Q: What if someone didn't know that he tried to dig someone else's blocks? 

A: Well, that's totally NOT possile. Once someone punch a block which is owned by a different person,
   he/she would see a red splash. Sometimes digger would lose 1 HP after punch, but that's only 
   if he/she insists on punching what isn't his/hers. 
   So you see a splash as if you were punched - you know that you're at someone's place.

Q: Okay, but what if I want to build stuff WITH someone's help? Is there any way to grant "interact" within 
   a certain area to a certain player? 

A: Of cource there is! 

Q: So, what do I need to do that? 

A: First you must craft a "markup pencil". With that you can select areas: just punch
   any block with that tool and you would set either the start or the end position. 
   Recipe for a pencil is as follows: 
   
        {'',              'shared_autoban:coal_dust',   ''           }, 
    
		{'default:stick', 'shared_autoban:coal_dust', 'default:stick'}, 
		
		{'default:stick', 'shared_autoban:coal_dust', 'default:stick'}. 

   Shared_autoban:coal_dust can be crafted from a coal_lump like so: 
   
        {'default:coal_lump'}

Q: Why do I need that stupid pencil? Can't I live happily without it? 

A: Well, you don't realy need to use a pencil to set positions. It's still possible to set that positions 
   without a pencil, but you'll need at least 1 pencil to craft a PC.

Q: Okay, and just why do I need that PC of yours? Or it's optional too? 

A: "PC" isn't optional. PC is a node that allows you to grant or to revoke "interact" within defined positions. 
    Crafting recipe for a PC is as follows:
     
  	    {'default:cobble',  'default:cobble',               'default:cobble'}, 
  	
		{'default:cobble',  'shared_autoban:markup_pencil', 'default:cobble'}, 
		
		{'default:cobble',  'default:cobble',               'default:cobble'}.

Q: I've made a PC , then what? 

A: Great! Place it anywhere you can and click with right mouse button on it. 
   You would see a form with 3 fields and 2 buttons. Fields are named so that anyone should figure out
   what to put in them. Buttons functions correspond to their names: "Grant" grants and "Revoke" revokes
   "interact" to/from a player with a "Playername" name within area from Pos1 to Pos2.   

Q: And what if I grant "interact" within my land, so that "granted" area would be within "non-granted"? 

A: If you grant someone not all of your land, then that very "someone" would be able to destroy your 
blocks within area from Pos1 to Pos2, but he/she won't be able to place a block near the edge of "granded"
   area, 'cause there are your blocks around. You can't place a block adjacent to someone else's block, 
   remember? ;)

Q: You vere saying that pencil can set Pos1 and Pos2 for me, but it doesn't work at all! What I'm doing wrong? 

A: To "paste" your start and end positions into the PC's fields you need to punch it. Yep, select 2 positions 
   and then punch your (or someone else's) PC. Then right-click on it as usual and you would see selected 
   positions are pasted in the fields "Pos1" and "Pos2".

Q: Can I revoke "interact" partially? Say, pos1 is {0,0,0} and pos2 is {100,100,100}, how can I "shrink" that
   to {20,20,20} .. {80,80,80}? 

A: You can't atm. You must revoke "interact" from the whole area and then grant again to a smaller one.

Q: Okay, how do I revoke "interact"? 

A: Just select pos1 and pos2 so that one of them would be smaller or equal to the pos1 of the granted area and 
   the second one would be bigger or equal to the pos2 of the granted area.
   To make it simplier to understand, let's say you have granted to 4aiman (yep, that's me) "interact" 
   from {0,0,0} to {10,10,10}.
   To revoke "interact" you should set pos1 and pos2 as follows: 
    
      pos1 = {0,0,0} pos = {10,10,10}  
      
   or 
    
      pos1 = {0-whatever,0-whatever,0-whatever} pos = {10+whatever,10+whatever,10+whatever}  
      
   or  
   
      pos1 = {0-whatever,10+whatever,0-whatever} pos = {10+whatever,0-whatever,10+whatever}  
      
   etc... 
   
   As you can see above, all you really need is to select an area without paying any special attention 
   to the Pos1 and Pos2 values. Just make sure you've selected area which is bigger or equal to the "granted" one.

Q: What if there are 2 owners in the area? Should I ask them both to grant me "interact"? 

A: Yes, you should. You may build to/break only those blocks of someone who granted you to do that.
   And that only within that "granted" area.

Q: So, if he/she had granted me "interact" and I have built something there then that person wouldn't be able to 
   destroy/build to my block until I grant him/her "interact"? 

A: Precisely so. So be nice and grant him/her "interact" too.

Q: Is there any moderator tool planned?

A: There is, but it would be usable only by trusted players. And I mean that - "trusted" by server community, not
   by administration ;)
   
Q: So, I can build a house without changing ground and... would anyone be able to destroy the floor an d fill my
   house with some hideous stuff?

A: Sure. So make a basement for your house too. If you won't - the blockspamming would be your problem, not this mod's.

Q: Can I break unowned blocks in the granted only to someone else area?

A: Yes, you can. This mod do not protect not owned stuff.

Q: If I would grant someone "interact" and then build something inside granted area - would new blocks be granted 
   as well?

A: They would.

Q: How many times can I violate someone's property safely?

A: 9 to EACH owner. So yes, anyone may try to annoy everyone else for 9 times and still be unbanned.

Q: Is there any way to change how many violations one can issue?

A: Sure - just change warnings_before_ban variable in the init.lua. 

Q: Why do I get messages that I can't place a block, because it's mine?

A: It's a bug. I'll fix that anytime soon. If that happens, then there is a block, owned by someone else.
   Do not insist on building, find out who is the onwner and ask him to grant you "interact". Also, try to 
   /forgive yourself.
   
Q: What are you talking about? There're chatcommands available, aren't they?

A: Yes, there are. One can use this commands:
   /area_grant <playername>            - grants interact to <playername> in the selected area (use pencil)
   /area_revoke <playername>           - revokes interact from <playername> in the selected area (use pencil)
   /area_grant_all <playername>        - grants interact to all in the selected area (use pencil)
   /area_revoke_all <playername>       - revokes interact from all in the selected area (use pencil)
   /forgive <playername>               - drops violaton counter of <playername> to 0
   /vote <playername>                  - +1 to reputation of <playername>
   /devote <playername>                - -1 to reputation of <playername>
   
   /forgive will check whether there are someone else who is griefed/annoyed by <playername>. If there's no such
            person, then <playername> have good chances to be unbanned*.

   /vote is possible only 1 time for each EXISTING <playername>. 
         So: - No, you can't "create" trusted player by yourself.
             - Yes, even if you cooperate with someone, you can't give your votes for some inexistent person.

   /devote is also possible only 1 time for each EXISTING <playername> and only if you've voted for that person.
   
   * It's up to settings to decide whether you'll be banned/unbanned or not. See init.lua lines 15-31.
   
Q: Why do I need to vote?

A: There's no need in that, but if min_trust_level% would vote for someone, then he/she would be able to use
   admin Super tools.
   
Q: Wow! Supertool! What's that?

A: That's a pickaxe, crafted like this:
  
      {'default:pick_*material*'}
      {'shared_autoban:markup_pencil'}   
   
   There are wooden, stone, steel and mese pickaxes. They are equal to their prototypes in all terms, but can break
   owned by a third person blocks. (Only if it's wielder is trusted amongst server population).

Q: Where can I learn more about this mod?

A: Check init.lua contents. This mod is commented rather well. In fact, you could've get answers on all the questions 
   above by doing that ;)
