
local guzheng = fk.CreateSkill {
  name = "ol_ex__guzheng",
}

Fk:loadTranslationTable{
  ["ol_ex__guzheng"] = "固政",
  [":ol_ex__guzheng"] = "每阶段限一次，当其他角色的至少两张牌因弃置而置入弃牌堆后，你可以令其获得其中一张牌，然后你可以获得剩余牌。",

  ["#ol_ex__guzheng-invoke"] = "固政：你可以令%dest获得其此次弃置的牌中的一张，然后你获得剩余牌",
  ["#ol_ex__guzheng-choose"] = "固政：你可以令一名角色获得其此次弃置的牌中的一张，然后你获得剩余牌",
  ["#guzheng-title"] = "固政：选择一张牌还给 %dest",
  ["guzheng_yes"] = "确定，获得剩余牌",
  ["guzheng_no"] = "确定，不获得剩余牌",

  ["$ol_ex__guzheng1"] = "兴国为任，可驱百里之行。",
  ["$ol_ex__guzheng2"] = "固政之责，在君亦在臣。",
}

local U = require("packages/utility/utility")

guzheng:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(guzheng.name) and player:usedSkillTimes(guzheng.name, Player.HistoryPhase) < 1 then
      local room = player.room
      local currentplayer = room.current
      if currentplayer and currentplayer.phase <= Player.Finish and currentplayer.phase >= Player.Start then
        local guzheng_pairs = {}
        for _, move in ipairs(data) do
          if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.from and move.from ~= player then
            local guzheng_value = guzheng_pairs[move.from] or {}
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.insert(guzheng_value, info.cardId)
              end
            end
            guzheng_pairs[move.from] = guzheng_value
          end
        end
        local guzheng_data, ids = {{}, {}}, {}
        for key, value in pairs(guzheng_pairs) do
          if not key.dead and #value > 1 then
            ids = U.moveCardsHoldingAreaCheck(room, table.filter(value, function (id)
              return room:getCardArea(id) == Card.DiscardPile
            end))
            if #ids > 0 then
              table.insert(guzheng_data[1], key)
              table.insert(guzheng_data[2], ids)
            end
          end
        end
        if #guzheng_data[1] > 0 then
          event:setCostData(self, {extra_data = guzheng_data})
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).extra_data[1]
    local card_pack = event:getCostData(self).extra_data[2]
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = guzheng.name,
        prompt = "#ol_ex__guzheng-invoke::"..targets[1].id,
      }) then
        event:setCostData(self, {tos = targets, cards = card_pack[1]})
        return true
      end
    elseif #targets > 1 then
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ol_ex__guzheng-choose",
        skill_name = guzheng.name,
      })
      if #tos > 0 then
        event:setCostData(self, {tos = tos, cards = card_pack[table.indexOf(targets, tos[1])]})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards
    local to_return = table.random(cards, 1)
    local choice = "guzheng_no"
    if #cards > 1 then
      to_return, choice = U.askforChooseCardsAndChoice(player, cards, {"guzheng_yes", "guzheng_no"}, guzheng.name,
      "#guzheng-title::" .. to.id)
    end
    local moveInfos = {}
    table.insert(moveInfos, {
      ids = to_return,
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = player,
      skillName = guzheng.name,
    })
    table.removeOne(cards, to_return[1])
    if choice == "guzheng_yes" and #cards > 0 then
      table.insert(moveInfos, {
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = guzheng.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
  end,
})

return guzheng
