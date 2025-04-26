local extension = Package:new("ol_other")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_other/skills")

Fk:loadTranslationTable{
  ["ol_other"] = "OL-其他",
  ["guandu"] = "官渡",
  ["ol_fd"] = "诸侯伐董",
  ["qin"] = "秦",
}

local hanba = General:new(extension, "hanba", "qun", 4, 4, General.Female)
hanba:addSkills { "fentian", "zhiri" }
hanba:addRelatedSkill("xintan")
Fk:loadTranslationTable{
  ["hanba"] = "旱魃",
  ["illustrator:hanba"] = "雪君s",

  ["~hanba"] = "应龙，是你在呼唤我吗……",
}

General:new(extension, "godzhenji", "god", 3, 3, General.Female):addSkills { "shenfu", "qixian" }
Fk:loadTranslationTable{
  ["godzhenji"] = "神甄姬",
  ["#godzhenji"] = "洛水的女神",
  ["illustrator:godzhenji"] = "鬼画府",

  ["~godzhenji"] = "众口铄金，难证吾清……",
}

local godcaopi = General:new(extension, "godcaopi", "god", 5)
godcaopi:addSkills { "chuyuan", "dengji" }
godcaopi:addRelatedSkills { "tianxing", "ex__jianxiong", "ex__rende", "ex__zhiheng", "ol_ex__luanji", "ol_ex__fangquan" }
Fk:loadTranslationTable{
  ["godcaopi"] = "神曹丕",
  ["#godcaopi"] = "诰天仰颂",
  ["illustrator:godcaopi"] = "鬼画府",

  ["$ex__jianxiong_godcaopi1"] = "孤之所长，继父之所长。",
  ["$ex__jianxiong_godcaopi2"] = "乱世枭雄，哼，孤亦是。",
  ["$ex__rende_godcaopi"] = "这些都是孤赏赐给你的。",
  ["$ex__zhiheng_godcaopi"] = "有些事情，还需多加思索。",
  ["$ol_ex__luanji_godcaopi"] = "违逆我的，都该处罚。",
  ["$ol_ex__fangquan_godcaopi"] = "此等小事，你们处理即可。",
  ["~godcaopi"] = "曹魏锦绣，孤还未看尽……",
}

local lvbu3 = General:new(extension, "hulao3__godlvbu", "god", 6)
lvbu3.hulao_status = 2
lvbu3:addSkills { "wushuang", "shenqu", "jiwu" }
lvbu3:addRelatedSkills { "qiangxi", "ex__tieji", "xuanfeng", "wansha" }
Fk:loadTranslationTable{
  ["hulao3__godlvbu"] = "神吕布",
  ["#hulao3__godlvbu"] = "神鬼无前",
  ["illustrator:hulao3__godlvbu"] = "LiuHeng",
  ["hulao3"] = "虎牢关",

  ["$wushuang_hulao3__godlvbu1"] = "此天下，还有挡我者？",
  ["$wushuang_hulao3__godlvbu2"] = "画戟扫沙场，无双立万世。",
  ["~hulao3__godlvbu"] = "你们的项上人头，我改日再取！",
}

General:new(extension, "guandu__xinping", "qun", 3):addSkills { "fuyuanx", "zhongjiex", "yongdi" }
Fk:loadTranslationTable{
  ["guandu__xinping"] = "辛评",
  --["illustrator:guandu__xinping"] = "",

  ["$yongdi_guandu__xinping1"] = "袁门当兴，兴在明公！",
  ["$yongdi_guandu__xinping2"] = "主公之位，非君莫属。",
  ["~guandu__xinping"] = "老臣，尽力了……",
}

General:new(extension, "guandu__hanmeng", "qun", 4):addSkills { "jieliang", "quanjiu" }
Fk:loadTranslationTable{
  ["guandu__hanmeng"] = "韩猛",
  --["illustrator:guandu__hanmeng"] = "",

  ["~guandu__hanmeng"] = "曹操狡诈，防不胜防……",
}

General:new(extension, "guandu__xuyou", "qun", 3):addSkills { "guandu__shicai", "guandu__zezhu", "guandu__chenggong" }
Fk:loadTranslationTable{
  ["guandu__xuyou"] = "许攸",
  ["#guandu__xuyou"] = "恃才傲物",
  ["illustrator:guandu__xuyou"] = "zoo",

  ["~guandu__xuyou"] = "我军之所以败，皆因尔等指挥不当！",
}

General:new(extension, "guandu__chunyuqiong", "qun", 5):addSkills { "guandu__cangchu", "guandu__sushou", "guandu__liangying" }
Fk:loadTranslationTable{
  ["guandu__chunyuqiong"] = "淳于琼",
  ["#guandu__chunyuqiong"] = "昔袍今臣",
  ["illustrator:guandu__chunyuqiong"] = "zoo",

  ["~guandu__chunyuqiong"] = "子远老贼，吾死当追汝之魂！",
}

