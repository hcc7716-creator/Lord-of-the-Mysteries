# 道具、材料、封印物数据库设计文档

> 文档用途：把材料、封印物、武器、消耗品和任务物品统一整理成可供背包、商店、装备、任务、魔药调配和封印物系统读取的游戏道具表。  
> 数据文件：`data/items.json`。  
> 数据来源：`data/materials.json`、`data/sealed_artifacts.json`、第一卷任务文档、战斗与技能文档，以及项目游戏化改编内容。  
> 参考资料：`docs/lord-of-mysteries-reference.md` 仍作为世界观和原始资料参考，不直接承担游戏道具表职责。

## 1. 设计目标

项目中已经有材料表和封印物清单，但游戏运行时不能让背包、商店、任务和装备系统分别读取多套完全不同的数据结构。统一道具表的目标是：

1. 让材料、封印物、武器、消耗品、任务物品都能进入同一个背包系统。
2. 让商店系统能判断物品是否可交易。
3. 让装备系统能判断物品是否可装备。
4. 让魔药调配系统能读取材料用途和所属途径。
5. 让封印物系统能读取正面效果、负面效果和封印方法。
6. 让任务系统能通过 `item_id` 引用关键物品。
7. 保留原始资料来源，避免把原著资料、Wiki 整理和游戏化改编混在一起。

## 2. 数据文件关系

| 文件 | 用途 |
| --- | --- |
| `data/materials.json` | 魔药材料原始开发数据 |
| `data/sealed_artifacts.json` | 封印物和特殊高危道具原始开发数据 |
| `data/items.json` | 统一游戏道具表，供背包、商店、装备、任务和 UI 使用 |
| `types/item.ts` | 道具表 TypeScript 类型定义 |
| `tools/generate_items_database.py` | 从材料表和封印物表生成统一道具表的脚本 |

重要原则：

- 不删除 `materials.json` 和 `sealed_artifacts.json`。
- `items.json` 是游戏运行层的统一索引。
- 如果材料或封印物原始资料发生变化，应重新运行 `tools/generate_items_database.py`。
- 手写新增的武器、消耗品和任务物品暂时写在脚本的 `EXTRA_ITEMS` 中，后续可以拆成独立源表。

## 3. 道具类型

| 类型 | 英文字段值 | 说明 |
| --- | --- | --- |
| 材料 | `material` | 魔药主材料、辅助材料、仪式材料、特殊需求 |
| 封印物 | `sealed_artifact` | 有正面效果、负面效果和封印要求的高危物品 |
| 武器 | `weapon` | 可装备的普通或神秘武器 |
| 消耗品 | `consumable` | 药剂、纸人、净化粉、仪式媒介等一次性或堆叠物品 |
| 任务物品 | `quest_item` | 推进剧情、案件、地图解锁或 NPC 关系的关键物品 |

## 4. 字段说明

| 字段 | 中文名 | 类型 | 说明 |
| --- | --- | --- | --- |
| `item_id` | 道具 ID | string | 稳定唯一 ID。材料沿用 `material_id`，封印物沿用 `artifact_id` |
| `name_cn` | 中文名 | string | 玩家 UI 和策划文档显示 |
| `name_en` | 英文名 | string | 代码、数据库或英文 UI 使用 |
| `item_type` | 类型 | string | `material`、`sealed_artifact`、`weapon`、`consumable`、`quest_item` |
| `rarity` | 稀有度 | string | common、uncommon、rare、epic、legendary、mythic、unknown |
| `related_pathway` | 所属途径 | string/null | 关联途径，例如 `fool`、`sun`；通用道具为 `null` |
| `related_sequence` | 关联序列 | number/null | 魔药材料对应序列；封印物或通用道具可为 `null` |
| `source_map` | 来源地图 | string[] | 物品可能出现或获得的地图、区域、据点 |
| `obtain_method` | 获取方式 | string[] | 商店购买、任务奖励、怪物掉落、官方补给、黑市交易等 |
| `usage` | 用途 | string | 物品在游戏系统中的主要用途 |
| `positive_effect` | 正面效果 | string | 使用、装备、调配或任务交付时的收益 |
| `negative_effect` | 负面效果 | string | 污染、失控、冷却、命运干扰、交易风险等代价 |
| `containment_method` | 封印方法 | string | 封印物收容方法；普通物品可写保存方式 |
| `is_tradeable` | 是否可交易 | boolean | 商店和黑市系统读取 |
| `is_equippable` | 是否可装备 | boolean | 装备栏读取 |
| `equip_slot` | 装备槽 | string/null | weapon、artifact、accessory、tool 或 `null` |
| `stack_limit` | 堆叠上限 | number | 背包堆叠数量 |
| `risk_level` | 风险等级 | string | low、medium、high、extreme、unknown |
| `artifact_level` | 封印物等级 | string | 仅封印物使用，例如 0、1、2、3、unclassified |
| `quest_usage` | 任务用途 | string[] | 仅封印物或任务关键物品使用 |
| `source_table` | 来源表 | string | materials、sealed_artifacts、manual_item_seed |
| `source_id` | 来源 ID | string/null | 原始记录 ID |
| `gameplay_tags` | 玩法标签 | string[] | 检索、筛选和系统联动 |
| `source_note` | 来源备注 | string[] | 第一部正文、Wiki、官方补充、游戏化改编等 |
| `canon_status` | 正典状态 | string | 沿用项目 canon_status 枚举 |
| `game_adaptation_note` | 游戏化说明 | string | 说明该记录如何被转成游戏道具 |

