import { Component, Mixins, Vue } from "vue-property-decorator";
import { Person } from "@/types/actor";

// TODO: Refactor into js/src/utils/username.ts
@Component
export default class IdentityEditionMixin extends Mixins(Vue) {
  identity: Person = new Person();

  oldDisplayName: string | null = null;

  autoUpdateUsername(newDisplayName: string | null): void {
    const oldUsername = IdentityEditionMixin.convertToUsername(
      this.oldDisplayName
    );

    if (this.identity.preferredUsername === oldUsername) {
      this.identity.preferredUsername = IdentityEditionMixin.convertToUsername(
        newDisplayName
      );
    }

    this.oldDisplayName = newDisplayName;
  }

  private static convertToUsername(value: string | null) {
    if (!value) return "";

    // https://stackoverflow.com/a/37511463
    return value
      .toLocaleLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/ /g, "_")
      .replace(/[^a-z0-9_]/g, "");
  }

  validateUsername(): boolean {
    return (
      this.identity.preferredUsername ===
      IdentityEditionMixin.convertToUsername(this.identity.preferredUsername)
    );
  }
}
