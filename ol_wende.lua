local extension = Package("ol_wende")
extension.extensionName = "ol"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_wende"] = "OL-文德武备",
  ["jin"] = "晋",
}

local simayi = General(extension, "ol__simayi", "jin", 3)
local buchen = fk.CreateTriggerSkill{
  name = "buchen",
  can_trigger = Util.FalseFunc,
}
local yingshis = fk.CreateActiveSkill{
  name = "yingshis",
  anim_type = "special",
  frequency = Skill.Compulsory,  --锁定主动技（
  card_num = 0,
  target_num = 0,
  prompt = "#yingshis",
  can_use = function(self, player)
    return player:getMark("yingshis-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "yingshis-phase", 1)
    if #room.draw_pile == 0 then return end
    local cards = room:getNCards(math.min(player.maxHp, #room.draw_pile))
    U.viewCards(player, cards, self.name, "Top")
    for i = #cards, 1, -1 do
      table.insert(room.draw_pile, 1, cards[i])
    end
  end,
}
local yingshis_trigger = fk.CreateTriggerSkill{
  name = "#yingshis_trigger",

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("yingshis-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "yingshis-phase", 0)
  end,
}
local xiongzhi = fk.CreateActiveSkill{
  name = "xiongzhi",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  prompt = "#xiongzhi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    while not player.dead do
      local card = room:getNCards(1)[1]
      room:moveCards({
        ids = {card},
        toArea = Card.Processing,
        skillName = self.name,
        moveReason = fk.ReasonJustMove,
      })
      room:setPlayerMark(player, "xiongzhi-tmp", {card})
      local success, dat = room:askForUseViewAsSkill(player, "xiongzhi_viewas", "#xiongzhi-use:::"..Fk:getCardById(card):toLogString(), true)
      room:setPlayerMark(player, "xiongzhi-tmp", 0)
      if success then
        local use = {
          from = player.id,
          tos = table.map(dat.targets, function(e) return{e} end),
          card = Fk:getCardById(card),
          extraUse = true,
        }
        room:useCard(use)
      else
        room:moveCards({
          ids = {card},
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        break
      end
    end
  end,
}
local xiongzhi_viewas = fk.CreateViewAsSkill{
  name = "xiongzhi_viewas",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:getCardById(Self:getMark("xiongzhi-tmp")[1])
    if Self:canUse(card) and not Self:prohibitUse(card) then
      return card
    end
  end,
}
local quanbian = fk.CreateTriggerSkill{
  name = "quanbian",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.suit ~= Card.NoSuit and
      U.IsUsingHandcard(player, data) then
      local card_suit = data.card.suit
      local room = player.room
      local logic = room.logic
      local current_event = logic:getCurrentEvent()
      local mark_name = "quanbian_" .. data.card:getSuitString() .. "-phase"
      local mark = player:getMark(mark_name)
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.from == player.id and use.card.suit == card_suit then
            mark = e.id
            room:setPlayerMark(player, mark_name, mark)
            return true
          end
          return false
        end, Player.HistoryPhase)
        logic:getEventsOfScope(GameEvent.RespondCard, 1, function (e)
          local use = e.data[1]
          if use.from == player.id and use.card.suit == card_suit then
            mark = math.max(e.id, mark)
            room:setPlayerMark(player, mark_name, mark)
            return true
          end
          return false
        end, Player.HistoryPhase)
      end
      return mark == current_event.id
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@quanbian-phase")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card:getSuitString(true))
    player.room:setPlayerMark(player, "@quanbian-phase", mark)
    self:doCost(event, target, player, data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_cards = room:getNCards(player.maxHp)
    local available_cards = table.filter(all_cards, function(id) return Fk:getCardById(id).suit ~= data.card.suit end)
    local cards, choice = U.askforChooseCardsAndChoice(player, available_cards, {"OK"}, self.name, "#quanbian-get", {"Cancel"}, 1, 1, all_cards)
    if #cards > 0 then
      table.removeOne(all_cards, cards[1])
      room:obtainCard(player, cards[1], false, fk.ReasonPrey)
    end
    if #all_cards > 0 then
      room:askForGuanxing(player, all_cards, nil, {0, 0}, self.name)
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.type ~= Card.TypeEquip and
      U.IsUsingHandcard(player, data)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "quanbian-phase", 1)
  end,
}
local quanbian_prohibit = fk.CreateProhibitSkill{
  name = "#quanbian_prohibit",
  prohibit_use = function(self, player, card)
    return player:hasSkill(self) and player.phase == Player.Play and player:getMark("quanbian-phase") >= player.maxHp and
      card and card.type ~= Card.TypeEquip and table.contains(player:getCardIds("h"), card:getEffectiveId())
  end,
}
yingshis:addRelatedSkill(yingshis_trigger)
quanbian:addRelatedSkill(quanbian_prohibit)
Fk:addSkill(xiongzhi_viewas)
simayi:addSkill(buchen)
simayi:addSkill(yingshis)
simayi:addSkill(xiongzhi)
simayi:addSkill(quanbian)
Fk:loadTranslationTable{
  ["ol__simayi"] = "司马懿",
  ["buchen"] = "不臣",
  [":buchen"] = "<font color='red'>隐匿技（暂时无法生效）</font>，你于其他角色的回合登场后，你可获得其一张牌。",
  ["yingshis"] = "鹰视",
  [":yingshis"] = "锁定技，出牌阶段，你可以观看牌堆顶X张牌（X为你的体力上限）。",
  ["xiongzhi"] = "雄志",
  [":xiongzhi"] = "限定技，出牌阶段，你可展示牌堆顶牌并使用之。你可重复此流程直到牌堆顶牌不能被使用。",
  ["quanbian"] = "权变",
  [":quanbian"] = "当你于出牌阶段首次使用或打出一种花色的手牌时，你可从牌堆顶X张牌中获得一张与此牌花色不同的牌，将其余牌以任意顺序置于牌堆顶。"..
  "出牌阶段，你至多使用X张非装备手牌。（X为你的体力上限）",
  ["#yingshis"] = "鹰视：你可以观看牌堆顶牌",
  ["#xiongzhi"] = "雄志：你可以重复亮出牌堆顶牌并使用之！",
  ["xiongzhi_viewas"] = "雄志",
  ["#xiongzhi-use"] = "雄志：是否使用%arg？",
  ["@quanbian-phase"] = "权变",
  ["#quanbian-get"] = "权变：获得一张花色不同的牌",

  ["$buchen1"] = "螟蛉之光，安敢同日月争辉？",
  ["$buchen2"] = "巍巍隐帝，岂可为臣？",
  ["$yingshis1"] = "鹰扬千里，明察秋毫。",
  ["$yingshis2"] = "鸢飞戾天，目入百川。",
  ["$xiongzhi1"] = "烈士雄心，志存高远。",
  ["$xiongzhi2"] = "乱世之中，唯我司马！",
  ["$quanbian1"] = "筹权谋变，步步为营。",
  ["$quanbian2"] = "随机应变，谋国窃权。",
  ["~ol__zhangchunhua"] = "虎入骷冢，司马难兴。",
}

local zhangchunhua = General(extension, "ol__zhangchunhua", "jin", 3, 3, General.Female)
local xuanmu = fk.CreateTriggerSkill{
  name = "xuanmu",
  can_trigger = Util.FalseFunc,
}
local ol__huishi = fk.CreateTriggerSkill{
  name = "ol__huishi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ol__huishi-invoke:::"..#player.room.draw_pile % 10)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #room.draw_pile % 10
    if n == 0 then return true end
    local card_ids = room:getNCards(n)
    local get = {}
    room:fillAG(player, card_ids)
    if n == 1 then
      room:delay(2000)
      room:closeAG(player)
      return true
    end
    while #get < (n // 2) do
      local card_id = room:askForAG(player, card_ids, false, self.name)
      room:takeAG(player, card_id)
      table.insert(get, card_id)
      table.removeOne(card_ids, card_id)
    end
    room:closeAG(player)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(get)
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    room:moveCards({
      ids = card_ids,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      drawPilePosition = -1,
    })
    return true
  end,
}
local qingleng = fk.CreateTriggerSkill{
  name = "qingleng",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and
      ((#target.player_cards[Player.Hand] + target.hp) >= #player.room.draw_pile % 10) and
      not player:isNude() and not player:isProhibited(target, Fk:cloneCard("ice__slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, true, self.name, true, ".", "#qingleng-invoke::"..target.id)
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:useVirtualCard("ice__slash", {self.cost_data}, player, target, self.name, true)
    if target:getMark(self.name) == 0 then
      if not player.dead then
        player:drawCards(1, self.name)
      end
      if not target.dead then
        room:addPlayerMark(target, self.name, 1)
      end
    end
  end,
}
zhangchunhua:addSkill(xuanmu)
zhangchunhua:addSkill(ol__huishi)
zhangchunhua:addSkill(qingleng)
Fk:loadTranslationTable{
  ["ol__zhangchunhua"] = "张春华",
  ["xuanmu"] = "宣穆",
  [":xuanmu"] = "锁定技，<font color='red'>隐匿技（暂时无法生效）</font>，你于其他角色的回合登场时，防止你受到的伤害直到回合结束。",
  ["ol__huishi"] = "慧识",
  [":ol__huishi"] = "摸牌阶段，你可以放弃摸牌，改为观看牌堆顶的X张牌，获得其中的一半（向下取整），然后将其余牌置入牌堆底。（X为牌堆数量的个位数）",
  ["qingleng"] = "清冷",
  [":qingleng"] = "其他角色回合结束时，若其体力值与手牌数之和不小于X，你可将一张牌当无距离限制的冰【杀】对其使用。"..
  "你对一名没有成为过〖清冷〗目标的角色发动〖清冷〗时，摸一张牌。（X为牌堆数量的个位数）",
  ["#ol__huishi-invoke"] = "慧识：你可以放弃摸牌，改为观看牌堆顶%arg张牌并获得其中的一半，其余置于牌堆底",
  ["#qingleng-invoke"] = "清冷：你可以将一张牌当冰【杀】对 %dest 使用",

  ["$xuanmu1"] = "四门穆穆，八面莹澈。",
  ["$xuanmu2"] = "天色澄穆，心明清静。",
  ["$ol__huishi1"] = "你的想法，我已知晓。",
  ["$ol__huishi2"] = "妾身慧眼，已看透太多。",
  ["$qingleng1"] = "冷冷清清，寂落沉沉。",
  ["$qingleng2"] = "冷月葬情，深雪埋伤。",
  ["~ol__zhangchunhua"] = "冷眸残情，孤苦为一人。",
}

local lisu = General(extension, "ol__lisu", "qun", 3)
local qiaoyan = fk.CreateTriggerSkill{
  name = "qiaoyan",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.NotActive and
      data.from and data.from ~= player and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("ol__lisu_zhu") == 0 then
      player:drawCards(1, self.name)
      if player:isKongcheng() or player.dead then return end
      local card = room:askForCard(player, 1, 1, true, self.name, false, ".", "#qiaoyan-card")
      player:addToPile("ol__lisu_zhu", card[1], false, self.name)
      return true
    else
      room:obtainCard(data.from.id, player:getPile("ol__lisu_zhu")[1], false, fk.ReasonJustMove)
    end
  end,
}
local ol__xianzhu = fk.CreateTriggerSkill{
  name = "ol__xianzhu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player:getPile("ol__lisu_zhu") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1,
      "#ol__xianzhu-choose:::"..Fk:getCardById(player:getPile("ol__lisu_zhu")[1]):toLogString(), self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    room:obtainCard(to.id, player:getPile("ol__lisu_zhu")[1], false, fk.ReasonJustMove)
    if to == player or player.dead or #room.alive_players < 3 then return end
    targets = table.map(table.filter(room:getOtherPlayers(to), function(p)
      return player:inMyAttackRange(p) and not to:isProhibited(p, Fk:cloneCard("slash")) end), Util.IdMapper)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ol__xianzhu-slash::"..to.id, self.name, false)
    if #tos > 0 then
      tos = tos[1]
    else
      tos = table.random(targets)
    end
    room:useVirtualCard("slash", nil, to, room:getPlayerById(tos), self.name, true)
  end,
}
lisu:addSkill(qiaoyan)
lisu:addSkill(ol__xianzhu)
Fk:loadTranslationTable{
  ["ol__lisu"] = "李肃",
  ["qiaoyan"] = "巧言",
  [":qiaoyan"] = "锁定技，在你的回合外，当其他角色对你造成伤害时，若你：没有“珠”，你防止此伤害并摸一张牌，然后将一张牌置于你的武将牌上，称为“珠”；"..
  "有“珠”，其获得“珠”。",
  ["ol__xianzhu"] = "献珠",
  [":ol__xianzhu"] = "锁定技，出牌阶段开始时，你令一名角色获得“珠”；若不为你，其视为对你攻击范围内你指定的一名角色使用一张【杀】。",
  ["ol__lisu_zhu"] = "珠",
  ["#qiaoyan-card"] = "巧言：将一张牌置为“珠”",
  ["#ol__xianzhu-choose"] = "献珠：令一名角色获得“珠”（%arg）",
  ["#ol__xianzhu-slash"] = "献珠：选择你攻击范围内一名角色，视为 %dest 对其使用【杀】",

  ["$qiaoyan1"] = "此事不宜迟，在于速决。",
  ["$qiaoyan2"] = "公若到彼，贵不可言。",
  ["$ol__xianzhu1"] = "馈珠之恩，望将军莫忘。",
  ["$ol__xianzhu2"] = "愿以珠为礼，与卿交好，而休刀兵。",
  ["~ol__lisu"] = "忘恩负义之徒！",
}

local simazhou = General(extension, "simazhou", "jin", 4)
local caiwang = fk.CreateViewAsSkill{
  name = "caiwang",
  anim_type = "control",
  pattern = "jink,nullification,slash",
  prompt = function()
    if Fk.currentResponsePattern == nil then
      return "#caiwang-slash"
    else
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("jink")) and Self:getHandcardNum() == 1 then
        return "#caiwang-jink"
      elseif Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("nullification")) and #Self:getCardIds("e") == 1 then
        return "#caiwang-nullification"
      elseif Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash")) and #Self:getCardIds("j") == 1 then
        return "#caiwang-slash"
      end
    end
  end,
  interaction = function()
    local names = {}
    if Fk.currentResponsePattern == nil then
      local card = Fk:cloneCard("slash")
      if #Self:getCardIds("j") == 1 and Self:canUse(card) and not Self:prohibitUse(card) then
        table.insertIfNeed(names, "slash")
      end
    elseif Fk.currentResponsePattern then
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("jink")) then  --FIXME：奇正相生
        if Self:getHandcardNum() == 1 then
          table.insertIfNeed(names, "jink")
        end
      end
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("nullification")) then
        if #Self:getCardIds("e") == 1 then
          table.insertIfNeed(names, "nullification")
        end
      end
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash")) then
        if #Self:getCardIds("j") == 1 then
          table.insertIfNeed(names, "slash")
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    if self.interaction.data == "jink" then
      card:addSubcard(Self.player_cards[Player.Hand][1])
    elseif self.interaction.data == "nullification" then
      card:addSubcard(Self.player_cards[Player.Equip][1])
    elseif self.interaction.data == "slash" then
      card:addSubcard(Self.player_cards[Player.Judge][1])
    end
    if #card.subcards ~= 1 then return end
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return #player.player_cards[Player.Judge] == 1
  end,
  enabled_at_response = function(self, player, response)
    if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) then
      if Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("nullification")) then
        return #player.player_cards[Player.Equip] == 1
      else
        return player:getHandcardNum() == 1 or #player.player_cards[Player.Judge] == 1
      end
    end
  end,
}
local caiwang_trigger = fk.CreateTriggerSkill{
  name = "#caiwang_trigger",
  mute = true,
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.responseToEvent then
      if (event == fk.CardUseFinished and data.toCard and data.toCard.color == data.card.color) or
        (event == fk.CardRespondFinished and data.responseToEvent.card and data.responseToEvent.card == data.card.color) then
        local id
        if data.responseToEvent.from == player.id then
          id = data.responseToEvent.to
        else
          id = data.responseToEvent.from
        end
        return id and id ~= player.id and not player.room:getPlayerById(id):isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#caiwang-discard"
    local to
    if data.responseToEvent.from == player.id then
      to = data.responseToEvent.to
    else
      to = data.responseToEvent.from
    end
    if player:getMark("naxiang") ~= 0 and table.contains(player:getMark("naxiang"), to) then
      prompt = "#caiwang-prey"
    end
    if player.room:askForSkillInvoke(player, "caiwang", nil, prompt.."::"..to) then
      self.cost_data = {to, prompt}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("caiwang")
    room:notifySkillInvoked(player, "caiwang", "control")
    local to = room:getPlayerById(self.cost_data[1])
    room:doIndicate(player.id, {to.id})
    local id = room:askForCardChosen(player, to, "he", "caiwang")
    if self.cost_data[2][10] == "d" then
      room:throwCard({id}, "caiwang", to, player)
    else
      room:obtainCard(player, id, false, fk.ReasonPrey)
    end
  end,
}
local naxiang = fk.CreateTriggerSkill{
  name = "naxiang",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= data.to and not (data.from.dead or data.to.dead)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local p = data.to
    if event == fk.Damaged then
      p = data.from
    end
    room:setPlayerMark(p, "@@naxiang", 1)
    local mark = player:getMark(self.name)
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, p.id)
    room:setPlayerMark(player, self.name, mark)
  end,

  refresh_events = {fk.EventPhaseChanging, fk.EventLoseSkill, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:getMark(self.name) ~= 0 then
      if event == fk.EventPhaseChanging then
        return data.from == Player.RoundStart
      elseif event == fk.EventLoseSkill then
        return data == self
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getMark(self.name)) do
      local p = room:getPlayerById(id)
      if not p.dead and not table.find(room:getOtherPlayers(player), function(to)
        return to:getMark(self.name) ~= 0 and table.contains(to:getMark(self.name), p.id) end) then
        room:setPlayerMark(p, "@@naxiang", 0)
      end
    end
    room:setPlayerMark(player, self.name, 0)
  end,
}
caiwang:addRelatedSkill(caiwang_trigger)
simazhou:addSkill(caiwang)
simazhou:addSkill(naxiang)
Fk:loadTranslationTable{
  ["simazhou"] = "司马伷",
  ["caiwang"] = "才望",
  [":caiwang"] = "当你使用/打出牌响应其他角色使用的牌后，或其他角色使用/打出牌响应你使用的牌后，若两张牌颜色相同，你可以弃置其一张牌。<br>"..
  "你可以将最后一张手牌当【闪】使用或打出；将最后一张你装备区里的牌当【无懈可击】使用；将最后一张你判定区的牌当【杀】使用或打出。",
  ["naxiang"] = "纳降",
  [":naxiang"] = "锁定技，当其他角色对你造成伤害或受到你的伤害后，你对其发动〖才望〗的“弃置”修改为“获得”直到你的回合开始。",
  ["#caiwang-discard"] = "才望：你可以弃置 %dest 一张牌",
  ["#caiwang-prey"] = "才望：你可以获得 %dest 一张牌",
  ["#caiwang-jink"] = "才望：你可以将最后一张手牌当【闪】使用或打出",
  ["#caiwang-nullification"] = "才望：你可以将最后一张装备当【无懈可击】使用",
  ["#caiwang-slash"] = "才望：你可以将最后一张判定区内的牌当【杀】使用或打出",
  ["@@naxiang"] = "纳降",

  ["$caiwang1"] = "才气不俗，声望四海。",
  ["$caiwang2"] = "绥怀之称，监守邺城。",
  ["$naxiang1"] = "奉命伐吴，得胜纳降。",
  ["$naxiang2"] = "进军逼江，震慑吴贼。",
  ["~simazhou"] = "恩赐重物，病身难消受……",
}

local cheliji = General(extension, "cheliji", "qun", 4)
local chexuan = fk.CreateActiveSkill{
  name = "chexuan",
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude() and #player:getEquipments(Card.SubtypeTreasure) == 0 and
      #player:getAvailableEquipSlots(Card.SubtypeTreasure) > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local all_choices = {"wheel_cart","caltrop_cart","grain_cart"}
    local names,ids = {},{}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local c = Fk:getCardById(id)
      if room:getCardArea(id) == Card.Void then
        local name = c.name
        if table.contains(all_choices, name) and not table.contains(names, name) then
          table.insert(names, name)
          table.insert(ids, id)
        end
      end
    end
    if #names > 0 then
      local choice = room:askForChoice(player, names, self.name, "#chexuan-choice", true, all_choices)
      for i, n in ipairs(names) do
        if n == choice then
          room:moveCardTo(Fk:getCardById(ids[i]), Card.PlayerEquip, player, fk.ReasonPut, self.name)
        end
      end
    end
  end,
}
local chexuan_ts = fk.CreateTriggerSkill{
  name = "#chexuan_ts",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and #player:getAvailableEquipSlots(Card.SubtypeTreasure) > 0 and
      #player:getEquipments(Card.SubtypeTreasure) == 0 then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).sub_type == Card.SubtypeTreasure then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#chexuan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {  who = player, reason = self.name, pattern = ".|.|spade,club" }
    room:judge(judge)
    if judge.card.color == Card.Black and not player.dead and #player:getAvailableEquipSlots(Card.SubtypeTreasure) > 0 and
      #player:getEquipments(Card.SubtypeTreasure) == 0 then
      local ids = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local c = Fk:getCardById(id)
        if room:getCardArea(id) == Card.Void then
          if c.name == "wheel_cart" or c.name == "caltrop_cart" or c.name == "grain_cart" then
            table.insert(ids, id)
          end
        end
      end
      if #ids > 0 then
        local put = table.random(ids)
        room:moveCardTo(Fk:getCardById(put), Card.PlayerEquip, player, fk.ReasonPut, self.name)
      end
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local cart_names = {"caltrop_cart", "grain_cart", "wheel_cart"}
    local mirror_moves = {}
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea ~= Card.Void then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.contains(cart_names, Fk:getCardById(id).name) and info.fromArea == Card.PlayerEquip then
            table.insert(mirror_info, info)
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #mirror_info > 0 then
          move.moveInfo = move_info
          local mirror_move = table.clone(move)
          mirror_move.to = nil
          mirror_move.toArea = Card.Void
          mirror_move.moveInfo = mirror_info
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{ type = "#destructDerivedCards", card = ids, }
    end
    table.insertTable(data, mirror_moves)
  end,
}
chexuan:addRelatedSkill(chexuan_ts)
cheliji:addSkill(chexuan)
local qiangshou = fk.CreateDistanceSkill{
  name = "qiangshou",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(self) and #from:getEquipments(Card.SubtypeTreasure) > 0 then
      return -1
    end
  end,
}
cheliji:addSkill(qiangshou)
Fk:loadTranslationTable{
  ["cheliji"] = "彻里吉",
  ["chexuan"] = "车悬",
  [":chexuan"] = "出牌阶段，若你的装备区里没有宝物牌，你可以弃置一张黑色牌，选择一张“舆”置入你的装备区（此牌离开装备区时销毁）。当你不因使用"..
  "装备牌失去装备区里的宝物牌后，你可以判定，若结果为黑色，将一张随机的“舆”置入你的装备区。",
  ["#chexuan_ts"] = "车悬",
  ["#chexuan-choice"] = "车悬：选择一种“舆”置入你的装备区",
  ["#chexuan-invoke"] = "车悬：你可以判定，若结果为黑色，将一张随机的“舆”置入你的装备区",
  ["qiangshou"] = "羌首",
  [":qiangshou"] = "锁定技，若你的装备区里有宝物牌，你至其他角色的距离-1。",

  ["$chexuan1"] = "兵车疾动，以悬敌首！",
  ["$chexuan2"] = "层层布设，以多胜强！",
  ["~cheliji"] = "元气已伤，不如归去。",
}

local huaxin = General(extension, "ol__huaxin", "wei", 3)
local ol__caozhao = fk.CreateActiveSkill{
  name = "ol__caozhao",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#ol__caozhao-invoke",
  interaction = function()
    local names = {}
    local mark = Self:getMark("@$ol__caozhao")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card:isCommonTrick()) and not card.is_derived then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    return UI.ComboBox {choices = names}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).hp <= Self.hp
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:sendLog{
      type = "#ol__caozhao",
      from = player.id,
      arg = self.interaction.data,
    }
    local mark = player:getMark("@$ol__caozhao")
    if mark == 0 then mark = {} end
    table.insert(mark, Fk:cloneCard(self.interaction.data).trueName)
    room:setPlayerMark(player, "@$ol__caozhao", mark)
    player:showCards(effect.cards)
    if player.dead then return end
    local id = effect.cards[1]
    local choice = room:askForSkillInvoke(target, self.name, nil,
      "#ol__caozhao-choice:"..player.id.."::"..Fk:getCardById(id, true):toLogString()..":"..self.interaction.data)
    if choice then
      room:setCardMark(Fk:getCardById(id), "@@ol__caozhao", self.interaction.data)
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper),
        1, 1, "#ol__caozhao-choose", self.name, true)
      if #to > 0 then
        room:obtainCard(to[1], id, true, fk.ReasonGive)
      end
    else
      room:loseHp(target, 1, self.name)
    end
  end,
}
local ol__caozhao_record = fk.CreateTriggerSkill{
  name = "#ol__caozhao_record",

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
  local room = player.room
    for _, move in ipairs(data) do
      if move.toArea ~= Card.PlayerHand and move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@ol__caozhao", 0)
        end
      end
    end
  end,
}
local ol__caozhao_filter = fk.CreateFilterSkill{
  name = "#ol__caozhao_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@ol__caozhao") ~= 0
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card:getMark("@@ol__caozhao"), card.suit, card.number)
  end,
}
local ol__xibing = fk.CreateTriggerSkill{
  name = "ol__xibing",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= player and
      ((not data.from.dead and #data.from:getCardIds("he") > 1) or #player:getCardIds("he") > 1)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    if not data.from.dead and #data.from:getCardIds("he") > 1 then
      table.insert(targets, data.from.id)
    end
    if #player:getCardIds("he") > 1 then
      table.insert(targets, player.id)
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ol__xibing-invoke::"..data.from.id, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = room:askForCardsChosen(player, to, 2, 2, "he", self.name)
    room:throwCard(cards, self.name, to, player)
    local p = nil
    if player:getHandcardNum() > data.from:getHandcardNum() then
      p = data.from
    elseif player:getHandcardNum() < data.from:getHandcardNum() then
      p = player
    end
    if not p or p.dead then return end
    p:drawCards(2, self.name)
    local mark = player:getMark("ol__xibing-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, p.id)
    room:setPlayerMark(player, "ol__xibing-turn", mark)
  end,
}
local ol__xibing_prohibit = fk.CreateProhibitSkill{
  name = "#ol__xibing_prohibit",
  is_prohibited = function(self, from, to, card)
    return to:getMark("ol__xibing-turn") ~= 0 and table.contains(to:getMark("ol__xibing-turn"), from.id)
  end,
}
ol__caozhao:addRelatedSkill(ol__caozhao_record)
ol__caozhao:addRelatedSkill(ol__caozhao_filter)
ol__xibing:addRelatedSkill(ol__xibing_prohibit)
huaxin:addSkill(ol__caozhao)
huaxin:addSkill(ol__xibing)
Fk:loadTranslationTable{
  ["ol__huaxin"] = "华歆",
  ["ol__caozhao"] = "草诏",
  [":ol__caozhao"] = "出牌阶段限一次，你可展示一张手牌并声明一种未以此法声明过的基本牌或普通锦囊牌，令一名体力值不大于你的其他角色选择一项："..
  "令此牌视为你声明的牌，或其失去1点体力。然后若此牌声明成功，你可以将之交给一名其他角色。",
  ["ol__xibing"] = "息兵",
  [":ol__xibing"] = "当你受到其他角色造成的伤害后，你可以弃置你或其两张牌，然后手牌数少的角色摸两张牌，以此法摸牌的角色不能使用牌指定你为目标直到回合结束。",
  ["#ol__caozhao-invoke"] = "草诏：选择要声明的牌，然后选择展示的手牌和目标角色",
  ["#ol__caozhao"] = "%from 声明了 %arg",
  ["#ol__caozhao-choice"] = "草诏：令 %src 将%arg视为【%arg2】，或点“取消”你失去1点体力",
  ["@$ol__caozhao"] = "草诏",
  ["@@ol__caozhao"] = "草诏",
  ["#ol__caozhao-choose"] = "草诏：你可以将这张牌交给一名其他角色",
  ["#ol__caozhao_filter"] = "草诏",
  ["#ol__xibing-invoke"] = "息兵：你可以弃置你或 %dest 两张牌，然后手牌数少的角色摸两张牌",

  ["$ol__caozhao1"] = "草诏所宣，密勿从事。",
  ["$ol__caozhao2"] = "惩恶扬功，四方之纲。",
  ["$ol__xibing1"] = "讲信修睦，息兵不功。",
  ["$ol__xibing2"] = "天时未至，周武还师。",
  ["~ol__huaxin"] = "死国，甚无谓也！",
}

local zhanghuyuechen = General(extension, "zhanghuyuechen", "jin", 4)
local xijue = fk.CreateTriggerSkill{
  name = "xijue",
  anim_type = "offensive",
  events = {fk.GameStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        return target == player and player:getMark(self.name) > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:addPlayerMark(player, "@zhanghuyuechen_jue", 4)
    else
      room:addPlayerMark(player, "@zhanghuyuechen_jue", player:getMark(self.name))
      room:setPlayerMark(player, self.name, 0)
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, self.name, data.damage)
  end,
}
local xijue_tuxi = fk.CreateTriggerSkill{
  name = "#xijue_tuxi",
  anim_type = "control",
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return (target == player and player:hasSkill(self) and data.n > 0 and player:getMark("@zhanghuyuechen_jue") > 0 and
      not table.every(player.room:getOtherPlayers(player), function (p) return p:isKongcheng() end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, data.n, "#xijue_tuxi-invoke", "ex__tuxi", true)
    if #tos > 0 then
      self.cost_data = tos
      room:removePlayerMark(player, "@zhanghuyuechen_jue", 1)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      local c = room:askForCardChosen(player, p, "h", "ex__tuxi")
      room:obtainCard(player.id, c, false, fk.ReasonPrey)
    end
    data.n = data.n - #self.cost_data
  end,
}
local xijue_xiaoguo = fk.CreateTriggerSkill{
  name = "#xijue_xiaoguo",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and
      not player:isKongcheng() and player:getMark("@zhanghuyuechen_jue") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, "xiaoguo", true, ".|.|.|.|.|basic", "#xijue_xiaoguo-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, "xiaoguo", player, player)
    room:removePlayerMark(player, "@zhanghuyuechen_jue", 1)
    if #room:askForDiscard(target, 1, 1, true, "xiaoguo", true, ".|.|.|.|.|equip", "#xiaoguo-discard:"..player.id) > 0 then
      player:drawCards(1)
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = "xiaoguo",
      }
    end
  end,
}
xijue:addRelatedSkill(xijue_tuxi)
xijue:addRelatedSkill(xijue_xiaoguo)
zhanghuyuechen:addSkill(xijue)
zhanghuyuechen:addRelatedSkill("ex__tuxi")
zhanghuyuechen:addRelatedSkill("xiaoguo")
Fk:loadTranslationTable{
  ["zhanghuyuechen"] = "张虎乐綝",
  ["xijue"] = "袭爵",
  [":xijue"] = "游戏开始时，你获得4个“爵”标记；回合结束时，你获得X个“爵”标记（X为你本回合造成的伤害值）。你可以移去1个“爵”标记发动〖突袭〗或〖骁果〗。",
  ["@zhanghuyuechen_jue"] = "爵",
  ["#xijue_tuxi-invoke"] = "袭爵：你可以移去1个“爵”标记发动〖突袭〗",
  ["#xijue_xiaoguo-invoke"] = "袭爵：你可以移去1个“爵”标记对 %dest 发动〖骁果〗",
  ["#xijue_tuxi"] = "突袭",
  [":#xijue_tuxi"] = "摸牌阶段，你可以少摸任意张牌，获得等量其他角色各一张手牌。",
  ["#xijue_xiaoguo"] = "骁果",
  [":#xijue_xiaoguo"] = "其他角色结束阶段开始时，你可以弃置一张基本牌。若如此做，该角色需弃置一张装备牌并令你摸一张牌，否则受到你对其造成的1点伤害。",

  ["$xijue1"] = "承爵于父，安能辱之！",
  ["$xijue2"] = "虎父安有犬子乎！",
  ["$#xijue_tuxi1"] = "动如霹雳，威震枭首！",
  ["$#xijue_tuxi2"] = "行略如风，摧枯拉朽！",
  ["$#xijue_xiaoguo1"] = "大丈夫生于世，当沙场效忠！",
  ["$#xijue_xiaoguo2"] = "骁勇善战，刚毅果断！",
  ["~zhanghuyuechen"] = "儿有辱……父亲威名……",
}

local xiahouhui = General(extension, "xiahouhui", "jin", 3, 3, General.Female)
local baoqie = fk.CreateTriggerSkill{
  name = "baoqie",
  can_trigger = Util.FalseFunc,
}
local yishi = fk.CreateTriggerSkill{
  name = "yishi",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local room = player.room
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason == fk.ReasonDiscard and room:getPlayerById(move.from).phase == Player.Play and
          not room:getPlayerById(move.from).dead and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
          self.cost_data = move.from
          player.tag[self.name] = {}
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and
              (room:getCardArea(info.cardId) == Card.DiscardPile or room:getCardArea(info.cardId) == Card.Processing) then
              table.insertIfNeed(player.tag[self.name], info.cardId)
            end
          end
          return #player.tag[self.name] > 0
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#yishi-invoke::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = player.tag[self.name]
    for _, id in ipairs(cards) do
      if room:getCardArea(id) ~= Card.DiscardPile and room:getCardArea(id) ~= Card.Processing then
        table.removeOne(cards)
      end
    end
    if #cards == 1 then
      room:obtainCard(to, cards[1], true, fk.ReasonJustMove)
    else
      room:fillAG(player, cards)
      local id = room:askForAG(player, cards, false, self.name)
      room:closeAG(player)
      table.removeOne(cards, id)
      room:obtainCard(to, id, true, fk.ReasonJustMove)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, true, fk.ReasonJustMove)
    end
    player.tag[self.name] = {}
  end,
}
local shidu = fk.CreateActiveSkill{
  name = "shidu",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      if not target:isKongcheng() then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(target:getCardIds(Player.Hand))
        room:obtainCard(player, dummy, false, fk.ReasonPrey)
      end
      local n = #player:getCardIds(Player.Hand)
      if n > 1 then
        local cards = room:askForCard(player, (n//2), (n//2), false, self.name, false, ".", "#shidu-give:::"..tostring(n//2))
        local dummy2 = Fk:cloneCard("dilu")
        dummy2:addSubcards(cards)
        room:obtainCard(target, dummy2, false, fk.ReasonGive)
      end
    end
  end,
}
xiahouhui:addSkill(baoqie)
xiahouhui:addSkill(yishi)
xiahouhui:addSkill(shidu)
Fk:loadTranslationTable{
  ["xiahouhui"] = "夏侯徽",
  ["baoqie"] = "宝箧",
  [":baoqie"] = "<font color='red'>隐匿技（暂时无法生效）</font>，锁定技，当你登场后，你从牌堆或弃牌堆获得一张宝物牌，然后你可以使用之。",
  ["yishi"] = "宜室",
  [":yishi"] = "每回合限一次，当一名其他角色于其出牌阶段弃置手牌后，你可以令其获得其中的一张牌，然后你获得其余的牌。",
  ["shidu"] = "识度",
  [":shidu"] = "出牌阶段限一次，你可以与一名其他角色拼点，若你赢，你获得其所有手牌，然后你交给其你的一半手牌（向下取整）。",
  ["#yishi-invoke"] = "宜室：你可以令 %dest 收回一张弃置的牌，你获得其余的牌",
  ["#shidu-give"] = "识度：你需交还%arg张手牌",

  ["$baoqie1"] = "宝箧藏玺，时局变动。",
  ["$baoqie2"] = "曹亡宝箧，尽露锋芒。",
  ["$yishi1"] = "家庭和顺，夫妻和睦。",
  ["$yishi2"] = "之子于归，宜其室家。",
  ["$shidu1"] = "鉴识得体，气度雅涵。",
  ["$shidu2"] = "宽容体谅，宽人益己。",
  ["~xiahouhui"] = "夫君，你怎么对我如此狠心……",
}

local simashi = General(extension, "ol__simashi", "jin", 3, 4)
local taoyin = fk.CreateTriggerSkill{
  name = "taoyin",
  can_trigger = Util.FalseFunc,
}
local yimie = fk.CreateTriggerSkill{
  name = "yimie",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to.hp > data.damage and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yimie-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    data.extra_data = data.extra_data or {}
    data.extra_data.yimie = {player.id, data.to.id, data.to.hp - data.damage}
    data.damage = data.to.hp
  end,

  refresh_events = {fk.DamageFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and not player.dead and data.extra_data and data.extra_data.yimie and data.extra_data.yimie[2] == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = math.min(player:getLostHp(), data.extra_data.yimie[3]),
      recoverBy = room:getPlayerById(data.extra_data.yimie[1]),
      skillName = self.name
    })
  end,
}
local tairan = fk.CreateTriggerSkill{
  name = "tairan",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player.phase == Player.Finish then
        player.room:setPlayerMark(player, "tairan_hp", 0)
        player.room:setPlayerMark(player, "tairan_cards", 0)
        return player:isWounded() or player:getHandcardNum() < player.maxHp
      elseif player.phase == Player.Play then
        return player:getMark("tairan_hp") > 0 or player:getMark("tairan_cards") ~= 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Finish then
      if player:isWounded() then
        local n = player:getLostHp()
        room:recover({
          who = player,
          num = n,
          recoverBy = player,
          skillName = self.name
        })
        room:setPlayerMark(player, "tairan_hp", n)
      end
      if player:getHandcardNum() < player.maxHp then
        local cards = player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
        room:setPlayerMark(player, "tairan_cards", cards)
      end
    else
      if player:getMark("tairan_hp") > 0 then
        room:loseHp(player, player:getMark("tairan_hp"), self.name)
      end
      if not player.dead then
        local cards = player:getMark("tairan_cards")
        if cards ~= 0 then
          local ids = {}
          for _, id in ipairs(cards) do
            for _, card in ipairs(player.player_cards[Player.Hand]) do
              if id == card then
                table.insertIfNeed(ids, id)
              end
            end
          end
          if #ids > 0 then
            room:throwCard(ids, self.name, player, player)
          end
        end
      end
    end
  end,
}
local ruilve = fk.CreateTriggerSkill{
  name = "ruilve",

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self and not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill(self, true) end)
    else
      return target == player and player:hasSkill(self, true, true) and
        not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill(self, true) end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "ruilve&", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:handleAddLoseSkills(p, "-ruilve&", nil, false, true)
      end
    end
  end,
}
local ruilve_active = fk.CreateActiveSkill{
  name = "ruilve&",
  mute = true,
  card_num = 1,
  target_num = 0,
  prompt = "#ruilve",
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.kingdom == "jin" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("ruilve") and p ~= player end)
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and (Fk:getCardById(to_select).is_damage_card)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return p:hasSkill("ruilve") and p ~= player end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, nil, self.name, false)[1])
    end
    if not target then return false end
    target:broadcastSkillInvoke("ruilve")
    room:notifySkillInvoked(target, "ruilve", "support")
    room:doIndicate(effect.from, {target.id})
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, true)
  end,
}
Fk:addSkill(ruilve_active)
simashi:addSkill(taoyin)
simashi:addSkill(yimie)
simashi:addSkill(tairan)
simashi:addSkill(ruilve)
Fk:loadTranslationTable{
  ["ol__simashi"] = "司马师",
  ["taoyin"] = "韬隐",
  [":taoyin"] = "<font color='red'>隐匿技（暂时无法生效）</font>，你于其他角色的回合登场后，你可以令其本回合的手牌上限-2。",
  ["yimie"] = "夷灭",
  [":yimie"] = "每回合限一次，当你对一名其他角色造成伤害时，你可失去1点体力，令此伤害值+X（X为其体力值减去伤害值）。伤害结算后，其回复X点体力。",
  ["tairan"] = "泰然",
  [":tairan"] = "锁定技，回合结束时，你回复体力至体力上限，将手牌摸至体力上限；出牌阶段开始时，你失去上回合以此法回复的体力值，弃置以此法获得的手牌。",
  ["ruilve"] = "睿略",
  [":ruilve"] = "主公技，其他晋势力角色的出牌阶段限一次，该角色可以将一张【杀】或伤害锦囊牌交给你。",
  ["ruilve&"] = "睿略",
  [":ruilve&"] = "出牌阶段限一次，你可以将一张【杀】或伤害锦囊牌交给司马师。",
  ["#ruilve"] = "睿略：你可以将一张伤害牌交给司马师",
  ["#yimie-invoke"] = "夷灭：你可以失去1点体力，令你对 %arg 造成的伤害增加至其体力值！",

  ["$taoyin1"] = "司马氏善谋、善忍，善置汝于绝境！",
  ["$taoyin2"] = "隐忍数载，亦不坠青云之志！",
  ["$yimie1"] = "汝大逆不道，当死无赦！",
  ["$yimie2"] = "斩草除根，灭其退路！",
  ["$tairan1"] = "撼山易，撼我司马氏难。",
  ["$tairan2"] = "云卷云舒，处之泰然。",
  ["$ruilve1"] = "司马当兴，其兴在吾。",
  ["$ruilve2"] = "吾承父志，故知军事通谋略。",
  ["~ol__simashi"] = "子上，这是为兄给你打下的江山……",
}

