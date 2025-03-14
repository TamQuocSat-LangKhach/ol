local zhongjian = fk.CreateSkill{
  name = "ol__zhongjian",
}

Fk:loadTranslationTable{
  ["ol__zhongjian"] = "忠鉴",
  [":ol__zhongjian"] = "出牌阶段限一次，你可以展示一张手牌，并展示一名其他角色的X张手牌（X为其体力值）。若其以此法展示的牌与你展示的牌中："..
  "有颜色相同，你摸一张牌或弃置一名其他角色的一张牌；有点数相同，本回合此技能改为“出牌阶段限两次”；均不同，你的手牌上限-1。",

  ["#ol__zhongjian"] = "忠鉴：展示一张手牌，并展示一名角色其体力值张数的手牌",
  ["#ol__zhongjian-choose"] = "忠鉴：弃置一名其他角色一张牌，或点“取消”摸一张牌",

  ["$ol__zhongjian1"] = "野心昭著者，虽女子亦能知晓。",
  ["$ol__zhongjian2"] = "慧眼识英才，明智辨忠奸。",
}

zhongjian:addEffect("active", {
  prompt = "#ol__zhongjian",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhongjian.name, Player.HistoryPhase) < (1 + player:getMark("ol__zhongjian_times-turn"))
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and #selected_cards == 1 and
      to_select.hp > 0 and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:showCards(effect.cards)
    local n = math.min(target:getHandcardNum(), target.hp)
    if player.dead or target.dead or n == 0 then return end
    local cards = room:askToChooseCards(player, {
      target = target,
      min = n,
      max = n,
      flag = "h",
      skill_name = zhongjian.name,
    })
    target:showCards(cards)
    if player.dead then return end
    local yes = false
    if table.find(cards, function(id)
      return Fk:getCardById(id).number == Fk:getCardById(effect.cards[1]).number
    end) then
      yes = true
      room:setPlayerMark(player, "ol__zhongjian_times-turn", 1)
    end
    if table.find(cards, function(id)
      return Fk:getCardById(id).color == Fk:getCardById(effect.cards[1]).color
    end) then
      yes = true
      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = zhongjian.name,
          prompt = "#ol__zhongjian-choose",
          cancelable = true,
        })
        if #to > 0 then
          local id = room:askToChooseCard(player, {
            target = to[1],
            flag = "he",
            skill_name = zhongjian.name,
          })
          room:throwCard(id, zhongjian.name, to[1], player)
          return
        else
          player:drawCards(1, zhongjian.name)
        end
      else
        player:drawCards(1, zhongjian.name)
      end
    end
    if not yes and player:getMaxCards() > 0 and not player.dead then
      room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
    end
  end,
})

return zhongjian
