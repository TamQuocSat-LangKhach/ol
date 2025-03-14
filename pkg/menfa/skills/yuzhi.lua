local yuzhi = fk.CreateSkill{
  name = "yuzhi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuzhi"] = "迂志",
  [":yuzhi"] = "锁定技，每轮开始时，你展示一张手牌，摸X张牌。此轮结束时，你弃置此牌，若你于此轮内使用过的牌数或上轮以此法摸牌数小于X，"..
  "你受到1点雷电伤害或失去〖保族〗。（X为此牌牌名字数）",

  ["#yuzhi-card"] = "迂志：展示一张手牌，摸其牌名字数的牌",
  ["@@yuzhi-inhand-round"] = "迂志",
  ["@yuzhi-round"] = "迂志",
  ["yuzhi1"] = "受到1点雷电伤害",
  ["yuzhi2"] = "失去〖保族〗",

  ["$yuzhi1"] = "我欲行夏禹旧事，为天下人。",
  ["$yuzhi2"] = "汉鹿已失，魏牛犹在，吾欲执其耳。",
  ["$yuzhi3"] = "风水轮流转，轮到我钟某问鼎重几何了。",
  ["$yuzhi4"] = "空将宝地赠他人，某怎会心甘情愿？",
  ["$yuzhi5"] = "入宝山而空手回，其与匹夫何异？",
  ["$yuzhi6"] = "天降大任于斯，不受必遭其殃。",
}

yuzhi:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(yuzhi.name) and not player:isKongcheng()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = yuzhi.name,
      prompt = "#yuzhi-card",
      cancelable = false,
    })
    local n = Fk:translate(Fk:getCardById(cards[1]).trueName, "zh_CN"):len()
    room:setCardMark(Fk:getCardById(cards[1]), "@@yuzhi-inhand-round", 1)
    player:showCards(cards)
    if player.dead then return false end
    player:drawCards(n, yuzhi.name)
    if player.dead then return false end
    room:setPlayerMark(player, "@yuzhi-round", n)
  end,
})
yuzhi:addEffect(fk.RoundEnd, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(yuzhi.name) and player:usedSkillTimes(yuzhi.name, Player.HistoryRound) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@yuzhi-inhand-round") > 0
    end)
    if #cards > 0 then
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@yuzhi-inhand-round", 0)
      end
      room:throwCard(cards, yuzhi.name, player, player)
      if player.dead then return end
    end
    local x = player:getMark("@yuzhi-round")
    if x == 0 then return false end
    if room:getBanner("RoundCount") == 1 or player:getMark("_yuzhi-round") >= x then
      local use_events = room.logic:getEventsOfScope(GameEvent.UseCard, x, function(e)
        return e.data.from == player
      end, Player.HistoryRound)
      if #use_events >= x then return end
    end
    if player:hasSkill("baozu", true) and room:askToChoice(player, {
      choices = {"yuzhi1", "yuzhi2"},
      skill_name = yuzhi.name,
    }) == "yuzhi2" then
      room:handleAddLoseSkills(player, "-baozu")
    else
      room:damage{
        to = player,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = yuzhi.name,
      }
    end
  end,

  can_refresh = Util.TrueFunc,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_yuzhi-round", player:getMark("_yuzhi_tmp"))
    room:setPlayerMark(player, "_yuzhi_tmp", player:getMark("@yuzhi-round"))
  end,
})

return yuzhi