local yanghuiyu = General(extension, "ol__yanghuiyu", "jin", 3, 3, General.Female)
local huirong = fk.CreateTriggerSkill{
  name = "huirong",
  can_trigger = Util.FalseFunc,
}
local ciwei = fk.CreateTriggerSkill{
  name = "ciwei",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase ~= Player.NotActive and target:getMark("ciwei-turn") == 2 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ciwei-invoke::"..target.id..":"..data.card:toLogString()) > 0
  end,
  on_use = function(self, event, target, player, data)  --有目标则取消，无目标则无效
    if data.card.name == "jink" or data.card.name == "nullification" then
      data.toCard = nil
      return true
    else
      table.forEach(TargetGroup:getRealTargets(data.tos), function (id)
        TargetGroup:removeTarget(data.tos, id)
      end)
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true) and target ~= player and target.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "ciwei-turn", 1)
  end,
}
local caiyuan = fk.CreateTriggerSkill{
  name = "caiyuan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.to == Player.NotActive then
      if player:getMark(self.name) > 0 then
        return true
      else
        player.room:setPlayerMark(player, self.name, 1)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and data.num < 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
yanghuiyu:addSkill(huirong)
yanghuiyu:addSkill(ciwei)
yanghuiyu:addSkill(caiyuan)
Fk:loadTranslationTable{
  ["ol__yanghuiyu"] = "羊徽瑜",
  ["huirong"] = "慧容",
  [":huirong"] = "<font color='red'>隐匿技（暂时无法生效）</font>，锁定技，你登场时，令一名角色将手牌摸或弃至体力值（至多摸至五张）。",
  ["ciwei"] = "慈威",
  [":ciwei"] = "其他角色于其回合内使用第二张牌时，若此牌为基本牌或普通锦囊牌，你可弃置一张牌令此牌无效或取消所有目标。",
  ["caiyuan"] = "才媛",
  [":caiyuan"] = "锁定技，回合结束前，若你于上回合结束至今未扣减过体力，你摸两张牌。",
  ["#ciwei-invoke"] = "慈威：你可以弃置一张牌，取消 %dest 使用的%arg",

  ["$huirong1"] = "红尘洗练，慧容不改。",
  ["$huirong2"] = "花貌易改，福惠长存。",
  ["$ciwei1"] = "乃家乃邦，是则是效。",
  ["$ciwei2"] = "其慈有威，不舒不暴。",
  ["$caiyuan1"] = "柳絮轻舞，撷芳赋诗。",
  ["$caiyuan2"] = "秀媛才德，知书达理。",
  ["~ol__yanghuiyu"] = "韶华易老，佳容不再……",
}

local shibao = General(extension, "shibao", "jin", 4)
local zhuosheng = fk.CreateTriggerSkill{
  name = "zhuosheng",
  anim_type = "special",
  events = {fk.AfterCardTargetDeclared, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and data.card:getMark("@@zhuosheng-round") > 0 then
      if event == fk.AfterCardTargetDeclared then
        return data.card:isCommonTrick() and data.tos
      else
        return data.card.type == Card.TypeEquip
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardTargetDeclared then
      local room = player.room
      local targets = TargetGroup:getRealTargets(data.tos)
      table.insertTable(targets, U.getUseExtraTargets(room, data, false))
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#zhuosheng-choose:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#zhuosheng-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardTargetDeclared then
      if table.contains(TargetGroup:getRealTargets(data.tos), self.cost_data[1]) then
        TargetGroup:removeTarget(data.tos, self.cost_data[1])
      else
        table.insert(data.tos, self.cost_data)
      end
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@zhuosheng-round", 0)
        end
      end
      if move.to == player.id and move.toArea == Player.Hand and move.skillName ~= self.name then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            room:setCardMark(Fk:getCardById(id), "@@zhuosheng-round", 1)
          end
        end
      end
    end
  end,
}
local zhuosheng_targetmod = fk.CreateTargetModSkill{
  name = "#zhuosheng_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(self) and player.phase == Player.Play and card and
      card.type == Card.TypeBasic and card:getMark("@@zhuosheng-round") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(self) and player.phase == Player.Play and card and
      card.type == Card.TypeBasic and card:getMark("@@zhuosheng-round") > 0
  end,
}
zhuosheng:addRelatedSkill(zhuosheng_targetmod)
shibao:addSkill(zhuosheng)
Fk:loadTranslationTable{
  ["shibao"] = "石苞",
  ["zhuosheng"] = "擢升",
  [":zhuosheng"] = "出牌阶段，当你使用本轮非以本技能获得的牌时，根据类型执行以下效果：1.基本牌，无距离和次数限制；"..
  "2.普通锦囊牌，可以令此牌目标+1或-1；3.装备牌，你可以摸一张牌。",
  ["@@zhuosheng-round"] = "擢升",
  ["#zhuosheng-choose"] = "擢升：你可以为此%arg增加或减少一个目标",
  ["#zhuosheng-invoke"] = "擢升：你可以摸一张牌",

  ["$zhuosheng1"] = "才经世务，干用之绩。",
  ["$zhuosheng2"] = "器量之远，当至公辅。",
  ["~shibao"] = "寒门出身，难以擢升。",
}

local simazhao = General(extension, "ol__simazhao", "jin", 3)
local choufa = fk.CreateActiveSkill{
  name = "choufa",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#choufa",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(card)
    if not target.dead then
      for _, id in ipairs(target:getCardIds("h")) do
        if Fk:getCardById(id).type ~= Fk:getCardById(card).type then
          room:setCardMark(Fk:getCardById(id), "@@choufa-turn", 1)
        end
      end
    end
  end,
}
local choufa_trigger = fk.CreateTriggerSkill{
  name = "#choufa_trigger",

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
  local room = player.room
    for _, move in ipairs(data) do
      if move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@choufa-turn", 0)
        end
      end
    end
  end,
}
local choufa_filter = fk.CreateFilterSkill{
  name = "#choufa_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@choufa-turn") > 0
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
local zhaoran = fk.CreateTriggerSkill{
  name = "zhaoran",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhaoran-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhaoran-phase", {})
    player:showCards(player:getCardIds("h"))
  end,
}
local zhaoran_trigger = fk.CreateTriggerSkill{
  name = "#zhaoran_trigger",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("zhaoran", Player.HistoryPhase) > 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              if not table.find(player:getCardIds("h"), function(id)
                return Fk:getCardById(id).suit == Fk:getCardById(info.cardId).suit end) and
                not table.contains(player:getMark("@zhaoran-phase"), Fk:getCardById(info.cardId):getSuitString(true)) then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local suits = {}
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            if not table.find(player:getCardIds("h"), function(id)
              return Fk:getCardById(id).suit == Fk:getCardById(info.cardId).suit end) and
              not table.contains(player:getMark("@zhaoran-phase"), Fk:getCardById(info.cardId):getSuitString(true)) then
              table.insertIfNeed(suits, Fk:getCardById(info.cardId):getSuitString(true))
            end
          end
        end
      end
    end
    local mark = player:getMark("@zhaoran-phase")
    table.insertTableIfNeed(mark, suits)
    player.room:setPlayerMark(player, "@zhaoran-phase", mark)
    for i = 1, #suits, 1 do
      self:doCost(event, target, player, suits)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(room:getOtherPlayers(player), function(p) return p:isNude() end) then
      player:broadcastSkillInvoke("zhaoran")
      room:notifySkillInvoked(player, "zhaoran", "drawcard")
      player:drawCards(1, "zhaoran")
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function (p)
        return not p:isNude() end), Util.IdMapper)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhaoran-discard", "zhaoran", true)
      player:broadcastSkillInvoke("zhaoran")
      if #to > 0 then
        room:notifySkillInvoked(player, "zhaoran", "control")
        local id = room:askForCardChosen(player, room:getPlayerById(to[1]), "he", "zhaoran")
        room:throwCard({id}, "zhaoran", room:getPlayerById(to[1]), player)
      else
        room:notifySkillInvoked(player, "zhaoran", "drawcard")
        player:drawCards(1, "zhaoran")
      end
    end
  end,
}
local chengwu = fk.CreateAttackRangeSkill{
  name = "chengwu$",
  frequency = Skill.Compulsory,
  within_func = function (self, from, to)
    if from:hasSkill(self) then
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.kingdom == "jin" and from ~= p and p:inMyAttackRange(to) then
          return true
        end
      end
    end
  end,
}
choufa:addRelatedSkill(choufa_trigger)
choufa:addRelatedSkill(choufa_filter)
zhaoran:addRelatedSkill(zhaoran_trigger)
simazhao:addSkill(choufa)
simazhao:addSkill(zhaoran)
simazhao:addSkill(chengwu)
Fk:loadTranslationTable{
  ["ol__simazhao"] = "司马昭",
  ["tuishi"] = "推弑",
  [":shiren"] = "<font color='red'>隐匿技（暂时无法生效）</font>，若你于其他角色的回合登场，此回合结束时，你可令其对其攻击范围内你选择的一名角色"..
  "使用【杀】，若其未使用【杀】，你对其造成1点伤害。",
  ["choufa"] = "筹伐",
  [":choufa"] = "出牌阶段限一次，你可展示一名其他角色的一张手牌，其手牌中与此牌不同类型的牌均视为【杀】直到其回合结束。",
  ["zhaoran"] = "昭然",
  --[":zhaoran"] = "出牌阶段开始时，你可令你的手牌对所有角色可见直到此阶段结束。若如此做，当你于本阶段失去任意花色的最后一张手牌时（每种花色限一次），"..
  [":zhaoran"] = "出牌阶段开始时，你可展示所有手牌。若如此做，当你于本阶段失去任意花色的最后一张手牌时（每种花色限一次），"..
  "你摸一张牌或弃置一名其他角色的一张牌。",
  ["chengwu"] = "成务",
  [":chengwu"] = "主公技，锁定技，其他晋势力角色攻击范围内的角色均视为在你的攻击范围内。",
  ["#choufa"] = "筹伐：展示一名其他角色一张手牌，本回合其手牌中不为此类别的牌均视为【杀】",
  ["@@choufa-turn"] = "筹伐",
  ["#zhaoran-invoke"] = "昭然：你可以展示所有手牌，本阶段你失去一种花色最后的手牌后摸一张牌或弃置一名角色一张牌",
  ["@zhaoran-phase"] = "昭然",
  ["#zhaoran-discard"] = "昭然：弃置一名其他角色一张牌，或点“取消”摸一张牌",

  ["$tuishi1"] = "此僚怀异，召汝讨贼。",
  ["$tuishi2"] = "推令既出，焉敢不从？",
  ["$choufa1"] = "秣马厉兵，筹伐不臣！",
  ["$choufa2"] = "枕戈待旦，秣马征平。",
  ["$zhaoran1"] = "行昭然于世，赦众贼以威。",
  ["$zhaoran2"] = "吾之心思，路人皆知。",
  ["$chengwu1"] = "令行禁止，政通无虞。",
  ["$chengwu2"] = "上下一体，大业可筹。",
  ["~ol__simazhao"] = "司马三代，一梦成空……",
}

