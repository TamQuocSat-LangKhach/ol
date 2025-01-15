local RougeUtil = require "packages.ol.rougelike1v1.util"
local hasTalent = RougeUtil.hasTalent

local rule = fk.CreateTriggerSkill{
  name = "#rougelike1v1_rule",
  events = {fk.TurnEnd},
  priority = 0.001,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getCurrentExtraTurnReason() == "game_rule"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    -- 回合结束时，增加虎符，进行消费
    local room = player.room
    local round = room:getTag("RoundCount")
    if round > 3 then
      for _, p in ipairs(room.alive_players) do
        RougeUtil.changeMoney(p, 2)
      end
    else
      if round == 1 and player.seat == 1 then
        RougeUtil.changeMoney(player, 2)
        RougeUtil.changeMoney(player:getNextAlive(), 3)
      else
        for _, p in ipairs(room.alive_players) do
          RougeUtil.changeMoney(p, 1)
        end
      end
    end

    RougeUtil:askForShopping(room.alive_players)
  end,

  refresh_events = {fk.RoundStart},
  can_refresh = function(self, event, target, player, data)
    return player.seat == 1
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setBanner("rouge_round", player.room:getTag("RoundCount"))
  end
}

-- 商店：领取初始战法后，刷新商店；回合结束时，购买并刷新商店
-- TODO: 再说吧

-- 喜从天降

RougeUtil:addTalent { 0, "rouge_xicongtianjiang", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  RougeUtil.changeMoney(player, 1)
end}
RougeUtil:addTalent { 0, "rouge_xicongtianjiang2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  RougeUtil.changeMoney(player, 2)
end}
Fk:loadTranslationTable{
  ["rouge_xicongtianjiang"] = "喜从天降Ⅰ",
  [":rouge_xicongtianjiang"] = "获得1个虎符",
  ["rouge_xicongtianjiang2"] = "喜从天降Ⅱ",
  [":rouge_xicongtianjiang2"] = "获得2个虎符",
}

-- 增寿

RougeUtil:addTalent { 2, "rouge_zengshou", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 1)
end}
RougeUtil:addTalent { 4, "rouge_zengshou2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 2)
end}
Fk:loadTranslationTable{
  ["rouge_zengshou"] = "增寿Ⅰ",
  [":rouge_zengshou"] = "体力上限+1（不改变当前体力）",
  ["rouge_zengshou2"] = "增寿Ⅱ",
  [":rouge_zengshou2"] = "体力上限+2（不改变当前体力）",
}

-- 回合开始相关：搬运、博闻、...

RougeUtil:addBuffTalent { 2, "rouge_banyun" }
RougeUtil:addBuffTalent { 3, "rouge_bowen" }
RougeUtil:addBuffTalent { 4, "rouge_bowen2" }
RougeUtil:addBuffTalent { 4, "rouge_bowen3" }
rule:addRelatedSkill(fk.CreateTriggerSkill{
  name = "#rougelike1v1_rule_turnstart",
  events = {fk.TurnStart},
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_banyun", "rouge_bowen", "rouge_bowen2", "rouge_bowen3" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if RougeUtil.hasTalent(player, "rouge_banyun") then
      RougeUtil.sendTalentLog(player, "rouge_banyun")
      local enemys = table.filter(room.alive_players, function(p)
        return p.role ~= player.role and not p:isKongcheng()
      end)
      local card = room:askForCardChosen(player, table.random(enemys), "h", "rouge_banyun")
      room:obtainCard(player, card, false, fk.ReasonPrey, player.id, "rouge_banyun")
    end
    if RougeUtil.hasTalent(player, "rouge_bowen") then
      RougeUtil.sendTalentLog(player, "rouge_bowen")
      local tricks = room:getCardsFromPileByRule('.|.|.|.|.|trick', 1, "drawPile")
      room:obtainCard(player, tricks, true, fk.ReasonPrey, player.id, "rouge_bowen")
    end
    if RougeUtil.hasTalent(player, "rouge_bowen2") then
      RougeUtil.sendTalentLog(player, "rouge_bowen2")
      local tricks = room:getCardsFromPileByRule('.|.|.|.|.|trick', 2, "drawPile")
      room:obtainCard(player, tricks, true, fk.ReasonPrey, player.id, "rouge_bowen3")
    end
    if RougeUtil.hasTalent(player, "rouge_bowen3") then
      RougeUtil.sendTalentLog(player, "rouge_bowen3")
      local tricks = room:getCardsFromPileByRule('.|.|.|.|.|trick', 3, "drawPile")
      room:obtainCard(player, tricks, true, fk.ReasonPrey, player.id, "rouge_bowen3")
    end
  end
})
Fk:loadTranslationTable{
  ["rouge_banyun"] = "搬运",
  [":rouge_banyun"] = "你的回合开始时，从随机敌方手牌区获得1张牌",
  ["rouge_bowen"] = "博闻Ⅰ",
  [":rouge_bowen"] = "你的回合开始时，从牌堆中获得1张随机锦囊牌",
  ["rouge_bowen2"] = "博闻Ⅱ",
  [":rouge_bowen2"] = "你的回合开始时，从牌堆中获得2张随机锦囊牌",
  ["rouge_bowen3"] = "博闻Ⅲ",
  [":rouge_bowen3"] = "你的回合开始时，从牌堆中获得3张随机锦囊牌",
}

