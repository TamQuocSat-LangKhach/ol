local extension = Package("ol_menfa")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_menfa"] = "OL-门阀士族",
  ["olz"] = "宗族",
}

local olz__xunchen = General(extension, "olz__xunchen", "qun", 3)
local sankuang = fk.CreateTriggerSkill{
  name = "sankuang",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      local mark = "sankuang_"..data.card:getTypeString().."-round"
      if player:getMark(mark) == 0 then
        player.room:addPlayerMark(player, mark, 1)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      local n = 0
      if #p:getCardIds{Player.Equip, Player.Judge} > 0 then n = n + 1 end
      if p:isWounded() then n = n + 1 end
      if p.hp < #p.player_cards[Player.Hand] then n = n + 1 end
      room:setPlayerMark(p, "@sankuang", n)  --FIXME: 用来显示三恇张数
      if #p:getCardIds{Player.Hand, Player.Equip} >= n then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#sankuang-choose:::"..data.card:toLogString(), self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    to = room:getPlayerById(to)
    if player:getMark("beishi") == 0 then
      room:setPlayerMark(player, "beishi", to.id)
    end
    local n = to:getMark("@sankuang")
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@sankuang", 0)
    end
    if n > 0 then
      local cards = room:askForCard(to, n, #to:getCardIds{Player.Hand, Player.Equip}, true, self.name, false, ".",
        "#sankuang-give:"..player.id.."::"..n)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, false, fk.ReasonGive)
    end
    if room:getCardArea(data.card) == Card.PlayerEquip or room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(to.id, data.card, true, fk.ReasonPrey)
    end
  end,
}
local beishi = fk.CreateTriggerSkill{
  name = "beishi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:isWounded() and player.tag["beishi"] then
      for _, move in ipairs(data) do
        if move.from == player.tag["beishi"] and player.room:getPlayerById(move.from):isKongcheng() then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
  end,
}
local daojie = fk.CreateTriggerSkill{
  name = "daojie",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("daojie-turn") == 0 and
      data.card.type == Card.TypeTrick and not data.card.is_damage_card
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "daojie-turn", 1)
    local skills = {"daojie_cancel"}
    for _, skill in ipairs(player.player_skills) do
      if skill.frequency == Skill.Compulsory and not skill.attached_equip then
        table.insert(skills, skill.name)
      end
    end
    local choice = room:askForChoice(player, skills, self.name, "#daojie-choice", true)
    if choice == "daojie_cancel" then
      room:loseHp(player, 1, self.name)
    else
      room:handleAddLoseSkills(player, "-"..choice, nil, true, false)
      if room:getCardArea(data.card) == Card.Processing then
        local targets = {}
        for _, p in ipairs(room:getAlivePlayers()) do
          if string.find(p.general, "olz__xun") or
            string.find(p.general, "xunyu") or string.find(p.general, "xunyou") or string.find(p.general, "xunchen") then
            table.insert(targets, p.id)
          end
        end
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#daojie-choose:::"..data.card:toLogString(), self.name, false)
        if #to == 0 then
          to = {table.random(targets)}
        end
        room:obtainCard(to[1], data.card, true, fk.ReasonPrey)
      end
    end
  end,
}
olz__xunchen:addSkill(sankuang)
olz__xunchen:addSkill(beishi)
olz__xunchen:addSkill(daojie)
Fk:loadTranslationTable{
  ["olz__xunchen"] = "荀谌",
  ["sankuang"] = "三恇",
  [":sankuang"] = "锁定技，当你每轮首次使用一种类别的牌后，你令一名其他角色交给你至少X张牌并获得你使用的牌（X为其满足的项数：1.场上有牌；2.已受伤；"..
  "3.体力值小于手牌数）。",
  ["beishi"] = "卑势",
  [":beishi"] = "锁定技，当你首次发动〖三恇〗选择的角色失去最后的手牌后，你回复1点体力。",
  ["daojie"] = "蹈节",
  [":daojie"] = "宗族技，锁定技，当你每回合首次使用非伤害锦囊牌后，你选择一项：1.失去1点体力；2.失去一个锁定技，然后令一名同族角色获得此牌。",
  ["#sankuang-choose"] = "三恇：令一名其他角色交给你至少X张牌并获得你使用的%arg",
  ["@sankuang"] = "三恇张数：",
  ["#sankuang-give"] = "三恇：你须交给 %src %arg张牌",
  ["#daojie-choice"] = "蹈节：失去一个锁定技，或点“取消”失去1点体力",
  ["#daojie-choose"] = "蹈节：令一名同族角色获得此%arg",
  ["daojie_cancel"] = "取消",
  [":daojie_cancel"] = "失去1点体力",

  ["$sankuang1"] = "人言可畏，宜常辟之。",
  ["$sankuang2"] = "天地可敬，可常惧之。",
  ["$beishi1"] = "虎卑其势，将有所逮。",
  ["$beishi2"] = "至山穷水尽，复柳暗花明。",
  ["$daojie1"] = "此生所重者，慷慨之节也。",
  ["$daojie2"] = "愿以此身，全清尚之节。",
  ["~olz__xunchen"] = "行二臣之为，羞见列祖……",
}