local xuangongzhu = General(extension, "xuangongzhu", "jin", 3, 3, General.Female)
local gaoling = fk.CreateTriggerSkill{
  name = "gaoling",
  can_trigger = Util.FalseFunc,
}
local qimei = fk.CreateTriggerSkill{
  name = "qimei",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
    1, 1, "#qimei-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local mark =  U.getMark(to, "@@qimei")
    table.insert(mark, player.id)
    room:setPlayerMark(to, "@@qimei", mark)
    room:setPlayerMark(player, "qimei_couple", to.id)
  end,

  refresh_events = {fk.BuryVictim, fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return not player.dead and (type(player:getMark("@@qimei")) == "table" or player == target)
  end,
  on_refresh = function(self, event, target, player, data)
    if player == target then
      player.room:setPlayerMark(player, "qimei_couple", 0)
    else
      local mark = player:getMark("@@qimei")
      table.removeOne(mark, target.id)
      player.room:setPlayerMark(player, "@@qimei", #mark > 0 and mark or 0)
    end
  end,
}
local qimei_delay = fk.CreateTriggerSkill{
  name = "#qimei_delay",
  events = {fk.AfterCardsMove, fk.HpChanged},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local mark_id = player:getMark("qimei_couple")
    if mark_id == 0 then return false end
    local room = player.room
    local to = room:getPlayerById(mark_id)
    if to == nil or to.dead then return false end
    if event == fk.AfterCardsMove then
      if player:getHandcardNum() ~= to:getHandcardNum() then return false end
      local tos = {player.id, mark_id}
      for _, move in ipairs(data) do
        if move.from and table.contains(tos, move.from) and table.find(move.moveInfo, function (info)
          return info.fromArea == Card.PlayerHand
        end) then
          table.removeOne(tos, move.from)
        end
        if move.to and table.contains(tos, move.to) and move.toArea == Card.PlayerHand then
          table.removeOne(tos, move.to)
        end
      end
      if #tos == 2 then return false end
      if #tos == 0 then
        tos = {player.id, mark_id}
      end
      local mark =  U.getMark(player, "qimei_used-turn")
      tos = table.filter(tos, function (id)
        return not table.contains(mark, id)
      end)
      if #tos == 0 then return false end
      self.cost_data = tos
      return true
    elseif event == fk.HpChanged then
      if player.hp ~= to.hp then return false end
      local mark =  U.getMark(player, "qimei_used-turn")
      if target == player then
        if not table.contains(mark, mark_id) then
          self.cost_data = {mark_id}
          return true
        end
      elseif target == to then
        if not table.contains(mark, player.id) then
          self.cost_data = {player.id}
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(self.cost_data)
    room:sortPlayersByAction(tos)
    room:doIndicate(player.id, tos)
    player:broadcastSkillInvoke(qimei.name)
    local mark = U.getMark(player, "qimei_used-turn")
    table.insertTable(mark, tos)
    room:setPlayerMark(player, "qimei_used-turn", mark)
    for _, pid in ipairs(tos) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:drawCards(p, 1, qimei.name)
      end
    end
  end,
}
local zhuijix = fk.CreateTriggerSkill{
  name = "zhuijix",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"zhuiji_draw-phase"}
    if player:isWounded() then
      table.insert(choices, 1, "zhuiji_recover-phase")
    end
    local choice = room:askForChoice(player, choices, self.name)
    room:addPlayerMark(player, choice, 1)
    if choice == "zhuiji_recover-phase" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    else
      player:drawCards(2, self.name)
    end
  end,
}
local zhuijix_trigger = fk.CreateTriggerSkill{
  name = "#zhuijix_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes("zhuijix", Player.HistoryPhase) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhuijix")
    room:notifySkillInvoked(player, "zhuijix", "negative")
    if player:getMark("zhuiji_recover-phase") > 0 then
      room:setPlayerMark(player, "zhuiji_recover-phase", 0)
      room:askForDiscard(player, 2, 2, true, "zhuijix", false)
    end
    if player:getMark("zhuiji_draw-phase") > 0 then
      room:setPlayerMark(player, "zhuiji_draw-phase", 0)
      room:loseHp(player, 1, "zhuijix")
    end
  end,
}
qimei:addRelatedSkill(qimei_delay)
zhuijix:addRelatedSkill(zhuijix_trigger)
xuangongzhu:addSkill(gaoling)
xuangongzhu:addSkill(qimei)
xuangongzhu:addSkill(zhuijix)
Fk:loadTranslationTable{
  ["xuangongzhu"] = "宣公主",
  ["gaoling"] = "高陵",
  [":gaoling"] = "<font color='red'>隐匿技（暂时无法生效）</font>，当你于其他角色的回合内登场时，你可以令一名角色回复1点体力。",
  ["qimei"] = "齐眉",
  [":qimei"] = "准备阶段，你可以选择一名其他角色，直到你的下个回合开始（每回合每项限一次），当你或该角色的手牌数或体力值变化后，若双方的此数值相等，"..
  "另一方摸一张牌。",
  ["zhuijix"] = "追姬",
  [":zhuijix"] = "出牌阶段开始时，你可以选择一项：1.回复1点体力，并于此阶段结束时弃置两张牌；2.摸两张牌，并于此阶段结束时失去1点体力。",
  ["#qimei-choose"] = "齐眉：指定一名其他角色为“齐眉”角色，双方手牌数或体力值变化后可摸牌",
  ["@@qimei"] = "齐眉",
  ["#qimei_delay"] = "齐眉",
  ["zhuiji_recover-phase"] = "回复1点体力，此阶段结束时弃两张牌",
  ["zhuiji_draw-phase"] = "摸两张牌，此阶段结束时失去1点体力",

  ["$gaoling1"] = "天家贵胄，福泽四海。",
  ["$gaoling2"] = "宣王之女，恩惠八方。",
  ["$qimei1"] = "辅车相依，比翼双飞。",
  ["$qimei2"] = "情投意合，相濡以沫。",
  ["$zhuijix1"] = "不过是些微代价罢了。",
  ["$zhuijix2"] = "哼，以为这就能难倒我吗？",
  ["~xuangongzhu"] = "元凯，我去也……",
}

