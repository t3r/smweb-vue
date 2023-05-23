<script setup>
import { profile } from '../profile.js';
import { useRouter } from 'vue-router';

const router = useRouter();

function click() {
  profile.logout();
  window.location.href = '/auth/logout';
}
</script>
<template>
  <main>
    <h1>Log out</h1>
    <p>Please press the button below log out. You will still be able to browse the database anonymously.
    </p>
    <p>
      <a class="btn btn-primary" @click="click"><i class="bi bi-box-arrow-right">&nbsp;Logout</i></a>
    </p>
  </main>
</template>
