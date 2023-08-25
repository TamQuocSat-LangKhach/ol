local extension = Package("ol_other")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_other"] = "OL-其他",
  ["qin"] = "秦",
}

local godzhenji = General(extension, "godzhenji", "god", 3, 3, General.Female)
local shenfu = fk.CreateTriggerSkill{
  name = "shenfu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player.player_cards[Player.Hand] % 2 == 1 then
      while true do
        local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
          return p.id end), 1, 1, "#shenfu-damage", self.name, true)
        if #tos > 0 then
          local to = room:getPlayerById(tos[1])
          room:damage{
            from = player,
            to = to,
            damage = 1,
            damageType = fk.ThunderDamage,
            skillName = self.name,
          }
          if not to.dead then return end
        else
          return
        end
      end
    else
      while true do
        local tos = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
          return p:getMark("shenfu-turn") == 0 end), function(p) return p.id end),
          1, 1, "#shenfu-hand", self.name, true)
        if #tos > 0 then
          local to = room:getPlayerById(tos[1])
          room:addPlayerMark(to, "shenfu-turn", 1)
          if to:isKongcheng() then
            to:drawCards(1, self.name)
          else
            local choice = room:askForChoice(player, {"shenfu_draw", "shenfu_discard"}, self.name)
            if choice == "shenfu_draw" then
              to:drawCards(1, self.name)
            else
              local card = room:askForCardsChosen(player, to, 1, 1, "h", self.name)
              room:throwCard(card, self.name, to, player)
            end
            if #to.player_cards[Player.Hand] ~= to.hp then return end
          end
        else
          return
        end
      end
    end
  end,
}
local qixian = fk.CreateMaxCardsSkill{
  name = "qixian",
  fixed_func = function (self, player)
    if player:hasSkill(self.name) then
      return 7
    end
  end,
}
godzhenji:addSkill(shenfu)
godzhenji:addSkill(qixian)
Fk:loadTranslationTable{
  ["godzhenji"] = "神甄姬",
  ["shenfu"] = "神赋",
  [":shenfu"] = "结束阶段，如果你的手牌数量为：奇数，可对一名其他角色造成1点雷电伤害，若造成其死亡，你可重复此流程；偶数，可令一名角色摸一张牌或你弃置其一张手牌，若执行后该角色的手牌数等于其体力值，你可重复此流程（不能对本回合指定过的目标使用）。",
  ["qixian"] = "七弦",
  [":qixian"] = "锁定技，你的手牌上限为7。",
  ["#shenfu-damage"] = "神赋：你可以对一名其他角色造成1点雷电伤害",
  ["#shenfu-hand"] = "神赋：你可以令一名角色摸一张牌或你弃置其一张手牌",
  ["shenfu_draw"] = "其摸一张牌",
  ["shenfu_discard"] = "你弃置其一张手牌",

  ["$shenfu1"] = "河洛之神，诗赋可抒。",
  ["$shenfu2"] = "云神鱼游，罗扇掩面。",
  ["~godzhenji"] = "众口铄金，难证吾清……",
}

