
local xinsheng = fk.CreateSkill {
  name = "ol_ex__xinsheng",
}

Fk:loadTranslationTable {
  ["ol_ex__xinsheng"] = "新生",
  [":ol_ex__xinsheng"] = "当你受到1点伤害后，若你有技能“化身”，你可以随机获得一张新的“化身”牌。",

  ["$ol_ex__xinsheng1"] = "枯木发荣，朽木逢春。",
  ["$ol_ex__xinsheng2"] = "风靡云涌，万丈光芒。",
}

local U = require("packages/utility/utility")

local huashen_blacklist = {
  -- imba
  "zuoci", "ol_ex__zuoci", "qyt__dianwei", "starsp__xiahoudun", "mou__wolong",
  -- haven't available skill
  "js__huangzhong", "liyixiejing", "olz__wangyun", "yanyan", "duanjiong", "wolongfengchu", "wuanguo", "os__wangling", "tymou__jiaxu",
}

local function Gethuashen(player, n)
  local room = player.room
  local generals = table.filter(room.general_pile, function (name)
    return not table.contains(huashen_blacklist, name)
  end)
  local mark = U.getPrivateMark(player, "&ol_ex__huashen")
  for _ = 1, n do
    if #generals == 0 then break end
    local g = table.remove(generals, math.random(#generals))
    table.insert(mark, g)
    table.removeOne(room.general_pile, g)
  end
  U.setPrivateMark(player, "&ol_ex__huashen", mark)
end

xinsheng:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xinsheng.name) and target == player and player:hasSkill("ol_ex__huashen", true)
  end,
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_use = function(self, event, target, player, data)
    Gethuashen(player, 1)
  end,
})

return xinsheng