## 5. 转换规则

### 5.1 材料转道具

材料记录从 `materials.json` 转成 `items.json` 时：

| 原字段 | 新字段 | 规则 |
| --- | --- | --- |
| `material_id` | `item_id` | 直接沿用，避免破坏魔药调配引用 |
| `name_cn` | `name_cn` | 直接沿用 |
| `name_en` | `name_en` | 直接沿用 |
| `material_type` | `gameplay_tags` | 作为标签保存 |
| `rarity` | `rarity` | 直接沿用 |
| `related_pathway` | `related_pathway` | 直接沿用 |
| `related_sequence` | `related_sequence` | 直接沿用 |
| `source_region` | `source_map` | 转成来源地图数组 |
| `obtain_method` | `obtain_method` | 直接沿用 |
| `description` | `usage` | 拼接成游戏用途说明 |
| `is_core_material` | `risk_level` / `negative_effect` | 主材料默认风险更高 |

材料默认可交易、不可装备、堆叠上限为 99。

### 5.2 封印物转道具

封印物记录从 `sealed_artifacts.json` 转成 `items.json` 时：

| 原字段 | 新字段 | 规则 |
| --- | --- | --- |
| `artifact_id` | `item_id` | 直接沿用，便于任务引用 |
| `artifact_name_cn` | `name_cn` | 转成统一中文名 |
| `artifact_name_en` | `name_en` | 转成统一英文名 |
| `artifact_level` | `artifact_level` / `rarity` | 封印物等级保留，并推导稀有度 |
| `appearance` | 暂不单列 | 后续可扩展为 `appearance` 或 UI 描述字段 |
| `positive_effect` | `positive_effect` | 直接沿用 |
| `negative_effect` | `negative_effect` | 直接沿用 |
| `containment_method` | `containment_method` | 直接沿用 |
| `related_pathway` | `related_pathway` | 直接沿用 |
| `obtain_method` | `obtain_method` | 直接沿用 |
| `quest_usage` | `quest_usage` | 直接沿用 |
| `can_player_use` | `is_equippable` | 可用封印物默认可装备到 artifact 槽 |
| `risk_level` | `risk_level` | 直接沿用 |

封印物默认不可交易，堆叠上限为 1。

### 5.3 稀有度推导

封印物稀有度由封印等级和风险等级推导：

| 封印物等级 | 道具稀有度 |
| --- | --- |
| 0 | mythic |
| 1 | legendary |
| 2 | epic |
| 3 | rare |
| unclassified + high/extreme | epic |
| unclassified + medium | rare |
| unclassified + low | uncommon |

## 6. 示例 JSON

### 6.1 材料示例

```json
{
  "item_id": "mat_lavos_squid_blood",
  "name_cn": "拉瓦章鱼血液",
  "name_en": "Lavos Squid's Blood",
  "item_type": "material",
  "rarity": "rare",
  "related_pathway": "fool",
  "related_sequence": 9,
  "source_map": ["鲁恩王国-廷根市", "地下黑市"],
  "obtain_method": ["值夜者仓库配给", "地下黑市购买", "海产相关委托奖励"],
  "usage": "用于 fool 途径序列 9 的魔药调配。占卜家魔药主材料之一。",
  "positive_effect": "作为魔药、仪式或制作系统的材料使用。",
  "negative_effect": "主材料错误、污染或替代不当会提高晋升失败、污染和失控风险。",
  "containment_method": "常规密封保存；若来自污染区域或黑市，应先进行灵性检查。",
  "is_tradeable": true,
  "is_equippable": false
}
```

### 6.2 封印物示例

```json
{
  "item_id": "artifact_2_049_antigonus_family_puppet",
  "name_cn": "2-049 安提哥努斯家族木偶",
  "name_en": "Antigonus Family Puppet",
  "item_type": "sealed_artifact",
  "rarity": "epic",
  "related_pathway": "fool",
  "positive_effect": "让附近人员身体和思维变得迟缓，可作为规则战教学对象。",
  "negative_effect": "影响所有附近人员，包括使用者或玩家队友。",
  "containment_method": "需隔离收容，避免无防护人员接近。",
  "is_tradeable": false,
  "is_equippable": false,
  "risk_level": "high",
  "artifact_level": "2"
}
```

### 6.3 任务物品示例

