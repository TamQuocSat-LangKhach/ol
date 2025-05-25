local bolong = fk.CreateSkill{
  name = "bolong",
}

Fk:loadTranslationTable{
  ["bolong"] = "驳龙",
  [":bolong"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.你交给其一张牌，视为对其使用一张雷【杀】；"..
  "2.交给你与你手牌数等量张牌，视为对你使用一张【酒】。",

  ["#bolong"] = "驳龙：令一名其他角色选择一项",
  ["#bolong-card"] = "驳龙：交给 %src %arg张牌视为对其使用【酒】，否则其交给你一张牌视为对你使用雷【杀】",
  ["#bolong-slash"] = "驳龙：交给 %dest 一张牌，视为对其使用雷【杀】",

  ["$bolong1"] = "驳者，食虎之兽焉，可摄冢虎。",
  ["$bolong2"] = "主上暗弱，当另择明主侍之。",
}

bolong.zhongliu_type = Player.HistoryPhase

bolong:addEffect("active", {
  anim_type = "offensive",
  prompt = "#bolong",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(bolong.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and to_select ~= player then
      return not player:isNude() or (not player:isKongcheng() and #to_select:getCardIds("he") >= player:getHandcardNum())
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = player:getHandcardNum()
    if #target:getCardIds("he") >= n and n > 0 then
      local cards = room:askToCards(target, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = bolong.name,
        prompt = "#bolong-card:"..player.id.."::"..n,
        cancelable = true,
      })
      if #cards == n then
        room:obtainCard(player, cards, false, fk.ReasonGive, target, bolong.name)
        room:useVirtualCard("analeptic", nil, target, player, bolong.name)
        return
      end
    end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = bolong.name,
      prompt = "#bolong-slash::"..target.id,
      cancelable = false,
    })
    room:obtainCard(target, card, false, fk.ReasonGive, player, bolong.name)
    room:useVirtualCard("thunder__slash", nil, player, target, bolong.name, true)
  end,
})

return bolong
