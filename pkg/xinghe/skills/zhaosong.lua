local zhaosong = fk.CreateSkill{
  name = "zhaosong",
}

Fk:loadTranslationTable{
  ["zhaosong"] = "诏颂",
  [":zhaosong"] = "其他角色摸牌阶段结束时，若其没有标记，你可以令其正面向上交给你一张手牌，根据此牌的类型，该角色获得对应的标记："..
  "锦囊牌-“诔”标记；装备牌-“赋”标记；基本牌-“颂”标记。拥有标记的角色：<br>"..
  "进入濒死状态时，可弃置“诔”，回复体力至1点，摸一张牌；<br>"..
  "出牌阶段开始时，可弃置“赋”，弃置一名角色区域内的至多两张牌；<br>"..
  "使用【杀】仅指定一个目标时，可弃置“颂”，为此【杀】额外选择至多两个目标。",

  ["#zhaosong-invoke"] = "诏颂：你可以令 %dest 交给你一张手牌，根据牌的类别其获得效果",
  ["#zhaosong-give"] = "诏颂：交给 %src 一张手牌，根据类别你获得效果<br>"..
  "锦囊-濒死时回复体力并摸牌；装备-弃置一名角色两张牌；基本-使用【杀】可额外指定两个目标",
  ["@@zuofen_lei"] = "诔",
  ["@@zuofen_fu"] = "赋",
  ["@@zuofen_song"] = "颂",
  ["#zhaosong1-invoke"] = "诏颂：你可以弃置“诔”，回复体力至1点并摸一张牌",
  ["#zhaosong2-invoke"] = "诏颂：你可以弃置“赋”，弃置一名角色区域内至多两张牌",
  ["#zhaosong3-invoke"] = "诏颂：你可以弃置“颂”，额外选择至多两个目标",

  ["$zhaosong1"] = "领诏者，可上而颂之。",
  ["$zhaosong2"] = "今为诏，以上告下也。",
}

zhaosong:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhaosong.name) and target ~= player and target.phase == Player.Draw and
      not target:isKongcheng() and not target.dead and
      target:getMark("@@zuofen_lei") + target:getMark("@@zuofen_fu") + target:getMark("@@zuofen_song") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhaosong.name,
      prompt = "#zhaosong-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhaosong.name,
      prompt = "#zhaosong-give:"..player.id,
      cancelable = false,
    })
    local card = Fk:getCardById(cards[1])
    room:obtainCard(player, cards, false, fk.ReasonGive, target, zhaosong.name)
    if target.dead then return false end
    local mark
    if card.type == Card.TypeTrick then
      mark = "@@zuofen_lei"
    elseif card.type == Card.TypeEquip then
      mark = "@@zuofen_fu"
    elseif card.type == Card.TypeBasic then
      mark = "@@zuofen_song"
    end
    room:addPlayerMark(target, mark, 1)
  end,
})
zhaosong:addEffect(fk.EnterDying, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("@@zuofen_lei") > 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhaosong.name,
      prompt = "#zhaosong1-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@@zuofen_lei", 1)
    if player.hp < 1 then
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = zhaosong.name
      }
    end
    if not player.dead then
      target:drawCards(1, zhaosong.name)
    end
  end,
})
zhaosong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("@@zuofen_fu") > 0 and player.phase == Player.Play and
      table.find(player.room.alive_players, function (p)
        return not p:isAllNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isAllNude()
    end)
    if table.contains(targets, player) and
      not table.find(player:getCardIds("hej"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      table.removeOne(targets, player)
    end
    if #targets == 0 then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = zhaosong.name,
        pattern = "false",
        prompt = "#zhaosong2-invoke",
        cancelable = true,
      })
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = zhaosong.name,
        prompt = "#zhaosong2-invoke",
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@@zuofen_fu", 1)
    local to = event:getCostData(self).tos[1]
    local cards = {}
    if to == player then
      local ids = table.filter(player:getCardIds("hej"), function (id)
        return not player:prohibitDiscard(id)
      end)
      cards = room:askToCards(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = zhaosong.name,
        pattern = tostring(Exppattern{ id = ids }),
        cancelable = false,
        expand_pile = player:getCardIds("j"),
      })
    else
      cards = room:askToChooseCards(player, {
        target = to,
        min = 2,
        max = 2,
        flag = "hej",
        skill_name = zhaosong.name,
      })
    end
    room:throwCard(cards, zhaosong.name, to, player)
  end,
})
zhaosong:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@zuofen_song") > 0 and data.card.trueName == "slash" and
      data:isOnlyTarget(data.tos[1]) and #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 2,
      targets = data:getExtraTargets(),
      skill_name = zhaosong.name,
      prompt = "#zhaosong3-invoke",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

return zhaosong