```json
{
  "item_id": "item_broken_pocket_watch",
  "name_cn": "破损怀表",
  "name_en": "Broken Pocket Watch",
  "item_type": "quest_item",
  "rarity": "rare",
  "source_map": ["案发公寓"],
  "obtain_method": ["第一卷主线 V01-MQ-01"],
  "usage": "第一卷开局关键线索，可用于占卜、仪式检查和身份谜团推进。",
  "positive_effect": "提供案发时间、黑伞人和死者身份相关线索。",
  "negative_effect": "错误仪式检查可能触发短暂幻觉。",
  "containment_method": "放入证物袋，进行灵性检查前不要长时间贴身携带。",
  "is_tradeable": false,
  "is_equippable": false
}
```

## 7. TypeScript 接口

```ts
export type GameItemType =
  | "material"
  | "sealed_artifact"
  | "weapon"
  | "consumable"
  | "quest_item";

export interface GameItem {
  item_id: string;
  name_cn: string;
  name_en: string;
  item_type: GameItemType;
  rarity: string;
  related_pathway: string | null;
  related_sequence: number | null;
  source_map: string[];
  obtain_method: string[];
  usage: string;
  positive_effect: string;
  negative_effect: string;
  containment_method: string;
  is_tradeable: boolean;
  is_equippable: boolean;
  equip_slot: string | null;
  stack_limit: number;
  risk_level: string;
  source_table: "materials" | "sealed_artifacts" | "manual_item_seed";
  source_id: string | null;
  gameplay_tags: string[];
  source_note: string[];
  canon_status: string;
  game_adaptation_note: string;
}
```

完整类型定义见 `types/item.ts`。

## 8. MVP 使用方式

第一版可以这样接入：

| 系统 | 读取字段 |
| --- | --- |
| 背包 | `item_id`、`name_cn`、`item_type`、`rarity`、`stack_limit` |
| 商店 | `is_tradeable`、`rarity`、`obtain_method`、`source_map` |
| 装备 | `is_equippable`、`equip_slot`、`positive_effect`、`negative_effect` |
| 魔药调配 | `item_type`、`related_pathway`、`related_sequence`、`gameplay_tags` |
| 任务系统 | `item_id`、`quest_usage`、`usage`、`source_map` |
| 封印物系统 | `artifact_level`、`risk_level`、`containment_method`、`negative_effect` |
| UI | `name_cn`、`rarity`、`positive_effect`、`negative_effect` |

暂时不做：

- 完整价格系统。
- 所有普通武器库。
- 所有消耗品配方。
- 封印物 3D 展示与收容小游戏。
- 不同城市商店库存动态经济。

## 9. 后续扩展方向

当前 `items.json` 采用平铺字段，适合 MVP 阶段快速接入背包、任务、商店、魔药调配和封印物系统。等项目进入更完整的数据库或配置表阶段，可以升级为更结构化的写法：

```json
{
  "item_id": "artifact_2_049_antigonus_family_puppet",
  "item_type": "sealed_artifact",
  "trade": {
    "allowed": false,
    "channels": [],
    "legal_status": "restricted"
  },
  "equipment": {
    "slot": "artifact",
    "requires_containment": true,
    "leakage_when_equipped": true
  },
  "containment": {
    "required": true,
    "current_state": "contained",
    "methods": [
      {
        "method_id": "seal_isolated_storage",
        "required_items": [],
        "success_rate": 0.82
      }
    ]
  },
  "type_data": {
    "artifact_rank": "2",
    "danger_level": 78,
    "stability": 42
  }
}
```

建议后续拆分的结构：

| 表或配置 | 用途 |
| --- | --- |
| `items` | 道具主表 |
| `item_effects` | 正面效果、负面效果、触发条件 |
| `item_trade_rules` | 价格、交易渠道、地区限制、阵营要求 |
| `item_equipment_rules` | 装备槽、属性修正、耐久、装备条件 |
| `item_containment_rules` | 封印方法、维护周期、突破风险 |
| `item_sources` | 掉落、商店、任务、地图来源 |
| `item_recipes` | 制作、加工、魔药调配配方 |

后续强校验规则：

- `item_id` 必须唯一。
- `item_type` 必须属于允许枚举。
- `is_equippable = true` 时必须有 `equip_slot`。
- `item_type = sealed_artifact` 时必须有 `containment_method` 或后续结构化 `containment`。
- `item_type = quest_item` 时默认 `is_tradeable = false`。
- 高风险封印物默认不可交易。
- `stack_limit = 1` 的物品在背包中不可堆叠。
- 所有从旧表迁移来的数据必须保留 `source_table` 和 `source_id`。

## 10. 更新流程

当材料或封印物源数据发生变化时，运行：

```powershell
python -X utf8 "D:\github\Lord of the Mysteries\tools\generate_items_database.py"
```

然后检查：

1. `data/items.json` 是否能正常解析。
2. `item_id` 是否唯一。
3. `item_type` 是否都在允许枚举中。
4. `is_tradeable` 和 `is_equippable` 是否符合设计预期。
5. 高风险封印物是否默认不可交易。

## 11. 总结

`items.json` 是项目进入可开发阶段的重要桥接表。它不取代材料表和封印物表，而是把原始资料转译成游戏系统能直接使用的道具层数据。

后续如果要做商店、背包、装备、任务奖励、魔药调配 UI 或封印物收容界面，都应该优先读取 `items.json`。
