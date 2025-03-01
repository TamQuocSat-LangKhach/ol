local extension = Package:new("ol_ex_shzl")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_ex/skills")

Fk:loadTranslationTable{
  ["ol_ex_shzl"] = "OL-界神话再临",
  ["ol_ex"] = "OL界",
}

General:new(extension, "ol_ex__zhaoyun", "shu", 4):addSkills { "ol_ex__longdan", "ol_ex__yajiao" }
Fk:loadTranslationTable{
  ["ol_ex__zhaoyun"] = "界赵云",
  ["#ol_ex__zhaoyun"] = "虎威将军",
  ["illustrator:ol_ex__zhaoyun"] = "木美人",

  ["~ol_ex__zhaoyun"] = "伐逆寇，兴汉室，吾难忘之……",
}

local lvmeng = General:new(extension, "ol_ex__lvmeng", "wu", 4)
lvmeng:addSkills { "keji", "ol_ex__qinxue", "botu", }
lvmeng:addRelatedSkills { "gongxin" }
Fk:loadTranslationTable{
  ["ol_ex__lvmeng"] = "界吕蒙",
  ["#ol_ex__lvmeng"] = "士别三日",
  ["illustrator:ol_ex__lvmeng"] = "木美人",

  ["$keji_ol_ex__lvmeng1"] = "哼，笑到最后的，才是赢家。",
  ["$keji_ol_ex__lvmeng2"] = "静观其变，相机而动。",
  ["$gongxin_ol_ex__lvmeng1"] = "料敌机先，攻心为上。",
  ["$gongxin_ol_ex__lvmeng2"] = "你的举动，都在我的掌握之中。",
  ["~ol_ex__lvmeng"] = "以后……就交给年轻人了……",
}

General:new(extension, "ol_ex__huaxiong", "qun", 6):addSkills { "ol_ex__yaowu", "shizhan" }
Fk:loadTranslationTable{
  ["ol_ex__huaxiong"] = "界华雄",
  ["#ol_ex__huaxiong"] = "飞扬跋扈",
  ["designer:ol_ex__huaxiong"] = "玄蝶既白",
  ["illustrator:ol_ex__huaxiong"] = "秋呆呆",

  ["~ol_ex__huaxiong"] = "我掉以轻心了……",
}

General:new(extension, "ol_ex__xiahouyuan", "wei", 4):addSkills { "ol_ex__shensu", "shebian" }
Fk:loadTranslationTable{
  ["ol_ex__xiahouyuan"] = "界夏侯渊",
  ["#ol_ex__xiahouyuan"] = "疾行的猎豹",
  ["illustrator:ol_ex__xiahouyuan"] = "李秀森",

  ["~ol_ex__xiahouyuan"] = "我的速度，还是不够……",
}

General:new(extension, "ol_ex__caoren", "wei", 4):addSkills { "ol_ex__jushou", "ol_ex__jiewei" }
Fk:loadTranslationTable{
  ["ol_ex__caoren"] = "界曹仁",
  ["#ol_ex__caoren"] = "大将军",
  ["illustrator:ol_ex__caoren"] = "Ccat",

  ["~ol_ex__caoren"] = "长江以南，再无王土矣……",
}

General:new(extension, "ol_ex__huangzhong", "shu", 4):addSkills { "ol_ex__liegong" }
Fk:loadTranslationTable{
  ["ol_ex__huangzhong"] = "界黄忠",
  ["#ol_ex__huangzhong"] = "老当益壮",
  ["illustrator:ol_ex__huangzhong"] = "匠人绘",

  ["~ol_ex__huangzhong"] = "末将，有负主公重托……",
}

General:new(extension, "ol_ex__weiyan", "shu", 4):addSkills { "ol_ex__kuanggu", "ol_ex__qimou" }
Fk:loadTranslationTable{
  ["ol_ex__weiyan"] = "界魏延",
  ["#ol_ex__weiyan"] = "嗜血的独狼",
  ["illustrator:ol_ex__weiyan"] = "王强",

  ["~ol_ex__weiyan"] = "这次失败，意料之中……",
}

