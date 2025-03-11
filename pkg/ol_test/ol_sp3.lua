
local dongtuna = General(extension, "dongtuna", "qun", 4)
local jianman = fk.CreateTriggerSkill{
  name = "jianman",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local users, names, to = {}, {}, nil
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data[1]
        if use.card.type == Card.TypeBasic then
          table.insert(users, use.from)
          table.insertIfNeed(names, use.card.name)
          return true
        end
      end, Player.HistoryTurn)
      if #users < 2 then return false end
      local n = 0
      if users[1] == player.id then
        n = n + 1
        to = users[2]
      end
      if users[2] == player.id then
        n = n + 1
        to = users[1]
      end
      self.cost_data = nil
      if n == 2 then
        self.cost_data = names
      elseif n == 1 then
        self.cost_data = to
      end
      return n > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "table" then
      U.askForUseVirtualCard(room, player, self.cost_data, nil, self.name, nil, false, true, false, true)
    else
      local to = room:getPlayerById(self.cost_data)
      if not to.dead and not to:isNude() then
        local id = room:askForCardChosen(player, to, "he", self.name)
        room:throwCard({id}, self.name, to, player)
      end
    end
  end,
}
dongtuna:addSkill(jianman)
Fk:loadTranslationTable{
  ["dongtuna"] = "董荼那",
  ["#dongtuna"] = "铅刀拿云",
  ["designer:dongtuna"] = "大宝",
  ["illustrator:dongtuna"] = "monkey",
  ["jianman"] = "鹣蛮",
  [":jianman"] = "锁定技，每回合结束时，若本回合前两张基本牌的使用者：均为你，你视为使用其中的一张牌；仅其中之一为你，你弃置另一名使用者一张牌。",

  ["$jianman1"] = "鹄巡山野，见腐羝而聒鸣！",
  ["$jianman2"] = "我蛮夷也，进退可无矩。",
  ["~dongtuna"] = "孟获小儿，安敢杀我！",
}

local peixiu = General(extension, "ol__peixiu", "wei", 4)
Fk:loadTranslationTable{
  ["ol__peixiu"] = "裴秀",
  ["#ol__peixiu"] = "勋德茂著",
  ["~ol__peixiu"] = "",
}

local maozhuo = fk.CreateTriggerSkill{
  name = "maozhuo",
  events = {fk.DamageCaused},
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
    player == target and
    player:hasSkill(self) and
    player.phase == Player.Play and
    player:usedSkillTimes(self.name) == 0 and
    player:getMark("maozhuo_record-turn") == 0 and
    #table.filter(player.player_skills, function(skill) return skill:isPlayerSkill(player) end) >
      #table.filter(data.to.player_skills, function(skill) return skill:isPlayerSkill(data.to) end) and
    #player.room.logic:getActualDamageEvents(
      1,
      function(e)
        if e.data[1].from == player then
          player.room:setPlayerMark(player, "maozhuo_record-turn", 1)
          return true
        end
        return false
      end,
      Player.HistoryPhase
    ) == 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local maozhuoTargetMod = fk.CreateTargetModSkill{
  name = "#maozhuo_targetmod",
  frequency = Skill.Compulsory,
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(maozhuo) and skill.trueName == "slash_skill" then
      return
        #table.filter(
          player.player_skills,
          function(skill) return skill:isPlayerSkill(player) and skill.visible end
        )
    end
  end,
}
local maozhuoMaxCards = fk.CreateMaxCardsSkill{
  name = "#maozhuo_maxcards",
  frequency = Skill.Compulsory,
  correct_func = function(self, player)
    if player:hasSkill(maozhuo) then
      return
        #table.filter(
          player.player_skills,
          function(skill) return skill:isPlayerSkill(player) and skill.visible end
        )
    end
  end,
}
Fk:loadTranslationTable{
  ["maozhuo"] = "茂著",
  [":maozhuo"] = "锁定技，你使用【杀】的次数上限和手牌上限+X（X为你的技能数）；当你于出牌阶段内首次造成伤害时，" ..
  "若受伤角色的技能数少于你，则此伤害+1。",
}

maozhuo:addRelatedSkill(maozhuoTargetMod)
maozhuo:addRelatedSkill(maozhuoMaxCards)
peixiu:addSkill(maozhuo)

local jinlan = fk.CreateActiveSkill{
  name = "jinlan",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = function()
    local mostSkillNum = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      local skillNum = #table.filter(
        p.player_skills,
        function(skill) return skill:isPlayerSkill(p) and skill.visible end
      )
      if skillNum > mostSkillNum then
        mostSkillNum = skillNum
      end
    end
    return "#jinlan:::" .. mostSkillNum
  end,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 then
      return false
    end

    local mostSkillNum = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      local skillNum = #table.filter(
        p.player_skills,
        function(skill) return skill:isPlayerSkill(p) and skill.visible end
      )
      if skillNum > mostSkillNum then
        mostSkillNum = skillNum
      end
    end
    return player:getHandcardNum() < mostSkillNum
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)

    local mostSkillNum = 0
    for _, p in ipairs(room.alive_players) do
      local skillNum = #table.filter(p.player_skills, function(skill) return skill:isPlayerSkill(p) end)
      if skillNum > mostSkillNum then
        mostSkillNum = skillNum
      end
    end
    player:drawCards(mostSkillNum - player:getHandcardNum(), self.name)
  end,
}
Fk:loadTranslationTable{
  ["jinlan"] = "尽览",
  [":jinlan"] = "出牌阶段限一次，你可以将手牌摸至X张（X为存活角色中技能最多角色的技能数）。",
  ["#jinlan"] = "尽览：你可将手牌摸至%arg张",
}

peixiu:addSkill(jinlan)
