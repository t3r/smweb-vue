import { reactive } from 'vue'

export const profile = reactive({
  user: null,
  logout() {
    this.user = null;
  },
  isAuthenticated() {
    return !!this.user;
  },
  isAdmin() {
    return this.isAuthenticated() && true;
  },
  isAuthor() {
    return this.isAuthenticated() && true;
  },
})
