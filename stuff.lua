
bans = minetest.deserialize('return { ["singleplayer"] = { ["data"] = { { ["cou"] = 7, ["own"] = "4" }, { ["cou"] = 8, ["own"] = "4ai" }, { ["cou"] = 0, ["own"] = "4aiman" } } }, ["4ai"] = { ["data"] = { { ["own"] = "singleplayer", ["cou"] = 61 }, { ["own"] = "4aiman", ["cou"] = 4 } } } }')

ex_pos = minetest.deserialize('return { ["singleplayer"] = { ["first"] = false, ["pos1"] = { ["y"] = 3, ["x"] = 67, ["z"] = -46 }, ["pos2"] = { ["y"] = 3, ["x"] = 67, ["z"] = -46 } } }')

trusted = minetest.deserialize('return {  }')
local _={ }
_[1]={ ["y"] = 2, ["x"] = 66, ["z"] = -46 }
_[2]={ ["y"] = 2, ["x"] = 66, ["z"] = -46 }

exceptions = minetest.deserialize('return { ["singleplayer"] = { ["data"] = { ["singleplayer"] = { { ["p2"] = _[1], ["p1"] = _[2] } } } }, ["4"] = { ["data"] = { ["singleplayer"] = { { ["p2"] = _[1], ["p1"] = _[2] } } } }, ["4aiman"] = { ["data"] = { ["singleplayer"] = { { ["p2"] = _[1], ["p1"] = _[2] } } } }, ["4ai"] = { ["data"] = { ["singleplayer"] = { { ["p2"] = _[1], ["p1"] = _[2] } } } } }')

votes = minetest.deserialize('return {  }')
