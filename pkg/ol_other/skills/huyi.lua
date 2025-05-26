local huyi = fk.CreateSkill{
  name = "huyi",
}

Fk:loadTranslationTable{
  ["huyi"] = "虎翼",
  [":huyi"] = "游戏开始时，你从三个五虎将技能中选择一个获得。当你使用或打出一张基本牌后，若你因本技能获得的技能总数小于5，你随机获得一个"..
  "描述中包含此牌名的五虎将技能。回合结束时，你可以选择失去一个以此法获得的技能，观看一名其他角色的三张随机手牌并获得其中一张牌。",

  ["#huyi-choose"] = "虎翼：选择获得一个五虎技能",
  ["#huyi-invoke"] = "虎翼：你可以失去一个五虎技能",
  ["#huyi-choosePlayer"] = "虎翼：请选择一名其他角色，随机观看其三张手牌并获得其中一张",

  ["$huyi1"] = "青龙啸赤月，长刀行千里。",
  ["$huyi2"] = "矛取敌将首，声震当阳桥。",
  ["$huyi3"] = "身跨白玉鞍，铁骑踏冰河。",
  ["$huyi4"] = "满弓望西北，弦惊夜行之虎。",
  ["$huyi5"] = "游龙战长坂，可复七进七出。",
}

local function GetWuhuSkills(player)
  local mappers = Fk:currentRoom():getBanner("huyi_wuhushangjiang")
  if mappers == nil then
    local skills = {}
    local generals = {}
    local SGmapper = {}
    for _, name in ipairs(player.room.general_pile) do
      if table.find({"guanyu", "zhangfei", "zhaoyun", "machao", "huangzhong"}, function(s)
          return name:endsWith(s)
        end) or name == "gundam" then  --高达！
        table.insert(generals, Fk.generals[name])
      end
    end
    if #generals == 0 then return {} end
    for _, general in ipairs(generals) do
      local list = general:getSkillNameList(true)
      for _, skill in ipairs(list) do
        table.insert(skills, skill)
        SGmapper[skill] = general.name
      end
    end
    mappers = {skills, SGmapper}
    Fk:currentRoom():setBanner("huyi_wuhushangjiang", mappers)
  end
  return table.filter(mappers[1], function(s) return not player:hasSkill(s, true) end)
end

huyi:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(huyi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local skills = table.random(GetWuhuSkills(player), 3)
    if #skills == 0 then return end
    local skill = ""
    local generals = table.map(skills, function(s)
      return player.room:getBanner("huyi_wuhushangjiang")[2][s]
    end)
    local result = room:askToCustomDialog(player, {
      skill_name = huyi.name,
      qml_path = "packages/utility/qml/ChooseSkillBox.qml",
      extra_data = {
        skills, 1, 1, "#huyi-choose", generals,
      },
    })
    if result == "" then
      skill = table.random(skills)
    else
      skill = json.decode(result)[1]
    end
    room:addTableMark(player, huyi.name, skill)
    room:handleAddLoseSkills(player, skill)
  end,
})

local spec = {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(huyi.name) and
      data.card.type == Card.TypeBasic and #player:getTableMark(huyi.name) < 5 and
      table.find(GetWuhuSkills(player), function(s)
        return string.find(Fk:getDescription(s, "zh_CN"), "【"..Fk:translate(data.card.trueName, "zh_CN").."】") ~= nil
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local skills = table.filter(GetWuhuSkills(player), function(s)
      return string.find(Fk:getDescription(s, "zh_CN"), "【"..Fk:translate(data.card.trueName, "zh_CN").."】") ~= nil
    end)
    if #skills == 0 then return end
    local skill = table.random(skills)
    room:addTableMark(player, huyi.name, skill)
    room:handleAddLoseSkills(player, skill)
  end,
}
huyi:addEffect(fk.CardUseFinished, spec)
huyi:addEffect(fk.CardRespondFinished, spec)


huyi:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huyi.name) and #player:getTableMark(huyi.name) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getTableMark(huyi.name)
    local generals = table.map(skills, function(s)
      return room:getBanner("huyi_wuhushangjiang")[2][s]
    end)
    local result = room:askToCustomDialog(player, {
      skill_name = huyi.name,
      qml_path = "packages/utility/qml/ChooseSkillBox.qml",
      extra_data = {
        skills, 0, 1, "#huyi-invoke", generals,
      },
    })
    if result == "" then return end
    local choice = json.decode(result)
    if #choice > 0 then
      event:setCostData(self, {choice = choice[1]})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = huyi.name
    local room = player.room
    local skill = event:getCostData(self).choice
    room:removeTableMark(player, skillName, skill)
    room:handleAddLoseSkills(player, "-"..skill)

    local availableTargets = table.filter(room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
    if #availableTargets == 0 then
      return false
    end

    local to = room:askToChoosePlayers(
      player,
      {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#huyi-choosePlayer",
        skill_name = skillName,
        cancelable = false,
      }
    )[1]

    local cid = room:askToChooseCard(
      player,
      {
        target = to,
        flag = { card_data = { { to.general, table.random(to:getCardIds("h"), 3) } } },
        skill_name = skillName,
      }
    )
    room:obtainCard(player, cid, false, fk.ReasonPrey, player, skillName)
  end,
})

return huyi
