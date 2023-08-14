local extension = Package("ol_sp3")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_sp3"] = "OL专属3",
}

local ol__zhugejin = General(extension, "ol__zhugejin", "wu", 3)
local ol__hongyuan = fk.CreateTriggerSkill{
  name = "ol__hongyuan",
  anim_type = "defensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and not player:isNude() then
      local currentplayer = player.room.current
      if currentplayer and currentplayer.phase <= Player.Finish and currentplayer.phase >= Player.Start then
        local x = 0
        for _, move in ipairs(data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            x = x + #move.moveInfo
          end
        end
        return x > 1
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), function(p)
      return p.id
    end)
    for _ = 1, 2, 1 do
      if player.dead or player:isNude() then break end
      local tos, cardId = room:askForChooseCardAndPlayers(
        player,
        targets,
        1,
        1,
        ".",
        "#ol__hongyuan-give",
        self.name,
        true,
        true
      )
      if #tos > 0 then
        room:obtainCard(tos[1], cardId, false, fk.ReasonGive)
        targets = table.filter(targets, function (pid)
          return tos[1] ~= pid and not room:getPlayerById(pid).dead
        end)
        if #targets < 1 then break end
      else
        break
      end
    end
  end,
}
local ol__mingzhe = fk.CreateTriggerSkill{
  name = "ol__mingzhe",
  frequency = Skill.Compulsory,
  anim_type = "defensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.Play then
      for _, move in ipairs(data) do
        if move.from == player.id and (move.to ~= player.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
ol__zhugejin:addSkill("huanshi")
ol__zhugejin:addSkill(ol__hongyuan)
ol__zhugejin:addSkill(ol__mingzhe)
Fk:loadTranslationTable{
  ["ol__zhugejin"] = "诸葛瑾",
  ["ol__huanshi"] = "缓释",
  [":ol__huanshi"] = "当一名角色的判定牌生效前，你可以令其观看你的牌并用其中一张牌代替判定牌。",
  ["ol__hongyuan"] = "弘援",
  [":ol__hongyuan"] = "每阶段限一次，当你一次获得至少两张牌后，你可以交给至多两名其他角色各一张牌。",
  ["ol__mingzhe"] = "明哲",
  [":ol__mingzhe"] = "锁定技，当你于出牌阶段外失去红色牌后，你摸一张牌。",

  ["#ol__hongyuan-give"] = "弘援：你可以选择一张牌交给一名角色",

  ["$ol__huanshi1"] = "不因困顿夷初志，肯为联蜀改阵营。",
  ["$ol__huanshi2"] = "合纵连横，只为天下苍生。",
  ["$ol__hongyuan1"] = "吾已料有所困，援兵不久必至。",
  ["$ol__hongyuan2"] = "恪守信义，方为上策。",
  ["$ol__mingzhe1"] = "乱世，当稳中求胜。",
  ["$ol__mingzhe2"] = "明哲维天，临君下土。",
  ["~ol__zhugejin"] = "联盟若能得以维系，吾……无他愿矣……",
}

local ol__guyong = General(extension, "ol__guyong", "wu", 3)
local ol__bingyi = fk.CreateTriggerSkill{
  name = "ol__bingyi",
  anim_type = "defensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and not player:isKongcheng() then
      local currentplayer = player.room.current
      if currentplayer and currentplayer.phase <= Player.Finish and currentplayer.phase >= Player.Start then
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    if #cards > 1 then
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).color == Card.NoColor or Fk:getCardById(id).color ~= Fk:getCardById(cards[1]).color then
          return false
        end
      end
    end
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), function(p)
      return p.id end), 1, #cards, "#ol__bingyi-choose:::"..#cards, self.name, true)
    table.insert(tos, player.id)
    room:sortPlayersByAction(tos)
    for _, pid in ipairs(tos) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:drawCards(p, 1, self.name)
      end
    end
  end,
}
ol__guyong:addSkill("shenxing")
ol__guyong:addSkill(ol__bingyi)
Fk:loadTranslationTable{
  ["ol__guyong"] = "顾雍",
  ["ol__bingyi"] = "秉壹",
  [":ol__bingyi"] = "每阶段限一次，当你的牌被弃置后，你可以展示所有手牌，若颜色均相同，你令你与至多X名角色各摸一张牌（X为你的手牌数）。",
  ["#ol__bingyi-choose"] = "秉壹：你可以与至多%arg名其他角色各摸一张牌，点取消则仅你摸牌",

  ["$ol__bingyi1"] = "秉直进谏，勿藏私心！",
  ["$ol__bingyi2"] = "秉公守一，不负圣恩！",
  ["~ol__guyong"] = "此番患疾，吾必不起……",
}

