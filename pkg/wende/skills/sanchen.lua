local sanchen = fk.CreateSkill{
  name = "sanchen",
}

Fk:loadTranslationTable{
  ["sanchen"] = "三陈",
  [":sanchen"] = "出牌阶段限一次，你可令一名角色摸三张牌然后弃置三张牌。若其未因此次效果而弃置类别相同的牌，则其摸一张牌，"..
  "且本技能视为未发动过（本回合不能再指定其为目标）。",

  ["#sanchen"] = "三陈：令一名角色摸三张牌并弃置三张牌",
  ["#sanchen-discard"] = "三陈：弃置三张牌，若类别各不相同则你摸一张牌且 %src 可以再发动“三陈”",
  ["@sanchen"] = "三陈",

  ["$sanchen1"] = "陈书弼国，当一而再、再而三。",
  ["$sanchen2"] = "勘除弼事，三陈而就。",
}

sanchen:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#sanchen",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(sanchen.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark("sanchen-turn"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if player:hasSkill("zhaotao", true) and player:usedSkillTimes("zhaotao", Player.HistoryGame) == 0 and
      player:getMark("@sanchen") < 3 then
      room:addPlayerMark(player, "@sanchen")
    end
    room:addTableMark(player, "sanchen-turn", target.id)
    target:drawCards(3, sanchen.name)
    local cards = room:askToDiscard(target, {
      min_num = 3,
      max_num = 3,
      include_equip = true,
      skill_name = sanchen.name,
      prompt = "#sanchen-discard:"..player.id,
      cancelable = false,
      skip = true,
    })
    local typeMap = {}
    for _, id in ipairs(cards) do
      typeMap[tostring(Fk:getCardById(id).type)] = (typeMap[tostring(Fk:getCardById(id).type)] or 0) + 1
    end
    room:throwCard(cards, sanchen.name, target, target)
    for _, v in pairs(typeMap) do
      if v >= 2 then return end
    end
    if not target.dead then
      target:drawCards(1, sanchen.name)
    end
    if not player.dead then
      player:setSkillUseHistory(sanchen.name, 0, Player.HistoryPhase)
    end
  end,
})

return sanchen
