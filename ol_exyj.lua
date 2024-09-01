local extension = Package("ol_exyj")
extension.extensionName = "ol"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_exyj"] = "OL-界一将成名",
}

local caozhi = General(extension, "ol_ex__caozhi", "wei", 3)
local ol_ex__jiushi = fk.CreateViewAsSkill{
  name = "ol_ex__jiushi",
  anim_type = "support",
  pattern = "analeptic",
  prompt = "#ol_ex__jiushi",
  card_filter = Util.FalseFunc,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self)
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function (self, player)
    return player.faceup
  end,
  enabled_at_response = function (self, player, response)
    return player.faceup and not response
  end,
}
local ol_ex__jiushi_trigger = fk.CreateTriggerSkill{
  name = "#ol_ex__jiushi_trigger",
  mute = true,
  main_skill = ol_ex__jiushi,
  events = {fk.Damaged, fk.AfterCardsMove, fk.PreCardUse},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ol_ex__jiushi) and not player.faceup then
      if event == fk.Damaged then
        return target == player and (data.extra_data or {}).ol_ex__jiushi_check and not player.faceup
      elseif event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.skillName == "luoying" and move.to == player.id then
            if player:getMark("@ol_ex__jiushi_count") >= player.maxHp then
              return true
            end
          end
        end
      elseif event == fk.PreCardUse then
        return target == player and data.card:getMark("@@luoying-inhand") > 0 and
          (data.card.trueName == "slash" or data.card:isCommonTrick())
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      return true
    else
      return player.room:askForSkillInvoke(player, "ol_ex__jiushi")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ol_ex__jiushi")
    if event == fk.PreCardUse then
      room:notifySkillInvoked(player, "ol_ex__jiushi", "offensive")
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    else
      room:notifySkillInvoked(player, "ol_ex__jiushi", "defensive")
      player:turnOver()
    end
  end,

  refresh_events = {fk.DamageInflicted, fk.AfterCardsMove, fk.TurnedOver, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(ol_ex__jiushi, true) then
      if not player.faceup then
        if event == fk.DamageInflicted then
          return target == player
        elseif event == fk.AfterCardsMove then
          for _, move in ipairs(data) do
            if move.skillName == "luoying" and move.to == player.id and player.phase == Player.NotActive then
              return true
            end
          end
        end
      end
    end
    if player:getMark("@ol_ex__jiushi_count") > 0 then
      if event == fk.TurnedOver then
        return player.faceup
      elseif event == fk.EventLoseSkill then
        return target == player and data == self
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      data.extra_data = data.extra_data or {}
      data.extra_data.ol_ex__jiushi_check = true
    elseif event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.skillName == "luoying" and move.to == player.id then
          room:addPlayerMark(player, "@ol_ex__jiushi_count", #move.moveInfo)
        end
      end
    elseif event == fk.TurnedOver or event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@ol_ex__jiushi_count", 0)
    end
  end,
}
local ol_ex__jiushi_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__jiushi_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(ol_ex__jiushi) and not player.faceup and card:getMark("@@luoying-inhand") > 0
  end,
}
ol_ex__jiushi:addRelatedSkill(ol_ex__jiushi_trigger)
ol_ex__jiushi:addRelatedSkill(ol_ex__jiushi_targetmod)
caozhi:addSkill("luoying")
caozhi:addSkill(ol_ex__jiushi)
Fk:loadTranslationTable{
  ["ol_ex__caozhi"] = "界曹植",
  ["#ol_ex__caozhi"] = "才高八斗",
  --["designer:ol_ex__caozhi"] = "",
  --["illustrator:ol_ex__caozhi"] = "",

  ["ol_ex__jiushi"] = "酒诗",
  [":ol_ex__jiushi"] = "若你的武将牌正面朝上，你可以翻面视为使用一张【酒】。若你的武将牌背面朝上，你使用“落英”牌无距离限制且不可被响应。"..
  "当你受到伤害时或当你于回合外发动〖落英〗累计获得至少X张牌后（X为你的体力上限），若你的武将牌背面朝上，你可以翻至正面。",
  ["#ol_ex__jiushi_targetmod"] = "酒诗",
  ["#ol_ex__jiushi"] = "酒诗：你可以翻面，视为使用一张【酒】",
  ["@ol_ex__jiushi_count"] = "酒诗",
}

local zhangchunhua = General(extension, "ol_ex__zhangchunhua", "wei", 3, 3, General.Female)
local jianmie = fk.CreateActiveSkill{
  name = "jianmie",
  anim_type = "offensive",
  prompt = "#jianmie",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    local choices = {"red", "black"}
    player.request_data = json.encode({choices, choices, self.name, "#jianmie-choice::"..target.id})
    target.request_data = json.encode({choices, choices, self.name, "#jianmie-choice::"..player.id})
    room:notifyMoveFocus({player, target}, self.name)
    room:doBroadcastRequest("AskForChoice", {player, target})
    for _, p in ipairs({player, target}) do
      local choice
      if p.reply_ready then
        choice = p.client_reply
      else
        local color = table.random(choices)
        p.client_reply = color
        choice = color
      end
      room:sendLog{
        type = "#jianmie-quest",
        from = p.id,
        arg = choice,
      }
    end
    local cards1 = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getColorString() == player.client_reply
    end)
    local cards2 = table.filter(target:getCardIds("h"), function (id)
      return Fk:getCardById(id):getColorString() == target.client_reply
    end)
    local moves = {}
    if #cards1 > 0 then
      table.insert(moves, {
        ids = cards1,
        from = player.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player.id,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moves, {
        ids = cards2,
        from = target.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = target.id,
        skillName = self.name,
      })
    end
    room:moveCards(table.unpack(moves))
    local src, to = player, player
    if #cards1 > #cards2 then
      src, to = player, target
    elseif #cards1 < #cards2 then
      src, to = target, player
    end
    if src ~= to and not to.dead then
      room:useVirtualCard("duel", nil, src, to, self.name)
    end
  end,
}
zhangchunhua:addSkill(jianmie)
zhangchunhua:addSkill("jueqing")
zhangchunhua:addSkill("shangshi")
Fk:loadTranslationTable{
  ["ol_ex__zhangchunhua"] = "界张春华",
  ["#ol_ex__zhangchunhua"] = "冷血皇后",
  --["designer:ol_ex__zhangchunhua"] = "",
  --["illustrator:ol_ex__zhangchunhua"] = "",

  ["jianmie"] = "翦灭",
  [":jianmie"] = "出牌阶段限一次，你可以选择一名其他角色，你与其同时选择一种颜色，弃置所有各自选择颜色的手牌，然后弃置牌数较多的角色视为对"..
  "另一名角色使用【决斗】。",
  ["#jianmie"] = "翦灭：与一名角色同时选择一种颜色的手牌弃置，弃牌数多的角色视为对对方使用【决斗】",
  ["#jianmie-choice"] = "翦灭：与 %dest 同时选择一种颜色的手牌弃置，弃牌数多的角色视为对对方使用【决斗】",
  ["#jianmie-quest"] = "%from 选择弃置 %arg 手牌",
}

