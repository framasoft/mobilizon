<template>
  <div v-if="loggedUser">
    <section>
      <div class="setting-title">
        <h2>{{ $t("Participation notifications") }}</h2>
      </div>
      <div class="field">
        <strong>{{
          $t(
            "Mobilizon will send you an email when the events you are attending have important changes: date and time, address, confirmation or cancellation, etc."
          )
        }}</strong>
        <p>
          {{ $t("Other notification options:") }}
        </p>
      </div>
      <div class="field">
        <o-checkbox
          v-model="notificationOnDay"
          @input="updateSetting({ notificationOnDay })"
        >
          <strong>{{ $t("Notification on the day of the event") }}</strong>
          <p>
            {{
              $t(
                "We'll use your timezone settings to send a recap of the morning of the event."
              )
            }}
          </p>
        </o-checkbox>
      </div>
      <p>
        {{
          $t(
            "To activate more notifications, head over to the notification settings."
          )
        }}
      </p>
    </section>
  </div>
</template>
<script lang="ts" setup>
// import { SnackbarProgrammatic as Snackbar } from "buefy";
import { doUpdateSetting, useLoggedUser } from "@/composition/apollo/user";
import { onMounted, ref } from "vue";

const notificationOnDay = ref(true);

const { loggedUser } = useLoggedUser();

const updateSetting = async (
  variables: Record<string, unknown>
): Promise<void> => {
  try {
    doUpdateSetting(variables);
  } catch (e: any) {
    // Snackbar.open({
    //   message: e.message,
    //   variant: "danger",
    //   position: "bottom",
    // });
  }
};

onMounted(() => {
  doUpdateSetting({
    notificationOnDay: true,
    notificationEachWeek: false,
    notificationBeforeEvent: false,
  });
});
</script>
