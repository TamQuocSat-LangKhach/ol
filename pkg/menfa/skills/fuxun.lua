local fuxun = fk.CreateSkill{
  name = "fuxun",
}

Fk:loadTranslationTable{
  ["fuxun"] = "抚循",
  [":fuxun"] = "出牌阶段限一次，你可以交给一名其他角色一张手牌或获得一名其他角色一张手牌，"..
  "然后若其手牌数与你相同且本阶段未因此法以外的方式变化过，你可以将一张牌当任意基本牌使用。",

  ["#fuxun"] = "抚循：交给或获得一名角色一张手牌，若双方手牌数相同，你可以将一张牌当任意基本牌使用",
  ["#fuxun-use"] = "抚循：你可以将一张牌当任意基本牌使用",

  ["$fuxun1"] = "东吴遗民惶惶，宜抚而不宜罚。",
  ["$fuxun2"] = "江东新附，不可以严法度之。",
}

fuxun.zhongliu_type = Player.HistoryPhase

fuxun:addEffect("active", {
  anim_type = "control",
  prompt = "#fuxun",
  min_card_num = 0,
  max_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(fuxun.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
      ((#selected_cards == 0 and not to_select:isKongcheng()) or #selected_cards == 1)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if #effect.cards == 0 then
      local id = room:askToChooseCard(player, {
        target = target,
        flag = "h",
        skill_name = fuxun.name,
      })
      room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, fuxun.name, nil, false, player)
    else
      room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, fuxun.name, nil, false, player)
    end
    if player:getHandcardNum() == target:getHandcardNum() and not player.dead and not player:isNude() then
      if #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.skillName ~= fuxun.name then
            if move.to == target and move.toArea == Card.PlayerHand and #move.moveInfo > 0 then
              return true
            end
            if move.from == target then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand then
                  return true
                end
              end
            end
          end
        end
      end, Player.HistoryPhase) > 0 then return end
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "fuxun_viewas",
        prompt = "#fuxun-use",
        cancelable = true,
        extra_data = {
          bypass_times = true,
        },
      })
      if success and dat then
        local card = Fk:cloneCard(dat.interaction)
        card.skillName = fuxun.name
        card:addSubcards(dat.cards)
        room:useCard{
          from = player,
          tos = dat.targets,
          card = card,
          extraUse = true,
        }
      end
    end
  end,
})

return fuxun
