local jijiang = fk.CreateSkill {
  name = "ol_ex__jijiang",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable {
  ["ol_ex__jijiang"] = "激将",
  [":ol_ex__jijiang"] = "主公技，当你需要使用或打出【杀】时，你可以令其他蜀势力角色选择是否打出一张【杀】（视为由你使用或打出）；"..
  "每回合限一次，其他蜀势力角色于其回合外使用或打出【杀】时，可令你摸一张牌。",

  ["#ol_ex__jijiang-invoke"] = "激将：是否令 %src 摸一张牌？",

  ["$ol_ex__jijiang_ol_ex__liushan1"] = "爱卿爱卿，快来护驾！",
  ["$ol_ex__jijiang_ol_ex__liushan2"] = "将军快替我，拦下此贼！",
}

jijiang:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if #cards ~= 0 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = jijiang.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    if #use.tos > 0 then
      room:doIndicate(player, use.tos)
    end

    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "shu" then
        local respond = room:askToResponse(p, {
          skill_name = jijiang.name,
          pattern = "slash",
          prompt = "#jijiang-ask:"..player.id,
          cancelable = true,
        })
        if respond then
          respond.skipDrop = true
          room:responseCard(respond)

          use.card = respond.card
          return
        end
      end
    end

    room:setPlayerMark(player, "jijiang_failed-phase", 1)
    return jijiang.name
  end,
  enabled_at_play = function(self, player)
    return player:getMark("jijiang_failed-phase") == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p.kingdom == "shu" and p ~= player
      end)
  end,
  enabled_at_response = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p.kingdom == "shu" and p ~= player
    end)
  end,
})

local jijiang_spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jijiang.name) and data.card.trueName == "slash" and target ~= player and
      target.kingdom == "shu" and target ~= player.room.current and not target.dead and
      player:getMark("ol_ex__jijiang_draw-turn") == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = jijiang.name,
      prompt = "#ol_ex__jijiang-invoke:"..player.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ol_ex__jijiang_draw-turn", 1)
    player:drawCards(1, jijiang.name)
  end,
}

jijiang:addEffect(fk.CardUsing, jijiang_spec)
jijiang:addEffect(fk.CardResponding, jijiang_spec)

return jijiang