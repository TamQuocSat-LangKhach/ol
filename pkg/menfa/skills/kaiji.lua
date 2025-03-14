local kaiji = fk.CreateSkill{
  name = "ol__kaiji",
}

Fk:loadTranslationTable{
  ["ol__kaiji"] = "开济",
  [":ol__kaiji"] = "出牌阶段限一次，你可以令一名本轮未以此法指定过的角色弃置你一张手牌，然后你可以使用弃置的牌，若如此做，你摸一张牌。",

  ["#ol__kaiji"] = "开济：令一名角色弃置你一张手牌，你可以使用被弃置的牌并摸一张牌",
  ["#ol__kaiji-discard"] = "开济：请弃置 %src 一张手牌",
  ["#ol__kaiji-use"] = "开济：你可以使用这张牌，摸一张牌",

  ["$ol__kaiji1"] = "开济国朝之心，可曰昭昭。",
  ["$ol__kaiji2"] = "开大胜之世，匡大魏之朝。",
}

kaiji.zhongliu_type = Player.HistoryPhase

kaiji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol__kaiji",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kaiji.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and not table.contains(player:getTableMark("ol__kaiji-round"), to_select.id) then
      if to_select == player then
        return table.find(player:getCardIds("h"), function (id)
          return not player:prohibitDiscard(id)
        end)
      else
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "ol__kaiji-round", target.id)
    local card
    if target == player then
      card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = kaiji.name,
        prompt = "#ol__kaiji-discard:"..player.id,
        cancelable = false,
      })
    else
      card = room:askToChooseCard(target, {
        target = player,
        flag = "h",
        skill_name = kaiji.name,
        prompt = "#ol__kaiji-discard:"..player.id,
      })
      room:throwCard(card, kaiji.name, player, target)
      card = {card}
    end
    if not player.dead and card and table.contains(room.discard_pile, card[1]) then
      local use = room:askToUseRealCard(player, {
        pattern = card,
        skill_name = kaiji.name,
        prompt = "#ol__kaiji-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
          expand_pile = card,
        }
      })
      if use and not player.dead then
        player:drawCards(1, kaiji.name)
      end
    end
  end,
})

return kaiji
