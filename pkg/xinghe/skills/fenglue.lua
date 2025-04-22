local fenglue = fk.CreateSkill{
  name = "fenglue",
}

Fk:loadTranslationTable{
  ["fenglue"] = "锋略",
  [":fenglue"] = "出牌阶段开始时，你可以与一名角色拼点：若你赢，该角色将每个区域内各一张牌交给你；若你没赢，你交给其一张牌。"..
  "你与其他角色的拼点结果确定后，你可以将你的拼点牌交给该角色。",

  ["#fenglue-choose"] = "锋略：你可以拼点，若赢，其交给你每个区域各一张牌；没赢，你交给其一张牌",
  ["#fenglue-ask"] = "锋略：请交给 %dest 一张牌",
  ["#fenglue-give"] = "锋略：你可以将你的拼点牌交给 %dest",

  ["$fenglue1"] = "汝能比得上我家主公吗？",
  ["$fenglue2"] = "将军有让贤之名而身安于泰山也，实乃上策。",
}

local U = require "packages/utility/utility"

fenglue:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fenglue.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = fenglue.name,
      prompt = "#fenglue-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({to}, fenglue.name)
    if player.dead or to.dead then return end
    if pindian.results[to].winner == player then
      if to:isAllNude() then return end
      local cards = U.askforCardsChosenFromAreas(to, to, "hej", fenglue.name, nil, nil, false)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, fenglue.name, nil, false, to)
    else
      if player:isNude() then return end
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = fenglue.name,
        prompt = "#fenglue-ask::"..to.id,
        cancelable = true,
      })
      room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, fenglue.name, nil, false, player)
    end
  end,
})
fenglue:addEffect(fk.PindianResultConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fenglue.name) then
      if data.from == player then
        return player.room:getCardArea(data.fromCard) == Card.Processing and not data.to.dead
      elseif data.to == player then
        return player.room:getCardArea(data.toCard) == Card.Processing and not data.from.dead
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = player == data.from and data.to or data.from
    local cards = player == data.from and data.fromCard or data.toCard
    if room:askToSkillInvoke(player, {
      skill_name = fenglue.name,
      prompt = "#fenglue-give::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards
    room:obtainCard(to, cards, true, fk.ReasonGive, player, fenglue.name)
  end,
})

return fenglue