General:new(extension, "ol_ex__xiaoqiao", "wu", 3, 3, General.Female):addSkills { "ol_ex__tianxiang", "ol_ex__hongyan", "ol_ex__piaoling" }
Fk:loadTranslationTable{
  ["ol_ex__xiaoqiao"] = "界小乔",
  ["#ol_ex__xiaoqiao"] = "矫情之花",
  ["illustrator:ol_ex__xiaoqiao"] = "王强",

  ["~ol_ex__xiaoqiao"] = "同心而离居，忧伤以终老……",
}

General:new(extension, "ol_ex__zhoutai", "wu", 4):addSkills { "ol_ex__buqu", "fenji" }
Fk:loadTranslationTable{
  ["ol_ex__zhoutai"] = "界周泰",
  ["#ol_ex__zhoutai"] = "历战之躯",
  ["illustrator:ol_ex__zhoutai"] = "Thinking",

  ["~ol_ex__zhoutai"] = "敌众我寡，无力回天……",
}

General:new(extension, "ol_ex__zhangjiao", "qun", 3):addSkills { "ol_ex__leiji", "ol_ex__guidao", "ol_ex__huangtian" }
Fk:loadTranslationTable{
  ["ol_ex__zhangjiao"] = "界张角",
  ["#ol_ex__zhangjiao"] = "天公将军",
  ["illustrator:ol_ex__zhangjiao"] = "青骑士",

  ["~ol_ex__zhangjiao"] = "天书无效，人心难聚……",
}

local yuji = General:new(extension, "ol_ex__yuji", "qun", 3)
yuji:addSkills { "ol_ex__guhuo" }
yuji:addRelatedSkills { "ol_ex__chanyuan" }
Fk:loadTranslationTable{
  ["ol_ex__yuji"] = "界于吉",
  ["#ol_ex__yuji"] = "太平道人",
  ["illustrator:ol_ex__yuji"] = "波子",

  ["~ol_ex__yuji"] = "符水失效，此病难医……",
}

General:new(extension, "ol_ex__dianwei", "wei", 4):addSkills { "ol_ex__qiangxi", "ninge" }
Fk:loadTranslationTable{
  ["ol_ex__dianwei"] = "界典韦",
  ["#ol_ex__dianwei"] = "古之恶来",
  ["illustrator:ol_ex__dianwei"] = "君桓文化",

  ["~ol_ex__dianwei"] = "为将者，怎可徒手而亡？",
}

General:new(extension, "ol_ex__xunyu", "wei", 3):addSkills { "quhu", "ol_ex__jieming" }
Fk:loadTranslationTable{
  ["ol_ex__xunyu"] = "界荀彧",
  ["#ol_ex__xunyu"] = "王佐之才",
  ["illustrator:ol_ex__xunyu"] = "罔両",

  ["$quhu_ol_ex__xunyu1"] = "两虎相斗，旁观成败。",
  ["$quhu_ol_ex__xunyu2"] = "驱兽相争，坐收渔利。",
  ["~ol_ex__xunyu"] = "一招不慎，为虎所噬……",
}

General:new(extension, "ol_ex__wolong", "shu", 3):addSkills { "bazhen", "ol_ex__huoji", "ol_ex__kanpo", "cangzhuo" }
Fk:loadTranslationTable{
  ["ol_ex__wolong"] = "界卧龙诸葛亮",
  ["#ol_ex__wolong"] = "卧龙",
  ["illustrator:ol_ex__wolong"] = "李秀森",

  ["$bazhen_ol_ex__wolong1"] = "八阵连心，日月同辉。",
  ["$bazhen_ol_ex__wolong2"] = "此阵变化，岂是汝等可解？",
  ["~ol_ex__wolong"] = "星途半废，夙愿未完……",
}