-- 回合结束相关：援助、...

RougeUtil:addBuffTalent { 2, "rouge_yuanzhu" }
RougeUtil:addBuffTalent { 3, "rouge_yuanzhu2" }
RougeUtil:addBuffTalent { 4, "rouge_yuanzhu3" }
rule:addRelatedSkill(fk.CreateTriggerSkill{
  name = "#rougelike1v1_rule_turnend",
  events = {fk.TurnEnd},
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_yuanzhu", "rouge_yuanzhu2", "rouge_yuanzhu3" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if RougeUtil.hasTalent(player, "rouge_yuanzhu") then
      RougeUtil.sendTalentLog(player, "rouge_yuanzhu")
      player:drawCards(1, "rouge_yuanzhu")
    end
    if RougeUtil.hasTalent(player, "rouge_yuanzhu2") then
      RougeUtil.sendTalentLog(player, "rouge_yuanzhu2")
      player:drawCards(2, "rouge_yuanzhu2")
    end
    if RougeUtil.hasTalent(player, "rouge_yuanzhu3") then
      RougeUtil.sendTalentLog(player, "rouge_yuanzhu3")
      player:drawCards(3, "rouge_yuanzhu3")
    end
  end
})
Fk:loadTranslationTable{
  ["rouge_yuanzhu"] = "援助Ⅰ",
  [":rouge_yuanzhu"] = "回合结束时，你摸1张牌",
  ["rouge_yuanzhu2"] = "援助Ⅱ",
  [":rouge_yuanzhu2"] = "回合结束时，你摸2张牌",
  ["rouge_yuanzhu3"] = "援助Ⅲ",
  [":rouge_yuanzhu3"] = "回合结束时，你摸3张牌",
}

-- Tmd: 出杀次数类
----------------------

RougeUtil:addBuffTalent { 2, "rouge_zhandouxuexi" }
RougeUtil:addBuffTalent { 1, "rouge_zhandouxuexi2" }
RougeUtil:addBuffTalent { 1, "rouge_zhandouxuexi3" }
RougeUtil:addBuffTalent { 2, "rouge_chijiuzhan4" }
RougeUtil:addBuffTalent { 3, "rouge_danliangboduo" }
RougeUtil:addBuffTalent { 2, "rouge_erlianji" }
RougeUtil:addBuffTalent { 4, "rouge_sanlianji" }
-- TODO RougeUtil:addBuffTalent { 3, "rouge_qianlong" }
-- TODO RougeUtil:addBuffTalent { 4, "rouge_wendingjingong" }
-- TODO RougeUtil:addBuffTalent { 3, "rouge_woxinchangdan" }
rule:addRelatedSkill(fk.CreateTargetModSkill{
  name = "#rougelike1v1_rule_slashcount",
  residue_func = function(self, player, skill, scope, card, to)
    if skill.trueName ~= "slash_skill" then return 0 end
    if scope ~= Player.HistoryPhase then return 0 end
    local ret = 0
    local room = Fk:currentRoom()

    local round = room:getBanner("rouge_round")
    if hasTalent(player, "rouge_zhandouxuexi") and round >= 3 then
      ret = ret + 1
    end
    if hasTalent(player, "rouge_zhandouxuexi2") and round >= 4 then
      ret = ret + 1
    end
    if hasTalent(player, "rouge_zhandouxuexi3") and round >= 7 then
      ret = ret + 1
    end

    if hasTalent(player, "rouge_erlianji") then
      ret = ret + 1
    end
    if hasTalent(player, "rouge_sanlianji") then
      ret = ret + 2
    end

    if hasTalent(player, "rouge_chijiuzhan4") and player:getMark("rouge_money") >= 3 then
      ret = ret + 1
    end

    ret = ret - #table.filter(room.alive_players, function(p)
      return p.role ~= player.role and hasTalent(p, "rouge_danliangboduo")
    end)

    return ret
  end
})