local fazheng = General(extension, "ol_ex__fazheng", "shu", 3)
local ol_ex__xuanhuo = fk.CreateTriggerSkill{
  name = "ol_ex__xuanhuo",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw and player:getHandcardNum() > 1 and
      #player.room.alive_players > 1
  end,
  on_cost = function(self, event, target, player, data)
    local _, dat = player.room:askForUseActiveSkill(player, "ol_ex__xuanhuo_choose", "#ol_ex__xuanhuo-invoke", true)
    if dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.targets[1])
    room:moveCardTo(self.cost_data.cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if to.dead then return end
    local victim = room:getPlayerById(self.cost_data.targets[2])
    local use = room:askForUseCard(to, "slash", nil, "#ol_ex__xuanhuo-use:"..player.id..":"..victim.id, nil,
      {must_targets = {victim.id}, bypass_times = true, bypass_distances = true})
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      if player.dead or to.dead or to:isNude() then return end
      local cards = U.askforChooseCardsAndChoice(player, to:getCardIds("he"), {"OK"}, self.name,
        "#ol_ex__xuanhuo-prey::"..to.id, {}, math.min(#to:getCardIds("he"), 2), 2)
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, self.name, nil, false)
    end
  end,
}
local ol_ex__xuanhuo_choose = fk.CreateActiveSkill{
  name = "ol_ex__xuanhuo_choose",
  card_num = 2,
  target_num = 2,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, cards)
    if #cards == 2 then
      return #selected == 0 and to_select ~= Self.id or #selected == 1
    end
  end,
}
local ol_ex__enyuan = fk.CreateTriggerSkill{
  name = "ol_ex__enyuan",
  mute = true,
  anim_type = "masochism",
  events = {fk.AfterCardsMove, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player.id and move.to == player.id and move.toArea == Card.PlayerHand and #move.moveInfo > 1 then
          self.cost_data = move.from
          return true
        end
      end
    elseif target == player and data.from and not data.from.dead and not player.dead then
      self.cost_data = data.from.id
      return true
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.Damaged then
      self.cancel_cost = false
      for i = 1, data.damage do
        if self.cancel_cost or player.dead or player.room:getPlayerById(self.cost_data).dead then
          break
        end
        self:doCost(event, target, player, {self.cost_data})
      end
    else
      self:doCost(event, target, player, {self.cost_data})
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#ol_ex__enyuan"
    if event == fk.Damaged then
      prompt = prompt.."2-invoke::"..data[1]
    else
      prompt = prompt.."1-invoke::"..data[1]
    end
    if player.room:askForSkillInvoke(player, self.name, data, prompt) then
      self.cost_data = data[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:doIndicate(player.id, {self.cost_data})
    if event ==  fk.AfterCardsMove then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "support")
      to:drawCards(1, self.name)
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name)
      local card = room:askForCard(to, 1, 1, false, self.name, true, ".|.|heart,diamond|hand|.|.", "#ol_ex__enyuan-give:"..player.id)
      if #card > 0 then
        room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, self.name, nil, false)
      else
        room:loseHp(to, 1, self.name)
      end
    end
  end,
}
Fk:addSkill(ol_ex__xuanhuo_choose)
fazheng:addSkill(ol_ex__xuanhuo)
fazheng:addSkill(ol_ex__enyuan)
Fk:loadTranslationTable{
  ["ol_ex__fazheng"] = "界法正",
  ["#ol_ex__fazheng"] = "蜀汉的辅翼",
  --["designer:ol_ex__fazheng"] = "玄蝶既白",
  --["illustrator:ol_ex__fazheng"] = "君桓文化",

  ["ol_ex__xuanhuo"] = "眩惑",
  [":ol_ex__xuanhuo"] = "摸牌阶段结束时，你可以交给一名其他角色两张牌，令其选择一项：1.对你指定的另一名角色使用一张【杀】；2.你观看其手牌并"..
  "获得其两张牌。",
  ["ol_ex__enyuan"] = "恩怨",
  [":ol_ex__enyuan"] = "当你获得一名其他角色至少两张牌后，你可以令其摸一张牌。当你受到1点伤害后，你可以令伤害来源选择一项：1.交给你一张红色手牌；"..
  "2.失去1点体力。",

  ["ol_ex__xuanhuo_choose"] = "眩惑",
  ["#ol_ex__xuanhuo-invoke"] = "眩惑：交给第一名角色两张手牌，令其选择对第二名角色使用【杀】或你获得其两张牌",
  ["#ol_ex__xuanhuo-use"] = "眩惑：你需对 %dest 使用一张【杀】，否则 %src 观看你手牌并获得你两张牌",
  ["#ol_ex__xuanhuo-prey"] = "眩惑：获得 %dest 两张牌",
  ["#ol_ex__enyuan1-invoke"] = "恩怨：是否令 %dest 摸一张牌？",
  ["#ol_ex__enyuan2-invoke"] = "恩怨：是否令 %dest 选择交给你牌或失去体力？",
  ["#ol_ex__enyuan-give"] = "交给 %src 一张红色手牌，否则你失去1点体力",

  ["$ol_ex__xuanhuo1"] = "眩惑之术，非为迷惑，乃为明辨贤愚。",
  ["$ol_ex__xuanhuo2"] = "以眩惑试人心，以真情待贤才，方能得天下。",
  ["$ol_ex__enyuan1"] = "恩重如山，必报之以雷霆之势！",
  ["$ol_ex__enyuan2"] = "怨深似海，必还之以烈火之怒！",
  ["~ol_ex__fazheng"] = "孝直不忠，不能佑主公复汉室了……",
}

