local saogu = fk.CreateSkill{
  name = "saogu",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["saogu"] = "扫谷",
  [":saogu"] = "转换技，出牌阶段，你可以：阳，弃置两张牌（不能包含你本阶段弃置过的花色），使用其中的【杀】；阴，摸一张牌。"..
  "结束阶段，你可以弃置一张牌，令一名其他角色执行当前项。",

  ["#saogu-yang"] = "扫谷：弃两张牌，你可以使用其中的【杀】",
  ["#saogu-yin"] = "扫谷：你可以摸一张牌",
  ["@saogu-phase"] = "扫谷",
  ["#saogu-choose"] = "扫谷：你可以弃置一张牌，令一名其他角色执行“扫谷”当前项",
  ["#saogu-use"] = "扫谷：你可以使用其中的【杀】",

  ["$saogu1"] = "大汉铁骑，必昭卫霍遗风于当年。",
  ["$saogu2"] = "笑驱百蛮，试问谁敢牧马于中原！",
}

local U = require "packages/utility/utility"

local function DoSaogu(player, ids)
  local room = player.room
  ids = table.filter(ids, function (id)
    return table.contains(room.discard_pile, id) and Fk:getCardById(id).trueName == "slash"
  end)
  while not player.dead do
    ids = table.filter(ids, function (id)
      return table.contains(room.discard_pile, id)
    end)
    if #ids == 0 then return end
    local use = room:askToUseRealCard(player, {
      pattern = ids,
      skill_name = saogu.name,
      prompt = "#saogu-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = ids,
      },
      skip = true,
    })
    if use then
      table.removeOne(ids, use.card:getEffectiveId())
      room:useCard(use)
    else
      break
    end
  end
end

saogu:addEffect("active", {
  anim_type = "switch",
  card_num = function(self, player)
    if player:getSwitchSkillState(saogu.name, false) == fk.SwitchYang then
      return 2
    else
      return 0
    end
  end,
  target_num = 0,
  prompt = function(self, player)
    if player:getSwitchSkillState(saogu.name, false) == fk.SwitchYang then
      return "#saogu-yang"
    else
      return "#saogu-yin"
    end
  end,
  can_use = function(self, player)
    return player:getSwitchSkillState(saogu.name, false) == fk.SwitchYin or #player:getTableMark("@saogu-phase") < 4
  end,
  card_filter = function(self, player, to_select, selected)
    if player:getSwitchSkillState(saogu.name, false) == fk.SwitchYang and #selected < 2 and not player:prohibitDiscard(to_select) then
      local card = Fk:getCardById(to_select)
      return card.suit ~= Card.NoSuit and not table.contains(player:getTableMark("@saogu-phase"), card:getSuitString(true))
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player:getSwitchSkillState(saogu.name, true) == fk.SwitchYang then
      room:throwCard(effect.cards, "saogu", player, player)
      DoSaogu(player, effect.cards)
    else
      player:drawCards(1, saogu.name)
    end
  end,
})
saogu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(saogu.name) and player.phase == Player.Finish and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    if player:getSwitchSkillState(saogu.name, false) == fk.SwitchYang then
      targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
    else
      targets = room:getOtherPlayers(player, false)
    end
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = saogu.name,
      prompt = "#saogu-choose",
      cancelable = true,
      will_throw = true,
    })
    if #to > 0 and #cards == 1 then
      event:setCostData(self, {tos = to, cards = cards, choice = player:getSwitchSkillState(saogu.name, false, true)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:throwCard(event:getCostData(self).cards, saogu.name, player, player)
    if not to.dead then
      if event:getCostData(self).choice == "yang" then
        local suits = {"spade", "heart", "club", "diamond"}
        for _, suit in ipairs(player:getTableMark("@saogu-phase")) do
          table.removeOne(suits, U.ConvertSuit(suit, "sym", "str"))
        end
        local cards = room:askToDiscard(to, {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = saogu.name,
          pattern = ".|.|"..table.concat(suits, ","),
          cancelable = false,
          prompt = "#saogu-yang",
        })
        if #cards > 0 then
          DoSaogu(to, cards)
        end
      else
        to:drawCards(1, saogu.name)
      end
    end
  end,
})

saogu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(saogu.name, true) and
      (player.phase == Player.Play or player.phase == Player.Finish)
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          local suit = Fk:getCardById(info.cardId):getSuitString(true)
          if suit ~= "log_nosuit" then
            player.room:addTableMarkIfNeed(player, "@saogu-phase", suit)
          end
        end
      end
    end
  end,
})

saogu:addAcquireEffect(function (self, player, is_start)
  if player.phase == Player.Play or player.phase == Player.Finish then
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            local suit = Fk:getCardById(info.cardId):getSuitString(true)
            if suit ~= "log_nosuit" then
              player.room:addTableMarkIfNeed(player, "@saogu-phase", suit)
            end
          end
        end
      end
    end, Player.HistoryPhase)
  end
end)

return saogu
