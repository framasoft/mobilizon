<template>
    <div class="participation-button">
        <b-dropdown aria-role="list" position="is-bottom-left" v-if="participation && participation.role === ParticipantRole.PARTICIPANT">
            <button class="button is-success" type="button" slot="trigger">
                <template>
                    <span>{{ $t('I participate') }}</span>
                </template>
                <b-icon icon="menu-down"></b-icon>
            </button>

            <!--                <b-dropdown-item :value="false" aria-role="listitem">-->
            <!--                  {{ $t('Change my identity…')}}-->
            <!--                </b-dropdown-item>-->

            <b-dropdown-item :value="false" aria-role="listitem" @click="confirmLeave">
                {{ $t('Cancel my participation…')}}
            </b-dropdown-item>
        </b-dropdown>

        <div v-else-if="participation && participation.role === ParticipantRole.NOT_APPROVED">
            <b-dropdown aria-role="list" position="is-bottom-left" class="dropdown-disabled">
                <button class="button is-success" type="button" slot="trigger">
                    <template>
                        <span>{{ $t('I participate') }}</span>
                    </template>
                    <b-icon icon="menu-down"></b-icon>
                </button>

                <!--                <b-dropdown-item :value="false" aria-role="listitem">-->
                <!--                  {{ $t('Change my identity…')}}-->
                <!--                </b-dropdown-item>-->

                <b-dropdown-item :value="false" aria-role="listitem" @click="confirmLeave">
                    {{ $t('Cancel my participation request…')}}
                </b-dropdown-item>
            </b-dropdown>
            <small>{{ $t('Participation requested!')}}</small><br />
            <small>{{ $t('Waiting for organization team approval.')}}</small>
        </div>

        <b-dropdown aria-role="list" position="is-bottom-left" v-if="!participation">
            <button class="button is-primary" type="button" slot="trigger">
                <template>
                    <span>{{ $t('Participate') }}</span>
                </template>
                <b-icon icon="menu-down"></b-icon>
            </button>

            <b-dropdown-item :value="true" aria-role="listitem" @click="joinEvent(currentActor)">
                <div class="media">
                    <div class="media-left">
                        <figure class="image is-32x32" v-if="currentActor.avatar">
                            <img class="is-rounded" :src="currentActor.avatar.url" alt="" />
                        </figure>
                    </div>
                    <div class="media-content">
                        <span>{{ $t('with {identity}', {identity: currentActor.preferredUsername }) }}</span>
                    </div>
                </div>
            </b-dropdown-item>

            <b-dropdown-item :value="false" aria-role="listitem" @click="joinModal">
                {{ $t('with another identity…')}}
            </b-dropdown-item>
        </b-dropdown>
    </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { IParticipant, ParticipantRole } from '@/types/event.model';
import { IPerson } from '@/types/actor';

@Component
export default class ParticipationButton extends Vue {
  @Prop({ required: true }) participation!: IParticipant;
  @Prop({ required: true }) currentActor!: IPerson;

  ParticipantRole = ParticipantRole;

  joinEvent(actor: IPerson) {
    this.$emit('joinEvent', actor);
  }

  joinModal() {
    this.$emit('joinModal');
  }

  confirmLeave() {
    this.$emit('confirmLeave');
  }

}
</script>

<style lang="scss">
    .participation-button {
        .dropdown {
            display: flex;
            justify-content: flex-end;

            &.dropdown-disabled button {
                opacity: 0.5;
            }
        }

        button {
            font-size: 1.5rem;
        }
    }
</style>