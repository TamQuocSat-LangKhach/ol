local weishu = fk.CreateSkill{
  name = "weishu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["weishu"] = "卫戍",
  [":weishu"] = "锁定技，你于摸牌阶段外因摸牌且并非因此技能而得到牌后，你令一名角色摸一张牌；"..
  "你于弃牌阶段外因弃置而失去牌后，你弃置一名其他角色的一张牌。",

  ["#weishu-draw"] = "卫戍：令一名角色摸一张牌",
  ["#weishu-discard"] = "卫戍：弃置一名其他角色的一张牌",

  ["$weishu1"] = "水来土掩，兵来将挡。",
  ["$weishu2"] = "吴人来犯，当用心戒备。",
}

weishu:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(weishu.name) then
      local draw, discard = false, false
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw and
          move.skillName ~= weishu.name and player.phase ~= Player.Draw then
          draw = true
        end
        if move.from == player and move.moveReason == fk.ReasonDiscard and player.phase ~= Player.Discard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              discard = true
              break
            end
          end
        end
      end
      local choices = {}
      if draw then
        table.insert(choices, "drawcard")
      end
      if discard and table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end) then
        table.insert(choices, "discard")
      end
      if #choices > 0 then
        event:setCostData(self, {extra_data = choices})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).extra_data
    local drawcard, discard = table.contains(choices, "drawcard"), table.contains(choices, "discard")
    if drawcard then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = weishu.name,
        prompt = "#weishu-draw",
        cancelable = false,
      })[1]
      to:drawCards(1, weishu.name)
      if player.dead then return end
    end
    if discard then
      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = weishu.name,
          prompt = "#weishu-discard",
          cancelable = false,
        })[1]
        local id = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = weishu.name,
        })
        room:throwCard(id, weishu.name, to, player)
      end
    end
  end,
})

return weishu
