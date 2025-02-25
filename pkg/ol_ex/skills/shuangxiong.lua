local this = fk.CreateSkill{
  name = "ol_ex__shuangxiong",
}

this:addEffect('active', {
  anim_type = "offensive",
  pattern = "duel",
  prompt = "#ol_ex__shuangxiong-viewas",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 or type(Self:getMark("@ol_ex__shuangxiong-turn")) ~= "table" then return false end
    local color = Fk:getCardById(to_select):getColorString()
    if color == "red" then
      color = "black"
    elseif color == "black" then
      color = "red"
    else
      return false
    end
    return table.contains(Self:getMark("@ol_ex__shuangxiong-turn"), color)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("duel")
    c.skillName = this.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return type(player:getMark("@ol_ex__shuangxiong-turn")) == "table"
  end,
  enabled_at_response = function(self, player, resp)
    return type(player:getMark("@ol_ex__shuangxiong-turn")) == "table" and not resp
  end,
})

this:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(this.name) then return end
    return player.phase == Player.Draw and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, { min_num = 1, max_num = 1, include_equip = true,
      skill_name = "ol_ex__shuangxiong", cancelable = true, pattern = ".", prompt = "#ol_ex__shuangxiong-discard", skip = true
    })
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local color = Fk:getCardById(self.cost_data[1]):getColorString()
    room:throwCard(self.cost_data, this.name, player, player)
    room:addTableMarkIfNeed(player, "@ol_ex__shuangxiong-turn", color)
  end,
})

this:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(this.name) or player.phase ~= Player.Finish then return end
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return false end
    local cards = {}
    local damage
    room.logic:getActualDamageEvents(1, function(e)
      damage = e.data[1]
      if damage.to == player and damage.card then
        table.insertTableIfNeed(cards, Card:getIdList(damage.card))
      end
      return false
    end, nil, turn_event.id)
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(player, self.cost_data, true, fk.ReasonJustMove)
  end,
})

Fk:loadTranslationTable {
  ["ol_ex__shuangxiong"] = "双雄",
  [":ol_ex__shuangxiong"] = "①摸牌阶段结束时，你可弃置一张牌，你于此回合内可以将一张与此牌颜色不同的牌转化为【决斗】使用。"..
  "②结束阶段，你获得弃牌堆中于此回合内对你造成过伤害的牌。",

  ["@ol_ex__shuangxiong-turn"] = "双雄",
  ["#ol_ex__shuangxiong-discard"] = "双雄：你可以弃置一张牌，本回合可以将不同颜色的牌当【决斗】使用",
  ["#ol_ex__shuangxiong-viewas"] = "你是否想要发动“双雄”，将一张牌当【决斗】使用？",

  ["$ol_ex__shuangxiong1"] = "吾执矛，君执槊，此天下可有挡我者？",
  ["$ol_ex__shuangxiong2"] = "兄弟协力，定可于乱世纵横！",
}

return this