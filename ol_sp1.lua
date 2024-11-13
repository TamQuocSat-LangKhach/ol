local extension = Package("ol_sp1")
extension.extensionName = "ol"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["ol_sp1"] = "OL专属1",
  ["ol"] = "OL",
  ["ol_sp"] = "OLSP",
}

local zhugeke = General(extension, "zhugeke", "wu", 3)
local aocai = fk.CreateViewAsSkill{
  name = "aocai",
  pattern = ".|.|.|.|.|basic",
  anim_type = "special",
  expand_pile = function()
    return Self:getTableMark("aocai")
  end,
  prompt = "#aocai",
  card_filter = function(self, to_select, selected)
    if #selected == 0 and table.contains(Self:getTableMark("aocai"), to_select) then
      local card = Fk:getCardById(to_select)
      if card.type == Card.TypeBasic then
        if Fk.currentResponsePattern == nil then
          return Self:canUse(card) and not Self:prohibitUse(card)
        else
          return Exppattern:Parse(Fk.currentResponsePattern):match(card)
        end
      end
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    return Fk:getCardById(cards[1])
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return player.phase == Player.NotActive
  end,
}
local aocai_trigger = fk.CreateTriggerSkill{
  name = "#aocai_trigger",

  refresh_events = {fk.AskForCardUse, fk.AskForCardResponse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(aocai) and player ~= player.room.current
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = player:isKongcheng() and 4 or 2
    local ids = {}
    for i = 1, n, 1 do
      if i > #room.draw_pile then break end
      table.insert(ids, room.draw_pile[i])
    end
    player.room:setPlayerMark(player, "aocai", ids)
  end,
}
local duwu = fk.CreateActiveSkill{
  name = "duwu",
  anim_type = "offensive",
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@@duwu-turn") == 0
  end,
  card_filter = function(self, to_select)
    return not Self:prohibitDiscard(to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if target.hp == #selected_cards then
        if table.contains(selected_cards, Self:getEquipment(Card.SubtypeWeapon)) then
          return Self:distanceTo(target) == 1  --FIXME: some skills(eg.gongqi, meibu) add attackrange directly!
        else
          return Self:inMyAttackRange(target)
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local duwu_trigger = fk.CreateTriggerSkill{
  name = "#duwu_trigger",
  mute = true,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.duwu and data.extra_data.duwu == player.id and not target.dead and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("duwu")
    room:notifySkillInvoked(player, "duwu", "negative")
    room:setPlayerMark(player, "@@duwu-turn", 1)
    room:loseHp(player, 1, "duwu")
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return data.damage and data.damage.skillName == "duwu" and data.damage.from and data.damage.from == player
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.duwu = player.id
  end,
}
aocai:addRelatedSkill(aocai_trigger)
duwu:addRelatedSkill(duwu_trigger)
zhugeke:addSkill(aocai)
zhugeke:addSkill(duwu)
Fk:loadTranslationTable{
  ["zhugeke"] = "诸葛恪",
  ["#zhugeke"] = "兴家赤族",
  ["designer:zhugeke"] = "韩旭",
  ["illustrator:zhugeke"] = "LiuHeng",
  ["aocai"] = "傲才",
  [":aocai"] = "当你于回合外需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌（若你没有手牌则改为四张），若你观看的牌中有此牌，你可以使用或打出之。",
  ["duwu"] = "黩武",
  [":duwu"] = "出牌阶段，你可以弃置X张牌对你攻击范围内的一名其他角色造成1点伤害（X为该角色的体力值）。"..
  "若其因此进入濒死状态且被救回，则濒死状态结算后你失去1点体力，且本回合不能再发动〖黩武〗。",
  ["#aocai"] = "傲才：你可以使用或打出其中你需要的基本牌",
  ["@@duwu-turn"] = "黩武失效",
  ["#duwu_trigger"] = "黩武",

  ["$aocai1"] = "哼，易如反掌。",
  ["$aocai2"] = "吾主圣明，泽披臣属。",
  ["$duwu1"] = "破曹大功，正在今朝！",
  ["$duwu2"] = "全力攻城！言退者，斩！",
  ["~zhugeke"] = "重权震主，是我疏忽了……",
}

local chengyu = General(extension, "chengyu", "wei", 3)
local shefu = fk.CreateTriggerSkill{
  name = "shefu",
  anim_type = "control",
  derived_piles = "$shefu",
  events ={fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and not player:isKongcheng()
      else
        return target ~= player and player.phase == Player.NotActive and
          (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick)
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
      player:addToPile("$shefu", self.cost_data, false, self.name)
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
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and
      (player:getHandcardNum() > data.from:getHandcardNum() or player:getHandcardNum() < math.min(data.from:getHandcardNum(), 5))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > data.from:getHandcardNum() then
      local num = data.from:getHandcardNum() + 1
      local cards = room:askForDiscard(player, num, 999, false, self.name, true, ".",
        "#benyu-discard::"..data.from.id..":"..num, true)
      if #cards >= num then
        self.cost_data = {tos = {data.from.id}, cards = cards}
        return true
      end
    elseif room:askForSkillInvoke(player, self.name, nil, "#benyu-draw:::"..math.min(data.from:getHandcardNum(), 5)) then
      self.cost_data = {tos = {data.from.id}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data.cards then
      local room = player.room
      room:throwCard(self.cost_data.cards, self.name, player, player)
      if not data.from.dead then
        room:damage{
          from = player,
          to = data.from,
          damage = 1,
          skillName = self.name,
        }
      end
    else
      player:drawCards(math.min(5, data.from:getHandcardNum()) - player:getHandcardNum(), self.name)
    end
  end,
}
chengyu:addSkill(shefu)
chengyu:addSkill(benyu)
Fk:loadTranslationTable{
  ["chengyu"] = "程昱",
  ["#chengyu"] = "泰山捧日",
  ["illustrator:chengyu"] = "GH",
  ["shefu"] = "设伏",
  [":shefu"] = "结束阶段开始时，你可将一张手牌扣置于武将牌上，称为“伏兵”。若如此做，你为“伏兵”记录一个基本牌或锦囊牌的名称"..
  "（须与其他“伏兵”记录的名称均不同）。当其他角色于你的回合外使用手牌时，你可将记录的牌名与此牌相同的一张“伏兵”置入弃牌堆，然后此牌无效。",
  ["benyu"] = "贲育",
  [":benyu"] = "当你受到伤害后，若你的手牌数不大于伤害来源手牌数，你可以将手牌摸至与伤害来源手牌数相同（最多摸至5张）；"..
  "否则你可以弃置大于伤害来源手牌数的手牌，然后对其造成1点伤害。",
  ["#shefu-cost"] = "设伏：你可以将一张手牌扣置为“伏兵”",
  ["$shefu"] = "伏兵",
  ["#benyu-discard"] = "贲育：你可以弃置至少%arg张手牌，对 %dest 造成1点伤害",
  ["#benyu-draw"] = "贲育：你可以将手牌摸至 %arg 张",

  ["$shefu1"] = "圈套已设，埋伏已完，只等敌军进来。",
  ["$shefu2"] = "如此天网，量你插翅也难逃。",
  ["$benyu1"] = "曹公智略乃上天所授！",
  ["$benyu2"] = "天下大乱，群雄并起，必有命事。",
  ["~chengyu"] = "此诚报效国家之时，吾却休矣。",
}

local sunhao = General(extension, "sunhao", "wu", 5)
local canshi = fk.CreateTriggerSkill{
  name = "canshi",
  anim_type = "drawcard",
  events ={fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not table.every(player.room:getAlivePlayers(false), function (p)
      return not p:isWounded() and not (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player)
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player) then
        n = n + 1
      end
    end
    data.n = data.n + n
  end,
}
local canshi_delay = fk.CreateTriggerSkill{
  name = "#canshi_delay",
  anim_type = "negative",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
      player:usedSkillTimes(canshi.name) > 0 and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, self.name, false)
  end,
}
local chouhai = fk.CreateTriggerSkill{
  name = "chouhai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events ={fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local guiming = fk.CreateTriggerSkill{
  name = "guiming$",
  frequency = Skill.Compulsory,
}
canshi:addRelatedSkill(canshi_delay)
sunhao:addSkill(canshi)
sunhao:addSkill(chouhai)
sunhao:addSkill(guiming)
Fk:loadTranslationTable{
  ["sunhao"] = "孙皓",
  ["#sunhao"] = "时日曷丧",
  ["illustrator:sunhao"] = "LiuHeng",
  ["canshi"] = "残蚀",
  [":canshi"] = "摸牌阶段，你可以多摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用基本牌或锦囊牌时，你弃置一张牌。",
  ["chouhai"] = "仇海",
  [":chouhai"] = "锁定技，当你受到伤害时，若你没有手牌，你令此伤害+1。",
  ["guiming"] = "归命",
  [":guiming"] = "主公技，锁定技，其他吴势力角色于你的回合内视为已受伤的角色。",

  ["#canshi_delay"] = "残蚀",

  ["$canshi1"] = "众人与蝼蚁何异？哈哈哈……",
  ["$canshi2"] = "难道一切不在朕手中？",
  ["$chouhai1"] = "哼，树敌三千又如何？",
  ["$chouhai2"] = "不发狂，就灭亡！",
  ["$guiming1"] = "这是要我命归黄泉吗？",
  ["$guiming2"] = "这就是末世皇帝的不归路！",
  ["~sunhao"] = "命啊！命！",
}

local shixie = General(extension, "shixie", "qun", 3)
local biluan = fk.CreateTriggerSkill{
  name = "biluan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isNude() then
      return table.find(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#biluan-invoke:::"..#kingdoms, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if player.dead then return end
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    local num = tonumber(player:getMark("@shixie_distance")) + #kingdoms
    room:setPlayerMark(player,"@shixie_distance",num > 0 and "+"..num or num)
  end,
}
local biluan_distance = fk.CreateDistanceSkill{
  name = "#biluan_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@shixie_distance"))
    if num > 0 then
      return num
    end
  end,
}
biluan:addRelatedSkill(biluan_distance)
shixie:addSkill(biluan)
local lixia = fk.CreateTriggerSkill{
  name = "lixia",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"draw1", "lixia_draw:"..target.id}
    if target:isWounded() then table.insert(all_choices, "lixia_recover:"..target.id) end
    local choices = room:askForChoices(player, all_choices, 1, 2, self.name, nil, false)
    for _, choice in ipairs(choices) do
      if choice == "draw1" then
        player:drawCards(1, self.name)
      elseif choice:startsWith("lixia_draw") then
        target:drawCards(2, self.name)
      else
        room:recover { num = 1, skillName = self.name, who = target, recoverBy = player}
      end
    end
    if player.dead then return end
    local num = tonumber(player:getMark("@shixie_distance"))-1
    room:setPlayerMark(player,"@shixie_distance",num > 0 and "+"..num or num)
  end,
}
local lixia_distance = fk.CreateDistanceSkill{
  name = "#lixia_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@shixie_distance"))
    if num < 0 then
      return num
    end
  end,
}
lixia:addRelatedSkill(lixia_distance)
shixie:addSkill(lixia)
Fk:loadTranslationTable{
  ["shixie"] = "士燮",
  ["#shixie"] = "南交学祖",
  ["designer:shixie"] = "Rivers",
  ["illustrator:shixie"] = "銘zmy",

  ["biluan"] = "避乱",
  [":biluan"] = "结束阶段，若有其他角色计算与你的距离为1，你可以弃置一张牌，令其他角色计算与你的距离+X（X为存活势力数）。",
  ["lixia"] = "礼下",
  [":lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一至两项：1.摸一张牌；2.令其摸两张牌；3.令其回复1点体力。选择完成后，其他角色计算与你的距离-1。",
  ["#biluan-invoke"] = "避乱：你可弃一张牌，令其他角色计算与你距离+%arg",
  ["@shixie_distance"] = "距离",
  ["lixia_draw"] = "令%src摸两张牌",
  ["lixia_recover"] = "令%src回复1点体力",

  ["$biluan1"] = "身处乱世，自保足矣。",
  ["$biluan2"] = "避一时之乱，求长世安稳。",
  ["$lixia1"] = "将军真乃国之栋梁。",
  ["$lixia2"] = "英雄可安身立命于交州之地。",
  ["~shixie"] = "我这一生，足矣……",
}

local zhanglu = General(extension, "zhanglu", "qun", 3)
local yishe = fk.CreateTriggerSkill{
  name = "yishe",
  anim_type = "support",
  derived_piles = "zhanglu_mi",
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and #player:getPile("zhanglu_mi") == 0
      else
        if #player:getPile("zhanglu_mi") == 0 and player:isWounded() then
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
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#yishe-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:drawCards(2, self.name)
      if player:isNude() then return false end
      local cards = room:askForCard(player, 2, 2, true, self.name, false, nil, "#yishe-cost")
      player:addToPile("zhanglu_mi", cards, true, self.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local bushi = fk.CreateTriggerSkill{
  name = "bushi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (target == player or data.from == player) and #player:getPile("zhanglu_mi") > 0
    and not (data.from.dead or data.to.dead)
  end,
  on_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      self.cancel_cost = false
      for i = 1, data.damage do
        if #player:getPile("zhanglu_mi") == 0 or target.dead or self.cancel_cost then return end
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(target, self.name, nil, "#bushi-invoke:"..player.id) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("zhanglu_mi")
    local id = (#cards == 1) and cards[1] or
    room:askForCardChosen(target, player, { card_data = { { "zhanglu_mi", cards } } }, self.name)
    room:obtainCard(target, id, true, fk.ReasonPrey)
  end,
}
local midao = fk.CreateTriggerSkill{
  name = "midao",
  anim_type = "control",
  expand_pile = "zhanglu_mi",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #player:getPile("zhanglu_mi") > 0
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
  ["#zhanglu"] = "政宽教惠",
  ["designer:zhanglu"] = "逍遥鱼叔",
  ["illustrator:zhanglu"] = "銘zmy",
  ["yishe"] = "义舍",
  [":yishe"] = "结束阶段开始时，若你的武将牌上没有牌，你可以摸两张牌，若如此做，你将两张牌置于武将牌上，称为“米”。当“米”移至其他区域后，"..
  "若你的武将牌上没有“米”，你回复1点体力。",
  ["bushi"] = "布施",
  [":bushi"] = "当你受到1点伤害后，或其他角色受到你造成的1点伤害后，受到伤害的角色可以获得一张“米”。",
  ["midao"] = "米道",
  [":midao"] = "当一张判定牌生效前，你可以打出一张“米”代替之。",
  ["zhanglu_mi"] = "米",
  ["#bushi-invoke"] = "布施：你可以获得 %src 的一张“米”",
  ["#yishe-invoke"] = "义舍：你可以摸两张牌，然后将两张牌置为“米”",
  ["#yishe-cost"] = "义舍：将两张牌置为“米”",
  ["#midao-choose"] = "米道：你可以打出一张“米”修改 %dest 的判定",

  ["$yishe1"] = "行大义之举，须有向道之心。",
  ["$yishe2"] = "你有你的权谋，我，哼，自有我的道义。",
  ["$bushi1"] = "布施行善，乃道义之本。",
  ["$bushi2"] = "行布施，得天道。",
  ["$midao1"] = "从善从良，从五斗米道。",
  ["$midao2"] = "兼济天下，解百姓之忧。",
  ["~zhanglu"] = "但，归置于道，无意凡事争斗。",
}

local mayunlu = General(extension, "mayunlu", "shu", 4, 4, General.Female)
local fengpo = fk.CreateTriggerSkill{
  name = "fengpo",
  anim_type = "offensive",
  events ={fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.trueName == "duel") then
      local room = player.room
      local to = room:getPlayerById(data.to)
      if not to.dead and U.isOnlyTarget(to, data, event) then
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event == nil then return false end
        local x = player:getMark("fengpo_record_" .. data.card.trueName.."-turn")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
            local use = e.data[1]
            if use.from == player.id and use.card.trueName == data.card.trueName then
              x = e.id
              room:setPlayerMark(player, "fengpo_record_" .. data.card.trueName.."-turn", x)
              return true
            end
          end, Player.HistoryTurn)
        end
        return x == use_event.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"fengpo_draw", "fengpo_damage", "Cancel"}, self.name,
      "#fengpo-choice::"..data.to..":"..data.card:toLogString())
    if choice == "Cancel" then return false end
    room:doIndicate(player.id, {data.to})
    self.cost_data = {tos = {data.to}, choice = choice}
    return true
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(data.to)
    local n = 0
    for _, id in ipairs(to:getCardIds("he")) do
      if Fk:getCardById(id).suit == Card.Diamond then
        n = n + 1
      end
    end
    --FIXME:理论上应当对全部目标加伤的，但考虑到不会有重复目标，两者没区别就是了
    if self.cost_data.choice == "fengpo_draw" then
      if n > 0 then
        player:drawCards(n, self.name)
      end
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      player:drawCards(1, self.name)
      if n > 0 then
        data.additionalDamage = (data.additionalDamage or 0) + n
      end
    end
  end,
}
mayunlu:addSkill("mashu")
mayunlu:addSkill(fengpo)
Fk:loadTranslationTable{
  ["mayunlu"] = "马云騄",
  ["#mayunlu"] = "剑胆琴心",
  ["cv:mayunlu"] = "水原",
  ["illustrator:mayunlu"] = "木美人",
  ["fengpo"] = "凤魄",
  [":fengpo"] = "当你每回合首次使用【杀】或【决斗】指定目标后，你可以选择一项：1.摸X张牌，此牌伤害+1；2.摸一张牌，此牌伤害+X"..
  "（X为其<font color='red'>♦</font>牌数）。",
  ["fengpo_draw"] = "摸X张牌，伤害+1",
  ["fengpo_damage"] = "摸一张牌，伤害+X",
  ["#fengpo-invoke"] = "凤魄：你可以令你对 %dest 使用的%arg发动“凤魄”",
  ["#fengpo-choice"] = "凤魄：选择你对 %dest 使用的%arg执行一项",

  ["$fengpo1"] = "等我提枪上马，打你个落花流水！",
  ["$fengpo2"] = "对付你，用不着我家哥哥亲自上阵！",
  ["~mayunlu"] = "呜呜……是你们欺负人……",
}

local wutugu = General(extension, "wutugu", "qun", 15)
local ranshang = fk.CreateTriggerSkill{
  name = "ranshang",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.Damaged then
        return data.damageType == fk.FireDamage
      else
        return player.phase == Player.Finish and player:getMark("@wutugu_ran") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:addPlayerMark(player, "@wutugu_ran", data.damage)
    else
      room:loseHp(player, player:getMark("@wutugu_ran"), self.name)
    end
  end,
}
local hanyong = fk.CreateTriggerSkill{
  name = "hanyong",
  anim_type = "offensive",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.card.name == "savage_assault" or data.card.name == "archery_attack") and player.hp < player.room:getTag("RoundCount")
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
wutugu:addSkill(ranshang)
wutugu:addSkill(hanyong)
Fk:loadTranslationTable{
  ["wutugu"] = "兀突骨",
  ["#wutugu"] = "霸体金刚",
  ["designer:wutugu"] = "韩旭",
  ["illustrator:wutugu"] = "biou09&KayaK",

  ["ranshang"] = "燃殇",
  [":ranshang"] = "锁定技，当你受到1点火焰伤害后，你获得1枚“燃”标记；结束阶段，你失去X点体力（X为“燃”标记的数量）。",
  ["hanyong"] = "悍勇",
  [":hanyong"] = "当你使用【南蛮入侵】或【万箭齐发】时，若你的体力值小于游戏轮数，你可以令此牌造成的伤害+1。",
  ["@wutugu_ran"] = "燃",

  ["$ranshang1"] = "战火燃尽英雄胆！",
  ["$ranshang2"] = "尔等，竟如此歹毒！",
  ["$hanyong1"] = "犯我者，杀！",
  ["$hanyong2"] = "藤甲军从无对手，不服来战！",
  ["~wutugu"] = "撤，快撤！",
}

local cuiyan = General(extension, "cuiyan", "wei", 3)
local yawang = fk.CreateTriggerSkill{
  name = "yawang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events ={fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room.alive_players) do
      if p.hp == player.hp then
        n = n + 1
      end
    end
    player:drawCards(n, self.name)
    player.room:addPlayerMark(player, "yawang-turn", n)
    return true
  end,

  refresh_events ={fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@yawang-turn", 1)
  end,
}
local yawang_prohibit = fk.CreateProhibitSkill{
  name = "#yawang_prohibit",
  prohibit_use = function(self, player, card)
    return player:usedSkillTimes("yawang", Player.HistoryTurn) > 0 and player.phase == Player.Play and
      player:getMark("@yawang-turn") >= player:getMark("yawang-turn")
  end,
}
local xunzhi = fk.CreateTriggerSkill{
  name = "xunzhi",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if (player:getNextAlive() == p or p:getNextAlive() == player) and player.hp == p.hp then return end
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
  end,
}
yawang:addRelatedSkill(yawang_prohibit)
cuiyan:addSkill(yawang)
cuiyan:addSkill(xunzhi)
Fk:loadTranslationTable{
  ["cuiyan"] = "崔琰",
  ["#cuiyan"] = "伯夷之风",
  ["designer:cuiyan"] = "凌天翼",
  ["yawang"] = "雅望",
  [":yawang"] = "锁定技，摸牌阶段开始时，你放弃摸牌，改为摸X张牌，然后你于出牌阶段内至多使用X张牌（X为与你体力值相等的角色数）。",
  ["xunzhi"] = "殉志",
  [":xunzhi"] = "准备阶段开始时，若你的上家和下家与你的体力值均不相等，你可以失去1点体力。若如此做，你的手牌上限+2。",
  ["@yawang-turn"] = "雅望",

  ["$yawang1"] = "君子，当以正气立于乱世。",
  ["$yawang2"] = "琰，定不负诸位雅望！",
  ["$xunzhi1"] = "春秋大义，自在我心！",
  ["$xunzhi2"] = "成大义者，这点牺牲算不得什么！",
  ["~cuiyan"] = "尔等，皆是欺世盗名之辈！",
}

local guansuo = General(extension, "guansuo", "shu", 4)
local zhengnan = fk.CreateTriggerSkill{
  name = "zhengnan",
  anim_type = "drawcard",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, self.name)
    local choices = {"wusheng", "dangxian", "zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      local choice = player.room:askForChoice(player, choices, self.name, "#zhengnan-choice", true)
      player.room:handleAddLoseSkills(player, choice, nil)
    end
  end,
}
local xiefang = fk.CreateDistanceSkill{
  name = "xiefang",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p:isFemale() then
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
  ["#guansuo"] = "倜傥孑侠",
  ["designer:guansuo"] = "千幻",
  ["illustrator:guansuo"] = "depp",
  ["zhengnan"] = "征南",
  [":zhengnan"] = "当其他角色死亡后，你可以摸三张牌，若如此做，你获得下列技能中的任意一个：〖武圣〗，〖当先〗和〖制蛮〗。",
  ["xiefang"] = "撷芳",
  [":xiefang"] = "锁定技，你计算与其他角色的距离-X（X为女性角色数）。",
  ["#zhengnan-choice"] = "征南：选择获得的技能",

  ["$zhengnan1"] = "索全凭丞相差遣，万死不辞！",
  ["$zhengnan2"] = "末将愿承父志，随丞相出征！",
  ["$wusheng_guansuo"] = "逆贼，可识得关氏之勇？",
  ["$dangxian_guansuo"] = "各位将军，且让小辈先行出战！",
  ["$zhiman_guansuo"] = "蛮夷可抚，不可剿！",
  ["~guansuo"] = "只恨天下未平，空留遗志。",
}

local tadun = General(extension, "tadun", "qun", 4)
local luanzhan = fk.CreateTriggerSkill{
  name = "luanzhan",
  anim_type = "offensive",
  events = {fk.HpChanged, fk.TargetSpecified, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if event == fk.HpChanged then
      return data.damageEvent and (data.damageEvent.from == player or data.damageEvent.to == player) and player:hasSkill(self)
    elseif event == fk.TargetSpecified then
      return player == target and data.firstTarget and player:hasSkill(self) and (data.card.trueName == "slash" or
      (data.card.color == Card.Black and data.card:isCommonTrick())) and
      data.targetGroup and #data.targetGroup < player:getMark("@luanzhan")
    else
      return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or
      (data.card.color == Card.Black and data.card:isCommonTrick())) and
      player:getMark("@luanzhan") > 0 and #player.room:getUseExtraTargets(data, false) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardTargetDeclared then
      local n = player:getMark("@luanzhan")
      local tos = player.room:askForChoosePlayers(player, player.room:getUseExtraTargets(data), 1, n,
      "#luanzhan-choose:::"..data.card:toLogString()..":"..n, self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.HpChanged then
      player.room:addPlayerMark(player, "@luanzhan", 1)
    elseif event == fk.TargetSpecified then
      player.room:removePlayerMark(player, "@luanzhan", (player:getMark("@luanzhan") + 1) // 2)
    else
      for _, id in ipairs(self.cost_data) do
        table.insert(data.tos, {id})
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@luanzhan") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@luanzhan", 0)
  end,
}
tadun:addSkill(luanzhan)
Fk:loadTranslationTable{
  ["tadun"] = "蹋顿",
  ["#tadun"] = "北狄王",
  ["illustrator:tadun"] = "NOVART",
  ["designer:tadun"] = "Rivers",

  ["luanzhan"] = "乱战",
  [":luanzhan"] = "当一名角色因你造成或受到的伤害而扣减体力后，你获得1枚“乱战”。"..
  "当【杀】或黑色普通锦囊牌指定第一个目标后，若使用者为你且目标角色数小于X，你弃一半数量的“乱战”（向上取整）。"..
  "当【杀】或黑色普通锦囊牌选择目标后，若使用者为你，你可令至多X名角色也成为此牌的目标。（X为“乱战”数）",

  ["@luanzhan"] = "乱战",
  ["#luanzhan-choose"] = "乱战：你可以为%arg额外指定至多%arg2个目标",

  ["$luanzhan1"] = "受袁氏大恩，当效死力。",
  ["$luanzhan2"] = "现，正是我乌桓崛起之机。",
  ["~tadun"] = "呃……不该趟曹袁之争的浑水……",
}

local yanbaihu = General(extension, "yanbaihu", "qun", 4)
local zhidao = fk.CreateTriggerSkill{
  name = "zhidao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.to ~= player and
      not data.to.dead and not data.to:isAllNude() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    local cards = U.askforCardsChosenFromAreas(player, data.to, "hej", self.name, nil, nil, false)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
    end
    room:setPlayerMark(player, "@@zhidao-turn", 1)
  end,
}
local zhidao_prohibit = fk.CreateProhibitSkill{
  name = "#zhidao_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@zhidao-turn") > 0 and card and from ~= to
  end,
}
local jili = fk.CreateTriggerSkill{
  name = "jili",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and target:distanceTo(player) == 1 and
    data.card.color == Card.Red and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
    data.from ~= player.id and not table.contains(AimGroup:getAllTargets(data.tos), player.id) and
    U.canTransferTarget(player, data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.is_damage_card or
      table.contains({"dismantlement", "snatch", "chasing_near"}, data.card.name) or
      data.card.is_derived then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "negative")
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "control")
    end
    room:doIndicate(player.id, {target.id})
    local targets = {player.id}
    if type(data.subTargets) == "table" then
      table.insertTable(targets, data.subTargets)
    end
    AimGroup:addTargets(room, data, targets)
  end,
}
zhidao:addRelatedSkill(zhidao_prohibit)
yanbaihu:addSkill(zhidao)
yanbaihu:addSkill(jili)
Fk:loadTranslationTable{
  ["yanbaihu"] = "严白虎",
  ["#yanbaihu"] = "豺牙落涧",
  ["designer:yanbaihu"] = "Rivers",
  ["illustrator:yanbaihu"] = "NOVART",

  ["zhidao"] = "雉盗",
  [":zhidao"] = "锁定技，当你于出牌阶段内第一次对区域里有牌的其他角色造成伤害后，你获得其手牌、装备区和判定区里的各一张牌，"..
  "然后直到回合结束，其他角色不能被选择为你使用牌的目标。",
  ["jili"] = "寄篱",
  [":jili"] = "锁定技，当一名其他角色成为红色基本牌或红色普通锦囊牌的目标时，若其与你的距离为1且"..
  "你既不是此牌的使用者也不是目标，你也成为此牌的目标。",
  ["@@zhidao-turn"] = "雉盗",

  ["$zhidao1"] = "谁有地盘，谁是老大！",
  ["$zhidao2"] = "乱世之中，能者为王！",
  ["$jili1"] = "寄人篱下的日子，不好过呀！",
  ["$jili2"] = "这份恩德，白虎记下了！",
  ["~yanbaihu"] = "严舆吾弟，为兄来陪你了。",
}

local wanglang = General(extension, "wanglang", "wei", 3)
local gushe = fk.CreateActiveSkill{
  name = "gushe",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  prompt = "#gushe-prompt",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 3 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
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
        if not player.dead then
          if p:isNude() or #room:askForDiscard(p, 1, 1, true, self.name, true, ".", "#gushe-discard::"..player.id) == 0 then
            player:drawCards(1, self.name)
          end
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
    if player:hasSkill(self) then
      if player == data.from then
        return data.fromCard.number <= player:getMark("@raoshe")
      elseif data.results[player.id] then
        return data.results[player.id].toCard.number <= player:getMark("@raoshe")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if player == data.from then
      data.fromCard.number = math.min(13, data.fromCard.number + player:getMark("@raoshe"))
    elseif data.results[player.id] then
      data.results[player.id].toCard.number = math.min(13, data.results[player.id].toCard.number + player:getMark("@raoshe"))
    end
    if player.phase == Player.Play then
      player:setSkillUseHistory("gushe", 0, Player.HistoryPhase)
    end
  end,
}
wanglang:addSkill(gushe)
wanglang:addSkill(jici)
Fk:loadTranslationTable{
  ["wanglang"] = "王朗",
  ["#wanglang"] = "凤鹛",
  ["designer:wanglang"] = "千幻",
  ["illustrator:wanglang"] = "銘zmy",
  ["gushe"] = "鼓舌",
  [":gushe"] = "出牌阶段限一次，你可以用一张手牌与至多三名角色同时拼点，然后依次结算拼点结果，没赢的角色选择一项：1.弃置一张牌；2.令你摸一张牌。"..
  "若拼点没赢的角色是你，你需先获得一个“饶舌”标记（你有7个饶舌标记时，你死亡）。",
  ["jici"] = "激词",
  [":jici"] = "当你的拼点牌亮出后，若点数不大于X，你可令点数+X并视为此回合未发动过〖鼓舌〗。（X为你“饶舌”标记的数量）。",
  ["@raoshe"] = "饶舌",
  ["#gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %dest 摸一张牌",
  ["#gushe-prompt"] = "鼓舌：你可以与至多三名角色同时拼点",

  ["$gushe1"] = "公既知天命，识时务，为何要兴无名之师，犯我疆界？",
  ["$gushe2"] = "你若倒戈卸甲，以礼来降，仍不失封侯之位，国安民乐，岂不美哉？",
  ["$jici1"] = "谅尔等腐草之荧光，如何比得上天空之皓月？",
  ["$jici2"] = "你……诸葛村夫，你敢！",
  ["~wanglang"] = "你，你…哇啊…啊……",
}

local litong = General(extension, "litong", "wei", 4)
local tuifeng = fk.CreateTriggerSkill{
  name = "tuifeng",
  anim_type = "masochism",
  derived_piles = "$tuifeng",
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
    player:addToPile("$tuifeng", self.cost_data, false, self.name)
  end,
}
local tuifeng_trigger = fk.CreateTriggerSkill{
  name = "#tuifeng_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player:getPile("$tuifeng") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("tuifeng")
    room:notifySkillInvoked(player, "tuifeng")
    local n = #player:getPile("$tuifeng")
    room:moveCards({
      from = player.id,
      ids = player:getPile("$tuifeng"),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = "tuifeng",
    })
    if player.dead then return end
    room:addPlayerMark(player, "@tuifeng-turn", n)
    player:drawCards(2 * n, "tuifeng")
  end,
}
local tuifeng_targetmod = fk.CreateTargetModSkill{
  name = "#tuifeng_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@tuifeng-turn") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@tuifeng-turn")
    end
  end,
}
tuifeng:addRelatedSkill(tuifeng_targetmod)
tuifeng:addRelatedSkill(tuifeng_trigger)
litong:addSkill(tuifeng)
Fk:loadTranslationTable{
  ["litong"] = "李通",
  ["#litong"] = "万亿吾独往",
  ["illustrator:litong"] = "瞎子Ghe",
  ["tuifeng"] = "推锋",
  [":tuifeng"] = "当你受到1点伤害后，你可以将一张牌置于武将牌上，称为“锋”。准备阶段开始时，若你的武将牌上有“锋”，你将所有“锋”置入弃牌堆，"..
  "摸2X张牌，然后你于此回合的出牌阶段内使用【杀】的次数上限+X（X为你此次置入弃牌堆的“锋”数）。",
  ["#tuifeng_trigger"] = "推锋",
  ["#tuifeng-cost"] = "推锋：你可以将一张牌置于武将牌上，称为“锋”",
  ["@tuifeng-turn"] = "推锋",
  ["$tuifeng"] = "推锋",

  ["$tuifeng1"] = "摧锋陷阵，以杀贼首！",
  ["$tuifeng2"] = "敌锋之锐，我已尽知。",
  ["~litong"] = "战死沙场，快哉。",
}

local mizhu = General(extension, "mizhu", "shu", 3)
local ziyuan = fk.CreateActiveSkill{
  name = "ziyuan",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  prompt = "#ziyuan",
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
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
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
local jugu = fk.CreateTriggerSkill{
  name = "jugu",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    player.room:drawCards(player, player.maxHp, self.name)
  end,
}
local jugu_maxcards = fk.CreateMaxCardsSkill{
  name = "#jugu_maxcards",
  frequency = Skill.Compulsory,
  correct_func = function(self, player)
    if player:hasSkill(self) then
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
  ["#mizhu"] = "挥金追义",
  ["designer:mizhu"] = "千幻",
  ["illustrator:mizhu"] = "瞎子Ghe",
  ["ziyuan"] = "资援",
  [":ziyuan"] = "出牌阶段限一次，你可以将任意张点数之和为13的手牌交给一名其他角色，然后该角色回复1点体力。",
  ["jugu"] = "巨贾",
  [":jugu"] = "锁定技，1.你的手牌上限+X。2.游戏开始时，你摸X张牌。（X为你的体力上限）",
  ["#ziyuan"] = "资援：你可以将点数之和为13的手牌交给一名其他角色，并令其回复1点体力",

  ["$jugu1"] = "钱？要多少有多少。",
  ["$jugu2"] = "君子爱财，取之有道。",
  ["$ziyuan1"] = "区区薄礼，万望使君笑纳。",
  ["$ziyuan2"] = "雪中送炭，以解君愁。",
  ["~mizhu"] = "劣弟背主，我之罪也。",
}

local buzhi = General(extension, "buzhi", "wu", 3)
local hongde = fk.CreateTriggerSkill{
  name = "hongde",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if #move.moveInfo > 1 and ((move.from == player.id and move.to ~= player.id) or
          (move.to == player.id and move.toArea == Card.PlayerHand)) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#hongde-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
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
  prompt = "#dingpan",
  times = function(self)
    return Self.phase == Player.Play and
    #table.filter(Fk:currentRoom().alive_players, function (p)
      return p.role == "rebel"
    end) - Self:usedSkillTimes(self.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) <
      #table.filter(Fk:currentRoom().alive_players, function (p)
        return p.role == "rebel"
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select):getCardIds("e") > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(1, self.name)
    local choice = room:askForChoice(target, {"dingpan_discard:"..player.id, "dingpan_damage:"..player.id}, self.name)
    if choice[10] == "i" then
      local id = room:askForCardChosen(player, target, "e", self.name)
      room:throwCard({id}, self.name, target, player)
    else
      room:moveCardTo(target:getCardIds("e"), Card.PlayerHand, target, fk.ReasonJustMove, self.name, nil, true, target.id)
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
buzhi:addSkill(hongde)
buzhi:addSkill(dingpan)
Fk:loadTranslationTable{
  ["buzhi"] = "步骘",
  ["#buzhi"] = "积跬靖边",
  ["illustrator:buzhi"] = "sinno",
  ["hongde"] = "弘德",
  [":hongde"] = "当你一次获得或失去至少两张牌后，你可以令一名其他角色摸一张牌。",
  ["dingpan"] = "定叛",
  [":dingpan"] = "出牌阶段限X次，你可以令一名装备区里有牌的角色摸一张牌，然后其选择一项：1.令你弃置其装备区里的一张牌；"..
  "2.获得其装备区里的所有牌，若如此做，你对其造成1点伤害（X为场上存活的反贼数）。",
  ["#hongde-choose"] = "弘德：你可以令一名其他角色摸一张牌",
  ["#dingpan"] = "定叛：令一名装备区里有牌的角色摸一张牌，然后其选择弃置装备或收回装备并受到你造成的伤害",
  ["dingpan_discard"] = "%src弃置你装备区里的一张牌",
  ["dingpan_damage"] = "收回所有装备，%src对你造成1点伤害",

  ["$hongde1"] = "江南重义，东吴尚德。",
  ["$hongde2"] = "德无单行，福必双至。",
  ["$dingpan1"] = "从孙者生，从刘者死！",
  ["$dingpan2"] = "多行不义必自毙！",
  ["~buzhi"] = "交州已定，主公尽可放心。",
}

local dongbai = General(extension, "dongbai", "qun", 3, 3, General.Female)
local lianzhu = fk.CreateActiveSkill{
  name = "lianzhu",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#lianzhu",
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
    player:showCards(effect.cards)
    if player.dead or not table.contains(player:getCardIds("h"), effect.cards[1]) then return end
    local card = Fk:getCardById(effect.cards[1])
    room:obtainCard(target, card, true, fk.ReasonGive)
    if player.dead then return end
    if card.color == Card.Black then
      if #target:getCardIds{Player.Hand, Player.Equip} < 2 or
        #room:askForDiscard(target, 2, 2, true, self.name, true, ".", "#lianzhu-discard:"..player.id) ~= 2 then
        player:drawCards(2, self.name)
      end
    end
  end,
}
local xiahui = fk.CreateMaxCardsSkill{
  name = "xiahui",
  frequency = Skill.Compulsory,
  exclude_from = function(self, player, card)
    return player:hasSkill(self) and card.color == Card.Black
  end,
}
local xiahui_trigger = fk.CreateTriggerSkill{
  name = "#xiahui_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.HpChanged},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove and player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    elseif event == fk.HpChanged then
      return target == player and data.num < 0 and
        table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@xiahui-inhand") > 0 end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          local to = room:getPlayerById(move.to)
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black and table.contains(to:getCardIds("h"), info.cardId) then
              room:setCardMark(Fk:getCardById(info.cardId), "@@xiahui-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.HpChanged then
      for _, id in ipairs(player:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@xiahui-inhand", 0)
      end
    end
  end,
}
local xiahui_prohibit = fk.CreateProhibitSkill{
  name = "#xiahui_prohibit",
  prohibit_use = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.find(cards, function(id) return Fk:getCardById(id):getMark("@@xiahui-inhand") > 0 end)
  end,
  prohibit_response = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.find(cards, function(id) return Fk:getCardById(id):getMark("@@xiahui-inhand") > 0 end)
  end,
  prohibit_discard = function(self, player, card)
    return card:getMark("@@xiahui-inhand") > 0
  end,
}
xiahui:addRelatedSkill(xiahui_trigger)
xiahui:addRelatedSkill(xiahui_prohibit)
dongbai:addSkill(lianzhu)
dongbai:addSkill(xiahui)
Fk:loadTranslationTable{
  ["dongbai"] = "董白",
  ["#dongbai"] = "魔姬",
  ["illustrator:dongbai"] = "alien", -- 掌上明珠
  ["lianzhu"] = "连诛",
  [":lianzhu"] = "出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若该牌为黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。",
  ["xiahui"] = "黠慧",
  [":xiahui"] = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，其不能使用、打出、弃置这些牌直到其体力值减少为止。",
  ["#lianzhu"] = "连诛：交给一名角色一张牌，若为黑色，其弃两张牌或令你摸两张牌",
  ["#lianzhu-discard"] = "连诛：你需弃置两张牌，否则 %src 摸两张牌",
  ["@@xiahui-inhand"] = "黠慧",

  ["$lianzhu1"] = "若有不臣之心，定当株连九族。",
  ["$lianzhu2"] = "你们都是一条绳上的蚂蚱~",
  ["~dongbai"] = "放肆，我要让爷爷赐你们死罪！",
}

local zhaoxiang = General(extension, "zhaoxiang", "shu", 4, 4, General.Female)
local fanghun = fk.CreateViewAsSkill{
  name = "fanghun",
  prompt = "#fanghun",
  pattern = "slash,jink",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local c = Fk:getCardById(to_select)
    return c.trueName == "slash" or c.name == "jink"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
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
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying", 1)
    player:drawCards(1, self.name)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@meiying") > 0
  end,
}
local fanghun_record = fk.CreateTriggerSkill{
  name = "#fanghun_record",

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@meiying", data.damage)
  end,
}
local fuhan = fk.CreateTriggerSkill{
  name = "fuhan",
  anim_type = "special",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:getMark("@meiying") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local maxHp = math.max(player:usedSkillTimes("fanghun", Player.HistoryGame), 2)
    maxHp = math.min(maxHp, 8)
    return player.room:askForSkillInvoke(player, self.name, nil, "#fuhan-invoke:::"..maxHp)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    local generals = room:findGenerals(function(g)
      return Fk.generals[g].kingdom == "shu"
    end, 5)
    local general = room:askForGeneral(player, generals, 1, true)
    if general == nil then
      general = table.random(generals)
    end
    room:changeHero(player, general, false, false, true)
    local maxHp = math.max(n + player:usedSkillTimes("fanghun", Player.HistoryGame), 2)
    maxHp = math.min(maxHp, 8)
    room:changeMaxHp(player, maxHp - player.maxHp)
    player.gender = Fk.generals[player.general].gender
    room:broadcastProperty(player, "gender")
    if player.hp == 0 then
      room:killPlayer({who = player.id,})
    end
    if table.every(player.room:getOtherPlayers(player), function(p) return p.hp >= player.hp end) and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
fanghun:addRelatedSkill(fanghun_record)
zhaoxiang:addSkill(fanghun)
zhaoxiang:addSkill(fuhan)
Fk:loadTranslationTable{
  ["zhaoxiang"] = "赵襄",
  ["#zhaoxiang"] = "拾梅鹊影",
  ["designer:zhaoxiang"] = "千幻",
  ["illustrator:zhaoxiang"] = "木美人",
  ["fanghun"] = "芳魂",
  [":fanghun"] = "当你使用【杀】造成伤害后或受到【杀】造成的伤害后，你获得等于伤害值的“梅影”标记；你可以移去1个“梅影”标记发动〖龙胆〗并摸一张牌。",
  ["fuhan"] = "扶汉",
  [":fuhan"] = "限定技，准备阶段开始时，你可以移去所有“梅影”标记，随机观看五名未登场的蜀势力角色，将武将牌替换为其中一名角色，"..
  "并将体力上限数调整为本局游戏中移去“梅影”标记的数量（至少2，至多8），然后若你是体力值最低的角色，你回复1点体力。",
  ["#fanghun"] = "芳魂：你可以移去1个“梅影”标记，发动〖龙胆〗并摸一张牌",
  ["@meiying"] = "梅影",
  ["#fuhan-invoke"] = "扶汉：你可以变身为一名蜀势力武将！（体力上限为%arg）",

  ["$fanghun1"] = "万花凋落尽，一梅独傲霜。",
  ["$fanghun2"] = "暗香疏影处，凌风踏雪来！",
  ["$fuhan1"] = "承先父之志，扶汉兴刘。",
  ["$fuhan2"] = "天将降大任于我。",
  ["~zhaoxiang"] = "遁入阴影之中……",
}

local dongyun = General(extension, "dongyun", "shu", 3)
local bingzheng = fk.CreateTriggerSkill{
  name = "bingzheng",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      not table.every(player.room:getAlivePlayers(), function(p) return p:getHandcardNum() == p.hp end)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room:getAlivePlayers(), function(p)
      return p:getHandcardNum() ~= p.hp end), Util.IdMapper), 1, 1, "#bingzheng-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"bingzheng_draw"}
    if not to:isKongcheng() then
      table.insert(choices, 1, "bingzheng_discard")
    end
    local choice = room:askForChoice(player, choices, self.name, "#bingzheng-choice::"..to.id)
    if choice == "bingzheng_draw" then
      to:drawCards(1, self.name)
    else
      room:askForDiscard(to, 1, 1, false, self.name, false)
    end
    if #to.player_cards[Player.Hand] == to.hp then
      player:drawCards(1, self.name)
      if to ~= player then
        local card = room:askForCard(player, 1, 1, true, self.name, true, ".", "#bingzheng-card::"..to.id)
        if #card > 0 then
          room:obtainCard(to, card[1], false, fk.ReasonGive)
        end
      end
    end
  end,
}
local sheyan = fk.CreateTriggerSkill{
  name = "sheyan",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card:isCommonTrick() then
      local room = player.room
      local targets = room:getUseExtraTargets(data, true, true)
      local origin_targets = U.getActualUseTargets(room, data, event)
      if #origin_targets > 1 then
        table.insertTable(targets, origin_targets)
      end
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, self.cost_data, 1, 1,
    "#sheyan-choose:::"..data.card:toLogString(), self.name, true, false, "addandcanceltarget_tip", AimGroup:getAllTargets(data.tos))
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if table.contains(AimGroup:getAllTargets(data.tos), self.cost_data) then
      AimGroup:cancelTarget(data, self.cost_data)
      return self.cost_data == player.id
    else
      AimGroup:addTargets(player.room, data, self.cost_data)
    end
  end,
}
dongyun:addSkill(bingzheng)
dongyun:addSkill(sheyan)
Fk:loadTranslationTable{
  ["dongyun"] = "董允",
  ["#dongyun"] = "骨鲠良相",
  ["designer:dongyun"] = "如释帆飞",
  ["illustrator:dongyun"] = "玖等仁品",
  ["bingzheng"] = "秉正",
  [":bingzheng"] = "出牌阶段结束时，你可以令手牌数不等于体力值的一名角色弃置一张手牌或摸一张牌。然后若其手牌数等于体力值，你摸一张牌，且可以交给该角色一张牌。",
  ["sheyan"] = "舍宴",
  [":sheyan"] = "当你成为一张普通锦囊牌的目标时，你可以为此牌增加一个目标或减少一个目标（目标数至少为一）。",
  ["#bingzheng-choose"] = "秉正：令一名角色弃一张手牌或摸一张牌，然后若其手牌数等于体力值，你摸一张牌且可以交给其一张牌",
  ["#bingzheng-choice"] = "秉正：选择令 %dest 执行的一项",
  ["bingzheng_discard"] = "其弃置一张手牌",
  ["bingzheng_draw"] = "其摸一张牌",
  ["#bingzheng-card"] = "秉正：你可以交给 %dest 一张牌",
  ["#sheyan-choose"] = "舍宴：你可以为%arg增加/减少一个目标",
  ["#collateral-choose"] = "请为对 %dest 使用的%arg指定被杀的目标",

  ["$bingzheng1"] = "自古，就是邪不胜正！",
  ["$bingzheng2"] = "主公面前，岂容小人搬弄是非！",
  ["$sheyan1"] = "公事为重，宴席不去也罢。",
  ["$sheyan2"] = "还是改日吧。",
  ["~dongyun"] = "大汉，要亡于宦官之手了……",
}

local mazhong = General(extension, "mazhong", "shu", 4)
local fuman = fk.CreateActiveSkill{
  name = "fuman",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("fuman-turn") == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive)
    room:addPlayerMark(target, "fuman-turn", 1)
    room:setPlayerMark(target, self.name, effect.cards[1])
  end,
}
local fuman_record = fk.CreateTriggerSkill{
  name = "#fuman_record",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self, true) and target:getMark("fuman") ~= 0 then
      if data.card:isVirtual() then
        if #data.card.subcards > 0 then
          for _, id in ipairs(data.card.subcards) do
            if target:getMark("fuman") == id then
              return true
            end
          end
        end
      else
        return data.card:getEffectiveId() == target:getMark("fuman")
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "fuman", 0)
    player:drawCards(1, "fuman")
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("fuman") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fuman", 0)
  end,
}
fuman:addRelatedSkill(fuman_record)
mazhong:addSkill(fuman)
Fk:loadTranslationTable{
  ["mazhong"] = "马忠",
  ["#mazhong"] = "笑合南中",
  ["designer:mazhong"] = "Virgopaladin",
  ["illustrator:mazhong"] = "Thinking",
  ["fuman"] = "抚蛮",
  [":fuman"] = "出牌阶段，你可以将一张【杀】交给一名本回合未获得过“抚蛮”牌的其他角色，然后其于下个回合结束之前使用“抚蛮”牌时，你摸一张牌。",
  ["#fuman_record"] = "抚蛮",

  ["$fuman1"] = "恩威并施，蛮夷可为我所用！",
  ["$fuman2"] = "发兵器啦！",
  ["~mazhong"] = "丞相不在，你们竟然……",
}

