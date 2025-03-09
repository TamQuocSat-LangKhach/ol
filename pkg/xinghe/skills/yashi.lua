local yashi = fk.CreateSkill{
  name = "yashi",
}

Fk:loadTranslationTable{
  ["yashi"] = "雅士",
  [":yashi"] = "当你受到伤害后，你可以选择一项：1.令伤害来源的非锁定技无效直到其下个回合开始；2.对一名其他角色发动一次〖观虚〗。",

  ["yashi_invalidity"] = "令%dest的非锁定技失效直到其下个回合开始",
  ["yashi_guanxu"] = "对一名其他角色发动一次〖观虚〗",
  ["@@yashi"] = "雅士",

  ["$yashi1"] = "德行贞绝者，谓其雅士。",
  ["$yashi2"] = "鸿儒雅士，闻见多矣。",
}

yashi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yashi.name) and
      ((data.from and not data.from.dead) or
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end))
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if table.find(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng()
    end) then
      table.insert(choices, 1, "yashi_guanxu")
    end
    if data.from and not data.from.dead then
      table.insert(choices, 1, "yashi_invalidity::"..data.from.id)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = yashi.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = choice ~= "yashi_guanxu" and {data.from} or {}, choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "yashi_guanxu" then
      room:askToUseActiveSkill(player, {
        skill_name = "guanxu",
        prompt = "#guanxu",
        cancelable = false,
        no_indicate = false,
      })
    else
      room:setPlayerMark(data.from, "@@yashi", 1)
    end
  end,
})
yashi:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@yashi") > 0 and skill:isPlayerSkill(from) and not skill:hasTag(Skill.Compulsory)
  end,
})
yashi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yashi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yashi", 0)
  end,
})

return yashi
