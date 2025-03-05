local zhuosheng = fk.CreateSkill{
  name = "zhuosheng",
}

Fk:loadTranslationTable{
  ["zhuosheng"] = "擢升",
  [":zhuosheng"] = "出牌阶段，当你使用本轮非以本技能获得的牌时，根据类型执行以下效果：基本牌，无距离和次数限制；"..
  "普通锦囊牌，可以令此牌目标+1或-1；装备牌，你可以摸一张牌。",

  ["@@zhuosheng-inhand-round"] = "擢升",
  ["#zhuosheng-choose"] = "擢升：你可以为此%arg增加或减少一个目标",
  ["#zhuosheng-invoke"] = "擢升：你可以摸一张牌",

  ["$zhuosheng1"] = "才经世务，干用之绩。",
  ["$zhuosheng2"] = "器量之远，当至公辅。",
}

zhuosheng:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuosheng.name) and (data.extra_data or {}).zhuosheng and
      data.card:isCommonTrick() and (#data.tos > 1 or #data:getExtraTargets() > 0)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = {}
    if #data.tos > 1 then
      table.insertTable(targets, data.tos)
    end
    table.insertTable(targets, data:getExtraTargets())
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#zhuosheng-choose:::"..data.card:toLogString(),
      skill_name = zhuosheng.name,
      cancelable = true,
      extra_data = table.map(data.tos, Util.IdMapper),
      target_tip_name = "addandcanceltarget_tip",
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    if table.contains(data.tos, to) then
      data:removeTarget(to)
    else
      data:addTarget(to)
    end
  end,
})
zhuosheng:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuosheng.name) and (data.extra_data or {}).zhuosheng and
    data.card.type == Card.TypeEquip
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhuosheng.name,
      prompt = "#zhuosheng-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, zhuosheng.name)
  end,
})
zhuosheng:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuosheng.name) and player.phase == Player.Play and
      data.card:getMark("@@zhuosheng-inhand-round") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.zhuosheng = true
    if data.card.type == Card.TypeBasic then
      data.extraUse = true
    end
  end,
})
zhuosheng:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(zhuosheng.name) and player.phase == Player.Play and card and
      card.type == Card.TypeBasic and card:getMark("@@zhuosheng-inhand-round") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(zhuosheng.name) and player.phase == Player.Play and card and
      card.type == Card.TypeBasic and card:getMark("@@zhuosheng-inhand-round") > 0
  end,
})
zhuosheng:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(zhuosheng.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand and move.skillName ~= zhuosheng.name then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@zhuosheng-inhand-round", 1)
          end
        end
      end
    end
  end,
})

return zhuosheng
