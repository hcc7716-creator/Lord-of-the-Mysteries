import type { CanonStatus, Id, Rarity, RiskLevel, SourceNote } from "./pathway";

export type GameItemType =
  | "material"
  | "sealed_artifact"
  | "weapon"
  | "consumable"
  | "quest_item";

export type EquipSlot =
  | "weapon"
  | "artifact"
  | "accessory"
  | "tool"
  | null;

export interface GameItem {
  item_id: Id;
  name_cn: string;
  name_en: string;
  item_type: GameItemType;
  rarity: Rarity;
  related_pathway: Id | null;
  related_sequence: number | null;
  source_map: string[];
  obtain_method: string[];
  usage: string;
  positive_effect: string;
  negative_effect: string;
  containment_method: string;
  is_tradeable: boolean;
  is_equippable: boolean;
  equip_slot: EquipSlot;
  stack_limit: number;
  risk_level: RiskLevel;
  artifact_level?: string;
  quest_usage?: Id[];
  source_table: "materials" | "sealed_artifacts" | "manual_item_seed";
  source_id: Id | null;
  gameplay_tags: string[];
  source_note: SourceNote[];
  canon_status: CanonStatus;
  game_adaptation_note: string;
}
