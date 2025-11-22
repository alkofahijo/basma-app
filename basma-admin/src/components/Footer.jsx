// src/components/Footer.jsx
import React from 'react';
import { Box, Typography } from '@mui/material';

const Footer = () => {
  const year = new Date().getFullYear();

  return (
    <Box
      component="footer"
      sx={{
        mt: 'auto',
        py: 2,
        px: 3,
        borderTop: (theme) => `1px solid ${theme.palette.divider}`,
        textAlign: 'center',
        bgcolor: (theme) =>
          theme.palette.mode === 'light'
            ? '#fafafa'
            : theme.palette.background.paper,
      }}
    >
      <Typography
        variant="body2"
        sx={{ color: 'text.secondary', fontSize: 13 }}
      >
        © {year} تطبيق بصمة – لوحة التحكم الإدارية
      </Typography>
    </Box>
  );
};

export default Footer;
