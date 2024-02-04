local extension = Package("ol_menfa")
extension.extensionName = "ol"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_menfa"] = "OL-门阀士族",
  ["olz"] = "宗族",
}

--- 判断一名角色是否为某族成员
---@param player Player
local isFamilyMember = function (player, famaly)
  local familyMap = {
    ["xun"] = {"olz__xun", "xunchen", "xunyu", "xunyou"},
    ["wu"] = {"olz__wu", "wuyi", "wuxian", "wuban"},
    ["han"] = {"olz__han", "hanshao", "hanrong"},
    ["wang"] = {"olz__wangyun", "wangyun", "wangling", "wangchang", "wanghun"},
    ["zhong"] = {"olz__zhong", "zhongyao", "zhongyu", "zhonghui", "zhongyan"},
  }
  local names = familyMap[famaly] or {}
  return table.find(names, function(name)
    return string.find(player.general, name) or string.find(player.deputyGeneral, name)
  end)
end

local olz__xunchen = General(extension, "olz__xunchen", "qun", 3)
local sankuang = fk.CreateTriggerSkill{
  name = "sankuang",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    local card_type = data.card.type
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark_name = "sankuang_" .. data.card:getTypeString() .. "-round"
    local mark = player:getMark(mark_name)
    if mark == 0 then
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local last_use = e.data[1]
        if last_use.from == player.id and last_use.card.type == card_type then
          mark = e.id
          room:setPlayerMark(player, mark_name, mark)
          return true
        end
        return false
      end, Player.HistoryRound)
    end
    return mark == use_event.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if p ~= player then
        table.insert(targets, p.id)
        local n = 0
        if #p:getCardIds{Player.Equip, Player.Judge} > 0 then n = n + 1 end
        if p:isWounded() then n = n + 1 end
        if p.hp < #p.player_cards[Player.Hand] then n = n + 1 end
        room:setPlayerMark(p, "@sankuang", {n})  --FIXME: 用来显示三恇张数
      end
    end
    if #targets == 0 then return end
    targets = room:askForChoosePlayers(player, targets, 1, 1, "#sankuang-choose:::"..data.card:toLogString(), self.name, false)
    local to = room:getPlayerById(targets[1])
    if player:getMark("beishi") == 0 then
      room:setPlayerMark(player, "beishi", targets[1])
      room:setPlayerMark(to, "@@beishi", 1)
    end
    local n = to:getMark("@sankuang")[1]
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@sankuang", 0)
    end
    local all_cards = to:getCardIds{Player.Hand, Player.Equip}
    if #all_cards == 0 then return false end
    local cards = {}
    if n == 0 then
      cards = room:askForCard(to, 1, #all_cards, true, self.name, true, ".", "#sankuang-give0:"..player.id.."::"..data.card:toLogString())
    elseif n >= #all_cards then
      cards = all_cards
    else
      cards = room:askForCard(to, n, #all_cards, true, self.name, false, ".", "#sankuang-give:"..player.id.."::"..n)
    end
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, self.name, nil, false, targets[1])
      if to.dead then return false end
      local card_ids = Card:getIdList(data.card)
      if #card_ids == 0 then return false end
      if data.card.type == Card.TypeEquip then
        if not table.every(card_ids, function (id)
          return room:getCardArea(id) == Card.PlayerEquip and room:getCardOwner(id) == player
        end) then return false end
      else
        if not table.every(card_ids, function (id)
          return room:getCardArea(id) == Card.Processing
        end) then return false end
      end
      room:moveCardTo(card_ids, Player.Hand, to, fk.ReasonPrey, self.name, nil, false, targets[1])
    end
  end,
}
local beishi = fk.CreateTriggerSkill{
  name = "beishi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:isWounded() then
      local beishi_id = player:getMark("beishi")
      if beishi_id == 0 then return false end
      local beishi_target = player.room:getPlayerById(beishi_id)
      if beishi_target == nil or beishi_target.dead or not beishi_target:isKongcheng() then return false end
      for _, move in ipairs(data) do
        if move.from == beishi_id then
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
    if player ~= target or not player:hasSkill(self) then return false end
    if not data.card:isCommonTrick() or data.card.is_damage_card then return false end
    local room = player.room
    local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
    if #cardlist == 0 or not table.every(cardlist, function (id)
      return room:getCardArea(id) == Card.Processing
    end) then return false end
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark_name = "daojie_record-turn"
    local mark = player:getMark(mark_name)
    if mark == 0 then
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local last_use = e.data[1]
        if last_use.from == player.id and last_use.card:isCommonTrick() and not last_use.card.is_damage_card then
          mark = e.id
          room:setPlayerMark(player, mark_name, mark)
          return true
        end
        return false
      end, Player.HistoryTurn)
    end
    return mark == use_event.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    for _, skill in ipairs(player.player_skills) do
      if skill.frequency == Skill.Compulsory and not (skill:isEquipmentSkill() or skill.name:endsWith("&")) then
        table.insert(skills, skill.name)
      end
    end
    table.insert(skills, "loseHp")
    local choice = room:askForChoice(player, skills, self.name, "#daojie-choice", true)
    if choice == "loseHp" then
      room:loseHp(player, 1, self.name)
    else
      room:handleAddLoseSkills(player, "-"..choice, nil, true, false)
    end
    if not player.dead and table.every(Card:getIdList(data.card), function (id)
      return room:getCardArea(id) == Card.Processing
    end) then
      local targets = {}
      for _, p in ipairs(room.alive_players) do
        if isFamilyMember(p, "xun") or player == p then
          table.insert(targets, p.id)
        end
      end
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#daojie-choose:::"..data.card:toLogString(), self.name, false)
        room:obtainCard(to[1], data.card, true, fk.ReasonPrey)
      end
    end
  end,
}
olz__xunchen:addSkill(sankuang)
olz__xunchen:addSkill(beishi)
olz__xunchen:addSkill(daojie)
Fk:loadTranslationTable{
  ["olz__xunchen"] = "族荀谌",
  ["#olz__xunchen"] = "挈怯恇恇",
  ["illustrator:olz__xunchen"] = "凡果",
  ["sankuang"] = "三恇",
  [":sankuang"] = "锁定技，当你每轮首次使用一种类别的牌后，你令一名其他角色交给你至少X张牌并获得你使用的牌（X为其满足的项数：1.场上有牌；2.已受伤；"..
  "3.体力值小于手牌数）。",
  ["beishi"] = "卑势",
  [":beishi"] = "锁定技，当你首次发动〖三恇〗选择的角色失去最后的手牌后，你回复1点体力。",
  ["daojie"] = "蹈节",
  [":daojie"] = "宗族技，锁定技，当你每回合首次使用非伤害类普通锦囊牌后，你选择一项：1.失去1点体力；2.失去一个锁定技。然后令一名同族角色获得此牌。",
  ["#sankuang-choose"] = "三恇：令一名其他角色交给你至少X张牌并获得你使用的%arg",
  ["@sankuang"] = "三恇张数：",
  ["#sankuang-give0"] = "三恇：可选择任意张牌交给 %src，然后获得其使用的 %arg",
  ["#sankuang-give"] = "三恇：你须选择至少 %arg 张牌交给 %src",
  ["@@beishi"] = "卑势",
  ["#daojie-choice"] = "蹈节：选择失去一个锁定技，或失去1点体力",
  ["#daojie-choose"] = "蹈节：令一名同族角色获得此%arg",
  ["daojie_cancel"] = "取消",
  [":daojie_cancel"] = "失去1点体力",

  ["$sankuang1"] = "人言可畏，宜常辟之。",
  ["$sankuang2"] = "天地可敬，可常惧之。",
  ["$beishi1"] = "虎卑其势，将有所逮。",
  ["$beishi2"] = "至山穷水尽，复柳暗花明。",
  ["$daojie_olz__xunchen1"] = "此生所重者，慷慨之节也。",
  ["$daojie_olz__xunchen2"] = "愿以此身，全清尚之节。",
  ["~olz__xunchen"] = "行二臣之为，羞见列祖……",
}

