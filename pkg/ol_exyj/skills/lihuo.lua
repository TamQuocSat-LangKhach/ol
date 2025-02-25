local this = fk.CreateSkill{
  name = "ol_ex__lihuo",
  anim_type = "offensive",
}

this:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(this.name) then
      return data.card.trueName == "slash" and data.card.name ~= "fire__slash"
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(player, { skill_name = this.name, prompt = "#ol_ex__lihuo-invoke:::"..data.card:toLogString()})
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk:cloneCard("fire__slash", data.card.suit, data.card.number)
    for k, v in pairs(data.card) do
      if card[k] == nil then
        card[k] = v
      end
    end
    if data.card:isVirtual() then
      card.subcards = data.card.subcards
    else
      card.id = data.card.id
    end
    card.skillNames = data.card.skillNames
    data.card = card
    data.extra_data = data.extra_data or {}
    data.extra_data.ol_ex__lihuo = data.extra_data.ol_ex__lihuo or {}
    table.insert(data.extra_data.ol_ex__lihuo, player.id)
  end,
})

this:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(this.name) then
      return data.card.name == "fire__slash" and #player.room:getUseExtraTargets(data) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, { targets = room:getUseExtraTargets(data), min_num = 1, max_num = 1,
      prompt = "#lihuo-choose:::"..data.card:toLogString(), skill_name = this.name, cancelable = true
    })
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    table.insert(data.tos, self.cost_data)
  end,
})

this:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.damageDealt and data.extra_data and data.extra_data.ol_ex__lihuo and
    table.contains(data.extra_data.ol_ex__lihuo, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askToDiscard(player, { min_num = 1, max_num = 1, include_equip = true,
      skill_name = "ol_ex__lihuo", cancelable = true, pattern = ".", prompt = "#ol_ex__lihuo-discard"
    }) == 0 then
      room:loseHp(player, 1, "ol_ex__lihuo")
    end
  end,
})

Fk:loadTranslationTable{
  ["ol_ex__lihuo"] = "疬火",
  [":ol_ex__lihuo"] = "你使用非火【杀】可以改为火【杀】，此牌结算后，若造成了伤害，你弃置一张牌或失去1点体力。你使用火【杀】时可以增加一个目标。",
  
  ["#ol_ex__lihuo-invoke"] = "疬火：是否将%arg改为火【杀】？",
  ["#ol_ex__lihuo-discard"] = "疬火：弃置一张牌，否则你失去1点体力",
  ["#ol_ex__lihuo_delay"] = "疬火",
  
  ["$ol_ex__lihuo1"] = "此火只为全歼敌寇，无需妇人之仁。",
  ["$ol_ex__lihuo2"] = "战胜攻取，以火修功。",
}

return this