local godcaopi = General(extension, "godcaopi", "god", 5)
local chuyuan = fk.CreateTriggerSkill{
  name = "chuyuan",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and #player:getPile("caopi_chu") < player.maxHp and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#chuyuan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    target:drawCards(1, self.name)
    if target:isKongcheng() then return end
    local card = room:askForCard(target, 1, 1, false, self.name, false, ".", "#chuyuan-card:"..player.id)
    player:addToPile("caopi_chu", card, false, self.name)
  end,
}
local dengji = fk.CreateTriggerSkill{
  name = "dengji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("caopi_chu"))
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    room:handleAddLoseSkills(player, "ex__jianxiong|tianxing", nil)
  end,
}
local tianxing = fk.CreateTriggerSkill{
  name = "tianxing",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("caopi_chu"))
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    local choice = room:askForChoice(player, {"rende", "ex__zhiheng", "ol_ex__luanji"}, self.name, "#tianxing-choice", true)  --TODO:ex__rende
    room:handleAddLoseSkills(player, choice.."|-chuyuan", nil)
  end,
}
godcaopi:addSkill(chuyuan)
godcaopi:addSkill(dengji)
godcaopi:addRelatedSkill("ex__jianxiong")
godcaopi:addRelatedSkill(tianxing)
godcaopi:addRelatedSkill("rende")
godcaopi:addRelatedSkill("ex__zhiheng")
godcaopi:addRelatedSkill("ol_ex__luanji")
Fk:loadTranslationTable{
  ["godcaopi"] = "神曹丕",
  ["chuyuan"] = "储元",
  [":chuyuan"] = "当一名角色受到伤害后，若你的“储”数小于你的体力上限，你可以令其摸一张牌，然后其将一张手牌置于你的武将牌上，称为“储”。",
  ["dengji"] = "登极",
  [":dengji"] = "觉醒技，准备阶段，若你的“储”数不小于3，你减1点体力上限，获得所有“储”，获得〖奸雄〗和〖天行〗。",
  ["tianxing"] = "天行",
  [":tianxing"] = "觉醒技，准备阶段，若你的“储”数不小于3，你减1点体力上限，获得所有“储”，失去〖储元〗，并获得下列技能中的一项：〖仁德〗、〖制衡〗、〖乱击〗。",
  ["#chuyuan-invoke"] = "储元：你可以令 %dest 摸一张牌，然后其将一张手牌置为“储”",
  ["caopi_chu"] = "储",
  ["#chuyuan-card"] = "储元：将一张手牌作为“储”置于 %src 武将牌上",
  ["#tianxing-choice"] = "天行：选择获得的技能",

  ["$chuyuan1"] = "储君之位，囊中之物。",
  ["$chuyuan2"] = "此役，我之胜。",
  ["$dengji1"] = "登高位，享极乐。",
  ["$dengji2"] = "今日，便是我称帝之时。",
  ["$tianxing1"] = "孤之行，天之意。",
  ["$tianxing2"] = "我做的决定，便是天的旨意。",
  ["$jianxiong1-godcaopi"] = "孤之所长，继父之所长。",
  ["$jianxiong2-godcaopi"] = "乱世枭雄，哼，孤亦是。",
  ["$rende-godcaopi"] = "这些都是孤赏赐给你的。",
  ["$zhiheng-godcaopi"] = "有些事情，还需多加思索。",
  ["$luanji-godcaopi"] = "违逆我的，都该处罚。",
  ["$fangquan-godcaopi"] = "此等小事，你们处理即可。",
  ["~godcaopi"] = "曹魏锦绣，孤还未看尽……",
}

local lvbu3 = General(extension, "hulao__godlvbu3", "god", 4)
lvbu3.hidden = true

local shenqu = fk.CreateTriggerSkill{
  name = "shenqu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player:hasSkill(self.name) and target.phase == Player.Start and player:getHandcardNum() <= player.maxHp
    elseif event == fk.Damaged then
      return player:hasSkill(self.name) and player == target
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#shenqu-invoke")
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      player:drawCards(2, self.name)
    else
      local use = player.room:askForUseCard(player, "peach", "peach", "#shenqu-use", true)
      if use then
        player.room:useCard(use)
      end
    end
  end,
}

local jiwu = fk.CreateActiveSkill{
  name = "jiwu",
  anim_type = "offensive",
  mute = true,
  card_num = 1,
  target_num = 0,
  interaction = function(self)
    local jiwu_skills = table.filter({"ol_ex__qiangxi", "ex__tieji", "ty_ex__xuanfeng", "ol_ex__wansha"}, function (skill_name)
      return not Self:hasSkill(skill_name, true)
    end)
    if #jiwu_skills == 0 then return false end
    return UI.ComboBox { choices = jiwu_skills }
  end,
  can_use = function(self, player)
    local jiwu_skills = {"ol_ex__qiangxi", "ex__tieji", "ty_ex__xuanfeng", "ol_ex__wansha"}
    return not table.every(jiwu_skills, function (skill_name) return player:hasSkill(skill_name, true) end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local skill_name = self.interaction.data
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, math.random(2))
    room:throwCard(effect.cards, self.name, player, player)
    local jiwu_skills = type(player:getMark("jiwu_skills")) == "table" and player:getMark("jiwu_skills") or {}
    table.insertIfNeed(jiwu_skills, skill_name)
    room:setPlayerMark(player, "jiwu_skills", jiwu_skills)
    room:handleAddLoseSkills(player, skill_name, nil, true, false)
  end,
}