local pangtong = General:new(extension, "ol_ex__pangtong", "shu", 3)
pangtong:addSkills { "ol_ex__lianhuan", "ol_ex__niepan" }
pangtong:addRelatedSkills { "bazhen", "ol_ex__huoji", "ol_ex__kanpo" }
Fk:loadTranslationTable{
  ["ol_ex__pangtong"] = "界庞统",
  ["#ol_ex__pangtong"] = "凤雏",
  ["illustrator:ol_ex__pangtong"] = "MUMU",

  ["$bazhen_ol_ex__pangtong1"] = "八卦四象，阴阳运转。",
  ["$bazhen_ol_ex__pangtong2"] = "离火艮山，皆随我用。",
  ["$ol_ex__huoji_ol_ex__pangtong1"] = "火计诱敌，江水助势。",
  ["$ol_ex__huoji_ol_ex__pangtong2"] = "火烧赤壁，曹贼必败。",
  ["$ol_ex__kanpo_ol_ex__pangtong1"] = "卧龙之才，吾也略懂。",
  ["$ol_ex__kanpo_ol_ex__pangtong2"] = "这些小伎俩，逃不出我的眼睛！",
  ["~ol_ex__pangtong"] = "骥飞羽落，坡道归尘……",
}

General:new(extension, "ol_ex__taishici", "wu", 4):addSkills { "tianyi", "hanzhan" }
Fk:loadTranslationTable{
  ["ol_ex__taishici"] = "界太史慈",
  ["#ol_ex__taishici"] = "笃烈之士",
  ["illustrator:ol_ex__taishici"] = "biou09",

  ["$tianyi_ol_ex__taishici1"] = "天降大任，速战解围！",
  ["$tianyi_ol_ex__taishici2"] = "义不从之，天必不佑！",
  ["~ol_ex__taishici"] = "无妄之灾，难以避免……",
}

General:new(extension, "ol_ex__pangde", "qun", 4):addSkills { "mashu", "ol_ex__jianchu" }
Fk:loadTranslationTable{
  ["ol_ex__pangde"] = "界庞德",
  ["#ol_ex__pangde"] = "人马一体",
  ["illustrator:ol_ex__pangde"] = "YanBai",

  ["~ol_ex__pangde"] = "人亡马倒，命之所归……",
}

General:new(extension, "ol_ex__yanliangwenchou", "qun", 4):addSkills { "ol_ex__shuangxiong" }
Fk:loadTranslationTable{
  ["ol_ex__yanliangwenchou"] = "界颜良文丑",
  ["#ol_ex__yanliangwenchou"] = "虎狼兄弟",
  ["illustrator:ol_ex__yanliangwenchou"] = "梦回唐朝",

  ["~ol_ex__yanliangwenchou"] = "双雄皆陨，徒隆武圣之名……",
}

General:new(extension, "ol_ex__yuanshao", "qun", 4):addSkills { "ol_ex__luanji", "ol_ex__xueyi" }
Fk:loadTranslationTable{
  ["ol_ex__yuanshao"] = "界袁绍",
  ["#ol_ex__yuanshao"] = "高贵的名门",
  ["illustrator:ol_ex__yuanshao"] = "罔両",

  ["~ol_ex__yuanshao"] = "孟德此计，防不胜防……",
}

General:new(extension, "ol_ex__xuhuang", "wei", 4):addSkills { "ol_ex__duanliang", "ol_ex__jiezi" }
Fk:loadTranslationTable{
  ["ol_ex__xuhuang"] = "界徐晃",
  ["#ol_ex__xuhuang"] = "周亚夫之风",
  ["illustrator:ol_ex__xuhuang"] = "biou09",

  ["~ol_ex__xuhuang"] = "亚夫易老，李广难封……",
}

General:new(extension, "ol_ex__zhurong", "shu", 4, 4, General.Female):addSkills { "juxiang", "lieren", "changbiao" }
Fk:loadTranslationTable{
  ["ol_ex__zhurong"] = "界祝融",
  ["#ol_ex__zhurong"] = "野性的女王",
  ["illustrator:ol_ex__zhurong"] = "匠人绘",

  ["$juxiang_ol_ex__zhurong1"] = "巨象冲锋，踏平敌阵！",
  ["$juxiang_ol_ex__zhurong2"] = "南兵象阵，刀枪不入！",
  ["$lieren_ol_ex__zhurong1"] = "烈火飞刃，例无虚发！",
  ["$lieren_ol_ex__zhurong2"] = "烈刃一出，谁与争锋？",
  ["~ol_ex__zhurong"] = "这汉人，竟……如此厉害……",
}

