local xingluan = fk.CreateSkill{
  name = "ol__xingluan",
}

Fk:loadTranslationTable{
  ["ol__xingluan"] = "兴乱",
  [":ol__xingluan"] = "你的出牌阶段内限一次，当你使用一张牌结算结束后，你可以选择一项：1.获得场上一张点数为6的牌；2.从牌堆里的两张点数为6的牌中"..
  "选择一张获得（没有则你摸一张牌）；3.令一名其他角色选择弃置一张点数为6的牌或交给你一张牌。",

  ["ol__xingluan_get"] = "获得场上一张点数为6的牌",
  ["ol__xingluan_draw"] = "从牌堆中两张点数为6的牌获得一张",
  ["ol__xingluan_give"] = "令一名角色弃一张点数为6或交给你一张牌",
  ["#ol__xingluan-choose"] = "兴乱：获得一名角色装备区或判定区一张点数为6的牌",
  ["#ol__xingluan-get"] = "兴乱：获得其中一张",
  ["#ol__xingluan-choose2"] = "兴乱：令一名角色选择弃置一张点数为6的牌或交给你一张牌",
  ["#ol__xingluan-discard"] = "兴乱：弃置一张点数为6的牌，否则你须交给 %src 一张牌",
  ["#ol__xingluan-give"] = "兴乱：交给 %src 一张牌",

  ["$ol__xingluan1"] = "大兴兵争，长安当乱。",
  ["$ol__xingluan2"] = "勇猛兴军，乱世当立。",
}

xingluan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingluan.name) and player.phase == Player.Play and
      player:usedSkillTimes(xingluan.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    if table.find(room.alive_players, function (p)
      return table.find(p:getCardIds("ej"), function (id)
        return Fk:getCardById(id).number == 6
      end) ~= nil
    end) then
      table.insert(choices, "ol__xingluan_get")
    end
    table.insert(choices, "ol__xingluan_draw")
    if table.find(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end) then
      table.insert(choices, "ol__xingluan_give")
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xingluan.name,
      all_choices = {"ol__xingluan_get", "ol__xingluan_draw", "ol__xingluan_give", "Cancel"}
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "ol__xingluan_get" then
      local targets = table.filter(room.alive_players, function (p)
        return table.find(p:getCardIds("ej"), function (id)
          return Fk:getCardById(id).number == 6
        end) ~= nil
      end)
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xingluan.name,
        prompt = "#ol__xingluan-choose",
        cancelable = false,
      })[1]
      local cards = table.filter(to:getCardIds("ej"), function(id)
        return Fk:getCardById(id).number == 6
      end)
      local card = room:askToChooseCard(player, {
        target = to,
        flag = { card_data = {{ target.general, cards }} },
        skill_name = xingluan.name,
        prompt = "#ol__xingluan-get",
      })
      room:obtainCard(player, card, true, fk.ReasonPrey, player, xingluan.name)
    elseif choice == "ol__xingluan_draw" then
      local cards = room:getCardsFromPileByRule(".|6", 2)
      if #cards > 0 then
        local card = room:askToChooseCard(player, {
          target = player,
          flag = { card_data = {{ "$Prey", cards }} },
          skill_name = xingluan.name,
          prompt = "#ol__xingluan-get",
        })
        room:obtainCard(player, card, false, fk.ReasonJustMove, player, xingluan.name)
      else
        player:drawCards(1, xingluan.name)
      end
    else
      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xingluan.name,
        prompt = "#ol__xingluan-choose2",
        cancelable = false,
      })[1]
      if #room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xingluan.name,
        pattern = ".|6",
        prompt = "#ol__xingluan-discard:"..player.id,
        cancelable = true,
      }) == 0 then
        local cards = room:askToCards(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = xingluan.name,
          prompt = "#ol__xingluan-give:"..player.id,
          cancelable = false,
        })
        room:obtainCard(player, cards, false, fk.ReasonGive, to, xingluan.name)
      end
    end
  end,
})

return xingluan
