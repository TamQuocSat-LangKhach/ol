-- SPDX-License-Identifier: GPL-3.0-or-later

local prefix = "packages.ol.pkg."

local ex_shzl = require(prefix .. "ol_ex")
local ex_yj = require(prefix .. "ol_exyj")
local wende = require(prefix .. "wende")
local xinghe = require(prefix .. "xinghe")
local ol_mou = require(prefix .. "ol_mou")
local menfa = require(prefix .. "menfa")
local jsrg = require(prefix .. "jsrg")
local qifu = require(prefix .. "qifu")
local ol_sp = require(prefix .. "ol_sp")
local ol_re = require(prefix .. "ol_re")
local ol_test = require(prefix .. "ol_test")
local ol_other = require(prefix .. "ol_other")

local ol_derived = require(prefix .. "ol_derived")

Fk:loadTranslationTable{ ["ol"] = "OL", }

return {
  ex_shzl,
  ex_yj,
  wende,
  xinghe,
  ol_mou,
  menfa,
  jsrg,
  qifu,
  ol_sp,
  ol_re,
  ol_test,
  ol_other,

  ol_derived,
}
