local RougeUtil = require "packages.ol.rougelike1v1.util"
local hasTalent = RougeUtil.hasTalent
local sendTalentLog = RougeUtil.sendTalentLog

local rule = fk.CreateTriggerSkill {
  name = "#rougelike1v1_rule",
  events = { fk.TurnEnd },
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
        local n = 2
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

  refresh_events = { fk.RoundStart },
  can_refresh = function(self, event, target, player, data)
    return player.seat == 1
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setBanner("rouge_round", player.room:getTag("RoundCount"))
  end
}

-- 商店：领取初始战法后，刷新商店；回合结束时，购买并刷新商店
-- TODO: 再说吧

-- 即时效果
-- 喜从天降

RougeUtil:addTalent { 0, "rouge_xicongtianjiang", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  RougeUtil.changeMoney(player, 1)
end }
RougeUtil:addTalent { 0, "rouge_xicongtianjiang2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  RougeUtil.changeMoney(player, 2)
end }
Fk:loadTranslationTable {
  ["rouge_xicongtianjiang"] = "喜从天降Ⅰ",
  [":rouge_xicongtianjiang"] = "获得1个虎符",
  ["rouge_xicongtianjiang2"] = "喜从天降Ⅱ",
  [":rouge_xicongtianjiang2"] = "获得2个虎符",
}

-- 增寿

RougeUtil:addTalent { 2, "rouge_zengshou", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 1)
end }
RougeUtil:addTalent { 4, "rouge_zengshou2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 2)
end }
Fk:loadTranslationTable {
  ["rouge_zengshou"] = "增寿Ⅰ",
  [":rouge_zengshou"] = "体力上限+1（不改变当前体力）",
  ["rouge_zengshou2"] = "增寿Ⅱ",
  [":rouge_zengshou2"] = "体力上限+2（不改变当前体力）",
}

-- 体魄

RougeUtil:addTalent { 3, "rouge_tipo", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 1)
  player.room:recover {
    who = player,
    num = 1,
    skillName = self
  }
end }
RougeUtil:addTalent { 4, "rouge_tipo2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 2)
  player.room:recover {
    who = player,
    num = 2,
    skillName = self
  }
end }
RougeUtil:addTalent { 4, "rouge_tipo3", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 3)
  player.room:recover {
    who = player,
    num = 3,
    skillName = self
  }
end }
Fk:loadTranslationTable {
  ["rouge_tipo"] = "体魄Ⅰ",
  [":rouge_tipo"] = "增加1点体力上限并回复等量体力",
  ["rouge_tipo2"] = "体魄Ⅱ",
  [":rouge_tipo2"] = "增加2点体力上限并回复等量体力",
  ["rouge_tipo3"] = "体魄Ⅲ",
  [":rouge_tipo3"] = "增加3点体力上限并回复等量体力",
}

-- 天降！

RougeUtil:addTalent { 2, "rouge_tianjiang__trick", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  local cards = room:getCardsFromPileByRule('.|.|.|.|.|trick', 3, "allPiles")
  room:obtainCard(player, cards, true, fk.ReasonPrey, player.id, self)
end }
RougeUtil:addTalent { 2, "rouge_tianjiang__basic", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  local cards = room:getCardsFromPileByRule('.|.|.|.|.|basic', 4, "allPiles")
  room:obtainCard(player, cards, true, fk.ReasonPrey, player.id, self)
end }
RougeUtil:addTalent { 2, "rouge_tianjiang__equip", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  local cards = room:getCardsFromPileByRule('.|.|.|.|.|equip', 4, "allPiles")
  room:obtainCard(player, cards, true, fk.ReasonPrey, player.id, self)
end }
RougeUtil:addTalent { 2, "rouge_tianjiang__any", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  local cards = room:getCardsFromPileByRule('.', 3, "allPiles")
  room:obtainCard(player, cards, true, fk.ReasonPrey, player.id, self)
end }
Fk:loadTranslationTable {
  ["rouge_tianjiang__trick"] = "天降锦囊",
  [":rouge_tianjiang__trick"] = "获取3张锦囊牌",
  ["rouge_tianjiang__basic"] = "天降横财",
  [":rouge_tianjiang__basic"] = "获取4张基本牌",
  ["rouge_tianjiang__equip"] = "天降装备",
  [":rouge_tianjiang__equip"] = "获取4张装备牌",
  ["rouge_tianjiang__any"] = "天降卡牌",
  [":rouge_tianjiang__any"] = "获取3张牌",
}

-- 铁布衫

RougeUtil:addTalent { 1, "rouge_tiebushan", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeShield(player, 1)
end }
RougeUtil:addTalent { 2, "rouge_tiebushan2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeShield(player, 2)
end }
RougeUtil:addTalent { 4, "rouge_tiebushan3", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeShield(player, 4)
end }
Fk:loadTranslationTable {
  ["rouge_tiebushan"] = "铁布衫Ⅰ",
  [":rouge_tiebushan"] = "获得1点护甲",
  ["rouge_tiebushan2"] = "铁布衫Ⅱ",
  [":rouge_tiebushan2"] = "获得2点护甲",
  ["rouge_tiebushan3"] = "铁布衫Ⅲ",
  [":rouge_tiebushan3"] = "获得4点护甲",
}

-- 士气剥夺

RougeUtil:addTalent { 3, "rouge_shiqiboduo", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if RougeUtil.isEnemy(player, p) and p.maxHp > 1 then
      player.room:changeMaxHp(p, -1)
    end
  end
end }
Fk:loadTranslationTable {
  ["rouge_shiqiboduo"] = "士气剥夺",
  [":rouge_shiqiboduo"] = "所有敌方的体力上限-1，最低为1",
}

-- 回合/轮数开始相关：搬运、博闻、...