local xunshu = General(extension, "olz__xunshu", "qun", 3)
local shenjun_viewas = fk.CreateViewAsSkill{
  name = "shenjun_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Self:getMark("@$shenjun")) do
      local name = Fk:getCardById(id, true).name
      if Self:canUse(Fk:cloneCard(name)) then
        table.insertIfNeed(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected < #Self:getMark("@$shenjun")
  end,
  view_as = function(self, cards)
    if Self:getMark("@$shenjun") ~= 0 and #cards ~= #Self:getMark("@$shenjun") or not self.interaction.data then return end
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
    if player:hasSkill(self) then
      if event == fk.CardUsing then
        return (data.card.trueName == "slash" or data.card:isCommonTrick()) and not player:isKongcheng() and
          table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end)
      else
        return player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and type(player:getMark("@$shenjun")) == "table"
        and #player:getMark("@$shenjun") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return true
    else
      local room = player.room
      room:setPlayerMark(player, MarkEnum.BypassTimesLimit.."-tmp", 1)
      local success, dat = room:askForUseActiveSkill(player, "shenjun_viewas",
      "#shenjun-invoke:::"..#player:getMark("@$shenjun"), true)
      room:setPlayerMark(player, MarkEnum.BypassTimesLimit.."-tmp", 0)
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
      local mark = player:getMark("@$shenjun")
      if mark == 0 then mark = {} end
      for _, id in ipairs(cards) do
        if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player and not table.contains(mark, id) then
          table.insert(mark, id)
          room:setCardMark(Fk:getCardById(id), "@@shenjun-inhand", 1)
        end
      end
      room:setPlayerMark(player, "@$shenjun", mark)
    else
      local dat = table.simpleClone(self.cost_data)
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcards(dat.cards)
      card.skillName = "shenjun"
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return type(player:getMark("@$shenjun")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local handcards = player:getCardIds(Player.Hand)
    local cards = table.filter(player:getMark("@$shenjun"), function (id)
      return table.contains(handcards, id)
    end)
    player.room:setPlayerMark(player, "@$shenjun", #cards > 0 and cards or 0)
  end,
}
local balong = fk.CreateTriggerSkill{
  name = "balong",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.HpLost, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and not player:isKongcheng() then
      local x = player:getMark("balong_record-turn")
      local room = player.room
      local hp_event = room.logic:getCurrentEvent()
      if not hp_event or (x > 0 and x ~= hp_event.id) then return false end
      local types = {Card.TypeBasic, Card.TypeEquip, Card.TypeTrick}
      local num = {0, 0, 0}
      for i = 1, 3, 1 do
        num[i] = #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type == types[i] end)
      end
      if num[3] <= num[1] or num[3] <= num[2] then return false end
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          if e.data[1] == player then
            local reason = e.data[3]
            local game_event = nil
            if reason == "damage" then
              game_event = GameEvent.Damage
            elseif reason == "loseHp" then
              game_event = GameEvent.LoseHp
            elseif reason == "recover" then
              game_event = GameEvent.Recover
            else
              return true
            end
            local first_event = e:findParent(game_event)
            if first_event then
              x = first_event.id
              room:setPlayerMark(player, "balong_record-round", x)
            end
            return true
          end
        end, Player.HistoryTurn)
      end
      return hp_event.id == x
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
  ["olz__xunshu"] = "族荀淑",
  ["#olz__xunshu"] = "长儒赡宗",
  ["illustrator:olz__xunshu"] = "凡果",
  ["shenjun"] = "神君",
  [":shenjun"] = "当一名角色使用【杀】或普通锦囊牌时，你展示所有同名手牌记为“神君”，本阶段结束时，你可以将X张牌当任意“神君”牌使用（X为“神君”牌数）。",
  ["balong"] = "八龙",
  [":balong"] = "锁定技，当你每回合体力值首次变化后，若你手牌中锦囊牌为唯一最多的类型，你展示手牌并摸至与存活角色数相同。",

  ["@$shenjun"] = "神君",
  ["@@shenjun-inhand"] = "神君",
  ["#shenjun-invoke"] = "神君：你可以将%arg张牌当一种“神君”牌使用",
  ["shenjun_viewas"] = "神君",

  ["$shenjun1"] = "区区障眼之法，难遮神人之目。",
  ["$shenjun2"] = "我以天地为师，自可道法自然。",
  ["$balong1"] = "八龙之蜿蜿，云旗之委蛇。",
  ["$balong2"] = "穆王乘八牡，天地恣遨游。",
  ["$daojie_olz__xunshu1"] = "荀人如玉，向节而生。",
  ["$daojie_olz__xunshu2"] = "竹有其节，焚之不改。",
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
    if player:hasSkill(self) and not target.dead and data.damageType ~= fk.NormalDamage then
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
    if player:getMark("fenchai") == 0 and player:compareGenderWith(target, true) then
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
  card_filter = function(self, to_select, player, isJudgeEvent)
    return player:hasSkill(self) and player:getMark(self.name) ~= 0 and isJudgeEvent
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
  ["olz__xuncan"] = "族荀粲",
  ["#olz__xuncan"] = "分钗断带",
  ["illustrator:olz__xuncan"] = "凡果",
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
  ["$daojie_olz__xuncan1"] = "君子持节，何移情乎？",
  ["$daojie_olz__xuncan2"] = "我心慕鸳，从一而终。",
  ["~olz__xuncan"] = "此钗，今日可合乎？",
}

local xuncai = General(extension, "olz__xuncai", "qun", 3, 3, General.Female)
local lieshi = fk.CreateActiveSkill{
  name = "lieshi",
  anim_type = "offensive",
  prompt = "#lieshi-active",
  interaction = function(self)
    local choiceList = {}
    if not table.contains(Self.sealedSlots, Player.JudgeSlot) then
      table.insert(choiceList, "lieshi_prohibit")
    end
    local handcards = Self:getCardIds(Player.Hand)
    if not table.every(handcards, function (id)
      local card = Fk:getCardById(id)
      return card.trueName ~= "slash" or Self:prohibitDiscard(card)
    end) then
      table.insert(choiceList, "lieshi_slash")
    end
    if not table.every(handcards, function (id)
      local card = Fk:getCardById(id)
      return card.trueName ~= "jink" or Self:prohibitDiscard(card)
    end) then
      table.insert(choiceList, "lieshi_jink")
    end
    return UI.ComboBox { choices = choiceList  , all_choices = {"lieshi_prohibit", "lieshi_slash", "lieshi_jink"} }
  end,
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return not table.contains(player.sealedSlots, Player.JudgeSlot) or not table.every(player:getCardIds(Player.Hand), function (id)
      local card = Fk:getCardById(id)
      return (card.trueName ~= "slash" and card.trueName ~= "jink") or player:prohibitDiscard(card)
    end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local choice = self.interaction.data
    local to = player
    for i = 1, 2, 1 do
      if i == 2 then
        if player.dead then return false end
        local targets = {}
        for _, p in ipairs(room.alive_players) do
          if p ~= player then
            table.insert(targets, p.id)
          end
        end
        if #targets == 0 then return false end
        to = room:getPlayerById(room:askForChoosePlayers(player, targets, 1, 1, "#lieshi-choose", self.name, false)[1])
        local choiceList, all_choices = {}, {"lieshi_prohibit", "lieshi_slash", "lieshi_jink"}
        if not table.contains(to.sealedSlots, Player.JudgeSlot) then
          table.insert(choiceList, "lieshi_prohibit")
        end
        local handcards = to:getCardIds(Player.Hand)
        if not table.every(handcards, function (id)
          local card = Fk:getCardById(id)
          return card.trueName ~= "slash" or to:prohibitDiscard(card)
        end) then
          table.insert(choiceList, "lieshi_slash")
        end
        if not table.every(handcards, function (id)
          local card = Fk:getCardById(id)
          return card.trueName ~= "jink" or to:prohibitDiscard(card)
        end) then
          table.insert(choiceList, "lieshi_jink")
        end
        table.removeOne(choiceList, choice)
        if #choiceList == 0 then return false end
        choice = room:askForChoice(to, choiceList, self.name, "#lieshi-choice:" .. player.id, false, all_choices)
      end
      if choice == "lieshi_prohibit" then
        room:abortPlayerArea(to, {Player.JudgeSlot})
        if not to.dead then
          room:damage{
            from = player,
            to = to,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = self.name,
          }
        end
      elseif choice == "lieshi_slash" then
        local cards = table.filter(to:getCardIds(Player.Hand), function (id)
          local card = Fk:getCardById(id)
          return card.trueName == "slash" and not to:prohibitDiscard(card)
        end)
        if #cards > 0 then
          room:throwCard(cards, self.name, to)
        end
      elseif choice == "lieshi_jink" then
        local cards = table.filter(to:getCardIds(Player.Hand), function (id)
          local card = Fk:getCardById(id)
          return card.trueName == "jink" and not to:prohibitDiscard(card)
        end)
        if #cards > 0 then
          room:throwCard(cards, self.name, to)
        end
      end
    end
  end,
}
local dianzhan = fk.CreateTriggerSkill{
  name = "dianzhan",
  events = {fk.CardUseFinished},
  frequency = Skill.Compulsory,
  anim_type = "drawCard",
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return false end
    local suit = data.card.suit
    if suit == Card.NoSuit then return false end
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark_name = "dianzhan_" .. data.card:getSuitString() .. "-round"
    local mark = player:getMark(mark_name)
    if mark == 0 then
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local last_use = e.data[1]
        if last_use.from == player.id and last_use.card.suit == suit then
          mark = e.id
          room:setPlayerMark(player, mark_name, mark)
          return true
        end
        return false
      end, Player.HistoryRound)
    end
    return mark == use_event.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dianzhan1, dianzhan2 = false, false
    local tos =TargetGroup:getRealTargets(data.tos)
    if #tos == 1 then
      local to = room:getPlayerById(tos[1])
      if not to.dead and not to.chained then
        dianzhan1 = true
        to:setChainState(true)
      end
    end
    if player.dead then return false end
    local cards = table.filter(player:getCardIds(Player.Hand), function (id)
      return Fk:getCardById(id).suit == data.card.suit
    end)
    if #cards > 0 then
      dianzhan2 = true
      room:recastCard(cards, player, self.name)
    end
    if dianzhan1 and dianzhan2 and not player.dead then
      room:drawCards(player, 1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player == target and player:hasSkill(self.name, true) and data.card.suit ~= Card.NoSuit
    elseif event == fk.EventLoseSkill then
      return target == player and data == self and player:getMark("@dianzhan_suit-round") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      local suitRecorded = U.getMark(player, "@dianzhan_suit-round")
      if not table.contains(suitRecorded, data.card:getSuitString(true)) then
        table.insert(suitRecorded, data.card:getSuitString(true))
        player.room:setPlayerMark(player, "@dianzhan_suit-round", suitRecorded)
      end
    elseif event == fk.EventLoseSkill then
      player.room:setPlayerMark(player, "@dianzhan_suit-round", 0)
    end
  end,
}
local huanyin = fk.CreateTriggerSkill{
  name = "huanyin",
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and player:getHandcardNum() < 4
  end,
  on_use = function(self, event, target, player, data)
    local x = 4 - player:getHandcardNum()
    if x > 0 then
      player:drawCards(x, self.name)
    end
  end,
}
xuncai:addSkill(lieshi)
xuncai:addSkill(dianzhan)
xuncai:addSkill(huanyin)
xuncai:addSkill("daojie")
Fk:loadTranslationTable{
  ["olz__xuncai"] = "族荀采",
  ["#olz__xuncai"] = "怀刃自誓",
  ["illustrator:olz__xuncai"] = "凡果",
  ["lieshi"] = "烈誓",
  [":lieshi"] = "出牌阶段，你可以选择一项：1.废除判定区并受到你的1点火焰伤害；2.弃置所有【闪】；3.弃置所有【杀】。然后令一名其他角色选择其他两项中的一项。",
  ["dianzhan"] = "点盏",
  [":dianzhan"] = "锁定技，当你每轮首次使用一种花色的牌后，你横置此牌唯一目标并重铸此花色的所有手牌，然后若你以此法横置了角色且你以此法重铸了牌，你摸一张牌。",
  ["huanyin"] = "还阴",
  [":huanyin"] = "锁定技，当你进入濒死状态时，你将手牌摸至四张。",

  ["#lieshi-active"] = "发动烈誓，选择你要执行的效果",
  ["#lieshi-choose"] = "烈誓：选择一名其他角色，令其选择执行与你不同的效果",
  ["#lieshi-choice"] = "烈誓：选择：废除判定区并受到%src造成的1点火焰伤害，或弃置手牌区中所有的【杀】或【闪】",
  ["lieshi_prohibit"] = "废除判定区并受到1点火焰伤害",
  ["lieshi_slash"] = "弃置手牌区中所有的【杀】",
  ["lieshi_jink"] = "弃置手牌区中所有的【闪】",
  ["@dianzhan_suit-round"] = "点盏",

  ["$lieshi1"] = "拭刃为誓，女无二夫。",
  ["$lieshi2"] = "霜刃证言，宁死不贰。",
  ["$dianzhan1"] = "此灯如我，独向光明。",
  ["$dianzhan2"] = "此间皆暗，唯灯瞩明。",
  ["$huanyin1"] = "且将此身，还于阴氏。",
  ["$huanyin2"] = "生不得同户，死可葬同穴乎？",
  ["$daojie_olz__xuncai1"] = "女子有节，宁死蹈之。",
  ["$daojie_olz__xuncai2"] = "荀氏三纲，死不贰嫁。",
  ["~olz__xuncai"] = "苦难已过，世间大好……",
}

local olz__wuban = General(extension, "olz__wuban", "shu", 4)
local zhanding = fk.CreateViewAsSkill{
  name = "zhanding",
  pattern = "slash",
  card_filter = Util.TrueFunc,
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
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "zhanding")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if data.damageDealt then
      local n = player:getHandcardNum() - player:getMaxCards()
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
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      local tos = {}
      local max_num = player:getMaxCards()
      for _, p in ipairs(player.room.alive_players) do
        max_num = math.max(max_num, p:getMaxCards())
      end
      return table.find(player.room.alive_players, function(p)
        return (isFamilyMember(p, "wu") or player == p) and p:getMaxCards() < max_num
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local max_num = player:getMaxCards()
    for _, p in ipairs(player.room.alive_players) do
      max_num = math.max(max_num, p:getMaxCards())
    end
    for _, p in ipairs(player.room.alive_players) do
      if (isFamilyMember(p, "wu") or player == p) and p:getMaxCards() < max_num then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#muyin-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), MarkEnum.AddMaxCards, 1)
    player.room:broadcastProperty(player, "MaxCards")
  end,
}
zhanding:addRelatedSkill(zhanding_record)
olz__wuban:addSkill(zhanding)
olz__wuban:addSkill(muyin)
Fk:loadTranslationTable{
  ["olz__wuban"] = "族吴班",
  ["#olz__wuban"] = "豪侠督进",
  ["illustrator:olz__wuban"] = "匠人绘",
  ["zhanding"] = "斩钉",
  [":zhanding"] = "你可以将任意张牌当【杀】使用并令你手牌上限-1，若此【杀】：造成伤害，你将手牌数调整至手牌上限；未造成伤害，此【杀】不计入次数。",
  ["muyin"] = "穆荫",
  [":muyin"] = "宗族技，准备阶段，你可以令一名手牌上限不为全场最大的同族角色手牌上限+1。",
  ["#muyin-choose"] = "穆荫：你可以令一名同族角色手牌上限+1",

  ["$zhanding1"] = "汝颈硬，比之金铁何如？",
  ["$zhanding2"] = "魍魉鼠辈，速速系颈伏首！",
  ["$muyin_olz__wuban1"] = "世代佐忠义，子孙何绝焉？",
  ["$muyin_olz__wuban2"] = "祖训秉心，其荫何能薄也？",
  ["~olz__wuban"] = "无胆鼠辈，安敢暗箭伤人……",
}

local olz__wuxian = General(extension, "olz__wuxian", "shu", 3, 3, General.Female)
local yirong = fk.CreateActiveSkill{
  name = "yirong",
  anim_type = "drawcard",
  target_num = 0,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2 and player:getHandcardNum() ~= player:getMaxCards()
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player:getHandcardNum() - player:getMaxCards()
    if n < 0 then
      player:drawCards(-n, self.name)
      if player:getMaxCards() > 0 then
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      end
    elseif n > 0 then
      room:askForDiscard(player, n, n, false, self.name, false)
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    end
    room:broadcastProperty(player, "MaxCards")
  end,
}
local guixiang = fk.CreateTriggerSkill{
  name = "guixiang",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.to > Player.RoundStart and data.to < Player.NotActive then
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
  ["olz__wuxian"] = "族吴苋",
  ["#olz__wuxian"] = "庄姝晏晏",
  ["illustrator:olz__wuxian"] = "君桓文化",
  ["yirong"] = "移荣",
  [":yirong"] = "出牌阶段限两次，你可以将手牌摸/弃至手牌上限并令你手牌上限-1/+1。",
  ["guixiang"] = "贵相",
  [":guixiang"] = "锁定技，你回合内第X个阶段改为出牌阶段（X为你的手牌上限）。",

  ["$yirong1"] = "花开彼岸，繁荣不减当年。",
  ["$yirong2"] = "移花接木，花容更胜从前。",
  ["$guixiang1"] = "女相显贵，凤仪从龙。",
  ["$guixiang2"] = "正官七杀，天生富贵。",
  ["$muyin_olz__wuxian1"] = "吴门隆盛，闻钟而鼎食。",
  ["$muyin_olz__wuxian2"] = "吴氏一族，感明君青睐。",
  ["~olz__wuxian"] = "玄德东征，何日归还？",
}

local hanshao = General(extension, "olz__hanshao", "qun", 3)
local fangzhen = fk.CreateTriggerSkill{
  name = "fangzhen",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self) and player.phase == Player.Play and
        not table.every(player.room.alive_players, function(p) return p.chained end)
    else
      return player:hasSkill(self.name, true) and player:getMark(self.name) ~= 0 and
        table.contains(player:getMark(self.name), player.room:getTag("RoundCount"))
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
        return not p.chained end), Util.IdMapper), 1, 1, "#fangzhen-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:getPlayerById(self.cost_data)
      to:setChainState(true)
      if to.dead or player.dead then return end
      local nums = player:getMark(self.name)
      if nums == 0 then nums = {} end
      table.insertIfNeed(nums, to.seat)
      room:setPlayerMark(player, self.name, nums)
      local choices = {"fangzhen1"}
      if to:isWounded() then
        table.insert(choices, "fangzhen2")
      end
      local choice = room:askForChoice(player, choices, self.name, "#fangzhen-choice::"..to.id)
      if choice == "fangzhen1" then
        player:drawCards(2, self.name)
        if to == player or player:isNude() then return end
        local cards
        if #player:getCardIds("he") <= 2 then
          cards = player:getCardIds("he")
        else
          cards = room:askForCard(player, 2, 2, true, self.name, false, ".", "#fangzhen-give::"..to.id)
        end
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        room:obtainCard(to.id, dummy, false, fk.ReasonGive)
      else
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    else
      room:handleAddLoseSkills(player, "-fangzhen", nil, true, false)
    end
  end,
}
local liuju = fk.CreateTriggerSkill{
  name = "liuju",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:canPindian(p) end), Util.IdMapper), 1, 1, "#liuju-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local pindian = player:pindian({to}, self.name)
    local loser = nil
    if pindian.results[to.id].winner == player then
      loser = to
    elseif pindian.results[to.id].winner == to then
      loser = player
    end
    if not loser or loser.dead then return end
    local n1, n2 = player:distanceTo(to), to:distanceTo(player)
    local ids = {}
    for _, card in ipairs({pindian.fromCard, pindian.results[to.id].toCard}) do
      if card.type ~= Card.TypeBasic and room:getCardArea(card) == Card.DiscardPile and
        not loser:prohibitUse(card) and loser:canUse(card) then
        table.insertIfNeed(ids, card:getEffectiveId())
      end
    end
    if #ids == 0 then return end
    local fakemove = {
      toArea = Card.PlayerHand,
      to = loser.id,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({loser}, {fakemove})
    room:setPlayerMark(loser, "liuju_cards", ids)
    local success, dat = room:askForUseActiveSkill(loser, "liuju_viewas", "#liuju-use", true)
    room:setPlayerMark(loser, "liuju_cards", 0)
    fakemove = {
      from = loser.id,
      toArea = Card.Void,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({loser}, {fakemove})
    if success then
      local card = Fk.skills["liuju_viewas"]:viewAs(dat.cards)
      room:useCard{
        from = loser.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
      }
      if player:usedSkillTimes("xumin", Player.HistoryGame) > 0 and not player.dead and not to.dead and
        (player:distanceTo(to) ~= n1 or to:distanceTo(player) ~= n2) then
        player:setSkillUseHistory("xumin", 0, Player.HistoryGame)
      end
    end
  end,
}
local liuju_viewas = fk.CreateViewAsSkill{
  name = "liuju_viewas",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("liuju_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
local xumin = fk.CreateActiveSkill{
  name = "xumin",
  anim_type = "support",
  frequency = Skill.Limited,
  card_num = 1,
  min_target_num = 1,
  prompt = "#xumin",
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
    room:useCard{
      from = effect.from,
      tos = table.map(effect.tos, function(id) return {id} end),
      card = card,
    }
  end,
}
Fk:addSkill(liuju_viewas)
hanshao:addSkill(fangzhen)
hanshao:addSkill(liuju)
hanshao:addSkill(xumin)
Fk:loadTranslationTable{
  ["olz__hanshao"] = "族韩韶",
  ["#olz__hanshao"] = "分投急所",
  ["illustrator:olz__hanshao"] = "鬼画府",
  ["fangzhen"] = "放赈",
  [":fangzhen"] = "出牌阶段开始时，你可以横置一名角色并选择一项：1.摸两张牌并交给其两张牌；2.令其回复1点体力。第X轮开始时（X为其座次），你失去此技能。",
  ["liuju"] = "留驹",
  [":liuju"] = "出牌阶段结束时，你可以与一名角色拼点，输的角色可以使用拼点牌中的非基本牌。若你与其的相互距离因此变化，你复原〖恤民〗。",
  ["xumin"] = "恤民",
  [":xumin"] = "宗族技，限定技，你可以将一张牌当【五谷丰登】对任意名其他角色使用。",
  ["#fangzhen-choose"] = "放赈：你可以横置一名角色，摸两张牌交给其或令其回复体力",
  ["fangzhen1"] = "摸两张牌并交给其两张牌",
  ["fangzhen2"] = "令其回复1点体力",
  ["#fangzhen-choice"] = "放赈：选择对 %dest 执行的一项",
  ["#fangzhen-give"] = "放赈：选择两张牌交给 %dest",
  ["#liuju-choose"] = "留驹：你可以拼点，输的角色可以使用其中的非基本牌",
  ["#liuju-use"] = "留驹：你可以使用其中的非基本牌",
  ["liuju_viewas"] = "留驹",
  ["#xumin"] = "恤民：你可以将一张牌当【五谷丰登】对任意名其他角色使用",

  ["$fangzhen1"] = "百姓罹灾，当施粮以赈。",
  ["$fangzhen2"] = "开仓放粮，以赈灾民。",
  ["$liuju1"] = "当逐千里之驹，情深可留嬴城。",
  ["$liuju2"] = "乡老十里相送，此驹可彰吾情。",
  ["$xumin_olz__hanshao1"] = "民者，居野而多艰，不可不恤。",
  ["$xumin_olz__hanshao2"] = "天下之本，上为君，下为民。",
  ["~olz__hanshao"] = "天地不仁，万物何辜……",
}

local hanrong = General(extension, "olz__hanrong", "qun", 3)
local lianhe = fk.CreateTriggerSkill{
  name = "lianhe",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      #table.filter(player.room.alive_players, function(p) return not p.chained end) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
      return not p.chained end), Util.IdMapper), 2, 2, "#lianhe-choose", self.name, true)
    if #tos == 2 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      p:setChainState(true)
      local mark = p:getMark("@@lianhe")
      if mark == 0 then mark = {} end
      if p == player and not table.contains(mark, player.id) then
        room:setPlayerMark(player, "lianhe-phase", 1)
      end
      table.insertIfNeed(mark, player.id)
      room:setPlayerMark(p, "@@lianhe", mark)
    end
  end,
}
local lianhe_trigger = fk.CreateTriggerSkill{
  name = "#lianhe_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("@@lianhe") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = {}
    for _, id in ipairs(player:getMark("@@lianhe")) do
      local p = room:getPlayerById(id)
      if not p.dead then
        table.insert(src, p)
      end
    end
    if player:getMark("lianhe-phase") > 0 then
      room:setPlayerMark(player, "@@lianhe", {player.id})
      if #src == 1 then return end
    else
      room:setPlayerMark(player, "@@lianhe", 0)
    end
    if #src == 0 then return end
    local n = 0
    local events = room.logic:getEventsOfScope(GameEvent.MoveCards, 3, function(e)
      for _, move in ipairs(e.data) do
        if move.to == player.id and move.toArea == Player.Hand then
          if move.moveReason == fk.ReasonDraw then
            return true
          else
            n = n + #move.moveInfo
          end
        end
      end
    end, Player.HistoryPhase)
    if #events > 0 then return end
    n = math.min(n, 3)
    for _, p in ipairs(src) do
      if player.dead then return end
      if not p.dead then
        room:doIndicate(p.id, {player.id})
        player:broadcastSkillInvoke("lianhe")
        room:notifySkillInvoked(p, "lianhe", "drawcard")
        if n < 2 or #player:getCardIds("he") < n - 1 then
          p:drawCards(n + 1, "lianhe")
        else
          local cards = room:askForCard(player, n - 1, n - 1, true, "lianhe", true, ".",
            "#lianhe-card:"..p.id.."::"..tostring(n - 1)..":"..tostring(n + 1))
          if #cards == n - 1 then
            local dummy = Fk:cloneCard("dilu")
            dummy:addSubcards(cards)
            room:obtainCard(p, dummy, false, fk.ReasonGive)
          else
            p:drawCards(n + 1, "lianhe")
          end
        end
      end
    end
  end,
}
local huanjia = fk.CreateTriggerSkill{
  name = "huanjia",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:canPindian(p) end), Util.IdMapper), 1, 1, "#huanjia-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local pindian = player:pindian({to}, self.name)
    local winner = nil
    if pindian.results[to.id].winner == player then
      winner = player
    elseif pindian.results[to.id].winner == to then
      winner = to
    end
    if not winner or winner.dead then return end
    local ids = {}
    for _, card in ipairs({pindian.fromCard, pindian.results[to.id].toCard}) do
      if room:getCardArea(card) == Card.DiscardPile and not winner:prohibitUse(card) and winner:canUse(card) then
        table.insertIfNeed(ids, card:getEffectiveId())
      end
    end
    if #ids == 0 then return end
    local fakemove = {
      toArea = Card.PlayerHand,
      to = winner.id,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({winner}, {fakemove})
    room:setPlayerMark(winner, "huanjia_cards", ids)
    local success, dat = room:askForUseActiveSkill(winner, "huanjia_viewas", "#huanjia-use:"..player.id, true)
    room:setPlayerMark(winner, "huanjia_cards", 0)
    fakemove = {
      from = winner.id,
      toArea = Card.Void,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({winner}, {fakemove})
    if success then
      local card = Fk.skills["huanjia_viewas"]:viewAs(dat.cards)
      local use = {
        from = winner.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
      }
      room:useCard(use)
      if not player.dead then
        if use.damageDealt then
          local skills = {}
          for _, skill in ipairs(player.player_skills) do
            if not skill.attached_equip then
              table.insert(skills, skill.name)
            end
          end
          local choice = room:askForChoice(player, skills, self.name, "#huanjia-choice", true)
          room:handleAddLoseSkills(player, "-"..choice, nil, true, false)
        else
          for _, c in ipairs({pindian.fromCard, pindian.results[to.id].toCard}) do
            if c:getEffectiveId() ~= card:getEffectiveId() and room:getCardArea(c) == Card.DiscardPile then
              room:obtainCard(player, c, true, fk.ReasonJustMove)
            end
          end
        end
      end
    end
  end,
}
local huanjia_viewas = fk.CreateViewAsSkill{
  name = "huanjia_viewas",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("huanjia_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
lianhe:addRelatedSkill(lianhe_trigger)
Fk:addSkill(huanjia_viewas)
hanrong:addSkill(lianhe)
hanrong:addSkill(huanjia)
hanrong:addSkill("xumin")
Fk:loadTranslationTable{
  ["olz__hanrong"] = "族韩融",
  ["#olz__hanrong"] = "虎口扳渡",
  ["illustrator:olz__hanrong"] = "鬼画府",
  ["lianhe"] = "连和",
  [":lianhe"] = "出牌阶段开始时，你可以横置两名角色，其下个出牌阶段的阶段结束时，若其此阶段未摸牌，其选择一项："..
  "1.令你摸X+1张牌；2.交给你X-1张牌（X为其此阶段获得牌数且至多为3）。",
  ["huanjia"] = "缓颊",
  [":huanjia"] = "出牌阶段结束时，你可以与一名角色拼点，赢的角色可以使用一张拼点牌，若此牌：未造成伤害，你获得另一张拼点牌；造成了伤害，你失去一个技能。",
  ["#lianhe-choose"] = "连和：你可以横置两名角色，你根据其下个出牌阶段获得牌数摸牌",
  ["@@lianhe"] = "连和",
  ["#lianhe_trigger"] = "连和",
  ["#lianhe-card"] = "连和：你需交给 %src %arg张牌，否则其摸%arg2张牌",
  ["#huanjia-choose"] = "缓颊：你可以拼点，赢的角色可以使用一张拼点牌",
  ["#huanjia-use"] = "缓颊：你可以使用一张拼点牌，若未造成伤害则 %src 获得另一张，若造成伤害则其失去一个技能",
  ["#huanjia-choice"] = "缓颊：你需失去一个技能",
  ["huanjia_viewas"] = "缓颊",

  ["$lianhe1"] = "枯草难存于劲风，唯抱簇得生。",
  ["$lianhe2"] = "吾所来之由，一为好，二为和。",
  ["$huanjia1"] = "我之所言，皆为君好。",
  ["$huanjia2"] = "吾言之切切，请君听之。",
  ["$xumin_olz__hanrong1"] = "江海陆沉，皆为黎庶之泪。",
  ["$xumin_olz__hanrong2"] = "天下汹汹，百姓何辜？",
  ["~olz__hanrong"] = "天下兴亡，皆苦百姓……",
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
          if color2 ~= "nocolor" and color2 == color then
            room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
          end
        end
      end
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return player:inMyAttackRange(p) end), Util.IdMapper)
      if #targets == 0 then return end
      local target = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhuw1-choose", self.name, false)
      if #target > 0 then
        target = room:getPlayerById(target[1])
      else
        target = room:getPlayerById(table.random(targets))
      end
      local use1 = room:askForUseCard(player, "slash", "slash", "#lianzhuw-slash::"..target.id, true,
        {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
      if use1 then
        room:useCard(use1)
        if not player.dead and not target.dead then
          local color = use1.card:getColorString()
          local prompt = "#lianzhuw1-slash::"..target.id..":"..color
          if color == "nocolor" then
            prompt = "#lianzhuw-slash::"..target.id
          end
          local use2 = room:askForUseCard(player, "slash", "slash", prompt, true,
            {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
          if use2 then
            room:useCard(use2)
            if color ~= "nocolor" then
              local color2 = use2.card:getColorString()
              if color2 ~= "nocolor" and color2 ~= color and player:getMaxCards() > 0 then
                room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
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
    src:broadcastSkillInvoke("lianzhuw")
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
          if color2 ~= "nocolor" and color2 == color then
            room:addPlayerMark(src, MarkEnum.AddMaxCards, 1)
          end
        end
      end
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return (player:inMyAttackRange(p) or src:inMyAttackRange(p)) and p ~= src end), Util.IdMapper)
      if #targets == 0 then return end
      local target = room:askForChoosePlayers(src, targets, 1, 1, "#lianzhuw2-choose:"..player.id, "lianzhuw", false)
      if #target > 0 then
        target = room:getPlayerById(target[1])
      else
        target = room:getPlayerById(table.random(targets))
      end
      local use1 = room:askForUseCard(player, "slash", "slash", "#lianzhuw-slash::"..target.id, true,
        {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
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
        local use2 = room:askForUseCard(src, "slash", "slash", prompt, true,
          {must_targets = {target.id}, bypass_distances = true, bypass_times = true})
        if use2 then
          room:useCard(use2)
          if color ~= "nocolor" then
            local color2 = use2.card:getColorString()
            if color2 ~= "nocolor" and color2 ~= color and src:getMaxCards() > 0 then
              room:addPlayerMark(src, MarkEnum.MinusMaxCards, 1)
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
  ["olz__wukuang"] = "族吴匡",
  ["#olz__wukuang"] = "诛绝宦竖",
  ["illustrator:olz__wukuang"] = "匠人绘",
  ["lianzhuw"] = "联诛",
  [":lianzhuw"] = "转换技，每名角色出牌阶段限一次，阳：其可以与你各重铸一张牌，若颜色相同，你的手牌上限+1；"..
  "阴：你选择一名在你或其攻击范围内的角色，其可以与你各对目标使用一张【杀】，若颜色不同，你的手牌上限-1。",
  ["#lianzhuw1-card"] = "联诛：你可以重铸一张牌，若为%arg，你手牌上限+1",
  ["#lianzhuw2-card"] = "联诛：你可以重铸一张牌",
  ["#lianzhuw1-choose"] = "联诛：选择一名你攻击范围内的角色",
  ["#lianzhuw2-choose"] = "联诛：选择一名你或 %src 攻击范围内的角色",
  ["#lianzhuw1-slash"] = "联诛：你可以对 %dest 使用一张【杀】，若不为%arg，你手牌上限-1",
  ["#lianzhuw-slash"] = "联诛：你可以对 %dest 使用一张【杀】",
  ["lianzhuw&"] = "联诛",
  [":lianzhuw&"] = "出牌阶段限一次，若吴匡的〖联诛〗为：阳：你可以与其各重铸一张牌，若颜色相同，其手牌上限+1；"..
  "阴：其选择一名在你或其攻击范围内的角色，你可以与吴匡各对目标使用一张【杀】，若颜色不同，其手牌上限-1。",

  ["$lianzhuw1"] = "奸宦作乱，当联兵伐之。",
  ["$lianzhuw2"] = "尽诛贼常侍，正在此时。",
  ["$muyin_olz__wukuang1"] = "家有贵女，其德泽三代。",
  ["$muyin_olz__wukuang2"] = "吾家当以此女而兴之。",
  ["~olz__wukuang"] = "孟德何在？本初何在？",
}

local wangyun = General(extension, "olz__wangyun", "qun", 3)
local jiexuan = fk.CreateViewAsSkill{
  name = "jiexuan",
  anim_type = "switch",
  switch_skill_name = "jiexuan",
  frequency = Skill.Limited,
  prompt = function(self)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return "#jiexuan-yang"
    else
      return "#jiexuan-yin"
    end
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        return Fk:getCardById(to_select).color == Card.Red
      else
        return Fk:getCardById(to_select).color == Card.Black
      end
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      card = Fk:cloneCard("snatch")
    else
      card = Fk:cloneCard("dismantlement")
    end
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
}
local mingjiew = fk.CreateActiveSkill{
  name = "mingjiew",
  anim_type = "control",
  prompt = "#mingjiew-active",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and (not table.contains(U.getMark(target, "@@mingjiew"), Self.id)
    or (to_select == Self.id and Self:getMark("mingjiew_Self-turn") == 0))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = U.getMark(target, "@@mingjiew")
    if player == target then
      room:setPlayerMark(player, "mingjiew_Self-turn", 1)
      if table.contains(mark, player.id) then
        return
      else
        room:setPlayerMark(player, "mingjiew_disabled-turn", 1)
      end
    end
    table.insert(mark, player.id)
    room:setPlayerMark(target, "@@mingjiew", mark)
  end,
}

local mingjiew_delay = fk.CreateTriggerSkill{
  name = "#mingjiew_delay",
  mute = true,
  events = {fk.AfterCardTargetDeclared, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      if target == player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
        local mark
        local targets = table.filter(U.getUseExtraTargets(player.room, data), function (id)
          mark = room:getPlayerById(id):getMark("@@mingjiew")
          return type(mark) == "table" and table.contains(mark, player.id)
        end)
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      end
    elseif event == fk.TurnEnd then
      if player:getMark("mingjiew_disabled-turn") > 0 or not table.contains(U.getMark(target, "@@mingjiew"), player.id) then
        return false
      end
      local events = room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      local end_id = target:getMark("mingjiew_record-turn")
      if end_id == 0 then
        end_id = room.logic:getCurrentEvent().id
      end
      room:setPlayerMark(target, "mingjiew_record-turn", room.logic.current_event_id)
      local ids = U.getMark(target, "mingjiew_usecard-turn")
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= end_id then break end
        local use = e.data[1]
        if use.card.suit == Card.Spade or use.cardsResponded then
          table.insertTableIfNeed(ids, use.card:isVirtual() and use.card.subcards or {use.card.id})
        end
      end
      room:setPlayerMark(target, "mingjiew_usecard-turn", ids)
      return table.find(ids, function (id)
        local card = Fk:getCardById(id)
        return room:getCardArea(id) == Card.DiscardPile and player:canUse(card) and not player:prohibitUse(card)
      end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      local tos = room:askForChoosePlayers(player, self.cost_data, 1, #self.cost_data,
        "#mingjiew-choose:::"..data.card:toLogString(), "mingjiew", true)
      if #tos > 0 then
        table.forEach(tos, function (id)
          table.insert(data.tos, {id})
        end)
      end
    elseif event == fk.TurnEnd then
      local ids = target:getMark("mingjiew_usecard-turn")
      local to_use = {}
      while not player.dead do
        to_use = table.filter(ids, function (id)
          local card = Fk:getCardById(id)
          return room:getCardArea(id) == Card.DiscardPile and player:canUse(card) and not player:prohibitUse(card)
        end)
        if #to_use == 0 then break end
        player.special_cards["mingjiew"] = table.simpleClone(to_use)
        player:doNotify("ChangeSelf", json.encode {
          id = player.id,
          handcards = player:getCardIds("h"),
          special_cards = player.special_cards,
        })
        room:setPlayerMark(player, "mingjiew_cards", to_use)
        local success, dat = room:askForUseActiveSkill(player, "mingjiew_viewas", "#mingjiew-use", true)
        room:setPlayerMark(player, "mingjiew_cards", 0)
        player.special_cards["mingjiew"] = {}
        player:doNotify("ChangeSelf", json.encode {
          id = player.id,
          handcards = player:getCardIds("h"),
          special_cards = player.special_cards,
        })
        if success then
          table.removeOne(ids, dat.cards[1])
          local card = Fk.skills["mingjiew_viewas"]:viewAs(dat.cards)
          room:useCard{
            from = player.id,
            tos = table.map(dat.targets, function(id) return {id} end),
            card = card,
            extraUse = true,
          }
        else
          break
        end
      end
    end
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@mingjiew") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    if player:getMark("mingjiew_Self-turn") == 0 then
      player.room:setPlayerMark(player, "@@mingjiew", 0)
    else
      player.room:setPlayerMark(player, "@@mingjiew", {player.id})
    end
  end,
}
local mingjiew_viewas = fk.CreateViewAsSkill{
  name = "mingjiew_viewas",
  expand_pile = "mingjiew",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("mingjiew_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
local zhongliu = fk.CreateTriggerSkill{
  name = "zhongliu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player == target then
      local no_skill = true
      local all_skills = Fk.generals[player.general]:getSkillNameList()
      if table.contains(all_skills, self.name) then
        for _, skill_name in ipairs(all_skills) do
          local skill = Fk.skills[skill_name]
          local scope_type = skill.scope_type
          if scope_type == nil and skill.frequency == Skill.Limited then
            scope_type = Player.HistoryGame
          end
          if scope_type and player:usedSkillTimes(skill_name, scope_type) > 0 then
            no_skill = false
            break
          end
        end
      end
      if no_skill and player.deputyGeneral and player.deputyGeneral ~= "" then
        all_skills = Fk.generals[player.deputyGeneral]:getSkillNameList()
        if table.contains(all_skills, self.name) then
          for _, skill_name in ipairs(all_skills) do
            local skill = Fk.skills[skill_name]
            local scope_type = skill.scope_type
            if scope_type == nil and skill.frequency == Skill.Limited then
              scope_type = Player.HistoryGame
            end
            if scope_type and player:usedSkillTimes(skill_name, scope_type) > 0 then
              no_skill = false
              break
            end
          end
        end
      end
      if no_skill then return false end
      local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
      if #cardlist == 0 then return true end
      local room = player.room
      local use_event = room.logic:getCurrentEvent()
      use_event:searchEvents(GameEvent.MoveCards, 1, function(e)
        if e.parent and e.parent.id == use_event.id then
          local subcheck = table.simpleClone(cardlist)
          for _, move in ipairs(e.data) do
            if move.moveReason == fk.ReasonUse then
              local wang_family = false
              if move.from then
                local p = room:getPlayerById(move.from)
                if isFamilyMember(p, "wang") or p == player then
                  wang_family = true
                end
              end
              for _, info in ipairs(move.moveInfo) do
                if table.removeOne(subcheck, info.cardId) and info.fromArea == Card.PlayerHand then
                  if wang_family then
                    no_skill = true
                  end
                end
              end
            end
          end
          if #subcheck == 0 then
            return true
          end
        end
      end)
      return not no_skill
    end
  end,
  on_use = function(self, event, target, player, data)
    local all_skills = Fk.generals[player.general]:getSkillNameList()
    if table.contains(all_skills, self.name) then
      for _, skill_name in ipairs(all_skills) do
        local skill = Fk.skills[skill_name]
        local scope_type = skill.scope_type
        if scope_type == nil and skill.frequency == Skill.Limited then
          scope_type = Player.HistoryGame
        end
        if scope_type and player:usedSkillTimes(skill_name, scope_type) > 0 then
          player:setSkillUseHistory(skill_name, 0, scope_type)
        end
      end
    end
    if player.deputyGeneral and player.deputyGeneral ~= "" then
      all_skills = Fk.generals[player.deputyGeneral]:getSkillNameList()
      if table.contains(all_skills, self.name) then
        for _, skill_name in ipairs(all_skills) do
          local skill = Fk.skills[skill_name]
          local scope_type = skill.scope_type
          if scope_type == nil and skill.frequency == Skill.Limited then
            scope_type = Player.HistoryGame
          end
          if scope_type and player:usedSkillTimes(skill_name, scope_type) > 0 then
            player:setSkillUseHistory(skill_name, 0, scope_type)
          end
        end
      end
    end
  end,
}
mingjiew:addRelatedSkill(mingjiew_delay)
Fk:addSkill(mingjiew_viewas)
wangyun:addSkill(jiexuan)
wangyun:addSkill(mingjiew)
wangyun:addSkill(zhongliu)
Fk:loadTranslationTable{
  ["olz__wangyun"] = "族王允",
  ["#olz__wangyun"] = "曷丧偕亡",
  ["illustrator:olz__wangyun"] = "君桓文化",
  ["jiexuan"] = "解悬",
  [":jiexuan"] = "转换技，限定技，阳：你可以将一张红色牌当【顺手牵羊】使用；阴：你可以将一张黑色牌当【过河拆桥】使用。",
  ["mingjiew"] = "铭戒",
  [":mingjiew"] = "限定技，出牌阶段，你可以选择一名角色，直到其下回合结束，你使用牌可以额外指定其为目标，且其下回合结束时，"..
  "你可以使用弃牌堆中此回合中被使用过的♠牌和被抵消过的牌。",
  ["zhongliu"] = "中流",
  [":zhongliu"] = "宗族技，锁定技，当你使用牌时，若不为同族角色的手牌，你视为未发动此武将牌上的技能。",
  ["#jiexuan-yang"] = "解悬：你可以将一张红色牌当【顺手牵羊】使用",
  ["#jiexuan-yin"] = "解悬：你可以将一张黑色牌当【过河拆桥】使用",
  ["#mingjiew-active"] = "发动 铭戒，选择一名角色作为目标",
  ["#mingjiew_delay"] = "铭戒",
  ["@@mingjiew"] = "铭戒",
  ["#mingjiew-choose"] = "铭戒：你可以为此%arg额外指定任意名“铭戒”角色为目标",
  ["mingjiew_viewas"] = "铭戒",
  ["#mingjiew-use"] = "铭戒：你可以使用其中的牌",

  ["$jiexuan1"] = "允不才，愿以天下苍生为己任。",
  ["$jiexuan2"] = "愿以此躯为膳，饲天下以太平。",
  ["$mingjiew1"] = "大公至正，恪忠义于国。",
  ["$mingjiew2"] = "此生柱国之志，铭恪于胸。",
  ["$zhongliu_olz__wangyun1"] = "国朝汹汹如涌，当如柱石镇之。",
  ["$zhongliu_olz__wangyun2"] = "砥中流之柱，其舍我复谁？",
  ["~olz__wangyun"] = "获罪于君，当伏大辟以谢天下……",
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
  card_filter = Util.FalseFunc,
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
wangling:addSkill(bolong)
bolong.scope_type = Player.HistoryPhase
wangling:addSkill("zhongliu")
Fk:loadTranslationTable{
  ["olz__wangling"] = "族王淩",
  ["#olz__wangling"] = "荧惑守斗",
  ["illustrator:olz__wangling"] = "君桓文化",
  ["bolong"] = "驳龙",
  [":bolong"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.你交给其一张牌，视为对其使用一张雷【杀】；"..
  "2.交给你与你手牌数等量张牌，视为对你使用一张【酒】。",
  ["#bolong-card"] = "驳龙：交给 %src %arg张牌视为对其使用【酒】，否则其交给你一张牌视为对你使用雷【杀】",
  ["#bolong-slash"] = "驳龙：交给 %dest 一张牌，视为对其使用雷【杀】",

  ["$bolong1"] = "驳者，食虎之兽焉，可摄冢虎。",
  ["$bolong2"] = "主上暗弱，当另择明主侍之。",
  ["$zhongliu_olz__wangling1"] = "王门世代骨鲠，皆为国之柱石。",
  ["$zhongliu_olz__wangling2"] = "行舟至中流而遇浪，大风起兮。",
  ["~olz__wangling"] = "淩忠心可鉴，死亦未悔……",
}

local zhongyan = General(extension, "olz__zhongyan", "jin", 3, 3, General.Female)
local guangu = fk.CreateActiveSkill{
  name = "guangu",
  anim_type = "switch",
  switch_skill_name = "guangu",
  card_num = 0,
  target_num = function(self)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return 0
    else
      return 1
    end
  end,
  prompt = function(self)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return "#guangu-yang"
    else
      return "#guangu-yin"
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return false
    else
      return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local status = player:getSwitchSkillState(self.name, true) == fk.SwitchYang and "yang" or "yin"
    local target = nil
    local ids = {}
    if status == "yang" then
      --local choice = tonumber(room:askForChoice(player, {"1", "2", "3", "4"}, self.name, "#guangu-choice"))
      --仪式选牌！
      --[[
      --这个函数在返回时id为-1的卡会自动填充target的随机手牌，因此不能返回超过target的手牌数的数量，by smart Notify
      ids = room:askForCardsChosen(player, player, 1, 4, {
        card_data = {
          { "Top", {-1,-1,-1,-1} }
        }
      }, self.name, "#guangu-choice")
      ids = room:getNCards(#ids)
      ]]
      local command = "AskForCardsChosen"
      room:notifyMoveFocus(player, command)
      local data = {player.id, 1, 4, {
        card_data = {
          { "Top", {-1,-1,-1,-1} }
        }
      }, self.name, "#guangu-choice"}
      local result = room:doRequest(player, command, json.encode(data))
      ids = room:getNCards(result ~= "" and #json.decode(result) or 1)
    elseif status == "yin" then
      target = room:getPlayerById(effect.tos[1])
      ids = room:askForCardsChosen(player, target, 1, 4, "h", self.name)
    end
    room:setPlayerMark(player, "@guangu-phase", #ids)

    if target == nil or target ~= player then
      player.special_cards["guangu"] = table.simpleClone(ids)
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
    end

    room:setPlayerMark(player, MarkEnum.BypassTimesLimit .. "-tmp", 1)
    local availableCards = {}
    for _, id in ipairs(ids) do
      local card = Fk:getCardById(id)
      if not player:prohibitUse(card) and player:canUse(card) then
        table.insertIfNeed(availableCards, id)
      end
    end
    room:setPlayerMark(player, "guangu_cards", availableCards)
    local success, dat = room:askForUseActiveSkill(player, "guangu_viewas", "#guangu-use", true)
    room:setPlayerMark(player, "guangu_cards", 0)

    room:setPlayerMark(player, MarkEnum.BypassTimesLimit .. "-tmp", 0)

    if target == nil or target ~= player then
      player.special_cards["guangu"] = {}
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
    end
    if status == "yang" then
      if success then
        table.removeOne(ids, dat.cards[1])
      end
      for i = #ids, 1, -1 do
        table.insert(room.draw_pile, 1, ids[i])
      end
    end
    if success then
      local card = Fk.skills["guangu_viewas"]:viewAs(dat.cards)
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    end
  end,
}
local guangu_viewas = fk.CreateViewAsSkill{
  name = "guangu_viewas",
  expand_pile = "guangu",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("guangu_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
local xiaoyong = fk.CreateTriggerSkill{
  name = "xiaoyong",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) or player:usedSkillTimes("guangu", Player.HistoryPhase) == 0 then return false end
    local n = Fk:translate(data.card.trueName):len()
    if n ~= player:getMark("@guangu-phase") then return false end
    local mark = player:getMark("xiaoyong-turn")
    if type(mark) ~= "table" then mark = {0,0,0,0} end
    local room = player.room
    local use_event = room.logic:getCurrentEvent()
    if mark[n] == 0 then
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == player.id and Fk:translate(use.card.trueName):len() == n then
          mark[n] = e.id
          room:setPlayerMark(player, "xiaoyong-turn", mark)
          return true
        end
        return false
      end, Player.HistoryTurn)
    end
    return use_event.id == mark[n]
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@guangu-phase", 0)
    player:setSkillUseHistory("guangu", 0, Player.HistoryPhase)
  end,
}
local baozu = fk.CreateTriggerSkill{
  name = "baozu",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.dying and not target.chained and
    (isFamilyMember(target, "zhong") or target == player)
    and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#baozu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    if not target.chained then
      target:setChainState(true)
    end
    if not target.dead and target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
Fk:addSkill(guangu_viewas)
zhongyan:addSkill(guangu)
zhongyan:addSkill(xiaoyong)
zhongyan:addSkill(baozu)
Fk:loadTranslationTable{
  ["olz__zhongyan"] = "族钟琰",
  ["#olz__zhongyan"] = "紫闼飞莺",
  ["illustrator:olz__zhongyan"] = "凡果",
  ["guangu"] = "观骨",
  [":guangu"] = "转换技，出牌阶段限一次，阳：你可以观看牌堆顶至多四张牌；阴：你可以观看一名角色至多四张手牌。然后你可以使用其中一张牌。",
  ["xiaoyong"] = "啸咏",
  [":xiaoyong"] = "锁定技，当你于回合内首次使用牌名字数为X的牌时（X为你上次发动〖观骨〗观看牌数），你视为未发动〖观骨〗。",
  ["baozu"] = "保族",
  [":baozu"] = "宗族技，限定技，当同族角色进入濒死状态时，你可以令其横置并回复1点体力。",
  ["#guangu-yang"] = "观骨：你可以观看牌堆顶至多四张牌，然后使用其中一张牌",
  ["#guangu-yin"] = "观骨：你可以观看一名角色至多四张手牌，然后使用其中一张牌",
  ["#guangu-choice"] = "观骨：选择你要观看的牌数",
  ["@guangu-phase"] = "观骨",
  ["guangu_viewas"] = "观骨",
  ["#guangu-use"] = "观骨：你可以使用其中一张牌",
  ["#baozu-invoke"] = "保族：你可以令 %dest 横置并回复1点体力",

  ["$guangu1"] = "此才拔萃，然观其形骨，恐早夭。",
  ["$guangu2"] = "绯衣者，汝所拔乎？",
  ["$xiaoyong1"] = "凉风萧条，露沾我衣。",
  ["$xiaoyong2"] = "忧来多方，慨然永怀。",
  ["$baozu_olz__zhongyan1"] = "好女宜家，可度大厄。",
  ["$baozu_olz__zhongyan2"] = "宗族有难，当施以援手。",
  ["~olz__zhongyan"] = "此间天下人，皆分一斗之才……",
}

local zhonghui = General(extension, "olz__zhonghui", "wei", 3, 4)
local yuzhi = fk.CreateTriggerSkill{
  name = "yuzhi",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.RoundStart, fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.RoundStart then
        return true
      else
        return player:getMark("_yuzhi") ~= 0 and
          (player:getMark("yuzhi2-round") < tonumber(player:getMark("yuzhi1")) or tonumber(player:getMark("_yuzhi")) < tonumber(player:getMark("yuzhi1")))
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.RoundStart then
      room:notifySkillInvoked(player, self.name, "drawcard")
      local cards = {}
      if not player:isKongcheng() then
        cards = room:askForCard(player, 1, 1, false, self.name, false, ".", "#yuzhi-card")
        player:showCards(cards)
      end
      if not player.dead then
        if player:getMark("yuzhi1") ~= 0 then
          room:setPlayerMark(player, "_yuzhi", player:getMark("yuzhi1"))
        end
        if #cards == 0 then
          room:setPlayerMark(player, "yuzhi1", "0")
        else
          local n = Fk:translate(Fk:getCardById(cards[1]).trueName):len() -- FIXME: depends on config language, catastrophe!
          room:setPlayerMark(player, "yuzhi1", n)
          player:drawCards(n, self.name)
        end
        room:setPlayerMark(player, "@yuzhi", player:getMark("yuzhi1"))
      end
    else
      room:notifySkillInvoked(player, self.name, "negative")
      local choices = {"loseHp"}
      if player:hasSkill("baozu", true) then
        table.insert(choices, "yuzhi2")
      end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "loseHp" then
        room:loseHp(player, 1, self.name)
      else
        room:handleAddLoseSkills(player, "-baozu", nil, true, false)
      end
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and player:getMark("yuzhi1") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "yuzhi2-round", 1)
    room:setPlayerMark(player, "@yuzhi", tostring(player:getMark("yuzhi1"))[1].."/"..tostring(player:getMark("yuzhi2-round")))
  end,
}
local xieshu = fk.CreateTriggerSkill{
  name = "xieshu",
  anim_type = "drawcard",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and #player:getCardIds("he") >= Fk:translate(data.card.trueName):len()
  end,
  on_cost = function(self, event, target, player, data)
    local n = Fk:translate(data.card.trueName):len()
    local cards = player.room:askForDiscard(player, n, n, true, self.name, true, ".",
      "#xieshu-invoke:::"..math.floor(n)..":"..player:getLostHp(), true)
    if #cards == n then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    if not player.dead and player:isWounded() then
      player:drawCards(player:getLostHp(), self.name)
    end
  end,
}
zhonghui:addSkill(yuzhi)
zhonghui:addSkill(xieshu)
zhonghui:addSkill("baozu")
Fk:loadTranslationTable{
  ["olz__zhonghui"] = "族钟会",
  ["#olz__zhonghui"] = "百巧惎",
  ["yuzhi"] = "迂志",
  [":yuzhi"] = "锁定技，每轮开始时，你展示一张手牌，摸X张牌（X为此牌牌名字数）。每轮结束时，若你本轮使用牌数或上轮以此法摸牌数小于X，"..
  "你失去1点体力或失去〖保族〗。",
  ["xieshu"] = "挟术",
  [":xieshu"] = "当你使用牌造成伤害后或受到牌造成的伤害后，你可以弃置X张牌（X为此牌牌名字数），摸你已损失体力值张数的牌。",
  ["#yuzhi-card"] = "迂志：请展示一张手牌，摸其牌名字数的牌",
  ["@yuzhi"] = "迂志",
  ["yuzhi2"] = "失去〖保族〗",
  [":loseHp"] = "失去1点体力",
  ["#xieshu-invoke"] = "挟术：你可以弃%arg张牌，摸%arg2张牌",

  ["$yuzhi1"] = "我欲行夏禹旧事，为天下人。",
  ["$yuzhi2"] = "汉鹿已失，魏牛犹在，吾欲执其耳。",
  ["$xieshu1"] = "今长缨在手，欲问鼎九州。",
  ["$xieshu2"] = "我有佐国之术，可缚苍龙。",
  ["$baozu_olz__zhonghui1"] = "不为刀下脍，且做俎上刀。",
  ["$baozu_olz__zhonghui2"] = "吾族恒大，谁敢欺之？",
  ["~olz__zhonghui"] = "谋事在人，成事在天……",
}

local wanghun = General(extension, "olz__wanghun", "jin", 3)
local fuxun = fk.CreateActiveSkill{
  name = "fuxun",
  anim_type = "control",
  min_card_num = 0,
  max_card_num = 1,
  target_num = 1,
  prompt = "#fuxun",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      return #selected_cards == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng() or #selected_cards == 1
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if #effect.cards == 0 then
      local id = room:askForCardChosen(player, target, "h", self.name)
      room:moveCards({
        from = target.id,
        ids = {id},
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    else
      room:moveCards({
        from = player.id,
        ids = effect.cards,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = self.name,
      })
    end
    if player:getHandcardNum() == target:getHandcardNum() and not player.dead then
      local events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.skillName ~= self.name then
            if move.to == target.id and move.toArea == Card.PlayerHand and #move.moveInfo > 0 then
              return true
            end
            if move.from == target.id then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand then
                  return true
                end
              end
            end
          end
        end
      end, Player.HistoryPhase)
      if #events > 0 then return end
      local success, data = room:askForUseActiveSkill(player, "fuxun_viewas", "#fuxun-use", true)
      if success then
        local card = Fk.skills["fuxun_viewas"]:viewAs(data.cards)
        room:useCard{
          from = player.id,
          tos = table.map(data.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      end
    end
  end,
}
local fuxun_viewas = fk.CreateViewAsSkill{
  name = "fuxun_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = "fuxun"
    return card
  end,
}
local fuxun_targetmod = fk.CreateTargetModSkill{
  name = "#fuxun_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, "fuxun")
  end,
}
local chenya = fk.CreateTriggerSkill{
  name = "chenya",
  anim_type = "support",
  events = {fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target and not target.dead and not target:isKongcheng() and
      ((data:isInstanceOf(ActiveSkill) or data:isInstanceOf(ViewAsSkill)) and
      table.find({"出牌阶段限一次", "阶段技", "每阶段限一次"}, function(str) return Fk:translate(":"..data.name):startsWith(str) end)) and
      not data.attached_equip and data.name[#data.name] ~= "&"
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#chenya-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local success, dat = room:askForUseActiveSkill(target, "chenya_active", "#chenya-card:::"..target:getHandcardNum(), true)
    if success then
      room:recastCard(dat.cards, target, self.name)
    end
  end,
}
local chenya_active = fk.CreateActiveSkill{
  name = "chenya_active",
  mute = true,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return Self:getHandcardNum() == Fk:translate(card.trueName):len()
  end,
}
Fk:addSkill(fuxun_viewas)
Fk:addSkill(chenya_active)
fuxun:addRelatedSkill(fuxun_targetmod)
fuxun.scope_type = Player.HistoryPhase
wanghun:addSkill(fuxun)
wanghun:addSkill(chenya)
wanghun:addSkill("zhongliu")
Fk:loadTranslationTable{
  ["olz__wanghun"] = "族王浑",
  ["#olz__wanghun"] = "献捷横江",
  ["illustrator:olz__wanghun"] = "匠人绘",
  ["fuxun"] = "抚循",
  [":fuxun"] = "出牌阶段限一次，你可以交给一名其他角色一张手牌或获得一名其他角色一张手牌，"..
  "然后若其手牌数与你相同且本阶段未因此法以外的方式变化过，你可以将一张牌当任意基本牌使用。",
  ["chenya"] = "沉雅",
  [":chenya"] = "一名角色发动“出牌阶段限一次”的技能后，你可以令其重铸任意张牌名字数为X的牌（X为其手牌数）。",
  ["#fuxun"] = "抚循：交给或获得一名角色一张手牌，然后若手牌数相同且符合一定条件，你可以将一张牌当任意基本牌使用",
  ["fuxun_viewas"] = "抚循",
  ["#fuxun-use"] = "抚循：你可以将一张牌当任意基本牌使用",
  ["#chenya-invoke"] = "沉雅：你可以令 %dest 重铸牌",
  ["chenya_active"] = "沉雅",
  ["#chenya-card"] = "沉雅：你可以重铸任意张牌名字数为%arg的牌",

  ["$fuxun1"] = "东吴遗民惶惶，宜抚而不宜罚。	",
  ["$fuxun2"] = "江东新附，不可以严法度之。",
  ["$chenya1"] = "喜怒不现于形，此为执中之道。",
  ["$chenya2"] = "胸有万丈之海，故而波澜不惊。",
  ["$zhongliu_olz__wanghun1"] = "国潮汹涌，当为中流之砥柱。",
  ["$zhongliu_olz__wanghun2"] = "执剑斩巨浪，息风波者出我辈。",
  ["~olz__wanghun"] = "灭国之功本属我，奈何枉作他人衣……",
}

local zhongyu = General(extension, "olz__zhongyu", "wei", 3)
local jiejian = fk.CreateTriggerSkill{
  name = "jiejian",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.type ~= Card.TypeEquip and data.firstTarget then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.from == player.id then
          n = n + 1
        end
      end, Player.HistoryTurn)
      return n == Fk:translate(data.card.trueName):len()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, 1,
      "#jiejian-choose:::"..math.floor(Fk:translate(data.card.trueName):len()), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(self.cost_data):drawCards(Fk:translate(data.card.trueName):len(), self.name)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@jiejian-turn", 1)
  end,
}
local huanghan = fk.CreateTriggerSkill{
  name = "huanghan",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#huanghan-invoke:::"..(math.floor(Fk:translate(data.card.trueName):len()))..":"..player:getLostHp())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(Fk:translate(data.card.trueName):len(), self.name)
    if not player.dead and player:isWounded() and not player:isNude() then
      local n = player:getLostHp()
      room:askForDiscard(player, n, n, true, self.name, false)
    end
    if player:usedSkillTimes(self.name, Player.HistoryTurn) > 1 and player:usedSkillTimes("baozu", Player.HistoryGame) > 0 then
      player:setSkillUseHistory("baozu", 0, Player.HistoryGame)
    end
  end,
}
zhongyu:addSkill(jiejian)
zhongyu:addSkill(huanghan)
zhongyu:addSkill("baozu")
Fk:loadTranslationTable{
  ["olz__zhongyu"] = "族钟毓",
  ["#olz__zhongyu"] = "础润殷忧",
  ["illustrator:olz__zhongyu"] = "匠人绘",
  ["jiejian"] = "捷谏",
  [":jiejian"] = "当你每回合使用第X张牌指定目标后，若此牌不为装备牌，你可以令其中一个目标摸X张牌（X为此牌牌名字数）。",
  ["huanghan"] = "惶汗",
  [":huanghan"] = "当你受到牌造成的伤害后，你可以摸X张牌（X为此牌牌名字数）并弃置你已损失体力值张牌；若不为本回合首次发动，你视为未发动过〖保族〗。",
  ["#jiejian-choose"] = "捷谏：你可以令其中一个目标摸%arg张牌",
  ["@jiejian-turn"] = "捷谏",
  ["#huanghan-invoke"] = "惶汗：你可以摸%arg张牌，弃%arg2张牌",

  ["$jiejian1"] = "庙胜之策，不临矢石。",
  ["$jiejian2"] = "王者之兵，有征无战。",
  ["$huanghan1"] = "居天子阶下，故诚惶诚恐。",
  ["$huanghan2"] = "战战惶惶，汗出如浆。",
  ["$baozu_olz__zhongyu1"] = "弟会腹有恶谋，不可不防。",
  ["$baozu_olz__zhongyu2"] = "会期大祸将至，请晋公恕之。",
  ["~olz__zhongyu"] = "百年钟氏，一朝为臣矣……",
}

local wanglun = General(extension, "olz__wanglun", "wei", 3)
local qiuxin = fk.CreateActiveSkill{
  name = "qiuxin",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choice = room:askForChoice(target, {"slash", "trick"}, self.name, "#qiuxin-choice:"..player.id)
    local mark = U.getMark(target, "@qiuxin")
    table.insertIfNeed(mark, choice)
    room:setPlayerMark(target, "@qiuxin", mark)
  end,
}
local qiuxin_trigger = fk.CreateTriggerSkill{
  name = "#qiuxin_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(qiuxin) then return false end
    local qiuxin_type = ""
    if data.card.trueName == "slash" then
      qiuxin_type = "slash"
    elseif data.card:isCommonTrick() then
      qiuxin_type = "trick"
    else
      return false
    end
    local tos = TargetGroup:getRealTargets(data.tos)
    for _, p in ipairs(player.room.alive_players) do
      if table.contains(tos, p.id) and table.contains(U.getMark(p, "@qiuxin"), qiuxin_type) then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = TargetGroup:getRealTargets(data.tos)
    if data.card.trueName == "slash" then
      for _, p in ipairs(player.room.alive_players) do
        if player.dead then break end
        if not p.dead and table.contains(tos, p.id) then
          local mark = U.getMark(p, "@qiuxin")
          if table.contains(mark, "slash") then
            room:setPlayerMark(player, "qiuxin-tmp", p.id)
            local success, dat = room:askForUseActiveSkill(player, "qiuxin_viewas", "#qiuxin-trick::"..p.id, true)
            room:setPlayerMark(player, "qiuxin-tmp", 0)
            if success and dat then
              table.removeOne(mark, "slash")
              room:setPlayerMark(p, "@qiuxin", #mark > 0 and mark or 0)
              local trick = Fk:cloneCard(dat.interaction)
              trick.skillName = qiuxin.name
              local _tos = {{p.id}}
              for _, pid in ipairs(dat.targets) do
                table.insert(_tos, {pid})
              end
              room:useCard({
                from = player.id,
                tos = _tos,
                card = trick,
                extraUse = true,
              })
            end
          end
        end
      end
    elseif data.card:isCommonTrick() then
      for _, p in ipairs(player.room.alive_players) do
        local slash = Fk:cloneCard("slash")
        slash.skillName = qiuxin.name
        if player.dead or player:prohibitUse(slash) then break end
        if table.contains(tos, p.id) and not (p.dead or player:isProhibited(p, slash))  then
          local mark = U.getMark(p, "@qiuxin")
          if table.contains(mark, "trick") and
          room:askForSkillInvoke(player, qiuxin.name, nil, "#qiuxin-slash::" .. p.id) then
            table.removeOne(mark, "trick")
            room:setPlayerMark(p, "@qiuxin", #mark > 0 and mark or 0)
            room:useCard({
              from = player.id,
              tos = {{p.id}},
              card = slash,
              extraUse = true,
            })
          end
        end
      end
    end
  end,
}
local qiuxin_viewas = fk.CreateActiveSkill{
  name = "qiuxin_viewas",
  interaction = function()
    local mark = Self:getMark("qiuxin-tmp")
    local all_names = U.getAllCardNames("t")
    local to = Fk:currentRoom():getPlayerById(mark)
    local names = table.filter(all_names, function (card_name)
      local trick = Fk:cloneCard(card_name)
      trick.skillName = qiuxin.name
      return not (Self:prohibitUse(trick) or Self:isProhibited(to, trick)) and
      trick.skill:modTargetFilter(mark, {}, Self.id, trick, false)
    end)
    if #names == 0 then return end
    return UI.ComboBox {choices = names, all_choices = all_names}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if not self.interaction.data then return false end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = qiuxin.name
    if card.skill:getMinTargetNum() < 2 then return false end
    local _selected = {Self:getMark("qiuxin-tmp")}
    table.insertTable(_selected, selected)
    return card.skill:targetFilter(to_select, _selected, {}, card)
  end,
  feasible = function(self, selected, selected_cards)
    if not self.interaction.data then return false end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = qiuxin.name
    local x = card.skill:getMinTargetNum()
    return x < 2 or #selected + 1 == x
  end,
}
local jianyuan = fk.CreateTriggerSkill{
  name = "jianyuan",
  anim_type = "support",
  events = {fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target and not target.dead and not target:isNude() and
      ((data:isInstanceOf(ActiveSkill) or data:isInstanceOf(ViewAsSkill)) and
      table.find({"出牌阶段限一次", "阶段技", "每阶段限一次"}, function(str) return Fk:translate(":"..data.name):startsWith(str) end)) and
      not data.attached_equip and data.name[#data.name] ~= "&"
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jianyuan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n = 0
    room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      if use and use.from == target.id then
        n = n + 1
      end
    end, Player.HistoryPhase)
    if n == 0 then return end
    room:setPlayerMark(target, "jianyuan-tmp", n)
    local success, dat = room:askForUseActiveSkill(target, "jianyuan_active", "#jianyuan-card:::"..n, true)
    room:setPlayerMark(target, "jianyuan-tmp", 0)
    if success then
      room:recastCard(dat.cards, target, self.name)
    end
  end,
}
local jianyuan_active = fk.CreateActiveSkill{
  name = "jianyuan_active",
  mute = true,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return Self:getMark("jianyuan-tmp") == Fk:translate(card.trueName):len()
  end,
}
qiuxin:addRelatedSkill(qiuxin_trigger)
Fk:addSkill(qiuxin_viewas)
Fk:addSkill(jianyuan_active)
qiuxin.scope_type = Player.HistoryPhase
wanglun:addSkill(qiuxin)
wanglun:addSkill(jianyuan)
wanglun:addSkill("zhongliu")
Fk:loadTranslationTable{
  ["olz__wanglun"] = "族王沦",
  ["#olz__wanglun"] = "半缘修道",
  ["illustrator:olz__wanglun"] = "君桓文化",
  ["qiuxin"] = "求心",
  [":qiuxin"] = "出牌阶段限一次，你可以令一名其他角色声明一项：1.你对其使用一张【杀】；2.你对其使用一张普通锦囊牌。你下次执行此项后，"..
  "可以视为执行另一项的效果。",
  ["jianyuan"] = "简远",
  [":jianyuan"] = "当一名角色发动“出牌阶段限一次”的技能后，你可以令其重铸任意张牌名字数为X的牌（X为其本阶段使用牌数）。",
  ["@qiuxin"] = "求心",
  ["#qiuxin-choice"] = "求心：%src 对你发动“求心”，请声明一项",
  ["#qiuxin-slash"] = "求心：是否视为对 %dest 使用【杀】？",
  ["#qiuxin-trick"] = "求心：选择视为对 %dest 使用的锦囊？",
  ["qiuxin_viewas"] = "求心",
  ["#jianyuan-invoke"] = "简远：你可以令 %dest 重铸牌",
  ["jianyuan_active"] = "简远",
  ["#jianyuan-card"] = "简远：你可以重铸任意张牌名字数为%arg的牌",

  ["$qiuxin1"] = "此生所求者，顺心意尔。",
  ["$qiuxin2"] = "羡孔丘知天命之岁，叹吾生之不达。",
  ["$jianyuan1"] = "我视天地为三，其为众妙之门。",
  ["$jianyuan2"] = "昔年孔明有言，宁静方能致远。",
  ["$zhongliu_olz__wanglun1"] = "上善若水，中流而引全局。",
  ["$zhongliu_olz__wanglun2"] = "泽物无声，此真名士风流。",
  ["~olz__wanglun"] = "人间多锦绣，奈何我云不喜……",
}

Fk:addQmlMark{
  name = "baichu",
  qml_path = "packages/ol/qml/Baichu",
  how_to_show = function() return " " end,
}

local xunyou = General(extension, "olz__xunyou", "wei", 3)
local baichu = fk.CreateTriggerSkill{
  name = "baichu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(self) then
      local mark = U.getMark(player, "@[baichu]")
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
          room:handleAddLoseSkills(player, "qice", nil, true, false)
          round_event:addCleaner(function()
            room:handleAddLoseSkills(player, "-qice", nil, true, false)
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
        local choice = room:askForChoice(player, names, self.name, "#baichu-choice", false, all_names)
        mark._tab[suit][ty] = choice
        mark[choice] = true
        room:setPlayerMark(player, "@[baichu]", mark)
      end
    end
    if mark[data.card.trueName] ~= nil then
      if not player:isWounded() then
        player:drawCards(1, self.name)
      else
        local choice = room:askForChoice(player, {"draw1", "recover"}, self.name)
        if choice == "draw1" then
          player:drawCards(1, self.name)
        else
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      end
    end
  end,
}
xunyou:addSkill(baichu)
xunyou:addSkill("daojie")
xunyou:addRelatedSkill("qice")
Fk:loadTranslationTable{
  ["olz__xunyou"] = "族荀攸",
  ["#olz__xunyou"] = "慨然入幕",
  ["illustrator:olz__xunyou"] = "错落宇宙",
  ["baichu"] = "百出",
  [":baichu"] = "锁定技，当你使用牌后，若此牌：花色-类型组合为你首次使用，你记录一张普通锦囊牌，否则你本轮获得〖奇策〗；"..
  "以此法记录过，你摸一张牌或回复1点体力。",
  -- ["@$baichu"] = "百出",
  ["@[baichu]"] = "百出",
  ["#baichu-choice"] = "百出：记录一张普通锦囊牌",

  ["@@baichu-inhand"] = "<font color='yellow'>未出</font>",
  ["@@baichu_record-inhand"] = "百出",

  ["$baichu1"] = "腹有经纶，到用时施无穷之计。",
  ["$baichu2"] = "胸纳甲兵，烽烟起可靖疆晏海。",
  ["$daojie_olz__xunyou1"] = "秉忠正之心，可抚宁内外。",
  ["$daojie_olz__xunyou2"] = "贤者，温良恭俭让以得之。",
  ["$qice_olz__xunyou1"] = "二袁相争，此曹公得利之时。",
  ["$qice_olz__xunyou2"] = "穷寇宜追，需防死蛇之不僵。",
  ["~olz__xunyou"] = "吾知命之寿，明知命之节……",
}

return extension
