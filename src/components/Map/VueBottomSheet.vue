<template>
  <div
    :class="[
      'bottom-sheet',
      {
        opened: opened,
        closed: opened === false,
        moving: moving,
      },
    ]"
    v-on="handlers"
    ref="bottomSheet"
    :style="{
      'pointer-events':
        backgroundClickable && clickToClose === false ? 'none' : 'all',
    }"
  >
    <div
      v-if="overlay"
      class="bottom-sheet__backdrop"
      :style="{ background: overlayColor }"
    />
    <div
      :style="[
        { bottom: cardP + 'px', maxWidth: maxWidth, maxHeight: maxHeight },
        { height: isFullScreen ? '100%' : 'auto' },
        { 'pointer-events': 'all' },
      ]"
      :class="[
        'bottom-sheet__card bg-white dark:bg-gray-800',
        { stripe: stripe, square: !rounded },
        effect,
      ]"
      ref="bottomSheetCard"
    >
      <div class="bottom-sheet__pan" ref="pan">
        <div class="bottom-sheet__bar bg-gray-700 dark:bg-gray-400" />
      </div>
      <div
        :style="{ height: contentH }"
        ref="bottomSheetCardContent"
        class="bottom-sheet__content"
      >
        <slot />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import Hammer from "hammerjs";
import { onBeforeUnmount, reactive, ref } from "vue";

const inited = ref(false);
const opened = ref(false);
const contentH = ref("auto");
const hammer = reactive<{
  pan: any;
  content: any;
}>({
  pan: null,
  content: null,
});
const contentScroll = ref(0);
const cardP = ref<number>(0);
const cardH = ref<number>(0);
const moving = ref(false);
const stripe = ref(0);

const props = withDefaults(
  defineProps<{
    overlay?: boolean;
    maxWidth?: string;
    maxHeight?: string;
    clickToClose?: boolean;
    effect?: string;
    rounded?: boolean;
    swipeAble?: boolean;
    isFullScreen?: boolean;
    overlayColor?: string;
    backgroundScrollable?: boolean;
    backgroundClickable?: boolean;
  }>(),
  {
    overlay: true,
    maxWidth: "640px",
    maxHeight: "95%",
    clickToClose: true,
    effect: "fx-default",
    rounded: true,
    swipeAble: true,
    isFullScreen: false,
    overlayColor: "#0000004D",
    backgroundScrollable: false,
    backgroundClickable: false,
  }
);

const emit = defineEmits(["closed", "opened"]);

const bottomSheetCardContent = ref();
const bottomSheetCard = ref();
const pan = ref();

const isIphone = () => {
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  const iPhone = /iPhone/.test(navigator.userAgent) && !window.MSStream;
  const aspect = window.screen.width / window.screen.height;
  return iPhone && aspect.toFixed(3) === "0.462";
};
const move = (event: any, type: any) => {
  if (props.swipeAble) {
    const delta = -event.deltaY;
    if (
      (type === "content" && event.type === "panup") ||
      (type === "content" &&
        event.type === "pandown" &&
        contentScroll.value > 0)
    ) {
      bottomSheetCardContent.value.scrollTop = contentScroll.value + delta;
    } else if (event.type === "panup" || event.type === "pandown") {
      moving.value = true;
      if (event.deltaY > 0) {
        cardP.value = delta;
      }
    }
    if (event.isFinal) {
      contentScroll.value = bottomSheetCardContent.value.scrollTop;
      moving.value = false;
      if (cardP.value < -30) {
        opened.value = false;
        cardP.value = (-cardH.value ?? 0) - stripe.value;
        document.body.style.overflow = "";
        emit("closed");
      } else {
        cardP.value = 0;
      }
    }
  }
};
const init = () => {
  return new Promise((resolve) => {
    contentH.value = "auto";
    stripe.value = isIphone() ? 20 : 0;
    cardH.value = bottomSheetCard.value.clientHeight;
    contentH.value = `${cardH.value - pan.value.clientHeight}px`;
    bottomSheetCard.value.style.maxHeight = props.maxHeight;
    cardP.value =
      props.effect === "fx-slide-from-right" ||
      props.effect === "fx-slide-from-left"
        ? 0
        : -cardH.value - stripe.value;
    if (!inited.value) {
      inited.value = true;
      const options = {
        recognizers: [[Hammer.Pan, { direction: Hammer.DIRECTION_VERTICAL }]],
      };
      hammer.pan = new Hammer(pan.value, options as any);
      hammer.pan?.on("panstart panup pandown panend", (e: any) => {
        move(e, "pan");
      });
      hammer.content = new Hammer(bottomSheetCardContent.value, options as any);
      hammer.content?.on("panstart panup pandown panend", (e: any) => {
        move(e, "content");
      });
    }
    setTimeout(() => {
      resolve(undefined);
    }, 100);
  });
};
const open = async () => {
  console.debug("open vue bottom sheet");
  await init();
  opened.value = true;
  cardP.value = 0;

  if (!props.backgroundScrollable) {
    document.body.style.overflow = "hidden";
  }

  emit("opened");
};
const close = () => {
  opened.value = false;
  cardP.value =
    props.effect === "fx-slide-from-right" ||
    props.effect === "fx-slide-from-left"
      ? 0
      : -cardH.value - stripe.value;
  document.body.style.overflow = "";
  emit("closed");
};
const clickOnBottomSheet = (event: any) => {
  if (props.clickToClose) {
    if (
      event.target.classList.contains("bottom-sheet__backdrop") ||
      event.target.classList.contains("bottom-sheet")
    ) {
      close();
    }
  }
};