RougeUtil:addBuffTalent { 2, "rouge_banyun" }
RougeUtil:addBuffTalent { 3, "rouge_bowen" }
RougeUtil:addBuffTalent { 4, "rouge_bowen2" }
RougeUtil:addBuffTalent { 4, "rouge_bowen3" }
RougeUtil:addBuffTalent { 2, "rouge_fuyiqu__slash" }
RougeUtil:addBuffTalent { 2, "rouge_fuyiqu__fire_attack" }
RougeUtil:addBuffTalent { 2, "rouge_fuyiqu__jink" }
RougeUtil:addBuffTalent { 3, "rouge_fuyiqu__peach" }
RougeUtil:addBuffTalent { 3, "rouge_fuyiqu__dismantlement" }
RougeUtil:addBuffTalent { 3, "rouge_fuyiqu__duel" }
RougeUtil:addBuffTalent { 3, "rouge_fuyiqu__iron_chain" }
RougeUtil:addBuffTalent { 4, "rouge_fuyiqu__snatch" }
RougeUtil:addBuffTalent { 1, "rouge_fenjin" }
RougeUtil:addBuffTalent { 1, "rouge_yuanmou" }
RougeUtil:addBuffTalent { 2, "rouge_yuanmou2" }
RougeUtil:addBuffTalent { 1, "rouge_yuanmou3" }


rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_rule_turnstart",
  events = { fk.TurnStart },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and (RougeUtil.hasOneOfTalents(player,
        { "rouge_banyun", "rouge_bowen", "rouge_bowen2", "rouge_bowen3", "rouge_fenjin",
          "rouge_yuanmou", "rouge_yuanmou2", "rouge_yuanmou3" }) or
      #RougeUtil.hasTalentStart(player, "rouge_fuyiqu__") ~= 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if RougeUtil.hasTalent(player, "rouge_banyun") then
      RougeUtil.sendTalentLog(player, "rouge_banyun")
      local enemys = table.filter(room.alive_players, function(p)
        return RougeUtil.isEnemy(player, p) and not p:isKongcheng()
      end)
      if #enemys ~= 0 then
        local card = table.random(table.random(enemys):getCardIds("h"))
        room:obtainCard(player, card, false, fk.ReasonPrey, player.id, "rouge_banyun")
      end
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

    if RougeUtil.hasTalent(player, "rouge_fenjin") then
      if player.hp > 2 then
        RougeUtil.sendTalentLog(player, "rouge_fenjin")
        room:loseHp(player, 1, "rouge_fenjin")
        player:drawCards(2, "rouge_fenjin")
      end
    end

    if RougeUtil.hasTalent(player, "rouge_yuanmou") then
      if room:getTag("RoundCount") == 3 then
        RougeUtil.sendTalentLog(player, "rouge_yuanmou")
        room:recover {
          who = player,
          num = 2,
          skillName = "rouge_yuanmou"
        }
      end
    end
    if RougeUtil.hasTalent(player, "rouge_yuanmou2") then
      if room:getTag("RoundCount") == 3 then
        RougeUtil.sendTalentLog(player, "rouge_yuanmou2")
        room:recover {
          who = player,
          num = 3,
          skillName = "rouge_yuanmou"
        }
      end
    end
    if RougeUtil.hasTalent(player, "rouge_yuanmou3") then
      if room:getTag("RoundCount") == 2 then
        RougeUtil.sendTalentLog(player, "rouge_yuanmou3")
        room:recover {
          who = player,
          num = 2,
          skillName = "rouge_yuanmou"
        }
      end
    end

    for _, talent in ipairs(RougeUtil.hasTalentStart(player, "rouge_fuyiqu__")) do
      RougeUtil.sendTalentLog(player, talent)
      local name_splited = talent:split("rouge_fuyiqu__")
      local card_name = name_splited[#name_splited]
      if card_name then
        local card = room:getCardsFromPileByRule(card_name)
        room:obtainCard(player, card, true, fk.ReasonPrey, player.id, talent)
      end
    end
  end
})


RougeUtil:addTalent { 1, "rouge_xuezhan1", function(self, player)
  local num = math.max(-1, 1 - player.maxHp)
  if num < 0 then
    RougeUtil.sendTalentLog(player, self)
    player.room:changeMaxHp(player, num)
  end
end }
RougeUtil:addTalent { 2, "rouge_xuezhan2", function(self, player)
  local num = math.max(-2, 1 - player.maxHp)
  if num < 0 then
    RougeUtil.sendTalentLog(player, self)
    player.room:changeMaxHp(player, num)
  end
end }
RougeUtil:addTalent { 4, "rouge_xuezhan3", function(self, player)
  local num = math.max(-3, 1 - player.maxHp)
  p(num)
  if num < 0 then
    RougeUtil.sendTalentLog(player, self)
    player.room:changeMaxHp(player, num)
  end
end }


rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_rule_roundstart",
  events = { fk.RoundStart },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return RougeUtil.hasOneOfTalents(player,
      { "rouge_xuezhan1", "rouge_xuezhan2", "rouge_xuezhan3" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = ""
    if RougeUtil.hasTalent(player, "rouge_xuezhan1") and player:isWounded() then
      skillName = "rouge_xuezhan1"
      RougeUtil.sendTalentLog(player, "rouge_xuezhan1")
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName
      })
    end

    if RougeUtil.hasTalent(player, "rouge_xuezhan2") and player:isWounded() then
      skillName = "rouge_xuezhan2"
      RougeUtil.sendTalentLog(player, "rouge_xuezhan2")
      room:recover({
        who = player,
        num = 2,
        recoverBy = player,
        skillName = skillName
      })
    end

    if RougeUtil.hasTalent(player, "rouge_xuezhan3") and player:isWounded() then
      skillName = "rouge_xuezhan3"
      RougeUtil.sendTalentLog(player, "rouge_xuezhan3")
      room:recover({
        who = player,
        num = 3,
        recoverBy = player,
        skillName = skillName
      })
    end
  end
})


