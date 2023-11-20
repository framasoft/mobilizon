<template>
  <div class="activity-item">
    <span>
      <o-skeleton circle width="32px" height="32px"></o-skeleton>
    </span>
    <div class="subject">
      <div class="prose dark:prose-invert">
        <p>
          <o-skeleton active></o-skeleton>
          <o-skeleton active class="datetime"></o-skeleton>
        </p>
      </div>
    </div>
  </div>
</template>
<style lang="scss" scoped>
@import "./activity.scss";
div.activity-item {
  flex: 1;

  .subject {
    flex: 1;
    max-width: 600px;

    .content p > div:last-child {
      max-width: 50px;
    }
  }
}
</style>