local wangyuanji = General(extension, "ol__wangyuanji", "jin", 3, 3, General.Female)
local shiren = fk.CreateTriggerSkill{
  name = "shiren",
  can_trigger = Util.FalseFunc,
}
local yanxi = fk.CreateActiveSkill{
  name = "yanxi",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:getNCards(2)
    for i = #cards, 1, -1 do
      table.insert(room.draw_pile, 1, cards[i])
    end
    room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile)
    local id = table.random(target.player_cards[Player.Hand])
    table.insert(cards, id)
    table.shuffle(cards)
    local id2 = room:askForCardChosen(player, target, {
      card_data = {
        { "$Hand", cards }
      }
    }, self.name)
    if id2 ~= id then
      cards = {id2}
    end
    room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, self.name, nil, false, player.id)
  end,
}
local yanxi_refresh = fk.CreateTriggerSkill{
  name = "#yanxi_refresh",

  refresh_events = {fk.AfterCardsMove, fk.AfterTurnEnd},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == yanxi.name then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@yanxi-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.AfterTurnEnd then
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@yanxi-inhand", 0)
      end
    end
  end,
}
local yanxi_maxcards = fk.CreateMaxCardsSkill{
  name = "#yanxi_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@yanxi-inhand") > 0
  end,
}
yanxi:addRelatedSkill(yanxi_refresh)
yanxi:addRelatedSkill(yanxi_maxcards)
wangyuanji:addSkill(shiren)
wangyuanji:addSkill(yanxi)
Fk:loadTranslationTable{
  ["ol__wangyuanji"] = "王元姬",
  ["shiren"] = "识人",
  [":shiren"] = "<font color='red'>隐匿技（暂时无法生效）</font>，你于其他角色的回合登场后，若当前回合角色有手牌，你可以对其发动〖宴戏〗。",
  ["yanxi"] = "宴戏",
  [":yanxi"] = "出牌阶段限一次，你将一名其他角色的随机一张手牌与牌堆顶的两张牌混合后展示，你猜测哪张牌来自其手牌。若猜对，你获得三张牌；"..
  "若猜错，你获得选中的牌。你以此法获得的牌本回合不计入手牌上限。",

  ["@@yanxi-inhand"] = "宴戏",

  ["$shiren1"] = "宠过必乱，不可大任。",
  ["$shiren2"] = "开卷有益，识人有法",
  ["$yanxi1"] = "宴会嬉趣，其乐融融。",
  ["$yanxi2"] = "宴中趣玩，得遇知己。",
  ["~ol__wangyuanji"] = "祖父已逝，哀凄悲戚。",
}

