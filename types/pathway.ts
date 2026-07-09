export type CanonStatus =
  | "novel_confirmed"
  | "book2_confirmed"
  | "official_supplement"
  | "wiki_only"
  | "game_adapted"
  | "original_placeholder";

export type RankStage =
  | "low_sequence"
  | "mid_sequence"
  | "demigod"
  | "angel"
  | "true_god";

export type MaterialType =
  | "main_material"
  | "auxiliary_material"
  | "ritual_material"
  | "special_requirement"
  | "unknown";

export type Rarity =
  | "common"
  | "uncommon"
  | "rare"
  | "epic"
  | "legendary"
  | "mythic"
  | "unknown";

export type AbilityType =
  | "investigation"
  | "combat"
  | "escape"
  | "support"
  | "control"
  | "ritual"
  | "identity"
  | "summon"
  | "miracle"
  | "authority"
  | "passive";

export type RiskLevel =
  | "low"
  | "medium"
  | "high"
  | "extreme"
  | "unknown";

export type SourceNote = string;
export type Id = string;

export interface Pathway {
  pathway_id: Id;
  pathway_name_cn: string;
  pathway_name_en: string;
  base_sequence_name_cn: string;
  base_sequence_name_en: string;
  group: string;
  adjacent_pathways: Id[];
  theme_keywords: string[];
  gameplay_role: string;
  main_mechanics: string[];
  risk_theme: string;
  available_sequences: number[];
  unlock_region: string[];
  source_note: SourceNote[];
  canon_status: CanonStatus;
}

export interface Sequence {
  sequence_id: Id;
  pathway_id: Id;
  sequence_number: number;
  sequence_name_cn: string;
  sequence_name_en: string;
  rank_stage: RankStage;
  role_position: string;
  main_materials: Id[];
  auxiliary_materials: Id[];
  advancement_ritual: Id | null;
  acting_method: string;
  abilities: Id[];
  passive_effects: string[];
  loss_control_risk: string;
  characteristic_id: Id;
  gameplay_tags: string[];
  unlock_conditions: Id[];
  related_quests: Id[];
  source_note: SourceNote[];
  canon_status: CanonStatus;
  game_adaptation_note: string;
}

export interface PotionFormula {
  formula_id: Id;
  sequence_id: Id;
  pathway_id: Id;
  name_cn: string;
  name_en: string;
  main_materials: Id[];
  auxiliary_materials: Id[];
  obtain_methods: Id[];
  base_price_pence: number;
  risk_level: RiskLevel;
  source_note: SourceNote[];
  canon_status: CanonStatus;
}

export interface Material {
  material_id: Id;
  name_cn: string;
  name_en: string;
  material_type: MaterialType;
  rarity: Rarity;
  related_pathway: Id;
  related_sequence: number;
  obtain_method: string[];
  source_region: string[];
  is_core_material: boolean;
  can_be_replaced_by_characteristic: boolean;
  description: string;
  source_note: SourceNote[];
  canon_status: CanonStatus;
}

export interface AbilityCost {
  [resource: string]: number | string;
}

export interface Ability {
  ability_id: Id;
  ability_name_cn: string;
  ability_name_en: string;
  pathway_id: Id;
  unlock_sequence: number;
  ability_type: AbilityType;
  cost: AbilityCost;
  cooldown: number;
  effect_description: string;
  upgrade_effect: string;
  side_effect: string;
  ui_hint: string;
  animation_hint: string;
  gameplay_tags: string[];
  source_note: SourceNote[];
  canon_status: CanonStatus;
  game_adaptation_note: string;
}

export interface Ritual {
  ritual_id: Id;
  pathway_id: Id;
  sequence_number: number;
  ritual_name: string;
  ritual_description: string;
  required_items: Id[];
  required_location: string[];
  required_npc_or_condition: string[];
  success_condition: string;
  failure_result: string;
  loss_control_risk_change: string;
  quest_design_note: string;
  source_note: SourceNote[];
  canon_status: CanonStatus;
}

export interface BeyonderCharacteristic {
  characteristic_id: Id;
  pathway_id: Id;
  sequence_number: number;
  appearance_cn: string;
  appearance_en: string;
  risk_level: RiskLevel;
  mental_imprint: string;
  can_replace_material: boolean;
  storage_requirement: string;
  possible_artifact_result: string[];
  gameplay_effect: string;
  source_note: SourceNote[];
  canon_status: CanonStatus;
}

export interface SealedArtifact {
  artifact_id: Id;
  artifact_name_cn: string;
  artifact_name_en: string;
  artifact_level: string;
  appearance: string;
  positive_effect: string;
  negative_effect: string;
  containment_method: string;
  related_pathway: Id;
  obtain_method: string[];
  quest_usage: Id[];
  can_player_use: boolean;
  risk_level: RiskLevel;
  source_note: SourceNote[];
  canon_status: CanonStatus;
}
