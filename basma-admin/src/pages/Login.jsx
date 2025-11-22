// src/pages/Login.jsx
import React, { useState } from 'react';
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  CircularProgress,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { loginAdmin } from '../services/auth';
import { useSnackbar } from 'notistack';

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { enqueueSnackbar } = useSnackbar();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!username || !password) {
      enqueueSnackbar('الرجاء إدخال اسم المستخدم وكلمة المرور', { variant: 'warning' });
      return;
    }
    try {
      setLoading(true);
      await loginAdmin(username, password);
      enqueueSnackbar('تم تسجيل الدخول بنجاح', { variant: 'success' });
      navigate('/users');
    } catch (err) {
      console.error(err);
      enqueueSnackbar(
        err?.response?.data?.detail || 'فشل تسجيل الدخول',
        { variant: 'error' }
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        backgroundColor: '#f0f2f5',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        p: 2,
      }}
    >
      <Paper
        elevation={4}
        sx={{
          p: 4,
          maxWidth: 400,
          width: '100%',
        }}
      >
        <Typography variant="h5" mb={2} textAlign="center">
          تسجيل الدخول للوحة التحكم
        </Typography>
        <form onSubmit={handleSubmit}>
          <TextField
            label="اسم المستخدم"
            variant="outlined"
            fullWidth
            margin="normal"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
          />
          <TextField
            label="كلمة المرور"
            type="password"
            variant="outlined"
            fullWidth
            margin="normal"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          <Box mt={2} display="flex" justifyContent="center">
            <Button
              type="submit"
              variant="contained"
              color="primary"
              disabled={loading}
              fullWidth
            >
              {loading ? <CircularProgress size={24} /> : 'دخول'}
            </Button>
          </Box>
        </form>
      </Paper>
    </Box>
  );
};

export default Login;
