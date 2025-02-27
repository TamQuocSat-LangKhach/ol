local shuangxiong = fk.CreateSkill{
  name = "ol_ex__shuangxiong",
}

Fk:loadTranslationTable {
  ["ol_ex__shuangxiong"] = "双雄",
  [":ol_ex__shuangxiong"] = "摸牌阶段结束时，你可以弃置一张牌，本回合你可以将一张与此牌颜色不同的牌当【决斗】使用。"..
  "结束阶段，你获得弃牌堆中于此回合内对你造成过伤害的牌。",

  ["@ol_ex__shuangxiong-turn"] = "双雄",
  ["#ol_ex__shuangxiong-discard"] = "双雄：你可以弃置一张牌，本回合可以将不同颜色的牌当【决斗】使用",
  ["#ol_ex__shuangxiong"] = "双雄：你可以将一张%arg牌当【决斗】使用",

  ["$ol_ex__shuangxiong1"] = "吾执矛，君执槊，此天下可有挡我者？",
  ["$ol_ex__shuangxiong2"] = "兄弟协力，定可于乱世纵横！",
}

shuangxiong:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "duel",
  prompt = function(self, player)
    local mark = player:getTableMark("@ol_ex__shuangxiong-turn")
    local color = ""
    if #mark == 1 then
      if mark[1] == "red" then
        color = "black"
      else
        color = "red"
      end
    end
    return "#ol_ex__shuangxiong:::"..color
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local color = Fk:getCardById(to_select):getColorString()
    if color == "red" then
      color = "black"
    elseif color == "black" then
      color = "red"
    else
      return false
    end
    return table.contains(player:getMark("@ol_ex__shuangxiong-turn"), color)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c.skillName = shuangxiong.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return #player:getTableMark("@ol_ex__shuangxiong-turn") > 0
  end,
  enabled_at_response = function(self, player, response)
    return #player:getTableMark("@ol_ex__shuangxiong-turn") > 0 and not response
  end,
})

shuangxiong:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shuangxiong.name) and player.phase == Player.Draw and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = shuangxiong.name,
      cancelable = true,
      prompt = "#ol_ex__shuangxiong-discard",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    local color = Fk:getCardById(id):getColorString()
    room:addTableMarkIfNeed(player, "@ol_ex__shuangxiong-turn", color)
    room:throwCard(id, shuangxiong.name, player, player)
  end,
})

shuangxiong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(shuangxiong.name) or player.phase ~= Player.Finish then return end
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return false end
    local cards = {}
    local damage
    room.logic:getActualDamageEvents(1, function(e)
      damage = e.data
      if damage.to == player and damage.card then
        table.insertTableIfNeed(cards, Card:getIdList(damage.card))
      end
    end, nil, turn_event.id)
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, event:getCostData(self).cards, true, fk.ReasonJustMove, player, shuangxiong.name)
  end,
})

return shuangxiong