local lingtong = General(extension, "ol_ex__lingtong", "wu", 4)
local ol_ex__xuanfeng = fk.CreateTriggerSkill{
  name = "ol_ex__xuanfeng",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          local n = 0
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              n = n + 1
            elseif info.fromArea == Card.PlayerEquip then
              n = 2
            end
          end
          if n > 1 then
            return table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    while player.room:askForSkillInvoke(player, self.name) do
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xuanfeng-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(player, to, "he", self.name)
    room:throwCard({card}, self.name, to, player)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper)
    if #targets == 0 or player.dead then return end
    to = room:askForChoosePlayers(player, targets, 1, 1, "#xuanfeng-choose", self.name, true)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard({card}, self.name, to, player)
    end
  end,
}
lingtong:addSkill(ol_ex__xuanfeng)
Fk:loadTranslationTable{
  ["ol_ex__lingtong"] = "界凌统",
  ["#ol_ex__lingtong"] = "豪情烈胆",
  ["designer:ol_ex__lingtong"] = "玄蝶既白",
  ["illustrator:ol_ex__lingtong"] = "君桓文化",

  ["ol_ex__xuanfeng"] = "旋风",
  [":ol_ex__xuanfeng"] = "当你失去装备区里的牌后，或一次性失去至少两张牌后，你可以依次弃置至多两名其他角色共计至多两张牌。",

  ["$ol_ex__xuanfeng1"] = "短兵相接，让敌人丢盔弃甲！",
  ["$ol_ex__xuanfeng2"] = "攻敌不备，看他们闻风而逃！",
  ["~ol_ex__lingtong"] = "先……停一下吧……",
}

local wuguotai = General(extension, "ol_ex__wuguotai", "wu", 3, 3, General.Female)
local ol_ex__ganlu = fk.CreateActiveSkill{
  name = "ol_ex__ganlu",
  anim_type = "control",
  target_num = 2,
  min_card_num = 0,
  prompt = function(self, selected_cards, selected_targets)
    if #selected_targets < 2 then
      return "#ol_ex__ganlu0:::"..Self:getLostHp()
    else
      local n1 = #Fk:currentRoom():getPlayerById(selected_targets[1]):getCardIds("e")
      local n2 = #Fk:currentRoom():getPlayerById(selected_targets[2]):getCardIds("e")
      if math.abs(n1 - n2) <= Self:getLostHp() then
        return "#ol_ex__ganlu1:"..selected_targets[1]..":"..selected_targets[2]
      else
        return "#ol_ex__ganlu2:"..selected_targets[1]..":"..selected_targets[2]..":"..math.abs(n1 - n2)
      end
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, to_select, selected, selected_targets)
    return not Self:prohibitDiscard(to_select) and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return not (#Fk:currentRoom():getPlayerById(to_select):getCardIds("e") == 0 and
        #Fk:currentRoom():getPlayerById(selected[1]):getCardIds("e") == 0)
    else
      return false
    end
  end,
  feasible = function (self, selected, selected_cards)
    if #selected == 2 then
      local n1 = #Fk:currentRoom():getPlayerById(selected[1]):getCardIds("e")
      local n2 = #Fk:currentRoom():getPlayerById(selected[2]):getCardIds("e")
      if math.abs(n1 - n2) <= Self:getLostHp() then
        return #selected_cards == 0
      else
        return #selected_cards == math.abs(n1 - n2)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if #effect.cards > 0 then
      room:throwCard(effect.cards, self.name, player, player)
    end
    local target1 = room:getPlayerById(effect.tos[1])
    local target2 = room:getPlayerById(effect.tos[2])
    if target1.dead or target2.dead then return end
    local cards1 = table.clone(target1:getCardIds("e"))
    local cards2 = table.clone(target2:getCardIds("e"))
    U.swapCards(room, player, target1, target2, cards1, cards2, self.name, Card.PlayerEquip)
  end,
}
local ol_ex__buyi = fk.CreateTriggerSkill{
  name = "ol_ex__buyi",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#ol_ex__buyi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local id = room:askForCardChosen(player, target, "he", self.name)
    if table.contains(target:getCardIds("h"), id) then
      target:showCards({id})
    end
    if target.dead then return end
    if Fk:getCardById(id).type ~= Card.TypeBasic then
      room:throwCard({id}, self.name, target, target)
      if not target.dead and target:isWounded() then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    end
  end,
}
wuguotai:addSkill(ol_ex__ganlu)
wuguotai:addSkill(ol_ex__buyi)
Fk:loadTranslationTable{
  ["ol_ex__wuguotai"] = "界吴国太",
  ["#ol_ex__wuguotai"] = "武烈皇后",
  --["designer:ol_ex__wuguotai"] = "",
  --["illustrator:ol_ex__wuguotai"] = "",

  ["ol_ex__ganlu"] = "甘露",
  [":ol_ex__ganlu"] = "出牌阶段限一次，你可以令两名角色交换装备区里的牌。若X大于你已损失体力值，你须先弃置X张手牌。（X为其装备区牌数之差）",
  ["ol_ex__buyi"] = "补益",
  [":ol_ex__buyi"] = "当一名角色进入濒死状态时，你可以选择其一张牌，若此牌不为基本牌，其弃置此牌，然后回复1点体力。",
  ["#ol_ex__ganlu0"] = "甘露：令两名角色交换装备区里的牌，若牌数之差大于%arg，须先弃置手牌",
  ["#ol_ex__ganlu1"] = "甘露：令 %src 和 %dest 交换装备区里的牌",
  ["#ol_ex__ganlu2"] = "甘露：弃置%arg张手牌，令 %src 和 %dest 交换装备区里的牌",
  ["#ol_ex__buyi-invoke"] = "补益：选择 %dest 的一张牌，若为非基本牌，其弃置之并回复1点体力",
}

