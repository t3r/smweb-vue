<script setup>
  import { useRouter, useRoute } from 'vue-router';
  import { profile } from '../profile.js';

  const props = defineProps(["code"]);

  const router = useRouter();
  const route = useRoute();

  profile.user =  JSON.parse(atob(props.code));

  if( profile.user.id ) {
    router.push({
      name: 'Author',
      params: { id: profile.user.id },
    })
  } else {
    router.push({
      name: 'home',
    })
  }
  
</script>
<template>
</template>
