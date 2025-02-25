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

local this = fk.CreateSkill {
  name = "ol_ex__xinsheng",
}

this:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(this.name) and target == player and player:hasSkill("ol_ex__huashen", true)
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for _ = 1, data.damage do
      if self.cancel_cost or not (player:hasSkill(this.name) and player:hasSkill("ol_ex__huashen", true)) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, { skill_name = this.name }) then return true end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    Gethuashen(player, 1)
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__xinsheng"] = "新生",
  [":ol_ex__xinsheng"] = "当你受到1点伤害后，若你有技能“化身”，你可以随机获得一张新的“化身”牌。",
  
  ["$ol_ex__xinsheng1"] = "枯木发荣，朽木逢春。",
  ["$ol_ex__xinsheng2"] = "风靡云涌，万丈光芒。",
}

return this