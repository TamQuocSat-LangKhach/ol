local this = fk.CreateSkill {
  name = "zhiba"
}

this:addEffect("active", {
  anim_type = "control",
  prompt = "#ol_ex__zhiba-active",
  can_use = function(self, player)
    return player:usedSkillTimes(this.name, Player.HistoryPhase) < 1 and not player:isKongcheng()
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and to_select ~= player.id then
      return to_select.kingdom == "wu" and player:canPindian(to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:pindian({target}, this.name)
  end,

  on_acquire = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p ~= player and p.kingdom == "wu" then
        room:handleAddLoseSkills(p, this.attached_skill_name, nil, false, true)
      end
    end
  end
})

this:addEffect(fk.PindianResultConfirmed, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if (data.from == player and (not data.winner or data.winner == player) and data.reason == "ol_ex__zhiba") or
      (data.to == player and (not data.winner or data.winner == player) and data.reason == "ol_ex__zhiba_other&") then
      local room = player.room
      return room:getCardArea(data.fromCard) == Card.Processing or room:getCardArea(data.toCard) == Card.Processing
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local id = data.fromCard:getEffectiveId()
    if room:getCardArea(id) == Card.Processing then
      table.insert(cards, id)
    end
    id = data.toCard:getEffectiveId()
    if room:getCardArea(id) == Card.Processing then
      table.insertIfNeed(cards, id)
    end
    if #cards > 1 and room:askToChoice(player, { choices = {"ol_ex__zhiba_obtain", "ol_ex__zhiba_cancel"}, skill_name = this.name, prompt = "#ol_ex__zhiba-obtain"}) == "ol_ex__zhiba_obtain" then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        skillName = this.name,
        proposer = player.id,
      })
    end
  end,
})

this:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "wu" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(this, true)
    end) then
      room:handleAddLoseSkills(player, "ol_ex__zhiba_other&", nil, false, true)
    else
      room:handleAddLoseSkills(player, "-ol_ex__zhiba_other&", nil, false, true)
    end
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__zhiba"] = "制霸",
  [":ol_ex__zhiba"] = "主公技，其他吴势力角色的出牌阶段限一次，其可以对你发起拼点，你可以拒绝此拼点。出牌阶段限一次，你可以与一名其他吴势力角色拼点。以此法发起的拼点，若其没赢，你可以获得两张拼点牌。",

  ["#ol_ex__zhiba-active"] = "你是否想要发动“制霸”，与一名吴势力角色拼点？",
  ["#ol_ex__zhiba-ask"] = "制霸：%src 向你发起拼点！",
  ["ol_ex__zhiba_accept"] = "接受拼点",
  ["ol_ex__zhiba_refuse"] = "拒绝拼点",
  ["#ol_ex__zhiba-obtain"] = "制霸：是否获得拼点的两张牌",
  ["ol_ex__zhiba_obtain"] = "获得拼点牌",
  ["ol_ex__zhiba_cancel"] = "取消",
  
  ["$ol_ex__zhiba1"] = "让将军在此恭候多时了。",
  ["$ol_ex__zhiba2"] = "有诸位将军在，此战岂会不胜？",
}

return this
