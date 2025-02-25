-- SPDX-License-Identifier: GPL-3.0-or-later

local prefix = "packages.ol.pkg."

local ex_shzl = require(prefix.."ol_ex")
local ex_yj = require(prefix.."ol_exyj")

Fk:loadTranslationTable{ ["ol"] = "OL", }

return {
  ex_shzl,
  ex_yj,
}
