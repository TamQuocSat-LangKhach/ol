local extension = Package("ol_other")
extension.extensionName = "ol"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_other"] = "OL-其他",
  ["guandu"] = "官渡",
  ["qin"] = "秦",
}

local godzhenji = General(extension, "godzhenji", "god", 3, 3, General.Female)
local shenfu = fk.CreateTriggerSkill{
  name = "shenfu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getCardIds("h") % 2 == 1 then
      while true do
        local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper),
          1, 1, "#shenfu-damage", self.name, true)
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
          return p:getMark("shenfu-turn") == 0 end), Util.IdMapper),
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
            if #to:getCardIds("h") ~= to.hp then return end
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
    if player:hasSkill(self) then
      return 7
    end
  end,
}
godzhenji:addSkill(shenfu)
godzhenji:addSkill(qixian)
Fk:loadTranslationTable{
  ["godzhenji"] = "神甄姬",
  ["#godzhenji"] = "洛水的女神",
  ["illustrator:godzhenji"] = "鬼画府",
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
  derived_piles = "caopi_chu",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #player:getPile("caopi_chu") < player.maxHp and not target.dead
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
    player:addToPile("caopi_chu", card, true, self.name)
  end,
}
local dengji = fk.CreateTriggerSkill{
  name = "dengji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:obtainCard(player, player:getPile("caopi_chu"), true, fk.ReasonJustMove)
    room:handleAddLoseSkills(player, "ex__jianxiong|tianxing", nil)
  end,
}
local tianxing = fk.CreateTriggerSkill{
  name = "tianxing",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:obtainCard(player, player:getPile("caopi_chu"), true, fk.ReasonJustMove)
    local choice = room:askForChoice(player, {"ex__rende", "ex__zhiheng", "ol_ex__luanji"}, self.name, "#tianxing-choice", true)
    room:handleAddLoseSkills(player, choice.."|-chuyuan", nil)
  end,
}
godcaopi:addSkill(chuyuan)
godcaopi:addSkill(dengji)
godcaopi:addRelatedSkill("ex__jianxiong")
godcaopi:addRelatedSkill(tianxing)
godcaopi:addRelatedSkill("ex__rende")
godcaopi:addRelatedSkill("ex__zhiheng")
godcaopi:addRelatedSkill("ol_ex__luanji")
godcaopi:addRelatedSkill("ol_ex__fangquan")
Fk:loadTranslationTable{
  ["godcaopi"] = "神曹丕",
  ["#godcaopi"] = "诰天仰颂",
  ["illustrator:godcaopi"] = "鬼画府",
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
  ["$ex__jianxiong_godcaopi1"] = "孤之所长，继父之所长。",
  ["$ex__jianxiong_godcaopi2"] = "乱世枭雄，哼，孤亦是。",
  ["$ex__rende_godcaopi"] = "这些都是孤赏赐给你的。",
  ["$ex__zhiheng_godcaopi"] = "有些事情，还需多加思索。",
  ["$ol_ex__luanji_godcaopi"] = "违逆我的，都该处罚。",
  ["$ol_ex__fangquan_godcaopi"] = "此等小事，你们处理即可。",
  ["~godcaopi"] = "曹魏锦绣，孤还未看尽……",
}

local lvbu3 = General(extension, "hulao3__godlvbu", "god", 4)
lvbu3.hulao_status = 2
--lvbu3.hidden = true

local shenqu = fk.CreateTriggerSkill{
  name = "shenqu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player:hasSkill(self) and target.phase == Player.Start and player:getHandcardNum() <= player.maxHp
    elseif event == fk.Damaged then
      return player:hasSkill(self) and player == target
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
  prompt = "#jiwu-active",
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
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event ~= nil then
      room:handleAddLoseSkills(player, skill_name, nil, true, false)
      turn_event:addCleaner(function()
        room:handleAddLoseSkills(player, "-" .. skill_name, nil, true, false)
      end)
    end
  end,
}

lvbu3:addSkill("wushuang")
lvbu3:addSkill(shenqu)
lvbu3:addSkill(jiwu)
lvbu3:addRelatedSkill("ol_ex__qiangxi")
lvbu3:addRelatedSkill("ex__tieji")
lvbu3:addRelatedSkill("ty_ex__xuanfeng")
lvbu3:addRelatedSkill("ol_ex__wansha")

Fk:loadTranslationTable{
  ["hulao3__godlvbu"] = "神吕布",
  ["#hulao3__godlvbu"] = "神鬼无前",
  ["illustrator:hulao3__godlvbu"] = "LiuHeng",
  ["shenqu"] = "神躯",
  [":shenqu"] = "一名角色的准备阶段，若你的手牌数不大于你的体力上限，你可以摸两张牌。当你受到伤害后，你可以使用一张【桃】。",
  ["jiwu"] = "极武",
  [":jiwu"] = "出牌阶段，你可以弃置一张牌，然后本回合你拥有以下其中一个技能：〖强袭〗、〖铁骑〗、〖旋风〗、〖完杀〗。",

  ["hulao3"] = "虎牢关",
  ["#shenqu-invoke"] = "是否使用神躯，摸两张牌",
  ["#shenqu-use"] = "神躯：你可以使用一张【桃】",
  ["#jiwu-active"] = "发动 极武，弃置一张牌来获得一项技能",

  ["$wushuang_hulao3__godlvbu1"] = "此天下，还有挡我者？",
  ["$wushuang_hulao3__godlvbu2"] = "画戟扫沙场，无双立万世。",
  ["$shenqu1"] = "别心怀侥幸了，你们不可能赢！",
  ["$shenqu2"] = "虎牢关，我一人镇守足矣。",
  ["$jiwu1"] = "我！是不可战胜的！",
  ["$jiwu2"] = "今天！就让你们感受一下真正的绝望！",
  ["$ol_ex__qiangxi_hulao3__godlvbu1"] = "这么想死，那我就成全你！",
  ["$ol_ex__qiangxi_hulao3__godlvbu2"] = "项上人头，待我来取！",
  ["$ex__tieji_hulao3__godlvbu1"] = "哈哈哈！破绽百出！",
  ["$ex__tieji_hulao3__godlvbu2"] = "我要让这虎牢关下，血流成河！",
  ["$ty_ex__xuanfeng_hulao3__godlvbu1"] = "千钧之势，力贯苍穹！",
  ["$ty_ex__xuanfeng_hulao3__godlvbu2"] = "风扫六合，威震八荒！",
  ["$ol_ex__wansha_hulao3__godlvbu1"] = "蝼蚁！怎容偷生！",
  ["$ol_ex__wansha_hulao3__godlvbu2"] = "沉沦吧！在这无边的恐惧！",
  ["~hulao3__godlvbu"] = "你们的项上人头，我改日再取！",
}

local hanba = General(extension, "hanba", "qun", 4, 4, General.Female)
local fentian = fk.CreateTriggerSkill{
  name = "fentian",
  anim_type = "control",
  derived_piles = "fentian_burn",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
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
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#fentian-choose", self.name, false)
    if #tos > 0 then
      local id = room:askForCardChosen(player, room:getPlayerById(tos[1]), "he", self.name)
      player:addToPile("fentian_burn", id, true, self.name)
    end
  end,
}
local fentian_attackrange = fk.CreateAttackRangeSkill{
  name = "#fentian_attackrange",
  correct_func = function (self, from, to)
    return from:hasSkill(fentian) and #from:getPile("fentian_burn") or 0
  end,
}
local zhiri = fk.CreateTriggerSkill{
  name = "zhiri",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("fentian_burn") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
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
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      from = effect.from,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
    })
    if not target.dead then
      room:loseHp(target, 1, self.name)
    end
  end,
}
fentian:addRelatedSkill(fentian_attackrange)
hanba:addSkill(fentian)
hanba:addSkill(zhiri)
hanba:addRelatedSkill(xintan)

