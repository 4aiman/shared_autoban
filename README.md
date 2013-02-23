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
- he ignores that messages 3 times and the 4th would be last one - he would be banned within 5 seconds

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
   So you see a splash as if you were punched - you know that you're at someone's place

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
