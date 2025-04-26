local hujia = fk.CreateSkill {
  name = "ol_ex__hujia",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["ol_ex__hujia"] = "护驾",
  [":ol_ex__hujia"] = "主公技，当你需要使用或打出【闪】时，你可以令其他魏势力角色选择是否打出一张【闪】（视为由你使用或打出）。"..
  "每回合限一次，当其他魏势力角色于其回合外使用或打出【闪】时，其可以令你摸一张牌。",

  ["#ol_ex__hujia-draw"] = "护驾：是否令 %src 摸一张牌？",

  ["$ol_ex__hujia1"] = "将才皆在，保我无忧。",
  ["$ol_ex__hujia2"] = "我有嘉宾，鼓瑟吹笙。",
}

local spec = {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hujia.name) and
      Exppattern:Parse(data.pattern):matchExp("jink") and
      (data.extraData == nil or data.extraData.hujia_ask == nil) and
      not table.every(player.room.alive_players, function(p)
        return p == player or p.kingdom ~= "wei"
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:isAlive() and p.kingdom == "wei" then
        local params = { ---@type AskToUseCardParams
          skill_name = "jink",
          pattern = "jink",
          prompt = "#hujia-ask:" .. player.id,
          cancelable = true,
          extra_data = {hujia_ask = true}
        }
        local respond = room:askToResponse(p, params)
        if respond then
          respond.skipDrop = true
          room:responseCard(respond)

          local new_card = Fk:cloneCard("jink")
          new_card.skillName = hujia.name
          new_card:addSubcards(room:getSubcardsByRule(respond.card, { Card.Processing }))
          local result = {
            from = player,
            card = new_card,
          }
          if event == fk.AskForCardUse then
            result.tos = {}
          end
          data.result = result
          return true
        end
      end
    end
  end,
}

hujia:addEffect(fk.AskForCardUse, spec)
hujia:addEffect(fk.AskForCardResponse, spec)

local spec2 = {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(hujia.name) and data.card.trueName == "jink" and
      target ~= player and target.kingdom == "wei" and not target.dead and player.room.current ~= target and
      player:usedEffectTimes("#ol_ex__hujia_3_trig", Player.HistoryTurn) +
      player:usedEffectTimes("#ol_ex__hujia_4_trig", Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(target, {
      skill_name = hujia.name,
      prompt = "#ol_ex__hujia-draw:"..player.id,
    }) then
      room:doIndicate(target, {player})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, hujia.name)
  end,
}

hujia:addEffect(fk.CardUsing, spec2)
hujia:addEffect(fk.CardResponding, spec2)

return hujia