Fk:loadTranslationTable {
  ["rouge_banyun"] = "搬运",
  [":rouge_banyun"] = "你的回合开始时，从随机敌方手牌区获得1张牌",
  ["rouge_bowen"] = "博闻Ⅰ",
  [":rouge_bowen"] = "你的回合开始时，从牌堆中获得1张随机锦囊牌",
  ["rouge_bowen2"] = "博闻Ⅱ",
  [":rouge_bowen2"] = "你的回合开始时，从牌堆中获得2张随机锦囊牌",
  ["rouge_bowen3"] = "博闻Ⅲ",
  [":rouge_bowen3"] = "你的回合开始时，从牌堆中获得3张随机锦囊牌",

  ["rouge_fuyiqu__slash"] = "拂衣去杀",
  [":rouge_fuyiqu__slash"] = "你的回合开始时，你获得1张【杀】",
  ["rouge_fuyiqu__fire_attack"] = "拂衣去火",
  [":rouge_fuyiqu__fire_attack"] = "你的回合开始时，你获得1张【火攻】",
  ["rouge_fuyiqu__jink"] = "拂衣去闪",
  [":rouge_fuyiqu__jink"] = "你的回合开始时，你获得1张【闪】",
  ["rouge_fuyiqu__peach"] = "拂衣去桃",
  [":rouge_fuyiqu__peach"] = "你的回合开始时，你获得1张【桃】",
  ["rouge_fuyiqu__dismantlement"] = "拂衣去拆",
  [":rouge_fuyiqu__dismantlement"] = "你的回合开始时，你获得1张【过河拆桥】",
  ["rouge_fuyiqu__duel"] = "拂衣去决",
  [":rouge_fuyiqu__duel"] = "你的回合开始时，你获得1张【决斗】",
  ["rouge_fuyiqu__iron_chain"] = "拂衣去锁",
  [":rouge_fuyiqu__iron_chain"] = "你的回合开始时，你获得1张【铁索连环】",
  ["rouge_fuyiqu__snatch"] = "拂衣去顺",
  [":rouge_fuyiqu__snatch"] = "你的回合开始时，你获得1张【顺手牵羊】",

  ["rouge_fenjin"] = "奋进",
  [":rouge_fenjin"] = "当体力大于2点，回合开始时失去1点体力并摸2张牌",

  ["rouge_yuanmou"] = "远谋Ⅰ",
  [":rouge_yuanmou"] = "第3轮你的回合开始时，你回复2点体力",
  ["rouge_yuanmou2"] = "远谋Ⅱ",
  [":rouge_yuanmou2"] = "第3轮你的回合开始时，你回复3点体力",
  ["rouge_yuanmou3"] = "远谋Ⅲ",
  [":rouge_yuanmou3"] = "第2轮你的回合开始时，你回复2点体力",

  ["rouge_xuezhan1"] = "血战Ⅰ",
  [":rouge_xuezhan1"] = "体力上限-1（最低为1），每轮开始时回复1点体力",
  ["rouge_xuezhan2"] = "血战Ⅱ",
  [":rouge_xuezhan2"] = "体力上限-2（最低为1），每轮开始时回复2点体力",
  ["rouge_xuezhan3"] = "血战Ⅲ",
  [":rouge_xuezhan3"] = "体力上限-3（最低为1），每轮开始时回复3点体力",

}

-- 额定摸牌数相关：布阵、...

RougeUtil:addBuffTalent { 2, "rouge_buzhen" }
RougeUtil:addBuffTalent { 1, "rouge_buzhen2" }
RougeUtil:addBuffTalent { 1, "rouge_buzhen3" }
RougeUtil:addBuffTalent { 3, "rouge_duanliangcao2" }
RougeUtil:addBuffTalent { 2, "rouge_chijiuzhan3" }
RougeUtil:addBuffTalent { 1, "rouge_kuangbao3" }
RougeUtil:addBuffTalent { 2, "rouge_kuangbao4" }
RougeUtil:addBuffTalent { 2, "rouge_mopai" }
RougeUtil:addBuffTalent { 4, "rouge_mopai2" }
RougeUtil:addBuffTalent { 2, "rouge_houfaxianzhi" }
RougeUtil:addBuffTalent { 3, "rouge_muniuliuma" }
RougeUtil:addBuffTalent { 4, "rouge_wendinghouqin" }
rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_rule_draw_n_cards",
  events = { fk.DrawNCards },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return (target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_buzhen", "rouge_buzhen2", "rouge_buzhen3", "rouge_chijiuzhan3",
        "rouge_kuangbao3", "rouge_kuangbao4", "rouge_mopai", "rouge_mopai2",
        "rouge_houfaxianzhi", "rouge_muniuliuma", "rouge_wendinghouqin" })) or (
      RougeUtil.isEnemy(player, target) and RougeUtil.hasOneOfTalents(player,
        { "rouge_duanliangcao2" })
    )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    if RougeUtil.hasTalent(player, "rouge_wendinghouqin") then
      RougeUtil.sendTalentLog(player, "rouge_wendinghouqin")
      data.n = 5
      data.locked = true
      return true -- TODO: 强制截停
    end

    if RougeUtil.hasTalent(player, "rouge_buzhen") then
      if room:getTag("RoundCount") >= 3 then
        RougeUtil.sendTalentLog(player, "rouge_buzhen")
        data.n = data.n + 1
      end
    end
    if RougeUtil.hasTalent(player, "rouge_buzhen2") then
      if room:getTag("RoundCount") >= 5 then
        RougeUtil.sendTalentLog(player, "rouge_buzhen2")
        data.n = data.n + 1
      end
    end
    if RougeUtil.hasTalent(player, "rouge_buzhen3") then
      if room:getTag("RoundCount") >= 7 then
        RougeUtil.sendTalentLog(player, "rouge_buzhen3")
        data.n = data.n + 1
      end
    end

    if RougeUtil.hasTalent(player, "rouge_duanliangcao2") then
      RougeUtil.sendTalentLog(player, "rouge_duanliangcao2")
      data.n = data.n - 1
    end

    if RougeUtil.hasTalent(player, "rouge_chijiuzhan3") then
      if player:getMark("rouge_money") >= 7 then
        RougeUtil.sendTalentLog(player, "rouge_chijiuzhan3")
        data.n = data.n + 1
      end
    end

    if RougeUtil.hasTalent(player, "rouge_kuangbao3") then
      if player.hp <= 3 then
        RougeUtil.sendTalentLog(player, "rouge_kuangbao3")
        data.n = data.n + 1
      end
    end
    if RougeUtil.hasTalent(player, "rouge_kuangbao4") then
      if player.hp <= 5 then
        RougeUtil.sendTalentLog(player, "rouge_kuangbao4")
        data.n = data.n + 1
      end
    end

    if RougeUtil.hasTalent(player, "rouge_mopai") then
      RougeUtil.sendTalentLog(player, "rouge_mopai")
      data.n = data.n + 1
    end
    if RougeUtil.hasTalent(player, "rouge_mopai2") then
      RougeUtil.sendTalentLog(player, "rouge_mopai2")
      data.n = data.n + 2
    end

    if RougeUtil.hasTalent(player, "rouge_houfaxianzhi") then
      RougeUtil.sendTalentLog(player, "rouge_houfaxianzhi")
      data.n = math.max(data.n - 1, 0)
    end

    if RougeUtil.hasTalent(player, "rouge_muniuliuma") then
      RougeUtil.sendTalentLog(player, "rouge_muniuliuma")
      data.n = data.n + 2
    end
  end
})
Fk:loadTranslationTable {
  ["rouge_buzhen"] = "布阵Ⅰ",
  [":rouge_buzhen"] = "从第3轮开始，你的摸牌数+1",
  ["rouge_buzhen2"] = "布阵Ⅱ",
  [":rouge_buzhen2"] = "从第5轮开始，你的摸牌数+1",
  ["rouge_buzhen3"] = "布阵Ⅲ",
  [":rouge_buzhen3"] = "从第7轮开始，你的摸牌数+1",

  ["rouge_duanliangcao2"] = "断粮草Ⅱ",
  [":rouge_duanliangcao2"] = "敌方摸牌数-1",

  ["rouge_chijiuzhan3"] = "持久战Ⅲ",
  [":rouge_chijiuzhan3"] = "虎符数量达到7后，摸牌数+1",

  ["rouge_kuangbao3"] = "狂暴Ⅲ",
  [":rouge_kuangbao3"] = "当你的体力值不大于3时，你摸牌数+1",
  ["rouge_kuangbao4"] = "狂暴Ⅳ",
  [":rouge_kuangbao4"] = "当你的体力值不大于5时，你摸牌数+1",

  ["rouge_mopai"] = "摸牌Ⅰ",
  [":rouge_mopai"] = "摸牌阶段，你的摸牌数+1",
  ["rouge_mopai2"] = "摸牌Ⅱ",
  [":rouge_mopai2"] = "摸牌阶段，你的摸牌数+2",

  ["rouge_houfaxianzhi"] = "后发先至",
  [":rouge_houfaxianzhi"] = "摸牌阶段，你的摸牌数-1；你的回合结束时，你摸3张牌",

  ["rouge_muniuliuma"] = "木牛流马",
  [":rouge_muniuliuma"] = "你的摸牌阶段，你额外摸2张牌,手牌上限-1",

  ["rouge_wendinghouqin"] = "稳定后勤",
  [":rouge_wendinghouqin"] = "摸牌阶段摸牌数固定为5",
}