General:new(extension, "guandu__zhanghe", "qun", 4):addSkills { "yuanlue" }
Fk:loadTranslationTable{
  ["guandu__zhanghe"] = "张郃",
  ["#guandu__zhanghe"] = "名门的梁柱",
  ["illustrator:guandu__zhanghe"] = "兴游",

  ["~guandu__zhanghe"] = "袁公不听吾之言，乃至今日。",
}

General:new(extension, "ol_fd__dongyue", "qun", 4):addSkills { "kuangxi", "mojun" }
Fk:loadTranslationTable{
  ["ol_fd__dongyue"] = "董越",
  ["#ol_fd__dongyue"] = "东中郎将",
  ["illustrator:ol_fd__dongyue"] = "江东的萌虎",
}

--General:new(extension, "ol_fd__fanchou", "qun", 4):addSkills { "", "mojun" }
Fk:loadTranslationTable{
  ["ol_fd__fanchou"] = "樊稠",
  ["#ol_fd__fanchou"] = "万年侯",
  ["illustrator:ol_fd__fanchou"] = "",
}

--General:new(extension, "ol_fd__guosi", "qun", 4):addSkills { "", "mojun" }
Fk:loadTranslationTable{
  ["ol_fd__guosi"] = "郭汜",
  ["#ol_fd__guosi"] = "美阳侯",
  ["illustrator:ol_fd__guosi"] = "",
}

--General:new(extension, "ol_fd__huaxiong", "qun", 8):addSkills { "", "mojun" }
Fk:loadTranslationTable{
  ["ol_fd__huaxiong"] = "华雄",
  ["#ol_fd__huaxiong"] = "飞扬跋扈",
  ["illustrator:ol_fd__huaxiong"] = "",
}

--General:new(extension, "ol_fd__lijue", "qun", 5):addSkills { "", "mojun" }
Fk:loadTranslationTable{
  ["ol_fd__lijue"] = "李傕",
  ["#ol_fd__lijue"] = "池阳侯",
  ["illustrator:ol_fd__lijue"] = "",
}

--General:new(extension, "ol_fd__niufudongxie", "qun", 4, 4, General.Bigender):addSkills { "", "mojun" }
Fk:loadTranslationTable{
  ["ol_fd__niufudongxie"] = "牛辅董翓",
  ["#ol_fd__niufudongxie"] = "蛇夫蝎妇",
  ["illustrator:ol_fd__niufudongxie"] = "",
}

--General:new(extension, "ol_fd__sunjian", "qun", 6):addSkills { "yinghun", "" }
Fk:loadTranslationTable{
  ["ol_fd__sunjian"] = "孙坚",
  ["#ol_fd__sunjian"] = "江东的猛虎",
  ["illustrator:ol_fd__sunjian"] = "Thinking",
}

--General:new(extension, "ol_fd__zhangji", "qun", 4):addSkills { "", "mojun" }
Fk:loadTranslationTable{
  ["ol_fd__zhangji"] = "张济",
  ["#ol_fd__zhangji"] = "平阳侯",
  ["illustrator:ol_fd__zhangji"] = "",
}

General:new(extension, "shangyang", "qin", 4):addSkills { "qin__bianfa", "qin__limu", "qin__kencao" }
Fk:loadTranslationTable{
  ["shangyang"] = "商鞅",
  ["#shangyang"] = "变法者",
  --["illustrator:shangyang"] = "",

  ["~shangyang"] = "无人可依，变法难行……",
}

General:new(extension, "zhangyiq", "qin", 4):addSkills { "qin__lianheng", "qin__xichu", "qin__xiongbian", "qin__qiaoshe" }
Fk:loadTranslationTable{
  ["zhangyiq"] = "张仪",
  ["#zhangyiq"] = "合纵连横",
  --["illustrator:zhangyiq"] = "",

  ["~zhangyiq"] = "连横之道，后世难存……",
}

General:new(extension, "baiqi", "qin", 4):addSkills { "qin__wuan", "qin__shashen", "qin__fachu", "qin__changsheng" }
Fk:loadTranslationTable{
  ["baiqi"] = "白起",
  ["#baiqi"] = "血战长平",
  --["illustrator:baiqi"] = "",

  ["~baiqi"] = "将士迟暮，难以再战……",
}

General:new(extension, "yingzheng", "qin", 4):addSkills { "qin__yitong", "qin__shihuang", "qin__zulong", "qin__fenshu" }
Fk:loadTranslationTable{
  ["yingzheng"] = "嬴政",
  ["#yingzheng"] = "横扫六合",
  --["illustrator:yingzheng"] = "",

  ["~yingzheng"] = "咳咳……拿孤的金丹……",
}