local duyu = General(extension, "ol__duyu", "jin", 4)
local sanchen = fk.CreateActiveSkill{
  name = "sanchen",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("sanchen-turn") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if player:hasSkill("zhaotao", true) and player:usedSkillTimes("zhaotao", Player.HistoryGame) == 0 then
      room:addPlayerMark(player, "@sanchen")
    end
    room:addPlayerMark(target, "sanchen-turn", 1)
    target:drawCards(3, self.name)
    local cards = room:askForDiscard(target, 3, 3, true, self.name, false, ".", "#sanchen-discard:"..player.id)
    if (Fk:getCardById(cards[1]).type ~= Fk:getCardById(cards[2]).type) and
      (Fk:getCardById(cards[1]).type ~= Fk:getCardById(cards[3]).type) and
      (Fk:getCardById(cards[2]).type ~= Fk:getCardById(cards[3]).type) then
      target:drawCards(1, self.name)
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    end
  end,
}
local zhaotao = fk.CreateTriggerSkill{
  name = "zhaotao",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("sanchen", Player.HistoryGame) > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@sanchen", 0)
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "pozhu", nil)
  end,
}
local pozhu = fk.CreateViewAsSkill{
  name = "pozhu",
  anim_type = "offensive",
  pattern = "unexpectation",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("unexpectation")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function (self, player)
    return player:getMark("pozhu-turn") == 0
  end,
}
local pozhu_record = fk.CreateTriggerSkill{
  name = "#pozhu_record",

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "pozhu")
  end,
  on_refresh = function(self, event, target, player, data)
    if not data.damageDealt then
      player.room:addPlayerMark(player, "pozhu-turn", 1)
    end
  end,
}
pozhu:addRelatedSkill(pozhu_record)
duyu:addSkill(sanchen)
duyu:addSkill(zhaotao)
duyu:addRelatedSkill(pozhu)
Fk:loadTranslationTable{
  ["ol__duyu"] = "杜预",
  ["sanchen"] = "三陈",
  [":sanchen"] = "出牌阶段限一次，你可令一名角色摸三张牌然后弃置三张牌。若其以此法弃置的牌种类均不同，则其摸一张牌，且视为本技能未发动过"..
  "（本回合不能再指定其为目标）。",
  ["zhaotao"] = "昭讨",
  [":zhaotao"] = "觉醒技，准备阶段开始时，若你本局游戏发动过至少3次〖三陈〗，你减1点体力上限，获得〖破竹〗。",
  ["pozhu"] = "破竹",
  [":pozhu"] = "出牌阶段，你可将一张手牌当【出其不意】使用，若此【出其不意】未造成伤害，此技能无效直到回合结束。",
  ["#sanchen-discard"] = "三陈：弃置三张牌，若类别各不相同则你摸一张牌且 %src 可以再发动“三陈”",
  ["@sanchen"] = "三陈",

  ["$sanchen1"] = "陈书弼国，当一而再、再而三。	",
  ["$sanchen2"] = "勘除弼事，三陈而就。",
  ["$zhaotao1"] = "奉诏伐吴，定鼎东南！",
  ["$zhaotao2"] = "三陈方得诏，一股下孙吴！",
  ["$pozhu1"] = "攻其不备，摧枯拉朽！",
  ["$pozhu2"] = "势如破竹，铁锁横江亦难挡！",
  ["~ol__duyu"] = "金瓯尚缺，死难瞑目……",
}