-- 回合结束相关：援助、...

RougeUtil:addBuffTalent { 2, "rouge_yuanzhu" }
RougeUtil:addBuffTalent { 3, "rouge_yuanzhu2" }
RougeUtil:addBuffTalent { 4, "rouge_yuanzhu3" }
RougeUtil:addBuffTalent { 2, "rouge_xvshi" }

rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_rule_turnend",
  events = { fk.TurnEnd },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_yuanzhu", "rouge_yuanzhu2", "rouge_yuanzhu3", "rouge_houfaxianzhi", "rouge_xvshi", "rouge_woxinchangdan" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
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

    if RougeUtil.hasTalent(player, "rouge_houfaxianzhi") then
      RougeUtil.sendTalentLog(player, "rouge_houfaxianzhi")
      player:drawCards(3, "rouge_houfaxianzhi")
    end

    if RougeUtil.hasTalent(player, "rouge_xvshi") then
      local play_ids = {}
      player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        if e.data[2] == Player.Play and e.end_id then
          table.insert(play_ids, {e.id, e.end_id})
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return true end
      local function PlayCheck (e)
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        return in_play and e.data[1].from == player.id and e.data[1].card.trueName == "slash"
      end
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, PlayCheck, Player.HistoryTurn) == 0
      and #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, PlayCheck, Player.HistoryTurn) == 0 then
        RougeUtil.sendTalentLog(player, "rouge_xvshi")
        player.room:setPlayerMark(player, "@@rouge_xvshi", 1)
      else
        if player:getMark("@@rouge_xvshi") > 0 then
          player.room:removePlayerMark(player, "@@rouge_xvshi")
        end
      end
    end

    if RougeUtil.hasTalent(player, "rouge_woxinchangdan") then
      if player:getMark("@rouge_woxinchangdan") > 0 then
        room:removePlayerMark(player, "@rouge_woxinchangdan", player:getMark("@rouge_woxinchangdan"))
      end
    end
  end
})
Fk:loadTranslationTable {
  ["rouge_yuanzhu"] = "援助Ⅰ",
  [":rouge_yuanzhu"] = "回合结束时，你摸1张牌",
  ["rouge_yuanzhu2"] = "援助Ⅱ",
  [":rouge_yuanzhu2"] = "回合结束时，你摸2张牌",
  ["rouge_yuanzhu3"] = "援助Ⅲ",
  [":rouge_yuanzhu3"] = "回合结束时，你摸3张牌",

  ["rouge_xvshi"] = "蓄势",
  [":rouge_xvshi"] = "本回合没出【杀】，则下回合【杀】伤害+1（最多+1）",
  ["@@rouge_xvshi"] = "蓄势",

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
RougeUtil:addBuffTalent { 3, "rouge_qianlong" }
-- TODO RougeUtil:addBuffTalent { 4, "rouge_wendingjingong" }
rule:addRelatedSkill(fk.CreateTargetModSkill {
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

    if hasTalent(player, "rouge_qianlong") then
      if player:getMark("@rougelike1v1_skill_num") > #player:getTableMark("rouge_skills") then
        ret = ret + (player:getMark("@rougelike1v1_skill_num") - #player:getTableMark("rouge_skills")) * 2
      end
    end

    if hasTalent(player, "rouge_woxinchangdan") then
      if player:getMark("@rouge_woxinchangdan") > 0 then
        ret = ret + player:getMark("@rouge_woxinchangdan")
      end
    end
    ret = ret - #table.filter(room.alive_players, function(p)
      return RougeUtil.isEnemy(player, p) and hasTalent(p, "rouge_danliangboduo")
    end)

    return ret
  end
})

Fk:loadTranslationTable {
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
  ["rouge_qianlong"] = "潜龙",
  [":rouge_qianlong"] = "每有一个已解锁的空技能槽，则出杀次数+2",
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
rule:addRelatedSkill(fk.CreateMaxCardsSkill {
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

    if hasTalent(player, "rouge_muniuliuma") then
      ret = ret - 1
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
Fk:loadTranslationTable {
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

-- 回复体力时相关
------------------------

RougeUtil:addBuffTalent { 2, "rouge_jiemeng" }
RougeUtil:addBuffTalent { 4, "rouge_shixue" }
RougeUtil:addBuffTalent { 3, "rouge_yaoli1" }
RougeUtil:addBuffTalent { 4, "rouge_yaoli2" }
rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_rule_prehprecover",
  events = { fk.PreHpRecover },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_jiemeng", "rouge_shixue", "rouge_yaoli1", "rouge_yaoli2" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_shixue") then
      sendTalentLog(player, "rouge_shixue")
      player:drawCards(1, "rouge_shixue")
    end

    if hasTalent(player, "rouge_yaoli1") then
      sendTalentLog(player, "rouge_yaoli1")
      data.num = data.num + 1
    end
    if hasTalent(player, "rouge_yaoli2") then
      sendTalentLog(player, "rouge_yaoli2")
      data.num = data.num + 2
    end

    if hasTalent(player, "rouge_jiemeng") and data.card and data.card.trueName == "god_salvation" then
      local use = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if use then
        use = use.data[1]
        if use.from and room:getPlayerById(use.from).role == player.role then
          sendTalentLog(player, "rouge_jiemeng")
          data.num = data.num * 2
        end
      end
    end
  end
})
Fk:loadTranslationTable {
  ["rouge_jiemeng"] = "结盟",
  [":rouge_jiemeng"] = "你使用的【桃园结义】友方角色回复双倍体力",
  ["rouge_shixue"] = "噬血Ⅰ",
  [":rouge_shixue"] = "回复体力时，摸1张牌",
  ["rouge_yaoli1"] = "药理Ⅰ",
  [":rouge_yaoli1"] = "回复体力时，额外回复1点",
  ["rouge_yaoli2"] = "药理Ⅱ",
  [":rouge_yaoli2"] = "回复体力时，额外回复2点",
}

-- 造成伤害时相关
------------------------

RougeUtil:addBuffTalent { 1, "rouge_zhongjiji" }
rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_zhongjiji",
  events = { fk.DamageCaused },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return hasTalent(player, "rouge_zhongjiji") and data.damage >= 3 and
        data.to.role ~= data.from.role
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    sendTalentLog(player, "rouge_zhongjiji")
    player:drawCards(1, "rouge_zhongjiji")
  end
})
RougeUtil:addBuffTalent { 1, "rouge_yuanjiji" }
rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_yuanjiji",
  events = { fk.DamageCaused },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if RougeUtil.hasOneOfTalents(player, { "rouge_yuanjiji", "rouge_xvshi" }) then
      if hasTalent(player, "rouge_yuanjiji") then
        return player:distanceTo(data.to) > 1
      elseif hasTalent(player, "rouge_xvshi") then
        return data.card and data.card.trueName == "slash"
            and player:getMark("@@rouge_xvshi") > 0 and player.phase ~= Player.NotActive
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if hasTalent(player, "rouge_yuanjiji") then
      sendTalentLog(player, "rouge_yuanjiji")
      data.damage = data.damage + 1
    elseif hasTalent(player, "rouge_xvshi") then
      sendTalentLog(player, "rouge_xvshi")
      data.damage = data.damage + 1
    end
  end
})