local ol__mazhong = General(extension, "ol__mazhong", "shu", 4)
local ol__fuman = fk.CreateActiveSkill{
  name = "ol__fuman",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("ol__fuman-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "ol__fuman-phase", 1)
    room:moveCards({
      from = player.id,
      ids = effect.cards,
      to = target.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      skillName = self.name,
    })
  end,
}
local ol__fuman_trigger = fk.CreateTriggerSkill{
  name = "#ol__fuman_trigger",
  main_skill = ol__fuman,
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self, true) and data.card.trueName == "slash" then
      local subcards = data.card:isVirtual() and data.card.subcards or {data.card.id}
      return #subcards == 1 and Fk:getCardById(subcards[1]):getMark("@@ol__fuman") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("ol__fuman")
    player.room:notifySkillInvoked(player, "ol__fuman", "drawcard")
    local num = (data.damageDealt) and 2 or 1
    player:drawCards(num, "ol__fuman")
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.skillName == "ol__fuman" and move.moveReason == fk.ReasonGive and move.to == player.id then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            room:setCardMark(Fk:getCardById(info.cardId), "@@ol__fuman", 1)
            Fk:filterCard(info.cardId, player)
          end
        end
      end
      if move.toArea ~= Card.Processing and move.skillName ~= "ol__fuman" then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@ol__fuman") > 0 then
            room:setCardMark(Fk:getCardById(info.cardId), "@@ol__fuman", 0)
          end
        end
      end
    end
  end,
}
local ol__fuman_filter = fk.CreateFilterSkill{
  name = "#ol__fuman_filter",
  card_filter = function(self, card, player)
    return card:getMark("@@ol__fuman") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
ol__fuman:addRelatedSkill(ol__fuman_filter)
ol__fuman:addRelatedSkill(ol__fuman_trigger)
ol__mazhong:addSkill(ol__fuman)
Fk:loadTranslationTable{
  ["ol__mazhong"] = "马忠",
  ["#ol__mazhong"] = "笑合南中",
  ["ol__fuman"] = "抚蛮",
  [":ol__fuman"] = "出牌阶段每名角色限一次，你可以将一张手牌交给一名其他角色，此牌视为【杀】直到离开其手牌区。当其使用此【杀】结算后，你摸一张牌；若此【杀】造成过伤害，你改为摸两张牌。",
  ["@@ol__fuman"] = "抚蛮",
  ["#ol__fuman_filter"] = "抚蛮",

  ["$ol__fuman1"] = "国家兴亡，匹夫有责。",
  ["$ol__fuman2"] = "跟着我们丞相走，错不了！",
  ["~ol__mazhong"] = "南中不定，后患无穷……",
}

local heqi = General(extension, "heqi", "wu", 4)
local function QizhouChange(player, num, skill_name)
  local room = player.room
  local skills = player.tag["qizhou"]
  if type(skills) ~= "table" then skills = {} end
  local suits = {}
  for _, e in ipairs(player.player_cards[Player.Equip]) do
    table.insertIfNeed(suits, Fk:getCardById(e).suit)
  end
  if #suits >= num then
    if not table.contains(skills, skill_name) then
      room:handleAddLoseSkills(player, skill_name, "qizhou")
      table.insert(skills, skill_name)
    end
  else
    if table.contains(skills, skill_name) then
      room:handleAddLoseSkills(player, "-"..skill_name, "qizhou")
      table.removeOne(skills, skill_name)
    end
  end
  player.tag["qizhou"] = skills
end
local qizhou = fk.CreateTriggerSkill{
  name = "qizhou",
  frequency = Skill.Compulsory,
  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerEquip then
          return true
        end
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    QizhouChange(player, 1, "ol__duanbing")
    QizhouChange(player, 2, "ex__yingzi")
    QizhouChange(player, 3, "fenwei")
    QizhouChange(player, 4, "lanjiang")
  end,
}
Fk:addPoxiMethod{
  name = "shanxi_show",
  card_filter = function(to_select, selected, data)
    return #selected < #Self:getAvailableEquipSlots()
  end,
  feasible = function(selected)
    return #selected > 0
  end,
}
local shanxi = fk.CreateActiveSkill{
  name = "shanxi",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function ()
    return "#shanxi-choose:::"..#Self:getAvailableEquipSlots()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and #player:getAvailableEquipSlots() > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and not target:inMyAttackRange(Self) and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local card_data = {}
    local to_hands = {}
    for i = 1, to:getHandcardNum() do
      table.insert(to_hands, -1)
    end
    if #to_hands > 0 then
      table.insert(card_data, { to.general, to_hands })
    end
    if not player:isKongcheng() then
      table.insert(card_data, { player.general, player.player_cards[Player.Hand] })
    end
    if #card_data == 0 then return end
    local cards = room:askForPoxi(player, "shanxi_show", card_data, nil, true)
    if #cards == 0 then return end
    local from_cards = table.filter(cards, function(id) return id ~= -1 end)
    local to_cards = (#from_cards == #cards) and {} or table.random(to:getCardIds("h"), #cards-#from_cards)
    player:showCards(from_cards)
    to:showCards(to_cards)
    cards = table.connect(from_cards, to_cards)
    local to_throw = table.filter(cards, function (id)
      return Fk:getCardById(id).name == "jink"
    end)
    if #to_throw > 0 then
      local moveInfos = {}
      local to_throw1 = table.filter(to_throw, function(id) return table.contains(from_cards, id)
      and not player:prohibitDiscard(Fk:getCardById(id)) end)
      if #to_throw1 > 0 then
        table.insert(moveInfos, {
          from = player.id,
          ids = to_throw1,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = player.id,
          skillName = self.name,
        })
      end
      local to_throw2 = table.filter(to_throw, function(id) return table.contains(to_cards, id) end)
      if #to_throw2 > 0 then
        table.insert(moveInfos, {
          from = to.id,
          ids = to_throw2,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = player.id,
          skillName = self.name,
        })
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
      if player.dead or to.dead then return end
      card_data = {}
      if #to:getCardIds("e") > 0 then
        table.insert(card_data, { "$Equip", to:getCardIds("e") })
      end
      local nonshow = table.filter(to:getCardIds("h"), function(id) return not table.contains(to_cards, id) end)
      if #nonshow > 0 then
        to_hands = {}
        for i = 1, #nonshow do
          table.insert(to_hands, -1)
        end
        table.insert(card_data, { "$Hand", to_hands })
      end
      if #card_data == 0 then return end
      local card = room:askForCardChosen(player, to, { card_data = card_data }, self.name)
      if room:getCardArea(card) ~= Card.PlayerEquip then
        card = table.random(nonshow)
      end
      room:obtainCard(player, card, false, fk.ReasonPrey)
    end
  end,
}
heqi:addSkill(qizhou)
heqi:addSkill(shanxi)
heqi:addRelatedSkill("ol__duanbing")
heqi:addRelatedSkill("ex__yingzi")
heqi:addRelatedSkill("fenwei")
heqi:addRelatedSkill("lanjiang")
Fk:loadTranslationTable{
  ["heqi"] = "贺齐",
  ["#heqi"] = "马踏群峦",
  ["designer:heqi"] = "千幻",
  ["illustrator:heqi"] = "DH",
  ["qizhou"] = "绮胄",
  [":qizhou"] = "锁定技，你根据装备区里牌的花色数获得以下技能：1种以上-〖短兵〗；2种以上-〖英姿〗；3种以上-〖奋威〗；4种-〖澜疆〗。",
  ["shanxi"] = "闪袭",
  [":shanxi"] = "出牌阶段限一次，你可以展示你与一名攻击范围内不包含你的角色共计至多X张手牌（X为你的空置装备栏数），若其中有【闪】，弃置之，然后获得其一张未以此法展示的牌。",
  ["#shanxi-choose"] = "闪袭：展示你与一名攻击范围内不包含你的角色共计至多 %arg 张手牌",
  ["shanxi_show"] = "闪袭",

  ["$ex__yingzi_heqi"] = "人靠衣装马靠鞍！",
  ["$ol__duanbing_heqi"] = "可真是一把好刀啊！",
  ["$fenwei_heqi"] = "我的船队，要让全建业城的人都看见！",
  ["$lanjiang_heqi"] = "大江惊澜，浪涌四极之疆！",
  ["$shanxi1"] = "敌援未到，需要速战速决！",
  ["$shanxi2"] = "快马加鞭，赶在敌人戒备之前！",
  ["~heqi"] = "别拿走……我的装备！",
}

local kanze = General(extension, "kanze", "wu", 3)
local xiashu = fk.CreateTriggerSkill{
  name = "xiashu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
    1, 1, "#xiashu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:moveCardTo(player:getCardIds(Player.Hand), Player.Hand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead or to.dead or to:isKongcheng() then return false end
    local cards = room:askForCard(to, 1, to:getHandcardNum(), false, self.name, false, ".", "#xiashu-card:"..player.id)
    to:showCards(cards)
    local choices = {"xiashu_show"}
    local x = to:getHandcardNum() - #cards
    if x > 0 then
      table.insert(choices, "xiashu_noshow:::" .. tostring(x))
    end
    local choice = U.askforViewCardsAndChoice(player, cards, choices, self.name, "#xiashu-choice::"..to.id)
    if choice ~= "xiashu_show" then
      cards = table.filter(to.player_cards[Player.Hand], function (id)
        return not table.contains(cards, id)
      end)
    end
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, choice == "xiashu_show", player.id)
  end,
}
local kuanshi = fk.CreateTriggerSkill{
  name = "kuanshi",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper),
    1, 1, "#kuanshi-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, self.cost_data)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}

local kuanshi_delay = fk.CreateTriggerSkill{
  name = "#kuanshi_delay",
  mute = true,
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  --FIXME:跳过摸牌阶段的时机应该是TurnStart的
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      return data.damage > 1 and target and not target.dead and not player.dead and player:getMark("kuanshi") == target.id
    elseif event == fk.EventPhaseStart then
      return not player.dead and player == target and player.phase == Player.Start and player:getMark("@@kuanshi") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      room:notifySkillInvoked(player, kuanshi.name, "defensive")
      player:broadcastSkillInvoke(kuanshi.name)
      room:setPlayerMark(player, "kuanshi", 0)
      room:setPlayerMark(player, "@@kuanshi", 1)
      return true
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, kuanshi.name, "negative")
      player:broadcastSkillInvoke(kuanshi.name)
      room:setPlayerMark(player, "@@kuanshi", 0)
      player:skip(Player.Draw)
    end
  end,
}
kuanshi:addRelatedSkill(kuanshi_delay)
kanze:addSkill(xiashu)
kanze:addSkill(kuanshi)
Fk:loadTranslationTable{
  ["kanze"] = "阚泽",
  ["#kanze"] = "慧眼的博士",
  ["illustrator:kanze"] = "LiuHeng",
  ["xiashu"] = "下书",
  [":xiashu"] = "出牌阶段开始时，你可以将所有手牌交给一名其他角色，然后该角色亮出任意数量的手牌（至少一张），令你选择一项："..
  "1.获得其亮出的手牌；2.获得其未亮出的手牌。",
  ["kuanshi"] = "宽释",
  [":kuanshi"] = "结束阶段，你可以选择一名角色。直到你的下回合开始，该角色下一次受到超过1点的伤害时，防止此伤害，然后你跳过下个回合的摸牌阶段。",
  ["#xiashu-choose"] = "下书：将所有手牌交给一名角色，其展示任意张手牌，你获得展示或未展示的牌",
  ["#xiashu-card"] = "下书：展示任意张手牌，%src 选择获得你展示的牌或未展示的牌",
  ["xiashu_show"] = "获得展示的牌",
  ["xiashu_noshow"] = "获得未展示的牌[%arg张]",
  ["#xiashu-choice"] = "下书：选择获得 %dest 的牌",
  ["#kuanshi-choose"] = "宽释：你可以选择一名角色，直到你下回合开始，防止其下次受到超过1点的伤害",
  ["#kuanshi_delay"] = "宽释",
  ["@@kuanshi"] = "宽释",

  ["$xiashu1"] = "吾有密信，特来献于将军。",
  ["$xiashu2"] = "将军若不信，可亲自验看！",
  ["$kuanshi1"] = "不知者，无罪。",
  ["$kuanshi2"] = "罚酒三杯，下不为例。",
  ["~kanze"] = "我早已做好了牺牲的准备。",
}

