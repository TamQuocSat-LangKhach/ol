local dingcuo = fk.CreateSkill{
  name = "dingcuo",
}

Fk:loadTranslationTable{
  ["dingcuo"] = "定措",
  [":dingcuo"] = "每回合限一次，当你造成或受到伤害后，你可以摸两张牌，若这两张牌颜色不同，你弃置一张手牌。",

  ["$dingcuo1"] = "丞相新丧，吾当继之！",
  ["$dingcuo2"] = "规画分部，筹度粮谷。",
}

local dingcuo_spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dingcuo.name) and player:usedSkillTimes(dingcuo.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local cards = player:drawCards(2, dingcuo.name)
    if Fk:getCardById(cards[1]).color ~= Fk:getCardById(cards[2]).color and not player.dead then
      player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = dingcuo.name,
        cancelable = false,
      })
    end
  end,
}

dingcuo:addEffect(fk.Damage, dingcuo_spec)
dingcuo:addEffect(fk.Damaged, dingcuo_spec)

return dingcuo
