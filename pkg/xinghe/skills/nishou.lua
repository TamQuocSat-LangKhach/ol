local nishou = fk.CreateSkill{
  name = "nishou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["nishou"] = "泥首",
  [":nishou"] = "锁定技，当你装备区里的牌进入弃牌堆后，你选择一项：1.将此牌当【闪电】使用；"..
  "2.本阶段结束时，你与一名全场手牌数最少的角色交换手牌且本阶段内你无法选择此项。",

  ["#nishou-choice"] = "泥首：选择将%arg当做【闪电】使用，或在本阶段结束时与手牌数最少的角色交换手牌",
  ["nishou_lightning"] = "将此装备牌当【闪电】使用",
  ["nishou_exchange"] = "本阶段结束时与手牌数最少的角色交换手牌",
  ["@@nishou_exchange-phase"] = "泥首",
  ["#nishou-choose"] = "泥首：与一名手牌数最少的角色交换手牌",

  ["$nishou1"] = "臣以泥涂首，足证本心。",
  ["$nishou2"] = "人生百年，终埋一抔黄土。",
}

local nishouFilter = function(player, id)
  local room = player.room
  local choices = {}
  if player:getMark("@@nishou_exchange-phase") == 0 then
    local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
    if phase_event ~= nil then
      table.insert(choices, "nishou_exchange")
    end
  end
  if table.contains(room.discard_pile, id) then
    local card = Fk:cloneCard("lightning")
    card:addSubcard(id)
    card.skillName = nishou.name
    if player:canUseTo(card, player) then
      table.insert(choices, "nishou_lightning")
    end
  else
    return {}
  end
  return choices
end

nishou:addEffect(fk.AfterCardsMove, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(nishou.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              if #nishouFilter(player, info.cardId) > 0 then
                event:setCostData(self, {cards = {info.cardId}})
                return true
              else
                return false
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    local choices = nishouFilter(player, id)
    if #choices == 0 then return false end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = nishou.name,
      prompt = "#nishou-choice:::"..Fk:getCardById(id):toLogString(),
    })
    if choice == "nishou_lightning" then
      local card = Fk:cloneCard("lightning")
      card:addSubcard(id)
      card.skillName = nishou.name
      room:useCard{
        from = player,
        tos = {player},
        card = card,
      }
    else
      room:setPlayerMark(player, "@@nishou_exchange-phase", 1)
    end
  end,
})
nishou:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@nishou_exchange-phase") > 0 and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return table.every(room.alive_players, function (q)
        return p:getHandcardNum() <= q:getHandcardNum()
      end)
    end)
    local to = targets[1]
    if #targets > 1 then
      to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = nishou.name,
        prompt = "#nishou-choose",
        cancelable = false,
      })[1]
    end
    if to ~= player then
      room:swapAllCards(player, {player, to}, nishou.name)
    end
  end,
})

return nishou