local liuqi = General(extension, "liuqi", "qun", 3)
liuqi.subkingdom = "shu"
local wenji = fk.CreateTriggerSkill{
  name = "wenji",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      not table.every(player.room:getOtherPlayers(player), function(p) return (p:isNude()) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper), 1, 1, "#wenji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#wenji-give::"..player.id)
    room:setPlayerMark(player, "wenji-turn", Fk:getCardById(card[1]).trueName)
    room:obtainCard(player.id, card[1], false, fk.ReasonGive)
  end,
}
local wenji_record = fk.CreateTriggerSkill{
  name = "#wenji_record",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("wenji", Player.HistoryTurn) > 0 and player:getMark("wenji-turn") ~= 0 and
      player:getMark("wenji-turn") == data.card.trueName
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
local tunjiang = fk.CreateTriggerSkill{
  name = "tunjiang",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      player:getMark("tunjiang-turn") == 0 and not player.skipped_phases[Player.Play]
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms, self.name)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:getMark("tunjiang-turn") == 0 and
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
  ["#liuqi"] = "居外而安",
  ["cv:liuqi"] = "戴超行",
  ["illustrator:liuqi"] = "NOVART",
  ["wenji"] = "问计",
  [":wenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌，你于本回合内使用与该牌同名的牌不能被其他角色响应。",
  ["tunjiang"] = "屯江",
  [":tunjiang"] = "结束阶段，若你未跳过本回合的出牌阶段，且你于本回合出牌阶段内未使用牌指定过其他角色为目标，则你可以摸X张牌（X为全场势力数）。",
  ["#wenji-choose"] = "问计：你可以令一名其他角色交给你一张牌",
  ["#wenji-give"] = "问计：你需交给 %dest 一张牌",

  ["$wenji1"] = "言出子口，入于吾耳，可以言未？",
  ["$wenji2"] = "还望先生救我！",
  ["$tunjiang1"] = "皇叔勿惊，吾与关将军已到。",
  ["$tunjiang2"] = "江夏冲要之地，孩儿愿往守之。",
  ["~liuqi"] = "父亲，孩儿来见你了。",
}

local tangzi = General(extension, "tangzi", "wei", 4)
tangzi.subkingdom = "wu"
local xingzhao = fk.CreateTriggerSkill{
  name = "xingzhao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.HpChanged, fk.MaxHpChanged, fk.CardUsing, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.HpChanged or event == fk.MaxHpChanged then
        return (player:hasSkill("xunxun", true) and not table.find(player.room.alive_players, function(p) return p:isWounded() end)) or
          (not player:hasSkill("xunxun", true) and table.find(player.room.alive_players, function(p) return p:isWounded() end))
      elseif event == fk.CardUsing then
        return target == player and data.card.type == Card.TypeEquip and
          #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > 1
      else
        return target == player and data.to == Player.Discard and
          #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > 2
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.HpChanged or event == fk.MaxHpChanged then
      if player:hasSkill("xunxun", true) then
        player.room:handleAddLoseSkills(player, "-xunxun", self.name, true, false)
      else
        player.room:handleAddLoseSkills(player, "xunxun", self.name, true, false)
      end
    elseif event == fk.CardUsing then
      player:drawCards(1, self.name)
    else
      return true
    end
  end,
}
tangzi:addSkill(xingzhao)
Fk:loadTranslationTable{
  ["tangzi"] = "唐咨",
  ["#tangzi"] = "工学之奇才",
  ["designer:tangzi"] = "荼蘼",
  ["illustrator:tangzi"] = "NOVART",
  ["xingzhao"] = "兴棹",
  [":xingzhao"] = "锁定技，场上受伤的角色为：1个或以上，你拥有技能〖恂恂〗；2个或以上，你使用装备牌时摸一张牌；3个或以上，你跳过弃牌阶段。",

  ["$xingzhao1"] = "精挑细选，方能成百年之计。",
  ["$xingzhao2"] = "拿些上好的木料来。",
  ["$xunxun_tangzi1"] = "让我先探他一探。",
  ["$xunxun_tangzi2"] = "船，也不是一天就能造出来的。",
  ["~tangzi"] = "偷工减料要不得啊……",
}

local wangyun = General(extension, "wangyun", "qun", 4)
local lianji = fk.CreateActiveSkill{
  name = "lianji",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and
      not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if target.dead then return end
    local cards = table.filter(room.draw_pile, function(id) return Fk:getCardById(id).sub_type == Card.SubtypeWeapon end)
    if #cards > 0 then
      local card = Fk:getCardById(table.random(cards))
      if card.name == "qinggang_sword" then
        room:moveCardTo(card, Card.Void, nil, fk.ReasonJustMove, self.name)
        card = room:printCard("seven_stars_sword", Card.Spade, 6)
      end
      if U.canUseCardTo(room, target, target, card) then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = card,
        })
      end
    end
    if target.dead or player.dead then return end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local victim = room:askForChoosePlayers(player, targets, 1, 1, "#lianji-choose::"..target.id, self.name, false)[1]
      room:doIndicate(target.id, {victim})
      local use = room:askForUseCard(target, "slash", "slash", "#lianji-slash:"..player.id..":"..victim, true,
      {exclusive_targets = {victim}, bypass_times = true})
      if use then
        room:useCard(use)
        if use.damageDealt then
          room:addPlayerMark(player, "moucheng", 1)
        end
        return false
      end
    end
    if target:getEquipment(Card.SubtypeWeapon) then
      local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#lianji-card::"..target.id, self.name, false)[1]
      room:moveCards({
        from = target.id,
        ids = target:getEquipments(Card.SubtypeWeapon),
        to = to,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local moucheng = fk.CreateTriggerSkill{
  name = "moucheng",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark(self.name) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-lianji|jingong", nil, true, false)
  end,
}
local jingong = fk.CreateViewAsSkill{
  name = "jingong",
  anim_type = "control",
  prompt = "#jingong",
  interaction = function()
    local names = Self:getMark("jingong-phase")
    if names == 0 then
      names = {"dismantlement", "ex_nihilo", "daggar_in_smile"}  --很难想象什么时候会用到这个默认值
    end
    return UI.ComboBox {choices = names}
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.trueName == "slash" or card.type == Card.TypeEquip)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local jingong_record = fk.CreateTriggerSkill{
  name = "#jingong_record",

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and
        not table.contains({"nullification", "adaptation"}, card.name) then
        table.insertIfNeed(names, card.name)
      end
    end
    local cards = table.random(names, 2)
    names = {cards[1], cards[2], table.random({"honey_trap", "daggar_in_smile"})}
    player.room:setPlayerMark(player, "jingong-phase", names)
  end,
}
jingong:addRelatedSkill(jingong_record)
wangyun:addSkill(lianji)
wangyun:addSkill(moucheng)
wangyun:addRelatedSkill(jingong)
Fk:loadTranslationTable{
  ["wangyun"] = "王允",
  ["#wangyun"] = "忠魂不泯",
  ["illustrator:wangyun"] = "Thinking",
  ["lianji"] = "连计",
  [":lianji"] = "出牌阶段限一次，你可以弃置一张手牌并指定一名其他角色，其使用牌堆中的一张随机武器牌，然后令其选择一项：1.对其攻击范围内你指定的一名角色"..
  "使用【杀】；2.你将其装备区的武器牌交给任意一名角色。",
  ["moucheng"] = "谋逞",
  [":moucheng"] = "觉醒技，准备阶段，若你发动〖连计〗令目标角色使用【杀】造成过伤害，则你失去〖连计〗，获得〖矜功〗。",
  ["jingong"] = "矜功",
  [":jingong"] = "出牌阶段限一次，你可以将一张装备牌或【杀】当一张锦囊牌使用（从两种随机普通锦囊牌和【美人计】、【笑里藏刀】随机一种中三选一）。",
  ["#lianji-choose"] = "连计：选择令 %dest 使用【杀】的目标",
  ["#lianji-slash"] = "连计：你需对 %dest 使用【杀】，否则 %src 将你的武器牌交给任意角色",
  ["#lianji-card"] = "连计：将 %dest 的武器交给一名角色",
  ["#jingong"] = "矜功：你可以将一张装备牌或【杀】当一张锦囊使用（从两种随机普通锦囊和一种随机专属锦囊中三选一）",

  ["$lianji1"] = "两计扣用，以催强势。",
  ["$lianji2"] = "容老夫细细思量。",
  ["$moucheng1"] = "董贼伏诛，天下太平！",
  ["$moucheng2"] = "叫天不应，叫地不灵，今天就是你的死期！",
  ["$jingong1"] = "董贼旧部，可尽诛之！",
  ["$jingong2"] = "若无老夫之谋，尔等皆化为腐土也。",
  ["~wangyun"] = "努力谢关东诸公，勤以国家为念！",
}

local quyi = General(extension, "quyi", "qun", 4)
local fuji = fk.CreateTriggerSkill{
  name = "fuji",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end)
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
    return target == player and player:hasSkill(self) and
      table.every(player.room:getOtherPlayers(player), function(p)
        return player:getHandcardNum() > p:getHandcardNum() end)
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
quyi:addSkill(fuji)
quyi:addSkill(jiaozi)
Fk:loadTranslationTable{
  ["quyi"] = "麴义",
  ["#quyi"] = "名门的骁将",
  ["cv:quyi"] = "冷泉月夜",
  ["illustrator:quyi"] = "王立雄", -- 稀有皮 界桥先登
  ["designer:quyi"] = "荼蘼",

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
local updataXianfu = function (room, player, target)
  local mark = player:getTableMark("xianfu")
  table.insertIfNeed(mark[2], target.id)
  room:setPlayerMark(player, "xianfu", mark)
  local names = table.map(mark[2], function(pid) return Fk:translate(room:getPlayerById(pid).general) end)
  room:setPlayerMark(player, "@xianfu", table.concat(names, ","))
end
local xianfu = fk.CreateTriggerSkill{
  name = "xianfu",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, math.random(2))
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#xianfu-choose", self.name, false, true)
    local mark = player:getTableMark(self.name)
    if #mark == 0 then mark = {{},{}} end
    table.insertIfNeed(mark[1], tos[1])
    room:setPlayerMark(player, self.name, mark)
  end,
}
local xianfu_delay = fk.CreateTriggerSkill{
  name = "#xianfu_delay",
  events = {fk.Damaged, fk.HpRecover},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getTableMark("xianfu")
    if not player.dead and not target.dead and #mark > 0 and table.contains(mark[1], target.id) then
      return event == fk.Damaged or player:isWounded()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    updataXianfu (room, player, target)
    room:sendLog{ type = "#SkillDelayInvoked", from = player.id, arg = "xianfu", }
    if event == fk.Damaged then
      player:broadcastSkillInvoke("xianfu", math.random(2)+2)
      room:damage{
        to = player,
        damage = data.damage,
        skillName = "xianfu",
      }
    else
      player:broadcastSkillInvoke("xianfu", math.random(2)+4)
      if player:isWounded() then
        room:recover{
          who = player,
          num = data.num,
          recoverBy = player,
          skillName = "xianfu",
        }
      end
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
      if i > 1 and (self.cancel_cost or not player:hasSkill(self)) then break end
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
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if player.dead then return false end
    if judge.card.color == Card.Red then
      local targets = table.map(room.alive_players, Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#chouce-draw", self.name, false)
      local to = room:getPlayerById(tos[1])
      local num = 1
      local mark = player:getTableMark("xianfu")
      if #mark > 0 and table.contains(mark[1], to.id) then
        num = 2
        updataXianfu (room, player, to)
      end
      to:drawCards(num, self.name)
    elseif judge.card.color == Card.Black then
      local targets = table.map(table.filter(room.alive_players, function(p) return not p:isAllNude() end), Util.IdMapper)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#chouce-discard", self.name, false)
      local to = room:getPlayerById(tos[1])
      local card = room:askForCardChosen(player, to, "hej", self.name)
      room:throwCard({card}, self.name, to, player)
    end
  end,
}
xianfu:addRelatedSkill(xianfu_delay)
xizhicai:addSkill("tiandu")
xizhicai:addSkill(xianfu)
xizhicai:addSkill(chouce)
Fk:loadTranslationTable{
  ["xizhicai"] = "戏志才",
  ["#xizhicai"] = "负俗的夭才",
  ["cv:xizhicai"] = "曹真",
  ["designer:xizhicai"] = "荼蘼",
  ["illustrator:xizhicai"] = "眉毛子",
  ["xianfu"] = "先辅",
  ["@xianfu"] = "先辅",
  [":xianfu"] = "锁定技，游戏开始时，你选择一名其他角色，当其受到伤害后，你受到等量的伤害；当其回复体力后，你回复等量的体力。",
  ["chouce"] = "筹策",
  [":chouce"] = "当你受到1点伤害后，你可以进行判定，若结果为：黑色，你弃置一名角色区域里的一张牌；红色，你令一名角色摸一张牌（先辅的角色摸两张）。",
  ["#xianfu-choose"] = "先辅: 请选择要先辅的角色",
  ["#chouce-draw"] = "筹策: 令一名角色摸一张牌（若为先辅角色则摸两张）",
  ["#chouce-discard"] = "筹策: 弃置一名角色区域里的一张牌",
  ["#xianfu_delay"] = "先辅",
  ["#SkillDelayInvoked"] = "%from 的“%arg”的延迟效果被触发",

  ["$tiandu_xizhicai1"] = "天意，不可逆。",
  ["$tiandu_xizhicai2"] = "既是如此。",
  ["$xianfu1"] = "辅佐明君，从一而终。",
  ["$xianfu2"] = "吾于此生，竭尽所能。",
  ["$xianfu3"] = "春蚕至死，蜡炬成灰！",
  ["$xianfu4"] = "愿为主公，尽我所能。",
  ["$xianfu5"] = "赠人玫瑰，手有余香。",
  ["$xianfu6"] = "主公之幸，我之幸也。",
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
    return target == player and player:hasSkill(self) and data.card.type == Card.TypeTrick and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local tos, cards = player.room:askForChooseCardsAndPlayers(player, 1, player:getHandcardNum(), table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, ".", "#qianya-invoke", self.name, true)
    if #tos > 0 and #cards > 0 then
      self.cost_data = {tos[1], cards}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(self.cost_data[2], Card.PlayerHand, player.room:getPlayerById(self.cost_data[1]), fk.ReasonGive, self.name, "", true, player.id)
  end,
}
local shuimeng = fk.CreateTriggerSkill{
  name = "shuimeng",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:canPindian(p) end), Util.IdMapper),
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
sunqian:addSkill(qianya)
sunqian:addSkill(shuimeng)
Fk:loadTranslationTable{
  ["sunqian"] = "孙乾",
  ["#sunqian"] = "折冲樽俎",
  ["illustrator:sunqian"] = "Thinking",
  ["qianya"] = "谦雅",
  [":qianya"] = "当你成为锦囊牌的目标后，你可以将任意张手牌交给一名其他角色。",
  ["shuimeng"] = "说盟",
  [":shuimeng"] = "出牌阶段结束时，你可以与一名角色拼点，若你赢，视为你使用【无中生有】；若你没赢，视为其对你使用【过河拆桥】。",
  ["#qianya-invoke"] = "谦雅：你可以将任意张手牌交给一名其他角色",
  ["#shuimeng-choose"] = "说盟：你可以拼点，若赢，视为你使用【无中生有】；若没赢，视为其对你使用【过河拆桥】",

  ["$qianya1"] = "君子不妄动，动必有道。",
  ["$qianya2"] = "哎！将军过誉了！",
  ["$shuimeng1"] = "你我唇齿相依，共御外敌，何如？  ",
  ["$shuimeng2"] = "今兵薄势寡，可遣某为使往说之。",
  ["~sunqian"] = "恨不能……得见皇叔早登大宝，咳咳咳……",
}

local shenpei = General(extension, "ol__shenpei", "qun", 3)
local gangzhi = fk.CreateTriggerSkill{
  name = "gangzhi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreDamage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and ((target == player and data.to ~= player) or (data.from and data.from ~= player and data.to == player))
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, data.damage, self.name)
    return true
  end,
}
local beizhan = fk.CreateTriggerSkill{
  name = "beizhan",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 1, "#beizhan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = player.room:getPlayerById(self.cost_data)
    local n = math.min(to.maxHp, 5) - #to.player_cards[Player.Hand]
    if n > 0 then
      to:drawCards(n, self.name)
    end
    player.room:addPlayerMark(to, self.name, 1)
  end,
}
local beizhan_delay = fk.CreateTriggerSkill{
  name = "#beizhan_delay",
  anim_type = "negative",
  events = {fk.TurnStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("beizhan") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "beizhan", 0)
    if table.every(room.alive_players, function(p) return player:getHandcardNum() >= p:getHandcardNum() end) then
      room:addPlayerMark(target, "@@beizhan-turn", 1)
    end
  end,
}
local beizhan_prohibit = fk.CreateProhibitSkill{
  name = "#beizhan_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@beizhan-turn") > 0 and from ~= to
  end,
}
beizhan:addRelatedSkill(beizhan_delay)
beizhan:addRelatedSkill(beizhan_prohibit)
shenpei:addSkill(gangzhi)
shenpei:addSkill(beizhan)
Fk:loadTranslationTable{
  ["ol__shenpei"] = "审配",
  ["#ol__shenpei"] = "正南义北",
  ["illustrator:ol__shenpei"] = "PCC",
  ["gangzhi"] = "刚直",
  [":gangzhi"] = "锁定技，其他角色对你造成的伤害，和你对其他角色造成的伤害均视为体力流失。",
  ["beizhan"] = "备战",
  [":beizhan"] = "回合结束后，你可以指定一名角色：若其手牌数少于X，其将手牌补至X（X为其体力上限且最多为5）；"..
  "该角色回合开始时，若其手牌数为全场最多，则其本回合内不能使用牌指定其他角色为目标。",
  ["#beizhan-choose"] = "备战：指定一名角色，若手牌少于X则补至X张（X为其体力上限且最多为5）；<br>"..
  "若其回合开始时手牌数为最多，则使用牌不能指定其他角色为目标",
  ["#beizhan_delay"] = "备战",
  ["@@beizhan-turn"] = "备战",

  ["$gangzhi1"] = "只恨箭支太少，不能射杀汝等！",
  ["$gangzhi2"] = "死便死，降？断不能降！",
  ["$beizhan1"] = "十，则围之；五，则攻之！",
  ["$beizhan2"] = "今伐曹氏，譬如覆手之举。",
  ["~ol__shenpei"] = "吾君在北，但求面北而亡。",
}

