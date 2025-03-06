local kuangxiang = fk.CreateSkill{
  name = "kuangxiang",
}

Fk:loadTranslationTable{
  ["kuangxiang"] = "匡襄",
  [":kuangxiang"] = "准备阶段，你可以令一名角色将手牌数调整为4，其以此法获得的黑色牌造成伤害+1，其以此法每获得一张红色牌，其下个摸牌阶段摸牌数-1。",

  ["#kuangxiang-choose"] = "匡襄：令一名角色将手牌数调整为4，其摸到的牌具有额外效果",
  ["@@kuangxiang-inhand"] = "匡襄",
  ["@kuangxiang"] = "摸牌数-",

  ["$kuangxiang1"] = "胜败乃兵家常事，主公不可言弃。",
  ["$kuangxiang2"] = "我等纵横数十载，必能东山再起。",
}

kuangxiang:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuangxiang.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function (p)
        return p:getHandcardNum() ~= 4
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getHandcardNum() ~= 4
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = kuangxiang.name,
      prompt = "#kuangxiang-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = to:getHandcardNum() - 4
    if n > 0 then
      room:askToDiscard(to, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = kuangxiang.name,
        cancelable = false,
      })
    else
      local cards = to:drawCards(-n, kuangxiang.name, "top", "@@kuangxiang-inhand")
      if not to.dead then
        n = #table.filter(cards, function (id)
          return Fk:getCardById(id).color == Card.Red
        end)
        if n > 0 then
          room:addPlayerMark(to, "@kuangxiang", n)
        end
      end
    end
  end,
})
kuangxiang:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    if target == player and data.card.is_damage_card and data.card.color == Card.Black then
      local ids = Card:getIdList(data.card)
      return #ids == 1 and Fk:getCardById(ids[1]):getMark("@@kuangxiang-inhand") > 0
    end
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})
kuangxiang:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@kuangxiang") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.n = data.n - player:getMark("@kuangxiang")
    player.room:setPlayerMark(player, "@kuangxiang", 0)
  end,
})

return kuangxiang
