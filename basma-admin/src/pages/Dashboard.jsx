// src/pages/Dashboard.jsx
import React from 'react';
import { Box, Toolbar, Container } from '@mui/material';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import Footer from '../components/Footer';

const drawerWidth = 220;

const DashboardLayout = ({ children }) => {
  return (
    <Box sx={{ display: 'flex', direction: 'rtl' }}>
      <Header />
      <Sidebar />
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          mr: `${drawerWidth}px`, // because sidebar is on the right
          minHeight: '100vh',
          backgroundColor: '#f5f5f5',
        }}
      >
        <Toolbar />
        <Container maxWidth="xl">
          {children}
          <Footer />
        </Container>
      </Box>
    </Box>
  );
};

export default DashboardLayout;
