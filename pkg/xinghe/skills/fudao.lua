local fudao = fk.CreateSkill{
  name = "ol__fudao",
}

Fk:loadTranslationTable{
  ["ol__fudao"] = "抚悼",
  [":ol__fudao"] = "游戏开始时，你摸三张牌，交给一名其他角色至多三张手牌，弃置任意张手牌，然后记录你的手牌数。每回合结束时，"..
  "若当前回合角色的手牌数为此数值，你可以与其各摸一张牌。",

  ["#ol__fudao-give"] = "抚悼：你可以交给一名其他角色至多三张牌",
  ["#ol__fudao-discard"] = "抚悼：你可以弃置任意张手牌",
  ["@ol__fudao"] = "抚悼",
  ["#ol__fudao-invoke"] = "抚悼：你可以与 %dest 各摸一张牌",

  ["$ol__fudao1"] = "冰刃入腹，使肝肠寸断。",
  ["$ol__fudao2"] = "失子之殇，世间再无春秋。",
}

fudao:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@ol__fudao", 0)
end)

fudao:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fudao.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, fudao.name)
    if player.dead then return end
    if not player:isKongcheng() and #room:getOtherPlayers(player, false) > 0 then
      local tos, cards = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 3,
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = fudao.name,
        prompt = "#ol__fudao-give",
        cancelable = true,
      })
      if #tos > 0 then
        room:moveCardTo(cards, Card.PlayerHand, tos[1], fk.ReasonGive, fudao.name, nil, false, player)
        if player.dead then return end
      end
    end
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = fudao.name,
      prompt = "#ol__fudao-discard",
      cancelable = true,
    })
    if player.dead then return end
    room:setPlayerMark(player, "@ol__fudao", tostring(player:getHandcardNum()))
  end,
})
fudao:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fudao.name) and not target.dead and
      player:getMark("@ol__fudao") ~= 0 and tonumber(player:getMark("@ol__fudao")) == target:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = fudao.name,
      prompt = "#ol__fudao-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, fudao.name)
    if not player.dead then
      player:drawCards(1, fudao.name)
    end
  end,
})

return fudao
