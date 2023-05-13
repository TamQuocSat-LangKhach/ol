local extension = Package("ol_sp2")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_sp2"] = "OL专属2",
  ["jin"] = "晋",
}

Fk:loadTranslationTable{
  ["ol__simayi"] = "司马懿",
  ["buchen"] = "不臣",
  [":buchen"] = "隐匿技，你于其他角色的回合登场后，你可获得其一张牌。",
  ["yingshi"] = "鹰视",
  [":yingshi"] = "锁定技，出牌阶段内，牌堆顶的X张牌对你可见（X为你的体力上限）。",
  ["xiongzhi"] = "雄志",
  [":xiongzhi"] = "限定技，出牌阶段，你可展示牌堆顶牌并使用之。你可重复此流程直到牌堆顶牌不能被使用。",
  ["quanbian"] = "权变",
  [":quanbian"] = "当你于出牌阶段首次使用或打出一种花色的手牌时，你可从牌堆顶X张牌中获得一张与此牌花色不同的牌，将其余牌以任意顺序置于牌堆顶。出牌阶段，你至多使用X张非装备手牌。（X为你的体力上限）",
}

local zhangchunhua = General(extension, "ol__zhangchunhua", "jin", 3, 3, General.Female)
local huishi = fk.CreateTriggerSkill{
  name = "huishi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#huishi-invoke:::"..#player.room.draw_pile % 10)
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
    })
    return true
  end,
}
local qingleng = fk.CreateTriggerSkill{
  name = "qingleng",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Finish and
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
zhangchunhua:addSkill(huishi)
zhangchunhua:addSkill(qingleng)
Fk:loadTranslationTable{
  ["ol__zhangchunhua"] = "张春华",
  ["xuanmu"] = "宣穆",
  [":xuanmu"] = "锁定技，隐匿技，你于其他角色的回合登场时，防止你受到的伤害直到回合结束。",
  ["huishi"] = "慧识",
  [":huishi"] = "摸牌阶段，你可以放弃摸牌，改为观看牌堆顶的X张牌，获得其中的一半（向下取整），然后将其余牌置入牌堆底。（X为牌堆数量的个位数）",
  ["qingleng"] = "清冷",
  [":qingleng"] = "其他角色回合结束时，若其体力值与手牌数之和不小于X，你可将一张牌当无距离限制的冰【杀】对其使用。你对一名没有成为过〖清冷〗目标的角色发动〖清冷〗时，摸一张牌。（X为牌堆数量的个位数）",
  ["#huishi-invoke"] = "慧识：你可以放弃摸牌，改为观看牌堆顶%arg张牌并获得其中的一半，其余置于牌堆底",
  ["#qingleng-invoke"] = "清冷：你可以将一张牌当冰【杀】对 %dest 使用",
}

local simashi = General(extension, "ol__simashi", "jin", 3, 4)
local yimie = fk.CreateTriggerSkill{
  name = "yimie",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 and data.to.hp >= data.damage
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    self.yimie_num = data.to.hp - data.damage
    data.damage = data.to.hp
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true, true) and player:usedSkillTimes(self.name) > 0 and not data.to.dead and self.yimie_num > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:recover({
      who = data.to,
      num = self.yimie_num,
      recoverBy = player,
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
    if target == player and player:hasSkill(self.name) then
      if player.phase == Player.Finish then
        player.room:setPlayerMark(player, "tairan_hp", 0)
        player.room:setPlayerMark(player, "tairan_cards", 0)
        return player:isWounded() or #player.player_cards[Player.Hand] < player.maxHp
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
      if #player.player_cards[Player.Hand] < player.maxHp then
        local cards = player:drawCards(player.maxHp - #player.player_cards[Player.Hand], self.name)
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
simashi:addSkill(yimie)
simashi:addSkill(tairan)
Fk:loadTranslationTable{
  ["ol__simashi"] = "司马师",
  ["taoyin"] = "韬隐",
  [":taoyin"] = "隐匿技，你于其他角色的回合登场后，你可以令其本回合的手牌上限-2。",
  ["yimie"] = "夷灭",
  [":yimie"] = "每回合限一次，当你对一名其他角色造成伤害时，你可失去1点体力，令此伤害值+X（X为其体力值减去伤害值）。伤害结算后，其回复X点体力。",
  ["tairan"] = "泰然",
  [":tairan"] = "锁定技，回合结束时，你回复体力至体力上限，将手牌摸至体力上限；出牌阶段开始时，你失去上回合以此法回复的体力值，弃置以此法获得的手牌。",
  ["ruilve"] = "睿略",
  [":ruilve"] = "主公技，其他晋势力角色的出牌阶段限一次，该角色可以将一张【杀】或伤害锦囊牌交给你。",
}

local xiahouhui = General(extension, "xiahouhui", "jin", 3, 3, General.Female)
local yishi = fk.CreateTriggerSkill{
  name = "yishi",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason == fk.ReasonDiscard and player.room:getPlayerById(move.from).phase == Player.Play and
          not player.room:getPlayerById(move.from).dead and player:usedSkillTimes(self.name) == 0 then
          self.cost_data = move.from
          player.tag[self.name] = {}
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and player.room:getCardArea(info.cardId) == Card.DiscardPile or player.room:getCardArea(info.cardId) == Card.Processing then
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
  card_filter = function(self, to_select, selected)
    return false
  end,
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
xiahouhui:addSkill(yishi)
xiahouhui:addSkill(shidu)
Fk:loadTranslationTable{
  ["xiahouhui"] = "夏侯徽",
  ["baoqie"] = "宝箧",
  [":baoqie"] = "隐匿技，锁定技，当你登场后，你从牌堆或弃牌堆获得一张宝物牌，然后你可以使用之。",
  ["yishi"] = "宜室",
  [":yishi"] = "每回合限一次，当一名其他角色于其出牌阶段弃置手牌后，你可以令其获得其中的一张牌，然后你获得其余的牌。",
  ["shidu"] = "识度",
  [":shidu"] = "出牌阶段限一次，你可以与一名其他角色拼点，若你赢，你获得其所有手牌，然后你交给其你的一半手牌（向下取整）。",
  ["#yishi-invoke"] = "宜室：你可以令 %dest 收回一张弃置的牌，你获得其余的牌",
  ["#shidu-give"] = "识度：你需交还%arg张手牌",
}

Fk:loadTranslationTable{
  ["ol__simazhao"] = "司马昭",
  ["tuishi"] = "推弑",
  [":shiren"] = "隐匿技，若你于其他角色的回合登场，此回合结束时，你可令其对其攻击范围内你选择的一名角色使用【杀】，若其未使用【杀】，你对其造成1点伤害。",
  ["choufa"] = "筹伐",
  [":choufa"] = "出牌阶段限一次，你可展示一名其他角色的一张手牌，其手牌中与此牌不同类型的牌均视为【杀】直到其回合结束。",
  ["zhaoran"] = "昭然",
  [":zhaoran"] = "出牌阶段开始时，你可令你的手牌对所有角色可见直到此阶段结束。若如此做，你于出牌阶段失去任意花色的最后一张手牌时，摸一张牌或弃置一名其他角色的一张牌。（每种花色限一次）",
  ["chengwu"] = "成务",
  [":chengwu"] = "主公技，锁定技，其他晋势力角色攻击范围内的角色均视为在你的攻击范围内。",
}

Fk:loadTranslationTable{
  ["ol__wangyuanji"] = "王元姬",
  ["shiren"] = "识人",
  [":shiren"] = "隐匿技，你于其他角色的回合登场后，若当前回合角色有手牌，你可以对其发动〖宴戏〗。",
  ["yanxi"] = "宴戏",
  [":yanxi"] = "出牌阶段限一次，你令一名其他角色的随机一张手牌与牌堆顶的两张牌混合后展示，你猜测哪张牌来自其手牌。若猜对，你获得三张牌；若猜错，你获得选中的牌。你以此法获得的牌本回合不计入手牌上限。",
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
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("sanchen-turn") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
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
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("sanchen", Player.HistoryGame) > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "pozhu")
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "pozhu")
    else
      if not data.card.extra_data or not table.contains(data.card.extra_data, "pozhu") then
        player.room:addPlayerMark(player, "pozhu-turn", 1)
      end
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
  [":sanchen"] = "出牌阶段限一次，你可令一名角色摸三张牌，然后弃置三张牌。若其以此法弃置的牌种类均不同，则其摸一张牌，并视为该技能未发动过（本回合不能再指定其为目标）。",
  ["zhaotao"] = "昭讨",
  [":zhaotao"] = "觉醒技，准备阶段开始时，若你本局游戏发动过至少3次〖三陈〗，你减1点体力上限，获得〖破竹〗。",
  ["pozhu"] = "破竹",
  [":pozhu"] = "出牌阶段，你可将一张手牌当【出其不意】使用，若此【出其不意】未造成伤害，此技能无效直到回合结束。",
  ["#sanchen-discard"] = "三陈：弃置三张牌，若类别各不相同则你摸一张牌且 %src 可以再发动“三陈”",
}

local zhanghuyuechen = General(extension, "zhanghuyuechen", "jin", 4)
local xijue = fk.CreateTriggerSkill{
  name = "xijue",
  anim_type = "offensive",
  events = {fk.GameStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        return target == player and player:getMark(self.name) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
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
    return target == player and player:hasSkill(self.name, true) and player.phase ~= Player.NotActive
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
    return (target == player and player:hasSkill(self.name) and data.n > 0 and player:getMark("@zhanghuyuechen_jue") > 0 and
      not table.every(player.room:getOtherPlayers(player), function (p) return p:isKongcheng() end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), function (p) return p.id end)
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
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Finish and
      not player:isKongcheng() and player:getMark("@zhanghuyuechen_jue") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, false, "xiaoguo", true, ".|.|.|.|.|basic", "#xijue_xiaoguo-invoke::"..target.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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
  ["#xijue_xiaoguo"] = "骁果",
}

local zhangling = General(extension, "zhangling", "qun", 4)
local huqi = fk.CreateTriggerSkill{
  name = "huqi",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive and data.from and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|heart,diamond",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      room:useVirtualCard("slash", nil, player, data.from, self.name, false)
    end
  end,
}
local huqi_distance = fk.CreateDistanceSkill{
  name = "#huqi_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      return -1
    end
  end,
}
local shoufu = fk.CreateActiveSkill{
  name = "shoufu",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:drawCards(1)
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p:getPile("zhangling_lu") == 0 then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to, id = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".|.|.|hand|.|.", "#shoufu-cost", self.name, false)
    room:getPlayerById(to[1]):addToPile("zhangling_lu", id, true, self.name)
  end,
}
local shoufu_prohibit = fk.CreateProhibitSkill{
  name = "#shoufu_prohibit",
  prohibit_use = function(self, player, card)
    if #player:getPile("zhangling_lu") > 0 then
      return card.type == Fk:getCardById(player:getPile("zhangling_lu")[1]).type
    end
  end,
  prohibit_response = function(self, player, card)
    if #player:getPile("zhangling_lu") > 0 then
      return card.type == Fk:getCardById(player:getPile("zhangling_lu")[1]).type
    end
  end,
}
local shoufu_record = fk.CreateTriggerSkill{
  name = "#shoufu_record",

  refresh_events = {fk.Damaged, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if #player:getPile("zhangling_lu") > 0 then
      if event == fk.Damaged then
        return target == player
      else
        if player.phase == Player.Discard then
          local n = 0
          for _, move in ipairs(data) do
            if move.from == player.id and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if Fk:getCardById(info.cardId).type == Fk:getCardById(player:getPile("zhangling_lu")[1]).type then
                  n = n + 1
                end
              end
            end
          end
          if n > 0 then
            player.room:addPlayerMark(player, "shoufu", n)
          end
          if player:getMark("shoufu") > 1 then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "shoufu", 0)
    room:moveCards({
      from = player.id,
      ids = player:getPile("zhangling_lu"),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = "shoufu",
      specialName = "zhangling_lu",
    })
    player:removeCards(Player.Special, player:getPile("zhangling_lu"), "zhangling_lu")
  end,
}
huqi:addRelatedSkill(huqi_distance)
shoufu:addRelatedSkill(shoufu_prohibit)
shoufu:addRelatedSkill(shoufu_record)
zhangling:addSkill(huqi)
zhangling:addSkill(shoufu)
Fk:loadTranslationTable{
  ["zhangling"] = "张陵",
  ["huqi"] = "虎骑",
  [":huqi"] = "锁定技，你计算与其他角色的距离-1；当你于回合外受到伤害后，你进行判定，若结果为红色，视为你对伤害来源使用一张【杀】（无距离限制）。",
  ["shoufu"] = "授符",
  [":shoufu"] = "出牌阶段限一次，你可摸一张牌，然后将一张手牌置于一名没有“箓”的角色的武将牌上，称为“箓”；其不能使用和打出与“箓”同类型的牌。该角色受伤时，或于弃牌阶段弃置至少两张与“箓”同类型的牌后，将“箓”置入弃牌堆。",
  ["zhangling_lu"] = "箓",
  ["#shoufu-cost"] = "授符：选择角色并将一张手牌置为其“箓”，其不能使用打出“箓”同类型的牌",
}
--卧龙凤雏 2021.2.7

local yanghuiyu = General(extension, "ol__yanghuiyu", "jin", 3, 3, General.Female)
local ciwei = fk.CreateTriggerSkill{
  name = "ciwei",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase ~= Player.NotActive and target:getMark("ciwei-turn") == 2 and
      (data.card.type == Card.TypeBasic or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick)) and not player:isNude()
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
    return player:hasSkill(self.name, true) and target ~= player and target.phase ~= Player.NotActive
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
    if target == player and player:hasSkill(self.name) and data.to == Player.NotActive then
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
    return target == player and player:hasSkill(self.name, true) and data.num < 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
yanghuiyu:addSkill(ciwei)
yanghuiyu:addSkill(caiyuan)
Fk:loadTranslationTable{
  ["ol__yanghuiyu"] = "羊徽瑜",
  ["huirong"] = "慧容",
  [":huirong"] = "隐匿技，锁定技，你登场时，令一名角色将手牌摸或弃至体力值（至多摸至五张）。",
  ["ciwei"] = "慈威",
  [":ciwei"] = "其他角色于其回合内使用第二张牌时，若此牌为基本牌或普通锦囊牌，你可弃置一张牌令此牌无效或取消所有目标。",
  ["caiyuan"] = "才媛",
  [":caiyuan"] = "锁定技，回合结束前，若你于上回合结束至今未扣减过体力，你摸两张牌。",
  ["#ciwei-invoke"] = "慈威：你可以弃置一张牌，取消 %dest 使用的%arg",
}

Fk:loadTranslationTable{
  ["simazhou"] = "司马伷",
  ["caiwang"] = "才望",
  [":caiwang"] = "当你使用/打出牌响应其他角色使用的牌，或其他角色使用/打出牌响应你使用的牌后，若牌的颜色相同，你可以弃置其一张牌。你可以将最后一张手牌当【闪】使用或打出；将最后一张你装备区里的牌当【无懈可击】使用；将最后一张你判定区的牌当【杀】使用或打出。",
  ["naxiang"] = "纳降",
  [":naxiang"] = "锁定技，当其他角色对你造成伤害或受到你的伤害后，你对其发动【才望】的“弃置”修改为“获得”直到你的回合开始。",
}
--李肃
--卫瓘 石苞 彻里吉 潘淑 2021.6.9
local weiguan = General(extension, "weiguan", "jin", 3)
local zhongyun = fk.CreateTriggerSkill{
  name = "zhongyun",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.hp == #player.player_cards[Player.Hand] and
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
        return player:inMyAttackRange(p) end), function (p) return p.id end)
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
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.hp == #player.player_cards[Player.Hand] and player:usedSkillTimes(self.name) == 0 then
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
    if table.every(room:getOtherPlayers(player), function (p) return p:isNude() end) then
      player:drawCards(1, self.name)
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function (p)
        return not p:isNude() end), function (p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhongyun-discard", self.name, true)
      if #to > 0 then
        local id = room:askForCardChosen(player, room:getPlayerById(to[1]), "he", self.name)
        room:throwCard({id}, self.name, room:getPlayerById(to[1]), player)
      else
        player:drawCards(1, self.name)
      end
    end
  end,
}
local shenpin = fk.CreateTriggerSkill{
  name = "shenpin",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player:isNude()
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
  [":zhongyun"] = "锁定技，每回合各限一次，当你受到伤害或回复体力后，若你的体力值与你的手牌数相等，你回复1点体力或对你攻击范围内的一名角色造成1点伤害；当你获得或失去手牌后，若你的体力值与你的手牌数相等，你摸一张牌或弃置一名其他角色的一张牌。",
  ["shenpin"] = "神品",
  [":shenpin"] = "当一名角色的判定牌生效前，你可以打出一张与判定牌颜色不同的牌代替之。",
  ["#zhongyun2"] = "忠允",
  ["#zhongyun-damage"] = "忠允：对攻击范围内一名角色造成1点伤害，或点“取消”回复1点体力",
  ["#zhongyun-discard"] = "忠允：弃置一名其他角色的一张牌，或点“取消”摸一张牌",
  ["#shenpin-invoke"] = "神品：你可以打出一张不同颜色的牌代替 %dest 的判定",
}

Fk:loadTranslationTable{
  ["shibao"] = "石苞",
  ["zhuosheng"] = "擢升",
  [":zhuosheng"] = "出牌阶段，当你使用本轮非以本技能获得的牌时，根据类型执行以下效果：1.基本牌，无距离和次数限制；2.普通锦囊牌，可以令此牌目标+1或-1；3.装备牌，你可以摸一张牌。",
}

Fk:loadTranslationTable{
  ["ol__panshu"] = "潘淑",
  ["weiyi"] = "威仪",
  [":weiyi"] = "每名角色限一次，当一名角色受到伤害后，若其体力值：1.不小于你，你可以令其失去1点体力；2.不大于你，你可以令其回复1点体力。",
  ["jinzhi"] = "锦织",
  [":jinzhi"] = "当你需要使用或打出基本牌时，你可以：弃置X张颜色相同的牌（为你本轮发动本技能的次数），然后摸一张牌，视为你使用或打出此基本牌。",
}

local huangzu = General(extension, "ol__huangzu", "qun", 4)
local wangong = fk.CreateTriggerSkill{
  name = "wangong",
  anim_type = "offensive",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.trueName == "slash" then
      room:broadcastSkillInvoke(self.name)
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
    if data.card.type == Card.TypeBasic then
      room:setPlayerMark(player, "@@wangong", 1)
    else
      room:setPlayerMark(player, "@@wangong", 0)
    end
  end,
}
local wangong_targetmod = fk.CreateTargetModSkill{
  name = "#wangong_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@wangong") > 0 and scope == Player.HistoryPhase then
      return 999
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("@@wangong") > 0 then
      return 999
    end
  end,
}
wangong:addRelatedSkill(wangong_targetmod)
huangzu:addSkill(wangong)
Fk:loadTranslationTable{
  ["ol__huangzu"] = "黄祖",
  ["wangong"] = "挽弓",
  [":wangong"] = "锁定技，若你使用的上一张牌是基本牌，你使用【杀】无距离和次数限制且造成的伤害+1。",
  ["@@wangong"] = "挽弓",
}
--钟琰 黄承彦 2021.7.15
local zhongyan = General(extension, "zhongyan", "jin", 3, 3, General.Female)
local bolan_skills = {"quhu", "qiangxi", "qice", "daoshu", "tiaoxin", "qiangwu", "tianyi", "ex__zhiheng", "jieyin", "guose",
"lijian", "qingnang", "lihun", "mingce", "mizhao", "sanchen", "gongxin"}  --固定技能库，缺ex__tiaoxin ex__jieyin ex__guose ex__lijian chuli 
local bolan = fk.CreateTriggerSkill{
  name = "bolan",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = table.clone(bolan_skills)
    for _, p in ipairs(room:getAllPlayers()) do
      for _, s in ipairs(skills) do
        if p:hasSkill(s, true, true) then
          table.removeOne(skills, s)
        end
      end
    end
    if #skills > 0 then
      local choice = room:askForChoice(player, table.random(skills, math.min(3, #skills)), self.name)
      room:handleAddLoseSkills(player, choice, nil, true, false)
      player.tag[self.name] = {choice}
    end
  end,

  refresh_events = {fk.EventPhaseEnd, fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return target == player and player.phase == Player.Play and player.tag[self.name] and #player.tag[self.name] > 0
    elseif event == fk.GameStart then
      return player:hasSkill(self.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    else
      return target == player and player:hasSkill(self.name, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      room:handleAddLoseSkills(player, "-"..player.tag[self.name][1], nil, true, false)
      player.tag[self.name] = {}
    elseif event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "&bolan", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player, true, true)) do
        room:handleAddLoseSkills(p, "-&bolan", nil, false, true)
      end
    end
  end,
}
local bolan_active = fk.CreateActiveSkill{
  name = "&bolan",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:hasSkill("bolan", true) then
        target = p
        break
      end
    end
    room:loseHp(player, 1, "bolan")
    if player.dead then return end
    local skills = table.clone(bolan_skills)
    for _, p in ipairs(room:getAllPlayers()) do
      for _, s in ipairs(skills) do
        if p:hasSkill(s, true, true) then
          table.removeOne(skills, s)
        end
      end
    end
    if #skills > 0 then
      local choice = room:askForChoice(target, table.random(skills, math.min(3, #skills)), self.name)
      room:handleAddLoseSkills(player, choice, nil, true, false)
      player.tag["bolan"] = {choice}
    end
  end,
}
local yifa = fk.CreateTriggerSkill{
  name = "yifa",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events ={fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and data.firstTarget and table.contains(AimGroup:getAllTargets(data.tos), player.id) and
      (data.card.trueName == "slash" or (data.card.color == Card.Black and data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick))
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "@yifa", 1)
  end,

  refresh_events ={fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.to == Player.NotActive and player:getMark("@yifa") > 0
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
  [":bolan"] = "出牌阶段开始时，你可以从随机三个“出牌阶段限一次”的技能中选择一个获得直到本阶段结束；其他角色的出牌阶段限一次，其可以失去1点体力，令你从随机三个“出牌阶段限一次”的技能中选择一个，其获得之直到此阶段结束。",
  ["yifa"] = "仪法",
  [":yifa"] = "锁定技，当其他角色使用【杀】或黑色普通锦囊牌指定你为目标后，其手牌上限-1直到其回合结束。",
  ["&bolan"] = "博览",
  [":&bolan"] = "出牌阶段限一次，你可以失去1点体力，令钟琰从随机三个“出牌阶段限一次”的技能中选择一个，你获得之直到此阶段结束。",
  ["@yifa"] = "仪法",
}

Fk:loadTranslationTable{
  ["gaogan"] = "高干",
  ["juguan"] = "拒关",
  [":juguan"] = "出牌阶段限一次，你可将一张手牌当【杀】或【决斗】使用。若受到此牌伤害的角色未在你的下回合开始前对你造成过伤害，你的下个摸牌阶段摸牌数+2。",
}

Fk:loadTranslationTable{
  ["duxi"] = "杜袭",
  ["quxi"] = "驱徙",
  [":quxi"] = "限定技，出牌阶段结束时，你可以跳过弃牌阶段并翻至背面，选择两名手牌数不同的其他角色，其中手牌少的角色获得另一名角色一张牌并获得「丰」，另一名角色获得「歉」。有「丰」的角色摸牌阶段摸牌数+1，有「歉」的角色摸牌阶段摸牌数-1。当有「丰」或「歉」的角色死亡时，或每轮开始时，你可以转移「丰」「歉」。",
  ["bixiong"] = "避凶",
  [":bixiong"] = "锁定技，若你于弃牌阶段弃置了手牌，直到你的下回合开始，其他角色不能使用与这些牌花色相同的牌指定你为目标。",
}

Fk:loadTranslationTable{
  ["lvkuanglvxiang"] = "吕旷吕翔",
  ["qigong"] = "齐攻",
  [":qigong"] = "当你使用的仅指定单一目标的【杀】被【闪】抵消后，你可以令一名角色对此目标再使用一张无距离限制的【杀】，此【杀】不可被响应。",
  ["liehou"] = "列侯",
  [":liehou"] = "出牌阶段限一次，你可以令你攻击范围内一名有手牌的角色交给你一张手牌，若如此做，你将一张手牌交给你攻击范围内的另一名其他角色。",
}
--华歆2021.9.24

Fk:loadTranslationTable{
  ["ol__dengzhi"] = "邓芝",
  ["xiuhao"] = "修好",
  [":xiuhao"] = "每名角色的回合限一次，你对其他角色造成伤害，或其他角色对你造成伤害时，你可防止此伤害，令伤害来源摸两张牌。",
  ["sujian"] = "素俭",
  [":sujian"] = "锁定技，弃牌阶段，你改为：将所有非本回合获得的手牌分配给其他角色，或弃置非本回合获得的手牌，并弃置一名其他角色至多等量的牌。",
}

Fk:loadTranslationTable{
  ["ol__wangrongh"] = "王荣",
  ["fengzi"] = "丰姿",
  [":fengzi"] = "出牌阶段限一次，当你使用基本牌或普通锦囊牌时，你可以弃置一张类型相同的手牌令此牌的效果结算两次。",
  ["jizhan"] = "吉占",
  [":jizhan"] = "摸牌阶段，你可以改为展示牌堆顶的一张牌，猜测牌堆顶下一张牌点数大于或小于此牌，然后展示之，若猜对你继续猜测，最后你获得以此法展示的牌。",
  ["fusong"] = "赋颂",
  [":fusong"] = "当你死亡时，你可以令一名体力上限大于你的角色选择获得【丰姿】或【吉占】。",
}

Fk:loadTranslationTable{
  ["ol__bianfuren"] = "卞夫人",
  ["ol__wanwei"] = "挽危",
  [":ol__wanwei"] = "每回合限一次，当你的牌被其他角色弃置或获得后，你可以从牌堆获得一张同名牌（无同名牌则改为摸一张牌）。",
  ["ol__yuejian"] = "约俭",
  [":ol__yuejian"] = "每回合限两次，当其他角色对你使用的牌置入弃牌堆时，你可以展示所有手牌，若花色与此牌均不同，你获得此牌。",
}

Fk:loadTranslationTable{
  ["zuofen"] = "左棻",
  ["zhaosong"] = "诏颂",
  [":zhaosong"] = "一名其他角色于其摸牌阶段结束时，若其没有标记，你可令其正面向上交给你一张手牌，然后根据此牌的类型，令该角色获得对应的标记：锦囊牌，“诔”标记；装备牌，“赋”标记；基本牌，“颂”标记。拥有标记的角色：<br>"..
  "进入濒死状态时，可弃置“诔”，回复至1体力，摸1张牌；<br>"..
  "出牌阶段开始时，可弃置“赋”，弃置一名角色区域内的至多两张牌；<br>"..
  "使用【杀】仅指定一个目标时，可弃置“颂”，为此【杀】额外选择至多两个目标。",
  ["lisi"] = "离思",
  [":lisi"] = "每当你于回合外使用的牌置入弃牌堆时，你可将其交给一名手牌数不大于你的其他角色。",
}
--杨艳 杨芷2021.11.17
--冯方女 杨仪 朱灵2021.12.24
--（官渡，未上线）辛评 韩猛2021.12.26

local xuangongzhu = General(extension, "xuangongzhu", "jin", 3, 3, General.Female)
local qimei = fk.CreateTriggerSkill{
  name = "qimei",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.tag[self.name] then
      room:setPlayerMark(room:getPlayerById(player.tag[self.name]), "@@qimei", 0)
    end
    player.tag[self.name] = nil
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#qimei-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player.room:getPlayerById(self.cost_data), "@@qimei", 1)
    player.tag[self.name] = self.cost_data
  end,

  refresh_events = {fk.AfterCardsMove, fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(self.name) and player.tag[self.name] and not room:getPlayerById(player.tag[self.name]).dead then
      local to = room:getPlayerById(player.tag[self.name])
      self.cost_data = nil
      if event == fk.AfterCardsMove then
        if #player.player_cards[Player.Hand] ~= #to.player_cards[Player.Hand] then return end
        for _, move in ipairs(data) do
          if move.toArea == Card.PlayerHand then
            if move.to == player.id then
              self.cost_data = to
              return true
            elseif move.to == to.id then
              self.cost_data = player
              return true
            end
          end
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              if move.from == player.id then
                self.cost_data = to
                return true
              elseif move.from == to.id then
                self.cost_data = player
                return true
              end
            end
          end
        end
      else
        if target == player and player.hp == to.hp then
          self.cost_data = to
          return true
        elseif target == to and player.hp == to.hp then
          self.cost_data = player
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    self.cost_data:drawCards(1, self.name)
  end,
}
local zhuijix = fk.CreateTriggerSkill{
  name = "zhuijix",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"zhuiji_draw"}
    if player:isWounded() then
      table.insert(choices, 1, "zhuiji_recover")
    end
    local choice = room:askForChoice(player, choices, self.name)
    room:addPlayerMark(player, choice, 1)
    if choice == "zhuiji_recover" then
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

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("zhuiji_recover") > 0 then
      room:setPlayerMark(player, "zhuiji_recover", 0)
      room:askForDiscard(player, 2, 2, true, self.name, false)
    end
    if player:getMark("zhuiji_draw") > 0 then
      room:setPlayerMark(player, "zhuiji_draw", 0)
      room:loseHp(player, 1, self.name)
    end
  end,
}
xuangongzhu:addSkill(qimei)
xuangongzhu:addSkill(zhuijix)
Fk:loadTranslationTable{
  ["xuangongzhu"] = "宣公主",
  ["gaoling"] = "高陵",
  [":gaoling"] = "隐匿技，当你于其他角色的回合内登场时，你可以令一名角色回复1点体力。",
  ["qimei"] = "齐眉",
  [":qimei"] = "准备阶段，你可以选择一名其他角色，直到你的下个回合开始（每回合每项限一次），当你或该角色的手牌数或体力值变化后，若双方的此数值相等，另一方摸一张牌。",
  ["zhuijix"] = "追姬",
  [":zhuijix"] = "出牌阶段开始时，你可以选择一项：1.回复1点体力，并于此阶段结束时弃置两张牌；2.摸两张牌，并于此阶段结束时失去1点体力。",
  ["#qimei-choose"] = "齐眉：指定一名其他角色为“齐眉”角色，双方手牌数或体力值变化后可摸牌",
  ["@@qimei"] = "齐眉",
  ["zhuiji_recover"] = "回复1点体力，此阶段结束时弃两张牌",
  ["zhuiji_draw"] = "摸两张牌，此阶段结束时失去1点体力",
}

Fk:loadTranslationTable{
  ["ol__dongzhao"] = "董昭",
  ["xianlve"] = "先略",
  [":xianlve"] = "主公的回合开始时，你可以记录一张普通锦囊牌。每回合限一次，当其他角色使用记录牌后，你摸两张牌并将之分配给任意角色，然后重新记录一张普通锦囊牌。",
  ["zaowang"] = "造王",
  [":zaowang"] = "限定技，出牌阶段，你可以令一名角色增加1点体力上限、回复1点体力并摸三张牌，若其为：忠臣，当主公死亡时与主公交换身份牌；反贼，当其被主公或忠臣杀死时，主公方获胜。",
}

local xinchang = General(extension, "xinchang", "jin", 3)
local canmou = fk.CreateTriggerSkill{
  name = "canmou",
  anim_type = "control",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.targetGroup and data.firstTarget and
      data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick and
      table.every(player.room:getOtherPlayers(target), function (p) return #target.player_cards[Player.Hand] > #p.player_cards[Player.Hand] end)
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
    return player:hasSkill(self.name) and target ~= player and
      data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick and
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
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "congjianx")
    end
  end,

  refresh_events = {fk.Damaged, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card and data.card.extra_data and table.contains(data.card.extra_data, "congjianx")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      if target == player then
        room:addPlayerMark(player, self.name, 1)
      end
    else
      if player:getMark(self.name) > 0 then
        player:drawCards(2, self.name)
        room:setPlayerMark(player, self.name, 0)
      end
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
}

local wuyan = General(extension, "wuyanw", "wu", 4)
local lanjiang = fk.CreateTriggerSkill{
  name = "lanjiang",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p.player_cards[Player.Hand] >= #player.player_cards[Player.Hand] then
        table.insert(targets, p.id)
        if room:askForSkillInvoke(p, self.name, nil, "#lanjiang-choose::"..player.id) then
          player:drawCards(1, self.name)
        end
      end
    end
    local targets1 = table.filter(targets, function (id) return #room:getPlayerById(id).player_cards[Player.Hand] == #player.player_cards[Player.Hand] end)
    if #targets1 > 0 then
      local to = room:askForChoosePlayers(player, targets1, 1, 1, "#lanjiang-damage", self.name, true)
      if #to > 0 then
        room:doIndicate(player.id, {to[1]})
        room:damage{
          from = player,
          to = room:getPlayerById(to[1]),
          damage = 1,
          skillName = self.name,
        }
      end
    end
    local targets2 = table.filter(targets, function (id) return #room:getPlayerById(id).player_cards[Player.Hand] < #player.player_cards[Player.Hand] end)
    if #targets2 > 0 then
      local to = room:askForChoosePlayers(player, targets2, 1, 1, "#lanjiang-draw", self.name, true)
      if #to > 0 then
        room:doIndicate(player.id, {to[1]})
        room:getPlayerById(to[1]):drawCards(1, self.name)
      end
    end
  end,
}
wuyan:addSkill(lanjiang)
Fk:loadTranslationTable{
  ["wuyanw"] = "吾彦",
  ["lanjiang"] = "澜江",
  [":lanjiang"] = "结束阶段，你可以令所有手牌数不小于你的角色依次选择是否令你摸一张牌。选择完成后，你可以对手牌数等于你的其中一名角色造成1点伤害，然后令手牌数小于你的其中一名角色摸一张牌。",
  ["#lanjiang-choose"] = "澜江：是否令 %dest 摸一张牌？",
  ["#lanjiang-damage"] = "澜江：你可以对其中一名角色造成1点伤害",
  ["#lanjiang-draw"] = "澜江：你可以令其中一名角色摸一张牌",
}

Fk:loadTranslationTable{
  ["ol__chendeng"] = "陈登",
  ["fengji"] = "丰积",
  [":fengji"] = "摸牌阶段开始时，你可以令你本回合以下至多两项数值-1：1.摸牌阶段摸牌数；2.出牌阶段使用【杀】的限制次数。你每选择一项，令一名其他角色下回合的对应项数值+2。选择完成后，你令你本回合未选择选项的数值+1。",
}

Fk:loadTranslationTable{
  ["ol__tianyu"] = "田豫",
  ["saodi"] = "扫狄",
  [":saodi"] = "当你使用【杀】或普通锦囊牌仅指定一名其他角色为目标时，你可以令你与其之间的角色均成为此牌的目标。",
  ["zhuitao"] = "追讨",
  [":zhuitao"] = "准备阶段，你可以令你与一名未以此法减少距离的其他角色的距离-1。当你对其造成伤害后，失去你以此法对其减少的距离。",
}

Fk:loadTranslationTable{
  ["fanjiangzhangda"] = "范疆张达",
  ["yuanchou"] = "怨仇",
  [":yuanchou"] = "锁定技，你使用的黑色【杀】无视目标角色防具，其他角色对你使用的黑色【杀】无视你的防具。",
  ["juesheng"] = "决生",
  [":juesheng"] = "限定技，你可以视为使用一张伤害为X的【决斗】（X为目标角色本局使用【杀】的数量且至少为1），然后其获得本技能直到其下回合结束。",
}

Fk:loadTranslationTable{
  ["ol__yanghu"] = "羊祜",
  ["huaiyuan"] = "怀远",
  [":huaiyuan"] = "你的初始手牌称为“绥”。你每失去一张“绥”时，令一名角色手牌上限+1或攻击范围+1或摸一张牌。当你死亡时，你可令一名其他角色获得你以此法增加的手牌上限和攻击范围。",
  ["chongxin"] = "崇信",
  [":chongxin"] = "出牌阶段限一次，你可令一名有手牌的其他角色与你各重铸一张牌。",
  ["dezhang"] = "德彰",
  [":dezhang"] = "觉醒技，回合开始时，若你没有“绥”，你减1点体力上限，获得〖卫戍〗。",
  ["weishu"] = "卫戍",
  [":weishu"] = "锁定技，你于摸牌阶段外非因〖卫戍〗摸牌后，你令一名角色摸1张牌；你于非弃牌阶段弃置牌后，你弃置一名其他角色的1张牌。",
}

local qinghegongzhu = General(extension, "qinghegongzhu", "wei", 3, 3, General.Female)
local zengou = fk.CreateTriggerSkill{
  name = "zengou",
  anim_type = "control",
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card.name == "jink" and player:inMyAttackRange(player.room:getPlayerById(data.from))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#zengou-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|.|.|^basic", "#zengou-discard") == 0 then
      room:loseHp(player, 1, self.name)
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player, data.card, true, fk.ReasonJustMove)
      end
    end
    return true
  end,
}
local zhangjiq = fk.CreateTriggerSkill{
  name = "zhangjiq",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Finish and
      (player:getMark("zhangji1-turn") > 0 or (player:getMark("zhangji2-turn") > 0 and not target:isNude()))
  end,
  on_cost = function(self, event, target, player, data)
    if player:getMark("zhangji1-turn") > 0 then
      if player.room:askForSkillInvoke(player, self.name, data, "#zhangji-draw::"..target.id) then
        self.cost_data = "zhangji1"
        return true
      end
    else
      if player.room:askForSkillInvoke(player, self.name, data, "#zhangji-discard::"..target.id) then
        self.cost_data = "zhangji2"
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "zhangji1" then
      target:drawCards(2, self.name)
      if player:getMark("zhangji2-turn") > 0 and not target:isNude() and room:askForSkillInvoke(player, self.name, data, "#zhangji-discard::"..target.id) then
        room:askForDiscard(target, 2, 2, true, self.name, false)
      end
    else
      room:askForDiscard(target, 2, 2, true, self.name, false)
    end
  end,

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "zhangji1-turn", 1)
    else
      player.room:addPlayerMark(player, "zhangji2-turn", 1)
    end
  end,
}
qinghegongzhu:addSkill(zengou)
qinghegongzhu:addSkill(zhangjiq)
Fk:loadTranslationTable{
  ["qinghegongzhu"] = "清河公主",
  ["zengou"] = "谮构",
  [":zengou"] = "当你攻击范围内一名角色使用【闪】时，你可以弃置一张非基本牌或失去1点体力，令此【闪】无效，然后你获得之。",
  ["zhangjiq"] = "长姬",
  [":zhangjiq"] = "一名角色的结束阶段，若你本回合：造成过伤害，你可以令其摸两张牌；受到过伤害，你可以令其弃置两张牌。",
  ["#zengou-invoke"] = "谮构：你可以弃置一张非基本牌或失去1点体力令 %dest 的【闪】无效，你获得之",
  ["#zengou-discard"] = "谮构：弃置一张非基本牌，或点“取消”失去1点体力",
  ["#zhangji-draw"] = "长姬：你可以令 %dest 摸两张牌",
  ["#zhangji-discard"] = "长姬：你可以令 %dest 弃置两张牌",
}

local jiachong = General(extension, "ol__jiachong", "jin", 3)
local xiongshu = fk.CreateTriggerSkill{
  name = "xiongshu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and
      #player:getCardIds{Player.Hand, Player.Equip} >= player:usedSkillTimes(self.name, Player.HistoryRound) and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:usedSkillTimes(self.name, Player.HistoryRound)
    if n == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#xiongshu-invoke::"..target.id)
    else
      return #player.room:askForDiscard(player, n, n, false, self.name, true, ".", "#xiongshu-cost::"..target.id..":"..tostring(n)) == n
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
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 then
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
      --room:broadcastSkillInvoke(self.name)
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
    if target == player and player:hasSkill(self.name) then
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
      --room:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    else
      if player.tag[self.name] and data.from.id == player.tag[self.name] then
        --room:broadcastSkillInvoke(self.name)
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
  [":xiongshu"] = "其他角色出牌阶段开始时，你可以：弃置X张牌（为本轮你已发动过本技能的次数），展示其一张手牌，你秘密猜测其于此出牌阶段是否会使用与此牌同名的牌。出牌阶段结束时，若你猜对，你对其造成1点伤害；若你猜错，你获得此牌。",
  ["jianhui"] = "奸回",
  [":jianhui"] = "锁定技，你记录上次对你造成伤害的角色。当你对其造成伤害后，你摸一张牌；当其对你造成伤害后，其弃置一张牌。",
  ["#xiongshu-invoke"] = "凶竖：你可以展示 %dest 的一张手牌，猜测其此阶段是否会使用同名牌",
  ["#xiongshu-cost"] = "凶竖：你可以弃置%arg张牌展示 %dest 一张手牌，猜测其此阶段是否会使用同名牌",
  ["yes"] = "是",
  ["no"] = "否",
}

Fk:loadTranslationTable{
  ["ol__tengfanglan"] = "滕芳兰",
  ["luochong"] = "落宠",
  [":luochong"] = "准备阶段或当你每回合首次受到伤害后，你可以选择一项，令一名角色：1.回复1点体力；2.失去1点体力；3.弃置两张牌；4.摸两张牌。每轮每项每名角色限一次。",
  ["aichen"] = "哀尘",
  [":aichen"] = "锁定技，当你进入濒死状态时，若【落宠】选项数大于1，你移除其中一项。",
}

return extension
