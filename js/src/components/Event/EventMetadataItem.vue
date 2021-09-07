<template>
  <div class="card card-content">
    <div class="media">
      <div class="media-left">
        <img
          v-if="
            metadataItem.icon && metadataItem.icon.substring(0, 7) === 'mz:icon'
          "
          :src="`/img/${metadataItem.icon.substring(8)}_monochrome.svg`"
          width="24"
          height="24"
          alt=""
        />

        <b-icon v-else-if="metadataItem.icon" :icon="metadataItem.icon" />
        <b-icon v-else icon="help-circle" />
      </div>
      <div class="media-content">
        <b>{{ metadataItem.title || metadataItem.label }}</b>
        <br />
        <small>
          {{ metadataItem.description }}
        </small>
        <div
          v-if="
            metadataItem.type === EventMetadataType.STRING &&
            metadataItem.keyType === EventMetadataKeyType.CHOICE &&
            metadataItem.choices
          "
        >
          <b-field v-for="(value, key) in metadataItem.choices" :key="key">
            <b-radio v-model="metadataItemValue" :native-value="key">{{
              value
            }}</b-radio>
          </b-field>
        </div>
        <b-field
          v-else-if="
            metadataItem.type === EventMetadataType.STRING &&
            metadataItem.keyType == EventMetadataKeyType.URL
          "
        >
          <b-input
            @blur="validatePattern"
            ref="urlInput"
            type="url"
            :pattern="
              metadataItem.pattern ? metadataItem.pattern.source : undefined
            "
            :validation-message="$t(`This URL doesn't seem to be valid`)"
            required
            v-model="metadataItemValue"
            :placeholder="metadataItem.placeholder"
          />
        </b-field>
        <b-field v-else-if="metadataItem.type === EventMetadataType.STRING">
          <b-input
            v-model="metadataItemValue"
            :placeholder="metadataItem.placeholder"
          />
        </b-field>
        <b-field v-else-if="metadataItem.type === EventMetadataType.INTEGER">
          <b-numberinput v-model="metadataItemValue" />
        </b-field>
        <b-field v-else-if="metadataItem.type === EventMetadataType.BOOLEAN">
          <b-checkbox v-model="metadataItemValue">
            {{
              metadataItemValue === "true"
                ? metadataItem.choices["true"]
                : metadataItem.choices["false"]
            }}
          </b-checkbox>
        </b-field>
      </div>
      <b-button
        icon-left="close"
        @click="$emit('removeItem', metadataItem.key)"
      />
    </div>
  </div>
</template>
<script lang="ts">
import { EventMetadataKeyType, EventMetadataType } from "@/types/enums";
import { IEventMetadataDescription } from "@/types/event-metadata";
import { PropType } from "vue";
import { Component, Prop, Ref, Vue } from "vue-property-decorator";

@Component
export default class EventMetadataItem extends Vue {
  @Prop({ type: Object as PropType<IEventMetadataDescription>, required: true })
  value!: IEventMetadataDescription;

  EventMetadataType = EventMetadataType;
  EventMetadataKeyType = EventMetadataKeyType;

  @Ref("urlInput") readonly urlInput!: any;

  get metadataItem(): IEventMetadataDescription {
    return this.value;
  }

  get metadataItemValue(): string {
    return this.metadataItem.value;
  }

  set metadataItemValue(value: string) {
    if (this.validate(value)) {
      this.$emit("input", { ...this.metadataItem, value: value.toString() });
    }
  }

  validatePattern(): void {
    this.urlInput.checkHtml5Validity();
  }

  private validate(value: string): boolean {
    if (this.metadataItem.keyType === EventMetadataKeyType.URL) {
      try {
        const url = new URL(value);
        if (!["http:", "https:", "mailto:"].includes(url.protocol))
          return false;
        if (this.metadataItem.pattern) {
          return value.match(this.metadataItem.pattern) !== null;
        }
      } catch {
        return false;
      }
    }
    return true;
  }
}
</script>
<style lang="scss" scoped>
.card .media {
  align-items: center;

  & > button {
    margin-left: 1rem;
  }
}
</style>