local xunchen = General(extension, "ol__xunchen", "qun", 3)
local fenglue = fk.CreateTriggerSkill{
  name = "fenglue",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.PindianResultConfirmed},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    local room = player.room
    if event == fk.EventPhaseStart then
      return target == player and player.phase == Player.Play and not player:isKongcheng() and table.find(room:getOtherPlayers(player), function(p)
        return not p:isKongcheng() end)
    else
      if data.from == player then
        return #room:getSubcardsByRule(data.fromCard, { Card.Processing }) > 0
      elseif data.to == player then
        return #room:getSubcardsByRule(data.toCard, { Card.Processing }) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
        return player:canPindian(p) end), Util.IdMapper),
        1, 1, "#fenglue-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      self.cost_data = data.from == player
        and {data.to, room:getSubcardsByRule(data.fromCard, { Card.Processing })}
        or {data.from, room:getSubcardsByRule(data.toCard, { Card.Processing })}
      return room:askForSkillInvoke(player, self.name, data, "#fenglue-give::"..self.cost_data[1].id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local to = room:getPlayerById(self.cost_data)
      local pindian = player:pindian({to}, self.name)
      if player.dead or to.dead then return end
      if pindian.results[to.id].winner == player then
        if to:isAllNude() then return end
        local cards = U.askforCardsChosenFromAreas(to, to, "hej", self.name, nil, nil, false)
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, to.id)
      else
        if player:isNude() then return end
        local id = room:askForCardChosen(player, player, "he", self.name)
        room:moveCardTo(id, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
      end
    else
      room:obtainCard(self.cost_data[1], self.cost_data[2], true, fk.ReasonGive)
    end
  end,
}
local moushi = fk.CreateActiveSkill{
  name = "moushi",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#moushi",
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
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if not player.dead and not target.dead then
      local mark = target:getTableMark("moushi_record")
      table.insertIfNeed(mark, player.id)
      room:setPlayerMark(target, "moushi_record", mark)
    end
  end,
}
local moushi_delay = fk.CreateTriggerSkill{
  name = "#moushi_delay",
  mute = true,
  events = {fk.Damage},
  can_trigger = function (self, event, target, player, data)
    return target and player:getMark("moushi_record-phase") == target.id and
      #player.room.logic:getActualDamageEvents(2, function(e)
        local damage = e.data[1]
        return damage.from == target and damage.to == data.to
      end, Player.HistoryPhase) == 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:broadcastSkillInvoke("moushi")
    player.room:notifySkillInvoked(player, "moushi", "drawcard")
    player:drawCards(1, "moushi")
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("moushi_record") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getMark("moushi_record")) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:setPlayerMark(p, "moushi_record-phase", player.id)
      end
    end
    room:setPlayerMark(player, "moushi_record", 0)
  end,
}
moushi:addRelatedSkill(moushi_delay)
xunchen:addSkill(fenglue)
xunchen:addSkill(moushi)
Fk:loadTranslationTable{
  ["ol__xunchen"] = "荀谌",
  ["#ol__xunchen"] = "单锋谋孤城",
  ["fenglue"] = "锋略",
  [":fenglue"] = "出牌阶段开始时，你可以与一名角色拼点：若你赢，该角色将每个区域内各一张牌交给你；若你没赢，你交给其一张牌。"..
  "你与其他角色的拼点结果确定后，你可以将你的拼点牌交给该角色。",
  ["moushi"] = "谋识",
  [":moushi"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色。若如此做，当该角色于其下个出牌阶段对每名角色第一次造成伤害后，你摸一张牌。",
  ["#fenglue-choose"] = "锋略：你可以拼点，若赢，其交给你每个区域各一张牌；没赢，你交给其一张牌",
  ["#fenglue-give"] = "锋略：你可以将你的拼点牌交给%dest",
  ["#moushi"] = "谋识：将一张手牌交给一名角色，其下个出牌阶段对每名角色第一次造成伤害后，你摸一张牌",
  ["#moushi_delay"] = "谋识",

  ["$fenglue1"] = "汝能比得上我家主公吗？",
  ["$fenglue2"] = "将军有让贤之名而身安于泰山也，实乃上策。",
  ["$moushi1"] = "官渡决战，袁公必胜而曹氏必败。",
  ["$moushi2"] = "吾既辅佐袁公，定不会使其覆巢。",
  ["~ol__xunchen"] = "吾欲赴死，断不做背主之事……",
}

local sufei = General(extension, "ol__sufei", "wu", 4)
sufei.subkingdom = "qun"
local lianpian = fk.CreateTriggerSkill{
  name = "lianpian",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 3 then
      local room = player.room
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
      if phase_event == nil then return end
      local end_id = phase_event.id
      local tos
      if #room.logic:getEventsByRule(GameEvent.UseCard, 2, function (e)
        local use = e.data[1]
        if use.from == player.id then
          tos = use.tos
          return true
        end
        return false
      end, end_id) < 2 then return end
      if not tos then return end
      local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
        return table.contains(TargetGroup:getRealTargets(tos), id)
      end)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(1, self.name)
    if table.contains(player:getCardIds("h"), cards[1]) then
      local targets = table.filter(self.cost_data, function (id)
        return not room:getPlayerById(id).dead and id ~= player.id
      end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1,
        "#lianpian-choose:::"..Fk:getCardById(cards[1]):toLogString(), self.name, true)
      if #to > 0 then
        room:moveCardTo(cards, Card.PlayerHand, room:getPlayerById(to[1]), fk.ReasonGive, self.name, nil, false, player.id)
      end
    end
  end,
}
sufei:addSkill(lianpian)
Fk:loadTranslationTable{
  ["ol__sufei"] = "苏飞",
  ["#ol__sufei"] = "与子同袍",
  ["illustrator:ol__sufei"] = "兴游",
  ["lianpian"] = "联翩",
  [":lianpian"] = "每回合限三次，当你于出牌阶段内使用牌指定目标后，若此牌与你此阶段内使用的上一张牌有共同的目标角色，你可以摸一张牌，"..
  "然后你可以摸到的牌交给这些角色中的一名。",
  ["#lianpian-choose"] = "联翩：你可以将%arg交给其中一名角色",

  ["$lianpian1"] = "需持续投入，方有回报。",
  ["$lianpian2"] = "心无旁骛，断而敢行！",
  ["~ol__sufei"] = "恐不能再与兴霸兄……并肩奋战了……",
}