Fk:loadTranslationTable{
  ["rouge_zhandouxuexi"] = "战斗学习Ⅰ",
  [":rouge_zhandouxuexi"] = "从第3轮开始，你的出杀+1",
  ["rouge_zhandouxuexi2"] = "战斗学习Ⅱ",
  [":rouge_zhandouxuexi2"] = "从第4轮开始，你的出杀+1",
  ["rouge_zhandouxuexi3"] = "战斗学习Ⅲ",
  [":rouge_zhandouxuexi3"] = "从第7轮开始，你的出杀+1",
  ["rouge_chijiuzhan4"] = "持久战Ⅳ",
  [":rouge_chijiuzhan4"] = "虎符数量达到3后，出杀次数+1",
  ["rouge_danliangboduo"] = "胆量剥夺",
  [":rouge_danliangboduo"] = "敌方的出杀次数-1",
  ["rouge_erlianji"] = "二连击",
  [":rouge_erlianji"] = "你的出牌阶段，你的出杀次数+1",
  ["rouge_sanlianji"] = "三连击",
  [":rouge_sanlianji"] = "你的出牌阶段，你的出杀次数+2",
}

-- 加手牌上限、不计入上限类
-----------------------------

RougeUtil:addBuffTalent { 1, "rouge_cangtaohu" }
RougeUtil:addBuffTalent { 3, "rouge_haoshenfa" }
RougeUtil:addBuffTalent { 1, "rouge_pinang1" }
RougeUtil:addBuffTalent { 2, "rouge_pinang2" }
RougeUtil:addBuffTalent { 3, "rouge_pinang3" }
RougeUtil:addBuffTalent { 4, "rouge_wendingchengzai" }
RougeUtil:addBuffTalent { 2, "rouge_xinshounianlai" }
rule:addRelatedSkill(fk.CreateMaxCardsSkill{
  name = "#rougelike1v1_rule_maxcard",
  exclude_from = function(self, player, card)
    if hasTalent(player, "rouge_cangtaohu") and card.trueName == "peach" then
      return true
    end
    if hasTalent(player, "rouge_haoshenfa") and card.trueName == "jink" then
      return true
    end
  end,
  correct_func = function(self, player)
    local ret = 0
    if hasTalent(player, "rouge_pinang1") then
      ret = ret + 1
    end
    if hasTalent(player, "rouge_pinang2") then
      ret = ret + 2
    end
    if hasTalent(player, "rouge_pinang3") then
      ret = ret + 5
    end
    return ret
  end,
  fixed_func = function(self, player)
    if hasTalent(player, "rouge_wendingchengzai") then
      return 8
    end
    if hasTalent(player, "rouge_xinshounianlai") then
      return player.maxHp
    end
  end
})
Fk:loadTranslationTable{
  ["rouge_cangtaohu"] = "藏桃户",
  [":rouge_cangtaohu"] = "【桃】不计入手牌上限",
  ["rouge_haoshenfa"] = "好身法",
  [":rouge_haoshenfa"] = "【闪】不计入手牌上限",
  ["rouge_pinang1"] = "皮囊Ⅰ",
  [":rouge_pinang1"] = "手牌上限+1",
  ["rouge_pinang2"] = "皮囊Ⅱ",
  [":rouge_pinang2"] = "手牌上限+2",
  ["rouge_pinang3"] = "皮囊Ⅲ",
  [":rouge_pinang3"] = "手牌上限+5",
  ["rouge_wendingchengzai"] = "稳定承载",
  [":rouge_wendingchengzai"] = "手牌上限基础值为8",
  ["rouge_xinshounianlai"] = "信手拈来",
  [":rouge_xinshounianlai"] = "你的手牌上限不因体力值改变而改变",
}

-- Misc: 系统耦合类
------------------------

Fk:addSkill(rule)
return rule