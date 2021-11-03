import { DELETE_POST, FETCH_POST } from "@/graphql/post";
import { usernameWithDomain } from "@/types/actor";
import { IPost } from "@/types/post.model";
import { Component, Vue } from "vue-property-decorator";
import RouteName from "../router/name";

@Component({
  apollo: {
    post: {
      query: FETCH_POST,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          slug: this.slug,
        };
      },
      skip() {
        return !this.slug;
      },
      error({ graphQLErrors }) {
        this.handleErrors(graphQLErrors);
      },
    },
  },
})
export default class PostMixin extends Vue {
  post!: IPost;

  RouteName = RouteName;

  protected async openDeletePostModal(): Promise<void> {
    this.$buefy.dialog.confirm({
      type: "is-danger",
      title: this.$t("Delete post") as string,
      message: this.$t(
        "Are you sure you want to delete this post? This action cannot be reverted."
      ) as string,
      onConfirm: () => this.deletePost(),
    });
  }

  async deletePost(): Promise<void> {
    const { data } = await this.$apollo.mutate({
      mutation: DELETE_POST,
      variables: {
        id: this.post.id,
      },
    });
    if (data && this.post.attributedTo) {
      this.$router.push({
        name: RouteName.POSTS,
        params: {
          preferredUsername: usernameWithDomain(this.post.attributedTo),
        },
      });
    }
  }

  handleErrors(errors: any[]): void {
    if (errors.some((error) => error.status_code === 404)) {
      this.$router.replace({ name: RouteName.PAGE_NOT_FOUND });
    }
  }
}