local lvbuwei = General:new(extension, "lvbuwei", "qin", 3)
lvbuwei:addSkills { "qin__qihuo", "jugu", "qin__chunqiu", "qin__baixiang" }
lvbuwei:addRelatedSkills { "qin__zhongfu", "ex__jianxiong", "ex__rende", "ex__zhiheng" }
Fk:loadTranslationTable{
  ["lvbuwei"] = "吕不韦",
  ["#lvbuwei"] = "吕氏春秋",
  --["illustrator:lvbuwei"] = "",

  ["$jugu_lvbuwei"] = "钱财富有，富甲一方。",
  ["~lvbuwei"] = "酖酒入肠，魂落异乡……",
}

General:new(extension, "zhaogao", "qin", 3):addSkills { "qin__zhilu", "qin__gaizhao", "qin__haizhong", "qin__yuanli" }
Fk:loadTranslationTable{
  ["zhaogao"] = "赵高",
  ["#zhaogao"] = "沙丘谋变",
  --["illustrator:zhaogao"] = "",

  ["~zhaogao"] = "唉！权力害己啊！",
}

General:new(extension, "zhaoji", "qin", 3, 4, General.Female):addSkills { "qin__shanwu", "qin__daqi", "qin__xianji", "qin__huoluan" }
Fk:loadTranslationTable{
  ["zhaoji"] = "赵姬",
  ["#zhaoji"] = "祸乱宫闱",
  --["illustrator:zhaoji"] = "",

  ["~zhaoji"] = "人间冷暖尝尽，富贵轮回成空……",
}

General:new(extension, "miyue", "qin", 3, 3, General.Female):addSkills { "qin__zhangzheng", "qin__taihou", "qin__youmie", "qin__yintui" }
Fk:loadTranslationTable{
  ["miyue"] = "芈月",
  ["#miyue"] = "始太后",
  --["illustrator:miyue"] = "",

  ["~miyue"] = "年老色衰，繁华已逝……",
}

General:new(extension, "qin__nushou", "qin", 3):addSkills { "qin__tongpao", "qin__jingnu" }
Fk:loadTranslationTable{
  ["qin__nushou"] = "秦军弩手",
  ["#qin__nushou"] = "与子同泽",
  --["illustrator:qin__nushou"] = "",
}

General:new(extension, "qin__qibing", "qin", 3):addSkills { "qin__tongpao", "qin__changjian", "qin__liangju" }
Fk:loadTranslationTable{
  ["qin__qibing"] = "秦军骑兵",
  ["#qin__qibing"] = "与子同泽",
  --["illustrator:qin__qibing"] = "",
}

General:new(extension, "qin__bubing", "qin", 4):addSkills { "qin__tongpao", "qin__fangzhen", "qin__changbing" }
Fk:loadTranslationTable{
  ["qin__bubing"] = "秦军步兵",
  ["#qin__bubing"] = "与子同泽",
  --["illustrator:qin__bubing"] = "",
}

General:new(extension, "wuhushangjiang", "shu", 4):addSkills { "huyi" }
Fk:loadTranslationTable{
  ["wuhushangjiang"] = "魂·五虎",
  ["#wuhushangjiang"] = "蜀汉之魂",  --称号出自官盗2025尊享
  --["illustrator:wuhushangjiang"] = "",

  --["~wuhushangjiang"] = "麦城残阳……洗长刀……",
  --["~wuhushangjiang"] = "当阳……空余声……",
  --["~wuhushangjiang"] = "西风寒……冷铁衣……",
  --["~wuhushangjiang"] = "年老力衰……不复当年勇……",
  ["~wuhushangjiang"] = "亢龙……有悔……",
}

General:new(extension, "ol__caocao", "qun", 4):addSkills { "dingxi", "nengchen", "huojie" }
Fk:loadTranslationTable{
  ["ol__caocao"] = "汉曹操",
  ["illustrator:ol__caocao"] = "凡果",

  ["~ol__caocao"] = "此征西将军曹侯之墓。",
}

local lvbu = General:new(extension, "ol__lvbu", "qun", 5)
lvbu:addSkills { "fengzhu", "yuyu", "zhijil", "jiejiu" }
lvbu:addRelatedSkills { "shenji", "wushuang" }
Fk:loadTranslationTable{
  ["ol__lvbu"] = "战神吕布",
  ["illustrator:ol__lvbu"] = "鬼画府",

  ["~ol__lvbu"] = "刘备！奸贼！汝乃天下最无信义之人！",
}

local nianshou = General:new(extension, "nianshou", "god", 4)
nianshou:addSkills { "suisui", "shouhun" }
nianshou:addRelatedSkills {
  "shengxiao_zishu", "shengxiao_chouniu", "shengxiao_yinhu", "shengxiao_maotu",
  "shengxiao_chenlong", "shengxiao_sishe", "shengxiao_wuma", "shengxiao_weiyang",
  "shengxiao_shenhou", "shengxiao_youji", "shengxiao_xugou", "shengxiao_haizhu"
}
Fk:loadTranslationTable{
  ["nianshou"] = "普通年兽",
}

return extension
