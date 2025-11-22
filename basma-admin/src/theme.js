// src/theme.js
import { createTheme } from '@mui/material/styles';

const theme = createTheme({
  direction: 'rtl',
  typography: {
    fontFamily: '"Tajawal", "Roboto", "Helvetica", "Arial", sans-serif',
  },
  palette: {
    primary: {
      main: '#039844', // your Flutter primary
    },
    secondary: {
      main: '#00695f',
    },
    background: {
      default: '#f5f5f5',
    },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          textTransform: 'none',
          fontWeight: 600,
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 16,
        },
      },
    },
  },
});

export default theme;
