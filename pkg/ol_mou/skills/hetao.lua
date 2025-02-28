local hetao = fk.CreateSkill{
  name = "hetao",
}

Fk:loadTranslationTable{
  ["hetao"] = "合讨",
  [":hetao"] = "当其他角色使用牌指定大于一个目标后，你可以弃置一张与此牌颜色相同的牌，令此牌对其中一个目标生效两次且对其他目标无效。",

  ["#hetao-choose"] = "合讨：你可以弃置一张%arg牌并指定一名角色，令此%arg2改为仅对其结算两次",

  ["$hetao1"] = "合诸侯之群力，扶大汉之将倾。",
  ["$hetao2"] = "猛虎啸于山野，群士执戈相待。",
  ["$hetao3"] = "合兵讨贼，其利断金！",
  ["$hetao4"] = "众将一心，战无不胜！",
  ["$hetao5"] = "秣马厉兵，今乃报国之时！",
  ["$hetao6"] = "齐心协力，第三造大汉之举！",
}

hetao:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and not player:isNude() and data.firstTarget and
      data.card.color ~= Card.NoColor and #data.use.tos > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = data.use.tos,
      pattern = data.card.color == Card.Red and ".|.|heart,diamond" or ".|.|spade,club",
      skill_name = hetao.name,
      prompt = "#hetao-choose:::"..data.card:getColorString()..":"..data.card:toLogString(),
      cancelable = true,
      will_throw = true,
    })
    if #to > 0 and #cards == 1 then
      event:setCostData(self, {tos = to, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, self.name, player, player)
    data.use.additionalEffect = 1
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    for _, p in ipairs(data.use.tos) do
      if p ~= event:getCostData(self).tos[1] then
        table.insert(data.use.nullifiedTargets, p)
      end
    end
  end,
})

return hetao
