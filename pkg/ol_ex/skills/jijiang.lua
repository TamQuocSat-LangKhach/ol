local this = fk.CreateSkill {
  name = "ol_ex__jijiang$",
}

this:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if #cards ~= 0 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = this.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    if use.tos then
      room:doIndicate(player.id, table.map(use.tos, Util.IdMapper))
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "shu" and p:isAlive() then
        local cardResponded = room:askToResponse(p, { pattern = "slash", prompt = "#jijiang-ask:" .. player.id, cancelable = true})
        if cardResponded then
          room:responseCard({
            from = p.id,
            card = cardResponded,
            skipDrop = true,
          })
          use.card = cardResponded
          return
        end
      end
    end
    room:setPlayerMark(player, "jijiang-failed-phase", 1)
    return this.name
  end,
  enabled_at_play = function(self, player)
    return player:getMark("jijiang-failed-phase") == 0 and table.every(Fk:currentRoom().alive_players, function(p)
      return p == player or p.kingdom ~= "shu"
    end)
  end,
  enabled_at_response = function(self, player)
    return not table.every(Fk:currentRoom().alive_players, function(p)
      return p == player or p.kingdom ~= "shu"
    end)
  end,
})

local jijiang_trigger = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return data.card.trueName == "slash" and target ~= player and player:hasSkill(jijiang)
    and target.kingdom == "shu" and target ~= player.room.current
    and player:getMark("ol_ex__jijiang_draw-turn") == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(target, this.name, nil, "#ol_ex__jijiang-invoke:"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ol_ex__jijiang_draw-turn", 1)
    player:drawCards(1, "ol_ex__jijiang")
  end,
}

this:addEffect(fk.CardUsing, jijiang_trigger)
this:addEffect(fk.CardResponding, jijiang_trigger)

Fk:loadTranslationTable {
  ["ol_ex__jijiang"] = "激将",
  [":ol_ex__jijiang"] = "主公技，①当你需要使用或打出【杀】时，你可以令其他蜀势力角色选择是否打出一张【杀】（视为由你使用或打出）；②每回合限一次，其他蜀势力角色于其回合外使用或打出【杀】时，可令你摸一张牌。",
  
  ["#ol_ex__jijiang-invoke"] = "激将：s可以令 %src 摸一张牌",

  ["$ol_ex__jijiang_ol_ex__liushan1"] = "爱卿爱卿，快来护驾！",
  ["$ol_ex__jijiang_ol_ex__liushan2"] = "将军快替我，拦下此贼！",
}

return this