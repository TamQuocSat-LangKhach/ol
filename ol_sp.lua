local extension = Package("ol_sp")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_sp"] = "OL专属",
  ["ol"] = "OL",
  ["olz"] = "宗族",
  ["jin"] = "晋",
}

Fk:loadTranslationTable{
  ["zhugeke"] = "诸葛恪",
  ["aocai"] = "傲才",
  [":aocai"] = "当你于回合外需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌，若你观看的牌中有此牌，你可以使用或打出之。",
  ["duwu"] = "黩武",
  [":duwu"] = "出牌阶段，你可以弃置X张牌对你攻击范围内的一名其他角色造成1点伤害（X为该角色的体力值）。若你以此法令该角色进入濒死状态，则濒死状态结算后你失去1点体力，且本回合不能再发动“黩武”。",
}

local chengyu = General(extension, "chengyu", "wei", 3)
local shefu = fk.CreateTriggerSkill{
  name = "shefu",
  anim_type = "control",
  events ={fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and not player:isKongcheng()
      else
        return target ~= player and player.phase == Player.NotActive and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".", "#shefu-cost")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      self.cost_data = 0
      local tag = player.tag[self.name]
      if type(tag) ~= "table" then return end
      for i = 1, #tag, 1 do
        if data.card.trueName == tag[i][2] then
          self.cost_data = tag[i][1]
          break
        end
      end
      if self.cost_data > 0 then
        return room:askForSkillInvoke(player, self.name)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:addToPile(self.name, self.cost_data, false, self.name)
      local names ={}
      local tag = player.tag[self.name]
      if type(tag) ~= "table" then tag ={} end
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeBasic or card.type == Card.TypeTrick then
          table.insertIfNeed(names, card.trueName)
        end
      end
      for i = #names, 1, -1 do
        for j = 1, #tag, 1 do
          if names[i] == tag[j][2] then
            table.remove(names, i)
          end
        end
      end
      if #names > 0 then
        local name = room:askForChoice(player, names, self.name)
        table.insert(tag,{self.cost_data[1], name})
        player.tag[self.name] = tag
      end
    else
      local tag = player.tag[self.name]
      for i = 1, #tag, 1 do
        if data.card.trueName == tag[i][2] then
          table.remove(tag, i)
          break
        end
      end
      player.tag[self.name] = tag
      room:moveCards({
        from = player.id,
        ids ={self.cost_data},
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      data.tos ={}
    end
  end,
}
local benyu = fk.CreateTriggerSkill{
  name = "benyu",
  anim_type = "masochism",
  events ={fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(self.name) and data.from ~= nil and not target.dead and #player.player_cards[Player.Hand] ~= #data.from.player_cards[Player.Hand] and #player.player_cards[Player.Hand] < 5
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if #player.player_cards[Player.Hand] > #data.from.player_cards[Player.Hand] then
      local _, discard = room:askForUseActiveSkill(player, "discard_skill", "#benyu-discard", true,{
        num = #player.player_cards[Player.Hand],
        min_num = #data.from.player_cards[Player.Hand] + 1,
        include_equip = false,
        reason = self.name,
        pattern = ".|.|.|hand|.|.",
      })
      if discard then
        self.cost_data = discard.cards
        return true
      end
    else
      self.cost_data = room:askForSkillInvoke(player, self.name)
      return self.cost_data
    end
  end,
  on_use = function(self, event, target, player, data)
    if type(self.cost_data) == "table" and #self.cost_data > 0 then
      player.room:throwCard(self.cost_data, self.name, player, player)
      player.room:damage{
        from = player,
        to = data.from,
        damage = 1,
        skillName = self.name,
      }
    else
      player:drawCards(math.min(5, #data.from.player_cards[Player.Hand]) - #player.player_cards[Player.Hand])
    end
  end,
}
chengyu:addSkill(shefu)
chengyu:addSkill(benyu)
Fk:loadTranslationTable{
  ["chengyu"] = "程昱",
  ["shefu"] = "设伏",
  [":shefu"] = "结束阶段开始时，你可将一张手牌扣置于武将牌上，称为“伏兵”。若如此做，你为“伏兵”记录一个基本牌或锦囊牌的名称（须与其他“伏兵”记录的名称均不同）。当其他角色于你的回合外使用手牌时，你可将记录的牌名与此牌相同的一张“伏兵”置入弃牌堆，然后此牌无效。",
  ["benyu"] = "贲育",
  [":benyu"] = "当你受到伤害后，若你的手牌数不大于伤害来源手牌数，你可以将手牌摸至与伤害来源手牌数相同（最多摸至5张）；否则你可以弃置大于伤害来源手牌数的手牌，然后对其造成1点伤害。",
  ["#shefu-cost"] = "设伏：你可以将一张手牌扣置为“伏兵”",
  ["#benyu-discard"] = "贲育：你可以弃置大于伤害来源手牌数的手牌，对其造成1点伤害",
}

local sunhao = General(extension, "sunhao", "wu", 5)
local canshi = fk.CreateTriggerSkill{
  name = "canshi",
  anim_type = "drawcard",
  events ={fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if p:isWounded() then
        n = n + 1
      end
    end
    player:drawCards(n)
    return true
  end,

  refresh_events ={fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and player:usedSkillTimes(self.name) > 0 and not player:isNude()
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, self.name)
  end,
}
local chouhai = fk.CreateTriggerSkill{
  name = "chouhai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events ={fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
sunhao:addSkill(canshi)
sunhao:addSkill(chouhai)
Fk:loadTranslationTable{
  ["sunhao"] = "孙皓",
  ["canshi"] = "残蚀",
  [":canshi"] = "摸牌阶段开始时，你可以放弃摸牌，摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用基本牌或锦囊牌时，你弃置一张牌。",
  ["chouhai"] = "仇海",
  [":chouhai"] = "锁定技，当你受到伤害时，若你没有手牌，你令此伤害+1。",
  ["guiming"] = "归命",
  [":guiming"] = "主公技，锁定技，其他吴势力角色于你的回合内视为已受伤的角色。",
}

local shixie = General(extension, "shixie", "qun", 3)
local biluan = fk.CreateTriggerSkill{
  name = "biluan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Draw then
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if p:distanceTo(player) == 1 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player.room:addPlayerMark(player, "@biluan", #kingdoms)
    return true
  end,
}
local biluan_distance = fk.CreateDistanceSkill{
  name = "#biluan_distance",
  correct_func = function(self, from, to)
    if to:hasSkill(self.name) then
      return to:getMark("@biluan")
    end
  end,
}
local lixia = fk.CreateTriggerSkill{
  name = "lixia",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Finish and not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"draw1", "lixia_draw"}, self.name)
    if choice == "draw1" then
      player:drawCards(1, self.name)
    else
      target:drawCards(1, self.name)
    end
    room:setPlayerMark(player, "@biluan", player:getMark("@biluan") - 1)
  end,
}
biluan:addRelatedSkill(biluan_distance)  --FIXME:maybe this should relate to lixia lest skill be sealed...
shixie:addSkill(biluan)
shixie:addSkill(lixia)
Fk:loadTranslationTable{
  ["shixie"] = "士燮",
  ["biluan"] = "避乱",
  [":biluan"] = "摸牌阶段开始时，若有其他角色与你距离为1，则你可以放弃摸牌，然后其他角色计算与你距离+X（X为势力数）。",
  ["lixia"] = "礼下",
  [":lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.其摸一张牌。然后其他角色与你的距离-1。",
  ["@biluan"] = "避乱",
  ["lixia_draw"] = "其摸一张牌",
}

local zhanglu = General(extension, "zhanglu", "qun", 3)
local yishe = fk.CreateTriggerSkill{
  name = "yishe",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and #player:getPile("zhanglu_mi") == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    local cards = player.room:askForCard(player, 2, 2, true, self.name, false, ".", "#yishe-cost")
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    player:addToPile("zhanglu_mi", dummy, true, self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) and #player:getPile("zhanglu_mi") == 0 and player:isWounded() then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromSpecialName == "zhanglu_mi" then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
  end,
}
local bushi = fk.CreateTriggerSkill{
  name = "bushi",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      self.cancel_cost = false
      for i = 1, data.damage do
        if #player:getPile("zhanglu_mi") == 0 or self.cancel_cost then return end
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(target, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("zhanglu_mi") == 1 then
      room:obtainCard(target, player:getPile("zhanglu_mi")[1], true, fk.ReasonPrey)
    else
      room:fillAG(target, player:getPile("zhanglu_mi"))
      local id = room:askForAG(target, player:getPile("zhanglu_mi"), false, self.name)
      room:closeAG(target)
      room:obtainCard(target, id, true, fk.ReasonPrey)
    end
  end,
}
local midao = fk.CreateTriggerSkill{
  name = "midao",
  anim_type = "control",
  expand_pile = "zhanglu_mi",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and #player:getPile("zhanglu_mi") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|zhanglu_mi|.|.", "#midao-choose::" .. target.id, "zhanglu_mi")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(Fk:getCardById(self.cost_data), player, data, self.name)
  end,
}
zhanglu:addSkill(yishe)
zhanglu:addSkill(bushi)
zhanglu:addSkill(midao)
Fk:loadTranslationTable{
  ["zhanglu"] = "张鲁",
  ["yishe"] = "义舍",
  [":yishe"] = "结束阶段开始时，若你的武将牌上没有牌，你可以摸两张牌。若如此做，你将两张牌置于武将牌上称为“米”，当“米”移至其他区域后，若你的武将牌上没有“米”，你回复1点体力。",
  ["bushi"] = "布施",
  [":bushi"] = "当你受到1点伤害后，或其他角色受到你造成的1点伤害后，受到伤害的角色可以获得一张“米”。",
  ["midao"] = "米道",
  [":midao"] = "当一张判定牌生效前，你可以打出一张“米”代替之。",
  ["zhanglu_mi"] = "米",
  ["#yishe-cost"] = "义舍：将两张牌置为“米”",
  ["#midao-choose"] = "米道：你可以打出一张“米”修改 %dest 的判定",
}

local mayunlu = General(extension, "mayunlu", "shu", 4, 4, General.Female)
local fengpo = fk.CreateTriggerSkill{
  name = "fengpo",
  anim_type = "offensive",
  events ={fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and (data.card.trueName == "slash" or data.card.name == "duel") then
        return player:usedCardTimes("slash") + player:usedCardTimes("duel") <= 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    if to:isKongcheng() then return end
    local n = 0
    for _, id in ipairs(to:getCardIds(Player.Hand)) do
      if Fk:getCardById(id).suit == Card.Diamond then
        n = n + 1
      end
    end
    local choice = room:askForChoice(player,{"fengpo_draw", "fengpo_damage"}, self.name)
    if choice == "fengpo_draw" then
      player:drawCards(n)
    else
      data.additionalDamage = (data.additionalDamage or 0) + n
    end
  end,
}
mayunlu:addSkill("mashu")
mayunlu:addSkill(fengpo)
Fk:loadTranslationTable{
  ["mayunlu"] = "马云騄",
  ["fengpo"] = "凤魄",
  [":fengpo"] = "当你于出牌阶段内使用的第一张【杀】或【决斗】仅指定唯一目标后，你可以选择一项:1.摸X张牌；2.此牌造成的伤害+X。(X为其♦手牌数)",
  ["fengpo_draw"] = "摸X张牌",
  ["fengpo_damage"] = "伤害+X",
}

local wutugu = General(extension, "wutugu", "qun", 15)
local ranshang = fk.CreateTriggerSkill{
  name = "ranshang",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.Damaged then
        return data.damageType == fk.FireDamage
      else
        return player.phase == Player.Finish and player:getMark("@ran") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:addPlayerMark(player, "@ran", data.damage)
    else
      room:loseHp(player, player:getMark("@ran"), self.name)
    end
  end,
}
local hanyong = fk.CreateTriggerSkill{
  name = "hanyong",
  anim_type = "offensive",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (data.card.name == "savage_assault" or data.card.name == "archery_attack") and player.hp < player.room:getTag("RoundCount")
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
wutugu:addSkill(ranshang)
wutugu:addSkill(hanyong)
Fk:loadTranslationTable{
  ["wutugu"] = "兀突骨",
  ["ranshang"] = "燃殇",
  [":ranshang"] = "锁定技，当你受到1点火焰伤害后，你获得1枚“燃”标记；结束阶段，你失去X点体力（X为“燃”标记的数量）。",
  ["hanyong"] = "悍勇",
  [":hanyong"] = "当你使用【南蛮入侵】或【万箭齐发】时，若你的体力值小于游戏轮数，你可以令此牌造成的伤害+1。",
  ["@ran"] = "燃",
}

local cuiyan = General(extension, "cuiyan", "wei", 3)
local yawang = fk.CreateTriggerSkill{
  name = "yawang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events ={fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if p.hp == player.hp then
        n = n + 1
      end
    end
    player:drawCards(n)
    player.room:addPlayerMark(player, "yawang-turn", n)
    return true
  end,

  refresh_events ={fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@yawang-turn", 1)
  end,
}
local yawang_prohibit = fk.CreateProhibitSkill{
  name = "#yawang_prohibit",
  prohibit_use = function(self, player, card)
    return player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("@yawang-turn") >= player:getMark("yawang-turn")
  end,
}
local xunzhi = fk.CreateTriggerSkill{
  name = "xunzhi",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Start then
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if (player:getNextAlive() == p or p:getNextAlive() == player) and player.hp == p.hp then return end
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    room:addPlayerMark(player, "AddMaxCards", 2)
  end,
}
yawang:addRelatedSkill(yawang_prohibit)
cuiyan:addSkill(yawang)
cuiyan:addSkill(xunzhi)
Fk:loadTranslationTable{
  ["cuiyan"] = "崔琰",
  ["yawang"] = "雅望",
  [":yawang"] = "锁定技，摸牌阶段开始时，你放弃摸牌，改为摸X张牌，然后你于出牌阶段内至多使用X张牌（X为与你体力值相等的角色数）。",
  ["xunzhi"] = "殉志",
  [":xunzhi"] = "准备阶段开始时，若你的上家和下家与你的体力值均不相等，你可以失去1点体力。若如此做，你的手牌上限+2。",
  ["@yawang-turn"] = "雅望",
}

local guansuo = General(extension, "guansuo", "shu", 4)
local zhengnan = fk.CreateTriggerSkill{
  name = "zhengnan",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3)
    local choices = {"wusheng", "dangxian", "zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i]) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      local choice = player.room:askForChoice(player, choices, self.name)
      player.room:handleAddLoseSkills(player, choice, nil)
    end
  end,
}
local xiefang = fk.CreateDistanceSkill{
  name = "xiefang",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.gender == General.Female then
          n = n + 1
        end
      end
      return -n
    end
    return 0
  end,
}
guansuo:addSkill(zhengnan)
guansuo:addSkill(xiefang)
guansuo:addRelatedSkill("wusheng")
guansuo:addRelatedSkill("dangxian")
guansuo:addRelatedSkill("zhiman")
Fk:loadTranslationTable{
  ["guansuo"] = "关索",
  ["zhengnan"] = "征南",
  [":zhengnan"] = "当其他角色死亡后，你可以摸三张牌，若如此做，你获得下列技能中的任意一个：“武圣”，“当先”和“制蛮”。",
  ["xiefang"] = "撷芳",
  [":xiefang"] = "锁定技，你计算与其他角色的距离-X（X为女性角色数）。",
}
Fk:loadTranslationTable{
  ["tadun"] = "蹋顿",
  ["luanzhan"] = "乱战",
  [":luanzhan"] = "你使用【杀】或黑色非延时类锦囊牌可以额外选择X名角色为目标；当你使用【杀】或黑色非延时类锦囊牌指定目标后，若此牌的目标角色数小于X，则X减至0。（X为你于本局游戏内造成过伤害的次数）。",
}
Fk:loadTranslationTable{
  ["yanbaihu"] = "严白虎",
  ["zhidao"] = "雉盗",
  [":zhidao"] = "锁定技，当你于出牌阶段内第一次对区域里有牌的其他角色造成伤害后，你获得其手牌、装备区和判定区里的各一张牌，然后直到回合结束，其他角色不能被选择为你使用牌的目标。",
  ["jili"] = "寄篱",
  [":jili"] = "锁定技，当一名其他角色成为红色基本牌或红色非延时类锦囊牌的目标时，若其与你的距离为1且你既不是此牌的使用者也不是目标，你也成为此牌的目标。",
}

local wanglang = General(extension, "wanglang", "wei", 3)
local gushe = fk.CreateActiveSkill{
  name = "gushe",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected < 3 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(effect.tos, function(p) return room:getPlayerById(p) end)
    local pindian = player:pindian(targets, self.name)
    for _, target in ipairs(targets) do
      local losers = {}
      if pindian.results[target.id].winner then
        if pindian.results[target.id].winner == player then
          table.insert(losers, target)
        else
          table.insert(losers, player)
        end
      else
        table.insert(losers, player)
        table.insert(losers, target)
      end
      for _, p in ipairs(losers) do
        if p == player then
          room:addPlayerMark(player, "@raoshe", 1)
          if player:getMark("@raoshe") >= 7 then
            room:killPlayer({who = player.id,})
          end
        end
        if #room:askForDiscard(p, 1, 1, true, self.name, true, ".", "#gushe-discard::"..player.id) == 0 then
          player:drawCards(1, self.name)
        end
      end
    end
  end,
}
local jici = fk.CreateTriggerSkill{
  name = "jici",
  anim_type = "special",
  events = {fk.PindianCardsDisplayed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.reason == "gushe" and data.fromCard.number <= player:getMark("@raoshe")
  end,
  on_use = function(self, event, target, player, data)
    if data.fromCard.number < player:getMark("@raoshe") then
      data.fromCard.number = data.fromCard.number + player:getMark("@raoshe")
    else
      player:setSkillUseHistory("gushe", 0, Player.HistoryPhase)
    end
  end,
}
wanglang:addSkill(gushe)
wanglang:addSkill(jici)
Fk:loadTranslationTable{
  ["wanglang"] = "王朗",
  ["gushe"] = "鼓舌",
  [":gushe"] = "出牌阶段限一次，你可以用一张手牌与至多三名角色同时拼点，然后依次结算拼点结果，没赢的角色选择一项：1.弃置一张牌；2.令你摸一张牌。若拼点没赢的角色是你，你需先获得一个“饶舌”标记（你有7个饶舌标记时，你死亡）。",
  ["jici"] = "激词",
  [":jici"] = "当你发动“鼓舌”拼点的牌亮出后，若点数小于X，你可令点数+X；若点数等于X，视为你此回合未发动过“鼓舌”。（X为你“饶舌”标记的数量）。",
  ["@raoshe"] = "饶舌",
  ["#gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %dest 摸一张牌",
}

local litong = General(extension, "litong", "wei", 4)
local tuifeng = fk.CreateTriggerSkill{
  name = "tuifeng",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if target:isNude() or self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(player, 1, 1, true, self.name, true, ".", "#tuifeng-cost")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(self.name, self.cost_data, false, self.name)
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and #player:getPile(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = #player:getPile(self.name)
    room:moveCards({
      from = player.id,
      ids = player:getPile(self.name),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
    })
    player:removeCards(Player.Special, player:getPile(self.name), self.name)
    player:drawCards(2 * n, self.name)
    room:addPlayerMark(player, "tuifeng-turn", n)
  end,
}
local tuifeng_targetmod = fk.CreateTargetModSkill{
  name = "#tuifeng_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("tuifeng-turn") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("tuifeng-turn")
    end
  end,
}
tuifeng:addRelatedSkill(tuifeng_targetmod)
litong:addSkill(tuifeng)
Fk:loadTranslationTable{
  ["litong"] = "李通",
  ["tuifeng"] = "推锋",
  [":tuifeng"] = "当你受到1点伤害后，你可以将一张牌置于武将牌上，称为“锋”。准备阶段开始时，若你的武将牌上有“锋”，你将所有“锋”置入弃牌堆，摸2X张牌，然后你于此回合的出牌阶段内使用【杀】的次数上限+X（X为你此次置入弃牌堆的“锋”数）。",
}

local mizhu = General(extension, "mizhu", "shu", 3)
local ziyuan = fk.CreateActiveSkill{
  name = "ziyuan",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip then return end
    local num = 0
    for _, id in ipairs(selected) do
      num = num + Fk:getCardById(id).number
    end
    return num + Fk:getCardById(to_select).number <= 13
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local num = 0
    for _, id in ipairs(selected_cards) do
      num = num + Fk:getCardById(id).number
    end
    return num == 13 and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target, dummy, false, fk.ReasonGive)
    if target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local jugu = fk.CreateTriggerSkill{
  name = "jugu",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    player.room:drawCards(player, player.maxHp, self.name)
  end,
}
local jugu_maxcards = fk.CreateMaxCardsSkill{
  name = "#jugu_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      return player.maxHp
    else
      return 0
    end
  end,
}
jugu:addRelatedSkill(jugu_maxcards)
mizhu:addSkill(ziyuan)
mizhu:addSkill(jugu)
Fk:loadTranslationTable{
  ["mizhu"] = "糜竺",
  ["ziyuan"] = "资援",
  [":ziyuan"] = "出牌阶段限一次，你可以将任意张点数之和为13的手牌交给一名其他角色，然后该角色回复1点体力。",
  ["jugu"] = "巨贾",
  [":jugu"] = "锁定技，1.你的手牌上限+X。2.游戏开始时，你摸X张牌。（X为你的体力上限）",
}

local buzhi = General(extension, "buzhi", "wu", 3)
local hongde = fk.CreateTriggerSkill{
  name = "hongde",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if #move.moveInfo > 1 and ((move.from == player.id and move.to ~= player.id) or (move.to == player.id and move.toArea == Card.PlayerHand)) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local p = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#hongde-choose", self.name)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(self.cost_data):drawCards(1, self.name)
  end,
}
local dingpan = fk.CreateActiveSkill{
  name = "dingpan",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < player:getMark(self.name)
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and #target.player_cards[Player.Equip] > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(1, self.name)
    local choice = room:askForChoice(target, {"dingpan_discard", "dingpan_damage"}, self.name)
    if choice == "dingpan_discard" then
      local id = room:askForCardChosen(player, target, "e", self.name)
      room:throwCard({id}, self.name, target, player)
    else
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(target.player_cards[Player.Equip])
      room:obtainCard(target, dummy, true, fk.ReasonJustMove)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local dingpan_record = fk.CreateTriggerSkill{
  name = "#dingpan_record",

  refresh_events = {fk.GameStart, fk.BeforeGameOverJudge},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local n
      if room.settings.gameMode == "aaa_role_mode" then
        local total = #room.alive_players
        if total == 8 then n = 4
        elseif total == 7 or total == 6 then n = 3
        elseif total == 5 then n = 2
        else n = 1
        end
      elseif room.settings.gameMode == "m_1v2_mode" or room.settings.gameMode == "m_2v2_mode" then
        n = 2
      end
      room:setPlayerMark(player, "dingpan", n)
    else
      if target.role == "rebel" then
        room:removePlayerMark(player, "dingpan", 1)
      end
    end
  end,
}
dingpan:addRelatedSkill(dingpan_record)
buzhi:addSkill(hongde)
buzhi:addSkill(dingpan)
Fk:loadTranslationTable{
  ["buzhi"] = "步骘",
  ["hongde"] = "弘德",
  [":hongde"] = "当你一次获得或失去至少两张牌后，你可以令一名其他角色摸一张牌。",
  ["dingpan"] = "定叛",
  [":dingpan"] = "出牌阶段限X次，你可以令一名装备区里有牌的角色摸一张牌，然后其选择一项：1.令你弃置其装备区里的一张牌；2.获得其装备区里的所有牌，若如此做，你对其造成1点伤害（X为场上存活的反贼数）。",
  ["#hongde-choose"] = "弘德：你可以令一名其他角色摸一张牌",
  ["dingpan_discard"] = "其弃置你装备区里的一张牌",
  ["dingpan_damage"] = "收回所有装备，其对你造成1点伤害",
}

Fk:loadTranslationTable{
  ["dongbai"] = "董白",
  ["lianzhu"] = "连诛",
  [":lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。",
  ["xiahui"] = "黠慧",
  [":xiahui"] = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，其不能使用、打出、弃置这些牌直到其体力值减少为止。",
}

--local zhaoxiang = General(extension, "zhaoxiang", "shu", 4, 4, General.Female)
local fanghun = fk.CreateViewAsSkill{
  name = "fanghun",
  pattern = "slash,jink",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local c = Fk:getCardById(to_select)
    return c.trueName == "slash" or c.name == "jink"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or Self:getMark("@meiying") == 0 then return end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, "fanghun")
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
}
local fanghun_record = fk.CreateTriggerSkill{
  name = "#fanghun_record",
  anim_type = "offensive",
  events = {fk.AfterCardUseDeclared, fk.PreCardRespond},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "fanghun")
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@meiying", 1)
    player:drawCards(1, "fanghun")
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@meiying", 1)
  end,
}
--[[local fuhan = fk.CreateTriggerSkill{
  name = "fuhan",
  anim_type = "special",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
      and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:getMark("@meiying") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@meiying", 0)
    local generals = Fk:getGeneralsRandomly(5, Fk:getAllGenerals(),
      table.map(room:getAllPlayers(), function(p) return p.general end),
      (function (p) return (p.kingdom ~= "shu") end))
    local general = room:askForGeneral(player, generals)
    room:setPlayerGeneral(player, general)
    player.maxHp = math.min(player:usedSkillTimes(#fanghun_record, Player.HistoryGame), #room:getAllPlayers())
    
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
  end,
}]]--
fanghun:addRelatedSkill(fanghun_record)
--zhaoxiang:addSkill(fanghun)
--zhaoxiang:addSkill(fuhan)
Fk:loadTranslationTable{
  ["zhaoxiang"] = "赵襄",
  ["fanghun"] = "芳魂",
  [":fanghun"] = "当你使用【杀】造成伤害后，你获得1个“梅影”标记；你可以移去1个“梅影”标记来发动〖龙胆〗并摸一张牌。",
  ["fuhan"] = "扶汉",
  [":fuhan"] = "限定技，准备阶段开始时，你可以移去所有“梅影”标记，随机观看五名未登场的蜀势力角色，将武将牌替换为其中一名角色，并将体力上限数调整为本局游戏中移去“梅影”标记的数量（至多为游戏人数），然后若你是体力值最低的角色，你回复1点体力。",
  ["@meiying"] = "梅影",
}
Fk:loadTranslationTable{
  ["dongyun"] = "董允",
  ["bingzheng"] = "秉正",
  [":bingzheng"] = "出牌阶段结束时，你可以令手牌数不等于体力值的一名角色弃置一张手牌或摸一张牌。然后若其手牌数等于体力值，你摸一张牌，且可以交给该角色一张牌。",
  ["sheyan"] = "舍宴",
  [":sheyan"] = "当你成为一张普通锦囊牌的目标时，你可以为此牌增加一个目标或减少一个目标（目标数至少为一）。",
}
Fk:loadTranslationTable{
  ["mazhong"] = "马忠",
  ["fuman"] = "抚蛮",
  [":fuman"] = "出牌阶段，你可以将一张【杀】交给一名本回合未获得过“抚蛮”牌的其他角色，然后其于下个回合结束之前使用“抚蛮”牌时，你摸一张牌。",
}
Fk:loadTranslationTable{
  ["heqi"] = "贺齐",
  ["qizhou"] = "绮胄",
  [":qizhou"] = "锁定技，你根据装备区里牌的花色数获得以下技能：1种以上-马术；2种以上-英姿；3种以上-短兵；4种-奋威。",
  ["shanxi"] = "闪袭",
  [":shanxi"] = "出牌阶段限一次，你可以弃置一张红色基本牌，然后弃置攻击范围内的一名其他角色的一张牌，若弃置的牌是【闪】，你观看其手牌，若弃置的不是【闪】，其观看你的手牌。",
}
Fk:loadTranslationTable{
  ["kanze"] = "阚泽",
  ["xiashu"] = "下书",
  [":xiashu"] = "出牌阶段开始时，你可以将所有手牌交给一名其他角色，然后该角色亮出任意数量的手牌（至少一张），令你选择一项：1.获得其亮出的手牌；2.获得其未亮出的手牌。",
  ["kuanshi"] = "宽释",
  [":kuanshi"] = "结束阶段，你可以选择一名角色。直到你的下回合开始，该角色下一次受到超过1点的伤害时，防止此伤害，然后你跳过下个回合的摸牌阶段。",
}

local liuqi = General(extension, "liuqi", "qun", 3)
local wenji = fk.CreateTriggerSkill{
  name = "wenji",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      not table.every(player.room:getOtherPlayers(player), function(p) return (p:isNude()) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (not p:isNude()) end), function(p) return p.id end),
      1, 1, "#wenji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#wenji-give::"..player.id)
    room:addPlayerMark(player, "wenji"..Fk:getCardById(card[1]).trueName.."-turn", 1)
    room:obtainCard(player, card[1], false, fk.ReasonGive)
  end,
}
local wenji_record = fk.CreateTriggerSkill{
  name = "#wenji_record",

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes("wenji") > 0 and player:getMark("wenji"..data.card.trueName.."-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
local tunjiang = fk.CreateTriggerSkill{
  name = "tunjiang",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      player:getMark("tunjiang-turn") == 0 and not player.skipped_phases[Player.Play]
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room:getAlivePlayers()) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("tunjiang-turn") == 0 and
      data.firstTarget and data.card.type ~= Card.TypeEquip
  end,
  on_refresh = function(self, event, target, player, data)
    if #AimGroup:getAllTargets(data.tos) == 0 then return end
    for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
      if id ~= player.id then
        player.room:addPlayerMark(player, "tunjiang-turn", 1)
        break
      end
    end
  end,
}
wenji:addRelatedSkill(wenji_record)
liuqi:addSkill(wenji)
liuqi:addSkill(tunjiang)
Fk:loadTranslationTable{
  ["liuqi"] = "刘琦",
  ["wenji"] = "问计",
  [":wenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌，你于本回合内使用与该牌同名的牌不能被其他角色响应。",
  ["tunjiang"] = "屯江",
  [":tunjiang"] = "结束阶段，若你未跳过本回合的出牌阶段，且你于本回合出牌阶段内未使用牌指定过其他角色为目标，则你可以摸X张牌（X为全场势力数）。",
  ["#wenji-choose"] = "问计：你可以令一名其他角色交给你一张牌",
  ["#wenji-give"] = "问计：你需交给 %dest 一张牌",
}

Fk:loadTranslationTable{
  ["tangzi"] = "唐咨",
  ["xingzhao"] = "兴棹",
  [":xingzhao"] = "锁定技，场上受伤的角色为：1个或以上，你拥有技能〖恂恂〗；2个或以上，你使用装备牌时摸一张牌；3个或以上，你跳过弃牌阶段。",
}

--王允

local quyi = General(extension, "quyi", "qun", 4)
local fuji = fk.CreateTriggerSkill{
  name = "fuji",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (data.card.trueName == "slash" or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick)) and
      #table.filter(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end) > 0
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
local jiaozi = fk.CreateTriggerSkill{
  name = "jiaozi",
  anim_type = "offensive",
  events = {fk.DamageCaused, fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      table.every(player.room:getOtherPlayers(player), function(p)
        return #player:getCardIds(Player.Hand) > #p:getCardIds(Player.Hand) end)
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
quyi:addSkill(fuji)
quyi:addSkill(jiaozi)
Fk:loadTranslationTable{
  ["quyi"] = "麴义",
  ["fuji"] = "伏骑",
  [":fuji"] = "锁定技，当你使用【杀】或普通锦囊牌时，你令所有至你距离为1的角色不能响应此牌。",
  ["jiaozi"] = "骄恣",
  [":jiaozi"] = "锁定技，当你造成或受到伤害时，若你的手牌为全场唯一最多，则此伤害+1。",

  ["$fuji1"] = "白马？不足挂齿！",
  ["$fuji2"] = "掌握之中，岂可逃之？",
  ["$jiaozi1"] = "数战之功，吾应得此赏！",
  ["$jiaozi2"] = "无我出力，怎会连胜？",
  ["~quyi"] = "主公，我无异心啊！",
}

local xizhicai = General(extension, "xizhicai", "wei", 3)
local xianfu = fk.CreateTriggerSkill{
  name = "xianfu",
  events = {fk.GameStart, fk.Damaged, fk.HpRecover},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        return target:getMark(self.name) == player.id and not target.dead
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#xianfu-choose", self.name)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:setPlayerMark(to, self.name, player.id)
    elseif event == fk.Damaged then
      if player:getMark("@xianfu") == 0 then
        room:setPlayerMark(player, "@xianfu", target.general)
      end
      room:damage{
        to = player,
        damage = data.damage,
        skillName = self.name,
      }
    elseif event == fk.HpRecover then
      if player:getMark("@xianfu") == 0 then
        room:setPlayerMark(player, "@xianfu", target.general)
      end
      room:recover{
        who = player,
        num = data.num,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
local chouce = fk.CreateTriggerSkill{
  name = "chouce",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      local targets = table.map(room:getAlivePlayers(), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#chouce-draw", self.name)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      to:drawCards(1 + (to:getMark("xianfu") == player.id and 1 or 0), self.name)
    elseif judge.card.color == Card.Black then
      local targets = table.map(table.filter(room:getAlivePlayers(), function(p) return not p:isAllNude() end), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#chouce-discard", self.name)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      local card = room:askForCardChosen(player, to, "hej", self.name)
      room:throwCard(card, self.name, to, player)
    end
  end,
}
xizhicai:addSkill("tiandu")
xizhicai:addSkill(xianfu)
xizhicai:addSkill(chouce)
Fk:loadTranslationTable{
  ["xizhicai"] = "戏志才",
  ["xianfu"] = "先辅",
  ["@xianfu"] = "先辅",
  [":xianfu"] = "锁定技，游戏开始时，你选择一名其他角色，当其受到伤害后，你受到等量的伤害；当其回复体力后，你回复等量的体力。",
  ["chouce"] = "筹策",
  [":chouce"] = "当你受到1点伤害后，你可以进行判定，若结果为：黑色，你弃置一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。",
  ["#xianfu-choose"] = "先辅: 请选择要先辅的角色",
  ["#chouce-draw"] = "筹策: 请选择一名角色令其摸牌",
  ["#chouce-discard"] = "筹策: 请选择一名角色，弃置其区域内的牌",

  -- ["$tiandu1"] = "天意不可逆。",
  -- ["$tiandu2"] = "既是如此。",
  ["$xianfu1"] = "辅佐明君，从一而终。",
  ["$xianfu2"] = "吾于此生，竭尽所能。",
  ["$chouce1"] = "一筹一划，一策一略。",
  ["$chouce2"] = "主公之忧，吾之所思也。",
  ["~xizhicai"] = "为何……不再给我……一点点时间……",
}

local sunqian = General(extension, "sunqian", "shu", 3)
local qianya = fk.CreateTriggerSkill{
  name = "qianya",
  anim_type = "support",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.type == Card.TypeTrick and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    player.room:askForUseActiveSkill(player, "#qianya_active", "#qianya-invoke", true)
  end,
}
local qianya_active = fk.CreateActiveSkill{
  name = "#qianya_active",
  anim_type = "support",
  max_card_num = function ()
    return #Self.player_cards[Player.Hand]
  end,
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, targets)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target, dummy, false, fk.ReasonGive)
  end,
}
local shuimeng = fk.CreateTriggerSkill{
  name = "shuimeng",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), function(p) return p.id end),
      1, 1, "#shuimeng-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local pindian = player:pindian({to}, self.name)
    if pindian.results[to.id].winner == player then
      room:useVirtualCard("ex_nihilo", nil, player, player, self.name)
    else
      if player:isAllNude() then return end
      room:useVirtualCard("dismantlement", nil, to, player, self.name)
    end
  end,
}
Fk:addSkill(qianya_active)
sunqian:addSkill(qianya)
sunqian:addSkill(shuimeng)
Fk:loadTranslationTable{
  ["sunqian"] = "孙乾",
  ["qianya"] = "谦雅",
  [":qianya"] = "当你成为锦囊牌的目标后，你可以将任意张手牌交给一名其他角色。",
  ["shuimeng"] = "说盟",
  [":shuimeng"] = "出牌阶段结束时，你可以与一名角色拼点，若你赢，视为你使用【无中生有】；若你没赢，视为其对你使用【过河拆桥】。",
  ["#qianya_active"] = "谦雅",
  ["#qianya-invoke"] = "谦雅：你可以将任意张手牌交给一名其他角色",
  ["#shuimeng-choose"] = "说盟：你可以拼点，若你赢，视为你使用【无中生有】；若你没赢，视为其对你使用【过河拆桥】",
}

local shenpei = General(extension, "ol__shenpei", "qun", 3)
local gangzhi = fk.CreateTriggerSkill{
  name = "gangzhi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreDamage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and ((target == player and data.to ~= player) or (data.from and data.from ~= player and data.to == player))
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, data.damage, self.name)
    return true
  end,
}
local beizhan = fk.CreateTriggerSkill{
  name = "beizhan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p.player_cards[Player.Hand] < math.min(p.maxHp, 5) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#beizhan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(self.cost_data)
    to:drawCards(math.min(to.maxHp, 5) - #to.player_cards[Player.Hand])
    player.room:addPlayerMark(to, self.name, 1)
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if target:getMark(self.name) > 0 and data.to == Player.Start then
      for _, p in ipairs(player.room.alive_players) do
        if #p.player_cards[Player.Hand] > #target.player_cards[Player.Hand] then return end
      end
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, self.name, 0)
    player.room:addPlayerMark(target, "beizhan-turn", 1)
  end,
}
local beizhan_prohibit = fk.CreateProhibitSkill{
  name = "#beizhan_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("beizhan-turn") > 0 and from ~= to
  end,
}
beizhan:addRelatedSkill(beizhan_prohibit)
shenpei:addSkill(gangzhi)
shenpei:addSkill(beizhan)
Fk:loadTranslationTable{
  ["ol__shenpei"] = "审配",
  ["gangzhi"] = "刚直",
  [":gangzhi"] = "锁定技，其他角色对你造成的伤害，和你对其他角色造成的伤害均视为体力流失。",
  ["beizhan"] = "备战",
  [":beizhan"] = "回合结束后，你可以令一名角色将手牌补至体力上限（至多为5）。该角色回合开始时，若其手牌数为全场最多，则其本回合内不能使用牌指定其他角色为目标。",
  ["#beizhan-choose"] = "备战：令一名角色将手牌补至X张（X为其体力上限且最多为5）",
}

local xunchen = General(extension, "ol__xunchen", "qun", 3)
local fenglve = fk.CreateTriggerSkill{
  name = "fenglve",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.PindianResultConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Play and not player:isKongcheng()
      else
        self.fenglve_data = {}
        if data.from == player then
          self.fenglve_data = {data.to, data.fromCard.id}
        elseif data.to == player then
          self.fenglve_data = {data.from, data.toCard.id}
        end
        return self.fenglve_data and player.room:getCardArea(self.fenglve_data[2]) == Card.Processing
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isKongcheng() end), function(p) return p.id end),
        1, 1, "#fenglve-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name, data, "#fenglve-give::"..self.fenglve_data[1].id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:getPlayerById(self.cost_data)
      local pindian = player:pindian({to}, self.name)
      if pindian.results[to.id].winner == player then
        if to:isAllNude() then return end
        local dummy = Fk:cloneCard("dilu")
        local areas = {Player.Hand, Player.Equip, Player.Judge}
        for i = 1, 3, 1 do
          if #to.player_cards[areas[i]] > 0 then
            local flag = {"h", "e", "j"}
            local id = room:askForCardChosen(to, to, flag[i], self.name)
            dummy:addSubcard(id)
          end
        end
        room:obtainCard(player, dummy, false, fk.ReasonGive)
      else
        if player:isNude() then return end
        local id = room:askForCardChosen(player, player, "he", self.name)
        room:obtainCard(to, id, false, fk.ReasonGive)
      end
    else
      room:obtainCard(self.fenglve_data[1], self.fenglve_data[2], true, fk.ReasonGive)
    end
  end,
}
local moushi = fk.CreateActiveSkill{
  name = "moushi",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive)
    room:addPlayerMark(target, self.name, 1)
  end,
}
local moushi_record = fk.CreateTriggerSkill{
  name = "#moushi_record",

  refresh_events = {fk.EventPhaseStart, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return target:getMark("moushi") > 0
      else
        return target:getMark("moushi_p-phase") > 0 and data.to:getMark("moushi-phase") == 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(target, "moushi", 0)
      room:addPlayerMark(target, "moushi_p-phase", 1)
    else
      room:addPlayerMark(data.to, "moushi-phase", 1)
      player:drawCards(1, self.name)
    end
  end,
}
moushi:addRelatedSkill(moushi_record)
xunchen:addSkill(fenglve)
xunchen:addSkill(moushi)
Fk:loadTranslationTable{
  ["ol__xunchen"] = "荀谌",
  ["fenglve"] = "锋略",
  [":fenglve"] = "出牌阶段开始时，你可以与一名角色拼点：若你赢，该角色将每个区域内各一张牌交给你；若你没赢，你交给其一张牌。你与其他角色的拼点结果确定后，你可以将你的拼点牌交给该角色。",
  ["moushi"] = "谋识",
  [":moushi"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色。若如此做，当该角色于其下个出牌阶段对每名角色第一次造成伤害后，你摸一张牌。",
  ["#fenglve-choose"] = "锋略：你可以拼点，若赢，其交给你每个区域各一张牌；没赢，你交给其一张牌",
  ["#fenglve-give"] = "锋略：你可以将你的拼点牌交给%dest",
}

-- 官渡 2017.12
--刘晔
--淳于琼

local sufei = General(extension, "ol__sufei", "wu", 4)
local lianpian = fk.CreateTriggerSkill{
  name = "lianpian",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:usedSkillTimes(self.name) < 3 then
      return self.cost_data and #self.cost_data > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = player:drawCards(1, self.name)
    if #self.cost_data > 1 or self.cost_data[1] ~= player.id then
      local tos = room:askForChoosePlayers(player, self.cost_data, 1, 1, "#lianpian-choose", self.name, true)
      if #tos > 0 and tos[1] ~= player.id then
        room:obtainCard(tos[1], card[1], false, fk.ReasonGive)
      end
    end
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.firstTarget
  end,
  on_refresh = function(self, event, target, player, data)
    self.cost_data = {}
    local mark = player:getMark("lianpian-phase")
    if mark ~= 0 and #mark > 0 and #AimGroup:getAllTargets(data.tos) > 0 then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if table.contains(mark, id) then
          table.insert(self.cost_data, id)
        end
      end
    end
    if #AimGroup:getAllTargets(data.tos) > 0 then
      mark = AimGroup:getAllTargets(data.tos)
    else
      mark = 0
    end
    player.room:setPlayerMark(player, "lianpian-phase", mark)
  end,
}
sufei:addSkill(lianpian)
Fk:loadTranslationTable{
  ["ol__sufei"] = "苏飞",
  ["lianpian"] = "联翩",
  [":lianpian"] = "每回合限三次，当你于出牌阶段使用牌连续指定相同角色为目标后，你可以摸一张牌，若如此做，你可以将此牌交给该角色。",
  ["#lianpian-choose"] = "联翩：你可以将这张牌交给其中一名角色",
}

local huangquan = General(extension, "ol__huangquan", "shu", 3)
local dianhu = fk.CreateTriggerSkill{
  name = "dianhu",
  events = {fk.GameStart, fk.Damage, fk.HpRecover},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      elseif event == fk.Damage then
        return target == player and player.tag[self.name][1] == data.to.id
      else
        return player.tag[self.name][1] == target.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#dianhu-choose", self.name)
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:doIndicate(player.id, {to})
      room:setPlayerMark(room:getPlayerById(to), "@dianhu", 1)
      player.tag[self.name] = {to}
    else
      player:drawCards(1, self.name)
    end
  end,
}
local jianji = fk.CreateActiveSkill{
  name = "jianji",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, use)
    local target = room:getPlayerById(use.tos[1])
    local id = target:drawCards(1, self.name)[1]
    local name = Fk:getCardById(id).trueName
    if name ~= "jink" and name ~= "nullification" then
      local _use = room:askForUseCard(target, Fk:getCardById(id).name, ".|.|.|.|.|.|"..tostring(id), "#jianji-invoke", true)
      if _use then
        room:useCard(_use)
      end
    end
  end,
}
huangquan:addSkill(dianhu)
huangquan:addSkill(jianji)
Fk:loadTranslationTable{
  ["ol__huangquan"] = "黄权",
  ["dianhu"] = "点虎",
  [":dianhu"] = "锁定技，游戏开始时，你指定一名其他角色；当你对该角色造成伤害后或该角色回复体力后，你摸一张牌。",
  ["jianji"] = "谏计",
  [":jianji"] = "出牌阶段限一次，你可以令一名其他角色摸一张牌，然后其可以使用该牌。",
  ["@dianhu"] = "点虎",
  ["#dianhu-choose"] = "点虎：指定一名角色，本局当你对其造成伤害或其回复体力后，你摸一张牌",
  ["#jianji-invoke"] = "谏计：你可以使用这张牌",
}

--卑弥呼 2018.6.8

local luzhi = General(extension, "luzhiw", "wei", 3)
local qingzhong = fk.CreateTriggerSkill{
  name = "qingzhong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = #player.player_cards[Player.Hand]
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] < n then
        n = #p.player_cards[Player.Hand]
      end
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] == n then
        table.insert(targets, p.id)
      end
    end
    local to
    if #targets == 0 then
      return
    elseif #targets == 1 then
      to = targets[1]
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#qingzhong-choose", self.name)
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
    end
    local cards1 = table.clone(player.player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(to).player_cards[Player.Hand])
    local move1 = {
      from = player.id,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,  --FIXME: this is still visible! same problem with dimeng!
    }
    local move2 = {
      from = to,
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = cards1,
      fromArea = Card.Processing,
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    local move4 = {
      ids = cards2,
      fromArea = Card.Processing,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move3, move4)
  end,
}
local weijing = fk.CreateViewAsSkill{
  name = "weijing",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and player:usedSkillTimes("#weijing_record", Player.HistoryRound) == 0
  end,
  enabled_at_response = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and player:usedSkillTimes("#weijing_record", Player.HistoryRound) == 0
  end,
}
local weijing_record = fk.CreateTriggerSkill{
  name = "#weijing_record",
  events = {fk.AskForCardUse, fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
    player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and player:usedSkillTimes("weijing", Player.HistoryRound) == 0 and
    (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none")))
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AskForCardUse then
      data.result = {
        from = player.id,
        card = Fk:cloneCard(data.cardName),
      }
      data.result.card.skillName = "weijing"
      if data.eventData then
        data.result.toCard = data.eventData.toCard
        data.result.responseToEvent = data.eventData.responseToEvent
      end
    else
      data.result = Fk:cloneCard(data.cardName)
      data.result.skillName = "weijing"
    end
    return true
  end
}
weijing:addRelatedSkill(weijing_record)
luzhi:addSkill(qingzhong)
luzhi:addSkill(weijing)
Fk:loadTranslationTable{
  ["luzhiw"] = "鲁芝",
  ["qingzhong"] = "清忠",
  [":qingzhong"] = "出牌阶段开始时，你可以摸两张牌，然后本阶段结束时，你与一名全场手牌数最少的其他角色交换手牌。",
  ["weijing"] = "卫境",
  [":weijing"] = "每轮限一次，当你需要使用【杀】或【闪】时，你可以视为使用之。",
  ["#qingzhong-choose"] = "清忠：选择一名手牌数最少的其他角色，与其交换手牌",
  ["#weijing_record"] = "卫境",
}

--鲍三娘
Fk:loadTranslationTable{
  ["baosanniang"] = "鲍三娘",
  ["wuniang"] = "武娘",
  [":wuniang"] = "当你使用或打出【杀】时，你可以获得一名其他角色的一张牌。若如此做，其摸一张牌，然后若“关索”在场，你令“关索”摸一张牌。",
  ["xushen"] = "许身",
  [":xushen"] = "限定技，当其他男性角色令你离开濒死状态后，如果“关索”不在场，其可以选择是否用“关索”代替其武将，然后你回复1点体力并获得技能〖镇南〗。",
  ["zhennan"] = "镇南",
  [":zhennan"] = "当你成为【南蛮入侵】的目标后，你可选择一名其他角色。然后你对其造成随机1-3点伤害。",
}

local caoying = General(extension, "caoying", "wei", 4, 4, General.Female)
local lingren = fk.CreateTriggerSkill{
  name = "lingren",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      if data.firstTarget and #AimGroup:getAllTargets(data.tos) > 0 then
        local pattern = "slash,duel,savage_assault,archery_attack,fire_attack"
        if data.card:matchPattern(pattern) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, data.tos[1], 1, 1, "#lingren-choose", self.name)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"lingren_basic", "lingren_trick", "lingren_equip", "lingren_end"}
    local yes = {}
    for i = 1, 3, 1 do
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "lingren_end" then
        break
      else
        table.insert(yes, choice)
        table.removeOne(choices, choice)
      end
    end
    table.removeOne(choices, "lingren_end")
    local right = 0
    for _, id in ipairs(to.player_cards[Player.Hand]) do
      local str = "lingren_"..Fk:getCardById(id):getTypeString()
      if table.contains(yes, str) then
        right = right + 1
        table.removeOne(yes, str)
      else
        table.removeOne(choices, str)
      end
    end
    right = right + #choices
    if right > 0 then data.card.extra_data = {self.name, self.cost_data} end  --can't use data.additionalDamage here!
    if right > 1 then player:drawCards(2) end
    if right > 2 then room:handleAddLoseSkills(player, "ex__jianxiong|xingshang", nil, true, false) end
  end,

  refresh_events = {fk.DamageCaused, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name, true) then
      if event == fk.DamageCaused then
        return data.card and data.card.extra_data and data.card.extra_data[1] == self.name and data.card.extra_data[2] == data.to.id
      else
        return data.to == Player.Start
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      player.room:handleAddLoseSkills(player, "-ex__jianxiong|-xingshang", nil, true, false)
    end
  end,
}
local fujian = fk.CreateTriggerSkill {
  name = "fujian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Finish then
      self.fujian_num = #player.player_cards[Player.Hand]
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Hand] < self.fujian_num then
          self.fujian_num = #p.player_cards[Player.Hand]
        end
      end
      return self.fujian_num > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getOtherPlayers(player)[math.random(1, #room.alive_players - 1)]
    room:doIndicate(player.id, {to.id})
    local view = {}
    while #view < self.fujian_num do
      local id = to.player_cards[Player.Hand][math.random(1, #to.player_cards[Player.Hand])]
      table.insertIfNeed(view, id)
    end
    room:fillAG(player, view)
    room:delay(5000)
    room:closeAG(player)
  end,
}
caoying:addSkill(lingren)
caoying:addRelatedSkill("ex__jianxiong")
caoying:addRelatedSkill("xingshang")
caoying:addSkill(fujian)
Fk:loadTranslationTable{
  ["caoying"] = "曹婴",
  ["lingren"] = "凌人",
  [":lingren"] = "出牌阶段限一次，当你使用【杀】或伤害类锦囊牌指定目标后，你可以猜测其中一名目标角色的手牌区中是否有基本牌、锦囊牌或装备牌。若你猜对：至少一项，此牌对其造成的伤害+1；至少两项，你摸两张牌；三项，你获得技能〖奸雄〗和〖行殇〗直到你的下个回合开始。",
  ["fujian"] = "伏间",
  [":fujian"] = "锁定技，结束阶段，你随机观看一名其他角色的X张手牌（X为全场手牌数最小的角色的手牌数）。",
  ["#lingren-choose"] = "凌人：你可以猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["lingren_basic"] = "有基本牌",
  ["lingren_trick"] = "有锦囊牌",
  ["lingren_equip"] = "有装备牌",
  ["lingren_end"] = "结束",
}

local xujing = General(extension, "ol__xujing", "shu", 3)
local yuxu = fk.CreateTriggerSkill{
  name = "yuxu",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    if player:getMark("yuxu-phase") == 0 then
      return player.room:askForSkillInvoke(player, self.name, data, "#yuxu-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("yuxu-phase") == 0 then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "yuxu-phase", 1)
    else
      if not player:isNude() then
        room:askForDiscard(player, 1, 1, true, self.name, false)
      end
      room:removePlayerMark(player, "yuxu-phase", 1)
    end
  end,
}
local shijian = fk.CreateTriggerSkill{
  name = "shijian",
  anim_type = "support",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Play and target:getMark("shijian-phase") == 2 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#shijian-invoke::"..target.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "shijian_invoke", 1)
    player.room:handleAddLoseSkills(target, "yuxu", nil, true, false)
  end,

  refresh_events = {fk.CardUseFinished, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player:hasSkill(self.name) and target ~= player and target.phase == Player.Play
    else
      return target == player and player:getMark("shijian_invoke") > 0 and data.to == Player.NotActive
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      room:addPlayerMark(target, "shijian-phase", 1)
    else
      room:setPlayerMark(player, "shijian_invoke", 0)
      room:handleAddLoseSkills(player, "-yuxu", nil, true, false)
    end
  end,
}
xujing:addSkill(yuxu)
xujing:addSkill(shijian)
Fk:loadTranslationTable{
  ["ol__xujing"] = "许靖",
  ["yuxu"] = "誉虚",
  [":yuxu"] = "出牌阶段，你使用一张牌后，可以摸一张牌。若如此做，你使用下一张牌后，弃置一张牌。",
  ["shijian"] = "实荐",
  [":shijian"] = "一名其他角色的出牌阶段，该角色在本阶段使用的第二张牌结算结束后，你可以弃置一张牌，令其获得〖誉虚〗直到回合结束。",
  ["#yuxu-invoke"] = "誉虚：你可以摸一张牌，然后你使用下一张牌后需弃置一张牌",
  ["#shijian-invoke"] = "实荐：你可以弃置一张牌，令%dest获得〖誉虚〗直到回合结束",
}
--袁谭袁尚 2020.2.7

local sunshao = General(extension, "ol__sunshao", "wu", 3)
local bizheng = fk.CreateTriggerSkill{
  name = "bizheng",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#bizheng-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    to:drawCards(2, self.name)
    for _, p in ipairs({player, to}) do
      if #p.player_cards[Player.Hand] > p.maxHp then
        room:askForDiscard(p, 2, 2, true, self.name, false)
      end
    end
  end,
}
local yidian = fk.CreateTriggerSkill{
  name = "yidian",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and
      (data.card.type == Card.TypeBasic or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick)) and
      data.targetGroup then
      for _, id in ipairs(player.room.discard_pile) do
        if data.card.name == Fk:getCardById(id).name then
          return
        end
      end
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not player:isProhibited(p, data.card) then
        table.insertIfNeed(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#yidian-choose", self.name, true)
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
sunshao:addSkill(bizheng)
sunshao:addSkill(yidian)
Fk:loadTranslationTable{
  ["ol__sunshao"] = "孙邵",
  ["bizheng"] = "弼政",
  [":bizheng"] = "摸牌阶段结束时，你可令一名其他角色摸两张牌，然后你与其之中，手牌数大于体力上限的角色弃置两张牌。",
  ["yidian"] = "佚典",
  [":yidian"] = "若你使用的基本牌或普通锦囊在弃牌堆中没有同名牌，你可以为此牌指定一个额外目标（无视距离）。",
  ["#bizheng-choose"] = "弼政：你可以令一名其他角色摸两张牌，然后你与其中手牌数大于体力上限的角色弃置两张牌",
  ["#yidian-choose"] = "佚典：你可以额外指定一个目标",
}

local godzhenji = General(extension, "godzhenji", "god", 3, 3, General.Female)
local shenfu = fk.CreateTriggerSkill {
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
}

local godcaopi = General(extension, "godcaopi", "god", 5)
local chuyuan = fk.CreateTriggerSkill{
  name = "chuyuan",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and #player:getPile("caopi_chu") < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1)
    local card = room:askForCard(target, 1, 1, false, self.name, false, ".", "#chuyuan-put")
    player:addToPile("caopi_chu", card, false, self.name)
  end,
}
local dengji = fk.CreateTriggerSkill{
  name = "dengji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
     player.phase == Player.Start and
     #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("caopi_chu"))
    room:obtainCard(player, dummy, false, fk.ReasonPrey)
    room:handleAddLoseSkills(player, "ex__jianxiong|tianxing", nil)
  end,
}
local tianxing = fk.CreateTriggerSkill{
  name = "tianxing",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
     player.phase == Player.Start and
     #player:getPile("caopi_chu") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("caopi_chu"))
    room:obtainCard(player, dummy, false, fk.ReasonPrey)
    local choice = room:askForChoice(player, {"rende", "ex__zhiheng", "luanji"}, self.name)  --TODO:ex__rende, ex__luanji
    room:handleAddLoseSkills(player, choice.."|-chuyuan", nil)
  end,
}
godcaopi:addSkill(chuyuan)
godcaopi:addSkill(dengji)
godcaopi:addRelatedSkill("ex__jianxiong")
godcaopi:addRelatedSkill(tianxing)
godcaopi:addRelatedSkill("rende")
godcaopi:addRelatedSkill("ex__zhiheng")
godcaopi:addRelatedSkill("luanji")
Fk:loadTranslationTable{
  ["godcaopi"] = "神曹丕",
  ["chuyuan"] = "储元",
  [":chuyuan"] = "当一名角色受到伤害后，若你的“储”数小于你的体力上限，你可以令其摸一张牌，然后其将一张手牌置于你的武将牌上，称为“储”。",
  ["dengji"] = "登极",
  [":dengji"] = "觉醒技，准备阶段，若你的“储”数不小于3，你减1点体力上限，获得所有“储”，获得〖奸雄〗和〖天行〗。",
  ["tianxing"] = "天行",
  [":tianxing"] = "觉醒技，准备阶段，若你的“储”数不小于3，你减1点体力上限，获得所有“储”，失去〖储元〗，并获得下列技能中的一项：〖仁德〗、〖制衡〗、〖乱击〗。",
  ["caopi_chu"] = "储",
  ["#chuyuan-put"] = "储元：将一张手牌作为“储”置于其武将牌上",
}
--（官渡）高览 2020.6.28
--曹爽 2020.9.4
--群张辽 2020.10.26

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
  ["#qingleng-invoke"] = "清冷：你可以将一张牌当冰【杀】对%dest使用",
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
    local cards = room:askForDiscard(target, 3, 3, true, self.name, false, ".", "#sanchen-discard")
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
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
     player.phase == Player.Start and
     player:usedSkillTimes("sanchen", Player.HistoryGame) > 2
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
  ["#sanchen-discard"] = "三陈：弃置三张牌，若类别各不相同则你摸一张牌且其可以再发动“三陈”",
}

local zhanghuyuechen = General(extension, "zhanghuyuechen", "jin", 4)
local xijue = fk.CreateTriggerSkill{
  name = "xijue",
  anim_type = "offensive",
  events = {fk.GameStart, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        return target == player and data.to == Player.NotActive and player:getMark(self.name) > 0
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
    local tos = room:askForChoosePlayers(player, targets, 1, data.n, "#xijue_tuxi-invoke", "ex__tuxi")
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
    if #room:askForDiscard(target, 1, 1, true, "xiaoguo", true, ".|.|.|.|.|equip", "#xiaoguo-discard") > 0 then
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
  ["#shoufu-cost"] = "授符：选择角色将一张手牌置为“箓”，其不能使用打出“箓”同类型的牌",
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
    return #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ciwei-invoke::"..target.id) > 0
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
  ["#ciwei-invoke"] = "慈威：你可以弃置一张牌，取消 %dest 使用的牌",
}
--司马伷 2021.5.24
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
--黄祖 2021.6.24
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
    if skill.trueName == "slash_skill" and player:getMark("@wangong") > 0 and scope == Player.HistoryPhase then
      return 999
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("@wangong") > 0 then
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
Fk:loadTranslationTable{
  ["zhongyan"] = "钟琰",
  ["bolan"] = "博览",
  [":bolan"] = "出牌阶段开始时，你可以从随机三个“出牌阶段限一次”的技能中选择一个获得直到本阶段结束；其他角色的出牌阶段限一次，其可以失去1点体力，令你从随机三个“出牌阶段限一次”的技能中选择一个，其获得之直到此阶段结束。",
  ["yifa"] = "仪法",
  [":yifa"] = "锁定技，当其他角色使用【杀】或黑色普通锦囊牌指定你为目标后，其手牌上限-1直到其回合结束。",
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
--吕旷吕翔 2021.9.15
--华歆2021.9.24

Fk:loadTranslationTable{
  ["ol__dengzhi"] = "邓芝",
  ["xiuhao"] = "修好",
  [":xiuhao"] = "每名角色的回合限一次，你对其他角色造成伤害，或其他角色对你造成伤害时，你可防止此伤害，令伤害来源摸两张牌。",
  ["sujian"] = "素俭",
  [":sujian"] = "锁定技，弃牌阶段，你改为：将所有非本回合获得的手牌分配给其他角色，或弃置非本回合获得的手牌，并弃置一名其他角色至多等量的牌。",
}

Fk:loadTranslationTable{
  ["wangrongh"] = "王荣",
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

Fk:loadTranslationTable{
  ["xinchang"] = "辛敞",
  ["canmou"] = "参谋",
  [":canmou"] = "当手牌数全场唯一最多的角色使用普通锦囊牌指定目标时，你可以为此锦囊牌多指定一个目标。",
  ["zaowang"] = "造王",
  [":zaowang"] = "当体力值全场唯一最大的其他角色成为普通锦囊牌的唯一目标时，你可以也成为此牌目标，此牌结算后，若此牌对你造成伤害，你摸两张牌。",
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

--陈登 田豫 范疆张达2022.3.25
Fk:loadTranslationTable{
  ["ol__chendeng"] = "陈登",
  ["fengji"] = "丰积",
  [":fengji"] = "摸牌阶段开始时，你可以令你本回合以下至多两项数值-1：1.摸牌阶段摸牌数；2.出牌阶段使用【杀】的限制次数。你每选择一项，令一名其他角色下回合的对应项数值+2。选择完成后，你令你本回合未选择选项的数值+1。",
}
--羊祜 清河公主 贾充 2022.5.7
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

Fk:loadTranslationTable{
  ["ol__jiachong"] = "贾充",
  ["xiongshu"] = "凶竖",
  [":xiongshu"] = "其他角色出牌阶段开始时，你可以：弃置X张牌（为本轮你已发动过本技能的次数），展示其一张手牌，你秘密猜测其于此出牌阶段是否会使用与此牌同名的牌。出牌阶段结束时，若你猜对，你对其造成1点伤害；若你猜错，你获得此牌。",
  ["jianhui"] = "奸回",
  [":jianhui"] = "锁定技，你记录上次对你造成伤害的角色。当你对其造成伤害后，你摸一张牌；当其对你造成伤害后，其弃置一张牌。",
}

Fk:loadTranslationTable{
  ["ol__tengfanglan"] = "滕芳兰",
  ["luochong"] = "落宠",
  [":luochong"] = "准备阶段或当你每回合首次受到伤害后，你可以选择一项，令一名角色：1.回复1点体力；2.失去1点体力；3.弃置两张牌；4.摸两张牌。每轮每项每名角色限一次。",
  ["aichen"] = "哀尘",
  [":aichen"] = "锁定技，当你进入濒死状态时，若【落宠】选项数大于1，你移除其中一项。",
}

Fk:loadTranslationTable{
  ["sp__menghuo"] = "孟获",
  ["manwang"] = "蛮王",
  [":manwang"] = "出牌阶段，你可以弃置任意张牌依次执行前等量项：1.获得〖叛侵〗；2.摸一张牌；3.回复1点体力；4.摸两张牌并失去〖叛侵〗。",
  ["panqin"] = "叛侵",
  [":panqin"] = "出牌和弃牌阶段结束时，你可以将弃牌堆中你本阶段弃置的牌当【南蛮入侵】使用，若此牌目标数不小于这些牌的数量，你执行并移除〖蛮王〗的最后一项。",
}

Fk:loadTranslationTable{
  ["ruiji"] = "芮姬",
  ["qiaoli"] = "巧力",
  [":qiaoli"] = "出牌阶段各限一次，1.你可以将一张武器牌当【决斗】使用，此牌对目标角色造成伤害后，你摸与之攻击范围等量张牌，然后可以分配其中任意张牌；2.你可以将一张非武器装备牌当【决斗】使用且不能被响应，然后于结束阶段随机获得一张装备牌。",
  ["qingliang"] = "清靓",
  [":qingliang"] = "每回合限一次，当你成为其他角色使用的【杀】或伤害锦囊牌的唯一目标时，你可以展示所有手牌并选择一项：1.你与其各摸一张牌；2.弃器一种花色的所有手牌，取消此目标。",
}

local wangxiang = General(extension, "wangxiang", "jin", 3)
local bingxin = fk.CreateViewAsSkill{
  name = "bingxin",
  pattern = ".|.|.|.|.|basic|.",
  interaction = function()
    local names = {}
    local mark = Self:getMark("bingxin-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and
        ((Fk.currentResponsePattern == nil and card.skill:canUse(Self)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    if self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = Fk:currentRoom()
    local mark = player:getMark("bingxin-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, Fk:cloneCard(self.interaction.data).trueName)
    room:setPlayerMark(player, "bingxin-turn", mark)
    player:drawCards(1, self.name)
  end,
  enabled_at_play = function(self, player)
    local cards = player.player_cards[Player.Hand]
    return #cards == player.hp and (player.dying or
      (table.every(cards, function (id) return Fk:getCardById(id).color ==Fk:getCardById(cards[1]).color end)))
  end,
  enabled_at_response = function(self, player, response)
    local cards = player.player_cards[Player.Hand]
    return not response and #cards == player.hp and (player.dying or
    (table.every(cards, function (id) return Fk:getCardById(id).color ==Fk:getCardById(cards[1]).color end)))
  end,
}
wangxiang:addSkill(bingxin)
Fk:loadTranslationTable{
  ["wangxiang"] = "王祥",
  ["bingxin"] = "冰心",
  [":bingxin"] = "若你手牌的数量等于体力值且颜色相同，你可以摸一张牌视为使用一张与本回合以此法使用过的牌牌名不同的基本牌。",
}

Fk:loadTranslationTable{
  ["weizi"] = "卫兹",
  ["yuanzi"] = "援资",
  [":yuanzi"] = "每轮限一次，其他角色的准备阶段，你可以交给其所有手牌。若如此做，当其本回合造成伤害后，若其手牌数不小于你，你可以摸两张牌。",
  ["liejie"] = "烈节",
  [":liejie"] = "当你受到伤害后，你可以弃置至多三张牌并摸等量张牌，然后你可以弃置伤害来源至多X张牌（X为你以此法弃置的红色牌数）。",
}

local guohuai = General(extension, "guohuaij", "jin", 3, 3, General.Female)
local zhefu = fk.CreateTriggerSkill{
  name = "zhefu",
  anim_type = "offensive",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive and data.card.type == Card.TypeBasic
  end,
  on_cost = function(self, event, target, player, data)
    local targets = {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if not p:isKongcheng() then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#zhefu-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForDiscard(to, 1, 1, false, self.name, true, data.card.trueName, "#zhefu-discard")
    if #card == 0 then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local yidu = fk.CreateTriggerSkill{
  name = "yidu",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.is_damage_card and #TargetGroup:getRealTargets(data.tos) == 1 and
      not (data.card.extra_data and table.contains(data.card.extra_data, self.name)) and
      not player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1]):isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#yidu-invoke::"..TargetGroup:getRealTargets(data.tos)[1])
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    local cards = room:askForCardsChosen(player, to, 1, math.min(3, #to.player_cards[Player.Hand]), "h", self.name)
    to:showCards(cards)
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).color ~= Fk:getCardById(cards[1]).color then
        return
      end
    end
    room:throwCard(cards, self.name, to, player)
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card
  end,
  on_refresh = function(self, event, target, player, data)
    data.card.extra_data = data.card.extra_data or {}
    table.insertIfNeed(data.card.extra_data, self.name)
  end,
}
guohuai:addSkill(zhefu)
guohuai:addSkill(yidu)
Fk:loadTranslationTable{
  ["guohuaij"] = "郭槐",
  ["zhefu"] = "哲妇",
  [":zhefu"] = "当你于回合外使用或打出一张基本牌后，你可以令一名有手牌的其他角色选择弃置一张同名基本牌或受到你的1点伤害。",
  ["yidu"] = "遗毒",
  [":yidu"] = "当你使用仅指定唯一目标的【杀】或伤害锦囊牌后，若此牌未对其造成伤害，你可以展示其至多三张手牌，若颜色均相同，其弃置这些牌。",
  ["#zhefu-choose"] = "哲妇：你可以指定一名角色，其弃置一张同名牌或受到你的1点伤害",
  ["#zhefu-discard"] = "哲妇：你需弃置一张同名牌，否则其对你造成1点伤害",
  ["#yidu-invoke"] = "遗毒：你可以展示 %dest 至多三张手牌，若颜色相同则全部弃置",
}

--神孙权（东吴命运线版） 赵俨2022.8.14
--周处 曹宪曹华2022.9.6
--王衍2022.9.29
--霍峻 邓忠2022.10.21
--夏侯玄2022.11.3
Fk:loadTranslationTable{
  ["xiahouxuan"] = "夏侯玄",
  ["huanfu"] = "宦浮",
  [":huanfu"] = "当你使用【杀】指定目标或成为【杀】的目标后，你可以弃置任意张牌（至多为你的体力上限），若此【杀】对目标角色造成的伤害值为弃牌数，你摸弃牌数两倍的牌。",
  ["qingyix"] = "清议",
  [":qingyix"] = "出牌阶段限一次，你可以与至多两名其他有牌的角色同时弃置一张牌，若类型相同，你可以重复此流程。结束阶段，你可以获得其中颜色不同的牌各一张。",
  ["zeyue"] = "迮阅",
  [":zeyue"] = "限定技，准备阶段，你可以令一名你上个回合结束后（首轮为游戏开始后）对你造成过伤害的其他角色失去武将牌上一个技能（锁定技、觉醒技、限定技除外）。每轮结束时，其视为对你使用X张【杀】（X为其已失去此技能的轮数），若此【杀】造成伤害，其获得以此法失去的技能。",
}
--张芝2022.11.19

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
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      local n = 0
      if #p:getCardIds{Player.Equip, Player.Judge} > 0 then n = n + 1 end
      if p:isWounded() then n = n + 1 end
      if p.hp < #p.player_cards[Player.Hand] then n = n + 1 end
      p.tag["sankuang"] = n  --TODO: show target's sankuang_num when targeting
      if #p:getCardIds{Player.Hand, Player.Equip} >= n then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#sankuang-choose", self.name)
      if #to == 0 then
        to = {table.random(targets)}
      end
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if player.tag["beishi"] == nil then
      player.tag["beishi"] = to.id
    end
    local n = to.tag["sankuang"]
    if n > 0 then
      local cards = room:askForCard(to, n, #to:getCardIds{Player.Hand, Player.Equip}, true, self.name, false, ".", "#sankuang-give:::"..tostring(n))
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, false, fk.ReasonGive)
    end
    if room:getCardArea(data.card) == Card.PlayerEquip or room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(to, data.card, true, fk.ReasonPrey)
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
    local skills = {"Cancel"}
    for _, skill in ipairs(player.player_skills) do
      if skill.frequency == Skill.Compulsory and not skill.attached_equip then
        table.insert(skills, skill.name)
      end
    end
    local choice = room:askForChoice(player, skills, self.name)
    if choice == "Cancel" then
      room:loseHp(player, 1, self.name)
    else
      room:handleAddLoseSkills(player, "-"..choice, nil, true, false)
      if room:getCardArea(data.card) == Card.Processing then
        local targets = {}
        for _, p in ipairs(room:getAlivePlayers()) do
          if string.find(p.general, "olz__xun") then
            table.insert(targets, p.id)
          end
        end
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#daojie-choose", self.name)
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
  [":sankuang"] = "锁定技，当你每轮首次使用一种类别的牌后，你令一名其他角色交给你至少X张牌并获得你使用的牌（X为其满足的项数：1.场上有牌；2.已受伤；3.体力值小于手牌数）。",
  ["beishi"] = "卑势",
  [":beishi"] = "锁定技，当你首次发动〖三恇〗选择的角色失去最后的手牌后，你回复1点体力。",
  ["daojie"] = "蹈节",
  [":daojie"] = "宗族技，锁定技，当你每回合首次使用非伤害锦囊牌后，你选择一项：1.失去1点体力；2.失去一个锁定技，然后令一名同族角色获得此牌。",
  ["#sankuang-choose"] = "三恇：令一名其他角色交给你至少X张牌并获得你使用的牌",
  ["#sankuang-give"] = "三恇：你须交给其%arg张牌",
  ["#daojie-choose"] = "蹈节：令一名同族角色获得此牌",
}


Fk:loadTranslationTable{
  ["olz__xunshu"] = "荀淑",
  ["shenjun"] = "神君",
  [":shenjun"] = "当一名角色使用【杀】或普通锦囊牌时，你展示所有同名手牌记为「神君」，本阶段结束时，你可以将X张牌当任意「神君」牌使用（X为「神君」牌数）。",
  ["balong"] = "八龙",
  [":balong"] = "锁定技，当你每回合体力值首次变化后，若你手牌中锦囊牌为唯一最多的类型，你展示手牌并摸至与存活角色数相同。",
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
    if player.tag["fenchai"] == nil and player.gender ~= target.gender then
      player.tag["fenchai"] = target.id
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
        player.room:addPlayerMark(player, "shangshen-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#shangshen-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.tag["fenchai"] == nil and player.gender ~= target.gender then
      player.tag["fenchai"] = target.id
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
    local n = 4 - #target.player_cards[Player.Hand]
    if n > 0 then
      target:drawCards(n, self.name)
    end
  end,
}
local fenchai = fk.CreateTriggerSkill{
  name = "fenchai",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.FinishRetrial},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.tag["fenchai"]
  end,
  on_use = function(self, event, target, player, data)
    if player.room:getPlayerById(player.tag["fenchai"]).dead then
      data.card.suit = Card.Spade
    else
      data.card.suit = Card.Heart
    end
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
  [":fenchai"] = "锁定技，若首次成为你技能目标的异性角色存活，你的判定牌视为♥，否则视为♠。",
  ["#shangshen-invoke"] = "伤神：你可以进行一次【闪电】判定并令 %dest 将手牌摸至四张",
  ["yushen1"] = "视为其对你使用冰【杀】",
  ["yushen2"] = "视为你对其使用冰【杀】",
}

Fk:loadTranslationTable{
  ["olz__xuncai"] = "荀采",
  ["lieshi"] = "烈誓",
  [":lieshi"] = "出牌阶段，你可以选择一项：1.废除判定区并受到你的1点火焰伤害；2.弃置所有【闪】；3.弃置所有【杀】。然后令一名其他角色选择其他两项中的一项。",
  ["dianzhan"] = "点盏",
  [":dianzhan"] = "锁定技，当你每轮首次使用一种花色的牌后，你横置此牌唯一目标并重铸此花色的所有手牌，然后若你以此法横置了角色且你以此法重铸了牌，你摸一张牌。",
  ["huanyin"] = "还阴",
  [":huanyin"] = "锁定技，当你进入濒死状态时，你将手牌摸至4张。",
}
--神孙权（制衡技能版）

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
      Fk:currentRoom():addPlayerMark(player, "MinusMaxCards", 1)  --TODO: this global MaxCardsSkill is in tenyear_sp, move it
    end
  end,
  enabled_at_response = function(self, player, response)
    return player:hasSkill(self.name) and not response
  end,
}
local zhanding_record = fk.CreateTriggerSkill{
  name = "#zhanding_record",
  anim_type = "offensive",

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "zhanding")
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      data.card.extra_data = {"zhanding"}
    else
      if data.card.extra_data and data.card.extra_data[1] == "zhanding" then
        local n = #player.player_cards[Player.Hand] - player:getMaxCards()
        if n < 0 then
          player:drawCards(-n, self.name)
        elseif n > 0 then
          player.room:askForDiscard(player, n, n, false, self.name, false)
        end
      else
        player:addCardUseHistory(data.card.trueName, -1)
      end
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
        if string.find(p.general, "olz__wu") and p:getMaxCards() < n then
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
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), "AddMaxCards", 1)
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
        room:addPlayerMark(player, "MinusMaxCards", 1)
      end
    elseif n > 0 then
      room:askForDiscard(player, n, n, false, self.name, false)
      room:addPlayerMark(player, "AddMaxCards", 1)
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
--阿会喃 胡班2023.1.13
local ahuinan = General(extension, "ahuinan", "qun", 4)
local jueman = fk.CreateTriggerSkill{
  name = "jueman",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.to == Player.NotActive then
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
      self.cost_data = nil
      if #player.tag[self.name] > 2 and n == 0 then
        self.cost_data = player.tag[self.name][3][2]
      end
      if #player.tag[self.name] > 1 and n == 1 then
        self.cost_data = 1
      end
      player.tag[self.name] = {}
      return self.cost_data
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data == 1 then
      player:drawCards(1, self.name)
    else
      local room = player.room
      local name = self.cost_data.name
      local targets = {}
      if name == "slash" then
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not player:isProhibited(p, Fk:cloneCard(name)) end), function(p) return p.id end)
      elseif (name == "peach" and player:isWounded()) or name == "analeptic" then
        targets = {player.id}
      end
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#jueman-choose:::"..name, self.name, false)
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
ahuinan:addSkill(jueman)
Fk:loadTranslationTable{
  ["ahuinan"] = "阿会喃",
  ["jueman"] = "蟨蛮",
  [":jueman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均不为你，你视为使用本回合第三张使用的基本牌；仅其中之一为你，你摸一张牌。",
  ["#jueman-choose"] = "蟨蛮：选择视为使用【%arg】的目标",
}

--傅肜2023.2.4
--刘巴2023.2.25
--族：韩韶 韩融
--local hanshao = General(extension, "olz__hanshao", "qun", 3)
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
--hanshao:addSkill(liuju)
--hanshao:addSkill(xumin)
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
  [":lianhe"] = "出牌阶段开始时，你可以横置两名角色，其下个出牌阶段结束时，若其此阶段未摸牌，其选择一项：1.令你摸X+1张牌；2.交给你X-1张牌（X为其此阶段获得牌数且至多为3）。",
  ["huanjia"] = "缓颊",
  [":huanjia"] = "出牌阶段结束时，你可以与一名角色拼点，赢的角色可以使用一张拼点牌，若其：未造成伤害，你获得另一张拼点牌；造成了伤害，你失去一个技能。",
}
--马承2023.3.26

local quhuang = General(extension, "quhuang", "wu", 3)
local qiejian = fk.CreateTriggerSkill{
  name = "qiejian",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getMark("qiejian-turn") == 0 then
      for _, move in ipairs(data) do
        if move.from and player.room:getPlayerById(move.from):isKongcheng() and not player.room:getPlayerById(move.from).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              self.qiejian_to = move.from
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.qiejian_to)
    player:drawCards(1, self.name)
    to:drawCards(1, self.name)
    local choices = {"qiejian_nulli"}
    if #player:getCardIds{Player.Equip, Player.Judge} > 0 or #to:getCardIds{Player.Equip, Player.Judge} > 0 then
      table.insert(choices, 1, "qiejian_discard")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "qiejian_discard" then
      local targets = {}
      if #player:getCardIds{Player.Equip, Player.Judge} > 0 then table.insertIfNeed(targets, player.id) end
      if #to:getCardIds{Player.Equip, Player.Judge} > 0 then table.insertIfNeed(targets, to.id) end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#qiejian-choose", self.name)
      local p
      if #tos > 0 then
        p = room:getPlayerById(tos[1])
      else
        p = room:getPlayerById(table.random(targets))
      end
      local id = room:askForCardChosen(player, p, 'ej', self.name)
      room:throwCard({id}, self.name, p, player)
    else
      room:addPlayerMark(player, "qiejian-turn", 1)
    end
  end,
}
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
            if info.fromArea == Card.PlayerEquip then
              self.nishou_equip = info.cardId
              return not player:hasDelayedTrick("lightning") or player:getMark(self.name) == 0
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if not player:hasDelayedTrick("lightning") then
      table.insert(choices, "nishou_lightning")
    end
    if player:getMark(self.name) == 0 then
      table.insert(choices, "nishou_nulli")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "nishou_lightning" then
      local card = Fk:cloneCard("lightning")
      card:addSubcards({self.nishou_equip})
      room:useCard{
        from = player.id,
        tos = {{player.id}},
        card = card,
      }
    else
      room:addPlayerMark(player, self.name, 1)  --ATTENTION: this mark shouldn't end with "-phase"!
    end
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) > 0 and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 0)
    local n = #player.player_cards[Player.Hand]
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] < n then
        n = #p.player_cards[Player.Hand]
      end
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] == n then
        table.insert(targets, p.id)
      end
    end
    local to
    if #targets == 0 then
      return
    elseif #targets == 1 then
      to = targets[1]
    else
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#nishou-choose", self.name)
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
    end
    local cards1 = table.clone(player.player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(to).player_cards[Player.Hand])
    local move1 = {
      from = player.id,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,  --FIXME: this is still visible! same problem with dimeng!
    }
    local move2 = {
      from = to,
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = cards1,
      fromArea = Card.Processing,
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    local move4 = {
      ids = cards2,
      fromArea = Card.Processing,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move3, move4)
  end,
}
quhuang:addSkill(qiejian)
quhuang:addSkill(nishou)
Fk:loadTranslationTable{
  ["quhuang"] = "屈晃",
  ["qiejian"] = "切谏",
  [":qiejian"] = "当一名角色失去最后的手牌后，你可以与其各摸一张牌，然后选择一项：1.弃置你或其场上一张牌；2.本回合本技能失效。",
  ["nishou"] = "泥首",
  [":nishou"] = "锁定技，当你装备区里的牌进入弃牌堆后，你选择一项：1.将第一张装备牌当【闪电】使用；2.本阶段结束时与手牌数最少的角色交换手牌，然后本阶段内你无法选择本项。",
  ["qiejian_discard"] = "弃置你或其场上一张牌",
  ["qiejian_nulli"] = "本回合本技能失效",
  ["#qiejian-choose"] = "切谏：弃置你或其场上一张牌",
  ["nishou_lightning"] = "将第一张装备牌当【闪电】使用",
  ["nishou_nulli"] = "本阶段无法选择本项，本阶段结束时你与手牌数最少的角色交换手牌",
  ["#nishou-choose"] = "泥首：你需与手牌数最少的角色交换手牌",
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
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,  --TODO: reason recast
    })
    local n = #effect.cards
    player:drawCards(n, self.name)
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
      local cards = room:askForCard(target, n, n, true, self.name, true, ".|.|.|.|.|"..type, "#jianhe-choose:::"..tostring(n))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          from = effect.tos[1],
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,  --TODO: reason recast
        })
        target:drawCards(#cards, self.name)
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

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return player.tag["chuanwu"] and data.to == Player.NotActive
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
  ["#jianhe-choose"] = "剑合：你需重铸%arg张相同类别的牌，否则受到1点雷电伤害",
}

local dongtuna = General(extension, "dongtuna", "qun", 4)
local jianman = fk.CreateTriggerSkill{
  name = "jianman",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.to == Player.NotActive then
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
    local choice = room:askForChoice(target, {"recover", "kangrui_damage"}, self.name)
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

  refresh_events = {fk.DamageCaused, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("kangrui_damage-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      player.room:addPlayerMark(player, "MinusMaxCards-turn", 999)
      player.room:setPlayerMark(player, "kangrui_damage-turn", 0)
    end
  end,
}
zhangyi:addSkill(dianjun)
zhangyi:addSkill(kangrui)
Fk:loadTranslationTable{
  ["ol__zhangyiy"] = "张翼",
  ["dianjun"] = "殿军",
  [":dianjun"] = "锁定技，回合结束时，你受到1点伤害并执行一个额外的出牌阶段。",
  ["kangrui"] = "亢锐",
  [":kangrui"] = "当一名角色于其回合内首次受到伤害后，你可以摸一张牌并令其：1.回复1点体力；2.本回合下次造成的伤害+1，然后当其造成伤害后，其此回合手牌上限改为0。",
  ["#kangrui-invoke"] = "亢锐：你可以摸一张牌，令 %dest 选择回复1点体力或本回合下次造成伤害+1",
  ["kangrui_damage"] = "本回合下次造成伤害+1，造成伤害后本回合手牌上限改为0",
}

local maxiumatie = General(extension, "maxiumatie", "qun", 4)
local kenshang = fk.CreateViewAsSkill{
  name = "kenshang",
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
    local room = Fk:currentRoom()
    if not table.every(room:getOtherPlayers(player), function (p) return player:inMyAttackRange(p) end) and
      room:askForSkillInvoke(player, self.name, nil, "#kenshang-invoke") then
      table.forEach(TargetGroup:getRealTargets(use.tos), function (id)
        TargetGroup:removeTarget(use.tos, id)
      end)
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not player:inMyAttackRange(p) then
          TargetGroup:pushTargets(use.tos, p.id)
        end
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return player:hasSkill(self.name) and not response
  end,
}
local kenshang_record = fk.CreateTriggerSkill{
  name = "#kenshang_record",

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "kenshang")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:addPlayerMark(player, "kenshang", data.damage)
    else
      if player:getMark("kenshang") > 0 then
        if #data.card.subcards > player:getMark("kenshang") then
          player:drawCards(player:getMark("kenshang"), "kenshang")
        else
          local skills = {}
          for _, skill in ipairs(player.player_skills) do
            if not skill.attached_equip then
              table.insert(skills, skill.name)
            end
          end
          local choice = room:askForChoice(player, skills, "kenshang")
          room:handleAddLoseSkills(player, "-"..choice, nil, true, false)
        end
        room:setPlayerMark(player, "kenshang", 0)
      end
    end
  end,
}
kenshang:addRelatedSkill(kenshang_record)
maxiumatie:addSkill("mashu")
maxiumatie:addSkill(kenshang)
Fk:loadTranslationTable{
  ["maxiumatie"] = "马休马铁",
  ["kenshang"] = "垦伤",
  [":kenshang"] = "你可以将任意张牌当【杀】使用，然后可以将目标改为所有你攻击范围外的角色。若这些牌数大于X，你摸X张牌，否则你失去一个技能。（X为以此法使用【杀】造成的伤害）",
  ["#kenshang-invoke"] = "垦伤：你可以将目标改为所有你攻击范围外的角色",
}

local zhujun = General(extension, "ol__zhujun", "qun", 4)
local cuipo = fk.CreateTriggerSkill{
  name = "cuipo",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and not data.chain and
      player:getMark("@cuipo-turn") == #Fk:translate(data.card.trueName)/3
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
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
  [":cuipo"] = "锁定技，当你使用牌对目标造成伤害时，若牌名字数等于本回合你已使用牌数，此伤害+1。（X为此牌牌名字数）",
  ["@cuipo-turn"] = "摧破",
}

--手杀
--留赞 凌操 孙茹 
--朱灵 李丰
--诸葛果
--曹纯
--赵统赵广
--马钧
--祢衡
--陶谦
--庞德公
--司马昭 王元姬 2019.6.30
--审配 2019.9.17
--胡金定 2019.12.24
--贾逵 张翼 2020.3.12
--陈登 杨彪 2020.4.10
--杨仪 董承 2020.5.15
--郑玄（切水果） 邓芝 2020.6.20
--群张辽 群张郃 群徐晃 群甘宁 2020.6.30
--苏飞 通渠贾逵 2020.8.18
--傅肜 2020.9.22
--丁原 2020.10.24
--司马师 羊徽瑜 2020.11.28
--胡车儿 2021.1.5
--公孙康 2021.2.23
--智包：王粲 陈震 孙邵 荀谌 卞夫人 费祎 骆统 杜预 神郭嘉 荀彧2021.3.20
--理包：李肃2021.4.15
--南华（flappy bird） 2021.6.4
--信包：辛毗 吴景 糜夫人 王淩 王甫赵累 周处 孔融 羊祜 神太史慈 孙策 2021.6.4
--周群 
--谯周 2021.10.14
--仁包：华歆 许靖 蔡贞姬 向宠 张仲景 张温 刘璋 桥公 2021.8.22
--勇包：文鸯 陈武董袭 宗预 袁涣 花鬘 王双 孙翊 高览2021.11.10
--孙寒华（小游戏） 傅佥2021.11.10
--司马孚 阎圃 马元义2021.12.7
--严包：张昌蒲 崔琰 蒋琬 蒋钦 吕范 皇甫嵩 朱儁 2022.1.7
--杨婉 裴秀 刘赪 2022.1.7
--群黄忠 蒋干 2022.2.9
--毛玠2022.3.16
--杨阜 马日磾 刘巴2022.4.13
--阮慧2022.7.14
--王濬2022.9.16
--曹嵩2022.10.26
--彭羕2022.12.27
--群魏延2023.3.23

--海外
--群葛玄2021.9.9
--贾充2021.9.24
--朵思大王 乐就 吴班2021.10.1
--群于禁2021.11.11
--臧霸 刘宏 霍峻 群曹操 牛金（1v1技能组） 张曼成2022.3.3
--曹肇 濮阳兴 田豫 王昶 吴景 王粲 2022.4.14
--刘夫人 马腾 蹇硕 牛辅董翓 蒋济 邴原 鲍信 傅肜 陈武董袭 王淩2022.6.22
--张既 冯习 张宁 于夫罗2022.8.15
--张南 呼厨泉2022.9.29
--阎象 李遗2022.10.9
--夏侯尚 夏侯恩 2022.10.21
--桥蕤2022.11.18
--武侠：王越 李彦 童渊 徐庶2022.12.3
--魏续 郝萌2023.1.13
--武侠：群典韦 群鲁肃 夏侯紫萼 赵娥 2023.4.17

--欢乐
--神华佗

--小程序
--极系列：吕布 大乔 小乔 郭嘉


--特殊
--忠胆英杰：崔琰 皇甫嵩
Fk:loadTranslationTable{
  ["huangfusong"] = "皇甫嵩",
  ["fenyue"] = "奋钺",
  [":fenyue"] = "出牌阶段限X次，你可以与一名角色拼点，若你赢，你选择一项：1.其不能使用或打出手牌直到回合结束；2.视为你对其使用了【杀】（不计入次数限制）。若你没赢，你结束出牌阶段。（X为存活的忠臣数）。",
}
--用间篇专属 
--1v1 及原稿 牛金 何进 韩遂 向宠 孙翊 朵思大王 注诣
--凯撒
--官盗：国战不臣（文钦 孟达） 群曹操 孙寒华
--台版：曹昂 夏侯霸 祖茂 曹洪 马良 丁奉
return extension