Fk:loadTranslationTable{
  ["hanba"] = "旱魃",
  ["illustrator:hanba"] = "雪君s",
  ["fentian"] = "焚天",
  [":fentian"] = "锁定技，结束阶段，若你的手牌数小于你的体力值，你将攻击范围内的一名角色的一张牌置于你的武将牌上，称为“焚”；"..
  "你的攻击范围+X（X为“焚”数）。",
  ["zhiri"] = "炙日",
  [":zhiri"] = "觉醒技，准备阶段，若你的“焚”数不小于3，你减1点体力上限，获得〖心惔〗。",
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

local xinping = General(extension, "guandu__xinping", "qun", 3)
local fuyuanx = fk.CreateTriggerSkill{
  name = "fuyuanx",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.NotActive and
      player.room.current and not player.room.current.dead
  end,
  on_cost = function(self, event, target, player, data)
    local current = player.room.current
    local to = player.id
    if current:getHandcardNum() < player:getHandcardNum() then
      to = current.id
    end
    return player.room:askForSkillInvoke(player, self.name, nil, "#fuyuanx-invoke::"..to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room.current:getHandcardNum() < player:getHandcardNum() then
      room:doIndicate(player.id, {room.current.id})
      room.current:drawCards(1, self.name)
    else
      player:drawCards(1, self.name)
    end
  end,
}
local zhongjiex = fk.CreateTriggerSkill{
  name = "zhongjiex",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhongjiex-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:changeMaxHp(to, 1)
    if not to.dead and to:isWounded() then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not to.dead then
      to:drawCards(1, self.name)
    end
  end,
}
xinping:addSkill(fuyuanx)
xinping:addSkill(zhongjiex)
xinping:addSkill("yongdi")
Fk:loadTranslationTable{
  ["guandu__xinping"] = "辛评",
  ["fuyuanx"] = "辅袁",
  [":fuyuanx"] = "当你于回合外使用或打出牌时，若当前回合角色的手牌数：小于你，你可以令其摸一张牌；不小于你，你可以摸一张牌。",
  ["zhongjiex"] = "忠节",
  [":zhongjiex"] = "你死亡时，你可以令一名其他角色加1点体力上限，回复1点体力，摸一张牌。",
  ["#fuyuanx-invoke"] = "辅袁：你可以令 %dest 摸一张牌",
  ["#zhongjiex-choose"] = "忠节：你可以令一名角色加1点体力上限，回复1点体力，摸一张牌",

  ["$fuyuanx1"] = "袁门一体，休戚与共。",
  ["$fuyuanx2"] = "袁氏荣光，俯仰唯卿。",
  ["$zhongjiex1"] = "义士有忠节，可杀不可量！",
  ["$zhongjiex2"] = "愿以骨血为饲，事汝君临天下。",
  ["$yongdi_guandu__xinping1"] = "袁门当兴，兴在明公！",
  ["$yongdi_guandu__xinping2"] = "主公之位，非君莫属。",
  ["~guandu__xinping"] = "老臣，尽力了……",
}

local hanmeng = General(extension, "guandu__hanmeng", "qun", 4)
local jieliang = fk.CreateTriggerSkill{
  name = "jieliang",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Draw and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#jieliang-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:throwCard(self.cost_data, self.name, player, player)
    if not target.dead then
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 1)
    end
  end,
}
local jieliang_trigger = fk.CreateTriggerSkill{
  name = "#jieliang_trigger",
  mute = true,
  events = {fk.DrawNCards, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("jieliang", Player.HistoryTurn) > 0 then
      if event == fk.DrawNCards then
        return true
      elseif target.phase == Player.Discard then
        local room = player.room
        local ids, cards = {}, {}
        local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
        if phase_event == nil then return false end
        local end_id = phase_event.id
        room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
          for _, move in ipairs(e.data) do
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if not table.contains(cards, id) then
                table.insert(cards, id)
                if move.from == target.id and info.fromArea == Card.PlayerHand and move.toArea == Card.DiscardPile and
                  move.moveReason == fk.ReasonDiscard and room:getCardArea(id) == Card.DiscardPile then
                  table.insert(ids, id)
                end
              end
            end
          end
          return false
        end, end_id)
        if #ids > 0 then
          self.cost_data = ids
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n - 1
    else
      local room = player.room
      local cards, choice = U.askforChooseCardsAndChoice(player, self.cost_data, {"OK"}, "jieliang", "#jieliang-get", {"Cancel"}, 1, 1)
      if #cards > 0 then
        room:obtainCard(player, cards[1], false, fk.ReasonJustMove)
      end
    end
  end,
}
local quanjiu = fk.CreateFilterSkill{
  name = "quanjiu",
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(self) and card.trueName == "analeptic" and
    (table.contains(player.player_cards[Player.Hand], card.id) or isJudgeEvent)
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
local quanjiu_trigger = fk.CreateTriggerSkill{
  name = "#quanjiu_trigger",
  mute = true,
  events = {fk.PreCardUse},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "quanjiu")
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.extraUse = true
  end,
}
local quanjiu_targetmod = fk.CreateTargetModSkill{
  name = "#quanjiu_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "quanjiu")
  end,
}
jieliang:addRelatedSkill(jieliang_trigger)
quanjiu:addRelatedSkill(quanjiu_targetmod)
quanjiu:addRelatedSkill(quanjiu_trigger)
hanmeng:addSkill(jieliang)
hanmeng:addSkill(quanjiu)
Fk:loadTranslationTable{
  ["guandu__hanmeng"] = "韩猛",
  ["jieliang"] = "截粮",
  [":jieliang"] = "其他角色摸牌阶段开始时，你可以弃置一张牌，令其本回合摸牌阶段摸牌数和手牌上限-1。若如此做，本回合弃牌阶段结束时，"..
  "你可以获得其中一张其于此阶段弃置的牌。",
  ["quanjiu"] = "劝酒",
  [":quanjiu"] = "锁定技，你的【酒】和【酗酒】均视为【杀】，且使用时不计入次数限制。",
  ["#jieliang-invoke"] = "截粮：你可以弃置一张牌，令 %dest 本回合摸牌阶段摸牌数和手牌上限-1",
  ["#jieliang-get"] = "截粮：你可以获得其中一张牌",
  ["#quanjiu_trigger"] = "劝酒",

  ["$jieliang1"] = "伏兵起，粮道绝！",
  ["$jieliang2"] = "粮草根本，截之破敌！",
  ["$quanjiu1"] = "大敌当前，怎可松懈畅饮？",
  ["$quanjiu2"] = "乌巢重地，不宜饮酒！",
  ["~guandu__hanmeng"] = "曹操狡诈，防不胜防……",
}

local xuyou = General(extension, "guandu__xuyou", "qun", 3)
local guandu__shicai = fk.CreateActiveSkill{
  name = "guandu__shicai",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  prompt = "#guandu__shicai",
  expand_pile = function()
    return Self:getTableMark("guandu__shicai")
  end,
  card_filter = function (self, to_select, selected)
    if table.find(Self:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@guandu__shicai-inhand-turn") > 0
    end) then
      return false
    else
      return #selected == 0 and not Self:prohibitDiscard(to_select) and table.contains(Self:getCardIds("he"), to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    room:moveCardTo(room.draw_pile[1], Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id,
      "@@guandu__shicai-inhand-turn")
  end,
}
local guandu__shicai_trigger = fk.CreateTriggerSkill{
  name = "#guandu__shicai_trigger",

  refresh_events = {fk.StartPlayCard},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(guandu__shicai)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "guandu__shicai", {room.draw_pile[1]})
  end,
}
local guandu__zezhu = fk.CreateActiveSkill{
  name = "guandu__zezhu",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#guandu__zezhu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function (p)
        return p.seat == 1 or p.role == "lord" or p.role:endsWith("marshal")
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return p.seat == 1 or p.role == "lord" or p.role:endsWith("marshal")
    end)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p.dead then
        if p.role == "lord" or p.role:endsWith("marshal") then
          if p:isNude() then
            player:drawCards(1, self.name)
          else
            if p == player then
              if #player:getCardIds("ej") > 0 then
                local card = room:askForCardChosen(player, p, "ej", self.name, "#guandu__zezhu-prey::"..p.id)
                room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
              end
            else
              local card = room:askForCardChosen(player, p, "he", self.name, "#guandu__zezhu-prey::"..p.id)
              room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
            end
          end
        end
      end
      if player.dead then return end
      if p.seat == 1 then
        if p:isNude() then
          player:drawCards(1, self.name)
        else
          if p == player then
            if #player:getCardIds("ej") > 0 then
              local card = room:askForCardChosen(player, p, "ej", self.name, "#guandu__zezhu-prey::"..p.id)
              room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
            end
          else
            local card = room:askForCardChosen(player, p, "he", self.name, "#guandu__zezhu-prey::"..p.id)
            room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
          end
        end
      end
    end
    for _, p in ipairs(targets) do
      if player.dead or player:isNude() then return end
      if not p.dead then
        if p.role == "lord" or p.role:endsWith("marshal") then
          if p == player then
            if #player:getCardIds("e") > 0 then
              local card = room:askForCard(player, 1, 1, true, self.name, false, ".|.|.|equip", "#guandu__zezhu-give::"..p.id)
              room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonGive, self.name, nil, false, player.id)
            end
          else
            local card = room:askForCard(player, 1, 1, true, self.name, false, nil, "#guandu__zezhu-give::"..p.id)
            room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonGive, self.name, nil, false, player.id)
          end
        end
      end
      if player.dead or player:isNude() then return end
      if p.seat == 1 then
        if p == player then
          if #player:getCardIds("e") > 0 then
            local card = room:askForCard(player, 1, 1, true, self.name, false, ".|.|.|equip", "#guandu__zezhu-give::"..p.id)
            room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonGive, self.name, nil, false, player.id)
          end
        else
          local card = room:askForCard(player, 1, 1, true, self.name, false, nil, "#guandu__zezhu-give::"..p.id)
          room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonGive, self.name, nil, false, player.id)
        end
      end
    end
  end,
}
local guandu__chenggong = fk.CreateTriggerSkill{
  name = "guandu__chenggong",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.firstTarget and #AimGroup:getAllTargets(data.tos) > 1 and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, nil, "#guandu__chenggong-invoke::"..target.id) then
      self.cost_data = {tos = {target.id}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, self.name)
  end,
}
guandu__shicai:addRelatedSkill(guandu__shicai_trigger)
xuyou:addSkill(guandu__shicai)
xuyou:addSkill(guandu__zezhu)
xuyou:addSkill(guandu__chenggong)
Fk:loadTranslationTable{
  ["guandu__xuyou"] = "许攸",
  ["#guandu__xuyou"] = "恃才傲物",
  ["illustrator:guandu__xuyou"] = "zoo",

  ["guandu__shicai"] = "恃才",
  [":guandu__shicai"] = "出牌阶段，牌堆顶牌对你可见；出牌阶段，你可以弃置一张牌并获得牌堆顶牌，若本回合此牌仍在你手中，你不能发动此技能。",
  ["fushix"] = "附势",
  [":fushix"] = "锁定技，根据场上角色数较多的势力，你视为拥有对应的技能：群势力-〖择主〗；魏势力-〖逞功〗。",
  ["guandu__zezhu"] = "择主",
  [":guandu__zezhu"] = "出牌阶段限一次，你可以获得主公和一号位区域内各一张牌（无牌则你摸一张牌），然后交给其各一张牌。",
  ["guandu__chenggong"] = "逞功",
  [":guandu__chenggong"] = "当一名角色使用牌指定目标后，若目标数大于1，你可以令其摸一张牌。",
  ["#guandu__shicai"] = "恃才：你可以弃置一张牌，获得牌堆顶牌，若“恃才”牌仍在你手中则不能发动<br>（点击“恃才”技能按钮可以观看牌堆顶牌）",
  ["@@guandu__shicai-inhand-turn"] = "恃才",
  ["#guandu__zezhu"] = "择主：获得主公和一号位区域内各一张牌（无牌则你摸一张牌），然后交给其各一张牌",
  ["#guandu__zezhu-prey"] = "择主：获得 %dest 区域内一张牌",
  ["#guandu__zezhu-give"] = "择主：交给 %dest 一张牌",
  ["#guandu__chenggong-invoke"] = "逞功：是否令 %dest 摸一张牌？",

  ["$guandu__shicai1"] = "主公不听吾之言，实乃障目不见泰山也！",
  ["$guandu__shicai2"] = "遣轻骑以袭许都，大事可成。",
  ["$guandu__chenggong1"] = "吾与主公患难之交也！",
  ["$guandu__chenggong2"] = "我豫州人才济济，元皓之辈，不堪大用。",
  ["~guandu__xuyou"] = "我军之所以败，皆因尔等指挥不当！",
}

