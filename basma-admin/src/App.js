// src/App.js
import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";

import Login from "./pages/Login";
import Users from "./pages/Users";
import Reports from "./pages/Reports";
import Accounts from "./pages/Accounts";
import PrivateRoute from "./components/PrivateRoute";

function App() {
  return (
    <Routes>
      {/* صفحة تسجيل الدخول */}
      <Route path="/login" element={<Login />} />

      {/* صفحة المستخدمين (محميّة) */}
      <Route
        path="/users"
        element={
          <PrivateRoute>
            <Users />
          </PrivateRoute>
        }
      />

      {/* صفحة البلاغات (محميّة) */}
      <Route
        path="/reports"
        element={
          <PrivateRoute>
            <Reports />
          </PrivateRoute>
        }
      />

      {/* صفحة الحسابات (محميّة) */}
      <Route
        path="/accounts"
        element={
          <PrivateRoute>
            <Accounts />
          </PrivateRoute>
        }
      />

      {/* أي مسار آخر → تحويل إلى /users إذا كان مسجلاً الدخول أو إلى /login */}
      <Route path="*" element={<Navigate to="/users" replace />} />
    </Routes>
  );
}

export default App;