local ol__zhoufei = General(extension, "ol__zhoufei", "wu", 3, 3, General.Female)
local ol__liangyin = fk.CreateTriggerSkill{
  name = "ol__liangyin",
  events = {fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerSpecial then
          if player:getMark("liangyin1used-turn") == 0 then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea ~= Card.PlayerSpecial then
                return true
              end
            end
          end
        elseif player:getMark("liangyin2used-turn") == 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerSpecial then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local drawcard, discard = false, false
    for _, move in ipairs(data) do
      if move.toArea == Card.PlayerSpecial then
        if player:getMark("liangyin1used-turn") == 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea ~= Card.PlayerSpecial then
              room:setPlayerMark(player, "liangyin1used-turn", 1)
              drawcard = true
            end
          end
        end
      elseif player:getMark("liangyin2used-turn") == 0 then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerSpecial then
            room:setPlayerMark(player, "liangyin2used-turn", 1)
            discard = true
          end
        end
      end
    end
    if drawcard then
      self.cost_data = "drawcard"
      self:doCost(event, target, player, data)
    end
    if discard and player:hasSkill(self.name) and not player:isNude() then
      self.cost_data = "discard"
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choice = self.cost_data
    local targets = table.filter(player.room.alive_players, function (p)
      return p ~= player and (choice == "drawcard" or not p:isNude())
    end)
    local to = player.room:askForChoosePlayers(player, table.map(targets, function (p)
      return p.id end), 1, 1, "#ol__liangyin-" .. choice, self.name, true)
    if #to > 0 then
      self.cost_data = {to[1], choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(self.cost_data[1])
    local choice = self.cost_data[2]
    if choice == "drawcard" then
      room:notifySkillInvoked(player, self.name, "support")
      room:broadcastSkillInvoke(self.name)
      room:drawCards(player, 1, self.name)
      if not tar.dead then
        room:drawCards(tar, 1, self.name)
      end
    elseif choice == "discard" then
      room:notifySkillInvoked(player, self.name, "control")
      room:broadcastSkillInvoke(self.name)
      room:askForDiscard(player, 1, 1, true, self.name, false)
      if not tar.dead then 
        room:askForDiscard(tar, 1, 1, true, self.name, false)
      end
    end
    if player.dead then return false end
    local x = #player:getPile("ol__kongsheng_harp")
    local targets = {}
    if player:getHandcardNum() == x and player:isWounded() then
      table.insert(targets, player.id)
    end
    if not tar.dead and tar:getHandcardNum() == x and tar:isWounded() then
      table.insert(targets, tar.id)
    end
    if #targets == 0 then return false end
    local tos = player.room:askForChoosePlayers(player, targets, 1, 1, "#ol__liangyin-recover", self.name, true)
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ol__kongsheng = fk.CreateTriggerSkill{
  name = "ol__kongsheng",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (player.phase == Player.Start or
    (player.phase == Player.Finish and #player:getPile("ol__kongsheng_harp") > 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local cards = room:askForCard(player, 1, 998, true, self.name, true, ".", "#ol__kongsheng-invoke")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    elseif player.phase == Player.Finish then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.phase == Player.Start then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(self.cost_data)
      player:addToPile("ol__kongsheng_harp", self.cost_data, true, self.name)
    elseif player.phase == Player.Finish then
      local room = player.room
      local cards = table.filter(player:getPile("ol__kongsheng_harp"), function (id)
        return Fk:getCardById(id).type ~= Card.TypeEquip
      end)
      if #cards == 0 then return false end
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
      if player.dead or #player:getPile("ol__kongsheng_harp") == 0 then return false end
      local targets = table.filter(room.alive_players, function (p)
        return table.find(player:getPile("ol__kongsheng_harp"), function (id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeEquip and not p:prohibitUse(card) and not p:isProhibited(p, card) and p:canUse(card)
        end)
      end)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, table.map(targets, function (p)
        return p.id end), 1, 1, "#ol__kongsheng-choose", self.name, false)
      if #tos == 0 then return false end
      local to = room:getPlayerById(tos[1])
      while true do
        if player.dead or to.dead then break end
        local to_use = table.find(player:getPile("ol__kongsheng_harp"), function (id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeEquip and not to:prohibitUse(card) and not to:isProhibited(to, card) and to:canUse(card)
        end)
        if to_use == nil then break end
        room:useCard({
          from = to.id,
          tos = {{to.id}},
          card = Fk:getCardById(to_use),
        })
      end
      if not to.dead then
        room:loseHp(to, 1, self.name)
      end
    end
  end,
}
ol__zhoufei:addSkill(ol__liangyin)
ol__zhoufei:addSkill(ol__kongsheng)
Fk:loadTranslationTable{
  ["ol__zhoufei"] = "周妃",
  ["ol__liangyin"] = "良姻",
  [":ol__liangyin"] = "当每回合首次有牌移出/移入游戏后，你可以与一名其他角色各摸/弃置一张牌，然后你可以令其中一名手牌数为X的角色回复1点体力（X为“箜”数）。",
  ["ol__kongsheng"] = "箜声",
  [":ol__kongsheng"] = "准备阶段，你可以将任意张牌置于你的武将牌上，称为“箜”。结束阶段，你获得“箜”中的非装备牌，然后令一名角色使用剩余“箜”并失去1点体力。",

  ["#ol__liangyin-drawcard"] = "你可以发动良姻，选择一名角色，与其各摸一张牌",
  ["#ol__liangyin-discard"] = "你可以发动良姻，选择一名角色，与其各弃置一张牌",
  ["#ol__liangyin-recover"] = "良姻：可以选择一名角色，令其回复1点体力",
  ["#ol__kongsheng-invoke"] = "你可以发动箜声，选择任意张牌作为“箜”置于武将牌上",
  ["#ol__kongsheng-choose"] = "箜声：选择一名角色，令其使用“箜”中的装备牌并失去1点体力",
  ["ol__kongsheng_harp"] = "箜",

  ["$ol__liangyin1"] = "碧水云月间，良缘情长在。",
  ["$ol__liangyin2"] = "皓月皎，花景明，两心同。",
  ["$ol__kongsheng1"] = "歌尽桃花颜，箜鸣玉娇黛。",
  ["$ol__kongsheng2"] = "箜篌双丝弦，心有千绪结。",
  ["~ol__zhoufei"] = "梧桐半枯衰，鸳鸯白头散……",
}

local hetaihou = General(extension, "ol__hetaihou", "qun", 3, 3, General.Female)
local ol__zhendu = fk.CreateTriggerSkill{
  name = "ol__zhendu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Play and not player:isKongcheng() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#ol__zhendu-invoke::"..target.id, true)
    if #card > 0 then
      player.room:doIndicate(player.id, {target.id})
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if not target.dead and room:useVirtualCard("analeptic", nil, target, target, self.name, false) and player ~= target and not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local ol__qiluan = fk.CreateTriggerSkill{
  name = "ol__qiluan",
  anim_type = "offensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if data.to == Player.NotActive and player:hasSkill(self.name) then
      local logic = player.room.logic
      local deathevents = logic.event_recorder[GameEvent.Death] or Util.DummyTable
      local turnevents = logic.event_recorder[GameEvent.Turn] or Util.DummyTable
      return #deathevents > 0 and #turnevents > 0 and deathevents[#deathevents].id > turnevents[#turnevents].id
    end
  end,
  on_use = function(self, event, target, player, data)
    local x = 0
    player.room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
      local deathData = e.data[1]
      if deathData.damage and deathData.damage.from == player then
        x = x + 3
      else
        x = x + 1
      end
      return false
    end, Player.HistoryTurn)
    if x > 0 then
      player:drawCards(x, self.name)
    end
  end,
}
hetaihou:addSkill(ol__zhendu)
hetaihou:addSkill(ol__qiluan)
Fk:loadTranslationTable{
  ["ol__hetaihou"] = "何太后",
  ["ol__zhendu"] = "鸩毒",
  [":ol__zhendu"] = "一名角色的出牌阶段开始时，你可以弃置一张手牌。若如此做，该角色视为使用一张【酒】，然后若该角色不为你，你对其造成1点伤害。",
  ["ol__qiluan"] = "戚乱",
  [":ol__qiluan"] = "一名角色回合结束时，你可摸X张牌（X为本回合死亡的角色数，其中每有一名角色是你杀死的，你多摸两张牌）。",
  ["#ol__zhendu-invoke"] = "鸩毒：你可以弃置一张手牌视为 %dest 使用一张【酒】，然后你对其造成1点伤害",

  ["$ol__zhendu1"] = "想要母凭子贵？你这是妄想。",
  ["$ol__zhendu2"] = "这皇宫，只能有一位储君。",
  ["$ol__qiluan1"] = "权力，只有掌握在自己手里才安心。",
  ["$ol__qiluan2"] = "有兄长在，我何愁不能继续享受。",
  ["~ol__hetaihou"] = "扰乱朝堂之事，我怎么会做……",
}

local machao = General(extension, "ol__machao", "qun", 4)
local ol__zhuiji = fk.CreateTriggerSkill{
  name = "ol__zhuiji",
  anim_type = "control",
  events = {fk.TargetSpecified},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name) and data.card.trueName == "slash") then return false end
    local to = player.room:getPlayerById(data.to)
    return not to.dead and not to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to})
    local to = room:getPlayerById(data.to)
    local x = #to:getCardIds("e")
    local cards = room:askForDiscard(to, 1, 1, true, self.name, x > 0, ".", "#ol__zhuiji-discard")
    if #cards == 0 and x > 0 then
      to:throwAllCards("e")
      if not to.dead then
        room:drawCards(to, x, self.name)
      end
    end
  end,
}
local ol__zhuiji_distance = fk.CreateDistanceSkill{
  name = "#ol__zhuiji_distance",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(ol__zhuiji.name) then
      if from.hp >= to.hp then
        from:setFixedDistance(to, 1)
      else
        from:removeFixedDistance(to)
      end
    end
    return 0
  end,
}
local ol__shichou = fk.CreateTriggerSkill{
  name = "ol__shichou",
  anim_type = "offensive",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card.trueName == "slash" then
      local current_targets = TargetGroup:getRealTargets(data.tos)
      for _, p in ipairs(player.room.alive_players) do
        if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) and
            data.card.skill:modTargetFilter(p.id, current_targets, data.from, data.card, true) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local current_targets = TargetGroup:getRealTargets(data.tos)
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if not table.contains(current_targets, p.id) and not player:isProhibited(p, data.card) and
          data.card.skill:modTargetFilter(p.id, current_targets, data.from, data.card, true) then
        table.insert(targets, p.id)
      end
    end
    local n = player:getLostHp() + 1
    local tos = room:askForChoosePlayers(player, targets, 1, n,
    "#ol__shichou-choose:::"..data.card:toLogString()..":"..tostring(n), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    table.insertTable(data.tos, table.map(self.cost_data, function (p)
      return {p}
    end))
  end,
}
ol__zhuiji:addRelatedSkill(ol__zhuiji_distance)
machao:addSkill(ol__zhuiji)
machao:addSkill(ol__shichou)

Fk:loadTranslationTable{
  ["ol__machao"] = "马超",
  ["ol__zhuiji"] = "追击",
  [":ol__zhuiji"] = "锁定技，你计算与体力值不大于你的角色的距离始终为1。当你使用【杀】指定距离为1的角色为目标后，其弃置一张牌或弃置装备区里的所有牌并摸等量的牌。",
  ["ol__shichou"] = "誓仇",
  [":ol__shichou"] = "你使用【杀】可以多选择至多X+1名角色为目标（X为你已损失的体力值）。",

  ["#ol__zhuiji-discard"] = "追击：选择一张牌弃置，或点取消则弃置装备区里的所有牌并摸等量的牌",
  ["#ol__shichou-choose"] = "是否使用誓仇，为此【%arg】额外指定至多%arg2个目标",

  ["$ol__shichou1"] = "你们一个都别想跑！",
  ["$ol__shichou2"] = "新仇旧恨，一并结算！",
  ["~ol__machao"] = "父亲！父亲！！",
}

local huban = General(extension, "ol__huban", "wei", 4)
local huiyun = fk.CreateViewAsSkill{
  name = "huiyun",
  anim_type = "support",
  pattern = "fire_attack",
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}
local huiyun_trigger = fk.CreateTriggerSkill{
  name = "#huiyun_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and table.contains(data.card.skillNames, "huiyun") then
      local to = player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
      if not to.dead and to:getMark(self.name) ~= 0 then
        return player.room:getCardOwner(to:getMark(self.name)) == to and player.room:getCardArea(to:getMark(self.name)) == Card.PlayerHand
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    self:doCost(event, target, player, data)
    local to = player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if not to.dead then
      player.room:setPlayerMark(to, self.name, 0)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel"}
    for i = 1, 3, 1 do
      local mark = "huiyun"..tostring(i).."-round"
      if player:getMark(mark) == 0 then
        table.insert(choices, mark)
      end
    end
    if #choices == 1 then return end
    local to = TargetGroup:getRealTargets(data.tos)[1]
    local choice = player.room:askForChoice(player, choices, "huiyun", "#huiyun-choice::"..to)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.cost_data, 1)
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    local id = to:getMark(self.name)
    room:setPlayerMark(to, self.name, 0)
    if self.cost_data == "huiyun3-round" then
      to:drawCards(1, "huiyun")
    else
      if self.cost_data == "huiyun1-round" then
        --FIXME：这里需要大量可用判断！满血吃桃、重复挂闪电等
        local use = room:askForUseCard(to, Fk:getCardById(id).name, "^(jink,nullification)|.|.|.|.|.|"..tostring(id), "#huiyun1-card", true)
        if use then
          room:useCard(use)
          room:delay(1000)
          if not to.dead and not to:isKongcheng() then
            room:recastCard(to:getCardIds{Player.Hand}, to, "huiyun")
          end
        end
      elseif self.cost_data == "huiyun2-round" then
        local use = room:askForUseCard(to, "", "^(jink,nullification)|.|.|hand", "#huiyun2-card", true)
        if use then
          --if not CanUseCard(use.card, player.id) then return end
          room:useCard(use)
          room:delay(1000)
          if not to.dead and room:getCardOwner(id) == to and room:getCardArea(id) == Card.PlayerHand then
            room:recastCard({id}, to, "huiyun")
          end
        end
      end
    end
  end,

  refresh_events = {fk.CardShown},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return table.contains(use.card.skillNames, "huiyun")
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, data.cardIds[1])
  end,
}
huiyun:addRelatedSkill(huiyun_trigger)
huban:addSkill(huiyun)
Fk:loadTranslationTable{
  ["ol__huban"] = "胡班",
  ["huiyun"] = "晖云",
  [":huiyun"] = "每轮每项限一次，你可以将一张牌当【火攻】使用，结算后你可以选择一项，令目标可以：1.使用展示牌，然后重铸所有手牌；"..
  "2.使用一张手牌，然后重铸展示牌；3.摸一张牌。",
  ["#huiyun-choice"] = "晖云：你可以选择一项，令 %dest 选择是否执行",
  ["huiyun1-round"] = "使用展示牌，然后重铸所有手牌",
  ["huiyun2-round"] = "使用一张手牌，然后重铸展示牌",
  ["huiyun3-round"] = "摸一张牌",
  ["#huiyun1-card"] = "晖云：你可以使用展示牌，然后重铸所有手牌",
  ["#huiyun2-card"] = "晖云：你可以使用一张手牌，然后重铸展示牌",
}

Fk:loadTranslationTable{
  ["ol__furong"] = "傅肜",
  ["xiaosi"] = "效死",
  [":xiaosi"] = "出牌阶段限一次，你可以与一名有手牌的其他角色各弃置一张基本牌（若其不能弃置则你摸一张牌），"..
  "然后你可以使用其中的任意张牌（无距离和次数限制）。",
}

