local RougeUtil = require "packages.ol.rougelike1v1.util"

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

Fk:addSkill(rule)
return rule