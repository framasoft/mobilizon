import {
  EventMetadataCategories,
  EventMetadataKeyType,
  EventMetadataType,
} from "./enums";

export interface IEventMetadata {
  key: string;
  title?: string;
  value: string;
  type: EventMetadataType;
}

export interface IEventMetadataDescription extends IEventMetadata {
  icon?: string;
  placeholder?: string;
  description: string;
  choices?: Record<string, string>;
  keyType: EventMetadataKeyType;
  pattern?: RegExp;
  label: string;
  category: EventMetadataCategories;
}
