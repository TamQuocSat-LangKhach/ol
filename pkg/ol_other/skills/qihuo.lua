local qihuo = fk.CreateSkill{
  name = "qin__qihuo",
}

Fk:loadTranslationTable{
  ["qin__qihuo"] = "奇货",
  [":qin__qihuo"] = "出牌阶段限一次，你可以弃置你一种类别全部的牌，摸等量的牌。",

  ["#qin__qihuo"] = "奇货：弃置你一种类别全部的牌，摸等量的牌",

  ["$qin__qihuo"] = "奇货可居，慧眼善识。",
}

qihuo:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#qin__qihuo",
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    local all_choices = {"basic","trick","equip"}
    local choices = table.filter(all_choices, function (type)
      return table.find(player:getCardIds("he"), function(id)
        return Fk:getCardById(id):getTypeString() == type and not player:prohibitDiscard(id)
      end) ~= nil
    end)
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id):getTypeString() == self.interaction.data and not player:prohibitDiscard(id)
    end)
    room:throwCard(cards, qihuo.name, player, player)
    if not player.dead then
      player:drawCards(#cards, qihuo.name)
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(qihuo.name, Player.HistoryPhase) == 0 and not player:isNude() and
      table.find(player:getCardIds("he"), function(id)
        return not player:prohibitDiscard(id)
      end)
  end,
})

return qihuo