local jiwu_refresh = fk.CreateTriggerSkill{
  name = "#jiwu_refresh",

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and type(player:getMark("jiwu_skills")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local jiwu_skills = player:getMark("jiwu_skills")
    if #jiwu_skills > 0 then
      player.room:handleAddLoseSkills(player, "-"..table.concat(jiwu_skills, "|-"), nil, true, false)
    end
    player.room:setPlayerMark(player, "jiwu_skills", 0)
  end,
}

jiwu:addRelatedSkill(jiwu_refresh)
lvbu3:addSkill("wushuang")
lvbu3:addSkill(shenqu)
lvbu3:addSkill(jiwu)

Fk:loadTranslationTable{
  ["hulao__godlvbu3"] = "神吕布",
  ["shenqu"] = "神躯",
  [":shenqu"] = "一名角色的准备阶段，若你的手牌数不大于你的体力上限，你可摸两张牌。当你受到伤害后，你可使用一张【桃】。",
  ["jiwu"] = "极武",
  [":jiwu"] = "出牌阶段，你可以弃置一张牌，然后本回合你拥有以下其中一个技能：“强袭”、“铁骑”、“旋风”、“完杀”。",

  ["#shenqu-invoke"] = "是否使用神躯，摸两张牌",
  ["#shenqu-use"] = "神躯：你可以使用一张【桃】",
	["$shenqu1"] = "别心怀侥幸了，你们不可能赢！",
	["$shenqu2"] = "虎牢关，我一人镇守足矣。",
	["$jiwu1"] = "我！是不可战胜的！",
	["$jiwu2"] = "今天！就让你们感受一下真正的绝望！",
	["$jiwu3"] = "这么想死，那我就成全你！",
	["$jiwu4"] = "项上人头，待我来取！",
	["$jiwu5"] = "哈哈哈！破绽百出！",
	["$jiwu6"] = "我要让这虎牢关下，血流成河！",
	["$jiwu7"] = "千钧之势，力贯苍穹！",
	["$jiwu8"] = "风扫六合，威震八荒！",
	["$jiwu9"] = "蝼蚁！怎容偷生！",
	["$jiwu10"] = "沉沦吧！在这无边的恐惧！",
	["~hulao__godlvbu3"] = "你们的项上人头，我改日再取！",

}

local hanba = General(extension, "hanba", "qun", 4, 4, General.Female)
local fentian = fk.CreateTriggerSkill{
  name = "fentian",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
    player:getHandcardNum() < player.hp and table.find(player.room.alive_players, function (p)
      return player:inMyAttackRange(p) and not p:isNude()
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return player:inMyAttackRange(p) and not p:isNude()
    end)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, table.map(targets, function (p)
      return p.id end), 1, 1, "#fentian-choose", self.name, false)
    if #tos > 0 then
      local id = room:askForCardChosen(player, room:getPlayerById(tos[1]), "he", self.name)
      player:addToPile("fentian_burn", id, true, self.name)
    end
  end,
}
local fentian_attackrange = fk.CreateAttackRangeSkill{
  name = "#fentian_attackrange",
  correct_func = function (self, from, to)
    return from:hasSkill(fentian.name) and #from:getPile("fentian_burn") or 0
  end,
}
local zhiri = fk.CreateTriggerSkill{
  name = "zhiri",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("fentian_burn") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "xintan", nil)
  end,
}
local xintan = fk.CreateActiveSkill{
  name = "xintan",
  anim_type = "offensive",
  prompt = "#xintan-active",
  card_num = 2,
  target_num = 1,
  expand_pile = "fentian_burn",
  can_use = function(self, player)
    return #player:getPile("fentian_burn") > 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected_cards == 2 and #selected == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Self:getPileNameOfId(to_select) == "fentian_burn"
  end,
  on_use = function(self, room, effect)
    room:moveCards({
      from = effect.from,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
    })
    room:loseHp(room:getPlayerById(effect.tos[1]), 1, self.name)
  end,
}
fentian:addRelatedSkill(fentian_attackrange)
hanba:addSkill(fentian)
hanba:addSkill(zhiri)
hanba:addRelatedSkill(xintan)