-- yj2012
local ol_ex__caozhang = General(extension, "ol_ex__caozhang", "wei", 4)
local ol_ex__jiangchi_select = fk.CreateActiveSkill{
  name = "ol_ex__jiangchi_select",
  target_num = 0,
  max_card_num = 1,
  min_card_num = 0,
  interaction = function()
    return UI.ComboBox {choices = {"ol_ex__jiangchi1", "ol_ex__jiangchi2"}}
  end,
  card_filter = function(self, to_select, selected)
    return (self.interaction or {}).data == "ol_ex__jiangchi2" and #selected == 0
  end,
}
local ol_ex__jiangchi = fk.CreateTriggerSkill{
  name = "ol_ex__jiangchi",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "ol_ex__jiangchi_select", "#ol_ex__jiangchi-invoke", true)
    if ret then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name, 2)
      room:recastCard(self.cost_data, player, self.name)
      room:addPlayerMark(player, "ol_ex__jiangchi_plus-turn")
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name, 1)
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "ol_ex__jiangchi_minus-turn")
    end
  end,
}
local ol_ex__jiangchi_targetmod = fk.CreateTargetModSkill{
  name = "#ol_ex__jiangchi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      local n = 0
      if player:getMark("ol_ex__jiangchi_plus-turn") > 0 then
        n = n + 1
      end
      if player:getMark("ol_ex__jiangchi_minus-turn") > 0 then
        n = n - 1
      end
      return n
    end
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return skill.trueName == "slash_skill" and player:getMark("ol_ex__jiangchi_plus-turn") > 0
  end,
}
local ol_ex__jiangchi_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol_ex__jiangchi_maxcards",
  exclude_from = function(self, player, card)
    return card and card.trueName == "slash" and player:getMark("ol_ex__jiangchi_minus-turn") > 0
  end,
}
Fk:addSkill(ol_ex__jiangchi_select)
ol_ex__jiangchi:addRelatedSkill(ol_ex__jiangchi_targetmod)
ol_ex__jiangchi:addRelatedSkill(ol_ex__jiangchi_maxcards)
ol_ex__caozhang:addSkill(ol_ex__jiangchi)

Fk:loadTranslationTable{
  ["ol_ex__caozhang"] = "界曹彰",
  ["#ol_ex__caozhang"] = "黄须儿",
  ["designer:ol_ex__caozhang"] = "玄蝶既白",
  ["illustrator:ol_ex__caozhang"] = "枭瞳",
  ["ol_ex__jiangchi"] = "将驰",
  [":ol_ex__jiangchi"] = "摸牌阶段结束时，你可以选择一项：1.摸一张牌，本回合使用【杀】的次数上限-1，且【杀】不计入手牌上限；2.重铸一张牌，本回合使用【杀】无距离限制且次数上限+1。",
  ["#ol_ex__jiangchi-invoke"] = "1.摸一张牌，【杀】次数-1，不计入手牌上限；2.重铸一张牌，【杀】次数+1，无距离限制",
  ["ol_ex__jiangchi_select"] = "将驰",
  ["ol_ex__jiangchi1"] = "摸牌，少用【杀】",
  ["ol_ex__jiangchi2"] = "重铸，多用【杀】",
  ["$ol_ex__jiangchi1"] = "丈夫当将十万骑驰沙漠，立功建号耳。",
  ["$ol_ex__jiangchi2"] = "披坚执锐，临危不难，身先士卒。",
  ["~ol_ex__caozhang"] = "黄须儿，愧对父亲……",
}

local wangyi = General(extension, "ol_ex__wangyi", "wei", 3, 3, General.Female)
local miji = fk.CreateTriggerSkill{
  name = "ol_ex__miji",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and player:isWounded() and
    (target == player or player:getMark("@@ol_ex__zhenlie-turn") > 0)
  end,
  on_cost = function(self, event, target, player, data)
    if target == player then
      return player.room:askForSkillInvoke(player, self.name)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getLostHp()
    room:drawCards(player, n, self.name)
    if player.dead or player:isNude() then return false end
    n = player:getLostHp()
    if n > 0 then
      U.askForDistribution(player, player:getCardIds("he"), room:getOtherPlayers(player, false), self.name, 0, n)
    end
  end,
}
local zhenlie = fk.CreateTriggerSkill{
  name = "ol_ex__zhenlie",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#ol_ex__zhenlie-invoke:" .. data.from .. "::" .. data.card:toLogString()) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if player.dead then return false end
    table.insertIfNeed(data.nullifiedTargets, player.id)
    local choices = {}
    local to = room:getPlayerById(data.from)
    if not (to.dead or to:isNude()) then
      table.insert(choices, "ol_ex__zhenlie_prey")
    end
    if player:isWounded() and player:hasSkill(miji, true) then
      table.insert(choices, "ol_ex__zhenlie_miji")
    end
    if #choices == 0 then return false end
    local choice = room:askForChoice(player, choices, self.name, "", false, {"ol_ex__zhenlie_prey", "ol_ex__zhenlie_miji"})
    if choice == "ol_ex__zhenlie_prey" then
      local id = room:askForCardChosen(player, to, "he", self.name)
      room:obtainCard(player.id, id, false, fk.ReasonPrey, player.id)
    elseif choice == "ol_ex__zhenlie_miji" then
      room:setPlayerMark(player, "@@ol_ex__zhenlie-turn", 1)
    end
  end,
}
wangyi:addSkill(zhenlie)
wangyi:addSkill(miji)
Fk:loadTranslationTable{
  ["ol_ex__wangyi"] = "界王异",
  ["#ol_ex__wangyi"] = "决意的巾帼",
  --["designer:ol_ex__wangyi"] = "",
  --["illustrator:ol_ex__wangyi"] = "",
  ["ol_ex__zhenlie"] = "贞烈",
  [":ol_ex__zhenlie"] = "当你成为【杀】或普通锦囊牌的目标后，若使用者不为你，你可以失去1点体力，令此牌对你无效，"..
  "你选择：1.获得使用者的一张牌；2.于当前回合（你的回合除外）的结束阶段发动〖秘计〗。",
  ["ol_ex__miji"] = "秘计",
  [":ol_ex__miji"] = "结束阶段，若你已受伤，你可以摸X张牌，然后可以将至多X张牌交给其他角色。（X为你已损失的体力值）",
  ["#ol_ex__zhenlie-invoke"] = "是否对%src发动 贞烈，令其使用的%arg对你无效",
  ["ol_ex__zhenlie_prey"] = "获得使用者的一张牌",
  ["ol_ex__zhenlie_miji"] = "于结束阶段发动〖秘计〗",
  ["@@ol_ex__zhenlie-turn"] = "贞烈",

  ["$ol_ex__zhenlie1"] = "",
  ["$ol_ex__zhenlie2"] = "",
  ["$ol_ex__miji1"] = "",
  ["$ol_ex__miji2"] = "",
  ["~ol_ex__wangyi"] = "",
}

