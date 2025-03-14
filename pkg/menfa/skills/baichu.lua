local baichu = fk.CreateSkill{
  name = "baichu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["baichu"] = "百出",
  [":baichu"] = "锁定技，当你使用牌后，若此牌：花色-类型组合为你首次使用，你记录一张普通锦囊牌，否则你本轮获得〖奇策〗；"..
  "以此法记录过，你摸一张牌或回复1点体力。",

  ["@[baichu]"] = "百出",
  ["#baichu-choice"] = "百出：记录一张普通锦囊牌",

  ["$baichu1"] = "腹有经纶，到用时施无穷之计。",
  ["$baichu2"] = "胸纳甲兵，烽烟起可靖疆晏海。",
}

Fk:addQmlMark{
  name = "baichu",
  qml_path = "packages/ol/qml/Baichu",
  how_to_show = function() return " " end,
}

baichu:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@[baichu]", 0)
end)

baichu:addEffect(fk.CardUseFinished, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(baichu.name) then
      local mark = player:getTableMark("@[baichu]")
      if type(mark) == "table" and mark[data.card.trueName] then return true end
      if data.card.suit == Card.NoSuit then return false end
      local suit = data.card:getSuitString()
      local ty = data.card:getTypeString()
      return not (mark._tab and mark._tab[suit] and mark._tab[suit][ty]) or not player:hasSkill("qice", true)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@[baichu]")
    if mark == 0 then mark = { _tab = {} } end
    if data.card.suit ~= Card.NoSuit then
      local suit = data.card:getSuitString()
      local ty = data.card:getTypeString()
      if mark._tab[suit] and mark._tab[suit][ty] then
        local round_event = room.logic:getCurrentEvent():findParent(GameEvent.Round)
        if round_event ~= nil and not player:hasSkill("qice", true) then
          room:handleAddLoseSkills(player, "qice")
          round_event:addCleaner(function()
            room:handleAddLoseSkills(player, "-qice")
          end)
        end
      else
        mark._tab[suit] = mark._tab[suit] or {}
        local names, all_names = {}, {}
        for _, id in ipairs(Fk:getAllCardIds()) do
          local card = Fk:getCardById(id)
          if card:isCommonTrick() and not card.is_derived and not table.contains(all_names, card.trueName) then
            table.insert(all_names, card.trueName)
            if not mark[card.trueName] then
              table.insert(names, card.trueName)
            end
          end
        end
        if #names == 0 then return end
        local choice = room:askToChoice(player, {
          choices = names,
          skill_name = baichu.name,
          prompt = "#baichu-choice",
          all_choices = all_names,
        })
        mark._tab[suit][ty] = choice
        mark[choice] = true
        room:setPlayerMark(player, "@[baichu]", mark)
      end
    end
    if mark[data.card.trueName] ~= nil then
      if not player:isWounded() then
        player:drawCards(1, baichu.name)
      else
        local choice = room:askToChoice(player, {
          choices = {"draw1", "recover"},
          skill_name = baichu.name,
        })
        if choice == "draw1" then
          player:drawCards(1, baichu.name)
        else
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = baichu.name,
          }
        end
      end
    end
  end,
})

return baichu