local liuba = General(extension, "ol__liuba", "shu", 3)
local ol__tongdu = fk.CreateTriggerSkill{
  name = "ol__tongdu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player), function(p) return p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), function(p) return p.id end), 1, 1, "#ol__tongdu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#ol__tongdu-give:"..player.id)
    room:obtainCard(player.id, card[1], false, fk.ReasonGive)
    room:setPlayerMark(player, "ol__tongdu-turn", card[1])
  end,
}
local ol__tongdu_trigger = fk.CreateTriggerSkill{
  name = "#ol__tongdu_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes("ol__tongdu", Player.HistoryTurn) > 0 and
      player:getMark("ol__tongdu-turn") ~= 0 and player.room:getCardOwner(player:getMark("ol__tongdu-turn")) == player and
      player.room:getCardArea(player:getMark("ol__tongdu-turn")) == Card.PlayerHand
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("ol__tongdu")
    room:notifySkillInvoked(player, "ol__tongdu")
    local id = player:getMark("ol__tongdu-turn")
    room:moveCards({
      ids = {id},
      from = player.id,
      fromArea = Player.Hand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = "ol__tongdu",
    })
  end,
}
local ol__zhubi = fk.CreateActiveSkill{
  name = "ol__zhubi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < player.maxHp
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#ol__zhubi-card")
    room:moveCards({
      ids = card,
      from = target.id,
      toArea = Card.DiscardPile,
      skillName = self.name,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = target.id
    })
    room:sendLog{
      type = "#RecastBySkill",
      from = target.id,
      card = card,
      arg = self.name,
    }
    local id = target:drawCards(1, self.name)[1]
    if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand then
      local mark = target:getMark(self.name)
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, id)
      room:setPlayerMark(target, self.name, mark)
    end
  end
}
local ol__zhubi_trigger = fk.CreateTriggerSkill{
  name = "#ol__zhubi_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name, true) and target.phase == Player.Finish and target:getMark("ol__zhubi") ~= 0 then
      for _, id in ipairs(target:getMark("ol__zhubi")) do
        if player.room:getCardOwner(id) == target and player.room:getCardArea(id) == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("ol__tongdu")
    room:notifySkillInvoked(player, "ol__tongdu")
    local ids = {}
    for _, id in ipairs(target:getMark("ol__zhubi")) do
      if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand then
        table.insert(ids, id)
      end
    end
    local piles = room:askForExchange(target, {room:getNCards(5, "bottom"), ids}, {"Bottom", "ol__zhubi"}, "ol__zhubi")
    local cards1, cards2 = {}, {}
    for _, id in ipairs(piles[1]) do
      if room:getCardArea(id) == target.Hand then
        table.insert(cards1, id)
      end
    end
    for _, id in ipairs(piles[2]) do
      if room:getCardArea(id) ~= target.Hand then
        table.insert(cards2, id)
      end
    end
    local move1 = {
      ids = cards1,
      from = target.id,
      fromArea = Player.Hand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = "ol__zhubi",
      drawPilePosition = -1,
    }
    local move2 = {
      ids = cards2,
      to = target.id,
      toArea = Player.Hand,
      moveReason = fk.ReasonJustMove,
      skillName = "ol__zhubi",
    }
    room:moveCards(move1, move2)
    ids = {}
    for _, id in ipairs(target:getMark("ol__zhubi")) do
      if room:getCardOwner(id) == target and room:getCardArea(id) == Card.PlayerHand then
        table.insertIfNeed(ids, id)
      end
    end
    if #ids == 0 then
      room:setPlayerMark(target, "ol__zhubi", 0)
    else
      room:setPlayerMark(target, "ol__zhubi", ids)
    end
  end,
}
ol__tongdu:addRelatedSkill(ol__tongdu_trigger)
ol__zhubi:addRelatedSkill(ol__zhubi_trigger)
liuba:addSkill(ol__tongdu)
liuba:addSkill(ol__zhubi)
Fk:loadTranslationTable{
  ["ol__liuba"] = "刘巴",
  ["ol__tongdu"] = "统度",
  [":ol__tongdu"] = "准备阶段，你可以令一名其他角色交给你一张手牌，然后本回合出牌阶段结束时，若此牌仍在你的手牌中，你将此牌置于牌堆顶。",
  ["ol__zhubi"] = "铸币",
  [":ol__zhubi"] = "出牌阶段限X次，你可以令一名角色重铸一张牌，以此法摸的牌称为“币”；有“币”的角色的结束阶段，其观看牌堆底的五张牌，"..
  "然后可以用任意“币”交换其中等量张牌（X为你的体力上限）。",
  ["#ol__tongdu-choose"] = "统度：你可以令一名其他角色交给你一张手牌，出牌阶段结束时你将之置于牌堆顶",
  ["#ol__tongdu-give"] = "统度：你须交给 %src 一张手牌，出牌阶段结束时将之置于牌堆顶",
  ["#ol__zhubi-card"] = "铸币：重铸一张牌，摸到的“币”可以在你的结束阶段和牌堆底牌交换",

  ["$ol__tongdu1"] = "上下调度，臣工皆有所为。",
  ["$ol__tongdu2"] = "统筹部划，不糜国利分毫。",
  ["$ol__zhubi1"] = "钱货之通者，在乎币。",
  ["$ol__zhubi2"] = "融金为料，可铸五铢。",
  ["~ol__liuba"] = "恨未见，铸兵为币之日……",
}

Fk:loadTranslationTable{
  ["macheng"] = "马承",
  ["chenglie"] = "骋烈",
  [":chenglie"] = "你使用【杀】可以多指定至多两个目标，然后展示牌堆顶与目标数等量张牌，秘密将一张手牌与其中一张牌交换，将之分别暗置于"..
  "目标角色武将牌上直到此【杀】结算结束，其中“骋烈”牌为红色的角色若：响应了此【杀】，其交给你一张牌；未响应此【杀】，其回复1点体力。",
}

local quhuang = General(extension, "quhuang", "wu", 3)
local qiejian = fk.CreateTriggerSkill{
  name = "qiejian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      local targetRecorded = type(player:getMark("qiejian_prohibit-round")) == "table" and player:getMark("qiejian_prohibit-round") or {}
      for _, move in ipairs(data) do
        if move.from and not table.contains(targetRecorded, move.from) then
          local to = player.room:getPlayerById(move.from)
          if to:isKongcheng() and not to.dead and not table.every(move.moveInfo, function (info)
              return info.fromArea ~= Card.PlayerHand end) then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local targetRecorded = type(player:getMark("qiejian_prohibit-round")) == "table" and player:getMark("qiejian_prohibit-round") or {}
    for _, move in ipairs(data) do
      if move.from and not table.contains(targetRecorded, move.from) then
        local to = player.room:getPlayerById(move.from)
        if to:isKongcheng() and not to.dead and not table.every(move.moveInfo, function (info)
            return info.fromArea ~= Card.PlayerHand end) then
          table.insertIfNeed(targets, move.from)
        end
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(self.name) then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead and skill_target:isKongcheng() then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qiejian-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:drawCards(player, 1, self.name)
    if not target.dead then
      room:drawCards(target, 1, self.name)
    end
    if player.dead or target.dead then return false end
    local tos = {}
    if #player:getCardIds{Player.Equip, Player.Judge} > 0 then
      table.insert(tos, player.id)
    end
    if player ~= target and #target:getCardIds{Player.Equip, Player.Judge} > 0 then
      table.insert(tos, target.id)
    end
    if #tos > 0 then
      tos = room:askForChoosePlayers(player, tos, 1, 1, "#qiejian-choose::" .. target.id, self.name, true, true)
    end
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      local id = room:askForCardChosen(player, to, 'ej', self.name)
      room:throwCard({id}, self.name, to, player)
    else
      local targetRecorded = type(player:getMark("qiejian_prohibit-round")) == "table" and player:getMark("qiejian_prohibit-round") or {}
      table.insertIfNeed(targetRecorded, target.id)
      room:setPlayerMark(player, "qiejian_prohibit-round", targetRecorded)
    end
  end,
}
local nishouchoicefilter = function(player, id)
  local room = player.room
  local choices = {}
  if player:getMark("@@nishou_exchange-phase") == 0 and room.current and room.current.phase <= Player.Finish and
      room.current.phase >= Player.Start then
    table.insert(choices, "nishou_exchange")
  end
  if room:getCardArea(id) == Card.DiscardPile then
    local card = Fk:cloneCard("lightning")
    card:addSubcard(id)
    if not player:hasDelayedTrick("lightning") and not player:prohibitUse(card) and not player:isProhibited(player, card) then
      table.insert(choices, "nishou_lightning")
    end
  end
  return choices
