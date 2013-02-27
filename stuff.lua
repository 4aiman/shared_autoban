
bans = minetest.deserialize('return { ["4ai"] = { ["data"] = { { ["cou"] = 61, ["own"] = "singleplayer" }, { ["cou"] = 4, ["own"] = "4aiman" } } }, ["4aiman"] = { ["data"] = { { ["cou"] = 40, ["own"] = "4ai" }, { ["cou"] = 319, ["own"] = "someone" } } }, ["4aiman2"] = { ["data"] = { { ["cou"] = 165, ["own"] = "someone" }, { ["cou"] = 36, ["own"] = "4ai" }, { ["own"] = "4aiman", ["cou"] = 1 } } }, ["singleplayer"] = { ["data"] = { { ["own"] = "4", ["cou"] = 7 }, { ["own"] = "4ai", ["cou"] = 8 }, { ["own"] = "4aiman", ["cou"] = 0 } } } }')

ex_pos = minetest.deserialize('return { ["singleplayer"] = { ["first"] = false, ["pos1"] = { ["y"] = 3, ["x"] = 67, ["z"] = -46 }, ["pos2"] = { ["y"] = 3, ["x"] = 67, ["z"] = -46 } } }')

trusted = minetest.deserialize('return {  }')

exceptions = minetest.deserialize('return nil')

votes = minetest.deserialize('return {  }')