local chengpu = General(extension, "ol_ex__chengpu", "wu", 4)
local ol_ex__lihuo = fk.CreateTriggerSkill{
  name = "ol_ex__lihuo",
  anim_type = "offensive",
  events = {fk.AfterCardUseDeclared, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.AfterCardUseDeclared then
        return data.card.trueName == "slash" and data.card.name ~= "fire__slash"
      elseif event == fk.AfterCardTargetDeclared then
        return data.card.name == "fire__slash" and #U.getUseExtraTargets(player.room, data) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player.room:askForSkillInvoke(player, self.name, nil, "#ol_ex__lihuo-invoke:::"..data.card:toLogString())
    elseif event == fk.AfterCardTargetDeclared then
      local tos = player.room:askForChoosePlayers(player, U.getUseExtraTargets(player.room, data), 1, 1,
        "#lihuo-choose:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      local card = Fk:cloneCard("fire__slash", data.card.suit, data.card.number)
      for k, v in pairs(data.card) do
        if card[k] == nil then
          card[k] = v
        end
      end
      if data.card:isVirtual() then
        card.subcards = data.card.subcards
      else
        card.id = data.card.id
      end
      card.skillNames = data.card.skillNames
      data.card = card
      data.extra_data = data.extra_data or {}
      data.extra_data.ol_ex__lihuo = data.extra_data.ol_ex__lihuo or {}
      table.insert(data.extra_data.ol_ex__lihuo, player.id)
    elseif event == fk.AfterCardTargetDeclared then
      table.insert(data.tos, self.cost_data)
    end
  end,
}
local ol_ex__lihuo_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__lihuo_delay",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.damageDealt and data.extra_data and data.extra_data.ol_ex__lihuo and
    table.contains(data.extra_data.ol_ex__lihuo, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askForDiscard(player, 1, 1, true, "ol_ex__lihuo", true, ".", "#ol_ex__lihuo-discard") == 0 then
      room:loseHp(player, 1, "ol_ex__lihuo")
    end
  end,
}
local ol_ex__chunlao = fk.CreateTriggerSkill{
  name = "ol_ex__chunlao",
  anim_type = "support",
  derived_piles = "ol_ex__chengpu_chun",
  events = {fk.AfterCardsMove, fk.AskForPeaches, fk.HpLost},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        local cards = {}
        local room = player.room
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            if move.moveReason == fk.ReasonDiscard and move.from and
              (move.from == player.id or move.from == player:getNextAlive().id or move.from == player:getLastAlive().id) then
              for _, info in ipairs(move.moveInfo) do
                if Fk:getCardById(info.cardId).trueName == "slash" and room:getCardArea(info.cardId) == Card.DiscardPile then
                  table.insertIfNeed(cards, info.cardId)
                end
              end
            end
          end
        end
        cards = U.moveCardsHoldingAreaCheck(room, cards)
        if #cards > 0 then
          self.cost_data = cards
          return true
        end
      elseif event == fk.AskForPeaches then
        return target.dying and #player:getPile("ol_ex__chengpu_chun") > 0
      elseif event == fk.HpLost then
        return #player:getPile("ol_ex__chengpu_chun") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return true
    elseif event == fk.AskForPeaches then
      local cards = player.room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|ol_ex__chengpu_chun|.|.",
        "#ol_ex__chunlao-invoke::"..target.id, "ol_ex__chengpu_chun")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    elseif event == fk.HpLost then
      local cards = player.room:askForCard(player, 1, 2, false, self.name, true, ".|.|.|ol_ex__chengpu_chun|.|.",
        "#ol_ex__chunlao-prey", "ol_ex__chengpu_chun")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      player:addToPile("ol_ex__chengpu_chun", self.cost_data, true, self.name, player.id)
    elseif event == fk.AskForPeaches then
      room:moveCardTo(self.cost_data, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
      if not target.dead then
        room:useCard({
          card = Fk:cloneCard("analeptic"),
          from = target.id,
          tos = {{target.id}},
          extra_data = {analepticRecover = true},
          skillName = self.name,
        })
      end
    elseif event == fk.HpLost then
      room:moveCardTo(self.cost_data, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end,
}
ol_ex__lihuo:addRelatedSkill(ol_ex__lihuo_delay)
chengpu:addSkill(ol_ex__lihuo)
chengpu:addSkill(ol_ex__chunlao)
Fk:loadTranslationTable{
  ["ol_ex__chengpu"] = "界程普",
  ["#ol_ex__chengpu"] = "三朝虎臣",
  --["designer:ol_ex__chengpu"] = "",
  --["illustrator:ol_ex__chengpu"] = "",
  ["ol_ex__lihuo"] = "疬火",
  [":ol_ex__lihuo"] = "你使用非火【杀】可以改为火【杀】，此牌结算后，若造成了伤害，你弃置一张牌或失去1点体力。你使用火【杀】时可以增加一个目标。",
  ["ol_ex__chunlao"] = "醇醪",
  [":ol_ex__chunlao"] = "你或你相邻角色的【杀】因弃置进入弃牌堆后，将之置为“醇”。当一名角色处于濒死状态时，你可以将一张“醇”置入弃牌堆，"..
  "视为该角色使用一张【酒】。当一名角色失去体力后，你可以获得至多两张“醇”。",
  ["#ol_ex__lihuo-invoke"] = "疬火：是否将%arg改为火【杀】？",
  ["#ol_ex__lihuo-discard"] = "疬火：弃置一张牌，否则你失去1点体力",
  ["#ol_ex__lihuo_delay"] = "疬火",
  ["ol_ex__chengpu_chun"] = "醇",
  ["#ol_ex__chunlao-invoke"] = "醇醪：你可以将一张“醇”置入弃牌堆，视为 %dest 使用一张【酒】",
  ["#ol_ex__chunlao-prey"] = "醇醪：你可以获得至多两张“醇”",
}

local liubiao = General(extension, "ol_ex__liubiao", "qun", 3)
local ol_ex__zishou = fk.CreateTriggerSkill{
  name = "ol_ex__zishou",
  anim_type = "drawcard",
  events = {fk.DrawNCards, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DrawNCards then
        return player:hasSkill(self)
      else
        return player.phase == Player.Finish and
          player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 and
          #player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
            local damage = e.data[1]
            return damage.from and damage.from == target and damage.to ~= target
          end, Player.HistoryTurn) > 0
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.DrawNCards then
      return player.room:askForSkillInvoke(player, self.name)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    if event == fk.DrawNCards then
      data.n = data.n + #kingdoms
    else
      player.room:askForDiscard(player, #kingdoms, #kingdoms, true, self.name, false)
    end
  end,
}
local ol_ex__zongshi = fk.CreateTriggerSkill{
  name = "ol_ex__zongshi",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= player and
      not table.contains(U.getMark(player, "@ol_ex__zongshi"), data.from.kingdom)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "@ol_ex__zongshi")
    table.insert(mark, data.from.kingdom)
    room:setPlayerMark(player, "@ol_ex__zongshi", mark)
    if not data.from.dead then
      room:doIndicate(player.id, {data.from.id})
      data.from:drawCards(1, self.name)
    end
    return true
  end,
}
local ol_ex__zongshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#ol_ex__zongshi_maxcards",
  main_skill = ol_ex__zongshi,
  correct_func = function(self, player)
    if player:hasSkill(ol_ex__zongshi) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms
    else
      return 0
    end
  end,
}
ol_ex__zongshi:addRelatedSkill(ol_ex__zongshi_maxcards)
liubiao:addSkill(ol_ex__zishou)
liubiao:addSkill(ol_ex__zongshi)
Fk:loadTranslationTable{
  ["ol_ex__liubiao"] = "界刘表",
  ["#ol_ex__liubiao"] = "跨蹈汉南",
  --["designer:ol_ex__liubiao"] = "",
  --["illustrator:ol_ex__liubiao"] = "",

  ["ol_ex__zishou"] = "自守",
  [":ol_ex__zishou"] = "摸牌阶段，你可以多摸X张牌，若如此做，本回合结束阶段，若你本回合对其他角色造成过伤害，你弃置X张牌（X为全场势力数）。",
  ["ol_ex__zongshi"] = "宗室",
  [":ol_ex__zongshi"] = "锁定技，你的手牌上限+X（X为全场势力数）。其他角色对你造成伤害时，防止此伤害并令其摸一张牌，每个势力限一次。",
  ["@ol_ex__zongshi"] = "宗室",

  ["$ol_ex__zishou1"] = "",
  ["$ol_ex__zishou2"] = "",
  ["$ol_ex__zongshi1"] = "",
  ["$ol_ex__zongshi2"] = "",
  ["~ol_ex__liubiao"] = "",
}

-- yj2013
local caochong = General(extension, "ol_ex__caochong", "wei", 3)
local ol_ex__chengxiang = fk.CreateTriggerSkill{
  name = "ol_ex__chengxiang",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for _ = 1, data.damage do
      if self.cancel_cost or not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 4
    if player:getMark(self.name) > 0 then
      num = 5
      room:setPlayerMark(player, self.name, 0)
    end
    local cards = room:getNCards(num)
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    local get = room:askForArrangeCards(player, self.name, {cards},
      "#chengxiang-choose", false, 0, {num, num}, {0, 1}, ".", "chengxiang_count", {{}, {cards[1]}})[2]
    local n = 0
    for _, id in ipairs(get) do
      n = n + Fk:getCardById(id).number
    end
    if n == 13 then
      room:setPlayerMark(player, self.name, 1)
    end
    room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, self.name, "", true, player.id)
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end
}
local ol_ex__renxin = fk.CreateTriggerSkill{
  name = "ol_ex__renxin",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|.|.|equip",
      "#ol_ex__renxin-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if not player.dead then
      player:turnOver()
    end
    if not target.dead and target:isWounded() and target.hp < 1 then
      room:recover{
        who = target,
        num = 1 - target.hp,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
caochong:addSkill(ol_ex__chengxiang)
caochong:addSkill(ol_ex__renxin)
Fk:loadTranslationTable{
  ["ol_ex__caochong"] = "界曹冲",
  ["#ol_ex__caochong"] = "仁爱的神童",
  --["designer:ol_ex__caochong"] = "",
  --["illustrator:ol_ex__caochong"] = "",

  ["ol_ex__chengxiang"] = "称象",
  [":ol_ex__chengxiang"] = "当你受到1点伤害后，你可以亮出牌堆顶四张牌，获得其中任意张数量点数之和不大于13的牌，将其余的牌置入弃牌堆。"..
  "若获得的牌点数之和恰好为13，你下次发动〖称象〗时多亮出一张牌。",
  ["ol_ex__renxin"] = "仁心",
  [":ol_ex__renxin"] = "当一名其他角色进入濒死状态时，你可以弃置一张装备牌并翻面，然后令其回复至1点体力。",
  ["#ol_ex__renxin-invoke"] = "仁心：你可以弃置一张装备牌并翻面，令 %dest 回复至1点体力",
}

local yufan = General(extension, "ol_ex__yufan", "wu", 3)
local zongxuan = fk.CreateTriggerSkill{
  name = "ol_ex__zongxuan",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local cards1, cards2 = {}, {}
      local room = player.room
      local last_player_id = 0
      local last_player
      local mark = 0
      local move_event = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
      if not player:isRemoved() then
        last_player = player:getLastAlive(false)
        if last_player ~= player and move_event ~= nil then
          mark = last_player:getMark("ol_ex__zongxuan_record-turn")
          if mark == 0 or mark == move_event.id then
            last_player_id = last_player.id
          end
        end
      end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(cards1, info.cardId)
              end
            end
          elseif move.from == last_player_id then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(cards2, info.cardId)
              end
            end
          end
        end
      end
      cards1 = U.moveCardsHoldingAreaCheck(room, cards1)
      if #cards2 > 0 then
        if mark == 0 then
          room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
            for _, move in ipairs(e.data) do
              if move.from == last_player_id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard and
              table.find(move.moveInfo, function (info)
                return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
              end) then
                mark = e.id
                room:setPlayerMark(last_player, "ol_ex__zongxuan_record-turn", mark)
                return true
              end
            end
            return false
          end, Player.HistoryTurn)
          if mark ~= move_event.id then
            cards2 = {}
          end
        end
      end
      if #cards2 > 0 then
        table.insertTable(cards1, U.moveCardsHoldingAreaCheck(room, cards2))
      end
      if #cards1 > 0 then
        self.cost_data = cards1
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local top = room:askForArrangeCards(player, self.name, {self.cost_data, "pile_discard","Top"},
    "#ol_ex__zongxuan-invoke", true, 7, nil, {0, 1})[2]
    room:sendLog{
      type = "#PutKnownCardtoDrawPile",
      from = player.id,
      card = top
    }
    top = table.reverse(top)
    room:moveCards({
      ids = top,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      proposer = player.id,
      moveVisible = true,
    })
  end,
}
local zhiyan = fk.CreateTriggerSkill{
  name = "ol_ex__zhiyan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and (target == player or target:getNextAlive() == player) and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#ol_ex__zhiyan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local ids = to:drawCards(1, self.name)
    if #ids == 0 then return false end
    local id = ids[1]
    if room:getCardOwner(id) ~= to or room:getCardArea(id) ~= Card.PlayerHand then return false end
    local card = Fk:getCardById(id)
    to:showCards(card)
    if to.dead then return false end
    room:delay(1000)
    if card.type == Card.TypeEquip then
      if to:canUseTo(card, to) then
        room:useCard({
          from = to.id,
          tos = {{to.id}},
          card = card,
        })
        if to:isWounded() and not to.dead then
          room:recover({
            who = to,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      end
    elseif to.hp ~= player.hp then
      room:loseHp(to, 1, self.name)
    end
  end,
}
yufan:addSkill(zongxuan)
yufan:addSkill(zhiyan)
Fk:loadTranslationTable{
  ["ol_ex__yufan"] = "界虞翻",
  ["#ol_ex__yufan"] = "狂直之士",
  --["designer:ol_ex__yufan"] = "",
  ["illustrator:ol_ex__yufan"] = "YanBai",
  ["ol_ex__zongxuan"] = "纵玄",
  [":ol_ex__zongxuan"] = "当你的牌因弃置而置入弃牌堆后，或你上家的牌于当前回合内第一次因弃置而置入弃牌堆后，"..
  "你可以将其中任意张牌置于牌堆顶。",
  ["ol_ex__zhiyan"] = "直言",
  [":ol_ex__zhiyan"] = "你或你上家的结束阶段，你可以令一名角色摸一张牌并展示之，若此牌：为装备牌，其使用此牌并回复1点体力；"..
  "不为装备牌且其体力值不等于你，其失去1点体力。",

  ["#ol_ex__zongxuan-invoke"] = "纵玄：将任意数量的弃牌置于牌堆顶",
  ["#ol_ex__zhiyan-choose"] = "是否发动 直言，令一名角色摸一张牌",
  ["#PutKnownCardtoDrawPile"] = "%from 将 %card 置于牌堆顶",

  ["$ol_ex__zongxuan1"] = "",
  ["$ol_ex__zongxuan2"] = "",
  ["$ol_ex__zhiyan1"] = "",
  ["$ol_ex__zhiyan2"] = "",
  ["~ol_ex__yufan"] = "",
}

local ol_ex__jianyong = General(extension, "ol_ex__jianyong", "shu", 3)
local ol_ex__qiaoshui = fk.CreateActiveSkill{
  name = "ol_ex__qiaoshui",
  anim_type = "control",
  prompt = "#ol_ex__qiaoshui-prompt",
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("ol_ex__qiaoshui_fail-turn") == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke("m_ex__qiaoshui")
    local to = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({to}, self.name)
    if player.dead then return end
    if pindian.results[to.id].winner == player then
      room:setPlayerMark(player, "@@ol_ex__qiaoshui-turn", 1)
    else
      room:setPlayerMark(player, "ol_ex__qiaoshui_fail-turn", 1)
    end
  end,
}
local ol_ex__qiaoshui_delay = fk.CreateTriggerSkill{
  name = "#ol_ex__qiaoshui_delay",
  events = {fk.AfterCardTargetDeclared},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@ol_ex__qiaoshui-turn") > 0
    and data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ol_ex__qiaoshui-turn", 0)
    local targets = U.getUseExtraTargets(room, data, true)
    if #TargetGroup:getRealTargets(data.tos) > 1 then
      table.insertTable(targets, TargetGroup:getRealTargets(data.tos))
    end
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ol_ex__qiaoshui-choose:::"
    ..data.card:toLogString(), ol_ex__qiaoshui.name, true)
    if #tos == 0 then return false end
    if table.contains(TargetGroup:getRealTargets(data.tos), tos[1]) then
      TargetGroup:removeTarget(data.tos, tos[1])
      room:sendLog{ type = "#RemoveTargetsBySkill", from = target.id, to = tos, arg = ol_ex__qiaoshui.name, arg2 = data.card:toLogString() }
    else
      table.insert(data.tos, tos)
      room:sendLog{ type = "#AddTargetsBySkill", from = target.id, to = tos, arg = ol_ex__qiaoshui.name, arg2 = data.card:toLogString() }
    end
  end,
}
ol_ex__qiaoshui:addRelatedSkill(ol_ex__qiaoshui_delay)
local ol_ex__qiaoshui_prohibit = fk.CreateProhibitSkill{
  name = "#ol_ex__qiaoshui_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("ol_ex__qiaoshui_fail-turn") > 0 and card and card.type == Card.TypeTrick
  end,
}
ol_ex__qiaoshui:addRelatedSkill(ol_ex__qiaoshui_prohibit)
ol_ex__jianyong:addSkill(ol_ex__qiaoshui)
ol_ex__jianyong:addSkill("zongshij")
Fk:loadTranslationTable{
  ["ol_ex__jianyong"] = "界简雍",
  ["#ol_ex__jianyong"] = "悠游风议",

  ["ol_ex__qiaoshui"] = "巧说",
  [":ol_ex__qiaoshui"] = "出牌阶段，你可以与一名角色拼点。若你赢，本回合你使用下一张基本牌或普通锦囊牌可以多或少选择一个目标（无距离限制）；若你没赢，此技能失效且你不能使用锦囊牌直到回合结束。",
  ["#ol_ex__qiaoshui-choose"] = "巧说：你可以为%arg增加/减少一个目标",
  ["@@ol_ex__qiaoshui-turn"] = "巧说",
  ["#ol_ex__qiaoshui-prompt"] = "巧说:与一名角色拼点，若赢，下一张基本牌或普通锦囊牌可增加或取消一个目标",
}

local liru = General(extension, "ol_ex__liru", "qun", 3)
local ol_ex__mieji = fk.CreateActiveSkill{
  name = "ol_ex__mieji",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  prompt = "#ol_ex__mieji",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeTrick
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      moveVisible = true,
      drawPilePosition = 1,
    })
    local ids = room:askForDiscard(target, 1, 1, true, self.name, false, ".", "#ol_ex__mieji-discard1")
    if #ids > 0 and Fk:getCardById(ids[1]).type ~= Card.TypeTrick and not target.dead then
      room:askForDiscard(target, 1, 1, true, self.name, false, ".", "#ol_ex__mieji-discard2")
    end
  end,
}
liru:addSkill("juece")
liru:addSkill(ol_ex__mieji)
liru:addSkill("ty_ex__fencheng")
Fk:loadTranslationTable{
  ["ol_ex__liru"] = "界李儒",
  ["#ol_ex__liru"] = "魔仕",
  --["designer:ol_ex__caochong"] = "",
  --["illustrator:ol_ex__caochong"] = "",

  ["ol_ex__mieji"] = "灭计",
  [":ol_ex__mieji"] = "出牌阶段限一次，你可以将一张锦囊牌置于牌堆顶并令一名有手牌的其他角色选择一项：1.弃置一张锦囊牌；2.依次弃置两张牌。",
  ["ol_ex__fencheng"] = "焚城",
  [":ol_ex__fencheng"] = "限定技，出牌阶段，你可以选择一名其他角色开始，所有其他角色依次选择一项：1.弃置任意张牌（须比上家弃置的牌多）；2.受到"..
  "你造成的2点火焰伤害。",
  ["#ol_ex__mieji"] = "灭计：将一张锦囊牌置于牌堆顶，令一名角色弃一张锦囊牌或弃置两张牌",
  ["#ol_ex__mieji-discard1"] = "灭计：请弃置一张锦囊牌，或依次弃置两张牌",
  ["#ol_ex__mieji-discard2"] = "灭计：请再弃置一张牌",
}

-- yj2014
local ol_ex__caifuren = General(extension, "ol_ex__caifuren", "qun", 3, 3, General.Female)
local ol_ex__qieting = fk.CreateTriggerSkill{
  name = "ol_ex__qieting",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      return #U.getActualDamageEvents(room, 1, function (e)
        local damage = e.data[1]
        return damage.from == target and damage.to ~= target
      end, nil, turn_event.id) == 0 or #U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == target.id and use.tos then
          if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
            return true
          end
        end
        return false
      end, turn_event.id) == 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    local all_choices = {"ol_ex__qieting_move::"..target.id, "draw1", "Cancel"}
    local choices = table.simpleClone(all_choices)
    if not target:canMoveCardsInBoardTo(player, "e") then
      table.remove(choices, 1)
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#ol_ex__qieting-invoke", false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"ol_ex__qieting_move::"..target.id, "draw1", "Cancel"}
    if self.cost_data == "draw1" then
      player:drawCards(1, self.name)
      if player.dead or target.dead or not target:canMoveCardsInBoardTo(player, "e") then return false end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      if #U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == target.id and use.tos then
          if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
            return true
          end
        end
        return false
      end, turn_event.id) == 0 then
        if room:askForChoice(player, {"ol_ex__qieting_move::"..target.id, "Cancel"}, self.name, "#ol_ex__qieting-invoke",
        false, all_choices) ~= "Cancel" then
          room:askForMoveCardInBoard(player, target, player, self.name, "e", target)
        end
      end
    else
      room:askForMoveCardInBoard(player, target, player, self.name, "e", target)
      if player.dead then return false end
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      if #U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == target.id and use.tos then
          if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
            return true
          end
        end
        return false
      end, turn_event.id) == 0 then
        if room:askForChoice(player, {"draw1", "Cancel"}, self.name, "#ol_ex__qieting-invoke", false, all_choices) == "draw1" then
          player:drawCards(1, self.name)
        end
      end
    end
  end,
}
ol_ex__caifuren:addSkill(ol_ex__qieting)
ol_ex__caifuren:addSkill("xianzhou")  --辣鸡策划真摆
Fk:loadTranslationTable{
  ["ol_ex__caifuren"] = "界蔡夫人",
  ["#ol_ex__caifuren"] = "襄江的蒲苇",

  ["ol_ex__qieting"] = "窃听",
  [":ol_ex__qieting"] = "其他角色的回合结束后，若其于此回合内未对其以外的角色造成过伤害或未对其以外的角色使用过牌，你可以选择："..
  "1.将其装备区的一张牌置入你的装备区；2.摸一张牌。若其于此回合内未对其以外的角色使用过牌，你可以执行另一项。",
  ["#ol_ex__qieting-invoke"] = "你可以发动 窃听，选择一项效果执行",
  ["ol_ex__qieting_move"] = "将%dest一张装备移动给你",

  ["$ol_ex__qieting1"] = "好你个刘玄德，敢坏我儿大事。",
  ["$ol_ex__qieting2"] = "两个大男人窃窃私语，定没有好事。",
  ["$xianzhou_ol_ex__caifuren1"] = "今献州以降，请丞相善待我孤儿寡母。",
  ["$xianzhou_ol_ex__caifuren2"] = "我儿志短才疏，只求方寸之地安享富贵。",
  ["~ol_ex__caifuren"] = "这哪里是荆州，分明是黄泉……",
}




return extension
