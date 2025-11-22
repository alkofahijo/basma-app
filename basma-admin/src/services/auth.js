// src/services/auth.js
import api from './api';

export async function loginAdmin(username, password) {
  const res = await api.post('/admin/login', { username, password });
  const token = res.data.access_token;
  localStorage.setItem('admin_token', token);
  return token;
}

export function logoutAdmin() {
  localStorage.removeItem('admin_token');
}

export function isLoggedIn() {
  return !!localStorage.getItem('admin_token');
}