Fk:loadTranslationTable{
  ["hanba"] = "旱魃",
  ["fentian"] = "焚天",
  [":fentian"] = "锁定技，结束阶段，若你的手牌数小于你的体力值，你将攻击范围内的一名角色的一张牌置于你的武将牌上，称为“焚”；"..
  "你的攻击范围+X（X为“焚”数）。",
  ["zhiri"] = "炙日",
  [":zhiri"] = "觉醒技，准备阶段，若你的“焚”数不小于3，你减1点体力上限，获得“心惔”。",
  ["xintan"] = "心惔",
  [":xintan"] = "出牌阶段限一次，你可将两张“焚”置入弃牌堆并选择一名角色，该角色失去1点体力。",

  ["fentian_burn"] = "焚",
  ["#fentian-choose"] = "焚天：选择一名角色，将其一张牌作为你的“焚”",
  ["#xintan-active"] = "发动心惔，选择两张“焚”牌置入弃牌堆并选择一名角色，令其失去1点体力",

	["$fentian1"] = "烈火燎原，焚天灭地！",
	["$fentian2"] = "骄阳似火，万物无生！",
	["$zhiri1"] = "好舒服，这太阳的力量！",
	["$zhiri2"] = "你以为这样就已经结束了？",
	["$xintan1"] = "让心中之火慢慢吞噬你吧！哈哈哈哈哈哈！",
	["$xintan2"] = "人人心中都有一团欲望之火！",
	["~hanba"] = "应龙，是你在呼唤我吗……",

}


--官渡群张郃 辛评 韩猛