local xunshu = General(extension, "olz__xunshu", "qun", 3)
local shenjun_viewas = fk.CreateViewAsSkill{
  name = "shenjun_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Self:getMark("shenjun-phase")) do
      table.insertIfNeed(names, Fk:getCardById(id, true).name)
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected < #Self:getMark("shenjun-phase")
  end,
  view_as = function(self, cards)
    if Self:getMark("shenjun-phase") ~= 0 and #cards ~= #Self:getMark("shenjun-phase") or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = "shenjun"
    return card
  end,
}
local shenjun = fk.CreateTriggerSkill{
  name = "shenjun",
  anim_type = "special",
  events = {fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.CardUsing then
        return (data.card.trueName == "slash" or data.card:isCommonTrick()) and not player:isKongcheng() and
          table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end)
      else
        if player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and not player:isNude() then
          local cards = {}
          for _, id in ipairs(player.player_cards[Player.Hand]) do
            if table.contains(player:getMark("shenjun-phase"), id) then
              table.insertIfNeed(cards, id)
            end
          end
          if #cards > 0 then
            player.room:setPlayerMark(player, "shenjun-phase", cards)
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return true
    else
      local success, dat = player.room:askForUseActiveSkill(player, "shenjun_viewas",
        "#shenjun-invoke:::"..#player:getMark("shenjun-phase"), true)
      if success then
        self.cost_data = dat
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end)
      player:showCards(cards)
      if player.dead then return end
      local mark = player:getMark("shenjun-phase")
      if mark == 0 then mark = {} end
      for _, id in ipairs(cards) do
        table.insertIfNeed(mark, id)
      end
      room:setPlayerMark(player, "shenjun-phase", mark)
    else
      local card = Fk.skills["shenjun_viewas"]:viewAs(self.cost_data.cards)
      room:useCard{
        from = player.id,
        tos = table.map(self.cost_data.targets, function(id) return {id} end),
        card = card,
      }
    end
  end,
}
local balong = fk.CreateTriggerSkill{
  name = "balong",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.HpChanged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if player:getMark("balong-turn") == 0 then
        player.room:setPlayerMark(player, "balong-turn", 1)
        if not player:isKongcheng() then
          local types = {Card.TypeBasic, Card.TypeEquip, Card.TypeTrick}
          local num = {0, 0, 0}
          for i = 1, 3, 1 do
            num[i] = #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type == types[i] end)
          end
          return num[3] > num[1] and num[3] > num[2]
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    if #cards < #player.room.alive_players and not player.dead then
      player:drawCards(#player.room.alive_players - #cards, self.name)
    end
  end,
}
Fk:addSkill(shenjun_viewas)
xunshu:addSkill(shenjun)
xunshu:addSkill(balong)
xunshu:addSkill("daojie")
Fk:loadTranslationTable{
  ["olz__xunshu"] = "荀淑",
  ["shenjun"] = "神君",
  [":shenjun"] = "当一名角色使用【杀】或普通锦囊牌时，你展示所有同名手牌记为“神君”，本阶段结束时，你可以将X张牌当任意“神君”牌使用（X为“神君”牌数）。",
  ["balong"] = "八龙",
  [":balong"] = "锁定技，当你每回合体力值首次变化后，若你手牌中锦囊牌为唯一最多的类型，你展示手牌并摸至与存活角色数相同。",
  ["#shenjun-invoke"] = "神君：你可以将%arg张牌当一种“神君”牌使用",

  ["$shenjun1"] = "区区障眼之法，难遮神人之目。",
  ["$shenjun2"] = "我以天地为师，自可道法自然。",
  ["$balong1"] = "八龙之蜿蜿，云旗之委蛇。",
  ["$balong2"] = "穆王乘八牡，天地恣遨游。",
  --["$daojie1"] = "荀人如玉，向节而生。",
  --["$daojie2"] = "竹有其节，焚之不改。",
  ["~olz__xunshu"] = "天下陆沉，荀氏难支……",
}

local xuncan = General(extension, "olz__xuncan", "wei", 3)
local yushen = fk.CreateActiveSkill{
  name = "yushen",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):isWounded() and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if player:getMark("fenchai") == 0 and player.gender ~= target.gender then
      room:setPlayerMark(player, "fenchai", target.id)
    end
    room:recover({
      who = target,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    local choice = room:askForChoice(player, {"yushen1", "yushen2"}, self.name)
    if choice == "yushen1" then
      room:useVirtualCard("ice__slash", nil, target, player, self.name, true)
    else
      room:useVirtualCard("ice__slash", nil, player, target, self.name, true)
    end
   end
}
local shangshen = fk.CreateTriggerSkill{
  name = "shangshen",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and not target.dead and data.damageType ~= fk.NormalDamage then
      if player:getMark("shangshen-turn") == 0 then
        player.room:setPlayerMark(player, "shangshen-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#shangshen-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    if player:getMark("fenchai") == 0 and player.gender ~= target.gender then
      room:setPlayerMark(player, "fenchai", target.id)
    end
    local judge = {
      who = player,
      reason = "lightning",
      pattern = ".|2~9|spade",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade and judge.card.number >= 2 and judge.card.number <= 9 then
      room:damage{
        to = player,
        damage = 3,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
    local n = 4 - target:getHandcardNum()
    if n > 0 and not target.dead then
      target:drawCards(n, self.name)
    end
  end,
}
local fenchai = fk.CreateFilterSkill{
  name = "fenchai",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self.name) and player:getMark(self.name) ~= 0 and RoomInstance and
      RoomInstance.logic:getCurrentEvent().event == GameEvent.Judge
  end,
  view_as = function(self, to_select, player)
    local suit = Card.Heart
    if player:getMark(self.name) ~= 0 and Fk:currentRoom():getPlayerById(player:getMark(self.name)).dead then
      suit = Card.Spade
    end
    return Fk:cloneCard(to_select.name, suit, to_select.number)
  end,
}
xuncan:addSkill(yushen)
xuncan:addSkill(shangshen)
xuncan:addSkill(fenchai)
xuncan:addSkill("daojie")
Fk:loadTranslationTable{
  ["olz__xuncan"] = "荀粲",
  ["yushen"] = "熨身",
  [":yushen"] = "出牌阶段限一次，你可以选择一名其他角色并令其回复1点体力，然后选择一项：1.视为其对你使用一张冰【杀】；2.视为你对其使用一张冰【杀】。",
  ["shangshen"] = "伤神",
  [":shangshen"] = "当每回合首次有角色受到属性伤害后，你可以进行一次【闪电】判定并令其将手牌摸至四张。",
  ["fenchai"] = "分钗",
  [":fenchai"] = "锁定技，若首次成为你技能目标的异性角色存活，你的判定牌视为<font color='red'>♥</font>，否则视为♠。",
  ["#shangshen-invoke"] = "伤神：你可以进行一次【闪电】判定并令 %dest 将手牌摸至四张",
  ["yushen1"] = "视为其对你使用冰【杀】",
  ["yushen2"] = "视为你对其使用冰【杀】",

  ["$yushen1"] = "此心恋卿，尽融三九之冰。",
  ["$yushen2"] = "寒梅傲雪，馥郁三尺之香。",
  ["$shangshen1"] = "识字数万，此痛无字可言。",
  ["$shangshen2"] = "吾妻已逝，吾心悲怆。",
  ["$fenchai1"] = "钗同我心，奈何分之？",
  ["$fenchai2"] = "夫妻分钗，天涯陌路。",
  --["$daojie1"] = "君子持节，何移情乎？",
  --["$daojie2"] = "我心慕鸳，从一而终。",
  ["~olz__xuncan"] = "此钗，今日可合乎？",
}

Fk:loadTranslationTable{
  ["olz__xuncai"] = "荀采",
  ["lieshi"] = "烈誓",
  [":lieshi"] = "出牌阶段，你可以选择一项：1.废除判定区并受到你的1点火焰伤害；2.弃置所有【闪】；3.弃置所有【杀】。然后令一名其他角色选择其他两项中的一项。",
  ["dianzhan"] = "点盏",
  [":dianzhan"] = "锁定技，当你每轮首次使用一种花色的牌后，你横置此牌唯一目标并重铸此花色的所有手牌，然后若你以此法横置了角色且你以此法重铸了牌，你摸一张牌。",
  ["huanyin"] = "还阴",
  [":huanyin"] = "锁定技，当你进入濒死状态时，你将手牌摸至4张。",

  ["$lieshi1"] = "拭刃为誓，女无二夫。",
  ["$lieshi2"] = "霜刃证言，宁死不贰。",
  ["$dianzhan1"] = "此灯如我，独向光明。",
  ["$dianzhan2"] = "此间皆暗，唯灯瞩明。",
  ["$huanyin1"] = "且将此身，还于阴氏。",
  ["$huanyin2"] = "生不得同户，死可葬同穴乎？",
  --["$daojie1"] = "荀氏三纲，死不贰嫁。",
  --["$daojie2"] = "女子有节，宁死蹈之。",
  ["~olz__xuncai"] = "苦难已过，世间大好……",
}

local olz__wuban = General(extension, "olz__wuban", "shu", 4)
local zhanding = fk.CreateViewAsSkill{
  name = "zhanding",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return true
  end,
  view_as = function(self, cards)
    if #cards == 0 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    if player:getMaxCards() > 0 then
      player.room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
local zhanding_record = fk.CreateTriggerSkill{
  name = "#zhanding_record",
  anim_type = "offensive",

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "zhanding")
  end,
  on_refresh = function(self, event, target, player, data)
    if data.damageDealt then
      local n = #player.player_cards[Player.Hand] - player:getMaxCards()
      if n < 0 then
        player:drawCards(-n, self.name)
      elseif n > 0 then
        player.room:askForDiscard(player, n, n, false, self.name, false)
      end
    else
      player:addCardUseHistory(data.card.trueName, -1)
    end
  end,
}
local muyin = fk.CreateTriggerSkill{
  name = "muyin",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Start then
      self.muyin_tos = {}
      local n = player:getMaxCards()
      for _, p in ipairs(player.room:getAlivePlayers()) do
        if p:getMaxCards() > n then
          n = p:getMaxCards()
        end
      end
      for _, p in ipairs(player.room:getAlivePlayers()) do
        if (string.find(p.general, "olz__wu") or string.find(p.general, "wuxian")) and p:getMaxCards() < n then
          table.insert(self.muyin_tos, p.id)
        end
      end
      return #self.muyin_tos > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, self.muyin_tos, 1, 1, "#muyin-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), MarkEnum.AddMaxCards, 1)
  end,
}
zhanding:addRelatedSkill(zhanding_record)
olz__wuban:addSkill(zhanding)
olz__wuban:addSkill(muyin)
Fk:loadTranslationTable{
  ["olz__wuban"] = "吴班",
  ["zhanding"] = "斩钉",
  [":zhanding"] = "你可以将任意张牌当【杀】使用并令你手牌上限-1，若此【杀】：造成伤害，你将手牌数调整至手牌上限；未造成伤害，此【杀】不计入次数。",
  ["muyin"] = "穆荫",
  [":muyin"] = "宗族技，准备阶段，你可以令一名手牌上限不为全场最大的同族角色手牌上限+1。",
  ["#muyin-choose"] = "穆荫：你可以令一名同族角色手牌上限+1",
}

local olz__wuxian = General(extension, "olz__wuxian", "shu", 3, 3, General.Female)
local yirong = fk.CreateActiveSkill{
  name = "yirong",
  anim_type = "drawcard",
  target_num = 0,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2 and #player.player_cards[Player.Hand] ~= player:getMaxCards()
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = #player.player_cards[Player.Hand] - player:getMaxCards()
    if n < 0 then
      player:drawCards(-n, self.name)
      if player:getMaxCards() > 0 then
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      end
    elseif n > 0 then
      room:askForDiscard(player, n, n, false, self.name, false)
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    end
  end,
}
local guixiang = fk.CreateTriggerSkill{
  name = "guixiang",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.to > Player.RoundStart and data.to < Player.NotActive then
      player.room:addPlayerMark(player, "guixiang-turn", 1)
      return player:getMark("guixiang-turn") == player:getMaxCards()
    end
  end,
  on_use = function(self, event, target, player, data)
    data.to = Player.Play
  end,
}
olz__wuxian:addSkill(yirong)
olz__wuxian:addSkill(guixiang)
olz__wuxian:addSkill("muyin")
Fk:loadTranslationTable{
  ["olz__wuxian"] = "吴苋",
  ["yirong"] = "移荣",
  [":yirong"] = "出牌阶段限两次，你可以将手牌摸/弃至手牌上限并令你手牌上限-1/+1。",
  ["guixiang"] = "贵相",
  [":guixiang"] = "锁定技，你回合内第X个阶段改为出牌阶段（X为你的手牌上限）。",
}

--韩韶 韩融
--[[local hanshao = General(extension, "olz__hanshao", "qun", 3)
local xumin = fk.CreateActiveSkill{
  name = "xumin",
  anim_type = "support",
  card_num = 1,
  min_target_num = 1,
  max_target_num = 999,
  can_use = function(self, player)
    return not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local card = Fk:cloneCard("amazing_grace")
    card:addSubcards(effect.cards)
    card.skillName = self.name
    local tos = {}
    for _, id in ipairs(effect.tos) do
      table.insert(tos, {id})
    end
    room:useCard{
      from = effect.from,
      tos = tos,
      card = card,
    }
  end,
}
hanshao:addSkill(liuju)
hanshao:addSkill(xumin)]]--
Fk:loadTranslationTable{
  ["olz__hanshao"] = "韩韶",
  ["fangzhen"] = "放赈",
  [":fangzhen"] = "出牌阶段开始时，你可以横置一名角色并选择一项：1.摸两张牌并交给其两张牌；2.令其回复1点体力。第X轮开始时（X为其座次），你失去此技能。",
  ["liuju"] = "留驹",
  [":liuju"] = "出牌阶段结束时，你可以与一名角色拼点，输的角色可以使用拼点牌中的非基本牌。若你与其的相互距离因此变化，你复原〖恤民〗。",
  ["xumin"] = "恤民",
  [":xumin"] = "宗族技，限定技，你可以将一张牌当【五谷丰登】对任意名其他角色使用。",
}
Fk:loadTranslationTable{
  ["olz__hanrong"] = "韩融",
  ["lianhe"] = "连和",
  [":lianhe"] = "出牌阶段开始时，你可以横置两名角色，其下个出牌阶段结束时，若其此阶段未摸牌，其选择一项："..
  "1.令你摸X+1张牌；2.交给你X-1张牌（X为其此阶段获得牌数且至多为3）。",
  ["huanjia"] = "缓颊",
  [":huanjia"] = "出牌阶段结束时，你可以与一名角色拼点，赢的角色可以使用一张拼点牌，若其：未造成伤害，你获得另一张拼点牌；造成了伤害，你失去一个技能。",
}

local wukuang = General(extension, "olz__wukuang", "qun", 4)
local lianzhuw = fk.CreateActiveSkill{
  name = "lianzhuw",
  anim_type = "switch",
  switch_skill_name = "lianzhuw",
  card_num = function()
    if Self:getSwitchSkillState("lianzhuw", false) == fk.SwitchYang then
      return 1
    else
      return 0
    end
  end,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return #selected == 0
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:recastCard(effect.cards, player, self.name)
      local color = Fk:getCardById(effect.cards[1]):getColorString()
      local prompt = "#lianzhuw1-card:::"..color
      if color == "nocolor" then
        prompt = "#lianzhuw2-card"
      end
      local card = room:askForCard(player, 1, 1, true, self.name, true, ".", prompt)
      if #card > 0 then
        room:recastCard(card, player, self.name)
        if color ~= "nocolor" then
          local color2 = Fk:getCardById(card[1]):getColorString()
          if color2 ~= "nocolor" and color2 ~= color and player:getMaxCards() > 0 then
            room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
          end
        end
      end
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return player:inMyAttackRange(p) end), function (p) return p.id end)
      if #targets == 0 then return end
      local target = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhuw1-choose", self.name, false)
      if #target > 0 then
        target = room:getPlayerById(target[1])
      else
        target = room:getPlayerById(table.random(targets))
      end
      local use1 = room:askForUseCard(player, "slash", "slash", "#lianzhuw-slash::"..target.id, true, {must_targets = {target.id}})
      if use1 then
        room:useCard(use1)
        if not player.dead and not target.dead then
          local color = use1.card:getColorString()
          local prompt = "#lianzhuw1-slash::"..target.id..":"..color
          if color == "nocolor" then
            prompt = "#lianzhuw-slash::"..target.id
          end
          local use2 = room:askForUseCard(player, "slash", "slash", prompt, true, {must_targets = {target.id}})
          if use2 then
            room:useCard(use2)
            if color ~= "nocolor" then
              local color2 = use2.card:getColorString()
              if color2 ~= "nocolor" and color2 == color then
                room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
              end
            end
          end
        end
      end
    end
  end,
}
local lianzhuw_trigger = fk.CreateTriggerSkill{
  name = "#lianzhuw_trigger",

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return target == player and data == self
    else
      return target == player and player:hasSkill(self.name, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:handleAddLoseSkills(p, "lianzhuw&", nil, false, true)
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player, true, true)) do
        room:handleAddLoseSkills(p, "-lianzhuw&", nil, false, true)
      end
    end
  end,
}
local lianzhuw_active = fk.CreateActiveSkill{
  name = "lianzhuw&",
  mute = true,
  card_num = function()
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("lianzhuw") then
        if p:getSwitchSkillState("lianzhuw", false) == fk.SwitchYang then
          return 1
        else
          return 0
        end
      end
    end
    return 0
  end,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("lianzhuw", true) then
        if p:getSwitchSkillState("lianzhuw", false) == fk.SwitchYang then
          return #selected == 0
        else
          return false
        end
      end
    end
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local src
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:hasSkill("lianzhuw") then
        src = p
        break
      end
    end
    room:doIndicate(player.id, {src.id})
    room:setPlayerMark(src, MarkEnum.SwithSkillPreName .. "lianzhuw", src:getSwitchSkillState("lianzhuw", true))
    src:addSkillUseHistory("lianzhuw")
    room:broadcastSkillInvoke("lianzhuw")
    room:notifySkillInvoked(src, "lianzhuw", "switch")
    if src:getSwitchSkillState("lianzhuw", true) == fk.SwitchYang then
      room:recastCard(effect.cards, player, "lianzhuw")
      local color = Fk:getCardById(effect.cards[1]):getColorString()
      local prompt = "#lianzhuw1-card:::"..color
      if color == "nocolor" then
        prompt = "#lianzhuw2-card"
      end
      local card = room:askForCard(src, 1, 1, true, "lianzhuw", true, ".", prompt)
      if #card > 0 then
        room:recastCard(card, src, "lianzhuw")
        if color ~= "nocolor" then
          local color2 = Fk:getCardById(card[1]):getColorString()
          if color2 ~= "nocolor" and color2 ~= color and src:getMaxCards() > 0 then
            room:addPlayerMark(src, MarkEnum.MinusMaxCards, 1)
          end
        end
      end
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return (player:inMyAttackRange(p) or src:inMyAttackRange(p)) and p ~= src end), function (p) return p.id end)
      if #targets == 0 then return end
      local target = room:askForChoosePlayers(src, targets, 1, 1, "#lianzhuw2-choose:"..player.id, "lianzhuw", false)
      if #target > 0 then
        target = room:getPlayerById(target[1])
      else
        target = room:getPlayerById(table.random(targets))
      end
      local use1 = room:askForUseCard(player, "slash", "slash", "#lianzhuw-slash::"..target.id, true, {must_targets = {target.id}})
      if use1 then
        room:useCard(use1)
      end
      if not src.dead and not target.dead then
        local color = "nocolor"
        local prompt = "#lianzhuw-slash::"..target.id
        if use1 then
          color = use1.card:getColorString()
          prompt = "#lianzhuw1-slash::"..target.id..":"..color
          if color == "nocolor" then
            prompt = "#lianzhuw-slash::"..target.id
          end
        end
        local use2 = room:askForUseCard(src, "slash", "slash", prompt, true, {must_targets = {target.id}})
        if use2 then
          room:useCard(use2)
          if color ~= "nocolor" then
            local color2 = use2.card:getColorString()
            if color2 ~= "nocolor" and color2 == color then
              room:addPlayerMark(src, MarkEnum.AddMaxCards, 1)
            end
          end
        end
      end
    end
  end,
}
Fk:addSkill(lianzhuw_active)
lianzhuw:addRelatedSkill(lianzhuw_trigger)
wukuang:addSkill(lianzhuw)
wukuang:addSkill("muyin")
Fk:loadTranslationTable{
  ["olz__wukuang"] = "吴匡",
  ["lianzhuw"] = "联诛",
  [":lianzhuw"] = "转换技，每名角色出牌阶段限一次，阳：其可以与你各重铸一张牌，若颜色不同，你的手牌上限-1；"..
  "阴：你选择一名在你或其攻击范围内的角色，其可以与你各对目标使用一张【杀】，若颜色相同，你的手牌上限+1。",
  ["#lianzhuw1-card"] = "联诛：你可以重铸一张牌，若不为%arg，你手牌上限-1",
  ["#lianzhuw2-card"] = "联诛：你可以重铸一张牌",
  ["#lianzhuw1-choose"] = "联诛：选择一名你攻击范围内的角色",
  ["#lianzhuw2-choose"] = "联诛：选择一名你或 %src 攻击范围内的角色",
  ["#lianzhuw1-slash"] = "联诛：你可以对 %dest 使用一张【杀】，若为%arg，你手牌上限+1",
  ["#lianzhuw-slash"] = "联诛：你可以对 %dest 使用一张【杀】",
  ["lianzhuw&"] = "联诛",
  [":lianzhuw&"] = "出牌阶段限一次，若吴匡的〖联诛〗为：阳：你可以与其各重铸一张牌，若颜色不同，其手牌上限-1；"..
  "阴：其选择一名在你或其攻击范围内的角色，你可以与吴匡各对目标使用一张【杀】，若颜色相同，其手牌上限+1。",
}

