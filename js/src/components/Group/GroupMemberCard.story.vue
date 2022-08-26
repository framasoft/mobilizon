<template>
  <Story>
    <Variant title="simple member">
      <div class="p-5">
        <GroupMemberCard :member="basicMember" />
      </div>
    </Variant>
    <Variant title="moderator">
      <div class="p-5">
        <GroupMemberCard :member="moderatorMember" />
      </div>
    </Variant>
    <Variant title="administrator">
      <div class="p-5">
        <GroupMemberCard :member="adminMember" />
      </div>
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import { IActor } from "@/types/actor";
import { IMember } from "@/types/actor/member.model";
import { MemberRole } from "@/types/enums";
import GroupMemberCard from "./GroupMemberCard.vue";
const baseActorAvatar = {
  id: "",
  name: "",
  alt: "",
  metadata: {},
  url: "https://social.tcit.fr/system/accounts/avatars/000/000/001/original/a28c50ce5f2b13fd.jpg",
};

const basePerson: IActor = {
  name: "Thomas Citharel",
  preferredUsername: "tcit",
  avatar: baseActorAvatar,
  domain: null,
  url: "",
  summary: "",
  suspended: false,
};

const basicGroup: IActor = {
  name: "Framasoft",
  preferredUsername: "framasoft",
  avatar: {
    url: "https://mobilizon.fr/media/ff5b2d425fb73e17fcbb56a1a032359ee0b21453c11af59e103e783817a32fdf.png?name=framasoft%27s%20avatar.png",
  },
  domain: "mobilizon.fr",
  url: "",
  summary: `<p><strong>La Fediverse</strong>, <strong>c'est la <em><u>Féd</u>ération qui englobe l'Un<u>ivers</u> des réseaux sociaux libres et décentralisés,</em> </strong>dont Mobilizon (évènements), Mastodon (microblog), Peertube (vidéos), Pixelfed (photos), Funkwhale (musique), Matrix (messagerie instantanée)... et tant d'autres font partie.</p><p><strong>Et "La Fediverse <em>Nantaise</em>" est un collectif cherchant à faire connaître localement tout le potentiel de ces réseaux ! :-)</strong></p>`,
  suspended: false,
  members: { total: 0, elements: [] },
  followers: { total: 0, elements: [] },
};

const basicMember: IMember = {
  parent: basicGroup as IActor,
  actor: basePerson,
  role: MemberRole.MEMBER,
};

const moderatorMember: IMember = {
  parent: basicGroup,
  actor: basePerson,
  role: MemberRole.MODERATOR,
};

const adminMember: IMember = {
  parent: basicGroup,
  actor: basePerson,
  role: MemberRole.ADMINISTRATOR,
};

// const groupWithMedia = {
//   ...basicGroup,
//   banner: {
//     url: "https://mobilizon.fr/media/7b340fe641e7ad711ebb6f8821b5ce824992db08701e37ebb901c175436aaafc.jpg?name=framasoft%27s%20banner.jpg",
//   },
//   avatar: {
//     url: "https://mobilizon.fr/media/ff5b2d425fb73e17fcbb56a1a032359ee0b21453c11af59e103e783817a32fdf.png?name=framasoft%27s%20avatar.png",
//   },
// };

// const groupWithFollowersOrMembers = {
//   ...groupWithMedia,
//   members: { total: 2, elements: [] },
//   followers: { total: 5, elements: [] },
// };
</script>
