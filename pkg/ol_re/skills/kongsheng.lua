local kongsheng = fk.CreateSkill{
  name = "ol__kongsheng",
}

Fk:loadTranslationTable{
  ["ol__kongsheng"] = "箜声",
  [":ol__kongsheng"] = "准备阶段，你可以将任意张牌置于你的武将牌上，称为“箜”。结束阶段，你获得“箜”中的非装备牌，然后令一名角色使用"..
  "剩余“箜”并失去1点体力。",

  ["#ol__kongsheng-invoke"] = "箜声：你可以将任意张牌作为“箜”置于武将牌上",
  ["#ol__kongsheng-choose"] = "箜声：选择一名角色，令其使用“箜”中的装备牌并失去1点体力",
  ["ol__kongsheng_harp"] = "箜",

  ["$ol__kongsheng1"] = "歌尽桃花颜，箜鸣玉娇黛。",
  ["$ol__kongsheng2"] = "箜篌双丝弦，心有千绪结。",
}

kongsheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  derived_piles = "ol__kongsheng_harp",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(kongsheng.name) then
      if player.phase == Player.Start then
        return not player:isNude()
      elseif player.phase == Player.Finish then
        return #player:getPile("ol__kongsheng_harp") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 999,
        include_equip = true,
        skill_name = kongsheng.name,
        prompt = "#ol__kongsheng-invoke",
        cancelable = true,
      })
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    elseif player.phase == Player.Finish then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.phase == Player.Start then
      player:addToPile("ol__kongsheng_harp", event:getCostData(self).cards, true, kongsheng.name)
    elseif player.phase == Player.Finish then
      local room = player.room
      local cards = table.filter(player:getPile("ol__kongsheng_harp"), function (id)
        return Fk:getCardById(id).type ~= Card.TypeEquip
      end)
      if #cards == 0 then return end
      room:obtainCard(player, cards, true, fk.ReasonJustMove)
      if player.dead or #player:getPile("ol__kongsheng_harp") == 0 then return end
      local targets = table.filter(room.alive_players, function (p)
        return table.find(player:getPile("ol__kongsheng_harp"), function (id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeEquip and p:canUseTo(card, p)
        end) ~= nil
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = kongsheng.name,
        prompt = "#ol__kongsheng-choose",
        cancelable = false,
      })[1]
      while not player.dead and not to.dead do
        local to_use = table.find(player:getPile("ol__kongsheng_harp"), function (id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeEquip and to:canUseTo(card, to)
        end)
        if to_use == nil then break end
        room:useCard{
          from = to,
          tos = {to},
          card = Fk:getCardById(to_use),
        }
      end
      if not to.dead then
        room:loseHp(to, 1, kongsheng.name)
      end
    end
  end,
})

return kongsheng
