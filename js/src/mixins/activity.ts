import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { IActivity } from "@/types/activity.model";
import { IActor } from "@/types/actor";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component({
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class ActivityMixin extends Vue {
  @Prop({ required: true, type: Object }) activity!: IActivity;
  currentActor!: IActor;

  get subjectParams(): Record<string, string> {
    return this.activity.subjectParams.reduce(
      (acc: Record<string, string>, { key, value }) => {
        acc[key] = value;
        return acc;
      },
      {}
    );
  }

  get isAuthorCurrentActor(): boolean {
    return (
      this.activity.author.id === this.currentActor.id &&
      this.currentActor.id !== undefined
    );
  }
}
