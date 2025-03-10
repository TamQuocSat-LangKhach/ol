local huiyun = fk.CreateSkill{
  name = "huiyun",
}

Fk:loadTranslationTable{
  ["huiyun"] = "晖云",
  [":huiyun"] = "你可以将一张牌当【火攻】使用，然后你于此牌结算结束后选择一项（每项每轮限一次），令目标选择是否执行："..
  "1.使用展示牌，然后重铸所有手牌；2.使用一张手牌，然后重铸展示牌；3.摸一张牌。",

  ["#huiyun"] = "晖云：将一张牌当【火攻】使用，结算后可以令目标执行选项",
  ["#huiyun-choice"] = "晖云：选择一项令 %dest 角色选择是否执行",
  ["huiyun1"] = "使用展示牌，然后重铸所有手牌",
  ["huiyun2"] = "使用一张手牌，然后重铸展示牌",
  ["huiyun3"] = "摸一张牌",
  ["#huiyun1-use"] = "晖云：你可以使用%arg，然后重铸所有手牌",
  ["#huiyun2-use"] = "晖云：你可以使用一张手牌，然后重铸%arg",
  ["#huiyun3-draw"] = "晖云：你可以摸一张牌",

  ["$huiyun1"] = "舍身饲离火，不负万古名。",
  ["$huiyun2"] = "义士今犹在，青笺气干云。",
}

huiyun:addEffect("viewas", {
  anim_type = "support",
  pattern = "fire_attack",
  prompt = "#huiyun",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = huiyun.name
    card:addSubcard(cards[1])
    return card
  end,
  after_use = function (self, player, UseCardData)
    if player.dead then return end
    local room = player.room
    local tos = table.simpleClone(UseCardData.tos)
    room:sortByAction(tos)
    local showMap = UseCardData.extra_data and UseCardData.extra_data.huiyun or {}
    for _, to in ipairs(tos) do
      local choices = table.filter({1, 2, 3}, function (n)
        return not table.contains(player:getTableMark("huiyun-round"), n)
      end)
      if player.dead or #choices == 0 then break end
      choices = table.map(choices, function (n)
        return "huiyun"..n
      end)
      if not to.dead and showMap[to] then
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = huiyun.name,
          prompt = "#huiyun-choice::"..to.id,
          all_choices = {"huiyun1", "huiyun2", "huiyun3"},
        })
        room:addTableMark(player, "huiyun-round", tonumber(choice[7]))
        local cards = showMap[to]
        for _, cardId in ipairs(cards) do
          if to.dead then break end
          local name = Fk:getCardById(cardId):toLogString()
          if choice == "huiyun3" then
            if room:askToSkillInvoke(to, {
              skill_name = huiyun.name,
              prompt = "#huiyun3-draw",
            }) then
              to:drawCards(1, "huiyun")
            end
          elseif choice == "huiyun1" then
            if table.contains(to:getCardIds("h"), cardId) then
              local use = room:askToUseRealCard(to, {
                pattern = {cardId},
                skill_name = huiyun.name,
                prompt = "#huiyun1-use:::"..name,
                extra_data = {
                  bypass_times = true,
                  extraUse = true,
                }
              })
              if use then
                room:delay(300)
                if not to.dead and not to:isKongcheng() then
                  room:recastCard(to:getCardIds("h"), to, huiyun.name)
                end
              end
            end
          elseif choice == "huiyun2" then
            local use = room:askToUseRealCard(to, {
              pattern = to:getCardIds("h"),
              skill_name = huiyun.name,
              prompt = "#huiyun2-use:::"..name,
              extra_data = {
                bypass_times = true,
                extraUse = true,
              }
            })
            if use then
              room:delay(300)
              if not to.dead and table.contains(to:getCardIds("h"), cardId) then
                room:recastCard({cardId}, to, huiyun.name)
              end
            end
          end
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})
huiyun:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        return table.contains(e.data.card.skillNames, "huiyun")
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data
      use.extra_data = use.extra_data or {}
      use.extra_data.huiyun = use.extra_data.huiyun or {}
      use.extra_data.huiyun[player] = use.extra_data.huiyun[player] or {}
      table.insertIfNeed(use.extra_data.huiyun[player], data.cardIds[1])
    end
  end,
})

return huiyun
