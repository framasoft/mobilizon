<template>
  <div class="activity-item">
    <span>
      <b-skeleton circle width="32px" height="32px"></b-skeleton>
    </span>
    <div class="subject">
      <div class="content">
        <p>
          <b-skeleton active></b-skeleton>
          <b-skeleton active class="datetime"></b-skeleton>
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