local shangyang = General(extension, "shangyang", "qin", 4)
local qin__bianfa = fk.CreateViewAsSkill{
  name = "qin__bianfa",
  anim_type = "offensive",
  pattern = "shangyang_reform",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):isCommonTrick()
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("shangyang_reform")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
}
local qin__bianfa_trigger = fk.CreateTriggerSkill{
  name = "#qin__bianfa_trigger",
  mute = true,
  events = {fk.GameStart, fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("qin__bianfa") then
      if event == fk.GameStart then
        return true
      else
        return target == player and data.card.trueName == "shangyang_reform"
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      local room = player.room
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not table.contains(AimGroup:getAllTargets(data.tos), p.id) and
        not player:isProhibited(p, data.card) end), function(p) return p.id end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#qin__bianfa:::"..data.card:toLogString(), "qin__bianfa", true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("qin__bianfa")
    if event == fk.GameStart then
      for i = #room.void, 1, -1 do
        if Fk:getCardById(room.void[i]).trueName == "shangyang_reform" then
          local id = table.remove(room.void, i)
          table.insert(room.draw_pile, math.random(1, #room.draw_pile), id)
          room:setCardArea(id, Card.DrawPile, nil)
        end
      end
      room:notifySkillInvoked(player, "qin__bianfa", "special")
      room:doBroadcastNotify("UpdateDrawPile", tostring(#room.draw_pile))
    else
      room:notifySkillInvoked(player, "qin__bianfa", "offensive")
      TargetGroup:pushTargets(data.targetGroup, self.cost_data)
    end
  end,
}
local qin__limu = fk.CreateTriggerSkill{
  name = "qin__limu",
  anim_type = "offensive",
  events = {fk.AfterCardUseDeclared},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card:isCommonTrick() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    data.prohibitedCardNames = {"nullification"}
  end,
}
local qin__kencao = fk.CreateTriggerSkill{
  name = "qin__kencao",
  anim_type = "support",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:addPlayerMark(target, "@qin__kencao", 1)
    if target:getMark("@qin__kencao") > 2 then
      room:setPlayerMark(target, "@qin__kencao", 0)
      if target.kingdom == "qin" then
        room:changeMaxHp(target, 1)
      end
      if target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    end
  end,
}
qin__bianfa:addRelatedSkill(qin__bianfa_trigger)
shangyang:addSkill(qin__bianfa)
shangyang:addSkill(qin__limu)
shangyang:addSkill(qin__kencao)
Fk:loadTranslationTable{
  ["shangyang"] = "商鞅",
  ["qin__bianfa"] = "变法",
  [":qin__bianfa"] = "游戏开始时，将三张【商鞅变法】洗入牌堆；你使用【商鞅变法】指定目标时，可以额外指定一个目标。出牌阶段限一次，"..
  "你可以将一张普通锦囊牌当【商鞅变法】使用。",
  ["qin__limu"] = "立木",
  [":qin__limu"] = "锁定技，你使用的普通锦囊牌不能被【无懈可击】响应。",
  ["qin__kencao"] = "垦草",
  [":qin__kencao"] = "锁定技，当一名角色造成伤害后，其获得一枚“功”标记。然后若其“功”标记不小于3，其弃置所有“功”，"..
  "回复1点体力；若其为秦势力角色，则先加1点体力上限。",
  ["#qin__bianfa"] = "变法：你可以为%arg额外指定一个目标",
  ["@qin__kencao"] = "功",

  ["$qin__bianfa"] = "前世不同教，何古之法？",
  ["$qin__limu"] = "立木之言，汇聚民心。",
  ["$qin__kencao"] = "农静，诛愚乱农之民欲农，则草必垦矣。",
  ["~shangyang"] = "无人可依，变法难行……",
}

Fk:loadTranslationTable{
  ["zhangyiq"] = "张仪",
  ["qin__lianheng"] = "连横",
  [":qin__lianheng"] = "锁定技，游戏开始时，你令随机一名其他角色获得一枚“横”标记。准备阶段，弃置“横”标记，然后令随机另一名其他角色获得“横”标记。"..
  "有“横”标记的角色使用牌不能指定你为目标。",
  ["qin__xichu"] = "戏楚",
  [":qin__xichu"] = "锁定技，。",

  ["$qin__lianheng"] = "连横之术，可破合纵之策。",
  ["$qin__xichu"] = "楚王欲贪，此戏方成。",
  ["$qin__xiongbian"] = "据坛雄辩，无人可驳！",
  ["$qin__qiaoshe"] = "巧舌如簧，虚实乱象。",
  ["~zhangyiq"] = "连横之道，后世难存……",
}

local yingzheng = General(extension, "yingzheng", "qin", 4)
yingzheng.hidden = true
local qin__yitong = fk.CreateTriggerSkill{
  name = "qin__yitong",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      table.contains({"slash", "dismantlement", "snatch", "fire_attack"}, data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not player:isProhibited(p, data.card) then
        player.room:doIndicate(player.id, {p.id})
        TargetGroup:pushTargets(data.targetGroup, p.id)
      end
    end
  end,
}
local qin__shihuang = fk.CreateTriggerSkill{
  name = "qin__shihuang",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and math.random() < (6 * player.room:getTag("RoundCount") / 100)
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(true)
  end,
}
local qin__zulong = fk.CreateTriggerSkill{
  name = "qin__zulong",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        return target == player and player.phase == Player.Start
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      for i = #room.void, 1, -1 do
        if Fk:getCardById(room.void[i]).trueName == "qin_dragon_sword" or Fk:getCardById(room.void[i]).trueName == "qin_seal" then
          local id = table.remove(room.void, i)
          table.insert(room.draw_pile, math.random(1, #room.draw_pile), id)
          room:setCardArea(id, Card.DrawPile, nil)
        end
      end
      room:doBroadcastNotify("UpdateDrawPile", tostring(#room.draw_pile))
    else
      local cards = room:getCardsFromPileByRule("qin_dragon_sword", 1, "allPiles")
      table.insertTable(cards, room:getCardsFromPileByRule("qin_seal", 1, "allPiles"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      else
        player:drawCards(2, self.name)
      end
    end
  end,
}
local qin__fenshu = fk.CreateTriggerSkill{
  name = "qin__fenshu$",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.card:isCommonTrick() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local to = player.room:getPlayerById(data.from)
      return to.phase ~= Player.NotActive and to ~= player and to.kingdom ~= "qin"
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {data.from})
    return true
  end,
}
yingzheng:addSkill(qin__yitong)
yingzheng:addSkill(qin__shihuang)
yingzheng:addSkill(qin__zulong)
yingzheng:addSkill(qin__fenshu)
Fk:loadTranslationTable{
  ["yingzheng"] = "嬴政",
  ["qin__yitong"] = "一统",
  [":qin__yitong"] = "锁定技，你使用【杀】【过河拆桥】【顺手牵羊】【火攻】指定目标时，选择所有其他角色为目标（无距离合法性限制）。",
  ["qin__shihuang"] = "始皇",
  [":qin__shihuang"] = "锁定技，其他角色回合结束时，你有X%概率获得一个额外回合（X为游戏轮数的6倍）。",
  ["qin__zulong"] = "祖龙",
  [":qin__zulong"] = "锁定技，游戏开始时，将【传国玉玺】和【真龙长剑】加入牌堆；准备阶段，若【传国玉玺】或【真龙长剑】在牌堆或弃牌堆中，"..
  "你获得之；否则你摸两张牌。",
  ["qin__fenshu"] = "焚书",
  [":qin__fenshu"] = "主公技，锁定技，非秦势力角色于其回合内使用的第一张普通锦囊牌无效。",

  ["$qin__yitong"] = "秦得一统，安乐升平！",
  ["$qin__shihuang"] = "吾，才是万世的开始！",
  ["$qin__zulong"] = "得龙血脉，万物初始！",
  ["$qin__fenshu"] = "愚民怎识得天下大智慧？",
  ["~yingzheng"] = "咳咳……拿孤的金丹……",
}

local lvbuwei = General(extension, "lvbuwei", "qin", 4)
lvbuwei.hidden = true
local qin__qihuo = fk.CreateActiveSkill{
  name = "qin__qihuo",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = "#qin__qihuo",
  interaction = function(self)
    local choices = {}
    if table.find(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then
      table.insert(choices, "basic")
    end
    if table.find(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type == Card.TypeTrick end) then
      table.insert(choices, "trick")
    end
    if table.find(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type == Card.TypeEquip end) or
      #Self.player_cards[Player.Equip] > 0 then
      table.insert(choices, "equip")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = {}
    for _, id in ipairs(player:getCardIds{Player.Hand, Player.Equip}) do
      if self.interaction.data == "basic" then
        if Fk:getCardById(id).type == Card.TypeBasic then
          table.insertIfNeed(cards, id)
        end
      elseif self.interaction.data == "trick" then
        if Fk:getCardById(id).type == Card.TypeTrick then
          table.insertIfNeed(cards, id)
        end
      elseif self.interaction.data == "equip" then
        if Fk:getCardById(id).type == Card.TypeEquip then
          table.insertIfNeed(cards, id)
        end
      end
    end
    room:throwCard(cards, self.name, player, player)
    if not player.dead then
      player:drawCards(2 * #cards, self.name)
    end
  end
}
local qin__chunqiu = fk.CreateTriggerSkill{
  name = "qin__chunqiu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local qin__baixiang = fk.CreateTriggerSkill{
  name = "qin__baixiang",
  anim_type = "special",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getHandcardNum() >= 3 * player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover({
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "qin__zhongfu", nil, true, false)
  end,
}
local qin__zhongfu = fk.CreateTriggerSkill{
  name = "qin__zhongfu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    if not player:hasSkill("ex__jianxiong", true) then
      table.insert(skills, "ex__jianxiong")
    end
    if not player:hasSkill("rende", true) then
      table.insert(skills, "rende")
    end
    if not player:hasSkill("ex__zhiheng", true) then
      table.insert(skills, "ex__zhiheng")
    end
    if #skills == 0 then return end
    local skill = table.random(skills)
    room:setPlayerMark(player, self.name, skill)
    room:handleAddLoseSkills(player, skill, nil, true, false)
  end,
}
local qin__zhongfu_trigger = fk.CreateTriggerSkill {
  name = "#qin__zhongfu_trigger",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.from == Player.RoundStart and player:getMark("qin__zhongfu") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skill = player:getMark("qin__zhongfu")
    room:setPlayerMark(player, "qin__zhongfu", 0)
    room:handleAddLoseSkills(player, "-"..skill, nil, true, false)
  end,
}
qin__zhongfu:addRelatedSkill(qin__zhongfu_trigger)
lvbuwei:addSkill(qin__qihuo)
lvbuwei:addSkill("jugu")
lvbuwei:addSkill(qin__chunqiu)
lvbuwei:addSkill(qin__baixiang)
lvbuwei:addRelatedSkill(qin__zhongfu)
lvbuwei:addRelatedSkill("ex__jianxiong")
lvbuwei:addRelatedSkill("rende")
lvbuwei:addRelatedSkill("ex__zhiheng")
Fk:loadTranslationTable{
  ["lvbuwei"] = "吕不韦",
  ["qin__qihuo"] = "奇货",
  [":qin__qihuo"] = "出牌阶段限一次，你可以弃置你一种类别全部的牌，摸两倍的牌。",
  ["qin__chunqiu"] = "春秋",
  [":qin__chunqiu"] = "锁定技，你每回合使用或打出第一张牌时，摸一张牌。",
  ["qin__baixiang"] = "拜相",
  [":qin__baixiang"] = "觉醒技，准备阶段，若你的手牌数不小于体力值三倍，你回复体力至上限，然后获得技能〖仲父〗。",
  ["qin__zhongfu"] = "仲父",
  [":qin__zhongfu"] = "锁定技，准备阶段，你随机获得以下一项技能直到你下回合开始：〖奸雄〗、〖仁德〗、〖制衡〗。",
  ["#qin__qihuo"] = "奇货：弃置你一种类别全部的牌，摸两倍的牌",

  --["$qin__jugu"] = "钱财富有，富甲一方。",
  ["$qin__qihuo"] = "奇货可居，慧眼善识。",
  ["$qin__chunqiu"] = "吕氏春秋，举世之著作！",
  ["$qin__baixiang"] = "入秦拜相，权倾朝野！",
  ["$qin__zhongfu"] = "吾有一日，便护国一日安康！",
  ["~lvbuwei"] = "酖酒入肠，魂落异乡……",
}

local zhaoji = General(extension, "zhaoji", "qin", 3, 3, General.Female)
local qin__shanwu = fk.CreateTriggerSkill{
  name = "qin__shanwu",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TargetSpecified then
      room:notifySkillInvoked(player, self.name, "offensive")
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|spade,club",
      }
      room:judge(judge)
      if judge.card.color == Card.Black then
        data.unoffsetable = true
      end
    else
      room:notifySkillInvoked(player, self.name, "defensive")
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|heart,diamond",
      }
      room:judge(judge)
      if judge.card.color == Card.Red then
        return true
      end
    end
  end,
}
local qin__daqi = fk.CreateTriggerSkill{
  name = "qin__daqi",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from == Player.RoundStart and player:getMark("@qin__daqi") > 9
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@qin__daqi", 0)
    if player:isWounded() then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = self.name
      }
    end
    if player:getHandcardNum() < player.maxHp then
      player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    end
  end,
}
local qin__daqi_trigger = fk.CreateTriggerSkill{
  name = "#qin__daqi_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding, fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("qin__daqi")
  end,
  on_trigger = function(self, event, target, player, data)
    local n = 1
    if event == fk.Damage or event == fk.Damaged then
      n = data.damage
    end
    for i = 1, n, 1 do
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("qin__daqi")
    room:notifySkillInvoked(player, "qin__daqi", "special")
    room:addPlayerMark(player, "@qin__daqi", 1)
  end,
}
local qin__xianji = fk.CreateActiveSkill{
  name = "qin__xianji",
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:throwAllCards("he")
    room:setPlayerMark(player, "@qin__daqi", 0)
    room:changeMaxHp(player, -1)
    if not player.dead then
      local skill = Fk.skills["qin__daqi"]
      skill:use(nil, nil, player, nil)
    end
  end,
}
local qin__huoluan = fk.CreateTriggerSkill{
  name = "qin__huoluan",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.name == "qin__daqi" or data.name == "qin__xianji")  --耦！
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, table.map(room:getOtherPlayers(player), function(p) return p.id end))
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
qin__daqi:addRelatedSkill(qin__daqi_trigger)
zhaoji:addSkill(qin__shanwu)
zhaoji:addSkill(qin__daqi)
zhaoji:addSkill(qin__xianji)
zhaoji:addSkill(qin__huoluan)
Fk:loadTranslationTable{
  ["zhaoji"] = "赵姬",
  ["qin__shanwu"] = "善舞",
  [":qin__shanwu"] = "锁定技，当你使用【杀】指定目标后，你判定，若为黑色，此【杀】不能被【闪】抵消；"..
  "当你成为【杀】的目标后，你判定，若为红色，此【杀】无效。",
  ["qin__daqi"] = "大期",
  [":qin__daqi"] = "①锁定技，当你使用或打出一张牌时、造成或受到1点伤害后，你获得1枚“期”标记。<br>②回合开始时，若“期”不小于10，"..
  "你弃置所有“期”，然后将体力回复至上限、将手牌摸至体力上限。",
  ["qin__xianji"] = "献姬",
  [":qin__xianji"] = "限定技，出牌阶段，你可以弃置所有牌和“期”并减1点体力上限，然后发动〖大期〗②的效果。",
  ["qin__huoluan"] = "祸乱",
  [":qin__huoluan"] = "锁定技，当你发动〖大期〗②的效果后，你对所有其他角色各造成1点伤害。",
  ["@qin__daqi"] = "期",

  ["$qin__shanwu"] = "妾身跳的舞，将军爱看吗？",
  ["$qin__daqi"] = "大期之时，福运轮转。",
  ["$qin__xianji"] = "妾身能得垂爱，是妾身福气。",
  ["$qin__huoluan"] = "这天下都是我的，我有什么不能做的？",
  ["~zhaoji"] = "人间冷暖尝尽，富贵轮回成空……",
}

local miyue = General(extension, "miyue", "qin", 3, 3, General.Female)
local qin__zhangzheng = fk.CreateTriggerSkill{
  name = "qin__zhangzheng",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, table.map(room:getOtherPlayers(player), function(p) return p.id end))
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        if p:isKongcheng() then
          room:loseHp(p, 1, self.name)
        else
          if #room:askForDiscard(p, 1, 1, false, self.name, true, ".", "#qin__zhangzheng-card") == 0 then
            room:loseHp(p, 1, self.name)
          end
        end
      end
    end
  end,
}
local qin__taihou = fk.CreateTriggerSkill{
  name = "qin__taihou",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and (data.card:isCommonTrick() or data.card.trueName == "slash") then
      local p = player.room:getPlayerById(data.from)
      return p.gender == General.Male and not p.dead
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local p = room:getPlayerById(data.from)
    if p.dead or p:isKongcheng() then
      return true
    elseif #room:askForDiscard(p, 1, 1, false, self.name, true, ".|.|.|hand|.|"..data.card:getTypeString(),
      "#qin__taihou-card:::"..data.card:getTypeString()..":"..data.card:toLogString()) == 0 then
      return true
    end
  end,
}
local qin__youmie = fk.CreateActiveSkill{
  name = "qin__youmie",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive)
    local mark = target:getMark("@@qin__youmie")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(target, "@@qin__youmie", mark)
    room:setPlayerMark(player, self.name, target.id)
  end,
}
local qin__youmie_prohibit = fk.CreateProhibitSkill{
  name = "#qin__youmie_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@qin__youmie") ~= 0 then
      return player.phase == Player.NotActive
    end
  end,
}
local qin__youmie_record = fk.CreateTriggerSkill{
  name = "#qin__youmie_record",

  refresh_events = {fk.EventPhaseChanging, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:getMark("qin__youmie") ~= 0 then
      if event == fk.EventPhaseChanging then
        return data.from == Player.RoundStart
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local p = room:getPlayerById(player:getMark("qin__youmie"))
    room:setPlayerMark(player, "qin__youmie", 0)
    if not p.dead then
      local mark = p:getMark("@@qin__youmie")
      if mark == 0 then return end
      table.removeOne(mark, player.id)
      if #mark == 0 then mark = 0 end
      room:setPlayerMark(p, "@@qin__youmie", mark)
    end
  end,
}
local qin__yintui = fk.CreateTriggerSkill{
  name = "qin__yintui",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove then
        if player:isKongcheng() then
          for _, move in ipairs(data) do
            if move.from == player.id then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand then
                  return true
                end
              end
            end
          end
        end
      else
        return target == player and not player.faceup
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      player:turnOver()
    else
      data.damage = data.damage - 1
      player:drawCards(1, self.name)
    end
  end,
}
qin__youmie:addRelatedSkill(qin__youmie_prohibit)
qin__youmie:addRelatedSkill(qin__youmie_record)
miyue:addSkill(qin__zhangzheng)
miyue:addSkill(qin__taihou)
miyue:addSkill(qin__youmie)
miyue:addSkill(qin__yintui)
Fk:loadTranslationTable{
  ["miyue"] = "芈月",
  ["qin__zhangzheng"] = "掌政",
  [":qin__zhangzheng"] = "锁定技，准备阶段，所有其他角色依次选择一项：1.弃置一张手牌；2.失去1点体力。",
  ["qin__taihou"] = "太后",
  [":qin__taihou"] = "锁定技，当你成为男性角色使用【杀】或普通锦囊牌的目标后，其需选择一项：1.弃置一张相同类别的手牌；2.此牌无效。",
  ["qin__youmie"] = "诱灭",
  [":qin__youmie"] = "出牌阶段限一次，你可以将一张牌交给一名其他角色，直到你的下回合开始，该角色于其回合外不能使用或打出牌。",
  ["qin__yintui"] = "隐退",
  [":qin__yintui"] = "锁定技，当你失去最后一张手牌后，你翻面。当你受到伤害时，若你的武将牌背面朝上，此伤害-1，然后你摸一张牌。",
  ["#qin__zhangzheng-card"] = "掌政：你须弃置一张手牌，否则失去1点体力",
  ["#qin__taihou-card"] = "太后：你须弃置一张%arg手牌，否则%arg2无效",
  ["@@qin__youmie"] = "诱灭",

  ["$qin__zhangzheng"] = "幼子年弱，吾代为掌政！",
  ["$qin__taihou"] = "本太后在此，岂容汝等放肆！",
  ["$qin__youmie"] = "美色误人，红颜灭国哟。",
  ["$qin__yintui"] = "妾身为国尽心，你们怎可如此待我？",
  ["~miyue"] = "年老色衰，繁华已逝……",
}

return extension
