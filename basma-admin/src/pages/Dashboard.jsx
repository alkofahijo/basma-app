// src/pages/Dashboard.jsx
import React from 'react';
import { Box, Toolbar, Container } from '@mui/material';
import Header from '../components/Header';
import Footer from '../components/Footer';

const DashboardLayout = ({ children }) => {
  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        bgcolor: (theme) =>
          theme.palette.mode === 'light'
            ? 'linear-gradient(180deg, #f5f7fb 0%, #eef2f7 40%, #e3edf7 100%)'
            : theme.palette.background.default,
        direction: 'rtl',
      }}
    >
      {/* شريط علوي */}
      <Header />

      {/* المحتوى الرئيسي */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        {/* مساحة تحت AppBar */}
        <Toolbar />

        <Container
          maxWidth="xl"
          sx={{
            mt: 3,
            mb: 3,
          }}
        >
          {/* غلاف للمحتوى بشكل Card */}
          <Box
            sx={{
              borderRadius: 3,
              p: 3,
              minHeight: '60vh',
              bgcolor: 'background.paper',
              boxShadow: (theme) =>
                theme.palette.mode === 'light'
                  ? '0 10px 30px rgba(15, 23, 42, 0.08)'
                  : '0 10px 30px rgba(0, 0, 0, 0.7)',
              display: 'flex',
              flexDirection: 'column',
              gap: 2,
            }}
          >
            {children}
          </Box>
        </Container>
      </Box>

      {/* الفوتر في الأسفل دائمًا */}
      <Footer />
    </Box>
  );
};

export default DashboardLayout;