--local wangyun = General(extension, "olz__wangyun", "qun", 3)
Fk:loadTranslationTable{
  ["olz__wangyun"] = "王允",
  ["jiexuan"] = "解悬",
  [":jiexuan"] = "",
  ["mingjie"] = "铭戒",
  [":mingjie"] = "",
}

local wangling = General(extension, "olz__wangling", "wei", 4)
local bolong = fk.CreateActiveSkill{
  name = "bolong",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 and to_select ~= Self.id then
      return not Self:isNude() or (not Self:isKongcheng() and
        #Fk:currentRoom():getPlayerById(to_select):getCardIds{Player.Hand, Player.Equip} >= Self:getHandcardNum())
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = player:getHandcardNum()
    if #target:getCardIds{Player.Hand, Player.Equip} >= n and n > 0 then
      local cards = room:askForCard(target, n, n, true, self.name, true, ".", "#bolong-card:"..player.id.."::"..n)
      if #cards == n then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        room:obtainCard(player.id, dummy, false, fk.ReasonGive)
        room:useVirtualCard("analeptic", nil, target, player, self.name)
        return
      end
    end
    local card = room:askForCard(player, 1, 1, true, self.name, false, ".", "#bolong-slash::"..target.id)
    room:obtainCard(target.id, card[1], false, fk.ReasonGive)
    room:useVirtualCard("thunder__slash", nil, player, target, self.name, true)
  end,
}
local zhongliu = fk.CreateTriggerSkill{
  name = "zhongliu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.BeforeCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.CardUsing then
        return target == player and data.card:isVirtual()
      else
        if player.room.logic:getCurrentEvent().parent.event == GameEvent.UseCard then
          local use = player.room.logic:getCurrentEvent().parent
          if not use or use.data[1].from ~= player.id then return end
          for _, move in ipairs(data) do
            if move.from and move.toArea == Card.Processing then
              local p = player.room:getPlayerById(move.from)
              if string.find(p.general, "olz__wang") or string.find(p.general, "wangyun") or
                string.find(p.general, "wangling") or string.find(p.general, "wangchang") then
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.PlayerHand then
                    return false
                  end
                end
              end
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, s in ipairs(Fk.generals[player.general].skills) do
      player:setSkillUseHistory(s.name, 0, Player.HistoryPhase)  --先用着看看，说不定还有重置限定技的
    end
  end,
}
wangling:addSkill(bolong)
wangling:addSkill(zhongliu)
Fk:loadTranslationTable{
  ["olz__wangling"] = "王淩",
  ["bolong"] = "驳龙",
  [":bolong"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.你交给其一张牌，视为对其使用一张雷【杀】；"..
  "2.交给你与你手牌数等量张牌，视为对你使用一张【酒】。",
  ["zhongliu"] = "中流",
  [":zhongliu"] = "宗族技，锁定技，当你使用牌时，若不为同族角色的手牌，你视为未发动武将牌上的技能。",
  ["#bolong-card"] = "驳龙：交给 %src %arg张牌视为对其使用【酒】，否则其交给你一张牌视为对你使用雷【杀】",
  ["#bolong-slash"] = "驳龙：交给 %dest 一张牌，视为对其使用雷【杀】",
}
return extension