local huangquan = General(extension, "ol__huangquan", "shu", 3)
huangquan.subkingdom = "wei"
local dianhu = fk.CreateTriggerSkill{
  name = "dianhu",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #player.room.alive_players > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, 1)
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#dianhu-choose", self.name, false)
    to = room:getPlayerById(to[1])
    local mark =  to:getTableMark("@@dianhu")
    table.insert(mark, player.id)
    room:setPlayerMark(to, "@@dianhu", mark)
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return not player.dead and type(player:getMark("@@dianhu")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("@@dianhu")
    table.removeOne(mark, target.id)
    player.room:setPlayerMark(player, "@@dianhu", #mark > 0 and mark or 0)
  end,
}
local dianhu_delay = fk.CreateTriggerSkill{
  name = "#dianhu_delay",
  events = {fk.Damaged, fk.HpRecover},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target and not (player.dead or target.dead) then
      local mark =  target:getTableMark("@@dianhu")
      if table.contains(mark, player.id) then
        if event == fk.Damaged then
          return data.from == player
        end
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(dianhu.name, 2)
    player:drawCards(1, dianhu.name)
  end,
}
local jianji = fk.CreateActiveSkill{
  name = "jianji",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#jianji-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local id = target:drawCards(1, self.name)[1]
    if not target.dead and table.contains(target.player_cards[Player.Hand], id) then
      U.askForUseRealCard(room, target, {id}, ".", self.name)
    end
  end,
}
dianhu:addRelatedSkill(dianhu_delay)
huangquan:addSkill(dianhu)
huangquan:addSkill(jianji)
Fk:loadTranslationTable{
  ["ol__huangquan"] = "黄权",
  ["#ol__huangquan"] = "道绝殊途",
  ["illustrator:ol__huangquan"] = "兴游",

  ["dianhu"] = "点虎",
  [":dianhu"] = "锁定技，游戏开始时，你指定一名其他角色；当你对该角色造成伤害后或该角色回复体力后，你摸一张牌。",
  ["jianji"] = "谏计",
  [":jianji"] = "出牌阶段限一次，你可以令一名其他角色摸一张牌，然后其可以使用该牌。",
  ["#dianhu_delay"] = "点虎",
  ["@@dianhu"] = "点虎",
  ["#dianhu-choose"] = "点虎：指定一名角色，本局当你对其造成伤害或其回复体力后，你摸一张牌",
  ["#jianji-invoke"] = "谏计：你可以使用这张牌",
  ["#jianji-prompt"] = "谏计：你可令一名其他角色摸一张牌，且其可以使用之",

  ["$dianhu1"] = "预则立，不预则废！",
  ["$dianhu2"] = "就用你，给我军祭旗！",
  ["$jianji1"] = "锦上添花，不如雪中送炭。",
  ["$jianji2"] = "密计交于将军，可解燃眉之困。",
  ["~ol__huangquan"] = "魏王厚待于我，降魏又有何错？",
}

local luzhi = General(extension, "luzhiw", "wei", 3)
local qingzhong = fk.CreateTriggerSkill{
  name = "qingzhong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    player.room:setPlayerMark(player, "qingzhong-phase", 1)
  end,
}
local qingzhong_delay = fk.CreateTriggerSkill{
  name = "#qingzhong_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("qingzhong-phase") > 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum()
    for _, p in ipairs(room:getOtherPlayers(player)) do
      n = math.min(n, p:getHandcardNum())
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:getHandcardNum() == n then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local cancelable = (n == player:getHandcardNum())
    local to
    if #targets == 1 and not cancelable then
      to = targets[1]
    else
      to = room:askForChoosePlayers(player, targets, 1, 1, "#qingzhong-choose", qingzhong.name, cancelable)[1]
    end
    if to then
      player:broadcastSkillInvoke(qingzhong.name)
      room:notifySkillInvoked(player, qingzhong.name, "support")
      U.swapHandCards(room, player, player, room:getPlayerById(to), qingzhong.name)
    end
  end,
}
qingzhong:addRelatedSkill(qingzhong_delay)
luzhi:addSkill(qingzhong)
local weijing = fk.CreateViewAsSkill{
  name = "weijing",
  pattern = "slash,jink",
  interaction = function()
    local names = {}
    for _, name in ipairs({"slash","jink"}) do
      local card = Fk:cloneCard(name)
      if (Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card)) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
}
luzhi:addSkill(weijing)
Fk:loadTranslationTable{
  ["luzhiw"] = "鲁芝",
  ["#luzhiw"] = "夷夏慕德",
  ["designer:luzhiw"] = "世外高v狼",
  ["illustrator:luzhiw"] = "秋呆呆",
  ["qingzhong"] = "清忠",
  [":qingzhong"] = "出牌阶段开始时，你可以摸两张牌，然后本阶段结束时，若有其他角色：和你一起并列场上手牌数最少，你可与这些角色中的一名交换手牌；比你手牌数少，你须与这些角色中手牌数最少的任意一名交换手牌。",
  ["weijing"] = "卫境",
  [":weijing"] = "每轮限一次，当你需要使用【杀】或【闪】时，你可以视为使用之。",
  ["#qingzhong-choose"] = "清忠：选择一名手牌数最少的其他角色，与其交换手牌",
  ["#weijing_record"] = "卫境",

  ["$qingzhong1"] = "执政为民，当尽我所能。",
  ["$qingzhong2"] = "吾自幼流离失所，更能体恤百姓之苦。",
  ["$weijing1"] = "战事兴起，最苦的，仍是百姓。",
  ["$weijing2"] = "国乃大家，保大家才有小家。",
  ["~luzhiw"] = "年迈力微，是该告老还乡了……",
}

local baosanniang = General(extension, "ol__baosanniang", "shu", 4, 4, General.Female)
local ol__wuniang = fk.CreateTriggerSkill{
  name = "ol__wuniang",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and player.phase == Player.Play and
      #TargetGroup:getRealTargets(data.tos) == 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ol__wuniang-invoke::"..TargetGroup:getRealTargets(data.tos)[1])
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if not to.dead then
      local use = room:askForUseCard(to, "slash", "slash", "#ol__wuniang-use:"..player.id, true,
      {exclusive_targets = {player.id}, bypass_times = true})
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    end
    if not player.dead then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase")
    end
  end,
}
local ol__xushen = fk.CreateTriggerSkill{
  name = "ol__xushen",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "ol__zhennan", nil, true, false)
    for _, p in ipairs(room:getAlivePlayers()) do
      if string.find(p.general, "guansuo") then
        return
      end
    end
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return p:isMale() end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ol__xushen-choose", self.name, true)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      if room:askForSkillInvoke(to, self.name, nil, "#ol__xushen-invoke") then
        room:changeHero(to, "guansuo", false, false, true)
      end
    end
  end,
}
local ol__zhennan = fk.CreateActiveSkill{
  name = "ol__zhennan",
  anim_type = "offensive",
  min_card_num = 1,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip then return end
    return #selected < #Fk:currentRoom().alive_players - 1
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local card = Fk:cloneCard("savage_assault")
    card:addSubcards(selected_cards)
    return to_select ~= Self.id and #selected < #selected_cards and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), card)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:useVirtualCard("savage_assault", effect.cards, player,
      table.map(effect.tos, function(id) return room:getPlayerById(id) end), self.name)
  end
}
local ol__zhennan_trigger = fk.CreateTriggerSkill{
  name = "#ol__zhennan_trigger",
  anim_type = "defensive",
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player.id == data.to and data.card.name == "savage_assault"
  end,
  on_cost = Util.TrueFunc,
  on_use = Util.TrueFunc,
}
ol__zhennan:addRelatedSkill(ol__zhennan_trigger)
baosanniang:addSkill(ol__wuniang)
baosanniang:addSkill(ol__xushen)
baosanniang:addRelatedSkill(ol__zhennan)
Fk:loadTranslationTable{
  ["ol__baosanniang"] = "鲍三娘",
  ["#ol__baosanniang"] = "平南之巾帼",
  ["illustrator:ol__baosanniang"] = "DH",

  ["ol__wuniang"] = "武娘",
  [":ol__wuniang"] = "你的出牌阶段内限一次，当你使用指定唯一目标的【杀】结算后，你可以令其选择是否对你使用一张【杀】，"..
  "然后你摸一张牌并令你本阶段使用【杀】次数上限+1。",
  ["ol__xushen"] = "许身",
  [":ol__xushen"] = "限定技，当你进入濒死状态时，你可以回复体力至1并获得〖镇南〗，然后若关索不在场，你可以令一名男性角色选择是否用关索代替其武将牌。",
  ["ol__zhennan"] = "镇南",
  [":ol__zhennan"] = "【南蛮入侵】对你无效。出牌阶段限一次，你可以将至多X张手牌当目标数为X的【南蛮入侵】使用（X为其他角色数）。",
  ["#ol__wuniang-invoke"] = "武娘：你可以令 %dest 对你使用一张【杀】，你摸一张牌并使用【杀】次数上限+1",
  ["#ol__wuniang-use"] = "武娘：你可以对 %src 使用一张【杀】",
  ["#ol__xushen-choose"] = "许身：你可以令一名男性角色选择是否变身为关索！",
  ["#ol__xushen-invoke"]= "许身：你可以变身为关索！",
  ["#ol__zhennan_trigger"] = "镇南",

  ["$ol__wuniang1"] = "虽为女子身，不输男儿郎。",
  ["$ol__wuniang2"] = "剑舞轻盈，沙场克敌。",
  ["$ol__xushen1"] = "救命之恩，涌泉相报。",
  ["$ol__xushen2"] = "解我危难，报君华彩。",
  ["$ol__zhennan1"] = "镇守南中，夫君无忧。",
  ["$ol__zhennan2"] = "与君携手，定平蛮夷。",
  ["~ol__baosanniang"] = "我还想与你，共骑这雪花驹……",
}

