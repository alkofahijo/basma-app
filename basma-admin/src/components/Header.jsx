// src/components/Header.jsx
import React from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  IconButton,
  Box,
  Button,
} from '@mui/material';
import LogoutIcon from '@mui/icons-material/Logout';
import DashboardIcon from '@mui/icons-material/Dashboard';
import { useNavigate, useLocation } from 'react-router-dom';
import { logoutAdmin } from '../services/auth';

const Header = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logoutAdmin();
    navigate('/login');
  };

  const navItems = [
    { label: 'المستخدمون', path: '/users' },
    { label: 'البلاغات', path: '/reports' },
    { label: 'الحسابات', path: '/accounts' },
  ];

  return (
    <AppBar
      position="fixed"
      color="primary" // نفس لون زر "مستخدم جديد" (primary.main)
      elevation={4}
      sx={{
        borderRadius: 0, // بدون أي حواف دائرية
        direction: 'rtl',
      }}
    >
      <Toolbar
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 2,
        }}
      >
        {/* يمين الهيدر: اللوجو / العنوان */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <DashboardIcon sx={{ color: '#fff' }} />
          <Box>
            <Typography variant="h6" component="div" sx={{ color: '#fff' }}>
              لوحة التحكم 
            </Typography>
          
          </Box>
        </Box>

        {/* مسافة مرنة في المنتصف */}
        <Box sx={{ flexGrow: 1 }} />

        {/* عناصر القائمة (بدون أيقونات) */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            gap: 1,
          }}
        >
          {navItems.map((item) => {
            const isActive =
              location.pathname === item.path ||
              location.pathname.startsWith(item.path + '/');

            return (
              <Button
                key={item.path}
                onClick={() => navigate(item.path)}
                sx={{
                  borderRadius: 999,
                  px: 2.8,
                  py: 0.7,
                  fontSize: 14,
                  color: '#fff', // نص أبيض
                  textTransform: 'none',
                  ...(isActive && {
                    bgcolor: 'rgba(255,255,255,0.16)',
                    '&:hover': { bgcolor: 'rgba(255,255,255,0.24)' },
                  }),
                }}
              >
                {item.label}
              </Button>
            );
          })}
        </Box>

        {/* يسار الهيدر: زر تسجيل الخروج */}
        <Box sx={{ ml: 1 }}>
          <IconButton
            color="inherit"
            onClick={handleLogout}
            sx={{
              borderRadius: 2,
              bgcolor: 'rgba(0,0,0,0.18)',
              '&:hover': { bgcolor: 'rgba(0,0,0,0.3)' },
            }}
          >
            <LogoutIcon />
          </IconButton>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Header;
