<script setup>
import { RouterLink, RouterView } from 'vue-router'
import { watch, ref, onMounted } from 'vue';
import SMApi from './services/smapi.js';

import { profile } from './profile.js';
const isAuthenticated = ref(false);

watch( profile, (v) => {
  isAuthenticated.value = profile.isAuthenticated();
});

onMounted(() => {
  const { data, error } = SMApi.getMe();
  watch( data, (d) => {
    profile.user = d;
  });
});

</script>

<template>
<nav class="navbar fixed-top navbar-expand-lg bg-light">
  <div class="container-fluid">
    <router-link class="navbar-brand" to="/">
      <img src="/FlightGear_logo.svg" alt="FlightGear" width="30" height="24">
    </router-link>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarSupportedContent">
      <ul class="navbar-nav me-auto mb-2 mb-lg-0">
        <li class="nav-item">
          <router-link class="nav-link" to="/models">Models</router-link>
        </li>
        <li class="nav-item">
          <router-link class="nav-link" to="/objects">Objects</router-link>
        </li>
        <li class="nav-item">
          <router-link class="nav-link" to="/authors">Authors</router-link>
        </li>
        <li class="nav-item dropdown">
          <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">
            Contribute
          </a>
          <ul class="dropdown-menu wide-dropdown">
            <li><router-link class="nav-link" to="/contrib/object/add">Add a New Object Position</router-link></li>
            <li><router-link class="nav-link" to="/contrib/object/import">Massive Import of Objects</router-link></li>
            <li><router-link class="nav-link" to="/contrib/object/delete">Delete a Single Object Position</router-link></li>
            <li><router-link class="nav-link" to="/contrib/object/update">Update Object Geodata</router-link></li>
            <li><hr class="dropdown-divider"></li>
            <li><router-link class="nav-link" to="/contrib/model/add">Add a new Model </router-link></li>
            <li><router-link class="nav-link" to="/contrib/model/update">Update existing Model </router-link></li>
            <li><hr class="dropdown-divider"></li>
            <li><router-link class="nav-link" to="/contribs">Show Pending Contributions</router-link></li>
          </ul>
        </li>
      </ul>
      <form class="d-flex" role="search">
        <input class="form-control me-2" type="search" placeholder="Search" aria-label="Search" disabled>
        <button class="btn btn-outline-secondary" type="submit" disabled>Search</button>
      </form>

      <ul class="d-flex navbar-nav">
        <li v-if="isAuthenticated" class="nav-item dropdown">
          <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">
            <i class="bi bi-person-fill"></i>
          </a>
          <ul class="dropdown-menu">
            <li>Profile</li>
            <li>My Models</li>
            <li><hr class="dropdown-divider"></li>
            <li><router-link class="nav-link" aria-label="Logout" title="Logout" to="/logout">Logout</router-link></li>
          </ul>
        </li>
        <li v-else class="nav-item dropdown">
          <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">
            <i class="bi bi-person"></i>
          </a>
          <ul class="dropdown-menu">
            <li><router-link class="nav-link" aria-label="Login" title="Login" to="/login">Login..</router-link></li>
          </ul>
        </li>
        <li>
          <a class="nav-link" aria-label="github" target="_blank" title="fork me on github!" href="https://github.com/t3r/smweb-vue"><i class="bi bi-github"></i></a>
        </li>
      </ul>
      
    </div>
  </div>
</nav>
<router-view></router-view>
<footer class="bg-light text-center fixed-bottom">
<small class="text-muted">Models © by their respective author. This website © Torsten Dreyer 2023. 
     If in doubt, ask at <a href="https://sourceforge.net/p/flightgear/mailman/flightgear-devel/">the flightgear-devel mailing list.</a></small>
</footer>
</template>

<style scoped>
.wide-dropdown {
  min-width: 20rem;
}
</style>