local caoying = General(extension, "caoying", "wei", 4, 4, General.Female)
local lingren = fk.CreateTriggerSkill{
  name = "lingren",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name) == 0 and
    data.firstTarget and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
      return not room:getPlayerById(id).dead
    end)
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#lingren-invoke::" .. targets[1]) then
        self.cost_data = {tos = targets}
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#lingren-choose", self.name, true, false)
      if #targets > 0 then
        self.cost_data = {tos = targets}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local choices = {"lingren_basic", "lingren_trick", "lingren_equip"}
    local yes = room:askForChoices(player, choices, 0, 3, self.name, "#lingren-choice::" .. to.id, false)
    for _, value in ipairs(yes) do
      table.removeOne(choices, value)
    end
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
    room:sendLog{
      type = "#lingren_result",
      from = player.id,
      arg = tostring(right),
    }
    if right > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.lingren = data.extra_data.lingren or {}
      table.insert(data.extra_data.lingren, to.id)
    end
    if right > 1 then
      player:drawCards(2, self.name)
    end
    if right > 2 then
      local skills = {}
      if not player:hasSkill("ex__jianxiong", true) then
        table.insert(skills, "ex__jianxiong")
      end
      if not player:hasSkill("xingshang", true) then
        table.insert(skills, "xingshang")
      end
      if #skills > 0 then
        room:setPlayerMark(player, self.name, skills)
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end
    end
  end,
}
local lingren_delay = fk.CreateTriggerSkill {
  name = "#lingren_delay",
  anim_type = "offensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or target ~= player then return false end
    local room = player.room
    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return false end
    local use = card_event.data[1]
    return use.extra_data and use.extra_data.lingren and table.contains(use.extra_data.lingren, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("lingren") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getMark("lingren")
    room:setPlayerMark(player, "lingren", 0)
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
  end,
}
local fujian = fk.CreateTriggerSkill {
  name = "fujian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and (player.phase == Player.Finish or player.phase == Player.Start) then
      local n = 0
      local players = table.filter(player.room.alive_players, function (p)
        if p ~= player and not p:isKongcheng() then
          n = math.max(n, p:getHandcardNum())
          return true
        end
      end)
      if #players == 0 then return false end
      local targets = table.filter(players, function (p)
        return p:getHandcardNum() ~= n
      end)
      if #targets == 0 then
        targets = players
      end
      self.cost_data = {tos = {table.random(targets).id}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    U.viewCards(player, to.player_cards[Player.Hand], self.name, "$ViewCardsFrom:"..to.id)
  end,
}
lingren:addRelatedSkill(lingren_delay)
caoying:addSkill(lingren)
caoying:addSkill(fujian)
caoying:addRelatedSkill("ex__jianxiong")
caoying:addRelatedSkill("xingshang")
Fk:loadTranslationTable{
  ["caoying"] = "曹婴",
  ["#caoying"] = "龙城凤鸣",
  ["cv:caoying"] = "水原",
  ["illustrator:caoying"] = "花弟",
  ["designer:caoying"] = "韩旭",
  ["lingren"] = "凌人",
  [":lingren"] = "每回合限一次，当你使用【杀】或伤害类锦囊牌指定第一个目标后，"..
  "你可以猜测其中一名目标角色的手牌区中是否有基本牌、锦囊牌或装备牌。"..
  "若你猜对：至少一项，此牌对其造成的伤害+1；至少两项，你摸两张牌；三项，你获得〖奸雄〗和〖行殇〗直到你的下个回合开始。",
  ["fujian"] = "伏间",
  [":fujian"] = "锁定技，准备阶段或结束阶段，你随机观看手牌数不是全场最多的一名其他角色的手牌。",
  --实测：若有手牌的其他角色的手牌数均相同，则随机选其中一名角色，否则随机选不为这些角色中手牌数最大的角色

  ["#lingren-choose"] = "是否发动 凌人，猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#lingren-invoke"] = "是否对%dest发动 凌人，猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#lingren-choice"] = "凌人：猜测%dest的手牌中是否有基本牌、锦囊牌或装备牌",
  ["lingren_basic"] = "有基本牌",
  ["lingren_trick"] = "有锦囊牌",
  ["lingren_equip"] = "有装备牌",
  ["#lingren_result"] = "%from 猜对了 %arg 项",
  ["#lingren_delay"] = "凌人",

  ["$lingren1"] = "敌势已缓，休要走了老贼！",
  ["$lingren2"] = "精兵如炬，困龙难飞！",
  ["$fujian1"] = "兵者，诡道也。",
  ["$fujian2"] = "粮资军备，一览无遗。",
  ["$ex__jianxiong_caoying"] = "且收此弩箭，不日奉还。",
  ["$xingshang_caoying"] = "此刀枪军械，尽归我有。",
  ["~caoying"] = "曹魏天下存，魂归故土安……",
}

