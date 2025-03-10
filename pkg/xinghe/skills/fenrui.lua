local fenrui = fk.CreateSkill{
  name = "fenrui",
}

Fk:loadTranslationTable{
  ["fenrui"] = "奋锐",
  [":fenrui"] = "结束阶段，你可以弃置一张牌并复原一个装备栏，从牌堆或弃牌堆随机使用一张对应的装备牌，然后每局游戏限一次，你可以对一名装备区牌数小于"..
  "你的角色造成X点伤害（X为你与其装备区牌数之差）。",

  ["#fenrui-invoke"] = "奋锐：你可以弃置一张牌恢复一个装备栏，随机使用一张对应的装备牌",
  ["@@fenrui"] = "已奋锐",
  ["#fenrui-choose"] = "奋锐：你可以对一名装备少于你的角色造成你与其装备数之差的伤害！（每局限一次）",

  ["$fenrui1"] = "待其疲敝，则可一击破之。",
  ["$fenrui2"] = "覆军斩将，便在旦夕之间。",
}

fenrui:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isNude() and
      #player.sealedSlots > 0 and not table.every(player.sealedSlots, function (slot)
        return slot == Player.JudgeSlot
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "fenrui_active",
      prompt = "#fenrui-invoke",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, fenrui.name, player, player)
    if player.dead then return end
    local choice = event:getCostData(self).choice
    room:resumePlayerArea(player, choice)
    local sub_type = Util.convertSubtypeAndEquipSlot(choice)
    local equips = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
      local c = Fk:getCardById(id)
      return c.sub_type == sub_type and player:canUseTo(c, player)
    end)
    if #equips > 0 then
      room:useCard({
        from = player,
        tos = {player},
        card = Fk:getCardById(table.random(equips)),
      })
    end
    if not player.dead and player:getMark("@@fenrui") == 0 then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return #p:getCardIds("e") < #player:getCardIds("e")
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = fenrui.name,
        prompt = "#fenrui-choose",
        cancelable = true,
      })
      if #to > 0 then
        room:setPlayerMark(player, "@@fenrui", 1)
        room:damage{
          from = player,
          to = to[1],
          damage = #player:getCardIds("e") - #to[1]:getCardIds("e"),
          skillName = fenrui.name,
        }
      end
    end
  end,
})

return fenrui