onBeforeUnmount(() => {
  hammer?.pan?.destroy();
  hammer?.content?.destroy();
});

const handlers = {
  mousedown: clickOnBottomSheet,
  touchstart: clickOnBottomSheet,
};

defineExpose({ open, close });
</script>

<style lang="scss" scoped>
.bottom-sheet {
  z-index: 99999;
  transition: all 0.4s ease;
  position: relative;

  * {
    box-sizing: border-box;
  }

  &__content {
    overflow-y: scroll;
  }

  &__backdrop {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 9999;
    opacity: 0;
    visibility: hidden;
  }

  &__card {
    width: 100%;

    position: fixed;
    border-radius: 14px 14px 0 0;
    left: 50%;
    z-index: 9999;
    margin: 0 auto;

    &.square {
      border-radius: 0;
    }

    &.stripe {
      padding-bottom: 20px;
    }

    &.fx-default {
      transform: translate(-50%, 0);
      transition: bottom 0.3s ease;
    }

    &.fx-fadein-scale {
      transform: translate(-50%, 0) scale(0.7);
      opacity: 0;
      transition: all 0.3s;
    }

    &.fx-slide-from-right {
      transform: translate(100%, 0);
      opacity: 0;
      transition: all 0.3s cubic-bezier(0.25, 0.5, 0.5, 0.9);
    }

    &.fx-slide-from-left {
      transform: translate(-100%, 0);
      opacity: 0;
      transition: all 0.3s cubic-bezier(0.25, 0.5, 0.5, 0.9);
    }
  }

  &__pan {
    padding-bottom: 20px;
    padding-top: 15px;
    height: 38px;
  }

  &__bar {
    display: block;
    width: 50px;
    height: 3px;
    border-radius: 14px;
    margin: 0 auto;
    cursor: pointer;
  }

  &.closed {
    opacity: 0;
    visibility: hidden;

    .bottom-sheet__backdrop {
      animation: hide 0.3s ease;
    }
  }

  &.moving {
    .bottom-sheet__card {
      transition: none;
    }
  }

  &.opened {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;

    .bottom-sheet__backdrop {
      animation: show 0.3s ease;
      opacity: 1;
      visibility: visible;
    }

    .bottom-sheet__card {
      &.fx-fadein-scale {
        transform: translate(-50%, 0) scale(1);
        opacity: 1;
      }

      &.fx-slide-from-right {
        transform: translate(-50%, 0);
        opacity: 1;
      }

      &.fx-slide-from-left {
        transform: translate(-50%, 0);
        opacity: 1;
      }
    }
  }
}

@keyframes show {
  0% {
    opacity: 0;
    visibility: hidden;
  }

  100% {
    opacity: 1;
    visibility: visible;
  }
}

@keyframes hide {
  0% {
    opacity: 1;
    visibility: visible;
  }

  100% {
    opacity: 0;
    visibility: hidden;
  }
}
</style>