local weiguan = General(extension, "weiguan", "jin", 3)
local zhongyun = fk.CreateTriggerSkill{
  name = "zhongyun",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.hp == player:getHandcardNum() and
      player:usedSkillTimes(self.name) == 0 then
      return player:isWounded() or not table.every(player.room:getOtherPlayers(player), function (p)
        return not player:inMyAttackRange(p)
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(room:getOtherPlayers(player), function (p) return not player:inMyAttackRange(p) end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function (p)
        return player:inMyAttackRange(p) end), Util.IdMapper)
      local cancelable = false
      if player:isWounded() then
        cancelable = true
      end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhongyun-damage", self.name, cancelable)
      if #to > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(to[1]),
          damage = 1,
          skillName = self.name,
        }
      else
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}
local zhongyun2 = fk.CreateTriggerSkill{
  name = "#zhongyun2",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.hp == player:getHandcardNum() and player:usedSkillTimes(self.name) == 0 then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand then
          return true
        end
        for _, info in ipairs(move.moveInfo) do
          if move.from == player.id and info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhongyun")
    room:notifySkillInvoked(player, "zhongyun")
    if table.every(room:getOtherPlayers(player), function(p) return p:isNude() end) then
      player:drawCards(1, "zhongyun")
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function (p)
        return not p:isNude() end), Util.IdMapper)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhongyun-discard", "zhongyun", true)
      if #to > 0 then
        local id = room:askForCardChosen(player, room:getPlayerById(to[1]), "he", "zhongyun")
        room:throwCard({id}, "zhongyun", room:getPlayerById(to[1]), player)
      else
        player:drawCards(1, "zhongyun")
      end
    end
  end,
}
local shenpin = fk.CreateTriggerSkill{
  name = "shenpin",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local pattern
    if data.card:getColorString() == "black" then
      pattern = "heart,diamond"
    elseif data.card:getColorString() == "red" then
      pattern = "spade,club"
    else
      return
    end
    local card = player.room:askForResponse(player, self.name, ".|.|"..pattern.."|hand,equip", "#shenpin-invoke::"..target.id, true)
    if card then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(self.cost_data, player, data, self.name, false)
  end,
}
zhongyun:addRelatedSkill(zhongyun2)
weiguan:addSkill(zhongyun)
weiguan:addSkill(shenpin)
Fk:loadTranslationTable{
  ["weiguan"] = "卫瓘",
  ["zhongyun"] = "忠允",
  [":zhongyun"] = "锁定技，每回合各限一次，当你受到伤害或回复体力后，若你的体力值与你的手牌数相等，你回复1点体力或对你攻击范围内的一名角色造成1点伤害；"..
  "当你获得或失去手牌后，若你的体力值与你的手牌数相等，你摸一张牌或弃置一名其他角色的一张牌。",
  ["shenpin"] = "神品",
  [":shenpin"] = "当一名角色的判定牌生效前，你可以打出一张与判定牌颜色不同的牌代替之。",
  ["#zhongyun-damage"] = "忠允：对攻击范围内一名角色造成1点伤害，或点“取消”回复1点体力",
  ["#zhongyun-discard"] = "忠允：弃置一名其他角色的一张牌，或点“取消”摸一张牌",
  ["#shenpin-invoke"] = "神品：你可以打出一张不同颜色的牌代替 %dest 的判定",

  ["$zhongyun1"] = "秉公行事，无所亲疏。",
  ["$zhongyun2"] = "明晰法理，通晓人情。",
  ["$shenpin1"] = "考其遗法，肃若神明。",
  ["$shenpin2"] = "气韵生动，出于天成。",
  ["~weiguan"] = "辞荣善终，不可求……",
}

