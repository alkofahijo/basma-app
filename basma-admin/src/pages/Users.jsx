// src/pages/Users.jsx
import React, { useEffect, useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { useSnackbar } from 'notistack';
import api from '../services/api';
import DashboardLayout from './Dashboard';

const Users = () => {
  const { enqueueSnackbar } = useSnackbar();
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    username: '',
    password: '',
    user_type: 2,
    is_active: 1,
    account_id: '',
  });

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await api.get('/admin/users');
      setRows(res.data);
    } catch (err) {
      console.error(err);
      enqueueSnackbar('حدث خطأ أثناء تحميل المستخدمين', { variant: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const openNewDialog = () => {
    setEditing(null);
    setForm({
      username: '',
      password: '',
      user_type: 2,
      is_active: 1,
      account_id: '',
    });
    setDialogOpen(true);
  };

  const openEditDialog = (row) => {
    setEditing(row);
    setForm({
      username: row.username,
      password: '',
      user_type: row.user_type,
      is_active: row.is_active,
      account_id: row.account_id || '',
    });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    if (!form.username || (!editing && !form.password)) {
      enqueueSnackbar('اسم المستخدم وكلمة المرور مطلوبة', { variant: 'warning' });
      return;
    }
    try {
      if (editing) {
        await api.put(`/admin/users/${editing.id}`, {
          username: form.username,
          password: form.password || undefined,
          user_type: Number(form.user_type),
          is_active: Number(form.is_active),
          account_id: form.account_id ? Number(form.account_id) : null,
        });
        enqueueSnackbar('تم تعديل المستخدم بنجاح', { variant: 'success' });
      } else {
        await api.post('/admin/users', {
          username: form.username,
          password: form.password,
          user_type: Number(form.user_type),
          is_active: Number(form.is_active),
          account_id: form.account_id ? Number(form.account_id) : null,
        });
        enqueueSnackbar('تم إنشاء المستخدم بنجاح', { variant: 'success' });
      }
      setDialogOpen(false);
      loadData();
    } catch (err) {
      console.error(err);
      enqueueSnackbar(
        err?.response?.data?.detail || 'حدث خطأ أثناء الحفظ',
        { variant: 'error' }
      );
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('هل أنت متأكد من حذف هذا المستخدم؟')) return;
    try {
      await api.delete(`/admin/users/${id}`);
      enqueueSnackbar('تم حذف المستخدم', { variant: 'success' });
      loadData();
    } catch (err) {
      console.error(err);
      enqueueSnackbar('حدث خطأ أثناء حذف المستخدم', { variant: 'error' });
    }
  };

  const columns = [
    { field: 'id', headerName: 'ID', width: 70 },
    { field: 'username', headerName: 'اسم المستخدم', flex: 1 },
    { field: 'user_type', headerName: 'نوع المستخدم', width: 130 },
    { field: 'is_active', headerName: 'مفعل', width: 90 },
    {
      field: 'actions',
      headerName: 'إجراءات',
      width: 200,
      renderCell: (params) => (
        <Box display="flex" gap={1}>
          <Button
            size="small"
            variant="outlined"
            onClick={() => openEditDialog(params.row)}
          >
            تعديل
          </Button>
          <Button
            size="small"
            variant="outlined"
            color="error"
            onClick={() => handleDelete(params.row.id)}
          >
            حذف
          </Button>
        </Box>
      ),
    },
  ];

  return (
    <DashboardLayout>
      <Box mb={2}>
        <Typography variant="h5" gutterBottom>
          إدارة المستخدمين
        </Typography>
        <Button variant="contained" onClick={openNewDialog}>
          مستخدم جديد
        </Button>
      </Box>
      <Paper sx={{ height: 500, width: '100%' }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={loading}
          pageSize={10}
          rowsPerPageOptions={[10, 25, 50]}
          disableSelectionOnClick
          getRowId={(row) => row.id}
        />
      </Paper>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} fullWidth>
        <DialogTitle>{editing ? 'تعديل مستخدم' : 'مستخدم جديد'}</DialogTitle>
        <DialogContent>
          <TextField
            label="اسم المستخدم"
            fullWidth
            margin="normal"
            value={form.username}
            onChange={(e) => setForm({ ...form, username: e.target.value })}
          />
          <TextField
            label="كلمة المرور"
            fullWidth
            margin="normal"
            type="password"
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            helperText={editing ? 'اتركها فارغة إذا لا تريد تغييرها' : ''}
          />
          <TextField
            label="نوع المستخدم (1=أدمن, 2=عادي)"
            fullWidth
            margin="normal"
            value={form.user_type}
            onChange={(e) => setForm({ ...form, user_type: e.target.value })}
          />
          <TextField
            label="مفعل (1/0)"
            fullWidth
            margin="normal"
            value={form.is_active}
            onChange={(e) => setForm({ ...form, is_active: e.target.value })}
          />
          <TextField
            label="Account ID (اختياري)"
            fullWidth
            margin="normal"
            value={form.account_id}
            onChange={(e) => setForm({ ...form, account_id: e.target.value })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>إلغاء</Button>
          <Button variant="contained" onClick={handleSave}>
            حفظ
          </Button>
        </DialogActions>
      </Dialog>
    </DashboardLayout>
  );
};

export default Users;