end
local nishou = fk.CreateTriggerSkill{
  name = "nishou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and #nishouchoicefilter(player, info.cardId) > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local card_ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(card_ids, info.cardId)
          end
        end
      end
    end
    for _, id in ipairs(card_ids) do
      if not player:hasSkill(self.name) then break end
      if #nishouchoicefilter(player, id) > 0 then
        self.cost_data = id
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = self.cost_data
    local choices = nishouchoicefilter(player, id)
    if #choices == 0 then return false end
    local choice = room:askForChoice(player, choices, self.name, "#nishou-choice:::" .. Fk:getCardById(id):toLogString())
    if choice == "nishou_lightning" then
      local card = Fk:cloneCard("lightning")
      card:addSubcard(id)
      room:useCard{
        from = player.id,
        tos = {{player.id}},
        card = card,
      }
    else
      room:addPlayerMark(player, "@@nishou_exchange-phase", 1)
    end
  end,
}
local nishou_delay = fk.CreateTriggerSkill{
  name = "#nishou_delay",
  events = {fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@nishou_exchange-phase") > 0 and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    local x = player:getHandcardNum()
    for _, p in ipairs(room.alive_players) do
      local y = p:getHandcardNum()
      if y < x then
        x = y
        tos = {}
        table.insert(tos, p.id)
      elseif y == x then
        table.insert(tos, p.id)
      end
    end
    local cancelable = table.removeOne(tos, player.id)
    if #tos == 0 then return false end
    tos = room:askForChoosePlayers(player, tos, 1, 1, "#nishou-choose", self.name, cancelable, true)
    if #tos == 0 then return false end

    local cards1 = table.clone(player.player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(tos[1]).player_cards[Player.Hand])
    local move1 = {
      from = player.id,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
    }
    local move2 = {
      from = tos[1],
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = table.filter(cards1, function (id)
        return room:getCardArea(id) == Card.Processing
      end),
      fromArea = Card.Processing,
      to = tos[1],
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
    }
    local move4 = {
      ids = table.filter(cards2, function (id)
        return room:getCardArea(id) == Card.Processing
      end),
      fromArea = Card.Processing,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
    }
    room:moveCards(move3, move4)
  end,
}
nishou:addRelatedSkill(nishou_delay)
quhuang:addSkill(qiejian)
quhuang:addSkill(nishou)
Fk:loadTranslationTable{
  ["quhuang"] = "屈晃",
  ["qiejian"] = "切谏",
  [":qiejian"] = "当一名角色失去最后的手牌后，你可以与其各摸一张牌，然后选择一项：1.弃置你或其场上的一张牌；2.你本轮不能对其发动此技能。",
  ["nishou"] = "泥首",
  ["#nishou_delay"] = "泥首",
  [":nishou"] = "锁定技，当你装备区里的牌进入弃牌堆后，你选择一项：1.将此牌当【闪电】使用；2.本阶段结束时，你与一名全场手牌数最少的角色交换手牌且本阶段内你无法选择此项。",

  ["#qiejian-invoke"] = "是否对 %dest 使用 切谏",
  ["#qiejian-choose"] = "切谏：选择一名角色，弃置其场上一张牌，或点取消则本轮内不能再对 %dest 发动 切谏",
  ["#nishou-choice"] = "泥首：选择将%arg当做【闪电】使用，或在本阶段结束时与手牌数最少的角色交换手牌",
  ["nishou_lightning"] = "将此装备牌当【闪电】使用",
  ["nishou_exchange"] = "本阶段结束时与手牌数最少的角色交换手牌",
  ["@@nishou_exchange-phase"] = "泥首",
  ["#nishou-choose"] = "泥首：你需与手牌数最少的角色交换手牌",

  ["$qiejian1"] = "东宫不稳，必使众人生异。",
  ["$qiejian2"] = "今三方鼎持，不宜擅动储君。",
  ["$nishou1"] = "臣以泥涂首，足证本心。",
  ["$nishou2"] = "人生百年，终埋一抔黄土。",
  ["~quhuang"] = "臣死谏于斯，死得其所……",
}

local zhanghua = General(extension, "zhanghua", "jin", 3)
local bihun = fk.CreateTriggerSkill{
  name = "bihun",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #player.player_cards[Player.Hand] > player:getMaxCards() and data.firstTarget and
      #AimGroup:getAllTargets(data.tos) > 0 and
      not table.every(AimGroup:getAllTargets(data.tos), function(id) return id == player.id end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #AimGroup:getAllTargets(data.tos) == 1 and AimGroup:getAllTargets(data.tos)[1] ~= player.id and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(AimGroup:getAllTargets(data.tos)[1], data.card, true, fk.ReasonJustMove)
    end
    for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
      AimGroup:cancelTarget(data, id)
    end
  end,
}
local jianhe = fk.CreateActiveSkill{
  name = "jianhe",
  anim_type = "offensive",
  min_card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    else
      if Fk:getCardById(selected[1]).type == Card.TypeEquip then
        return Fk:getCardById(to_select).type == Card.TypeEquip
      end
      return Fk:getCardById(to_select).trueName == Fk:getCardById(selected[1]).trueName
    end
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("jianhe-turn") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(target, "jianhe-turn", 1)
    local n = #effect.cards
    room:recastCard(effect.cards, player, self.name)
    if #target:getCardIds{Player.Hand, Player.Equip} < n then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    else
      local type = Fk:getCardById(effect.cards[1]):getTypeString()
      local cards = room:askForCard(target, n, n, true, self.name, true, ".|.|.|.|.|"..type, "#jianhe-choose:::"..n..":"..type)
      if #cards > 0 then
        room:recastCard(cards, target, self.name)
      else
        room:damage{
          from = player,
          to = target,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    end
  end
}
local chuanwu = fk.CreateTriggerSkill{
  name = "chuanwu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local skills = table.map(Fk.generals[player.general].skills, function(s) return s.name end)
    for i = #skills, 1, -1 do
      if not player:hasSkill(skills[i], true) then
        table.removeOne(skills, skills[i])
      end
    end
    local to_lose = {}
    player.tag[self.name] = player.tag[self.name] or {}
    local n = math.min(player:getAttackRange(), #skills)
    for i = 1, n, 1 do
      if player:hasSkill(skills[i], true) then
        table.insert(to_lose, skills[i])
        table.insert(player.tag[self.name], skills[i])
      end
    end
    player.room:handleAddLoseSkills(player, "-"..table.concat(to_lose, "|-"), nil, true, false)
    player:drawCards(n, self.name)
  end,
}
local chuanwu_record = fk.CreateTriggerSkill{
  name = "#chuanwu_record",

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player.tag["chuanwu"]
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, table.concat(player.tag["chuanwu"], "|"), nil, true, false)
    player.tag["chuanwu"] = {}
  end,
}
chuanwu:addRelatedSkill(chuanwu_record)
zhanghua:addSkill(bihun)
zhanghua:addSkill(jianhe)
zhanghua:addSkill(chuanwu)
Fk:loadTranslationTable{
  ["zhanghua"] = "张华",
  ["bihun"] = "弼昏",
  [":bihun"] = "锁定技，当你使用牌指定其他角色为目标时，若你的手牌数大于手牌上限，你取消之并令唯一目标获得此牌。",
  ["jianhe"] = "剑合",
  [":jianhe"] = "出牌阶段每名角色限一次，你可以重铸至少两张同名牌或至少两张装备牌，令一名角色选择一项：1.重铸等量张与之类型相同的牌；2.受到你造成的1点雷电伤害。",
  ["chuanwu"] = "穿屋",
  [":chuanwu"] = "锁定技，当你造成或受到伤害后，你失去你武将牌上前X个技能直到回合结束（X为你的攻击范围），然后摸等同失去技能数张牌。",
  ["#jianhe-choose"] = "剑合：你需重铸%arg张%arg2，否则受到1点雷电伤害",

  ["$bihun1"] = "辅弼天家，以扶朝纲。",
  ["$bihun2"] = "为国治政，尽忠匡辅。",
  ["$jianhe1"] = "身临朝阙，腰悬太阿。",
  ["$jianhe2"] = "位登三事，当配龙泉。",
  ["$chuanwu1"] = "祝融侵库，剑怀远志。",
  ["$chuanwu2"] = "斩蛇穿屋，其志绥远。",
  ["~zhanghua"] = "桑化为柏，此非不祥乎？",
}

local dongtuna = General(extension, "dongtuna", "qun", 4)
local jianman = fk.CreateTriggerSkill{
  name = "jianman",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      player.tag[self.name] = player.tag[self.name] or {}
      if #player.tag[self.name] < 2 then
        player.tag[self.name] = {}
        return
      end
      local n = 0
      if player.tag[self.name][1][1] == player.id then
        n = n + 1
      end
      if player.tag[self.name][2][1] == player.id then
        n = n + 1
      end
      self.cost_data = {}
      if n == 2 then
        for i = 1, 2, 1 do
          if player.tag[self.name][i][2].name ~= "jink" then
            table.insertIfNeed(self.cost_data, player.tag[self.name][i][2].name)
          end
        end
      elseif n == 1 then
        if player.tag[self.name][1][1] == player.id then
          self.cost_data = player.tag[self.name][2][1]
        else
          self.cost_data = player.tag[self.name][1][1]
        end
      else
        player.tag[self.name] = {}
        return
      end
      player.tag[self.name] = {}
      return self.cost_data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "number" then
      room:doIndicate(player.id, {self.cost_data})
      local to = room:getPlayerById(self.cost_data)
      if to:isNude() then return end
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard(card, self.name, to, player)
    else
      local name = room:askForChoice(player, self.cost_data, self.name, "#jianman-choice")
      local targets = {}
      if string.find(name, "slash") then
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not player:isProhibited(p, Fk:cloneCard(name)) end), function(p) return p.id end)
      else
        targets = {player.id}
      end
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#jianman-choose:::"..name, self.name, false)
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        room:useVirtualCard(name, nil, player, room:getPlayerById(to), self.name, true)
      end
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card.type == Card.TypeBasic and not table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.tag[self.name] = player.tag[self.name] or {}
    table.insert(player.tag[self.name], {target.id, data.card})
  end,
}
dongtuna:addSkill(jianman)
Fk:loadTranslationTable{
  ["dongtuna"] = "董荼那",
  ["jianman"] = "鹣蛮",
  [":jianman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均为你，你视为使用其中的一张牌；仅其中之一为你，你弃置另一名使用者一张牌。",
  ["#jianman-choice"] = "选择视为使用的牌名",
  ["#jianman-choose"] = "鹣蛮：选择视为使用【%arg】的目标",

  ["$jianman1"] = "鹄巡山野，见腐羝而聒鸣！",
  ["$jianman2"] = "我蛮夷也，进退可无矩。",
  ["~dongtuna"] = "孟获小儿，安敢杀我！",
}

local zhangyi = General(extension, "ol__zhangyiy", "shu", 4)
local dianjun = fk.CreateTriggerSkill{
  name = "dianjun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.NotActive
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player,
      damage = 1,
      skillName = self.name,
    }
    player:gainAnExtraPhase(Player.Play)
  end,
}
local kangrui = fk.CreateTriggerSkill{
  name = "kangrui",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase ~= Player.NotActive and not target.dead then
      if target:getMark("kangrui-turn") == 0 then
        player.room:addPlayerMark(target, "kangrui-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#kangrui-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local choice = room:askForChoice(player, {"recover", "kangrui_damage"}, self.name, "#kangrui-choice::"..target.id)
    if choice == "recover" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    else
      room:addPlayerMark(target, "kangrui_damage-turn", 1)
    end
  end,

  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("kangrui_damage-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + 1
    player.room:setPlayerMark(player, "kangrui_minus-turn", 1)
    player.room:setPlayerMark(player, "kangrui_damage-turn", 0)
  end,
}
local kangrui_maxcards = fk.CreateMaxCardsSkill{
  name = "#kangrui_maxcards",
  fixed_func = function(self, player)
    if player:getMark("kangrui_minus-turn") > 0 then
      return 0
    end
  end
}
kangrui:addRelatedSkill(kangrui_maxcards)
zhangyi:addSkill(dianjun)
zhangyi:addSkill(kangrui)
Fk:loadTranslationTable{
  ["ol__zhangyiy"] = "张翼",
  ["dianjun"] = "殿军",
  [":dianjun"] = "锁定技，回合结束时，你受到1点伤害并执行一个额外的出牌阶段。",
  ["kangrui"] = "亢锐",
  [":kangrui"] = "当一名角色于其回合内首次受到伤害后，你可以摸一张牌并令其：1.回复1点体力；2.本回合下次造成的伤害+1，然后当其造成伤害时，其此回合手牌上限改为0。",
  ["#kangrui-invoke"] = "亢锐：你可以摸一张牌，令 %dest 回复1点体力或本回合下次造成伤害+1",
  ["kangrui_damage"] = "本回合下次造成伤害+1，造成伤害后本回合手牌上限改为0",
  ["#kangrui-choice"] = "亢锐：选择令 %dest 执行的一项",

  ["$dianjun1"] = "大将军勿忧，翼可领后军。",
  ["$dianjun2"] = "诸将速行，某自领军殿后！",
  ["$kangrui1"] = "尔等魍魉，愿试吾剑之利乎！",
  ["$kangrui2"] = "诸君努力，克复中原指日可待！",
  ["~ol__zhangyiy"] = "伯约不见疲惫之国力乎？",
}

local maxiumatie = General(extension, "maxiumatie", "qun", 4)
local kenshang = fk.CreateViewAsSkill{
  name = "kenshang",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return true
  end,
  view_as = function(self, cards)
    if #cards < 2 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not player:isProhibited(p, use.card) end), function(p) return p.id end)
    local n = math.min(#targets, #use.card.subcards)
    local tos = room:askForChoosePlayers(player, targets, n, n, "#kenshang-choose:::"..n, self.name, false)
    if #tos > 0 then
      table.forEach(TargetGroup:getRealTargets(use.tos), function (id)
        TargetGroup:removeTarget(use.tos, id)
      end)
      for _, id in ipairs(tos) do
        TargetGroup:pushTargets(use.tos, id)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return player:hasSkill(self.name) and not response
  end,
}
local kenshang_record = fk.CreateTriggerSkill{
  name = "#kenshang_record",

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "kenshang") and data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room:getAllPlayers()) do
      if data.damageDealt[p.id] then
        n = n + data.damageDealt[p.id]
      end
    end
    if #data.card.subcards > n then
      player:drawCards(1, "kenshang")
    end
  end,
}
kenshang:addRelatedSkill(kenshang_record)
maxiumatie:addSkill("mashu")
maxiumatie:addSkill(kenshang)
Fk:loadTranslationTable{
  ["maxiumatie"] = "马休马铁",
  ["kenshang"] = "垦伤",
  [":kenshang"] = "你可以将至少两张牌当【杀】使用，然后目标可以改为等量的角色。你以此法使用的【杀】结算后，若这些牌数大于此牌造成的伤害，你摸一张牌。",
  ["#kenshang-choose"] = "垦伤：你可以将目标改为指定%arg名角色",

  ["$kenshang1"] = "择兵选将，一击而大白。",
  ["$kenshang2"] = "纵横三辅，垦伤庸富。",
  ["~maxiumatie"] = "我兄弟，愿随父帅赴死。",
}

local zhujun = General(extension, "ol__zhujun", "qun", 4)
local cuipo = fk.CreateTriggerSkill{
  name = "cuipo",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("@cuipo-turn") == #Fk:translate(data.card.trueName)/3
  end,
  on_use = function(self, event, target, player, data)
    if data.card.is_damage_card then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@cuipo-turn", 1)
  end,
}
zhujun:addSkill(cuipo)
Fk:loadTranslationTable{
  ["ol__zhujun"] = "朱儁",
  ["cuipo"] = "摧破",
  [":cuipo"] = "锁定技，当你每回合使用第X张牌时（X为此牌牌名字数），若为【杀】或伤害锦囊牌，此牌伤害+1，否则你摸一张牌。",
  ["@cuipo-turn"] = "摧破",

  ["$cuipo1"] = "虎贲冯河，何惧千城！",
  ["$cuipo2"] = "长锋在手，万寇辟易。",
  ["~ol__zhujun"] = "李郭匹夫，安敢辱我！",
}

local wangguan = General(extension, "wangguan", "wei", 3)
local miuyan = fk.CreateViewAsSkill{
  name = "miuyan",
  anim_type = "switch",
  switch_skill_name = "miuyan",
  pattern = "fire_attack",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@@miuyan-round") == 0
  end,
}
local miuyan_trigger = fk.CreateTriggerSkill{
  name = "#miuyan_trigger",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("miuyan") and table.contains(data.card.skillNames, "miuyan")
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState("miuyan", true) == fk.SwitchYang and data.damageDealt then
      local moveInfos = {}
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p:isKongcheng() then
          local cards = {}
          for _, id in ipairs(p.player_cards[Player.Hand]) do
            if Fk:getCardById(id):getMark("miuyan") > 0 then
              table.insertIfNeed(cards, id)
            end
          end
          if #cards > 0 then
            table.insert(moveInfos, {
              from = p.id,
              ids = cards,
              to = player.id,
              toArea = Card.PlayerHand,
              moveReason = fk.ReasonPrey,
              proposer = player.id,
              skillName = "miuyan",
            })
          end
        end
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
    elseif player:getSwitchSkillState("miuyan", true) == fk.SwitchYin and not data.damageDealt then
      room:setPlayerMark(player, "@@miuyan-round", 1)
    end
  end,

  refresh_events = {fk.CardShown, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardShown then
      for _, id in ipairs(data.cardIds) do
        room:setCardMark(Fk:getCardById(id), "miuyan", 1)
      end
    else
      for _, id in ipairs(Fk:getAllCardIds()) do
        room:setCardMark(Fk:getCardById(id), "miuyan", 0)
      end
    end
  end,
}
local shilu = fk.CreateTriggerSkill{
  name = "shilu",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.hp, self.name)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) and not p:isKongcheng() end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#shilu-choose", self.name, false)
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    local id = room:askForCardChosen(player, to, "h", self.name)
    to:showCards(id)
    if room:getCardArea(id) == Card.PlayerHand then
      room:setCardMark(Fk:getCardById(id), "@@shilu", 1)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
  local room = player.room
    for _, move in ipairs(data) do
      if move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@shilu", 0)
        end
      end
    end
  end,
}
local shilu_filter = fk.CreateFilterSkill{
  name = "#shilu_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@shilu") > 0
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
miuyan:addRelatedSkill(miuyan_trigger)
shilu:addRelatedSkill(shilu_filter)
wangguan:addSkill(miuyan)
wangguan:addSkill(shilu)
Fk:loadTranslationTable{
  ["wangguan"] = "王瓘",
  ["miuyan"] = "谬焰",
  [":miuyan"] = "转换技，阳：你可以将一张黑色牌当【火攻】使用，若此牌造成伤害，你获得本阶段展示过的所有手牌；"..
  "阴：你可以将一张黑色牌当【火攻】使用，若此牌未造成伤害，本轮本技能失效。",
  ["shilu"] = "失路",
  [":shilu"] = "锁定技，当你受到伤害后，你摸等同体力值张牌并展示攻击范围内一名其他角色的一张手牌，令此牌视为【杀】。",
  ["@@miuyan-round"] = "谬焰失效",
  ["#shilu-choose"] = "失路：展示一名角色的一张手牌，此牌视为【杀】",
  ["@@shilu"] = "失路",
  ["#shilu_filter"] = "失路",
}

local luoxian = General(extension, "luoxian", "shu", 4)
local daili = fk.CreateTriggerSkill{
  name = "daili",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (player:isKongcheng() or
      #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@daili") > 0 end) % 2 == 0)
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    local cards = player:drawCards(3, self.name)
    player:showCards(cards)
  end,

  refresh_events = {fk.CardShown, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardShown then
      return target == player and player:hasSkill(self.name, true)
    else
      return player:getMark("@$daili") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$daili")
    if event == fk.CardShown then
      if mark == 0 then mark = {} end
      for _, id in ipairs(data.cardIds) do
        if Fk:getCardById(id):getMark("@@daili") == 0 then
          table.insert(mark, Fk:getCardById(id, true).name)
          room:setCardMark(Fk:getCardById(id, true), "@@daili", 1)
        end
      end
      room:setPlayerMark(player, "@$daili", mark)
    else
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId, true):getMark("@@daili") > 0 then
              table.removeOne(mark, Fk:getCardById(info.cardId, true).name)
              room:setCardMark(Fk:getCardById(info.cardId, true), "@@daili", 0)
            end
          end
        end
      end
      room:setPlayerMark(player, "@$daili", mark)
    end
  end,
}
luoxian:addSkill(daili)
Fk:loadTranslationTable{
  ["luoxian"] = "罗宪",
  ["daili"] = "带砺",
  [":daili"] = "每回合结束时，若你有偶数张展示过的手牌，你可以翻面，摸三张牌并展示之。",
  ["@$daili"] = "带砺",
  ["@@daili"] = "带砺",

  ["$daili1"] = "国朝倾覆，吾宁当为降虏乎！",
  ["$daili2"] = "弃百姓之所仰，君子不为也。",
  ["~luoxian"] = "汉亡矣，命休矣……",
}

local sunhong = General(extension, "sunhong", "wu", 3)
local xianbi = fk.CreateActiveSkill{
  name = "xianbi",
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
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and #Self.player_cards[Player.Hand] ~= #target.player_cards[Player.Equip] and target:getMark("zenrun") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #player.player_cards[Player.Hand] - #target.player_cards[Player.Equip]
    if n < 0 then
      player:drawCards(-n, self.name)
    else
      local cards = room:askForDiscard(player, n, n, false, self.name, false, ".", "#xianbi-discard:::"..n)
      for _, id in ipairs(cards) do
        local get = {}
        local card = Fk:getCardById(id, true)
        table.insertTable(get, room:getCardsFromPileByRule(".|.|.|.|.|"..card:getTypeString().."|^"..id, 1, "discardPile"))
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local zenrun = fk.CreateTriggerSkill{
  name = "zenrun",
  events = {fk.BeforeDrawCard},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = data.num
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p:getMark(self.name) == 0 and #p:getCardIds{Player.Hand, Player.Equip} >= n end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zenrun-choose:::"..n, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = data.num
    data.num = 0
    local dummy = Fk:cloneCard("dilu")
    local cards = room:askForCardsChosen(player, to, n, n, "he", self.name)
    dummy:addSubcards(cards)
    room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    local choice = room:askForChoice(to, {"zenrun_draw", "zenrun_forbid"}, self.name, "#zenrun-choice:"..player.id)
    if choice == "zenrun_draw" then
      to:drawCards(n, self.name)
    else
      room:addPlayerMark(to, self.name, 1)
    end
  end,
}
sunhong:addSkill(xianbi)
sunhong:addSkill(zenrun)
Fk:loadTranslationTable{
  ["sunhong"] = "孙弘",
  ["xianbi"] = "险诐",
  [":xianbi"] = "出牌阶段限一次，你可以将手牌调整至与一名角色装备区里的牌数相同，然后每因此弃置一张牌，你随机获得弃牌堆中另一张类型相同的牌。",
  ["zenrun"] = "谮润",
  [":zenrun"] = "每阶段限一次，当你摸牌时，你可以改为获得一名其他角色等量张牌，然后其选择一项："..
  "1.摸等量的牌；2.本局游戏中你发动〖险诐〗和〖谮润〗不能指定其为目标。",
  ["#xianbi-discard"] = "险诐：弃置%arg张手牌，然后随机获得弃牌堆中相同类别的牌",
  ["#zenrun-choose"] = "谮润：你可以将摸牌改为获得一名其他角色%arg张牌，然后其选择摸等量牌或你本局不能对其发动技能",
  ["#zenrun-choice"] = "谮润：选择 %src 令你执行的一项",
  ["zenrun_draw"] = "你摸等量牌",
  ["zenrun_forbid"] = "其本局不能对你发动〖险诐〗和〖谮润〗",

  ["$xianbi1"] = "宦海如薄冰，求生逐富贵。",
  ["$xianbi2"] = "吾不欲为鱼肉，故为刀俎。",
  ["$zenrun1"] = "据图谋不轨，今奉诏索命。",
  ["$zenrun2"] = "休妄论芍陂之战，当诛之。",
  ["~sunhong"] = "诸葛公何至于此……",
}

local zhangshiping = General(extension, "zhangshiping", "shu", 3)
local hongji = fk.CreateTriggerSkill{
  name = "hongji",
  events = {fk.EventPhaseStart},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = ""
    if table.every(room:getOtherPlayers(target), function(p) return p:getHandcardNum() >= target:getHandcardNum() end) then
      prompt = "hongji1"
    end
    if table.every(room:getOtherPlayers(target), function(p) return p:getHandcardNum() <= target:getHandcardNum() end) then
      prompt = "hongji2"
    end
    if prompt == "" then return end
    if room:askForSkillInvoke(player, self.name, nil, "#"..prompt.."-invoke::"..target.id) then
      self.cost_data = prompt
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    player.room:setPlayerMark(target, self.cost_data.."-turn", 1)
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and ((player:getMark("hongji1-turn") > 0 and data.from == Player.Draw) or
      (player:getMark("hongji2-turn") > 0 and data.from == Player.Play))
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.from == Player.Draw then
      room:setPlayerMark(player, "hongji1-turn", 0)
      player:gainAnExtraPhase(Player.Draw)
    else
      room:setPlayerMark(player, "hongji2-turn", 0)
      player:gainAnExtraPhase(Player.Play)
    end
  end,
}
local xinggu = fk.CreateTriggerSkill{
  name = "xinggu",
  anim_type = "support",
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        return target == player and player.phase == Player.Finish and #player:getPile(self.name) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      return player.room:askForUseActiveSkill(player, "xinggu_active", "#xinggu-invoke", true)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).sub_type == Card.SubtypeOffensiveRide or Fk:getCardById(id).sub_type == Card.SubtypeDefensiveRide then
          table.insertIfNeed(cards, id)
        end
      end
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(table.random(cards, 3))
      player:addToPile(self.name, dummy, true, self.name)
    else
      local card = room:getCardsFromPileByRule(".|.|diamond")
      if #card > 0 then
        room:moveCards({
          ids = card,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
local xinggu_active = fk.CreateActiveSkill{
  name = "xinggu_active",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  expand_pile = "xinggu",
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "xinggu"
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and #cards == 1 and to_select ~= Self.id and
      Fk:currentRoom():getPlayerById(to_select):getEquipment(Fk:getCardById(cards[1]).sub_type) == nil
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      to = target.id,
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonPut,
      fromSpecialName = "xinggu",
    })
  end,
}
Fk:addSkill(xinggu_active)
zhangshiping:addSkill(hongji)
zhangshiping:addSkill(xinggu)
Fk:loadTranslationTable{
  ["zhangshiping"] = "张世平",
  ["hongji"] = "鸿济",
  [":hongji"] = "每轮各限一次，每名角色的准备阶段，若其手牌数为全场最少/最多，你可以令其于本回合摸牌/出牌阶段后额外执行一个摸牌/出牌阶段。",
  ["xinggu"] = "行贾",
  [":xinggu"] = "游戏开始时，你将随机三张坐骑牌置于你的武将牌上。结束阶段，你可以将其中一张牌置于一名其他角色的装备区，"..
  "然后你获得牌堆中一张<font color='red'>♦</font>牌。",
  ["#hongji1-invoke"] = "鸿济：你可以令 %dest 本回合摸牌阶段后额外执行一个摸牌阶段",
  ["#hongji2-invoke"] = "鸿济：你可以令 %dest 本回合出牌阶段后额外执行一个出牌阶段",
  ["#xinggu-invoke"] = "行贾：你可以将一张“行贾”坐骑置入一名其他角色的装备区，然后获得一张<font color='red'>♦</font>牌",
  ["xinggu_active"] = "行贾",
}

local lushi = General(extension, "lushi", "qun", 3, 3, General.Female)
local function setZhuyanMark(p)  --FIXME：先用个mark代替贴脸文字
  local room = p.room
  if p:getMark("zhuyan1") == 0 then
    local sig = ""
    local n = p:getMark("zhuyan")[1] - p.hp
    if n > 0 then
      sig = "+"
    end
    room:setPlayerMark(p, "@zhuyan1", sig..tostring(n))
  end
  if p:getMark("zhuyan2") == 0 then
    local sig = ""
    local n = p:getMark("zhuyan")[2] - p:getHandcardNum()
    if n > 0 then
      sig = "+"
    end
    room:setPlayerMark(p, "@zhuyan2", sig..tostring(n))
  end
end
local zhuyan = fk.CreateTriggerSkill{
  name = "zhuyan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room.alive_players, function(p)
      return p:getMark("zhuyan1") == 0 or p:getMark("zhuyan2") == 0 end), function(p) return p.id end)
    if #targets == 0 then return end
    for _, id in ipairs(targets) do
      local p = player.room:getPlayerById(id)
      setZhuyanMark(p)
    end
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#zhuyan-choose", self.name, true)
    for _, id in ipairs(targets) do
      local p = player.room:getPlayerById(id)
      player.room:setPlayerMark(p, "@zhuyan1", 0)
      player.room:setPlayerMark(p, "@zhuyan2", 0)
    end
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    setZhuyanMark(to)
    local choices = {}
    if to:getMark("zhuyan1") == 0 then
      table.insert(choices, "@zhuyan1")
    end
    if to:getMark("zhuyan2") == 0 then
      table.insert(choices, "@zhuyan2")
    end
    local choice = room:askForChoice(player, choices, self.name, "#zhuyan-choice::"..to.id)
    room:setPlayerMark(to, "@zhuyan1", 0)
    room:setPlayerMark(to, "@zhuyan2", 0)
    if choice == "@zhuyan1" then
      room:setPlayerMark(to, "zhuyan1", 1)
      local n = to:getMark(self.name)[1] - to.hp
      if n > 0 then
        if to:isWounded() then
          room:recover({
            who = to,
            num = math.min(to:getLostHp(), n),
            recoverBy = player,
            skillName = self.name
          })
        end
      elseif n < 0 then
        room:loseHp(to, -n, self.name)
      end
    else
      room:setPlayerMark(to, "zhuyan2", 1)
      local n = to:getMark(self.name)[2] - to:getHandcardNum()
      if n > 0 then
        to:drawCards(n, self.name)
      elseif n < 0 then
        room:askForDiscard(to, -n, -n, false, self.name, false)
      end
    end
  end,

  refresh_events = {fk.GameStart , fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      return target == player and player.phase == Player.Start
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, {player.hp, math.min(player:getHandcardNum(), 5)})
  end,
}
local leijie = fk.CreateTriggerSkill{
  name = "leijie",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function (p)
      return p.id end), 1, 1, "#leijie-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local judge = {
      who = to,
      reason = self.name,
      pattern = ".|2~9|spade",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade and judge.card.number >= 2 and judge.card.number <= 9 then
      room:damage{
        to = to,
        damage = 2,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    else
      to:drawCards(2, self.name)
    end
  end,
}
lushi:addSkill(zhuyan)
lushi:addSkill(leijie)
Fk:loadTranslationTable{
  ["lushi"] = "卢氏",
  ["zhuyan"] = "驻颜",
  [":zhuyan"] = "结束阶段，你可以令一名角色将以下项调整至与其上个准备阶段结束时（若无则改为游戏开始时）相同：体力值；手牌数（至多摸至五张）。"..
  "每名角色每项限一次",
  ["leijie"] = "雷劫",
  [":leijie"] = "准备阶段，你可以令一名角色判定，若结果为♠2~9，其受到2点雷电伤害，否则其摸两张牌。",
  ["#zhuyan-choose"] = "驻颜：你可以令一名角色将体力值或手牌数调整至与其上个准备阶段相同",
  ["#zhuyan-choice"] = "驻颜：选择令 %dest 调整的一项",
  ["#leijie-choose"] = "雷劫：令一名角色判定，若为♠2~9，其受到2点雷电伤害，否则其摸两张牌",

  ["@zhuyan1"] = "体力",
  ["@zhuyan2"] = "手牌",

  ["$zhuyan1"] = "心有灵犀，面如不老之椿。",
  ["$zhuyan2"] = "驻颜有术，此间永得芳容。",
  ["$leijie1"] = "雷劫锻体，清瘴涤魂。",
  ["$leijie2"] = "欲得长生，必受此劫。",
  ["~lushi"] = "人世寻大道，何其愚也……",
}

local zhouqun = General(extension, "ol__zhouqun", "shu", 4)
local tianhou = fk.CreateTriggerSkill{
  name = "tianhou",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and (player:hasSkill(self.name) or player:getMark(self.name) ~= 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) ~= 0 then
      local p = room:getPlayerById(player:getMark(self.name)[1])
      if p:hasSkill(player:getMark(self.name)[2], true, true) then
        room:handleAddLoseSkills(p, "-"..player:getMark(self.name)[2], nil, true, false)
      end
    end
    if not player:hasSkill(self.name) then return end
    local piles = room:askForExchange(player, {room:getNCards(1), player:getCardIds{Player.Hand, Player.Equip}},
      {"Top", player.general}, self.name)
    if room:getCardOwner(piles[1][1]) == player then
      local cards1, cards2 = {piles[1][1]}, {}
      for _, id in ipairs(piles[2]) do
        if room:getCardArea(id) ~= Player.Hand then
          table.insert(cards2, id)
          break
        end
      end
      local move1 = {
        ids = cards1,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      local move2 = {
        ids = cards2,
        to = player.id,
        toArea = Player.Hand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      room:moveCards(move1, move2)
    else
      table.insert(room.draw_pile, 1, piles[1][1])
    end
    local card = room:getNCards(1)
    room:moveCards({
      ids = card,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:sendFootnote(card, {
      type = "##ShowCard",
      from = player.id,
    })
    local suits = {Card.Heart, Card.Diamond, Card.Spade, Card.Club}
    local i = table.indexOf(suits, Fk:getCardById(card[1], true).suit)
    local targets = table.map(room.alive_players, function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1,
      "#tianhou-choose:::".."tianhou"..i..":"..Fk:translate(":tianhou"..i), self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    room:moveCards({
      ids = card,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:setPlayerMark(player, self.name, {to.id, "tianhou"..i})
    room:handleAddLoseSkills(to, "tianhou"..i, nil, true, false)
  end,
}
local tianhou1 = fk.CreateTriggerSkill{
  name = "tianhou1",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Finish and not target.dead and
      table.every(player.room:getOtherPlayers(target), function(p) return target.hp >= p.hp end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, self.name)
  end,
}
local tianhou2 = fk.CreateTriggerSkill{
  name = "tianhou2",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) and data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 then
      local to = player.room:getPlayerById(AimGroup:getAllTargets(data.tos)[1])
      return to:getNextAlive() ~= target and target:getNextAlive() ~= to
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.card.number
    local pattern = ".|14"
    if n < 13 then
      pattern = ".|"..tostring(n + 1).."~13"
    end
    local judge = {
      who = target,
      reason = self.name,
      pattern = pattern,
    }
    room:judge(judge)
    if judge.card.number > data.card.number then
      data.nullifiedTargets = table.map(room.alive_players, function(p) return p.id end)
    end
  end,
}
local tianhou3 = fk.CreateTriggerSkill{
  name = "tianhou3",
  anim_type = "offensive",
  events = {fk.DamageCaused, fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.DamageCaused then
        return target ~= player and data.damageType == fk.FireDamage
      else
        return data.damageType == fk.ThunderDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return true
    else
      local room = player.room
      for _, p in ipairs(room:getOtherPlayers(data.to)) do
        if not p.dead and p:getMark("tianhou_lose") > 0 then
          room:loseHp(p, 1, self.name)
        end
      end
    end
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.damageType == fk.ThunderDamage
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if target:getNextAlive() == p or p:getNextAlive() == target then
        room:setPlayerMark(p, "tianhou_lose", 1)
      else
        room:setPlayerMark(p, "tianhou_lose", 0)
      end
    end
  end,
}
local tianhou4 = fk.CreateTriggerSkill{
  name = "tianhou4",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Finish and not target.dead and
      table.every(player.room:getOtherPlayers(target), function(p) return target.hp <= p.hp end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, self.name)
  end,
}
local chenshuo = fk.CreateTriggerSkill{
  name = "chenshuo",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true, ".", "#chenshuo-invoke")
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:showCards(self.cost_data)
    if player.dead then return end
    local card = Fk:getCardById(self.cost_data[1])
    local dummy = Fk:cloneCard("dilu")
    for i = 1, 3, 1 do
      local get = room:getNCards(1)
      room:moveCards{
        ids = get,
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      dummy:addSubcard(get[1])
      local card2 = Fk:getCardById(get[1], true)
      if card.type == card2.type or card.suit == card2.suit or card.number == card2.number or
        #Fk:translate(card.trueName) == #Fk:translate(card2.trueName) then
        room:setCardEmotion(get[1], "judgegood")
        room:delay(1000)
      else
        room:setCardEmotion(get[1], "judgebad")
        room:delay(1000)
        break
      end
    end
    room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
  end,
}
zhouqun:addSkill(tianhou)
zhouqun:addSkill(chenshuo)
zhouqun:addRelatedSkill(tianhou1)
zhouqun:addRelatedSkill(tianhou2)
zhouqun:addRelatedSkill(tianhou3)
zhouqun:addRelatedSkill(tianhou4)
Fk:loadTranslationTable{
  ["ol__zhouqun"] = "周群",
  ["tianhou"] = "天候",
  [":tianhou"] = "锁定技，准备阶段，你观看牌堆顶牌并选择是否用一张牌交换之，然后展示牌堆顶的牌，令一名角色根据此牌花色获得技能直到你下个准备阶段："..
  "<font color='red'>♥</font>〖烈暑〗；<font color='red'>♦</font>〖凝雾〗；♠〖骤雨〗；♣〖严霜〗。",
  ["chenshuo"] = "谶说",
  [":chenshuo"] = "结束阶段，你可以展示一张手牌。若如此做，展示牌堆顶牌，若两张牌类型/花色/点数/牌名字数中任意项相同且展示牌数不大于3，重复此流程。"..
  "然后你获得以此法展示的牌。",
  ["tianhou1"] = "烈暑",
  [":tianhou1"] = "锁定技，其他角色的结束阶段，若其体力值全场最大，其失去1点体力。",
  ["tianhou2"] = "凝雾",
  [":tianhou2"] = "锁定技，当其他角色使用【杀】指定不与其相邻的角色为唯一目标时，其判定，若判定牌点数大于此【杀】，此【杀】无效。",
  ["tianhou3"] = "骤雨",
  [":tianhou3"] = "锁定技，防止其他角色造成的火焰伤害。当一名角色受到雷电伤害后，其相邻的角色失去1点体力。",
  ["tianhou4"] = "严霜",
  [":tianhou4"] = "锁定技，其他角色的结束阶段，若其体力值全场最小，其失去1点体力。",
  ["#tianhou-choose"] = "天候：令一名角色获得技能<br>〖%arg〗：%arg2",
  ["#chenshuo-invoke"] = "谶说：你可以展示一张手牌，亮出并获得牌堆顶至多三张相同类型/花色/点数/字数的牌",
}

Fk:loadTranslationTable{
  ["ol__liuyan"] = "刘焉",
  ["pianan"] = "偏安",
  [":pianan"] = "锁定技，游戏开始时和你的弃牌阶段结束时，你弃置不为【闪】的手牌并从牌堆或弃牌堆获得【闪】至你的体力值。",
  ["yinji"] = "殷积",
  [":yinji"] = "锁定技结束阶段，若你不是体力值唯一最大的角色，你回复1点体力或增加1点体力上限。",
  ["kuisi"] = "窥伺",
  [":kuisi"] = "锁定技，你跳过摸牌阶段，改为观看牌堆顶的4张牌并使用其中任意张，若你以此法使用的牌数不为2或3，你减少1点体力上限。",
}

--曹羲 成济成倅
--local caoxi = General(extension, "caoxi", "wei", 3)

local haopu = General(extension, "haopu", "shu", 4)
local zhenying = fk.CreateActiveSkill{
  name = "zhenying",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#zhenying",
  can_use = function(self, player)
    return player:usedCardTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:getHandcardNum() >= Fk:currentRoom():getPlayerById(to_select):getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local tos = {player, target}
    for _, p in ipairs(tos) do
      local choices = {"0", "1", "2"}
      p.request_data = json.encode({choices, choices, self.name, "#zhenying-choice"})
    end
    room:notifyMoveFocus(tos, self.name)
    room:doBroadcastRequest("AskForChoice", tos)
    for _, p in ipairs(tos) do
      local n
      if p.reply_ready then
        n = p:getHandcardNum() - tonumber(p.client_reply)
      else
        n = p:getHandcardNum() - 2
      end
      room:setPlayerMark(p, "zhenying-tmp", n)
      if n > 0 then
        local extraData = {
          num = n,
          min_num = n,
          include_equip = false,
          pattern = ".",
          reason = self.name,
        }
        p.request_data = json.encode({ "choose_cards_skill", "#zhenying-discard:::"..n, true, json.encode(extraData) })
      end
    end
    room:notifyMoveFocus(tos, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", tos)
    for _, p in ipairs(tos) do
      local n = p:getMark("zhenying-tmp")
      if n < 0 then
        p:drawCards(-n, self.name)
      elseif n > 0 then
        if p.reply_ready then
          local replyCard = json.decode(p.client_reply).card
          room:throwCard(json.decode(replyCard).subcards, self.name, p, p)
        else
          room:throwCard(table.random(p:getCardIds("h"), n), self.name, p, p)
        end
      end
      room:setPlayerMark(p, "zhenying-tmp", 0)
    end
    if not player.dead and not target.dead and player:getHandcardNum() ~= target:getHandcardNum() then
      local from, to = player, target
      if player:getHandcardNum() > target:getHandcardNum() then
        from, to = target, player
      end
      room:useVirtualCard("duel", nil, from, to, self.name)
    end
  end,
}
haopu:addSkill(zhenying)
Fk:loadTranslationTable{
  ["haopu"] = "郝普",
  ["zhenying"] = "震荧",
  [":zhenying"] = "出牌阶段限两次，你可以与一名手牌数不大于你的其他角色同时摸或弃置手牌至至多两张，然后手牌数较少的角色视为对另一名角色使用【决斗】。",
  ["#zhenying"] = "震荧：与一名角色同时选择将手牌调整至0~2",
  ["#zhenying-choice"] = "震荧：选择你要调整至的手牌数",
  ["#zhenying-discard"] = "震荧：请弃置%arg张手牌",
}

local mengda = General(extension, "ol__mengda", "shu", 4)
mengda.subkingdom = "wei"
local goude = fk.CreateTriggerSkill{
  name = "goude",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.to == Player.NotActive then
      local room = player.room
      for _, p in ipairs(room.alive_players) do
        if p.kingdom == player.kingdom then
          local events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            local move = e.data[1]
            if move.to == p.id and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw and #move.moveInfo == 1 then
              return true
            elseif move.moveReason == fk.ReasonDiscard and (move.proposer == p or move.proposer == p.id) and #move.moveInfo == 1 then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand then
                  return true
                end
              end
            end
          end, Player.HistoryTurn)
          if #events > 0 then return true end
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            local use = e.data[1]
            return use.from == p.id and use.card.trueName == "slash" and use.card:getEffectiveId() == nil
          end, Player.HistoryTurn)
          if #events > 0 then return true end
          events = room.logic:getEventsOfScope(GameEvent.SkillEffect, 1, function(e)
            local dat = e.data
            return dat[2] == p and table.contains({"huashen", "os__chijie", "bianzhuang", "qyt__lianli"}, dat[3].name)  --FIXME: 耦！
          end, Player.HistoryTurn)
          if #events > 0 then return true end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel", "draw1", "goude2", "goude3", "goude4"}
    if table.every(room.alive_players, function(pl) return pl:isKongcheng() end) then
      table.removeOne(choices, "goude2")
    end
    for _, p in ipairs(room.alive_players) do
      if p.kingdom == player.kingdom then
        local events
        if table.contains(choices, "draw1") then
          events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            local move = e.data[1]
            if move.to == p.id and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw and #move.moveInfo == 1 then
              return true
            end
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "draw1")
          end
        end
        if table.contains(choices, "goude2") then
          events = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            local move = e.data[1]
            if move.to == p.id and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw and #move.moveInfo == 1 then
              return true
            end
            if move.moveReason == fk.ReasonDiscard and (move.proposer == p or move.proposer == p.id) and #move.moveInfo == 1 then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand then
                  return true
                end
              end
            end
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "goude2")
          end
        end
        if table.contains(choices, "goude3") then
          events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            local use = e.data[1]
            return use.from == p.id and use.card.trueName == "slash" and use.card:getEffectiveId() == nil
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "goude3")
          end
        end
        if table.contains(choices, "goude4") then
          events = room.logic:getEventsOfScope(GameEvent.SkillEffect, 1, function(e)
            local dat = e.data
            return dat[2] == p and table.contains({"huashen", "os__chijie", "bianzhuang", "qyt__lianli"}, dat[3].name)  --FIXME: 耦！
          end, Player.HistoryTurn)
          if #events > 0 then
            table.removeOne(choices, "goude4")
          end
        end
      end
    end
    if #choices == 1 then return end
    local choice
    while choice ~= "Cancel" do
      choice = room:askForChoice(player, choices, self.name, "#goude-choice", false, {"Cancel", "draw1", "goude2", "goude3", "goude4"})
      if choice == "draw1" or choice == "goude4" then
        self.cost_data = {choice}
        return true
      elseif choice == "goude2" then
        local targets = table.map(table.filter(room.alive_players, function(pl)
          return not pl:isKongcheng() end), function(pl) return pl.id end)
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#goude-choose", self.name, true)
        if #to > 0 then
          self.cost_data = {choice, to[1]}
          return true
        end
      elseif choice == "goude3" then
        local success, dat = room:askForUseActiveSkill(player, "goude_viewas", "#goude-slash", true)
        if success then
          self.cost_data = {choice, dat}
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[1] == "draw1" then
      player:drawCards(1, self.name)
    elseif self.cost_data[1] == "goude2" then
      local to = room:getPlayerById(self.cost_data[2])
      local id = room:askForCardChosen(player, to, "h", self.name)
      room:throwCard({id}, self.name, to, player)
    elseif self.cost_data[1] == "goude3" then
      local card = Fk.skills["goude_viewas"]:viewAs(self.cost_data[2].cards)
      room:useCard{
        from = player.id,
        tos = table.map(self.cost_data[2].targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    elseif self.cost_data[1] == "goude4" then
      local allKingdoms = {}
      allKingdoms = table.simpleClone(Fk.kingdoms)
      local exceptedKingdoms = {"god", player.kingdom}
      for _, kingdom in ipairs(exceptedKingdoms) do
        table.removeOne(allKingdoms, kingdom)
      end
      player.kingdom = room:askForChoice(player, allKingdoms, "AskForKingdom", "#ChooseInitialKingdom")
      room:broadcastProperty(player, "kingdom")
    end
  end,
}
local goude_viewas = fk.CreateViewAsSkill{
  name = "goude_viewas",
  pattern = "slash",
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = "goude"
    return card
  end,
}
Fk:addSkill(goude_viewas)
mengda:addSkill(goude)
Fk:loadTranslationTable{
  ["ol__mengda"] = "孟达",
  ["goude"] = "苟得",
  [":goude"] = "每回合结束时，若有势力相同的角色此回合执行过以下效果，你可以执行另一项：1.摸一张牌；2.弃置一名角色一张手牌；"..
  "3.视为使用一张【杀】；4.变更势力。",
  ["#goude-choice"] = "苟得：你可以选择执行一项",
  ["goude2"] = "弃置一名角色一张手牌",
  ["goude3"] = "视为使用一张【杀】",
  ["goude4"] = "变更势力",
  ["#goude-choose"] = "苟得：选择一名角色，弃置其一张手牌",
  ["#goude-slash"] = "苟得：视为使用一张【杀】",
  ["goude_viewas"] = "苟得",
}

local wenqin = General(extension, "ol__wenqin", "wei", 4)
wenqin.subkingdom = "wu"
local guangao = fk.CreateTriggerSkill{
  name = "guangao",
  anim_type = "control",
  events = {fk.TargetSpecifying, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.card.trueName == "slash" then
      if event == fk.TargetSpecifying then
        return target == player and table.find(player.room:getOtherPlayers(player), function(p)
          return not table.contains(AimGroup:getAllTargets(data.tos), p.id) and
            not player:isProhibited(p, data.card) and player:inMyAttackRange(p) end)
      else
        return data.extra_data and data.extra_data.guangao and table.contains(data.extra_data.guangao, player.id) and
          player:getHandcardNum() % 2 == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecifying then
      local room = player.room
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not table.contains(AimGroup:getAllTargets(data.tos), p.id) and
          not player:isProhibited(p, data.card) and player:inMyAttackRange(p) end), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#guangao-choose:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecifying then
      for _, id in ipairs(self.cost_data) do
        room:doIndicate(player.id, {id})
        TargetGroup:pushTargets(data.targetGroup, id)
      end
      data.extra_data = data.extra_data or {}
      data.extra_data.guangao = data.extra_data.guangao or {}
      table.insertIfNeed(data.extra_data.guangao, player.id)
    else
      player:drawCards(1, self.name)
      local targets = AimGroup:getAllTargets(data.tos)
      local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#guangao-cancel:::"..data.card:toLogString(), self.name, true)
      if #tos > 0 then
        for _, id in ipairs(tos) do
          table.insertIfNeed(data.nullifiedTargets, id)
        end
      end
    end
  end,
}
local guangao_trigger = fk.CreateTriggerSkill{
  name = "#guangao_trigger",
  mute = true,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card.trueName == "slash" then
      return table.find(player.room:getOtherPlayers(player), function(p)
        return p:hasSkill("guangao") and not table.contains(AimGroup:getAllTargets(data.tos), p.id) and
        not player:isProhibited(p, data.card) and player:inMyAttackRange(p) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p:hasSkill("guangao") and not table.contains(AimGroup:getAllTargets(data.tos), p.id) and
      not player:isProhibited(p, data.card) and player:inMyAttackRange(p) end), function(p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#guangao2-choose:::"..data.card:toLogString(), "guangao", true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("guangao")
    data.extra_data = data.extra_data or {}
    data.extra_data.guangao = data.extra_data.guangao or {}
    for _, id in ipairs(self.cost_data) do
      room:notifySkillInvoked(room:getPlayerById(id), "guangao", "negative")
      room:doIndicate(player.id, {id})
      TargetGroup:pushTargets(data.targetGroup, id)
      table.insertIfNeed(data.extra_data.guangao, id)
    end
  end,
}
local huiqi = fk.CreateTriggerSkill{
  name = "huiqi",
  frequency = Skill.Wake,
  anim_type = "offensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and
      data.to == Player.NotActive and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
        table.insertIfNeed(targets, id)
      end
    end, Player.HistoryTurn)
    return #targets == 3 and table.contains(targets, player.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "xieju", nil, true, false)
    player:gainAnExtraTurn(true)
  end,
}
local xieju = fk.CreateActiveSkill{
  name = "xieju",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  prompt = "#xieju",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getMark("xieju-turn") ~= 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return Self:getMark("xieju-turn") ~= 0 and table.contains(Self:getMark("xieju-turn"), to_select)
  end,
  on_use = function(self, room, effect)
    for _, id in ipairs(effect.tos) do
      local target = room:getPlayerById(id)
      if not target.dead and target:canUse(Fk:cloneCard("slash")) then
        local success, dat = room:askForUseViewAsSkill(target, "xieju_viewas", "#xieju-slash", false)
        if success then
          local card = Fk.skills["xieju_viewas"]:viewAs(dat.cards)
          room:useCard{
            from = target.id,
            tos = table.map(dat.targets, function(id) return {id} end),
            card = card,
            extraUse = true,
          }
        end
      end
    end
  end,
}
local xieju_record = fk.CreateTriggerSkill{
  name = "#xieju_record",

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill("xieju", true)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("xieju-turn")
    if mark == 0 then mark = {} end
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      table.insertIfNeed(mark, id)
    end
    player.room:setPlayerMark(player, "xieju-turn", mark)
  end,
}
local xieju_viewas = fk.CreateViewAsSkill{
  name = "xieju_viewas",
  pattern = "slash",
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = "xieju"
    return card
  end,
}
local xieju_targetmod = fk.CreateTargetModSkill{
  name = "#xieju_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "xieju")
  end,
}
guangao:addRelatedSkill(guangao_trigger)
xieju:addRelatedSkill(xieju_record)
xieju:addRelatedSkill(xieju_targetmod)
Fk:addSkill(xieju_viewas)
wenqin:addSkill(guangao)
wenqin:addSkill(huiqi)
wenqin:addRelatedSkill(xieju)
Fk:loadTranslationTable{
  ["ol__wenqin"] = "文钦",
  ["guangao"] = "犷骜",
  [":guangao"] = "你使用【杀】可以额外指定一个目标；其他角色使用【杀】可以额外指定你为目标（均有距离限制）。以此法使用的【杀】指定目标后，"..
  "若你的手牌数为偶数，你摸一张牌，令此【杀】对任意名角色无效。",
  ["huiqi"] = "彗企",
  [":huiqi"] = "觉醒技，每个回合结束时，若本回合仅有包括你的三名角色成为过牌的目标，你获得〖偕举〗并执行一个额外回合。",
  ["xieju"] = "偕举",
  [":xieju"] = "出牌阶段限一次，你可以令任意名本回合成为过牌的目标的角色各视为使用一张【杀】。",
  ["#guangao-choose"] = "犷骜：你可以为此%arg额外指定一个目标",
  ["#guangao2-choose"] = "犷骜：此%arg可以额外指定有技能“犷骜”的角色为目标",
  ["#guangao-cancel"] = "犷骜：你可以令此%arg对任意名角色无效",
  ["#xieju"] = "偕举：你可以令任意名角色各视为使用一张【杀】",
  ["#xieju-slash"] = "偕举：请视为使用一张【杀】",
  ["xieju_viewas"] = "偕举",
}

return extension
