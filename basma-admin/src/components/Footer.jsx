// src/components/Footer.jsx
import React from 'react';
import { Box, Typography } from '@mui/material';

const Footer = () => {
  return (
    <Box
      component="footer"
      sx={{
        mt: 2,
        py: 1,
        textAlign: 'center',
        fontSize: 12,
        color: 'text.secondary',
      }}
    >
      <Typography variant="body2">
        © {new Date().getFullYear()} تطبيق بصمة - لوحة التحكم الإدارية
      </Typography>
    </Box>
  );
};

export default Footer;