RougeUtil:addBuffTalent { 3, "rouge_yuzhanyuyong1" }
RougeUtil:addBuffTalent { 2, "rouge_yuzhanyuyong2" }
RougeUtil:addBuffTalent { 1, "rouge_yuzhanyuyong3" }
RougeUtil:addBuffTalent { 4, "rouge_wendingshiqi" }
RougeUtil:addBuffTalent { 3, "rouge_tijiashu" }
RougeUtil:addBuffTalent { 2, "rouge_sanbanfu1" }
RougeUtil:addBuffTalent { 4, "rouge_sanbanfu2" }
RougeUtil:addBuffTalent { 4, "rouge_ruoxi" }
RougeUtil:addBuffTalent { 3, "rouge_miaoji1" }
RougeUtil:addBuffTalent { 4, "rouge_miaoji2" }
RougeUtil:addBuffTalent { 2, "rouge_leihuoshi1" }
RougeUtil:addBuffTalent { 4, "rouge_leihuoshi2" }
RougeUtil:addBuffTalent { 1, "rouge_kuangbao1" }
RougeUtil:addBuffTalent { 3, "rouge_kuangbao2" }
RougeUtil:addBuffTalent { 2, "rouge_jiyi1" }
RougeUtil:addBuffTalent { 4, "rouge_jiyi2" }
RougeUtil:addBuffTalent { 2, "rouge_guangongren" }
RougeUtil:addBuffTalent { 1, "rouge_geshandaniu" }
RougeUtil:addBuffTalent { 3, "rouge_dangtouyibang1" }
RougeUtil:addBuffTalent { 4, "rouge_dangtouyibang2" }


