local desc = dofile 'packages/ol/rougelike1v1/readme.md'
local talent_rule = require "packages.ol.rougelike1v1.talent"

local rougelike1v1 = fk.CreateGameMode{
  name = "rougelike1v1",
  minPlayer = 2,
  maxPlayer = 2,
  logic = function()
    local ret = require "packages.ol.rougelike1v1.logic"
    return ret
  end,
  -- 移除所有马
  build_draw_pile = function(self)
    local allCardIds, void = GameMode.buildDrawPile(self)
    for i = #allCardIds, 1, -1 do
      local subt = Fk:getCardById(allCardIds[i]).sub_type
      if subt == Card.SubtypeDefensiveRide or subt == Card.SubtypeOffensiveRide then
        local id = allCardIds[i]
        table.remove(allCardIds, i)
        table.insert(void, id)
      end
    end
    return allCardIds, void
  end,
}

Fk:loadTranslationTable{
  ["rougelike1v1"] = "单骑无双",
  [":rougelike1v1"] = desc,
}

return rougelike1v1