import { IActor } from "@/types/actor";
import { ActorType } from "@/types/enums";
import { Component, Vue, Ref } from "vue-property-decorator";
import VueRouter from "vue-router";
const { isNavigationFailure, NavigationFailureType } = VueRouter;

@Component
export default class RelayMixin extends Vue {
  @Ref("table") readonly table!: any;

  toggle(row: Record<string, unknown>): void {
    this.table.toggleDetails(row);
  }

  protected async pushRouter(
    routeName: string,
    args: Record<string, string>
  ): Promise<void> {
    try {
      await this.$router.push({
        name: routeName,
        query: { ...this.$route.query, ...args },
      });
    } catch (e) {
      if (isNavigationFailure(e, NavigationFailureType.redirected)) {
        throw Error(e.toString());
      }
    }
  }

  static isInstance(actor: IActor): boolean {
    return (
      actor.type === ActorType.APPLICATION &&
      (actor.preferredUsername === "relay" ||
        actor.preferredUsername === actor.domain)
    );
  }
}