Fk:loadTranslationTable{
  ["guandu__chunyuqiong"] = "淳于琼",
  ["guandu__cangchu"] = "仓储",
  [":guandu__cangchu"] = "锁定技，游戏开始时，你获得三枚“粮”标记；当你受到1点火焰伤害后，你弃置一枚“粮”标记。",
  ["guandu__sushou"] = "宿守",
  [":guandu__sushou"] = "弃牌阶段开始时，你可以摸X+1张牌（X为“粮”标记数），然后你可以交给任意名角色各一张牌。",
  ["guandu__liangying"] = "粮营",
  [":guandu__liangying"] = "锁定技，若你有“粮”，群势力角色摸牌阶段多摸一张牌；当你失去所有“粮”时，你减1点体力上限，然后魏势力角色各摸一张牌。",

  ["$guandu__cangchu1"] = "袁公所托，琼，必当死守！",
  ["$guandu__cangchu2"] = "敌袭！速度整军，坚守营寨！",
  ["$guandu__sushou1"] = "今夜，需再加强巡逻，不要出了差池。",
  ["$guandu__sushou2"] = "吾军之所守，为重中之重，尔等、切莫懈怠！",
  ["~guandu__chunyuqiong"] = "子远老贼，吾死当追汝之魂！",
}

local zhanghe = General(extension, "guandu__zhanghe", "qun", 4)
local yuanlue = fk.CreateActiveSkill{
  name = "yuanlue",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#yuanlue",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeEquip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = effect.cards[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if not target.dead and table.contains(target:getCardIds("h"), id) then
      local card = Fk:getCardById(id)
      local use = U.askForUseRealCard(room, target, {id}, nil, self.name,
        "#yuanlue-invoke:"..player.id.."::"..card:toLogString(), {extraUse = true}, false, true)
      if use and not player.dead then
        player:drawCards(1, self.name)
      end
    end
  end,
}
zhanghe:addSkill(yuanlue)
Fk:loadTranslationTable{
  ["guandu__zhanghe"] = "张郃",
  ["yuanlue"] = "远略",
  [":yuanlue"] = "出牌阶段限一次，你可以交给一名其他角色一张非装备牌，然后其可以使用此牌，令你摸一张牌。",
  ["#yuanlue"] = "远略：交给一名其他角色一张非装备牌，其可以使用此牌，令你摸一张牌",
  ["#yuanlue-invoke"] = "远略：你可以使用%arg，令 %src 摸一张牌",

  ["$yuanlue1"] = "若不引兵救乌巢，则主公危矣！",
  ["$yuanlue2"] = "此番攻之不破，吾属尽成俘虏。",
  ["~guandu__zhanghe"] = "袁公不听吾之言，乃至今日。",
}

local dongyue = General(extension, "chaos__dongyue", "qun", 4)
local kuangxi = fk.CreateActiveSkill{
  name = "kuangxi",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#kuangxi",
  can_use = function(self, player)
    return player:getMark("@@kuangxi-turn") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:loseHp(player, 1, self.name)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}
local kuangxi_trigger = fk.CreateTriggerSkill{
  name = "#kuangxi_trigger",

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return data.damage and data.damage.skillName == "kuangxi" and data.damage.from and data.damage.from == player and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@kuangxi-turn", 1)
  end,
}
local mojun = fk.CreateTriggerSkill{
  name = "mojun",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.from and table.contains(U.GetFriends(player.room, player, true, true), data.from) and
      data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.color == Card.Black then
      pt(U.GetFriends(room, player))
      for _, p in ipairs(U.GetFriends(room, player)) do
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,
}
kuangxi:addRelatedSkill(kuangxi_trigger)
dongyue:addSkill(kuangxi)
dongyue:addSkill(mojun)
Fk:loadTranslationTable{
  ["chaos__dongyue"] = "董越",  --其实他不是文和乱武
  ["kuangxi"] = "狂袭",
  [":kuangxi"] = "出牌阶段，你可以失去1点体力，对一名其他角色造成1点伤害。若该角色因此进入濒死状态，此技能本回合失效。",
  ["mojun"] = "魔军",
  [":mojun"] = "锁定技，当友方角色使用【杀】造成伤害后，你判定，若结果为黑色，友方角色各摸一张牌。",
  ["#kuangxi"] = "狂袭：失去1点体力，对一名其他角色造成1点伤害！",
  ["@@kuangxi-turn"] = "狂袭失效",

  ["$kuangxi1"] = "",
  ["$kuangxi2"] = "",
  ["$mojun1"] = "",
  ["$mojun2"] = "",
  ["~dongyue"] = "喵喵喵。",
}