local xujing = General(extension, "ol__xujing", "shu", 3)
local yuxu = fk.CreateTriggerSkill{
  name = "yuxu",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) % 2 == 1 or
    player.room:askForSkillInvoke(player, self.name, data, "#yuxu-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:usedSkillTimes(self.name, Player.HistoryPhase) % 2 == 1 then
      player:drawCards(1, self.name)
    else
      if not player:isNude() then
        room:askForDiscard(player, 1, 1, true, self.name, false)
      end
    end
  end,
}
local shijian = fk.CreateTriggerSkill{
  name = "shijian",
  anim_type = "support",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) and target.phase == Player.Play and not player:isNude() and not target:hasSkill("yuxu",true) then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data[1]
        return use.from == target.id
      end, Player.HistoryPhase)
      return #events == 2 and events[2].data[1] == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#shijian-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    room:handleAddLoseSkills(target, "yuxu")
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(target, "-yuxu")
    end)
  end,
}
xujing:addSkill(yuxu)
xujing:addSkill(shijian)
Fk:loadTranslationTable{
  ["ol__xujing"] = "许靖",
  ["#ol__xujing"] = "品评名士",
  ["designer:ol__xujing"] = "pui980178",
  ["illustrator:ol__xujing"] = "君桓文化",
  ["yuxu"] = "誉虚",
  [":yuxu"] = "当你于出牌阶段内使用牌结算结束后，若你于此阶段内发动过本技能的次数为：偶数，你可以摸一张牌；奇数，你弃置一张牌。",
  ["shijian"] = "实荐",
  [":shijian"] = "一名其他角色于其出牌阶段使用的第二张牌结算结束后，你可以弃置一张牌，令其获得〖誉虚〗直到回合结束。",
  ["#yuxu-invoke"] = "誉虚：你可以摸一张牌，然后你使用下一张牌后需弃置一张牌",
  ["#shijian-invoke"] = "实荐：你可以弃置一张牌，令%dest获得〖誉虚〗直到回合结束",

  ["$yuxu1"] = "誉名浮虚，播流四海。",
  ["$yuxu2"] = "誉虚之名，得保一时。",
  ["$shijian1"] = "国家安危，在于足下。",
  ["$shijian2"] = "行之得道，即社稷用宁。",
  ["~ol__xujing"] = "漂薄风波，绝粮茹草……",
}

