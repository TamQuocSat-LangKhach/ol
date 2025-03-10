local liehou = fk.CreateSkill{
  name = "liehou",
}

Fk:loadTranslationTable{
  ["liehou"] = "列侯",
  [":liehou"] = "出牌阶段限一次，你可以令你攻击范围内一名有手牌的角色交给你一张手牌，然后你将一张手牌交给你攻击范围内的另一名其他角色。",

  ["#liehou"] = "列侯：令一名角色交给你一张手牌，然后你将一张手牌交给攻击范围内另一名角色",
  ["#liehou-give"] = "列侯：你需交给 %src 一张手牌",
  ["#liehou-choose"] = "列侯：将一张手牌交给攻击范围内另一名角色",

  ["$liehou1"] = "识时务者为俊杰。",
  ["$liehou2"] = "丞相有令，尔敢不从？",
}

liehou:addEffect("active", {
  anim_type = "control",
  prompt = "#liehou",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(liehou.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:inMyAttackRange(to_select) and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = liehou.name,
      prompt = "#liehou-give:"..player.id,
      cancelable = false,
    })
    room:obtainCard(player, card, false, fk.ReasonGive, target, liehou.name)
    if player.dead or player:isKongcheng() then return end
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:inMyAttackRange(p) and p ~= target
      end)
    if #targets == 0 then return end
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      pattern = ".|.|.|hand",
      skill_name = liehou.name,
      prompt = "#liehou-choose",
      cancelable = false,
    })
    room:obtainCard(to[1], cards, false, fk.ReasonGive, player, liehou.name)
  end
})

return liehou