local shangyang = General(extension, "shangyang", "qin", 4)
local qin__bianfa = fk.CreateViewAsSkill{
  name = "qin__bianfa",
  anim_type = "offensive",
  pattern = "shangyang_reform",
  prompt = "#qin__bianfa",
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
local qin__limu = fk.CreateTriggerSkill{
  name = "qin__limu",
  anim_type = "offensive",
  events = {fk.AfterCardUseDeclared},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player, data)
    data.unoffsetableList = table.map(player.room.alive_players, Util.IdMapper)
  end,
}
local qin__kencao = fk.CreateTriggerSkill{
  name = "qin__kencao",
  anim_type = "support",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target and not target.dead and target.kingdom == "qin"
  end,
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.damage do
      if not target.dead then
        self:doCost(event, target, player, data)
      end
      player.room:delay(100)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:addPlayerMark(target, "@qin__kencao", 1)
    if target:getMark("@qin__kencao") > 2 then
      room:setPlayerMark(target, "@qin__kencao", 0)
      room:changeMaxHp(target, 1)
      if target:isWounded() and not target.dead then
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
shangyang:addSkill(qin__bianfa)
shangyang:addSkill(qin__limu)
shangyang:addSkill(qin__kencao)
Fk:loadTranslationTable{
  ["shangyang"] = "商鞅",
  ["#shangyang"] = "变法者",
  ["qin__bianfa"] = "变法",
  [":qin__bianfa"] = "出牌阶段限一次，你可以将一张普通锦囊牌当【商鞅变法】使用。"..
  "<font color='grey'><small>【商鞅变法】<br>出牌阶段，对一名其他角色使用，随机对其造成1~2点伤害，若其进入濒死，你判定，若为黑色，"..
  "除其以外的角色不能对其使用【桃】。</small></font>",
  ["qin__limu"] = "立木",
  [":qin__limu"] = "锁定技，你使用的普通锦囊牌不能被抵消。",
  ["qin__kencao"] = "垦草",
  [":qin__kencao"] = "锁定技，每当秦势力角色造成1点伤害后，其获得一枚“功”标记。然后若其“功”标记不小于3，其弃置所有“功”标记，加1点体力上限，"..
  "回复1点体力。",
  ["#qin__bianfa"] = "变法：你可以将一张普通锦囊牌当【商鞅变法】使用",
  ["@qin__kencao"] = "功",

  ["$qin__bianfa"] = "前世不同教，何古之法？",
  ["$qin__limu"] = "立木之言，汇聚民心。",
  ["$qin__kencao"] = "农静，诛愚；乱农之民欲农，则草必垦矣。",
  ["~shangyang"] = "无人可依，变法难行……",
}

local zhangyiq = General(extension, "zhangyiq", "qin", 4)
local qin__lianheng = fk.CreateTriggerSkill{
  name = "qin__lianheng",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return table.find(player.room.alive_players, function (p) return p.kingdom ~= "qin" end)
      else
        return target == player
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local to = table.random(table.filter(room.alive_players, function (p) return p.kingdom ~= "qin" end))
      room:doIndicate(player.id, {to.id})
      room:setPlayerMark(to, "@@qin__lianheng", 1)
    else
      for _, p in ipairs(room.alive_players) do
        if p:getMark("@@qin__lianheng") > 0 then
          room:setPlayerMark(p, "@@qin__lianheng", 0)
        end
      end
      local tos = table.filter(room.alive_players, function (p) return p.kingdom ~= "qin" end)
      if #tos >= 2 then
        local to = table.random(tos)
        room:doIndicate(player.id, {to.id})
        room:setPlayerMark(to, "@@qin__lianheng", 1)
      end
    end
  end,
}
local qin__lianheng_prohibit = fk.CreateProhibitSkill{
  name = "#qin__lianheng_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:getMark("@@qin__lianheng") > 0 then
      return to.kingdom == "qin"
    end
  end,
}
local qin__xichu = fk.CreateTriggerSkill{
  name = "qin__xichu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.trueName == "slash" then
      local room = player.room
      return not room:getPlayerById(data.from).dead and
        table.find(room:getOtherPlayers(player), function(p)
        return room:getPlayerById(data.from):inMyAttackRange(p) and
          table.contains(player.room:getUseExtraTargets(data, false, true), p.id)
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askForDiscard(room:getPlayerById(data.from), 1, 1, true, self.name, true, ".|6", "#qin__xichu-discard:"..player.id) == 0 then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return room:getPlayerById(data.from):inMyAttackRange(p) and table.contains(room:getUseExtraTargets(data, false, true), p.id)
      end), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#qin__xichu-choose::"..data.from, self.name, true) or table.random(targets)
      if #tos > 0 then
        TargetGroup:removeTarget(data.targetGroup, player.id)
        TargetGroup:pushTargets(data.targetGroup, tos[1])
      end
    end
  end,
}
local qin__xiongbian = fk.CreateTriggerSkill{
  name = "qin__xiongbian",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|6",
    }
    room:judge(judge)
    if judge.card.number == 6 then
      data.tos = AimGroup:initAimGroup({})
      return true
    end
  end,
}
local qin__qiaoshe = fk.CreateTriggerSkill{
  name = "qin__qiaoshe",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    for i = -3, 3, 1 do
      if data.card.number + i > 0 and data.card.number + i < 14 then
        if i <= 0 then
          table.insert(choices, tostring(i))
        else
          table.insert(choices, "+"..tostring(i))
        end
      end
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#qin__qiaoshe-choice::"..target.id)
    if choice ~= "0" then
      self.cost_data = tonumber(choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local new_card = Fk:cloneCard(data.card.name, data.card.suit, data.card.number + self.cost_data)
    new_card.id = data.card.id
    new_card.skillName = self.name
    data.card = new_card
  end,
}
qin__lianheng:addRelatedSkill(qin__lianheng_prohibit)
zhangyiq:addSkill(qin__lianheng)
zhangyiq:addSkill(qin__xichu)
zhangyiq:addSkill(qin__xiongbian)
zhangyiq:addSkill(qin__qiaoshe)
Fk:loadTranslationTable{
  ["zhangyiq"] = "张仪",
  ["#zhangyiq"] = "合纵连横",
  ["qin__lianheng"] = "连横",
  [":qin__lianheng"] = "锁定技，游戏开始时，你令随机一名非秦势力角色获得“横”标记；"..
  "你的回合开始时，弃置场上的所有“横”标记。然后若非秦势力角色数不小于2，你令随机一名非秦势力角色获得“横”标记；"..
  "秦势力角色不能成为拥有“横”标记的角色使用牌的目标。",
  ["qin__xichu"] = "戏楚",
  [":qin__xichu"] = "锁定技，当你成为【杀】的目标时，若使用者攻击范围内有其他角色，则该角色需弃置一张点数为6的牌，"..--村：真的在成为目标时改目标
  "否则此【杀】的目标转移给其攻击范围内你指定的另一名角色。",
  ["qin__xiongbian"] = "雄辩",
  [":qin__xiongbian"] = "锁定技，当你成为普通锦囊牌的目标时，你判定，若点数为6，此牌无效。",
  ["qin__qiaoshe"] = "巧舌",
  [":qin__qiaoshe"] = "一名角色判定牌生效前，你可以令之点数增加或减少至多3。",
  ["@@qin__lianheng"] = "横",
  ["#qin__xichu-choose"] = "戏楚：选择一名角色，将 %dest 对你使用的【杀】转移给指定的角色",
  ["#qin__xichu-discard"] = "戏楚：你需弃置一张点数6的牌，否则对 %src 使用的【杀】转移给 %src 指定的角色",
  ["#qin__qiaoshe-choice"] = "巧舌：你可以令 %dest 的判定结果增加或减少至多3",

  ["$qin__lianheng"] = "连横之术，可破合纵之策。",
  ["$qin__xichu"] = "楚王欲贪，此戏方成。",
  ["$qin__xiongbian"] = "据坛雄辩，无人可驳！",
  ["$qin__qiaoshe"] = "巧舌如簧，虚实乱象。",
  ["~zhangyiq"] = "连横之道，后世难存……",
}

local baiqi = General(extension, "baiqi", "qin", 4)
local qin__wuan = fk.CreateTriggerSkill{
  name = "qin__wuan",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.kingdom == "qin" and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
local qin__wuan_targetmod = fk.CreateTargetModSkill{
  name = "#qin__wuan_targetmod",
  frequency = Skill.Compulsory,
  residue_func = function(self, player, skill, scope)
    if player.kingdom == "qin" and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      if table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill(qin__wuan) end) then
        return 1
      end
    end
  end,
}
local qin__shashen = fk.CreateViewAsSkill{
  name = "qin__shashen",
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#qin__shashen",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local qin__shashen_trigger = fk.CreateTriggerSkill{
  name = "#qin__shashen_trigger",
  mute = true,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.trueName == "slash"
      end, Player.HistoryTurn)
      return #events == 1 and events[1].id == player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).id
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, "qin__shashen")
  end,
}
local qin__fachu = fk.CreateTriggerSkill{
  name = "qin__fachu",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and data.damage and data.damage.from and data.damage.from == player
     and data.damage.to and data.damage.to.kingdom ~= "qin" and #target:getAvailableEquipSlots() > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:abortPlayerArea(target, {table.random(target:getAvailableEquipSlots())})
  end,
}
local qin__changsheng = fk.CreateTargetModSkill{
  name = "qin__changsheng",
  frequency = Skill.Compulsory,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(self) and card and card.trueName == "slash"
  end,
}
qin__wuan:addRelatedSkill(qin__wuan_targetmod)
qin__shashen:addRelatedSkill(qin__shashen_trigger)
baiqi:addSkill(qin__wuan)
baiqi:addSkill(qin__shashen)
baiqi:addSkill(qin__fachu)
baiqi:addSkill(qin__changsheng)
Fk:loadTranslationTable{
  ["baiqi"] = "白起",
  ["#baiqi"] = "血战长平",
  ["qin__wuan"] = "武安",
  [":qin__wuan"] = "锁定技，秦势力角色出牌阶段使用【杀】的次数上限+1，使用【杀】造成的伤害+1。",
  ["qin__shashen"] = "杀神",
  [":qin__shashen"] = "你可以将一张手牌当【杀】使用或打出；当每回合你使用的第一张【杀】造成伤害后，你摸一张牌。",
  ["qin__fachu"] = "伐楚",
  [":qin__fachu"] = "锁定技，你造成伤害使非秦势力角色进入濒死状态后，随机废除其一个装备栏。",
  ["qin__changsheng"] = "常胜",
  [":qin__changsheng"] = "锁定技，你使用【杀】无距离限制。",
  ["#qin__shashen"] = "杀神：你可以将一张手牌当【杀】使用或打出",

  ["$qin__wuan"] = "受封武安，为国尽忠！",
  ["$qin__shashen"] = "战场，是我的舞台！",
  ["$qin__fachu"] = "兴兵伐楚，稳大秦基业！",
  ["$qin__changsheng"] = "百战百胜，攻无不克！",
  ["~baiqi"] = "将士迟暮，难以再战……",
}

local yingzheng = General(extension, "yingzheng", "qin", 4)
local qin__yitong = fk.CreateTriggerSkill{
  name = "qin__yitong",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      table.contains({"slash", "dismantlement", "snatch", "fire_attack"}, data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.kingdom ~= "qin" and
      not player:isProhibited(p, data.card) and data.card.skill:modTargetFilter(p.id, {}, data.from, data.card, false) then
        table.insert(tos, p.id)
      end
    end
    data.tos = table.map(tos, function(p) return {p} end)
  end,
}
local qin__yitong_targetmod = fk.CreateTargetModSkill{
  name = "#qin__yitong_targetmod",
  frequency = Skill.Compulsory,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(self) and card and table.contains({"slash", "dismantlement", "snatch", "fire_attack"}, card.trueName)
  end,
}
local qin__shihuang = fk.CreateTriggerSkill{
  name = "qin__shihuang",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and math.random() < (6 * player.room:getTag("RoundCount") / 100)
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(true, self.name)
  end,
}
local zulong_derivecards = {{"qin_dragon_sword", Card.Heart, 2}, {"qin_seal", Card.Heart, 7}}
local qin__zulong = fk.CreateTriggerSkill{
  name = "qin__zulong",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      return target == player
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("qin_dragon_sword,qin_seal", 2, "allPiles")
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
  end,
}
local qin__fenshu = fk.CreateTriggerSkill{
  name = "qin__fenshu",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card:isCommonTrick() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local to = player.room:getPlayerById(data.from)
      return to.phase ~= Player.NotActive and to ~= player and to.kingdom ~= "qin"
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {data.from})
    data.tos ={}
  end,
}
qin__yitong:addRelatedSkill(qin__yitong_targetmod)
yingzheng:addSkill(qin__yitong)
yingzheng:addSkill(qin__shihuang)
yingzheng:addSkill(qin__zulong)
yingzheng:addSkill(qin__fenshu)
Fk:loadTranslationTable{
  ["yingzheng"] = "嬴政",
  ["#yingzheng"] = "横扫六合",
  ["qin__yitong"] = "一统",
  [":qin__yitong"] = "锁定技，你使用【杀】、【过河拆桥】、【顺手牵羊】、【火攻】无距离限制且改为指定所有非秦势力角色为目标。",
  ["qin__shihuang"] = "始皇",
  [":qin__shihuang"] = "锁定技，其他角色回合结束时，你有X%几率获得一个额外回合（X为游戏轮数的6倍，最大为100）。",
  ["qin__zulong"] = "祖龙",
  [":qin__zulong"] = "锁定技，你的回合开始时，若牌堆或弃牌堆内有【传国玉玺】或【真龙长剑】，你获得之；若没有，你摸两张牌。",
  ["qin__fenshu"] = "焚书",
  [":qin__fenshu"] = "锁定技，非秦势力角色于其回合内使用的第一张普通锦囊牌无效。",

  ["$qin__yitong"] = "秦得一统，安乐升平！",
  ["$qin__shihuang"] = "吾，才是万世的开始！",
  ["$qin__zulong"] = "得龙血脉，万物初始！",
  ["$qin__fenshu"] = "愚民怎识得天下大智慧？",
  ["~yingzheng"] = "咳咳……拿孤的金丹……",
}

