import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"


def load_json(name: str):
    return json.loads((DATA_DIR / name).read_text(encoding="utf-8"))


def write_json(name: str, data):
    (DATA_DIR / name).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def listify(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def artifact_rarity(artifact_level: str, risk_level: str) -> str:
    level = str(artifact_level).lower()
    risk = str(risk_level).lower()
    if level == "0":
        return "mythic"
    if level == "1":
        return "legendary"
    if level == "2":
        return "epic"
    if level == "3":
        return "rare"
    if risk in {"extreme", "high"}:
        return "epic"
    if risk == "medium":
        return "rare"
    if risk == "low":
        return "uncommon"
    return "unknown"


def material_to_item(material: dict) -> dict:
    is_core = bool(material.get("is_core_material"))
    related_pathway = material.get("related_pathway")
    related_sequence = material.get("related_sequence")
    sequence_text = (
        f"序列 {related_sequence}" if related_sequence is not None else "未知序列"
    )
    usage = f"用于 {related_pathway} 途径 {sequence_text} 的魔药调配。"
    description = material.get("description")
    if description:
        usage = f"{usage}{description}"

    negative_effect = "无固定负面效果；若来源被污染，风险由魔药调配系统判定。"
    if is_core:
        negative_effect = "主材料错误、污染或替代不当会提高晋升失败、污染和失控风险。"

    return {
        "item_id": material["material_id"],
        "name_cn": material.get("name_cn", ""),
        "name_en": material.get("name_en", ""),
        "item_type": "material",
        "rarity": material.get("rarity", "unknown"),
        "related_pathway": related_pathway,
        "related_sequence": related_sequence,
        "source_map": listify(material.get("source_region")),
        "obtain_method": listify(material.get("obtain_method")),
        "usage": usage,
        "positive_effect": "作为魔药、仪式或制作系统的材料使用。",
        "negative_effect": negative_effect,
        "containment_method": "常规密封保存；若来自污染区域或黑市，应先进行灵性检查。",
        "is_tradeable": material.get("material_type") != "special_requirement",
        "is_equippable": False,
        "equip_slot": None,
        "stack_limit": 99,
        "risk_level": "medium" if is_core else "low",
        "source_table": "materials",
        "source_id": material["material_id"],
        "gameplay_tags": [
            "potion_material",
            material.get("material_type", "unknown"),
            "core_material" if is_core else "auxiliary_or_other_material",
        ],
        "source_note": listify(material.get("source_note")),
        "canon_status": material.get("canon_status", "wiki_only"),
        "game_adaptation_note": "由 materials.json 转换为统一道具表记录，用于背包、商店、魔药调配和任务系统。",
    }


def artifact_to_item(artifact: dict) -> dict:
    can_player_use = bool(artifact.get("can_player_use"))
    return {
        "item_id": artifact["artifact_id"],
        "name_cn": artifact.get("artifact_name_cn", ""),
        "name_en": artifact.get("artifact_name_en", ""),
        "item_type": "sealed_artifact",
        "rarity": artifact_rarity(
            artifact.get("artifact_level", "unknown"),
            artifact.get("risk_level", "unknown"),
        ),
        "related_pathway": artifact.get("related_pathway"),
        "related_sequence": None,
        "source_map": [],
        "obtain_method": listify(artifact.get("obtain_method")),
        "usage": "封印物、特殊道具或高危任务物品；具体用途由 quest_usage 和效果字段决定。",
        "positive_effect": artifact.get("positive_effect", ""),
        "negative_effect": artifact.get("negative_effect", ""),
        "containment_method": artifact.get("containment_method", ""),
        "is_tradeable": False,
        "is_equippable": can_player_use,
        "equip_slot": "artifact" if can_player_use else None,
        "stack_limit": 1,
        "risk_level": artifact.get("risk_level", "unknown"),
        "artifact_level": artifact.get("artifact_level", "unknown"),
        "quest_usage": listify(artifact.get("quest_usage")),
        "source_table": "sealed_artifacts",
        "source_id": artifact["artifact_id"],
        "gameplay_tags": ["sealed_artifact", f"risk_{artifact.get('risk_level', 'unknown')}"],
        "source_note": listify(artifact.get("source_note")),
        "canon_status": artifact.get("canon_status", "game_adapted"),
        "game_adaptation_note": "由 sealed_artifacts.json 转换为统一道具表记录，用于背包、收容、装备、任务和风险系统。",
    }


EXTRA_ITEMS = [
    {
        "item_id": "item_fog_city_service_revolver",
        "name_cn": "雾城制式左轮",
        "name_en": "Fog City Service Revolver",
        "item_type": "weapon",
        "rarity": "common",
        "related_pathway": None,
        "related_sequence": None,
        "source_map": ["雾城下城区", "市警局"],
        "obtain_method": ["警局临时配给", "武器店购买", "主线任务奖励"],
        "usage": "第一卷早期通用武器，用于普通敌人和低风险遭遇。",
        "positive_effect": "提供稳定远程伤害，可打断普通敌人动作。",
        "negative_effect": "枪声会吸引敌人和警力；对灵体与高污染目标效果有限。",
        "containment_method": "常规武器保管，进入官方据点时需登记。",
        "is_tradeable": True,
        "is_equippable": True,
        "equip_slot": "weapon",
        "stack_limit": 1,
        "risk_level": "low",
        "source_table": "manual_item_seed",
        "source_id": None,
        "gameplay_tags": ["weapon", "ranged", "volume_1"],
        "source_note": ["第一卷任务文档", "游戏化改编"],
        "canon_status": "original_placeholder",
        "game_adaptation_note": "MVP 战斗用通用武器，占位数据。",
    },
    {
        "item_id": "item_paper_figurine",
        "name_cn": "空白纸人",
        "name_en": "Blank Paper Figurine",
        "item_type": "consumable",
        "rarity": "uncommon",
        "related_pathway": "fool",
        "related_sequence": 7,
        "source_map": ["黑荆棘事务所", "老莫里斯书店"],
        "obtain_method": ["神秘学商店购买", "任务奖励", "手工制作"],
        "usage": "纸人替身、误导、仪式替代和魔术师相关技能消耗品。",
        "positive_effect": "可消耗以触发纸人替身或制造短暂诱饵。",
        "negative_effect": "连续使用会提升命运干扰值。",
        "containment_method": "保持干燥，远离明火和污染墨水。",
        "is_tradeable": True,
        "is_equippable": False,
        "equip_slot": None,
        "stack_limit": 20,
        "risk_level": "low",
        "source_table": "manual_item_seed",
        "source_id": None,
        "gameplay_tags": ["consumable", "paper_substitute", "fool"],
        "source_note": ["战斗与技能系统文档", "游戏化改编"],
        "canon_status": "game_adapted",
        "game_adaptation_note": "为纸人替身技能准备的消耗品。",
    },
    {
        "item_id": "item_sedative_potion",
        "name_cn": "镇静药剂",
        "name_en": "Sedative Potion",
        "item_type": "consumable",
        "rarity": "common",
        "related_pathway": None,
        "related_sequence": None,
        "source_map": ["黑荆棘事务所", "药剂店"],
        "obtain_method": ["官方补给", "药剂店购买", "医疗支线奖励"],
        "usage": "降低短期理智动摇，帮助玩家从恐惧、幻听和轻度污染反应中恢复。",
        "positive_effect": "恢复少量理智值，暂时降低失控检定风险。",
        "negative_effect": "短时间内降低反应速度；连续使用效果递减。",
        "containment_method": "常温保存，过期后不可使用。",
        "is_tradeable": True,
        "is_equippable": False,
        "equip_slot": None,
        "stack_limit": 10,
        "risk_level": "low",
        "source_table": "manual_item_seed",
        "source_id": None,
        "gameplay_tags": ["consumable", "sanity", "medical"],
        "source_note": ["任务与剧情第一卷文档", "游戏化改编"],
        "canon_status": "original_placeholder",
        "game_adaptation_note": "MVP 理智系统恢复道具。",
    },
    {
        "item_id": "item_purification_powder",
        "name_cn": "简易净化粉",
        "name_en": "Simple Purification Powder",
        "item_type": "consumable",
        "rarity": "uncommon",
        "related_pathway": "sun",
        "related_sequence": None,
        "source_map": ["黑荆棘事务所", "草药铺"],
        "obtain_method": ["仪式教学奖励", "草药铺购买", "官方补给"],
        "usage": "用于基础净化仪式、清除轻度污染状态或处理低风险污染物。",
        "positive_effect": "降低轻度污染，提升基础仪式稳定性。",
        "negative_effect": "对深层污染无效；错误使用可能扩散污染粉尘。",
        "containment_method": "密封干燥保存，使用时避免吸入。",
        "is_tradeable": True,
        "is_equippable": False,
        "equip_slot": None,
        "stack_limit": 20,
        "risk_level": "low",
        "source_table": "manual_item_seed",
        "source_id": None,
        "gameplay_tags": ["consumable", "purification", "ritual"],
        "source_note": ["任务与剧情第一卷文档", "游戏化改编"],
        "canon_status": "original_placeholder",
        "game_adaptation_note": "MVP 净化和仪式系统消耗品。",
    },
    {
        "item_id": "item_broken_pocket_watch",
        "name_cn": "破损怀表",
        "name_en": "Broken Pocket Watch",
        "item_type": "quest_item",
        "rarity": "rare",
        "related_pathway": None,
        "related_sequence": None,
        "source_map": ["案发公寓"],
        "obtain_method": ["第一卷主线 V01-MQ-01"],
        "usage": "第一卷开局关键线索，可用于占卜、仪式检查和身份谜团推进。",
        "positive_effect": "提供案发时间、黑伞人和死者身份相关线索。",
        "negative_effect": "错误仪式检查可能触发短暂幻觉。",
        "containment_method": "放入证物袋，进行灵性检查前不要长时间贴身携带。",
        "is_tradeable": False,
        "is_equippable": False,
        "equip_slot": None,
        "stack_limit": 1,
        "risk_level": "medium",
        "source_table": "manual_item_seed",
        "source_id": None,
        "gameplay_tags": ["quest_item", "volume_1", "case_clue"],
        "source_note": ["任务与剧情第一卷文档", "游戏化改编"],
        "canon_status": "original_placeholder",
        "game_adaptation_note": "第一卷案件线索道具。",
    },
    {
        "item_id": "item_gray_candle_wax",
        "name_cn": "污染蜡块",
        "name_en": "Polluted Gray Candle Wax",
        "item_type": "quest_item",
        "rarity": "rare",
        "related_pathway": None,
        "related_sequence": None,
        "source_map": ["雾港码头", "下城区仓库"],
        "obtain_method": ["第一卷主线 V01-MQ-04", "邪教据点调查"],
        "usage": "追踪灰烛会仪式来源，也可作为诱饵或污染样本。",
        "positive_effect": "帮助定位邪教仪式节点和污染源。",
        "negative_effect": "未封存携带时会周期性增加污染值。",
        "containment_method": "以银箔和净化粉双重封存，交由官方组织检测。",
        "is_tradeable": False,
        "is_equippable": False,
        "equip_slot": None,
        "stack_limit": 5,
        "risk_level": "high",
        "source_table": "manual_item_seed",
        "source_id": None,
        "gameplay_tags": ["quest_item", "polluted", "cult"],
        "source_note": ["任务与剧情第一卷文档", "游戏化改编"],
        "canon_status": "original_placeholder",
        "game_adaptation_note": "第一卷邪教线索和污染样本道具。",
    },
    {
        "item_id": "item_black_umbrella_ticket",
        "name_cn": "黑伞人的车票",
        "name_en": "Black Umbrella Man's Ticket",
        "item_type": "quest_item",
        "rarity": "epic",
        "related_pathway": None,
        "related_sequence": None,
        "source_map": ["废弃钟楼", "城际车站"],
        "obtain_method": ["第一卷主线 V01-MQ-07", "第一卷主线 V01-MQ-09"],
        "usage": "指向下一座城市的核心线索，用于第一卷结尾转场。",
        "positive_effect": "解锁离开雾城和追踪黑伞人的下一阶段任务。",
        "negative_effect": "占卜车票真实来源可能触发高位注视和污染判定。",
        "containment_method": "夹入案件日志，不要对车票上的目的地进行连续占卜。",
        "is_tradeable": False,
        "is_equippable": False,
        "equip_slot": None,
        "stack_limit": 1,
        "risk_level": "medium",
        "source_table": "manual_item_seed",
        "source_id": None,
        "gameplay_tags": ["quest_item", "volume_1", "next_city"],
        "source_note": ["任务与剧情第一卷文档", "游戏化改编"],
        "canon_status": "original_placeholder",
        "game_adaptation_note": "第一卷卷尾转场道具。",
    },
]


def main():
    materials = load_json("materials.json")
    artifacts = load_json("sealed_artifacts.json")
    items = [material_to_item(material) for material in materials]
    items.extend(artifact_to_item(artifact) for artifact in artifacts)
    items.extend(EXTRA_ITEMS)
    items.sort(key=lambda item: item["item_id"])
    write_json("items.json", items)
    print(f"Generated {len(items)} items at {DATA_DIR / 'items.json'}")


if __name__ == "__main__":
    main()
