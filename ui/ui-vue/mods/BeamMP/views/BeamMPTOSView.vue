<template>
  <section class="panel">
    <h1>MR Multiplayer</h1>

    <div class="block">
      <!-- license-notice:begin -->
      <p class="license-notice">
        MR Multiplayer esta basado en BeamMP (AGPL-3.0). Codigo fuente:
        <a href="#" @click.prevent="openExternal('https://github.com/Cache180/mr-mp')">github.com/Cache180/mr-mp</a>
      </p>
      <!-- license-notice:end -->
    </div>

    <div class="actions">
      <BngButton @click="proceed">Aceptar</BngButton>
    </div>
  </section>
</template>

<script setup>
import { useRouter } from "vue-router"
import { BngButton } from "@/common/components/base"
import { BEAMMP_LOGIN_ROUTE_NAME } from "../shared/constants.js"
import { useBeamMPState } from "../shared/beammpState.js"

const router = useRouter()
const { acceptTos, openExternal } = useBeamMPState()

function proceed() {
  acceptTos()
  router.push({ name: BEAMMP_LOGIN_ROUTE_NAME })
}
</script>

<style scoped lang="scss">
.panel {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.block {
  padding: 0.8rem;
  border-radius: var(--bng-corners-1);
  background: rgba(255, 255, 255, 0.04);
}

.actions {
  display: flex;
  justify-content: flex-end;
}

p {
  color: var(--bng-cool-gray-100);
}

a {
  color: var(--bng-orange-300);
}
</style>