local lvbuwei = General(extension, "lvbuwei", "qin", 3)
local qin__qihuo = fk.CreateActiveSkill{
  name = "qin__qihuo",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = "#qin__qihuo",
  interaction = function()
    local choices = {}
    for _, t in ipairs({"basic","trick","equip"}) do
      if table.find(Self:getCardIds("he"), function(id) return Fk:getCardById(id):getTypeString() == t
      and not Self:prohibitDiscard(Fk:getCardById(id)) end) then
        table.insert(choices, t)
      end
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
    and table.find(player:getCardIds("he"), function(id) return not Self:prohibitDiscard(Fk:getCardById(id)) end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = table.filter(player:getCardIds("he"), function(id) return Fk:getCardById(id):getTypeString() == self.interaction.data
      and not player:prohibitDiscard(Fk:getCardById(id)) end)
    room:throwCard(cards, self.name, player, player)
    if not player.dead then
      player:drawCards(#cards, self.name)
    end
  end
}
local qin__chunqiu = fk.CreateTriggerSkill{
  name = "qin__chunqiu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
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
    return target == player and player:hasSkill(self) and
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
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    for _, s in ipairs({"ex__jianxiong", "ex__rende", "ex__zhiheng"}) do
      if not player:hasSkill(s, true) then
        table.insert(skills, s)
      end
    end
    if #skills == 0 then return end
    local skill = table.random(skills)
    room:setPlayerMark(player, self.name, skill)
    room:handleAddLoseSkills(player, skill, nil, true, false)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("qin__zhongfu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skill = player:getMark("qin__zhongfu")
    room:setPlayerMark(player, "qin__zhongfu", 0)
    room:handleAddLoseSkills(player, "-"..skill, nil, true, false)
  end,
}
lvbuwei:addSkill(qin__qihuo)
lvbuwei:addSkill("jugu")
lvbuwei:addSkill(qin__chunqiu)
lvbuwei:addSkill(qin__baixiang)
lvbuwei:addRelatedSkill(qin__zhongfu)
lvbuwei:addRelatedSkill("ex__jianxiong")
lvbuwei:addRelatedSkill("ex__rende")
lvbuwei:addRelatedSkill("ex__zhiheng")
Fk:loadTranslationTable{
  ["lvbuwei"] = "吕不韦",
  ["#lvbuwei"] = "吕氏春秋",
  ["qin__qihuo"] = "奇货",
  [":qin__qihuo"] = "出牌阶段限一次，你可以弃置你一种类别全部的牌，摸等量的牌。",
  ["qin__chunqiu"] = "春秋",
  [":qin__chunqiu"] = "锁定技，当你使用或打出每回合第一张牌时，你摸一张牌。",
  ["qin__baixiang"] = "拜相",
  [":qin__baixiang"] = "觉醒技，准备阶段，若你的手牌数不小于体力值三倍，你回复体力至上限，然后获得〖仲父〗。",
  ["qin__zhongfu"] = "仲父",
  [":qin__zhongfu"] = "锁定技，准备阶段，你随机获得以下一项技能直到你下回合开始：〖奸雄〗、〖仁德〗、〖制衡〗。",
  ["#qin__qihuo"] = "奇货：弃置你一种类别全部的牌，摸等量的牌",

  ["$jugu_lvbuwei"] = "钱财富有，富甲一方。",
  ["$qin__qihuo"] = "奇货可居，慧眼善识。",
  ["$qin__chunqiu"] = "吕氏春秋，举世之著作！",
  ["$qin__baixiang"] = "入秦拜相，权倾朝野！",
  ["$qin__zhongfu"] = "吾有一日，便护国一日安康！",
  ["~lvbuwei"] = "酖酒入肠，魂落异乡……",
}

local zhaogao = General(extension, "zhaogao", "qin", 3)
local qin__zhilu = fk.CreateViewAsSkill{
  name = "qin__zhilu",
  pattern = "slash,jink",
  prompt = "#qin__zhilu",
  card_filter = function(self, to_select, selected)
    if #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      local card = Fk:getCardById(to_select)
      local c
      if card.color == Card.Red then
        c = Fk:cloneCard("jink")
      elseif card.color == Card.Black then
        c = Fk:cloneCard("slash")
      else
        return false
      end
      return (Fk.currentResponsePattern == nil and Self:canUse(c)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:getCardById(cards[1])
    local c
    if card.color == Card.Red then
      c = Fk:cloneCard("jink")
    elseif card.color == Card.Black then
      c = Fk:cloneCard("slash")
    end
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local qin__gaizhao = fk.CreateTriggerSkill{
  name = "qin__gaizhao",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
    table.find(player.room:getUseExtraTargets(data, true, true), function (p) return player.room:getPlayerById(p).kingdom == "qin" end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getUseExtraTargets(data, true, true), function (p)
      return room:getPlayerById(p).kingdom == "qin"
    end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#qin__gaizhao-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    TargetGroup:removeTarget(data.targetGroup, player.id)
    TargetGroup:pushTargets(data.targetGroup, self.cost_data)
    return true
  end,
}
local qin__haizhong = fk.CreateTriggerSkill{
  name = "qin__haizhong",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.kingdom ~= "qin" and player:usedSkillTimes(self.name, Player.HistoryTurn) < 14
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n = math.max(target:getMark("@qin__haizhong"), 1)
    if #room:askForDiscard(target, 1, 1, true, self.name, true, ".|.|heart,diamond", "#qin__haizhong-invoke:"..player.id.."::"..n) == 0 then
      room:damage{
        from = player,
        to = target,
        damage = n,
        skillName = self.name,
      }
    end
    if not target.dead then
      room:addPlayerMark(target, "@qin__haizhong", 1)
    end
  end,
}
local qin__yuanli = fk.CreateTriggerSkill{
  name = "qin__yuanli",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick", 2)
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
zhaogao:addSkill(qin__zhilu)
zhaogao:addSkill(qin__gaizhao)
zhaogao:addSkill(qin__haizhong)
zhaogao:addSkill(qin__yuanli)
Fk:loadTranslationTable{
  ["zhaogao"] = "赵高",
  ["#zhaogao"] = "沙丘谋变",
  ["qin__zhilu"] = "指鹿",
  [":qin__zhilu"] = "你可以将一张红色/黑色手牌当【闪】/【杀】使用或打出。",
  ["qin__gaizhao"] = "改诏",
  [":qin__gaizhao"] = "当你成为【杀】或普通锦囊牌的目标时，你可以将此牌的目标转移给此牌目标以外的一名其他秦势力角色。",
  ["qin__haizhong"] = "害忠",
  [":qin__haizhong"] = "锁定技，每回合限十四次，非秦势力角色回复体力后，其需选择一项：1.弃置一张红色牌，2.受到X点伤害（X为其拥有的“害”标记数，至少为1）。然后其获得一个“害”标记。", -- 限14=秦朝活了十四年，海嗣智慧
  ["qin__yuanli"] = "爰历",
  [":qin__yuanli"] = "锁定技，出牌阶段开始时，你随机获得两张普通锦囊牌。",
  ["#qin__zhilu"] = "指鹿：你可以将一张红色/黑色手牌当【闪】/【杀】使用或打出",
  ["#qin__gaizhao-choose"] = "改诏：你可以将此%arg的目标转移给一名角色",
  ["@qin__haizhong"] = "害",
  ["#qin__haizhong-invoke"] = "害忠：你需弃置一张红色牌，否则 %src 对你造成%arg点伤害",

  ["$qin__zhilu"] = "看清楚了，这可是马。",
  ["$qin__gaizhao"] = "我的话才是诏书所言。",
  ["$qin__haizhong"] = "违逆我的，可都没有好下场。",
  ["$qin__yuanli"] = "玉律法令，爰历皆记。",
  ["~zhaogao"] = "唉！权力害己啊！",
}

local zhaoji = General(extension, "zhaoji", "qin", 3, 4, General.Female)
local qin__shanwu = fk.CreateTriggerSkill{
  name = "qin__shanwu",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified, fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
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
        data.tos = AimGroup:initAimGroup({})
        return true
      end
    end
  end,
}
local qin__daqi = fk.CreateTriggerSkill{
  name = "qin__daqi",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@qin__daqi") > 9
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
    return target == player and player:hasSkill(self) and (data.name == "qin__daqi" or data.name == "qin__xianji")  --耦！
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, table.map(room:getOtherPlayers(player), Util.IdMapper))
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
  ["#zhaoji"] = "祸乱宫闱",
  ["qin__shanwu"] = "善舞",
  [":qin__shanwu"] = "锁定技，当你使用【杀】指定目标后，你判定，若为黑色，此【杀】不能被【闪】抵消；"..
  "当你成为【杀】的目标后，你判定，若为红色，此【杀】无效。",
  ["qin__daqi"] = "大期",
  [":qin__daqi"] = "锁定技，每当你使用或打出牌、造成或受到1点伤害后，你获得一个“期”标记；回合开始时，若你拥有的“期”标记数不小于10，"..
  "你弃置所有“期”标记，然后将体力回复至体力上限、将手牌摸至体力上限。",
  ["qin__xianji"] = "献姬",
  [":qin__xianji"] = "限定技，出牌阶段，你可以弃置所有牌和“期”标记并减1点体力上限，然后发动〖大期〗的回复效果和摸牌效果。",
  ["qin__huoluan"] = "祸乱",
  [":qin__huoluan"] = "锁定技，当你发动〖大期〗的回复效果和摸牌效果后，你对所有其他角色各造成1点伤害。",
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
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, table.map(table.filter(room.alive_players, function (p) return p.kingdom ~= "qin" end), Util.IdMapper))
    for _, p in ipairs(table.filter(room:getAlivePlayers(), function (p) return p.kingdom ~= "qin" end)) do
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
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and (data.card:isCommonTrick() or data.card.trueName == "slash") then
      local p = player.room:getPlayerById(data.from)
      return p:isMale() and not p.dead
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askForDiscard(room:getPlayerById(data.from), 1, 1, false, self.name, true, ".|.|.|hand|.|"..data.card:getTypeString(),
      "#qin__taihou-card:::"..data.card:getTypeString()..":"..data.card:toLogString()) == 0 then
      data.tos = AimGroup:initAimGroup({})
      return true
    end
  end,
}
local qin__youmie = fk.CreateActiveSkill{
  name = "qin__youmie",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#qin__youmie",
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
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    room:addTableMark(target, "@@qin__youmie", player.id)
    room:setPlayerMark(player, self.name, target.id)
  end,
}
local qin__youmie_prohibit = fk.CreateProhibitSkill{
  name = "#qin__youmie_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@qin__youmie") ~= 0 and player.phase == Player.NotActive
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@qin__youmie") ~= 0 and player.phase == Player.NotActive
  end,
}
local qin__youmie_record = fk.CreateTriggerSkill{
  name = "#qin__youmie_record",

  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("qin__youmie", Player.HistoryGame) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      local mark = p:getTableMark("@@qin__youmie")
      for i = #mark, 1, -1 do
        if mark == player.id then
          table.remove(mark, i)
        end
      end
      if #mark == 0 then mark = 0 end
      room:setPlayerMark(p, "@@qin__youmie", 0)
    end
  end,
}
local qin__yintui = fk.CreateTriggerSkill{
  name = "qin__yintui",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
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
  ["#miyue"] = "始太后",
  ["qin__zhangzheng"] = "掌政",
  [":qin__zhangzheng"] = "锁定技，准备阶段，所有非秦势力角色依次选择：1.弃置一张手牌；2.失去1点体力。",
  ["qin__taihou"] = "太后",
  [":qin__taihou"] = "锁定技，当你成为男性角色使用的【杀】或普通锦囊牌的目标时，其需弃置一张相同类别的牌，否则此牌无效。",
  ["qin__youmie"] = "诱灭",
  [":qin__youmie"] = "出牌阶段限一次，你可以将一张牌交给一名其他角色，直到你的下回合开始，该角色于其回合外不能使用或打出牌。",
  ["qin__yintui"] = "隐退",
  [":qin__yintui"] = "锁定技，当你失去最后一张手牌后，你翻面；当你受到伤害时，若你的武将牌背面朝上，此伤害-1，然后你摸一张牌。",
  ["#qin__zhangzheng-card"] = "掌政：你须弃置一张手牌，否则失去1点体力",
  ["#qin__taihou-card"] = "太后：你须弃置一张%arg手牌，否则%arg2无效",
  ["#qin__youmie"] = "诱灭：将一张牌交给一名角色，直到你下回合开始，其于回合外不能使用或打出牌",
  ["@@qin__youmie"] = "诱灭",

  ["$qin__zhangzheng"] = "幼子年弱，吾代为掌政！",
  ["$qin__taihou"] = "本太后在此，岂容汝等放肆！",
  ["$qin__youmie"] = "美色误人，红颜灭国哟。",
  ["$qin__yintui"] = "妾身为国尽心，你们怎可如此待我？",
  ["~miyue"] = "年老色衰，繁华已逝……",
}

--- 〖同袍〗找防具
---@param room Room @ 房间
---@param card Card @ 目标防具牌
---@return Card @ 找到/打印的牌
local getTongpaoArmor = function(room, card)
  local armor = table.find(table.map(room.void, Util.Id2CardMapper), function(c)
    return c.name == card.name
  end)
  return armor or room:printCard(card.name, card.suit, card.number)
end

local tongpao = fk.CreateTriggerSkill{ -- 同袍
  name = "qin__tongpao",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) then
      local c = data.card
      if target.kingdom == "qin" and c.type == Card.TypeEquip
        and c.sub_type == Card.SubtypeArmor and player:hasEmptyEquipSlot(c.sub_type)
        and player:canUse(Fk:cloneCard(c.name, c.suit, c.number)) then
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    if player.dead then return end
    local room = player.room
    local armor = getTongpaoArmor(room, data.card)
    room:setCardMark(armor, MarkEnum.DestructOutMyEquip, 1)
    room:useCard{
      from = player.id,
      card = armor,
      tos = { {player.id} }
    }
  end
}
Fk:loadTranslationTable{
  ["qin__tongpao"] = "同袍",
  [":qin__tongpao"] = "锁定技，其他秦势力角色使用防具牌结算完成后，若你没有装备防具，你从游戏外使用一张相同的防具牌（离开你的装备区时销毁）。",
  ["$qin__tongpao"] = "岂曰无衣，与子同袍！"
}

-- 弩手
local nushou = General(extension, "qin__nushou", "qin", 3)
nushou.hidden = true

Fk:loadTranslationTable{
  ["qin__nushou"] = "秦军弩手"
}

--- 〖劲弩〗找秦弩
---@param room Room @ 房间
---@return Card @ 找到/打印的牌
local getQinnu = function(room)
  local qinnu = table.find(table.map(room.void, Util.Id2CardMapper), function(c)
    return c.name == "qin_crossbow"
  end)
  return qinnu or room:printCard("qin_crossbow", Card.Club, 1)
end

local jingnu = fk.CreateTriggerSkill{
  name = "qin__jingnu",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player then
      if not table.find(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).name == "qin_crossbow"
      end) then
        local qinnu = getQinnu(player.room)
        if qinnu and player:canUse(qinnu) then
          self.cost_data = qinnu.id
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.dead then return end
    local card = Fk:getCardById(self.cost_data)
    local room = player.room
    room:setCardMark(card, MarkEnum.DestructOutMyEquip, 1)
    room:useCard{
      from = player.id,
      card = card,
      tos = { {player.id} }
    }
  end,
}

Fk:loadTranslationTable{
  ["qin__jingnu"] = "劲弩",
  [":qin__jingnu"] = "锁定技，回合开始时，若你装备区里没有【秦弩】，你从游戏外使用一张【秦弩】。",
  ["$qin__jingnu"] = "劲弩在手，百发皆中！"
}

nushou:addSkill(tongpao)
nushou:addSkill(jingnu)

-- 骑兵
local qibing = General(extension, "qin__qibing", "qin", 3)
qibing.hidden = true

Fk:loadTranslationTable{
  ["qin__qibing"] = "秦军骑兵"
}

local changjian = fk.CreateTriggerSkill{
  name = "qin__changjian",
  anim_type = "offensive",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player then
      return data.card.trueName == "slash"
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"changjian-exTG", "changjian-exDMG", "Cancel"}
    local choices = table.clone(all_choices)
    local tos = room:getUseExtraTargets(data)
    tos = table.filter(table.map(tos, Util.Id2PlayerMapper), function (p)
      return player:inMyAttackRange(p)
    end)
    if #tos == 0 then
      table.removeOne(choices, "changjian-exTG")
    end
    local choice = room:askForChoice(player, choices, self.name, "#changjian-choose", false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "changjian-exTG" then
      local tos = room:getUseExtraTargets(data)
      tos = table.filter(tos, function (id)
        return player:inMyAttackRange(room:getPlayerById(id))
      end)
      local ex_to = room:askForChoosePlayers(player, tos, 1, 1, "#changjian-ex", self.name, false)
      if #ex_to == 1 then
        table.insertTable(data.tos, {ex_to})
      end
    else
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
local changjian_attackrange = fk.CreateAttackRangeSkill{
  name = "#changjian_attackrange",
  frequency = Skill.Compulsory,
  correct_func = function (self, from, to)
    if from:hasSkill(changjian) then
      return 1
    end
  end,
}
changjian:addRelatedSkill(changjian_attackrange)

Fk:loadTranslationTable{
  ["qin__changjian"] = "长剑",
  [":qin__changjian"] = "锁定技，你的攻击范围+1；当你使用【杀】指定目标时，你选择一项："
  .."1.令攻击范围内的一名角色成为此【杀】的额外目标；2.令此【杀】造成的伤害+1。",
  ["$qin__changjian"] = "长剑一出，所向披靡！",

  ["#changjian_attackrange"] = "长剑",
  ["#changjian-choose"] = "长剑：请为此【杀】选择一项增益效果",
  ["changjian-exTG"] = "令攻击范围内的一名角色成为此【杀】的额外目标",
  ["changjian-exDMG"] = "令此【杀】造成的伤害+1",
  ["#changjian-ex"] = "长剑：令一名角色成为此【杀】的额外目标",
}

local liangju = fk.CreateTriggerSkill{
  name = "qin__liangju",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      return data.card.trueName == "slash"
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TargetSpecified then -- offence!
      room:notifySkillInvoked(player, self.name, "offensive")
      local judge = {
        who = room:getPlayerById(data.to),
        reason = self.name,
        pattern = ".|.|diamond",
      }
      room:judge(judge)
      if judge.card.suit == Card.Diamond then
        data.unoffsetable = true
      end
    else -- defence!
      room:notifySkillInvoked(player, self.name, "defensive")
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|heart",
      }
      room:judge(judge)
      if judge.card.suit == Card.Heart then
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,
}

Fk:loadTranslationTable{
  ["qin__liangju"] = "良驹",
  [":qin__liangju"] = "锁定技，你使用【杀】指定一名目标后，其须判定：若结果为<font color='red'>♦</font>，其不能使用【闪】响应；"
  .."当你成为【杀】的目标后，你须判定：若结果为<font color='red'>♥</font>，此【杀】对你无效。",
  ["$qin__liangju"] = "良驹千里，踏遍河山"
}

qibing:addSkill("qin__tongpao")
qibing:addSkill(changjian)
qibing:addSkill(liangju)

-- 步兵
local bubing = General(extension, "qin__bubing", "qin", 4)
bubing.hidden = true

Fk:loadTranslationTable{
  ["qin__bubing"] = "秦军步兵"
}

local fangzhen = fk.CreateTriggerSkill{
  name = "qin__fangzhen",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if target == player and player:hasSkill(self) then
      return (data.card:isCommonTrick() or data.card.trueName == "slash")
        and from.kingdom ~= "qin" and player:inMyAttackRange(from)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.color == Card.Black and player:canUseTo(slash, from, {bypass_times = true}) then
      room:useCard{
        from = player.id,
        card = slash,
        tos = {{from.id}},
        extraUse = true,
      }
    end
  end,
}

Fk:loadTranslationTable{
  ["qin__fangzhen"] = "方阵",
  [":qin__fangzhen"] = "锁定技，当一名为非秦势力角色指定你为普通锦囊牌或【杀】的目标后，若其在你的攻击范围内，"
  .."你判定：若结果为黑色，你视为对其使用一张【杀】。",
  ["$qin__fangzhen"] = "步阵而走，方寸之间。"
}

local changbing = fk.CreateAttackRangeSkill{
  name = "qin__changbing",
  frequency = Skill.Compulsory,
  correct_func = function (self, from, to)
    if from:hasSkill(self) then
      return 2
    end
  end,
}

Fk:loadTranslationTable{
  ["qin__changbing"] = "长兵",
  [":qin__changbing"] = "锁定技，你的攻击范围+2。"
}

bubing:addSkill("qin__tongpao")
bubing:addSkill(fangzhen)
bubing:addSkill(changbing)

local wuhushangjiang = General(extension, "wuhushangjiang", "shu", 4)
local function GetWuhuSkills(player)
  local mappers = Fk:currentRoom():getBanner("huyi_wuhushangjiang")
  if mappers == nil then
    local skills = {}
    local generals = {}
    local SGmapper = {}
    for _, name in ipairs(player.room.general_pile) do
      if table.find({"guanyu", "zhangfei", "zhaoyun", "machao", "huangzhong"}, function(s)
          return name:endsWith(s)
        end) or name == "gundam" then  --高达！
        table.insert(generals, Fk.generals[name])
      end
    end
    if #generals == 0 then return {} end
    for _, general in ipairs(generals) do
      local list = general:getSkillNameList(true)
      for _, skill in ipairs(list) do
        table.insert(skills, skill)
        SGmapper[skill] = general.name
      end
    end
    mappers = {skills, SGmapper}
    Fk:currentRoom():setBanner("huyi_wuhushangjiang", mappers)
  end
  return table.filter(mappers[1], function(s) return not player:hasSkill(s, true) end)
end
local huyi = fk.CreateTriggerSkill {
  name = "huyi",
  anim_type = "special",
  events = {fk.GameStart, fk.CardUseFinished, fk.CardRespondFinished, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        if target == player then
          if event == fk.TurnEnd then
            return #player:getTableMark(self.name) > 0
          else
            return data.card.type == Card.TypeBasic and #player:getTableMark(self.name) < 5 and
              table.find(GetWuhuSkills(player), function(s)
                return string.find(Fk:getDescription(s, "zh_CN"), "【"..Fk:translate(data.card.trueName, "zh_CN").."】")
              end)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TurnEnd then
      local skills = player:getTableMark(self.name)
      local generals = table.map(skills, function(s) return player.room:getBanner("huyi_wuhushangjiang")[2][s] end)
      local result = player.room:askForCustomDialog(player, self.name,
      "packages/utility/qml/ChooseSkillBox.qml", {
        skills, 0, 1, "#huyi-invoke", generals,
      })
      if result == "" then return false end
      local choice = json.decode(result)
      if #choice > 0 then
        self.cost_data = choice[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark(self.name)
    if event == fk.TurnEnd then
      table.removeOne(mark, self.cost_data)
      room:setPlayerMark(player, self.name, mark)
      room:handleAddLoseSkills(player, "-"..self.cost_data, nil, true, false)
    else
      local skills = {}
      local skill = ""
      if event == fk.GameStart then
        skills = table.random(GetWuhuSkills(player), 3)
        if #skills == 0 then return end
        local generals = table.map(skills, function(s) return player.room:getBanner("huyi_wuhushangjiang")[2][s] end)
        local result = room:askForCustomDialog(player, self.name,
        "packages/utility/qml/ChooseSkillBox.qml", {
          skills, 1, 1, "#huyi-choose", generals,
        })
        if result == "" then
          skill = table.random(skills)
        else
          skill = json.decode(result)[1]
        end
      else
        skills = table.filter(GetWuhuSkills(player), function(s)
          return string.find(Fk:getDescription(s, "zh_CN"), "【"..Fk:translate(data.card.trueName, "zh_CN").."】")
        end)
        if #skills == 0 then return end
        skill = table.random(skills)
      end
      table.insertIfNeed(mark, skill)
      room:setPlayerMark(player, self.name, mark)
      room:handleAddLoseSkills(player, skill, nil, true, false)
    end
  end,
}
wuhushangjiang:addSkill(huyi)
Fk:loadTranslationTable{
  ["wuhushangjiang"] = "魂·五虎",
  --["#wuhushangjiang"] = ""

  ["huyi"] = "虎翼",
  [":huyi"] = "游戏开始时，你从三个五虎将技能中选择一个获得。当你使用或打出一张基本牌后，若你因本技能获得的技能总数小于5，你随机获得一个"..
  "描述中包含此牌名的五虎将技能。回合结束时，你可以选择失去一个以此法获得的技能。",
  ["#huyi-choose"] = "虎翼：选择获得一个五虎技能",
  ["#huyi-invoke"] = "虎翼：你可以失去一个五虎技能",

  ["$huyi1"] = "青龙啸赤月，长刀行千里。",
  ["$huyi2"] = "矛取敌将首，声震当阳桥。",
  ["$huyi3"] = "身跨白玉鞍，铁骑踏冰河。",
  ["$huyi4"] = "满弓望西北，弦惊夜行之虎。",
  ["$huyi5"] = "游龙战长坂，可复七进七出。",
  --["~wuhushangjiang"] = "麦城残阳……洗长刀……",
  --["~wuhushangjiang"] = "当阳……空余声……",
  --["~wuhushangjiang"] = "西风寒……冷铁衣……",
  --["~wuhushangjiang"] = "年老力衰……不复当年勇……",
  ["~wuhushangjiang"] = "亢龙……有悔……",
}

local caocao = General(extension, "ol__caocao", "qun", 4)
local dingxi = fk.CreateTriggerSkill{
  name = "dingxi",
  mute = true,
  derived_piles = "dingxi",
  events = {fk.AfterCardsMove, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        local room = player.room
        local cards = {}
        for _, move in ipairs(data) do
          if move.from == nil and move.moveReason == fk.ReasonUse then
            local move_event = room.logic:getCurrentEvent()
            local use_event = move_event.parent
            if use_event ~= nil and use_event.event == GameEvent.UseCard then
              local use = use_event.data[1]
              if use.from == player.id and use.card.is_damage_card then
                local card_ids = room:getSubcardsByRule(use.card)
                for _, info in ipairs(move.moveInfo) do
                  local card = Fk:getCardById(info.cardId, true)
                  if table.contains(card_ids, info.cardId) and card.is_damage_card and
                    table.contains(room.discard_pile, info.cardId) then
                    table.insertIfNeed(cards, info.cardId)
                  end
                end
              end
            end
          end
        end
        cards = U.moveCardsHoldingAreaCheck(room, cards)
        cards = table.filter(cards, function (id)
          local card = Fk:getCardById(id)
          if player:getLastAlive() == player then
            return player:canUseTo(card, player)
          else
            return not player:isProhibited(player:getLastAlive(), card)
          end
        end)
        if #cards > 0 then
          self.cost_data = cards
          return true
        end
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and #player:getPile(self.name) > 0
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.AfterCardsMove then
      local use = U.askForUseRealCard(player.room, player, self.cost_data, nil, self.name, "#dingxi-use::"..player:getLastAlive().id,
        {
          expand_pile = self.cost_data,
          must_targets = {player:getLastAlive().id},
          bypass_times = true,
          extraUse = true,
        },
        true, true)
      if use then
        self.cost_data = use
        return true
      end
    elseif event == fk.EventPhaseStart then
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "offensive")
      local use = self.cost_data
      if #use.tos == 0 then
        use.tos = {{player:getLastAlive().id}}
      end
      use.extra_data = use.extra_data or {}
      use.extra_data.dingxi = player.id
      room:useCard(self.cost_data)
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(#player:getPile(self.name), self.name)
    end
  end,
}
local dingxi_delay = fk.CreateTriggerSkill{
  name = "#dingxi_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.dingxi == player.id and
      not player.dead and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:addToPile("dingxi", data.card, true, "dingxi", player.id)
  end,
}
local nengchen = fk.CreateTriggerSkill{
  name = "nengchen",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and
      table.find(player:getPile("dingxi"), function (id)
        return data.card.trueName == Fk:getCardById(id).trueName
      end)
  end,
  on_use = function(self, event, target, player, data)
    local cards = table.filter(player:getPile("dingxi"), function (id)
      return data.card.trueName == Fk:getCardById(id).trueName
    end)
    player.room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
  end,
}
local huojie = fk.CreateTriggerSkill{
  name = "huojie",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and #player:getPile("dingxi") > #player.room.players
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = #player:getPile("dingxi")
    for i = 1, n, 1 do
      if player.dead then return end
      local judge = {
        who = player,
        reason = "lightning",
        pattern = ".|2~9|spade",
      }
      room:judge(judge)
      if judge.card.suit == Card.Spade and judge.card.number > 1 and judge.card.number < 10 then
        if player.dead then return end
        room:damage{
          to = player,
          damage = 3,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
        if player.dead then return end
        if #player:getPile("dingxi") > 0 then
          room:moveCardTo(player:getPile("dingxi"), Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
        end
        break
      end
    end
  end,
}
dingxi:addRelatedSkill(dingxi_delay)
caocao:addSkill(dingxi)
caocao:addSkill(nengchen)
caocao:addSkill(huojie)
Fk:loadTranslationTable{
  ["ol__caocao"] = "忠曹操",
  ["illustrator:ol__caocao"] = "凡果",

  ["dingxi"] = "定西",
  [":dingxi"] = "当你使用伤害牌结算完毕进入弃牌堆后，你可以对你的上家使用其中一张伤害牌（无次数限制），然后将之置于你的武将牌上。结束阶段，"..
  "你摸X张牌（X为“定西”牌数）。",
  ["nengchen"] = "能臣",
  [":nengchen"] = "锁定技，当你受到伤害后，你获得随机一张与造成伤害的牌牌名相同的“定西”牌。",
  ["huojie"] = "祸结",
  [":huojie"] = "锁定技，出牌阶段开始时，若X大于游戏人数，你进行X次【闪电】判定直到你以此法受到伤害（X为“定西”牌的数量）。若你以此法受到伤害，"..
  "你获得所有“定西”牌。",
  ["#dingxi-use"] = "定西：你可以对 %dest 使用其中一张牌",
  ["#dingxi_delay"] = "定西",

  ["$dingxi1"] = "今天，我曹操誓要踏平祁连山！",
  ["$dingxi2"] = "饮马瀚海、封狼居胥，大丈夫当如此！",
  ["$nengchen1"] = "当今四海升平，可为治世之能臣。",
  ["$nengchen2"] = "为大汉江山鞠躬尽瘁，臣死犹生。",
  ["$huojie1"] = "国虽大，忘战必危，好战必亡。",
  ["$huojie2"] = "这穷兵黩武的罪，让我一人受便可！",
  ["~ol__caocao"] = "此征西将军曹侯之墓。",
}

local lvbu = General(extension, "ol__lvbu", "qun", 5)
local fengzhu = fk.CreateTriggerSkill{
  name = "fengzhu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player), function (p)
        return p:isMale() and not table.contains(player:getTableMark(self.name), p.id)
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local fathers = table.filter(room:getOtherPlayers(player), function (p)
      return p:isMale() and not table.contains(player:getTableMark(self.name), p.id)
    end)
    local father = room:askForChoosePlayers(player, table.map(fathers, Util.IdMapper), 1, 1, "#fengzhu-father", self.name, false)
    father = room:getPlayerById(father[1])
    room:setPlayerMark(father, "@@fengzhu_father", 1)
    room:addTableMark(player, self.name, father.id)
    player:drawCards(3, self.name)
  end,
}
local yuyu = fk.CreateTriggerSkill{
  name = "yuyu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd, fk.Damaged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getMark("fengzhu") ~= 0 then
      if event == fk.TurnEnd then
        return target == player and
          table.find(player:getTableMark("fengzhu"), function (id)
            return not player.room:getPlayerById(id).dead
          end)
      else
        local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
        if turn_event == nil or not table.contains(player:getTableMark("fengzhu"), turn_event.data[1].id) or
          turn_event.data[1].dead then return end
        if event == fk.Damaged then
          return target == player
        elseif event == fk.AfterCardsMove then
          for _, move in ipairs(data) do
            if move.from == player.id then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  return true
                end
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      local fathers = table.filter(player:getTableMark("fengzhu"), function (id)
        return not room:getPlayerById(id).dead
      end)
      local father = room:askForChoosePlayers(player, fathers, 1, 1, "#yuyu-hate", self.name, false)
      father = room:getPlayerById(father[1])
      room:addPlayerMark(father, "@lvbu_hate", 1)
    else
      local n = 0
      if event == fk.Damaged then
        n = data.damage
      elseif event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                n = n + 1
              end
            end
          end
        end
      end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      room:addPlayerMark(turn_event.data[1], "@lvbu_hate", n)
    end
  end,
}
local zhijil = fk.CreateTriggerSkill{
  name = "zhijil",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      table.contains(player:getTableMark("fengzhu"), data.to) and
      player.room:getPlayerById(data.to):getMark("@lvbu_hate") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local father = room:getPlayerById(data.to)
    local n = father:getMark("@lvbu_hate")
    if data.card.is_damage_card then
      data.additionalDamage = (data.additionalDamage or 0) + n
      room:setPlayerMark(father, "@lvbu_hate", 0)
    else
      for i = 1, n, 1 do
        local judge = {
          who = player,
          reason = self.name,
          pattern = "slash,duel;.|.|.|.|.|equip",
          skipDrop = true,
        }
        room:judge(judge)
        if player.dead then
          if room:getCardArea(judge.card) == Card.Processing then
            room:moveCardTo(judge.card, Card.DiscardPile, nil, fk.ReasonJudge)
          end
          break
        end
        if judge.card.type == Card.TypeEquip then
          room:handleAddLoseSkills(player, "shenji", nil, true, false)
          if room:getCardArea(judge.card) == Card.Processing then
            room:moveCardTo(judge.card, Card.DiscardPile, nil, fk.ReasonJudge)
          end
        elseif table.contains({"slash", "duel"}, judge.card.trueName) then
          room:handleAddLoseSkills(player, "wushuang", nil, true, false)
          if room:getCardArea(judge.card) == Card.Processing then
            room:moveCardTo(judge.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
          end
        end
        if room:getCardArea(judge.card) == Card.Processing then
          room:moveCardTo(judge.card, Card.DiscardPile, nil, fk.ReasonJudge)
        end
      end
    end
  end,
}
local jiejiu = fk.CreateViewAsSkill{
  name = "jiejiu",
  pattern = ".|.|.|.|.|basic",
  prompt = "#jiejiu",
  interaction = function(self)
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, self.name, all_names, nil, {"analeptic"})
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "analeptic"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
}
local jiejiu_trigger = fk.CreateTriggerSkill{
  name = "#jiejiu_trigger",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiejiu)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:isFemale() then
        local skills = Fk.generals[p.general]:getSkillNameList(true)
        if #skills > 0 then
          room:handleAddLoseSkills(p, "lijian|-"..table.random(skills), nil, true, false)
        end
      end
    end
  end,
}
local jiejiu_prohibit = fk.CreateProhibitSkill{
  name = "#jiejiu_prohibit",
  prohibit_use = function(self, player, card)
    if not player:hasSkill(jiejiu) or not card or card.trueName ~= "analeptic" or #card.skillNames > 0 then return false end
    local subcards = Card:getIdList(card)
    return #subcards > 0 and table.every(subcards, function(id)
      return table.contains(player:getCardIds("h&"), id)
    end)
  end
}
jiejiu:addRelatedSkill(jiejiu_trigger)
jiejiu:addRelatedSkill(jiejiu_prohibit)
lvbu:addSkill(fengzhu)
lvbu:addSkill(yuyu)
lvbu:addSkill(zhijil)
lvbu:addSkill(jiejiu)
Fk:loadTranslationTable{
  ["ol__lvbu"] = "战神吕布",
  ["illustrator:ol__lvbu"] = "鬼画府",

  ["fengzhu"] = "逢主",
  [":fengzhu"] = "锁定技，准备阶段，你拜一名其他男性角色为“义父”，摸三张牌。",
  ["yuyu"] = "郁郁",
  [":yuyu"] = "锁定技，你的回合结束时，你令一名“义父”获得一枚“恨”标记。你于其回合每受到1点伤害或每失去一张牌后，其获得一枚“恨”标记。",
  ["zhijil"] = "掷戟",
  [":zhijil"] = "锁定技，你使用非伤害牌指定“义父”为目标时，你判定X次，若判定牌包含：装备牌，你获得〖神戟〗；【杀】或【决斗】，你获得〖无双〗和"..
  "此判定牌。你使用伤害牌指定“义父”为目标时，你令此牌伤害+X并移除其“恨”标记（X为其“恨”标记的数量）。",
  ["jiejiu"] = "戒酒",
  [":jiejiu"] = "锁定技，你的【酒】仅能当其他基本牌使用。游戏开始时，将其他女性角色武将牌上随机一个技能替换为〖离间〗。",
  ["#fengzhu-father"] = "逢主：拜一名男性角色为“义父”，摸三张牌",
  ["@@fengzhu_father"] = "义父",
  ["@lvbu_hate"] = "恨",
  ["#yuyu-hate"] = "郁郁：令一名“义父”获得一枚“恨”标记",
  ["#jiejiu"] = "戒酒：仅能将【酒】当其他基本牌使用",
  ["#jiejiu_trigger"] = "戒酒",

  ["$fengzhu"] = "吕布飘零半生，只恨未逢明主，公若不弃，布愿拜为义父！",
  ["$yuyu"] = "大丈夫生居天地之间，岂能郁郁久居人下！",
  ["$zhijil1"] = "老贼，我与你势不两立！",
  ["$zhijil2"] = "我堂堂大丈夫，安肯为汝之义子！",
  ["$jiejiu"] = "我被酒色所伤，竟然如此憔悴。自今日始，戒酒！",
  ["~ol__lvbu"] = "刘备！奸贼！汝乃天下最无信义之人！",
}

return extension
