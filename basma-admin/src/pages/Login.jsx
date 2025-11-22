// src/pages/Login.jsx
import React, { useState } from 'react';
import {
  Box,
  Card,
  TextField,
  Button,
  Typography,
  CircularProgress,
  CssBaseline,
  Stack,
  FormControl,
  FormLabel,
  FormControlLabel,
  Checkbox,
  Divider,
  Link,
} from '@mui/material';
import { styled } from '@mui/material/styles';
import { useNavigate } from 'react-router-dom';
import { loginAdmin } from '../services/auth';
import { useSnackbar } from 'notistack';

const SignInContainer = styled(Stack)(({ theme }) => ({
  minHeight: '100vh',
  position: 'relative',
  padding: theme.spacing(2),
  [theme.breakpoints.up('sm')]: {
    padding: theme.spacing(4),
  },
  alignItems: 'center',
  justifyContent: 'center',
  '&::before': {
    content: '""',
    display: 'block',
    position: 'absolute',
    zIndex: -1,
    inset: 0,
    backgroundImage:
      'radial-gradient(ellipse at 50% 50%, hsl(210, 100%, 97%), hsl(0, 0%, 100%))',
    backgroundRepeat: 'no-repeat',
  },
}));

const StyledCard = styled(Card)(({ theme }) => ({
  display: 'flex',
  flexDirection: 'column',
  width: '100%',
  padding: theme.spacing(4),
  gap: theme.spacing(2),
  margin: 'auto',
  [theme.breakpoints.up('sm')]: {
    maxWidth: '450px',
  },
  boxShadow:
    'hsla(220, 30%, 5%, 0.05) 0px 5px 15px 0px, hsla(220, 25%, 10%, 0.05) 0px 15px 35px -5px',
}));

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { enqueueSnackbar } = useSnackbar();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!username || !password) {
      enqueueSnackbar('الرجاء إدخال اسم المستخدم وكلمة المرور', {
        variant: 'warning',
      });
      return;
    }

    try {
      setLoading(true);
      await loginAdmin(username, password);
      enqueueSnackbar('تم تسجيل الدخول بنجاح', { variant: 'success' });
      navigate('/users');
    } catch (err) {
      console.error(err);
      enqueueSnackbar(err?.response?.data?.detail || 'فشل تسجيل الدخول', {
        variant: 'error',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <CssBaseline />
      <SignInContainer direction="column">
        <StyledCard sx={{ direction: 'rtl' }}>
          <Typography
            component="h1"
            variant="h4"
            sx={{
              width: '100%',
              fontSize: 'clamp(2rem, 5vw, 2.2rem)',
              textAlign: 'center',
              mb: 1,
            }}
          >
            تسجيل الدخول للوحة التحكم
          </Typography>

          <Typography
            variant="body2"
            sx={{ textAlign: 'center', color: 'text.secondary', mb: 2 }}
          >
            يرجى إدخال بيانات حساب المشرف للمتابعة
          </Typography>

          <Box
            component="form"
            onSubmit={handleSubmit}
            noValidate
            sx={{
              display: 'flex',
              flexDirection: 'column',
              width: '100%',
              gap: 2,
            }}
          >
            <FormControl>
              <FormLabel
                htmlFor="username"
                sx={{ alignSelf: 'flex-end', mb: 0.5 }}
              >
                اسم المستخدم
              </FormLabel>
              <TextField
                id="username"
                name="username"
                fullWidth
                variant="outlined"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                autoComplete="username"
                autoFocus
                inputProps={{ style: { textAlign: 'right' } }}
              />
            </FormControl>

            <FormControl>
              <FormLabel
                htmlFor="password"
                sx={{ alignSelf: 'flex-end', mb: 0.5 }}
              >
                كلمة المرور
              </FormLabel>
              <TextField
                id="password"
                name="password"
                type="password"
                fullWidth
                variant="outlined"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                inputProps={{ style: { textAlign: 'right' } }}
              />
            </FormControl>

            <Box
              sx={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                mt: 1,
              }}
            >
              <FormControlLabel
                control={<Checkbox color="primary" />}
                label="تذكرني"
                sx={{
                  m: 0,
                  '& .MuiFormControlLabel-label': {
                    fontSize: 14,
                  },
                }}
              />
              <Link
                component="button"
                type="button"
                variant="body2"
                sx={{ fontSize: 14 }}
                onClick={() =>
                  enqueueSnackbar('يرجى التواصل مع مسؤول النظام لاستعادة كلمة المرور', {
                    variant: 'info',
                  })
                }
              >
                نسيت كلمة المرور؟
              </Link>
            </Box>

            <Button
              type="submit"
              fullWidth
              variant="contained"
              disabled={loading}
              sx={{ mt: 1, py: 1.2 }}
            >
              {loading ? <CircularProgress size={22} /> : 'دخول'}
            </Button>
          </Box>

          <Divider sx={{ my: 2 }}>أو</Divider>

          <Typography
            variant="body2"
            sx={{ textAlign: 'center', color: 'text.secondary' }}
          >
            هذا النظام مخصص لمشرفي لوحة التحكم فقط
          </Typography>
        </StyledCard>
      </SignInContainer>
    </>
  );
};

export default Login;