General:new(extension, "ol_ex__menghuo", "shu", 4):addSkills { "huoshou", "ol_ex__zaiqi" }
Fk:loadTranslationTable{
  ["ol_ex__menghuo"] = "界孟获",
  ["#ol_ex__menghuo"] = "南蛮王",
  ["illustrator:ol_ex__menghuo"] = "磐蒲",

  ["$huoshou_ol_ex__menghuo1"] = "啸据哀牢，闻祸而喜！",
  ["$huoshou_ol_ex__menghuo2"] = "坐据三山，蛮霸四野！",
  ["~ol_ex__menghuo"] = "勿再放我，但求速死！",
}

General:new(extension, "ol_ex__sunjian", "wu", 4, 5):addSkills { "yinghun", "wulie" }
Fk:loadTranslationTable{
  ["ol_ex__sunjian"] = "界孙坚",
  ["#ol_ex__sunjian"] = "武烈帝",
  ["illustrator:ol_ex__sunjian"] = "匠人绘",

  ["$yinghun_ol_ex__sunjian1"] = "提刀奔走，灭敌不休。",
  ["$yinghun_ol_ex__sunjian2"] = "贼寇草莽，我且出战。",
  ["~ol_ex__sunjian"] = "袁术之辈，不可共谋！",
}

General:new(extension, "ol_ex__lusu", "wu", 3):addSkills { "ol_ex__haoshi", "ol_ex__dimeng" }
Fk:loadTranslationTable{
  ["ol_ex__lusu"] = "界鲁肃",
  ["#ol_ex__lusu"] = "独断的外交家",
  ["illustrator:ol_ex__lusu"] = "游漫美绘",

  ["~ol_ex__lusu"] = "一生为国，纵死无憾……",
}

General:new(extension, "ol_ex__dongzhuo", "qun", 8):addSkills { "ol_ex__jiuchi", "roulin", "benghuai", "ol_ex__baonue" }
Fk:loadTranslationTable{
  ["ol_ex__dongzhuo"] = "界董卓",
  ["#ol_ex__dongzhuo"] = "魔王",
  ["illustrator:ol_ex__dongzhuo"] = "磐蒲",

  ["$roulin_ol_ex__dongzhuo1"] = "醇酒美人，幸甚乐甚！",
  ["$roulin_ol_ex__dongzhuo2"] = "这些美人，都可进贡。",
  ["$benghuai_ol_ex__dongzhuo1"] = "何人伤我？",
  ["$benghuai_ol_ex__dongzhuo2"] = "酒色伤身呐……",
  ["~ol_ex__dongzhuo"] = "地府……可有美人乎？",
}

General:new(extension, "ol_ex__jiaxu", "qun", 3):addSkills { "ol_ex__wansha", "ol_ex__luanwu", "ol_ex__weimu" }
Fk:loadTranslationTable{
  ["ol_ex__jiaxu"] = "界贾诩",
  ["#ol_ex__jiaxu"] = "冷酷的毒士",
  ["illustrator:ol_ex__jiaxu"] = "游漫美绘",

  ["~ol_ex__jiaxu"] = "此劫，我亦有所算……",
}

General:new(extension, "ol_ex__zhanghe", "wei", 4):addSkills { "ol_ex__qiaobian" }
Fk:loadTranslationTable{
  ["ol_ex__zhanghe"] = "界张郃",
  ["#ol_ex__zhanghe"] = "料敌机先",
  ["illustrator:ol_ex__zhanghe"] = "君桓文化",

  ["~ol_ex__zhanghe"] = "何处之流矢……",
}

local dengai = General:new(extension, "ol_ex__dengai", "wei", 4)
dengai:addSkills { "ol_ex__tuntian", "ol_ex__zaoxian" }
dengai:addRelatedSkill("ol_ex__jixi")
Fk:loadTranslationTable{
  ["ol_ex__dengai"] = "界邓艾",
  ["#ol_ex__dengai"] = "矫然的壮士",
  ["illustrator:ol_ex__dengai"] = "君桓文化",

  ["~ol_ex__dengai"] = "钟会！你为何害我！",
}

