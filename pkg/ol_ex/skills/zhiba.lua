local zhiba = fk.CreateSkill {
  name = "ol_ex__zhiba",
  tags = { Skill.Lord },
  attached_skill_name = "ol_ex__zhiba_active&",
}

Fk:loadTranslationTable {
  ["ol_ex__zhiba"] = "制霸",
  [":ol_ex__zhiba"] = "主公技，其他吴势力角色的出牌阶段限一次，其可以对你发起拼点，你可以拒绝此拼点。出牌阶段限一次，你可以与一名其他吴势力"..
  "角色拼点。以此法发起的拼点，若其没赢，你可以获得两张拼点牌。",

  ["#ol_ex__zhiba"] = "制霸：你可以与一名吴势力角色拼点，若赢，你可以获得双方拼点牌",
  ["#ol_ex__zhiba-ask"] = "制霸：%src 向你发起拼点！",
  ["#ol_ex__zhiba-prey"] = "制霸：是否获得拼点的两张牌",

  ["$ol_ex__zhiba1"] = "让将军在此恭候多时了。",
  ["$ol_ex__zhiba2"] = "有诸位将军在，此战岂会不胜？",
}

zhiba:addAcquireEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    if p.kingdom == "wu" then
      room:handleAddLoseSkills(p, "ol_ex__zhiba_active&", nil, false, true)
    else
      room:handleAddLoseSkills(p, "-ol_ex__zhiba_active&", nil, false, true)
    end
  end
end)

zhiba:addEffect("active", {
  anim_type = "control",
  prompt = "#ol_ex__zhiba",
  can_use = function(self, player)
    return player:usedSkillTimes(zhiba.name, Player.HistoryPhase) < 1 and not player:isKongcheng()
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      to_select.kingdom == "wu" and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:pindian({target}, zhiba.name)
  end,

  on_acquire = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p ~= player and p.kingdom == "wu" then
        room:handleAddLoseSkills(p, zhiba.attached_skill_name, nil, false, true)
      end
    end
  end
})

zhiba:addEffect(fk.PindianResultConfirmed, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if (data.from == player and (not data.winner or data.winner == player) and data.reason == "ol_ex__zhiba") or
      (data.to == player and (not data.winner or data.winner == player) and data.reason == "ol_ex__zhiba_active&") then
      local room = player.room
      return room:getCardArea(data.fromCard) == Card.Processing or room:getCardArea(data.toCard) == Card.Processing
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    if room:getCardArea(data.fromCard) == Card.Processing then
      table.insert(cards, Card:getIdList(data.fromCard))
    end
    if room:getCardArea(data.toCard) == Card.Processing then
      table.insertIfNeed(cards, Card:getIdList(data.toCard))
    end
    if #cards > 0 and room:askToSkillInvoke(player, {
      skill_name = zhiba.name,
      prompt = "#ol_ex__zhiba-prey",
    }) then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, zhiba.name, nil, true, player)
    end
  end,
})

zhiba:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "wu" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(zhiba.name, true)
    end) then
      room:handleAddLoseSkills(player, "ol_ex__zhiba_active&", nil, false, true)
    else
      room:handleAddLoseSkills(player, "-ol_ex__zhiba_active&", nil, false, true)
    end
  end,
})

return zhiba