Fk:loadTranslationTable {
  ["rouge_zhongjiji"] = "重击技",
  [":rouge_zhongjiji"] = "对敌方造成伤害一次大于等于3点时，摸1张牌",
  ["rouge_yuanjiji"] = "远击技",
  [":rouge_yuanjiji"] = "造成伤害时，若你与其距离大于1，此伤害+1",
  ["rouge_yuzhanyuyong1"] = "愈战愈勇Ⅰ",
  [":rouge_yuzhanyuyong1"] = "从第3轮开始，你的【杀】造成的伤害+1",
  ["rouge_yuzhanyuyong2"] = "愈战愈勇Ⅱ",
  [":rouge_yuzhanyuyong2"] = "从第5轮开始，你的【杀】造成的伤害+1",
  ["rouge_yuzhanyuyong3"] = "愈战愈勇Ⅲ",
  [":rouge_yuzhanyuyong3"] = "从第7轮开始，你的【杀】造成的伤害+1",
  ["rouge_wendingshiqi"] = "稳定士气",
  [":rouge_wendingshiqi"] = "您的所有伤害值固定为2",
  ["rouge_tijiashu"] = "剔甲术",
  [":rouge_tijiashu"] = "对护甲造成双倍伤害",
  ["rouge_sanbanfu1"] = "三板斧Ⅰ",
  [":rouge_sanbanfu1"] = "你的每第3张【杀】伤害+1",
  ["rouge_sanbanfu2"] = "三板斧Ⅱ",
  [":rouge_sanbanfu2"] = "你的每第3张【杀】伤害+2",
  ["rouge_ruoxi"] = "弱袭",
  [":rouge_ruoxi"] = "你的手牌小于当前体力时，你造成的伤害+1",
  ["rouge_miaoji1"] = "妙技Ⅰ",
  [":rouge_miaoji1"] = "每回合首张锦囊造成的伤害+1",
  ["rouge_miaoji2"] = "妙技Ⅱ",
  [":rouge_miaoji2"] = "每回合前2张锦囊造成的伤害+1",
  ["rouge_leihuoshi1"] = "雷火势Ⅰ",
  [":rouge_leihuoshi1"] = "每回合限1次，你使用的第1张属性【杀】伤害+1",
  ["rouge_leihuoshi2"] = "雷火势Ⅱ",
  [":rouge_leihuoshi2"] = "每回合限1次，你使用的第1张属性【杀】伤害+2",
  ["rouge_kuangbao1"] = "狂暴Ⅰ",
  [":rouge_kuangbao1"] = "当你的体力值不大于2时，你造成的伤害+1",
  ["rouge_kuangbao2"] = "狂暴Ⅱ",
  [":rouge_kuangbao2"] = "当你的体力值不大于3时，你造成的伤害+1",
  ["rouge_jiyi1"] = "技艺Ⅰ",
  [":rouge_jiyi1"] = "当你的技能直接造成伤害时，此伤害+1",
  ["rouge_jiyi2"] = "技艺Ⅱ",
  [":rouge_jiyi2"] = "当你的技能直接造成伤害时，此伤害+2",
  ["rouge_guangongren"] = "关公刃",
  [":rouge_guangongren"] = "红桃【杀】伤害+1",
  ["rouge_geshandaniu"] = "隔山打牛",
  [":rouge_geshandaniu"] = "你对其他人造成伤害时，无视其护甲",
  ["rouge_dangtouyibang1"] = "当头一棒Ⅰ",
  [":rouge_dangtouyibang1"] = "每轮，你的首张【杀】伤害+1",
  ["rouge_dangtouyibang2"] = "当头一棒Ⅱ",
  [":rouge_dangtouyibang2"] = "每轮，你的首张【杀】伤害+2",
}



-- 卡牌使用/指定目标时相关
---------------------------
RougeUtil:addBuffTalent { 3, "rouge_zuiquan" }


rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_AfterCardTargetDeclared",
  events = { fk.AfterCardTargetDeclared },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if hasTalent(player, "rouge_zuiquan") and data.card and data.card.trueName == "slash" then
      return ((data.extra_data or {}).drankBuff or 0)>0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room=player.room
    sendTalentLog(player,"rouge_zuiquan")
    data.unoffsetableList = table.map(room.alive_players, Util.IdMapper)
  end
})

RougeUtil:addBuffTalent { 4, "rouge_yinyangshufa" }

rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_PreCardEffect_yinyangshufa",
  events = { fk.PreCardEffect },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if RougeUtil.hasOneOfTalents(player, {"rouge_yinyangshufa" }) and data.card then
      if hasTalent(player, "rouge_yinyangshufa") and data.card.type == Card.TypeTrick and data.card.is_damage_card == true then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room=player.room
    if hasTalent(player, "rouge_yinyangshufa") then
      sendTalentLog(player, "rouge_yinyangshufa")
      for _, to in ipairs(data.tos) do
        if RougeUtil.isEnemy(player,room:getPlayerById(to[1])) then
          data.disresponsiveList = data.disresponsiveList or {}
          table.insertIfNeed(data.disresponsiveList,to[1])
        end
      end
    end
  end
})


RougeUtil:addBuffTalent { 1, "rouge_xvlijian" }


local rouge_xvlijian__archery_attack_skill = fk.CreateActiveSkill{
  name = "rouge_xvlijian__archery_attack_skill",
  prompt = "#rouge_xvlijian__archery_attack_skill",
  mute=true,
  can_use = Util.AoeCanUse,
  on_use = Util.AoeOnUse,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return user ~= to_select
  end,
  on_effect = function(self, room, effect)
    local cardResponded = room:askForResponse(room:getPlayerById(effect.to), 'jink', nil, nil, true, nil, effect)
    if cardResponded then
      room:responseCard({
        from = effect.to,
        card = cardResponded,
        responseToEvent = effect,
      })
      cardResponded = room:askForResponse(room:getPlayerById(effect.to), 'jink', nil, nil, true, nil, effect)
      if cardResponded then
        room:responseCard({
          from = effect.to,
          card = cardResponded,
          responseToEvent = effect,
        })
      else
        room:damage({
          from = room:getPlayerById(effect.from),
          to = room:getPlayerById(effect.to),
          card = effect.card,
          damage = 1,
          damageType = fk.NormalDamage,
          skillName = self.name,
        })
      end
    else
      room:damage({
        from = room:getPlayerById(effect.from),
        to = room:getPlayerById(effect.to),
        card = effect.card,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = self.name,
      })
    end
  end
}

local rouge_xvlijian_trigger = fk.CreateTriggerSkill {
  name = "#rougelike1v1_PreCardEffect_rouge_xvlijian",
  events = { fk.PreCardEffect },
  mute = true,
  priority = 0.002,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return hasTalent(player, "rouge_xvlijian") and data.from == player.id and data.card.trueName == "archery_attack"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    sendTalentLog(player,"rouge_xvlijian")
    card.skill = rouge_xvlijian__archery_attack_skill
    data.card = card
  end,
}

Fk:addSkill(rouge_xvlijian__archery_attack_skill)
rule:addRelatedSkill(rouge_xvlijian_trigger)



RougeUtil:addBuffTalent { 3, "rouge_yingjifangan" }
RougeUtil:addBuffTalent { 3, "rouge_yingjizhanshu" }
RougeUtil:addBuffTalent { 4, "rouge_yingjizhanlv" }

rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_TargetConfirming",
  events = { fk.TargetConfirming },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if RougeUtil.hasOneOfTalents(player, { "rouge_yingjifangan", "rouge_yingjizhanshu", "rouge_yingjizhanlv" })
        and data.card and data.from and not player.room:getPlayerById(data.from):isNude() and #data.tos[1] == 1 and
        player.phase == Player.NotActive and RougeUtil.isEnemy(player, player.room:getPlayerById(data.from)) then
      if hasTalent(player, "rouge_yingjifangan") then
        return data.card.type == Card.TypeBasic
      elseif hasTalent(player, "rouge_yingjizhanshu") then
        return data.card.type == Card.TypeTrick
      elseif hasTalent(player, "rouge_yingjizhanlv") then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room, skilName = player.room, ""
    local targetPlayer = room:getPlayerById(data.from)
    local target_card = table.random(targetPlayer:getCardIds("he"))
    if hasTalent(player, "rouge_yingjifangan") then
      skilName = "rouge_yingjifangan"
      room:throwCard(target_card, skilName, targetPlayer, player)
    elseif hasTalent(player, "rouge_yingjizhanshu") then
      skilName = "rouge_yingjizhanshu"
      room:throwCard(target_card, skilName, targetPlayer, player)
    elseif hasTalent(player, "rouge_yingjizhanlv") then
      skilName = "rouge_yingjizhanlv"
      room:throwCard(target_card, skilName, targetPlayer, player)
    end
    sendTalentLog(player, skilName)
  end
})


RougeUtil:addBuffTalent { 2, "rouge_zhudao1" }
RougeUtil:addBuffTalent { 3, "rouge_zhudao2" }
rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_CardUseFinished",
  events = { fk.CardUseFinished },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return RougeUtil.hasOneOfTalents(player, { "rouge_zhudao1", "rouge_zhudao2" }) and data.card
        and data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 1
    local skillName = "rouge_zhudao1"
    if hasTalent(player, "rouge_zhudao2") then
      num = 2
      skillName = "rouge_zhudao2"
    end
    sendTalentLog(player, skillName)
    local choice_cards = room:askForCard(player, 1, num, true, skillName, true, ".", "#rouge_zhudao:::" .. num)
    room:recastCard(choice_cards, player, skillName)
  end
})



RougeUtil:addBuffTalent { 1, "rouge_xvyan" }

local rouge_xvyan__fireAttackSkill = fk.CreateActiveSkill {
  name = "rouge_xvyan__fire_attack_skill",
  prompt = "#rouge_xvyan__fire_attack_skill",
  target_num = 1,
  mute=true,
  mod_target_filter = function(_, to_select, _, _, _, _)
    return not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_filter = function(self, to_select, selected, _, card)
    if #selected < self:getMaxTargetNum(Self, card) then
      return self:modTargetFilter(to_select, selected, Self.id, card)
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    local from = room:getPlayerById(cardEffectEvent.from)
    local to = room:getPlayerById(cardEffectEvent.to)
    if to:isKongcheng() then return end

    local showCard = room:askForCard(to, 1, 1, false, self.name, false, ".|.|.|hand",
      "#rouge_xvyan__fire_attack_skill-show1:" .. from.id)[1]
    to:showCards(showCard)

    showCard = Fk:getCardById(showCard)
    local color_string = "."
    if showCard.color == Card.Red then
      color_string = "heart,diamond"
    elseif showCard.color == Card.Black then
      color_string = "spade,club"
    end
    local cards = room:askForCard(from, 1, 1, false, self.name, false, ".|.|" .. color_string,
      "#rouge_xvyan__fire_attack_skill-show2")
    if #cards > 0 then
      sendTalentLog(from, "rouge_xvyan")
      from:showCards(cards)
      room:damage({
        from = from,
        to = to,
        card = cardEffectEvent.card,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name
      })
    end
  end,
}

local rouge_xvyan_trigger = fk.CreateTriggerSkill {
  name = "#rougelike1v1_PreCardEffect_rouge_xvyan",
  events = { fk.PreCardEffect },
  mute = true,
  priority = 0.002,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return hasTalent(player, "rouge_xvyan") and data.from == player.id and data.card.trueName == "fire_attack"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = rouge_xvyan__fireAttackSkill
    data.card = card
  end,
}

Fk:addSkill(rouge_xvyan__fireAttackSkill)
rule:addRelatedSkill(rouge_xvyan_trigger)


Fk:loadTranslationTable {
  ["rouge_zuiquan"] = "醉拳",
  [":rouge_zuiquan"] = "【酒】【杀】不能被抵消",
  ["rouge_yinyangshufa"] = "阴阳术法",
  ["#rougelike1v1_PreCardEffect_yinyangshufa"]= "阴阳术法",
  [":rouge_yinyangshufa"] = "敌方无法响应你的伤害型锦囊牌",
  ["rouge_xvlijian"] = "蓄力箭",
  [":rouge_xvlijian"] = "你使用的【万箭齐发】其他角色需要使用2张【闪】来响应",
  ["rouge_xvlijian__archery_attack_skill"]= "蓄力箭",
  ["#rouge_xvlijian__archery_attack_skill"]= "蓄力箭:你使用的【万箭齐发】其他角色需要使用2张【闪】来响应",
  ["#rougelike1v1_PreCardEffect_rouge_xvlijian"]= "蓄力箭",
  ["rouge_zhudao1"] = "铸刀Ⅰ",
  [":rouge_zhudao1"] = "你使用【杀】后可以至多重铸1张牌",
  ["rouge_zhudao2"] = "铸刀Ⅱ",
  [":rouge_zhudao2"] = "你使用【杀】后可以至多重铸2张牌",
  ["#rouge_zhudao"] = "铸刀:你可以至多重铸%arg张牌",
  ["rouge_yingjifangan"] = "应急方案",
  [":rouge_yingjifangan"] = "回合外成为敌方角色基本牌唯一目标，随机弃置来源1张牌",
  ["rouge_yingjizhanshu"] = "应急战术",
  [":rouge_yingjizhanshu"] = "回合外成为敌方角色锦囊牌唯一目标，随机弃置来源1张牌",
  ["rouge_yingjizhanlv"] = "应急战略",
  [":rouge_yingjizhanlv"] = "回合外成为敌方角色使用牌唯一目标，随机弃置来源1张牌",
  ["rouge_xvyan"] = "虚焰",
  [":rouge_xvyan"] = "【火攻】弃置改为展示",
  ["rouge_xvyan__fire_attack_skill"] = "虚焰",
  ["#rouge_xvyan__fire_attack_skill"] = "虚焰:你使用【火攻】的弃置牌改为展示牌",
  ["#rouge_xvyan__fire_attack_skill-show1"] = "虚焰：你需要对【%src】展示一张火攻牌。",
  ["#rouge_xvyan__fire_attack_skill-show2"] = "虚焰：你可以展示一张与展示牌相同花色的牌，然后对其造成1点火焰伤害。"

}


