local sijun = fk.CreateSkill {
  name = "ol__sijun",
}

Fk:loadTranslationTable{
  ["ol__sijun"] = "肆军",
  [":ol__sijun"] = "准备阶段，若“黄”标记数大于牌堆里的牌数，你可以移去所有“黄”标记，然后获得随机张点数之和为36的牌。",

  ["$ol__sijun1"] = "山河为罗，苍生为醮。问诸天神佛，何为大道！",
  ["$ol__sijun2"] = "微渺之蛾可以熄离火，方寸之雪可以教天地变色！",
}

sijun:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sijun.name) and player.phase == Player.Start and
      player:getMark("@zhangjiao_huang") > #player.room.draw_pile
  end,
  on_use = function(self, event, tar, player)
    local room = player.room
    room:setPlayerMark(player, "@zhangjiao_huang", 0)
    local cards = {}
    if #room.draw_pile > 3 then
      local ret = {}
      local total = 36
      local numnums = {}
      local maxs = {}
      local pileToSearch = {}
      for i = 1, 13, 1 do
        table.insert(numnums, 0)
        table.insert(maxs, 36//i)
        table.insert(pileToSearch, {})
      end
      for _, id in ipairs(room.draw_pile) do
        local x = Fk:getCardById(id).number
        if x > 0 and x < 14 then
          table.insert(pileToSearch[x], id)
          if numnums[x] < maxs[x] then
            numnums[x] = numnums[x] + 1
          end
        end
      end
      local nums = {}
      for index, value in ipairs(numnums) do
        for _ = 1, value, 1 do
          table.insert(nums, index)
        end
      end
      local postsum = {}
      local nn = #nums
      postsum[nn+1] = 0
      for i = nn, 1, -1 do
        postsum[i] = postsum[i+1] + nums[i]
      end
      local function nSum(n, l, r, target)
        local _ret = {}
        if n == 1 then
          for i = l, r, 1 do
            if nums[i] == target then
              table.insert(_ret, {target})
              break
            end
          end
        elseif n == 2 then
          while l < r do
            local now = nums[l] + nums[r]
            if now > target then
              r = r - 1
            elseif now < target then
              l = l + 1
            else
              table.insert(_ret, {nums[l], nums[r]})
              l = l + 1
              r = r - 1
              while l < r and nums[l] == nums[l-1] do
                l = l + 1
              end
              while l < r and nums[r] == nums[r+1] do
                r = r - 1
              end
            end
          end
        else
          for i = l, r-(n-1), 1 do
            if (i > l and nums[i] == nums[i-1]) or
              (nums[i] + postsum[r - (n-1) + 1] < target) then
            else
              if postsum[i] - postsum[i+n] > target then
                break
              end
              local v = nSum(n-1, i+1, r, target - nums[i])
              for j = 1, #v, 1 do
                table.insert(v[j], nums[i])
                table.insert(_ret, v[j])
              end
            end
          end
        end
        return _ret
      end
      for i = 3, total, 1 do
        table.insertTable(ret, nSum(i, 1, #nums, total))
      end
      if #ret > 0 then
        local compare = table.random(ret)
        table.sort(compare)
        local x = 0
        local current_n = compare[1]
        for _, value in ipairs(compare) do
          if value == current_n then
            x = x + 1
          else
            table.insertTable(cards, table.random(pileToSearch[current_n], x))
            x = 1
            current_n = value
          end
        end
        table.insertTable(cards, table.random(pileToSearch[current_n], x))
      end
    end
    if #cards == 0 then
      local tmp_drawPile = table.simpleClone(room.draw_pile)
      local sum = 0
      while sum < 36 and #tmp_drawPile > 0 do
        local id = table.remove(tmp_drawPile, math.random(1, #tmp_drawPile))
        sum = sum + Fk:getCardById(id).number
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, sijun.name, nil, false, player)
    end
  end,
})

return sijun
