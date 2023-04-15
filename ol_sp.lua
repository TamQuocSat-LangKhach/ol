local extension = Package("ol_sp")
extension.extensionName = "ol"

Fk:loadTranslationTable{
  ["ol_sp"] = "OL专属",
  ["olz"] = "宗族",
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
Fk:loadTranslationTable{
  ["wanglang"] = "王朗",
  ["gushe"] = "鼓舌",
  [":gushe"] = "出牌阶段限一次，你可以用一张手牌与至多三名角色同时拼点，然后依次结算拼点结果，没赢的角色选择一项：1.弃置一张牌；2.令你摸一张牌。若拼点没赢的角色是你，你需先获得一个“饶舌”标记（你有7个饶舌标记时，你死亡）。",
  ["jici"] = "激词",
  [":jici"] = "当你发动“鼓舌”拼点的牌亮出后，若点数小于X，你可令点数+X；若点数等于X，视为你此回合未发动过“鼓舌”。（X为你“饶舌”标记的数量）。",
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
    return player:usedSkillTimes(self.name) == 0 and not player:isKongcheng()
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
Fk:loadTranslationTable{
  ["buzhi"] = "步骘",
  ["hongde"] = "弘德",
  [":hongde"] = "当你一次获得或失去至少两张牌后，你可以令一名其他角色摸一张牌。",
  ["dingpan"] = "定叛",
  [":dingpan"] = "出牌阶段限X次，你可以令一名装备区里有牌的角色摸一张牌，然后其选择一项：1.令你弃置其装备区里的一张牌；2.获得其装备区里的所有牌，若如此做，你对其造成1点伤害（X为场上存活的反贼数）。",
}

Fk:loadTranslationTable{
  ["dongbai"] = "董白",
  ["lianzhu"] = "连诛",
  [":lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。",
  ["xiahui"] = "黠慧",
  [":xiahui"] = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，其不能使用、打出、弃置这些牌直到其体力值减少为止。",
}

--赵襄
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

Fk:loadTranslationTable{
  ["huangfusong"] = "皇甫嵩",
  ["fenyue"] = "奋钺",
  [":fenyue"] = "出牌阶段限X次，你可以与一名角色拼点，若你赢，你选择一项：1.其不能使用或打出手牌直到回合结束；2.视为你对其使用了【杀】（不计入次数限制）。若你没赢，你结束出牌阶段。（X为存活的忠臣数）。",
}

--刘琦
--唐咨
--王允

--麹义
--戏志才
Fk:loadTranslationTable{
  ["sunqian"] = "孙乾",
  ["qianya"] = "谦雅",
  [":qianya"] = "当你成为锦囊牌的目标后，你可以将任意张手牌交给一名其他角色。",
  ["shuimeng"] = "说盟",
  [":shuimeng"] = "出牌阶段结束时，你可以与一名角色拼点，若你赢，视为你使用【无中生有】；若你没赢，视为其对你使用【过河拆桥】。",
}

--审配 官渡 2017.12
--荀谌
--刘晔
--淳于琼
Fk:loadTranslationTable{
  ["shenpei"] = "审配",
  ["gangzhi"] = "刚直",
  [":gangzhi"] = "锁定技，其他角色对你造成的伤害，和你对其他角色造成的伤害均视为体力流失。",
  ["beizhan"] = "备战",
  [":beizhan"] = "回合结束后，你可以令一名角色将手牌补至体力上限（至多为5）。该角色回合开始时，若其手牌数为全场最多，则其本回合内不能使用牌指定其他角色为目标。",
}
Fk:loadTranslationTable{
  ["xunchen"] = "荀谌",
  ["fenglve"] = "锋略",
  [":fenglve"] = "出牌阶段开始时，你可以与一名角色拼点：若你赢，该角色将每个区域内各一张牌交给你；若你没赢，你交给其一张牌。你与其他角色的拼点结果确定后，你可以将你的拼点牌交给该角色。",
  ["moushi"] = "谋识",
  [":moushi"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色。若如此做，当该角色于其下个出牌阶段对每名角色第一次造成伤害后，你摸一张牌。",
}

--苏飞 龙舟 2018.05
--黄权
Fk:loadTranslationTable{
  ["sufei"] = "苏飞",
  ["lianpian"] = "联翩",
  [":lianpian"] = "每回合限三次，当你于出牌阶段使用牌连续指定相同角色为目标时，你可以摸一张牌，若如此做，你可以将此牌交给该角色。",
}
Fk:loadTranslationTable{
  ["huangquan"] = "黄权",
  ["dianhu"] = "点虎",
  [":dianhu"] = "锁定技，游戏开始时，你指定一名其他角色；当你对该角色造成伤害后或该角色回复体力后，你摸一张牌。",
  ["jianji"] = "谏计",
  [":jianji"] = "出牌阶段限一次，你可以令一名其他角色摸一张牌，然后其可以使用该牌。",
}

--卑弥呼 2018.6.8
--鲁芝 2018.7.5

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
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:usedSkillTimes(self.name) == 0 then
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
    if right > 2 then room:handleAddLoseSkills(player, "jianxiong|xingshang", nil, true, false) end
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
      player.room:handleAddLoseSkills(player, "-jianxiong|-xingshang", nil, true, false)
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
--许靖 2020.1.1
--袁谭袁尚 2020.2.7
--孙邵 2020.4.30
--神甄姬 神曹丕 2020.5.22
--（官渡）高览 2020.6.28
--曹爽 2020.9.4
--群张辽 2020.10.26
--晋 司马懿 张春华 司马师 夏侯徽 司马昭 王元姬 杜预 张虎乐綝 2020.12.15 应变篇
--张陵 2021.1.10
--卧龙凤雏 2021.2.7
--羊徽瑜 2021.3.12
--司马伷 2021.5.24
--卫瓘 石苞 彻里吉 潘淑 2021.6.9
--黄祖 2021.6.24
--钟琰 黄承彦 2021.7.15
--高干 杜袭2021.8.27
--吕旷吕翔 2021.9.15
--华歆2021.9.24
--邓芝 王荣 卞夫人2021.10.1
--左棻 2021.10.30
--杨艳 杨芷2021.11.17
--冯方女 杨仪 朱灵2021.12.24
--（官渡，未上线）辛评 韩猛2021.12.26
--宣公主 董昭 辛敞 吾彦2022.1.20
--陈登 田豫 范疆张达 朱灵2022.3.25
--羊祜 清河公主 贾充 2022.5.7
--滕芳兰2022.6.12
--群孟获 芮姬 王祥 卫兹2022.6.14
--郭槐
--神孙权（东吴命运线版） 赵俨2022.8.14
--周处 曹宪曹华2022.9.6
--王衍2022.9.29
--霍峻 邓忠2022.10.21
--夏侯玄2022.11.3
--张芝2022.11.19
--颍川荀氏：荀谌 荀淑 荀粲 荀采
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
      p.tag["sankuang"] = n  --TODO: show target's sankuangnum when targeting
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
      local cards = room:askForCard(to, n, #to:getCardIds{Player.Hand, Player.Equip}, true, self.name, false, ".", "#sankuang-give")
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
    if target == player and player:hasSkill(self.name) then
      if player:getMark("daojie-turn") == 0 and
        table.contains({"amazing_grace", "collateral", "dismantlement", "ex_nihilo", "god_salvation", "indulgence", "nullification", "snatch", "iron_chain", "supply_shortage"}, data.card.name) then
        return true
      end
    end
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
  ["#sankuang-give"] = "三恇：你须交给其X张牌",
  ["#daojie-choose"] = "蹈节：令一名同族角色获得此牌",
}
Fk:loadTranslationTable{
  ["olz__xunshu"] = "荀淑",
  ["shenjun"] = "神君",
  [":shenjun"] = "当一名角色使用【杀】或普通锦囊牌时，你展示所有与此牌同名的手牌并均称为“神君”牌。本阶段结束时，你可将“神君”牌数张牌当任意“神君”牌使用。",
  ["balong"] = "八龙",
  [":balong"] = "锁定技，当你每回合体力值首次变化后，若你手牌中锦囊牌为唯一最多的类别，你展示手牌并将手牌摸至角色数张。",
}
Fk:loadTranslationTable{
  ["olz__xuncan"] = "荀粲",
  ["yushen"] = "熨身",
  [":yushen"] = "出牌阶段限一次，你可以选择一名其他角色并令其回复1点体力，然后选择一项：1.视为其对你使用一张冰【杀】；2.视为你对其使用一张冰【杀】。",
  ["shangshen"] = "伤神",
  [":shangshen"] = "当每回合首次有角色受到属性伤害后，你可以进行一次【闪电】判定并令其将手牌摸至四张。",
  ["fenchai"] = "分钗",
  [":fenchai"] = "锁定技，若首次成为你技能目标的异性角色存活，你的判定牌视为红桃，否则视为黑桃。",
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
  --[[enabled_at_response = function (self, player)
    return false  FIXME: response use
  end,]]
}
local zhanding_record = fk.CreateTriggerSkill{
  name = "#zhanding_record",
  anim_type = "offensive",

  refresh_events = {fk.AfterCardUseDeclared, fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "zhanding")
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      if player:getMaxCards() > 0 then
        player.room:addPlayerMark(player, "MinusMaxCards", 1)  --TODO: this global MaxCardsSkill is in tenyear_sp, move it
      end
    elseif event == fk.Damage then
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

local olz__wuxian = General(extension, "olz__wuxian", "shu", 3)
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
--傅肜2023.2.4
--刘巴2023.2.25
--族：韩韶 韩融
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
--屈晃2023.4.14
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

--特殊
--用间篇专属 
--1v1 及原稿 牛金 何进 韩遂 向宠 孙翊 朵思大王 注诣
--神貂蝉
--官盗：群曹操 孙寒华
return extension