local zhongyan = General(extension, "zhongyan", "jin", 3, 3, General.Female)
local bolan_skills = {
  --ol official skills
  "quhu", "qiangxi", "qice", "daoshu", "ol_ex__tiaoxin", "qiangwu", "tianyi", "ex__zhiheng", "ex__jieyin", "ex__guose",
  "lijian", "qingnang", "lihun", "mingce", "mizhao", "sanchen", "gongxin", "ex__chuli",
  --sp
  "quji", "dahe", "tanhu",
  --yjcm
  "nos__xuanhuo", "xinzhan", "nos__jujian", "ganlu", "xianzhen", "anxu", "gongqi", "huaiyi", "zhige",
  --ol
  "ziyuan", "lianzhu", "shanxi", "lianji", "jianji", "liehou", "xianbi", "shidu", "yanxi", "xuanbei", "yushen", "bolong", "fuxun",
  --mobile
  "wuyuan", "zhujian", "duansuo", "poxiang", "hannan", "shihe", "wisdom__qiai", "shameng", "zundi", "mobile__shangyi", "yangjie",
  "mou__jushou", "mou__fanjian",
  --overseas
  "os__jimeng", "os__beini", "os__yuejian", "os__waishi", "os__weipo", "os__shangyi",
  --tenyear
  "guolun", "kuiji", "ty__jianji", "caizhuang", "xinyou", "tanbei", "lveming", "ty__songshu", "ty__mouzhu", "libang", "nuchen",
  "weiwu", "ty__qingcheng", "ty__jianshu", "qiangzhiz", "ty__fenglve", "boyan",
  --jsrg
  "js__yizheng", "shelun", "lunshi",
  --offline
  "miaojian", "xuepin", "ofl__shameng",
  --wandian
  "wd__liangce", "wd__kenjian", "wd__zongqin", "wd__suli",
  --tuguo
  "tg__bode",
}
local bolan = fk.CreateTriggerSkill{
  name = "bolan",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = table.simpleClone(bolan_skills)
    for i = #skills, 1, -1 do
      if table.find(room.players, function(p) return p:hasSkill(skills[i], true, true) end) then
        table.removeOne(skills, skills[i])
      end
    end
    if #skills > 0 then
      local choice = room:askForChoice(player, table.random(skills, math.min(3, #skills)), self.name, "#bolan-choice::"..player.id, true)
      room:handleAddLoseSkills(player, choice, nil, true, false)
      room:setPlayerMark(player, self.name, choice)
    end
  end,

  refresh_events = {fk.EventPhaseEnd, fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return target == player and player.phase == Player.Play and player:getMark(self.name) ~= 0
    elseif event == fk.GameStart then
      return player:hasSkill(self, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return target == player and data == self and
        not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill(self, true) end)
    else
      return target == player and player:hasSkill(self, true, true) and
        not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill(self, true) end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      room:handleAddLoseSkills(player, "-"..player:getMark(self.name), nil, true, false)
      room:setPlayerMark(player, self.name, 0)
    elseif event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "bolan&", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player, true, true)) do
        room:handleAddLoseSkills(p, "-bolan&", nil, false, true)
      end
    end
  end,
}
local bolan_active = fk.CreateActiveSkill{
  name = "bolan&",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:hasSkill("bolan", true) then
        target = p
        break
      end
    end
    target:broadcastSkillInvoke("bolan")
    room:notifySkillInvoked(target, "bolan", "special")
    room:doIndicate(player.id, {target.id})
    room:loseHp(player, 1, "bolan")
    if player.dead then return end
    local skills = table.simpleClone(bolan_skills)
    for i = #skills, 1, -1 do
      if table.find(room.players, function(p) return p:hasSkill(skills[i], true, true) end) then
        table.removeOne(skills, skills[i])
      end
    end
    if #skills > 0 then
      local choice = room:askForChoice(target, table.random(skills, math.min(3, #skills)), self.name, "#bolan-choice::"..player.id, true)
      room:handleAddLoseSkills(player, choice, nil, true, false)
      room:setPlayerMark(player, "bolan", choice)
    end
  end,
}
local yifa = fk.CreateTriggerSkill{
  name = "yifa",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events ={fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and data.firstTarget and
      table.contains(AimGroup:getAllTargets(data.tos), player.id) and (data.card.trueName == "slash" or
      (data.card.color == Card.Black and data.card:isCommonTrick()))
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "@yifa", 1)
  end,

  refresh_events ={fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@yifa") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@yifa", 0)
  end,
}
local yifa_maxcards = fk.CreateMaxCardsSkill{
  name = "#yifa_maxcards",
  correct_func = function(self, player)
    return -player:getMark("@yifa")
  end,
}
Fk:addSkill(bolan_active)
yifa:addRelatedSkill(yifa_maxcards)
zhongyan:addSkill(bolan)
zhongyan:addSkill(yifa)
Fk:loadTranslationTable{
  ["zhongyan"] = "钟琰",
  ["bolan"] = "博览",
  [":bolan"] = "出牌阶段开始时，你可以从随机三个“出牌阶段限一次”的技能中选择一个获得直到本阶段结束；其他角色的出牌阶段限一次，其可以失去1点体力，"..
  "令你从随机三个“出牌阶段限一次”的技能中选择一个，其获得之直到此阶段结束。",
  ["yifa"] = "仪法",
  [":yifa"] = "锁定技，当其他角色使用【杀】或黑色普通锦囊牌指定你为目标后，其手牌上限-1直到其回合结束。",
  ["bolan&"] = "博览",
  [":bolan&"] = "出牌阶段限一次，你可以失去1点体力，令钟琰从随机三个“出牌阶段限一次”的技能中选择一个，你获得之直到此阶段结束。",
  ["#bolan-choice"] = "博览：选择令 %dest 此阶段获得技能",
  ["@yifa"] = "仪法",

  ["$bolan1"] = "博览群书，融会贯通。",
  ["$bolan2"] = "博览于文，约之以礼。",
  ["$yifa1"] = "仪法不明，则实不称名。",
  ["$yifa2"] = "仪法明晰，则长治久安。",
  ["~zhongyan"] = "嗟尔姜任，邈不我留。",
}

local xinchang = General(extension, "xinchang", "jin", 3)
local canmou = fk.CreateTriggerSkill{
  name = "canmou",
  anim_type = "control",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.targetGroup and data.firstTarget and data.card:isCommonTrick() and
      table.every(player.room:getOtherPlayers(target), function (p) return target:getHandcardNum() > p:getHandcardNum() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not player:isProhibited(p, data.card) then
        table.insertIfNeed(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#canmou-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if data.card.name == "collateral" then  --TODO:

    else
      TargetGroup:pushTargets(data.targetGroup, self.cost_data)  --TODO: sort by action order
    end
  end,
}
local congjianx = fk.CreateTriggerSkill{
  name = "congjianx",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and data.card:isCommonTrick() and
      data.targetGroup and #AimGroup:getAllTargets(data.tos) == 1 and
      table.every(player.room:getOtherPlayers(target), function (p) return target.hp > p.hp end) and
      not player.room:getPlayerById(data.from):isProhibited(player, data.card)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#congjianx-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    if data.card.name == "collateral" then  --TODO:

    else
      TargetGroup:pushTargets(data.targetGroup, {player.id})
      data.extra_data = data.extra_data or {}
      data.extra_data.congjianx = data.extra_data.congjianx or player.id
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.congjianx and data.extra_data.congjianx == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    if data.damageDealt and data.damageDealt[player.id] then
      player:drawCards(2, self.name)
    end
  end,
}
xinchang:addSkill(canmou)
xinchang:addSkill(congjianx)
Fk:loadTranslationTable{
  ["xinchang"] = "辛敞",
  ["canmou"] = "参谋",
  [":canmou"] = "当手牌数全场唯一最多的角色使用普通锦囊牌指定目标时，你可以为此锦囊牌多指定一个目标。",
  ["congjianx"] = "从鉴",
  [":congjianx"] = "当体力值全场唯一最大的其他角色成为普通锦囊牌的唯一目标时，你可以也成为此牌目标，此牌结算后，若此牌对你造成伤害，你摸两张牌。",
  ["#canmou-choose"] = "参谋：你可以为此%arg多指定一个目标",
  ["#congjianx-invoke"] = "从鉴：你可以成为此%arg的额外目标，若此牌对你造成伤害，你摸两张牌",

  ["$canmou1"] = "兢兢业业，竭心筹划。",
  ["$canmou2"] = "欲设此法，计谋二人。",
  ["$congjianx1"] = "为人臣属，安可不随？",
  ["$congjianx2"] = "主公有难，吾当从之。",
  ["~xinchang"] = "宪英，救我！",
}

local jiachong = General(extension, "ol__jiachong", "jin", 3)
local xiongshu = fk.CreateTriggerSkill{
  name = "xiongshu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Play and
      #player:getCardIds("he") >= player:usedSkillTimes(self.name, Player.HistoryRound) and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:usedSkillTimes(self.name, Player.HistoryRound)
    if n == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#xiongshu-invoke::"..target.id)
    else
      return #player.room:askForDiscard(player, n, n, false, self.name, true, ".", "#xiongshu-cost::"..target.id..":"..n) == n
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    player.tag[self.name] = {id, room:askForChoice(player, {"yes", "no"}, self.name), "no"}
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 then
      if event == fk.AfterCardUseDeclared then
        return target == player.room.current and data.card.trueName == Fk:getCardById(player.tag[self.name][1]).trueName
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      player.tag[self.name][3] = "yes"
    else
      local room = player.room
      --player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "offensive")
      if player.tag[self.name][2] == player.tag[self.name][3] then
        if not target.dead then
          room:damage{
            from = player,
            to = target,
            damage = 1,
            skillName = self.name,
          }
        end
      else
        room:obtainCard(player, player.tag[self.name][1], true, fk.ReasonPrey)
      end
      player.tag[self.name] = {}
    end
  end,
}
local jianhui = fk.CreateTriggerSkill{
  name = "jianhui",
  anim_type = "offensive",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.Damage then
        return player.tag[self.name] and data.to.id == player.tag[self.name]
      else
        return data.from
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      --player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    else
      if player.tag[self.name] and data.from.id == player.tag[self.name] then
        --player:broadcastSkillInvoke(self.name)
        room:notifySkillInvoked(player, self.name, "control")
        if not data.from.dead and not data.from:isNude() then
          room:askForDiscard(data.from, 1, 1, true, self.name, false, ".")
        end
      else
        player.tag[self.name] = data.from.id
      end
    end
  end,
}
jiachong:addSkill(xiongshu)
jiachong:addSkill(jianhui)
Fk:loadTranslationTable{
  ["ol__jiachong"] = "贾充",
  ["xiongshu"] = "凶竖",
  [":xiongshu"] = "其他角色出牌阶段开始时，你可以：弃置X张牌（X为本轮你已发动过本技能的次数），展示其一张手牌，"..
  "你秘密猜测其于此出牌阶段是否会使用与此牌同名的牌。出牌阶段结束时，若你猜对，你对其造成1点伤害；若你猜错，你获得此牌。",
  ["jianhui"] = "奸回",
  [":jianhui"] = "锁定技，你记录上次对你造成伤害的角色。当你对其造成伤害后，你摸一张牌；当其对你造成伤害后，其弃置一张牌。",
  ["#xiongshu-invoke"] = "凶竖：你可以展示 %dest 的一张手牌，猜测其此阶段是否会使用同名牌",
  ["#xiongshu-cost"] = "凶竖：你可以弃置%arg张牌展示 %dest 一张手牌，猜测其此阶段是否会使用同名牌",
  ["yes"] = "是",
  ["no"] = "否",

  ["$xiongshu1"] = "怀志拥权，谁敢不服？",
  ["$xiongshu2"] = "天下凶凶，由我一人。",
  ["$jianhui1"] = "一箭之仇，十年不忘！",
  ["$jianhui2"] = "此仇不报，怨恨难消！",
  ["~ol__jiachong"] = "任元褒，吾与汝势不两立！",
}

local wangxiang = General(extension, "wangxiang", "jin", 3)
local bingxin = fk.CreateViewAsSkill{
  name = "bingxin",
  pattern = "^nullification|.|.|.|.|basic|.",
  interaction = function()
    local names = {}
    local mark = Self:getMark("bingxin-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and
        ((Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local mark = player:getMark("bingxin-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, Fk:cloneCard(self.interaction.data).trueName)
    player.room:setPlayerMark(player, "bingxin-turn", mark)
    player:drawCards(1, self.name)
  end,
  enabled_at_play = function(self, player)
    local cards = player.player_cards[Player.Hand]
    return #cards == player.hp and
      table.every(cards, function(id) return Fk:getCardById(id).color ==Fk:getCardById(cards[1]).color end)
  end,
  enabled_at_response = function(self, player, response)
    local cards = player.player_cards[Player.Hand]
    return not response and #cards == player.hp and
      table.every(cards, function(id) return Fk:getCardById(id).color ==Fk:getCardById(cards[1]).color end)
  end,
}
wangxiang:addSkill(bingxin)
Fk:loadTranslationTable{
  ["wangxiang"] = "王祥",
  ["bingxin"] = "冰心",
  [":bingxin"] = "若你手牌的数量等于体力值且颜色相同，你可以摸一张牌视为使用一张与本回合以此法使用过的牌牌名不同的基本牌。",

  ["$bingxin1"] = "思鸟黄雀至，卧冰鱼自跃。",
  ["$bingxin2"] = "夜静向寒月，卧冰求鲤鱼。",
  ["~wangxiang"] = "夫生之有死，自然之理也。",
}

local yangyan = General(extension, "yangyan", "jin", 3, 3, General.Female)
local xuanbei = fk.CreateActiveSkill{
  name = "xuanbei",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "hej", self.name)
    local card = Fk:cloneCard("slash")
    card:addSubcard(id)
    local use = {
      from = target.id,
      tos = {{player.id}},
      card = card,
      skillName = self.name,
      extraUse = true,
    }
    room:useCard(use)
    if not player.dead then
      if use.damageDealt and use.damageDealt[player.id] then
        player:drawCards(2, self.name)
      else
        player:drawCards(1, self.name)
      end
    end
  end,
}
local xianwan = fk.CreateViewAsSkill{
  name = "xianwan",
  pattern = "slash,jink",
  anim_type = "defensive",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card
    if Self:hasSkill(self) then
      if Self.chained then
        card = Fk:cloneCard("slash")
      else
        card = Fk:cloneCard("jink")
      end
    end
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    if player.chained then
      player:setChainState(false)
    else
      player:setChainState(true)
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
yangyan:addSkill(xuanbei)
yangyan:addSkill(xianwan)
Fk:loadTranslationTable{
  ["yangyan"] = "杨艳",
  ["xuanbei"] = "选备",
  [":xuanbei"] = "出牌阶段限一次，你可以选择一名其他角色区域内的一张牌，令其将此牌当无距离限制的【杀】对你使用，若此【杀】未对你造成伤害，"..
  "你摸一张牌，否则你摸两张牌。",
  ["xianwan"] = "娴婉",
  [":xianwan"] = "你可以横置，视为使用一张【闪】；你可以重置，视为使用一张【杀】。",

  ["$xuanbei1"] = "博选良家，以充后宫。",
  ["$xuanbei2"] = "非良家，不可选也。",
  ["$xianwan1"] = "婉而从物，不竞不争。",
  ["$xianwan2"] = "娴婉恭谨，重贤加礼。",
  ["~yangyan"] = "一旦殂损，痛悼伤怀……",
}

local yangzhi = General(extension, "yangzhi", "jin", 3, 3, General.Female)

local wanyi_select = fk.CreateActiveSkill{
  name = "wanyi_select",
  card_num = 1,
  target_num = 1,
  expand_pile = "wanyi",
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "wanyi"
  end,
}
Fk:addSkill(wanyi_select)
local wanyi = fk.CreateTriggerSkill{
  name = "wanyi",
  anim_type = "control",
  events = {fk.TargetSpecified, fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TargetSpecified then
        if (data.card.trueName ~= "slash" and not data.card:isCommonTrick()) or data.to == player.id then return false end
        local to = player.room:getPlayerById(data.to)
        return U.isOnlyTarget(to, data, event) and not to:isNude()
      elseif #player:getPile("wanyi") > 0 then
        if event == fk.EventPhaseStart then
          return player.phase == Player.Finish
        else
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      local room = player.room
      if room:askForSkillInvoke(player, self.name, nil, "#wanyi-invoke::"..data.to) then
        room:doIndicate(player.id, {data.to})
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local id = room:askForCardChosen(player, room:getPlayerById(data.to), "he", self.name)
      player:addToPile(self.name, id, false, self.name)
    else
      local _, dat = room:askForUseActiveSkill(player, "wanyi_select", "#wanyi-card", false, Util.DummyTable, true)
      if dat then
        room:moveCardTo(dat.cards, Card.PlayerHand, room:getPlayerById(dat.targets[1]), fk.ReasonGive, self.name, nil, true, player.id)
      else
        room:moveCardTo(player:getPile("wanyi")[1], Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, player.id)
      end
    end
  end,
}

--FIXME：本来这个效果是不会被无效的，但是因为失去技能不清牌，故暂时采用hasskill来判定
local wanyi_prohibit = fk.CreateProhibitSkill{
  name = "#wanyi_prohibit",
  prohibit_use = function(self, player, card)
    if player:hasSkill(wanyi, true) and #player:getPile("wanyi") > 0 then
      return table.find(player:getPile("wanyi"), function(id) return Fk:getCardById(id).suit == card.suit end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:hasSkill(wanyi, true) and #player:getPile("wanyi") > 0 then
      return table.find(player:getPile("wanyi"), function(id) return Fk:getCardById(id).suit == card.suit end)
    end
  end,
  prohibit_discard = function(self, player, card)
    if player:hasSkill(wanyi, true) and #player:getPile("wanyi") > 0 then
      return table.find(player:getPile("wanyi"), function(id) return Fk:getCardById(id).suit == card.suit end)
    end
  end,
}
local maihuo = fk.CreateTriggerSkill{
  name = "maihuo",
  anim_type = "defensive",
  events = {fk.TargetConfirmed, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return false end
    if event == fk.TargetConfirmed then
      if data.card.trueName == "slash" and U.isOnlyTarget(player, data, event) and U.isPureCard(data.card) and data.from then
        if (data.extra_data and data.extra_data.maihuo) then return false end
        local from = player.room:getPlayerById(data.from)
        return from ~= nil and not from.dead and #from:getPile("yangzhi_huo") == 0
      end
    elseif event == fk.Damage then
      --FIXME：不清楚埋祸牌是不是绑定角色，先按简单的做
      return data.to and not data.to.dead and #data.to:getPile("yangzhi_huo") > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      if room:askForSkillInvoke(player, self.name, nil, "#maihuo-invoke::"..data.from..":"..data.card:toLogString()) then
        room:doIndicate(player.id, {data.from})
        return true
      end
    elseif event == fk.Damage then
      room:doIndicate(player.id, {data.to.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      table.insertIfNeed(data.nullifiedTargets, player.id)
      if room:getCardArea(data.card) == Card.Processing then
        room:doIndicate(player.id, {data.from})
        local to = room:getPlayerById(data.from)
        to:addToPile("yangzhi_huo", data.card, true, self.name)
        room:setPlayerMark(to, self.name, {player.id, data.card.id})
      end
    elseif event == fk.Damage then
      room:setPlayerMark(data.to, self.name, 0)
      room:moveCards({
        from = data.to.id,
        ids = data.to:getPile("yangzhi_huo"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
      })
    end
  end,
}
local maihuo_delay = fk.CreateTriggerSkill{
  name = "#maihuo_delay",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Play and #player:getPile("yangzhi_huo") > 0 and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("maihuo")[1])
    local card = Fk:getCardById(player:getPile("yangzhi_huo")[1])
    room:setPlayerMark(player, "maihuo", 0)
    if U.canUseCardTo(room, player, to, card, true, true) then
      room:useCard({
        from = player.id,
        tos = {{to.id}},
        card = card,
        extraUse = false,
        extra_data = {maihuo = true},
      })
    else
      room:moveCards({
        from = player.id,
        ids = player:getPile("yangzhi_huo"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = "maihuo",
      })
    end
  end,
}
wanyi:addRelatedSkill(wanyi_prohibit)
maihuo:addRelatedSkill(maihuo_delay)
yangzhi:addSkill(wanyi)
yangzhi:addSkill(maihuo)
Fk:loadTranslationTable{
  ["yangzhi"] = "杨芷",
  ["wanyi"] = "婉嫕",
  [":wanyi"] = "当你使用【杀】或普通锦囊牌指定唯一其他角色为目标后，你可以将其一张牌置于你的武将牌上。"..
  "你不能使用、打出、弃置与“婉嫕”牌花色相同的牌。结束阶段或当你受到伤害后，你令一名角色获得一张“婉嫕”牌。",
  ["maihuo"] = "埋祸",
  [":maihuo"] = "其他角色非因本技能使用的非转化的【杀】指定你为唯一目标后，若其没有“祸”，你可以令此【杀】对你无效并将之置于其武将牌上，称为“祸”，"..
  "其下个出牌阶段开始时对你使用此【杀】（须合法且有次数限制，不合法则移去之）。当你对其他角色造成伤害后，你移去其武将牌上的“祸”。",
  ["#wanyi-invoke"] = "婉嫕：你可以将 %dest 的一张牌置于你的武将牌上",
  ["wanyi_select"] = "婉嫕",
  ["#wanyi-card"] = "婉嫕：令一名角色获得一张“婉嫕”牌",
  ["yangzhi_huo"] = "祸",
  ["#maihuo-invoke"] = "埋祸：你可以令 %dest 对你使用的%arg无效并将之置为其“祸”，延迟到其下个出牌阶段对你使用",
  ["#maihuo_delay"] = "埋祸",

  ["$wanyi1"] = "天性婉嫕，易以道御。",
  ["$wanyi2"] = "婉嫕利珍，为后攸行。",
  ["$maihuo1"] = "祸根未决，转而滋蔓。",
  ["$maihuo2"] = "无德之亲，终为祸根。",
  ["~yangzhi"] = "贾氏……构陷……",
}

local wangyan = General(extension, "wangyan", "jin", 3)
local yangkuang = fk.CreateTriggerSkill{
  name = "yangkuang",
  anim_type = "control",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#yangkuang-invoke"
    if room.current and not room.current.dead then
      prompt = "#yangkuang2-invoke::"..room.current.id
    end
    return room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:useVirtualCard("analeptic", nil, player, player, self.name)
    player:drawCards(1, self.name)
    if room.current and not room.current.dead then
      room.current:drawCards(1, self.name)
    end
  end,
}
local cihuang_active = fk.CreateActiveSkill{
  name = "cihuang_active",
  card_num = 1,
  target_num = 0,
  interaction = function()
    local names = {}
    local mark = Self:getMark("cihuang-round")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if mark == 0 or (not table.contains(mark, card.name)) then
        if Self.phase == Player.NotActive then
          if (card.trueName == "slash" and card.name ~= "slash") or
            (card:isCommonTrick() and card.skill.target_num == 1 and not card.is_derived) then
            table.insertIfNeed(names, card.name)
          end
        else
          if table.contains({"ex_nihilo", "fire_attack", "foresight"}, card.name) then
            table.insertIfNeed(names, card.name)
          end
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(to_select)
    return #selected == 0
  end,
}
local cihuang = fk.CreateTriggerSkill{
  name = "cihuang",
  anim_type = "control",
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.from and player.room:getPlayerById(data.from).phase ~= Player.NotActive and
      data.tos and #data.tos == 1 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local command = "AskForUseActiveSkill"
    room:notifyMoveFocus(player, "cihuang_active")
    local dat = {"cihuang_active", "#cihuang-invoke::"..data.from, true, json.encode({})}
    local result = room:doRequest(player, command, json.encode(dat))
    if result == "" then return false end
    dat = json.decode(result)
    self.cost_data = {
      cards = json.decode(dat.card).subcards,
      interaction_data = dat.interaction_data,
    }
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(self.cost_data.interaction_data)
    card:addSubcards(self.cost_data.cards)
    room:useCard{
      from = player.id,
      tos = {{room.current.id}},
      card = card,
      disresponsiveList = table.map(room.alive_players, Util.IdMapper),
    }
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card.type == Card.TypeTrick)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("cihuang-round")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, data.card.name)
    player.room:setPlayerMark(player, "cihuang-round", mark)
  end,
}
local sanku = fk.CreateTriggerSkill{
  name = "sanku",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying, fk.MaxHpChanged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      return event == fk.EnterDying or (event == fk.MaxHpChanged and data.num > 0)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      room:changeMaxHp(player, -1)
      if not player.dead then
        room:recover({
          who = player,
          num = player.maxHp - player.hp,
          recoverBy = player,
          skillName = self.name
        })
      end
    else
      player.maxHp = player.maxHp - data.num
      room:broadcastProperty(player, "maxHp")  --FIXME: 没有相关时机，此法会触发相关技能（eg威重）
    end
  end,
}
Fk:addSkill(cihuang_active)
wangyan:addSkill(yangkuang)
wangyan:addSkill(cihuang)
wangyan:addSkill(sanku)
Fk:loadTranslationTable{
  ["wangyan"] = "王衍",
  ["yangkuang"] = "阳狂",
  [":yangkuang"] = "当你回复体力至上限后，你可以视为使用一张【酒】并与当前回合角色各摸一张牌。",
  ["cihuang"] = "雌黄",
  [":cihuang"] = "当前回合角色对唯一目标使用的牌被抵消后，你可以将一张牌当一张本轮你未使用过的属性【杀】或单一目标普通锦囊牌对使用者使用且此牌不能被响应。",
  ["sanku"] = "三窟",
  [":sanku"] = "锁定技，当你进入濒死状态时，你减1点体力上限并回复体力至上限；当你的体力上限增加时，你防止之。",
  ["#yangkuang-invoke"] = "阳狂：你可以视为使用【酒】并摸一张牌",
  ["#yangkuang2-invoke"] = "阳狂：你可以视为使用【酒】并与 %dest 各摸一张牌",
  ["#cihuang-invoke"] = "雌黄：选择一张牌，将之当属性【杀】或单目标锦囊对 %dest 使用",
  ["cihuang_active"] = "雌黄",

  ["$yangkuang1"] = "比干忠谏剖心死，箕子披发阳狂生。",
  ["$yangkuang2"] = "梅伯数谏遭炮烙，来革顺志而用国。",
  ["$cihuang1"] = "腹存经典，口吐雌黄。",
  ["$cihuang2"] = "手把玉麈，胸蕴成篇。",
  ["$sanku1"] = "纲常难为，应存后路。",
  ["$sanku2"] = "世将大乱，当思保全。",
  ["~wangyan"] = "影摇枭鸱动，三窟难得生。",
}

local chengjichengcui = General(extension, "chengjichengcui", "wei", 6)
chengjichengcui.subkingdom = "jin"
local tousui = fk.CreateViewAsSkill{
  name = "tousui",
  pattern = "slash",
  prompt = "#tousui-invoke",
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude()
  end,
}
local tousui_trigger = fk.CreateTriggerSkill{
  name = "#tousui_trigger",
  events = {fk.PreCardUse, fk.TargetSpecified},
  mute = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and table.contains(data.card.skillNames, "tousui")
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      player.room:doIndicate(player.id, TargetGroup:getRealTargets(data.tos))
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      local room = player.room
      local cards = room:askForCard(player, 1, 999, true, "tousui", false, ".", "#tousui-card")
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = "tousui",
          drawPilePosition = -1,
        })
        data.extra_data = data.extra_data or {}
        data.extra_data.tousui = #cards
        return false
      else
        return true
      end
    else
      data.fixedResponseTimes = data.fixedResponseTimes or {}
      data.fixedResponseTimes["jink"] = data.extra_data.tousui
    end
  end,
}
local chuming = fk.CreateTriggerSkill{
  name = "chuming",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if event ~= fk.TurnEnd then
      if target == player and player:hasSkill(self) then
        if event == fk.DamageCaused then
          return data.to ~= player
        else
          return data.from and data.from ~= player
        end
      end
    else
      return player:getMark("chuming-turn") ~= 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event ~= fk.TurnEnd then
      if not data.card or #Card:getIdList(data.card) == 0 then
        if event == fk.DamageCaused then
          player:broadcastSkillInvoke(self.name, 2)
          room:notifySkillInvoked(player, self.name, "offensive")
        else
          player:broadcastSkillInvoke(self.name, 1)
          room:notifySkillInvoked(player, self.name, "negative")
        end
        data.damage = data.damage + 1
      else
        player:broadcastSkillInvoke(self.name)
        room:notifySkillInvoked(player, self.name, "negative")
        local p
        if event == fk.DamageCaused then
          p = data.to.id
        else
          p = data.from.id
        end
        local mark = player:getMark("chuming-turn")
        if mark == 0 then mark = {} end
        table.insert(mark, {p, Card:getIdList(data.card)})
        room:setPlayerMark(player, "chuming-turn", mark)
      end
    else
      local infos = table.simpleClone(player:getMark("chuming-turn"))
      for _, info in ipairs(infos) do
        if player.dead then return end
        local p = room:getPlayerById(info[1])
        if not p.dead and table.every(info[2], function(id) return room:getCardArea(id) == Card.DiscardPile end) then
          room:setPlayerMark(p, "chuming-tmp", {player.id, info[2]})
          local command = "AskForUseActiveSkill"
          room:notifyMoveFocus(p, "chuming_viewas")
          local dat = {"chuming_viewas", "#chuming-invoke::"..player.id, false, json.encode({})}
          local result = room:doRequest(p, command, json.encode(dat))
          if result ~= "" then
            dat = json.decode(result)
            if dat.interaction_data == "collateral" then
              local card = Fk:cloneCard("collateral")
              card:addSubcards(info[2])
              card.skillName = self.name
              local use = {
                from = p.id,
                tos = {{player.id}, {dat.targets[1]}},
                card = card,
              }
              room:useCard(use)
            else
              room:useVirtualCard(dat.interaction_data, info[2], p, player, self.name)
            end
          end
        end
      end
    end
  end,
}
local chuming_viewas = fk.CreateActiveSkill{
  name = "chuming_viewas",
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = function()
    local names = {}
    local mark = Self:getMark("chuming-tmp")
    for _, name in ipairs({"collateral", "dismantlement"}) do
      local card = Fk:cloneCard(name)
      if card.skill:targetFilter(mark[1], {}, {}, card) and not Self:isProhibited(Fk:currentRoom():getPlayerById(mark[1]), card) then
        table.insert(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if self.interaction.data == "collateral" then
      if #selected == 0 then
        local room = Fk:currentRoom()
        return room:getPlayerById(Self:getMark("chuming-tmp")[1]):inMyAttackRange(room:getPlayerById(to_select))
      end
    else
      return false
    end
  end,
  feasible = function (self, selected, selected_cards)
    if self.interaction.data == "collateral" then
      return #selected == 1
    else
      return #selected == 0
    end
  end,
}
tousui:addRelatedSkill(tousui_trigger)
Fk:addSkill(chuming_viewas)
chengjichengcui:addSkill(tousui)
chengjichengcui:addSkill(chuming)
Fk:loadTranslationTable{
  ["chengjichengcui"] = "成济成倅",
  ["tousui"] = "透髓",
  [":tousui"] = "你可以将任意张牌置于牌堆底，视为使用一张需要等量张【闪】抵消的【杀】。",
  ["chuming"] = "畜鸣",
  [":chuming"] = "锁定技，当你对其他角色造成伤害或受到其他角色造成的伤害时，若此伤害：没有对应的实体牌，此伤害+1；有对应的实体牌，"..
  "其本回合结束时将造成伤害的牌当【借刀杀人】或【过河拆桥】对你使用。",
  ["#tousui-invoke"] = "透髓：选择【杀】的目标，然后将任意张牌置于牌堆底",
  ["#tousui-card"] = "透髓：将任意张牌置于牌堆底，按选牌的顺序放置",
  ["chuming_viewas"] = "畜鸣",
  ["#chuming-invoke"] = "畜鸣：选择对 %dest 使用的牌（若使用【借刀杀人】则再选择被杀的角色）",

  ["$tousui1"] = "区区黄口孺帝，能有何作为？",
  ["$tousui2"] = "昔年沙场茹血，今欲饮帝血！",
  ["$chuming1"] = "明公为何如此待我兄弟？",
  ["$chuming2"] = "栖佳木之良禽，其鸣亦哀乎？",
  ["~chengjichengcui"] = "今为贼子贾充所害！",
}

return extension
