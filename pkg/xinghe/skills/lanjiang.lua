local lanjiang = fk.CreateSkill{
  name = "lanjiang",
}

Fk:loadTranslationTable{
  ["lanjiang"] = "澜疆",
  [":lanjiang"] = "结束阶段，你可以令所有手牌数不小于你的角色依次选择是否令你摸一张牌。选择完成后，你可以对手牌数等于你的其中一名角色造成1点伤害，"..
  "然后令手牌数小于你的其中一名角色摸一张牌。",

  ["#lanjiang-choice"] = "澜疆：是否令 %dest 摸一张牌？",
  ["#lanjiang-damage"] = "澜疆：你可以对其中一名角色造成1点伤害",
  ["#lanjiang-draw"] = "澜疆：你可以令其中一名角色摸一张牌",

  ["$lanjiang1"] = "一人擒虎力，千军拗锋芒。",
  ["$lanjiang2"] = "勇力擎四疆，狂澜涌八荒。",
}

lanjiang:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lanjiang.name) and player.phase == Player.Finish
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = lanjiang.name,
    }) then
      local tos = table.filter(room:getAlivePlayers(), function (p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    for _, p in ipairs(targets) do
      if not p.dead then
        if room:askToSkillInvoke(p, {
          skill_name = lanjiang.name,
          prompt = "#lanjiang-choice::"..player.id,
        }) then
          player:drawCards(1, lanjiang.name)
          if player.dead then return end
        end
      end
    end
    local targets1 = table.filter(targets, function(p)
      return not p.dead and p:getHandcardNum() == player:getHandcardNum()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets1,
      skill_name = lanjiang.name,
      prompt = "#lanjiang-damage",
      cancelable = true,
    })
    if #to > 0 then
      room:damage{
        from = player,
        to = to[1],
        damage = 1,
        skillName = lanjiang.name,
      }
      if player.dead then return end
    end
    targets1 = table.filter(targets, function(p)
      return not p.dead and p:getHandcardNum() < player:getHandcardNum()
    end)
    if #targets1 > 0 then
      to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets1,
        skill_name = lanjiang.name,
        prompt = "#lanjiang-draw",
        cancelable = true,
      })
      if #to > 0 then
        to[1]:drawCards(1, lanjiang.name)
      end
    end
  end,
})

return lanjiang
