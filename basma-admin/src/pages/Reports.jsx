// src/pages/Reports.jsx
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
  MenuItem,
  Stack,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { useSnackbar } from 'notistack';
import api from '../services/api';
import DashboardLayout from './Dashboard';

const Reports = () => {
  const { enqueueSnackbar } = useSnackbar();
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);

  const [statusOptions, setStatusOptions] = useState([]);
  const [filterStatusId, setFilterStatusId] = useState('');
  const [filterSearch, setFilterSearch] = useState('');

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    report_type_id: '',
    name_ar: '',
    description_ar: '',
    note: '',
    status_id: '',
    adopted_by_account_id: '',
    government_id: '',
    district_id: '',
    area_id: '',
    location_id: '',
    image_before_url: '',
    image_after_url: '',
    reported_by_name: '',
    is_active: 1,
  });

  // =================== Load lookups & data ===================

  const loadStatusOptions = async () => {
    try {
      const res = await api.get('/report-status'); // backend: GET /report-status
      setStatusOptions(res.data || []);
    } catch (err) {
      console.error(err);
      enqueueSnackbar('تعذر تحميل حالات البلاغات', { variant: 'error' });
    }
  };

  const loadData = async () => {
    try {
      setLoading(true);
      const params = {};
      if (filterStatusId) params.status_id = filterStatusId;
      if (filterSearch) params.q = filterSearch;
      const res = await api.get('/admin/reports', { params });
      setRows(res.data || []);
    } catch (err) {
      console.error(err);
      enqueueSnackbar('حدث خطأ أثناء تحميل البلاغات', { variant: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadStatusOptions();
  }, []);

  useEffect(() => {
    loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterStatusId]);

  const handleSearch = () => {
    loadData();
  };

  // =================== Dialog helpers (تعديل فقط) ===================

  const openEditDialog = (row) => {
    setEditing(row);
    setForm({
      report_type_id: row.report_type_id || '',
      name_ar: row.name_ar || '',
      description_ar: row.description_ar || '',
      note: row.note || '',
      status_id: row.status_id || '',
      adopted_by_account_id: row.adopted_by_account_id || '',
      government_id: row.government_id || '',
      district_id: row.district_id || '',
      area_id: row.area_id || '',
      location_id: row.location_id || '',
      image_before_url: row.image_before_url || '',
      image_after_url: row.image_after_url || '',
      reported_by_name: row.reported_by_name || '',
      is_active: row.is_active ?? 1,
    });
    setDialogOpen(true);
  };

  // =================== CRUD handlers (تعديل / حذف / اعتماد) ===================

  const handleSave = async () => {
    if (!editing) {
      enqueueSnackbar('لا يوجد بلاغ محدد للتعديل', { variant: 'error' });
      return;
    }

    if (!form.name_ar || !form.report_type_id || !form.status_id) {
      enqueueSnackbar('الحقول (نوع البلاغ، العنوان، الحالة) مطلوبة', {
        variant: 'warning',
      });
      return;
    }

    const payload = {
      report_type_id: Number(form.report_type_id),
      name_ar: form.name_ar,
      description_ar: form.description_ar,
      note: form.note || null,
      status_id: Number(form.status_id),
      adopted_by_account_id: form.adopted_by_account_id
        ? Number(form.adopted_by_account_id)
        : null,
      government_id: form.government_id
        ? Number(form.government_id)
        : undefined,
      district_id: form.district_id ? Number(form.district_id) : undefined,
      area_id: form.area_id ? Number(form.area_id) : undefined,
      location_id: form.location_id ? Number(form.location_id) : undefined,
      image_before_url: form.image_before_url || null,
      image_after_url: form.image_after_url || null,
      reported_by_name: form.reported_by_name || null,
      is_active: Number(form.is_active),
    };

    try {
      await api.put(`/admin/reports/${editing.id}`, payload);
      enqueueSnackbar('تم تعديل البلاغ بنجاح', { variant: 'success' });
      setDialogOpen(false);
      setEditing(null);
      loadData();
    } catch (err) {
      console.error(err);
      enqueueSnackbar(
        err?.response?.data?.detail || 'حدث خطأ أثناء حفظ البلاغ',
        { variant: 'error' }
      );
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('هل أنت متأكد من حذف هذا البلاغ؟')) return;
    try {
      await api.delete(`/admin/reports/${id}`);
      enqueueSnackbar('تم حذف البلاغ', { variant: 'success' });
      loadData();
    } catch (err) {
      console.error(err);
      enqueueSnackbar('حدث خطأ أثناء حذف البلاغ', { variant: 'error' });
    }
  };

  const handleApprove = async (id) => {
    try {
      await api.post(`/admin/reports/${id}/approve`);
      enqueueSnackbar('تم اعتماد البلاغ بنجاح', { variant: 'success' });
      loadData();
    } catch (err) {
      console.error(err);
      enqueueSnackbar(
        err?.response?.data?.detail || 'حدث خطأ أثناء اعتماد البلاغ',
        { variant: 'error' }
      );
    }
  };

  // =================== Helpers ===================

  const statusName = (id) => {
    const s = statusOptions.find((st) => st.id === id);
    return s ? s.name_ar : id;
  };

  // =================== DataGrid columns ===================

  const columns = [
    { field: 'id', headerName: 'ID', width: 70 },
    { field: 'report_code', headerName: 'كود البلاغ', width: 160 },
    {
      field: 'name_ar',
      headerName: 'عنوان البلاغ',
      flex: 1,
    },
    {
      field: 'status_id',
      headerName: 'حالة البلاغ',
      width: 150,
      renderCell: (params) => {
        const statusId = params.row?.status_id ?? null;
        return <span>{statusName(statusId)}</span>;
      },
    },
    {
      field: 'reported_by_name',
      headerName: 'مقدّم البلاغ',
      width: 160,
    },
    {
      field: 'reported_at',
      headerName: 'تاريخ الإبلاغ',
      width: 180,
      renderCell: (params) => {
        const value = params.row?.reported_at;
        if (!value) return '';
        return new Date(value).toLocaleString('ar-JO');
      },
    },
    {
      field: 'actions',
      headerName: 'إجراءات',
      width: 260,
      renderCell: (params) => (
        <Box display="flex" gap={1}>
          {params.row?.status_id === 1 && (
            <Button
              size="small"
              variant="contained"
              color="primary"
              onClick={() => handleApprove(params.row.id)}
            >
              اعتماد
            </Button>
          )}
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

  // =================== Render ===================

  return (
    <DashboardLayout>
      <Box mb={2}>
        <Typography variant="h5" gutterBottom>
          إدارة البلاغات
        </Typography>

        <Stack
          direction={{ xs: 'column', sm: 'row' }}
          spacing={2}
          alignItems="center"
          mb={2}
        >
          <TextField
            label="بحث (كود / عنوان)"
            size="small"
            value={filterSearch}
            onChange={(e) => setFilterSearch(e.target.value)}
          />
          <TextField
            label="حالة البلاغ"
            select
            size="small"
            sx={{ minWidth: 180 }}
            value={filterStatusId}
            onChange={(e) => setFilterStatusId(e.target.value)}
          >
            <MenuItem value="">الكل</MenuItem>
            {statusOptions.map((st) => (
              <MenuItem key={st.id} value={st.id}>
                {st.name_ar}
              </MenuItem>
            ))}
          </TextField>
          <Button variant="outlined" onClick={handleSearch}>
            تطبيق البحث
          </Button>
          <Box flexGrow={1} />
          {/* تم إزالة زر "بلاغ جديد" */}
        </Stack>
      </Box>

      <Paper sx={{ height: 550, width: '100%' }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={loading}
          pageSizeOptions={[10, 25, 50]}
          pageSize={10}
          disableSelectionOnClick
          getRowId={(row) => row.id}
        />
      </Paper>

      {/* Dialog لتعديل بلاغ فقط */}
      <Dialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          setEditing(null);
        }}
        fullWidth
        maxWidth="md"
      >
        <DialogTitle>تعديل بلاغ</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2} mt={1}>
            <TextField
              label="نوع البلاغ (ID)"
              value={form.report_type_id}
              onChange={(e) =>
                setForm({ ...form, report_type_id: e.target.value })
              }
            />
            <TextField
              label="العنوان (name_ar)"
              value={form.name_ar}
              onChange={(e) => setForm({ ...form, name_ar: e.target.value })}
            />
            <TextField
              label="الوصف"
              multiline
              minRows={3}
              value={form.description_ar}
              onChange={(e) =>
                setForm({ ...form, description_ar: e.target.value })
              }
            />
            <TextField
              label="ملاحظات"
              multiline
              minRows={2}
              value={form.note}
              onChange={(e) => setForm({ ...form, note: e.target.value })}
            />
            <TextField
              label="حالة البلاغ"
              select
              value={form.status_id}
              onChange={(e) =>
                setForm({ ...form, status_id: e.target.value })
              }
            >
              {statusOptions.map((st) => (
                <MenuItem key={st.id} value={st.id}>
                  {st.name_ar}
                </MenuItem>
              ))}
            </TextField>
            <TextField
              label="ID الحساب المتبني (اختياري)"
              value={form.adopted_by_account_id}
              onChange={(e) =>
                setForm({
                  ...form,
                  adopted_by_account_id: e.target.value,
                })
              }
            />
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
              <TextField
                label="Government ID"
                value={form.government_id}
                onChange={(e) =>
                  setForm({ ...form, government_id: e.target.value })
                }
              />
              <TextField
                label="District ID"
                value={form.district_id}
                onChange={(e) =>
                  setForm({ ...form, district_id: e.target.value })
                }
              />
              <TextField
                label="Area ID"
                value={form.area_id}
                onChange={(e) =>
                  setForm({ ...form, area_id: e.target.value })
                }
              />
              <TextField
                label="Location ID"
                value={form.location_id}
                onChange={(e) =>
                  setForm({ ...form, location_id: e.target.value })
                }
              />
            </Stack>
            <TextField
              label="رابط الصورة قبل"
              value={form.image_before_url}
              onChange={(e) =>
                setForm({ ...form, image_before_url: e.target.value })
              }
            />
            <TextField
              label="رابط الصورة بعد"
              value={form.image_after_url}
              onChange={(e) =>
                setForm({ ...form, image_after_url: e.target.value })
              }
            />
            <TextField
              label="اسم مقدم البلاغ (لو زائر)"
              value={form.reported_by_name}
              onChange={(e) =>
                setForm({ ...form, reported_by_name: e.target.value })
              }
            />
            <TextField
              label="مفعل (1/0)"
              value={form.is_active}
              onChange={(e) =>
                setForm({ ...form, is_active: e.target.value })
              }
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => {
              setDialogOpen(false);
              setEditing(null);
            }}
          >
            إلغاء
          </Button>
          <Button variant="contained" onClick={handleSave}>
            حفظ
          </Button>
        </DialogActions>
      </Dialog>
    </DashboardLayout>
  );
};

export default Reports;
