local extension = Package("ol_other")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_other"] = "OL-其他",
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
    room:broadcastSkillInvoke(self.name, math.random(2))
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

--官渡群张郃 辛评 韩猛
return extension