local jiangwei = General:new(extension, "ol_ex__jiangwei", "shu", 4)
jiangwei:addSkills { "ol_ex__tiaoxin", "ol_ex__zhiji" }
jiangwei:addRelatedSkills { "ex__guanxing" }
Fk:loadTranslationTable{
  ["ol_ex__jiangwei"] = "界姜维",
  ["#ol_ex__jiangwei"] = "龙的衣钵",
  ["illustrator:ol_ex__jiangwei"] = "游漫美绘",

  ["$ex__guanxing_ol_ex__jiangwei1"] = "星象相弦，此乃吉兆！",
  ["$ex__guanxing_ol_ex__jiangwei2"] = "星之分野，各有所属。",
  ["~ol_ex__jiangwei"] = "星散流离……",
}

local liushan = General:new(extension, "ol_ex__liushan", "shu", 3)
liushan:addSkills { "xiangle", "ol_ex__fangquan", "ol_ex__ruoyu" }
liushan:addRelatedSkills { "ol_ex__jijiang", "sishu" }
Fk:loadTranslationTable{
  ["ol_ex__liushan"] = "界刘禅",
  ["#ol_ex__liushan"] = "无为的真命主",
  ["illustrator:ol_ex__liushan"] = "拉布拉卡",

  ["$xiangle_ol_ex__liushan1"] = "美好的日子，应该好好享受。",
  ["$xiangle_ol_ex__liushan2"] = "嘿嘿嘿，还是玩耍快乐。",
  ["~ol_ex__liushan"] = "将军英勇，我……我投降……",
}

local sunce = General:new(extension, "ol_ex__sunce", "wu", 4)
sunce:addSkills { "ol_ex__jiang", "ol_ex__hunzi", "ol_ex__zhiba" }
sunce:addRelatedSkills{ "ex__yingzi", "yinghun" }
Fk:loadTranslationTable{
  ["ol_ex__sunce"] = "界孙策",
  ["#ol_ex__sunce"] = "江东的小霸王",
  ["illustrator:ol_ex__sunce"] = "李敏然",

  ["$ex__yingzi_ol_ex__sunce1"] = "得公瑾辅助，策必当一战！",
  ["$ex__yingzi_ol_ex__sunce2"] = "公瑾在此，此战无忧！",
  ["$yinghun_ol_ex__sunce1"] = "东吴繁盛，望父亲可知。",
  ["$yinghun_ol_ex__sunce2"] = "父亲，吾定不负你期望！",
  ["~ol_ex__sunce"] = "汝等，怎能受于吉蛊惑？",
}

General:new(extension, "ol_ex__zhangzhaozhanghong", "wu", 3):addSkills { "ol_ex__zhijian", "ol_ex__guzheng" }
Fk:loadTranslationTable{
  ["ol_ex__zhangzhaozhanghong"] = "界张昭张纮",
  ["#ol_ex__zhangzhaozhanghong"] = "经天纬地",
  ["designer:ol_ex__zhangzhaozhanghong"] = "玄蝶既白",
  ["illustrator:ol_ex__zhangzhaozhanghong"] = "君桓文化",

  ["~ol_ex__zhangzhaozhanghong"] = "老臣年迈，无力为继……",
}

General:new(extension, "ol_ex__zuoci", "qun", 3):addSkills { "ol_ex__huashen", "ol_ex__xinsheng" }
Fk:loadTranslationTable{
  ["ol_ex__zuoci"] = "界左慈",
  ["#ol_ex__zuoci"] = "迷之仙人",
  ["illustrator:ol_ex__zuoci"] = "波子",

  ["~ol_ex__zuoci"] = "红尘看破，驾鹤仙升……",
}

General:new(extension, "ol_ex__caiwenji", "qun", 3, 3, General.Female):addSkills { "ol_ex__beige", "duanchang" }
Fk:loadTranslationTable{
  ["ol_ex__caiwenji"] = "界蔡文姬",
  ["#ol_ex__caiwenji"] = "异乡的孤女",
  ["illustrator:ol_ex__caiwenji"] = "罔両",

  ["$duanchang_ol_ex__caiwenji1"] = "红颜留塞外，愁思欲断肠。",
  ["$duanchang_ol_ex__caiwenji2"] = "莫吟苦辛曲，此生谁忍闻。",
  ["~ol_ex__caiwenji"] = "飘飘外域里，何日能归乡？",
}

return extension
