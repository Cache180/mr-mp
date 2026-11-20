<template>
  <section class="login-layout">
    <article class="login-popup">
      <div class="mr-logo" role="img" aria-label="MR Multiplayer">
        <span class="mr-logo-mark">MR</span> Multiplayer
      </div>

      <p v-if="state.loginError.value && hasTriedToLogin" class="error-notice" role="alert">{{ state.loginError.value }}</p>
      <p v-else-if="state.loginMessage.value && hasTriedToLogin" class="ok-notice" role="status">{{ state.loginMessage.value }}</p>

      <div class="input-group">
        <label for="beammp-login-username">Nombre de piloto</label>
        <div class="input-shell" :class="{ invalid: showInvalid }">
          <input
            id="beammp-login-username"
            v-model="pilotName"
            v-bng-text-input
            type="text"
            autocomplete="off"
            autocapitalize="none"
            spellcheck="false"
            aria-describedby="beammp-login-help"
            :aria-invalid="showInvalid"
            @keyup.enter="submitLogin"
          />
        </div>
        <p id="beammp-login-help" class="help-text" :class="{ invalid: showInvalid }">{{ PILOT_NAME_HELP }}</p>
      </div>

      <div class="actions">
        <BngButton :disabled="!nameValid" @click="submitLogin">Entrar</BngButton>
      </div>
    </article>
  </section>
</template>

<script setup>
import { computed, ref, watch } from "vue"
import { useRouter } from "vue-router"
import { BngButton } from "@/common/components/base"
import { vBngTextInput } from "@/common/directives"
import { BEAMMP_SERVERS_ROUTE_NAME, PILOT_NAME_HELP } from "../shared/constants.js"
import { useBeamMPState } from "../shared/beammpState.js"

const router = useRouter()
const pilotName = ref("")
const hasTriedToLogin = ref(false)
const { isValidPilotName, login, state } = useBeamMPState()

const nameValid = computed(() => isValidPilotName(pilotName.value))
// Solo se marca en rojo cuando ya hay algo escrito y no cumple la regla.
const showInvalid = computed(() => pilotName.value.trim().length > 0 && !nameValid.value)

async function submitLogin() {
  if (!nameValid.value) return
  hasTriedToLogin.value = true
  await login(pilotName.value)
}

watch(() => state.loggedIn.value, value => {
  if (value) router.replace({ name: BEAMMP_SERVERS_ROUTE_NAME })
}, { immediate: true })
</script>

<style scoped lang="scss">
.login-layout {
  min-height: min(40rem, 70vh);
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0;
  margin: 0;
  overflow: hidden;
  position: relative;
}

.login-popup {
  width: min(36rem, 96%);
  padding: 1rem;
  border-radius: var(--bng-corners-3);
  border: 2px solid rgba(var(--bng-cool-gray-600-rgb), 0.95);
  background: linear-gradient(145deg, rgba(29, 29, 29, 0.92), rgba(20, 20, 20, 0.9));
  display: flex;
  flex-direction: column;
  gap: 0.7rem;
  color: var(--bng-off-white);
}

// Logo provisional de texto (el definitivo lo decide Muertazos Racing).
.mr-logo {
  margin: 0 auto 0.25rem;
  font-size: 2rem;
  font-weight: 800;
  letter-spacing: 0.04em;
  text-align: center;
}

.mr-logo-mark {
  color: var(--bng-orange-400);
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;

  label {
    font-size: 0.85rem;
    font-weight: 600;
    color: var(--bng-cool-gray-100);
  }
}

.input-shell {
  display: flex;
  min-height: 2.7rem;
  align-items: stretch;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.22);
  border-radius: var(--bng-corners-1);
  background: rgba(7, 10, 14, 0.78);
  transition: border-color 120ms ease, box-shadow 120ms ease;

  &:hover {
    border-color: rgba(255, 255, 255, 0.42);
  }

  &:focus-within {
    border-color: var(--bng-orange-500);
    box-shadow: 0 0 0 0.13rem rgba(var(--bng-orange-500-rgb), 0.32);
  }

  &.invalid {
    border-color: var(--bng-add-red-500);
  }

  input {
    flex: 1;
    min-width: 0;
    padding: 0.55rem 0.7rem;
    border: 0;
    outline: 0;
    color: var(--bng-off-white);
    background: transparent;
    font: inherit;

    &:-webkit-autofill {
      -webkit-text-fill-color: var(--bng-off-white);
      box-shadow: 0 0 0 1000px rgb(12, 15, 20) inset;
    }
  }
}

.help-text {
  margin: 0;
  font-size: 0.85rem;
  color: var(--bng-cool-gray-100);

  &.invalid {
    color: var(--bng-add-red-400);
  }
}

.actions {
  justify-content: center;
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;

  :deep(button),
  :deep(.bng-button) {
    margin: 0;
  }
}

.error-notice,
.ok-notice {
  font-weight: 600;
  padding: 0.5rem 0.75rem;
  border-radius: var(--bng-corners-1);
  text-align: center;
  margin: 0.25rem 0;
}

.error-notice {
  color: var(--bng-add-red-400);
  background: rgba(var(--bng-add-red-500-rgb), 0.1);
  border: 1px solid rgba(var(--bng-add-red-500-rgb), 0.3);
}

.ok-notice {
  color: var(--bng-add-green-400);
  background: rgba(var(--bng-add-green-550-rgb), 0.1);
  border: 1px solid rgba(var(--bng-add-green-550-rgb), 0.3);
}

@media (max-width: 680px) {
  .actions {
    > * {
      flex: 1 1 100%;
    }
  }
}
</style>