local yuantanyuanshang = General(extension, "yuantanyuanshang", "qun", 4)
local neifa = fk.CreateTriggerSkill{
  name = "neifa",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, ret = room:askForUseActiveSkill(player, "choose_players_skill", "#neifa-choose", true, {
      targets = table.map(table.filter(room.alive_players, function(p)
        return #p:getCardIds("ej") > 0 end), Util.IdMapper),
      num = 1,
      min_num = 0,
      pattern = "",
      skillName = self.name
    })
    if ret then
      self.cost_data = ret.targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:doIndicate(player.id, self.cost_data)
      local id = room:askForCardChosen(player, room:getPlayerById(self.cost_data[1]), "ej", self.name)
      room:obtainCard(player, id, true, fk.ReasonPrey, player.id, self.name)
    else
      room:drawCards(player, 2, self.name)
    end
    if player.dead or player:isNude() then return end
    local card = room:askForDiscard(player, 1, 1, true, self.name, false, ".", "#neifa-discard")
    if #card == 0 then return false end
    local list = {}
    if Fk:getCardById(card[1]).type == Card.TypeBasic then
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type ~= Card.TypeBasic end)
      list = {"basic_char", math.min(#cards, 5)}
    else
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).type == Card.TypeBasic end)
      list = {"non_basic_char", math.min(#cards, 5)}
    end
    local mark = player:getTableMark("@neifa-turn")
    -- 未测试，暂定同类覆盖
    if mark[1] == list[1] then
      mark[2] = list[2]
    else
      table.insertTable(mark, list)
    end
    room:setPlayerMark(player, "@neifa-turn", mark)
  end,
}
local neifa_trigger = fk.CreateTriggerSkill{
  name = "#neifa_trigger",
  anim_type = "control",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if player == target then
      local mark = player:getTableMark("@neifa-turn")
      if #mark == 0 then return false end
      if data.card:isCommonTrick() and table.contains(mark, "non_basic_char") then
        local targets = player.room:getUseExtraTargets(data)
        if #TargetGroup:getRealTargets(data.tos) > 1 then
          table.insertTable(targets, TargetGroup:getRealTargets(data.tos))
        end
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      elseif data.card.trueName == "slash" and table.contains(mark, "basic_char") then
        local targets = player.room:getUseExtraTargets(data)
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, self.cost_data, 1, 1, "#neifa_trigger-choose:::"..data.card:toLogString(),
    neifa.name, true, false, "addandcanceltarget_tip", TargetGroup:getRealTargets(data.tos))
    if #to > 0 then
      self.cost_data = to
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(neifa.name)
    local room = player.room
    if table.contains(TargetGroup:getRealTargets(data.tos), self.cost_data[1]) then
      TargetGroup:removeTarget(data.tos, self.cost_data[1])
      room:sendLog{ type = "#RemoveTargetsBySkill", from = target.id, to = self.cost_data, arg = neifa.name, arg2 = data.card:toLogString() }
    else
      table.insert(data.tos, self.cost_data)
      room:sendLog{ type = "#AddTargetsBySkill", from = target.id, to = self.cost_data, arg = neifa.name, arg2 = data.card:toLogString() }
    end
  end,
}
local neifa_draw = fk.CreateTriggerSkill{
  name = "#neifa_draw",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if not player.dead and target == player and data.card.type == Card.TypeEquip and
    player:usedSkillTimes(self.name, Player.HistoryTurn) < 2 then
      local mark = player:getTableMark("@neifa-turn")
      local index = table.indexOf(mark, "non_basic_char")
      return index > 0 and mark[index + 1] > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(neifa.name)
    local mark = player:getTableMark("@neifa-turn")
    local index = table.indexOf(mark, "non_basic_char")
    if index > 0 and mark[index + 1] > 0 then
      player:drawCards(mark[index + 1], "neifa")
    end
  end,
}
local neifa_targetmod = fk.CreateTargetModSkill{
  name = "#neifa_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      local mark = player:getTableMark("@neifa-turn")
      local index = table.indexOf(mark, "basic_char")
      if index > 0 then
        return mark[index + 1]
      end
    end
  end,
}
local neifa_prohibit = fk.CreateProhibitSkill{
  name = "#neifa_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getTableMark("@neifa-turn")
    if card.type == Card.TypeBasic then
      return table.contains(mark, "non_basic_char")
    else
      return table.contains(mark, "basic_char")
    end
  end,
}
neifa:addRelatedSkill(neifa_targetmod)
neifa:addRelatedSkill(neifa_prohibit)
neifa:addRelatedSkill(neifa_trigger)
neifa:addRelatedSkill(neifa_draw)
yuantanyuanshang:addSkill(neifa)
Fk:loadTranslationTable{
  ["yuantanyuanshang"] = "袁谭袁尚",
  ["#yuantanyuanshang"] = "兄弟阋墙",
  ["designer:yuantanyuanshang"] = "笔枔",
  ["illustrator:yuantanyuanshang"] = "MUMU",
  ["neifa"] = "内伐",
  [":neifa"] = "出牌阶段开始时，你可以摸两张牌或获得场上一张牌，然后弃置一张牌。若弃置的牌：是基本牌，你本回合不能使用非基本牌，"..
  "本阶段使用【杀】次数上限+X，目标上限+1；不是基本牌，你本回合不能使用基本牌，使用普通锦囊牌的目标+1或-1，前两次使用装备牌时摸X张牌"..
  "（X为发动技能时手牌中因本技能不能使用的牌且至多为5）。",
  ["#neifa-choose"] = "是否使用 内伐，获得场上的一张牌，或不选择角色则摸两张牌",
  ["#neifa-discard"] = "内伐：请弃置一张牌：若弃基本牌，你不能使用非基本牌；若弃非基本牌，你不能使用基本牌",
  ["@neifa-turn"] = "内伐",
  ["non_basic"] = "非基本牌", -- TODO: 搬运到本体翻译
  ["non_basic_char"] = "非基",
  ["#neifa_trigger-choose"] = "内伐：你可以为%arg增加/减少1个目标",
  ["#neifa_trigger"] = "内伐",
  ["#neifa_draw"] = "内伐",

  ["$neifa1"] = "自相恩残，相煎何急。",
  ["$neifa2"] = "同室内伐，贻笑外人。",
  ["~yuantanyuanshang"] = "兄弟难齐心，该有此果……",
}

local sunshao = General(extension, "ol__sunshao", "wu", 3)
local bizheng = fk.CreateTriggerSkill{
  name = "bizheng",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false),
    Util.IdMapper), 1, 1, "#bizheng-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    to:drawCards(2, self.name)
    if not player.dead and player:getHandcardNum() > player.maxHp then
      room:askForDiscard(player, 2, 2, true, self.name, false)
    end
    if not to.dead and to:getHandcardNum() > to.maxHp then
      room:askForDiscard(to, 2, 2, true, self.name, false)
    end
  end,
}
local yidian = fk.CreateTriggerSkill{
  name = "yidian",
  anim_type = "offensive",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.tos and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not table.find(player.room.discard_pile, function(id) return Fk:getCardById(id).name == data.card.name end) and
      #player.room:getUseExtraTargets(data, true) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, room:getUseExtraTargets(data, true), 1, 1,
      "#yidian-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    table.insert(data.tos, self.cost_data)
  end,
}
sunshao:addSkill(bizheng)
sunshao:addSkill(yidian)
Fk:loadTranslationTable{
  ["ol__sunshao"] = "孙邵",
  ["#ol__sunshao"] = "廊庙才",
  ["illustrator:ol__sunshao"] = "紫剑-h",
  ["bizheng"] = "弼政",
  [":bizheng"] = "摸牌阶段结束时，你可令一名其他角色摸两张牌，然后你与其之中，手牌数大于体力上限的角色弃置两张牌。",
  ["yidian"] = "佚典",
  [":yidian"] = "若你使用的基本牌或普通锦囊在弃牌堆中没有同名牌，你可以为此牌指定一个额外目标（无视距离）。",
  ["#bizheng-choose"] = "弼政：你可以令一名其他角色摸两张牌，然后你与其中手牌数大于体力上限的角色弃置两张牌",
  ["#yidian-choose"] = "佚典：你可以为此%arg额外指定一个目标",

  ["$bizheng1"] = "弼亮四世，正色率下。",
  ["$bizheng2"] = "弼佐辅君，国事政法。",
  ["$yidian1"] = "无传书卷记，功过自有评。",
  ["$yidian2"] = "佚以典传，千秋谁记？",
  ["~ol__sunshao"] = "此去一别，难见文举……",
}

local gaolan = General(extension, "ol__gaolan", "qun", 4)
local xiying = fk.CreateTriggerSkill{
  name = "xiying",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|hand|.|^basic", "#xiying-invoke", true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "xiying_invoked-turn", 1)
    room:doIndicate(player.id, table.map(room:getOtherPlayers(player), Util.IdMapper))
    room:throwCard(self.cost_data, self.name, player, player)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and #room:askForDiscard(p, 1, 1, true, self.name, true, ".", "#xiying-discard") == 0 then
        room:addPlayerMark(p, "@@xiying-turn", 1)
      end
    end
  end,
}
local xiying_delay = fk.CreateTriggerSkill{
  name = "#xiying_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and player.phase == Player.Finish and player:getMark("xiying_invoked-turn") > 0 then
      local play_ids = {}
      player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        if e.data[2] == Player.Play and e.end_id then
          table.insert(play_ids, {e.id, e.end_id})
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return false end
      local function PlayCheck (e)
        if e.data[1].from ~= player then return false end
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        return in_play
      end
      return #player.room.logic:getActualDamageEvents(1, PlayCheck) > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(room.draw_pile, function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    if #cards > 0 then
      room:moveCards({
        ids = table.random(cards, 1),
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
xiying:addRelatedSkill(xiying_delay)
local xiying_prohibit = fk.CreateProhibitSkill{
  name = "#xiying_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@xiying-turn") > 0
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@xiying-turn") > 0
  end,
}
xiying:addRelatedSkill(xiying_prohibit)
gaolan:addSkill(xiying)
Fk:loadTranslationTable{
  ["ol__gaolan"] = "高览",
  ["#ol__gaolan"] = "名门的峦柱",
  ["designer:ol__gaolan"] = "七哀",
  ["illustrator:ol__gaolan"] = "兴游",
  ["xiying"] = "袭营",
  [":xiying"] = "出牌阶段开始时，你可以弃置一张非基本手牌，令所有其他角色选择一项：1.弃置一张牌；2.本回合不能使用或打出牌。"..
  "若如此做，结束阶段，若你于本回合出牌阶段造成过伤害，你获得牌堆中一张【杀】或伤害锦囊牌。",
  ["#xiying_delay"] = "袭营",
  ["@@xiying-turn"] = "被袭营",
  ["#xiying-invoke"] = "袭营：你可以弃置一张非基本手牌，所有其他角色需弃置一张牌，否则其本回合不能使用或打出牌",
  ["#xiying-discard"] = "袭营：你需弃置一张牌，否则本回合不能使用或打出牌",
  
  ["$xiying1"] = "速袭曹营，以解乌巢之难！",
  ["$xiying2"] = "此番若功不能成，我军恐难以再战。",
  ["~ol__gaolan"] = "郭图小辈之计……误军呐！",
}

return extension