-- 受到伤害时相关
---------------------------
RougeUtil:addBuffTalent { 2, "rouge_yongzhan1" }
RougeUtil:addBuffTalent { 4, "rouge_yongzhan2" }

rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_AfterDying",
  events = { fk.AfterDying },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return RougeUtil.hasOneOfTalents(player, { "rouge_yongzhan1", "rouge_yongzhan2" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 1
    local skillName = "rouge_yongzhan1"
    if hasTalent(player, "rouge_yongzhan2") then
      skillName = "rouge_yongzhan2"
      num = 2
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if RougeUtil.isEnemy(player, p) then
        sendTalentLog(player, skillName)
        room:damage({
          from = player,
          to = p,
          damage = num,
          skillName = skillName
        })
      end
    end
  end
})

RougeUtil:addBuffTalent { 1, "rouge_xialuxiangfeng" }
RougeUtil:addBuffTalent { 3, "rouge_woxinchangdan" }

rule:addRelatedSkill(fk.CreateTriggerSkill {
  name = "#rougelike1v1_Damaged",
  events = { fk.Damaged },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return RougeUtil.hasOneOfTalents(player, { "rouge_xialuxiangfeng", "rouge_woxinchangdan" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_xialuxiangfeng") and data.card and data.card.trueName == "duel" then
      sendTalentLog(player, "rouge_xialuxiangfeng")
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "rouge_xialuxiangfeng"
      })
    end
    if hasTalent(player, "rouge_woxinchangdan") and player.phase == Player.NotActive then
      sendTalentLog(player, "rouge_woxinchangdan")
      room:addPlayerMark(player, "@rouge_woxinchangdan", 1)
    end
  end
})


Fk:loadTranslationTable {
  ["rouge_yongzhan1"] = "勇战Ⅰ",
  [":rouge_yongzhan1"] = "你离开濒死时，对所有敌方造成1点伤害",
  ["rouge_yongzhan2"] = "勇战Ⅱ",
  [":rouge_yongzhan2"] = "你离开濒死时，对所有敌方造成2点伤害",
  ["rouge_xialuxiangfeng"] = "狭路相逢",
  [":rouge_xialuxiangfeng"] = "受到【决斗】伤害后回复1点体力",
  ["rouge_woxinchangdan"] = "卧薪尝胆",
  [":rouge_woxinchangdan"] = "回合外每受到1次伤害，下回合出杀次数+1",
  ["@rouge_woxinchangdan"] = "卧薪尝胆",

}


-- 状态技
---------------------------

RougeUtil:addBuffTalent { 1, "rouge_yanxian" }
RougeUtil:addBuffTalent { 1, "rouge_qiangquhaoduo" }

local rouge_yanxian = fk.CreateVisibilitySkill {
  name = "#rougelike1v1_Visibility",
  mute = true,
  global = true,
  frequency = Skill.Compulsory,
  card_visible = function(self, player, card)
    if (hasTalent(player, "rouge_yanxian")or hasTalent(player, "rouge_qiangquhaoduo") ) and card:getMark("@rouge_yanxian") > 0 then
      return true
    end
  end
}

local rouge_yanxian_trigger = fk.CreateTriggerSkill {
  name = "#rougelike1v1_PreEffect_Visibility",
  events = { fk.PreCardEffect },
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if hasTalent(player, "rouge_yanxian") then
      return data.card and data.card.trueName == "dismantlement" 
    elseif hasTalent(player, "rouge_qiangquhaoduo") then
      return data.card and data.card.trueName == "snatch"
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(data.tos) do
      local targetPlayer = room:getPlayerById(to[1])
      if targetPlayer:isKongcheng() then return end
      if data.card.trueName == "snatch" then
        sendTalentLog(player, "rouge_qiangquhaoduo")
      else
        sendTalentLog(player, "rouge_yanxian")
      end
      for _, cid in ipairs(targetPlayer:getCardIds("h")) do
        local card_true = Fk:getCardById(cid)
        room:setCardMark(card_true, "@rouge_yanxian", 1)
      end
    end
    
  end
}

local rouge_yanxian_effectfinished= fk.CreateTriggerSkill {
  name = "#rouge_yanxian_effectfinished",
  events = { fk.CardEffectFinished },
  priority = 0.002,
  mute = true,
  global=true,
  can_trigger = function(self, event, target, player, data)
    return data.card and (data.card.trueName=="dismantlement" or data.card.trueName=="snatch") and not player:isKongcheng()
       and table.find(player:getCardIds("h"),function (cid)
      return Fk:getCardById(cid):getMark("@rouge_yanxian")>0
    end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, cid in ipairs(player:getCardIds("h")) do
      local card_true=Fk:getCardById(cid)
      room:removeCardMark(card_true,"@rouge_yanxian",card_true:getMark("@rouge_yanxian"))
    end
    
  end
}

rouge_yanxian_trigger:addRelatedSkill(rouge_yanxian_effectfinished)
Fk:addSkill(rouge_yanxian)
rule:addRelatedSkill(rouge_yanxian_trigger)

Fk:loadTranslationTable {
  ["rouge_yanxian"] = "眼线",
  ["@rouge_yanxian"] = "明牌",
  [":rouge_yanxian"] = "【过河拆桥】时目标手牌可见",
  ["rouge_qiangquhaoduo"] = "强取豪夺",
  [":rouge_qiangquhaoduo"] = "【顺手牵羊】时目标手牌可见",
  ["#rougelike1v1_PreEffect_Visibility"]="战法：眼线/强夺豪取"
}

-- Misc: 系统耦合类
------------------------

RougeUtil:addTalent { 4, "rouge_shangdao", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:addPlayerMark(player, "rougelike1v1_shop_num", 1)
end }

RougeUtil:addTalent { 3, "rouge_yunchouweiwo", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:addPlayerMark(player, "@rougelike1v1_skill_num", 1)
end }

Fk:loadTranslationTable {
  ["rouge_shangdao"] = "商道",
  [":rouge_shangdao"] = "商店中商品展示数量+1",

  ["rouge_yunchouweiwo"] = "运筹帷幄",
  [":rouge_yunchouweiwo"] = "技能槽上限+1",
}

Fk:addSkill(rule)
return rule
