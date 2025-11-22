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
  IconButton,
  Tooltip,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { useSnackbar } from 'notistack';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import api from '../services/api';
import DashboardLayout from './Dashboard';

const Reports = () => {
  const { enqueueSnackbar } = useSnackbar();

  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);

  // lookups
  const [statusOptions, setStatusOptions] = useState([]);
  const [reportTypes, setReportTypes] = useState([]);
  const [accountOptions, setAccountOptions] = useState([]);

  // filters
  const [filterStatusId, setFilterStatusId] = useState('');
  const [filterSearch, setFilterSearch] = useState('');

  // edit dialog
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState(null);

  const [form, setForm] = useState({
    id: '',
    report_code: '',
    report_type_id: '',
    name_ar: '',
    description_ar: '',
    note: '',
    status_id: '',
    adopted_by_account_id: '',
    government_id: '',
    government_name_ar: '',
    district_id: '',
    district_name_ar: '',
    area_id: '',
    area_name_ar: '',
    location_id: '',
    image_before_url: '',
    image_after_url: '',
    reported_by_name: '',
    is_active: 1,
  });

  // =================== Load lookups & data ===================

  const loadStatusOptions = async () => {
    try {
      const res = await api.get('/report-status');
      setStatusOptions(res.data || []);
    } catch (err) {
      console.error(err);
      enqueueSnackbar('تعذر تحميل حالات البلاغات', { variant: 'error' });
    }
  };

  const loadReportTypes = async () => {
    try {
      const res = await api.get('/report-types');
      setReportTypes(res.data || []);
    } catch (err) {
      console.error(err);
      enqueueSnackbar('تعذر تحميل أنواع البلاغات', { variant: 'error' });
    }
  };

  const loadAccountOptions = async () => {
    try {
      const res = await api.get('/account-options');
      setAccountOptions(res.data || []);
    } catch (err) {
      console.error(err);
      enqueueSnackbar('تعذر تحميل الحسابات المتبنية', { variant: 'error' });
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
    loadReportTypes();
    loadAccountOptions();
  }, []);

  useEffect(() => {
    loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterStatusId]);

  const handleSearch = () => {
    loadData();
  };

  // =================== Helpers ===================

  const statusName = (id) => {
    const s = statusOptions.find((st) => st.id === id);
    return s ? s.name_ar : id;
  };

  const reportTypeName = (id) => {
    const t = reportTypes.find((rt) => rt.id === id);
    return t ? t.name_ar : id;
  };

  const accountName = (id) => {
    if (!id) return 'بدون';
    const a = accountOptions.find((acc) => acc.id === id);
    return a ? a.name_ar : id;
  };

  // =================== Dialog helpers (تعديل فقط) ===================

  const openEditDialog = (row) => {
    setEditing(row);
    setForm({
      id: row.id,
      report_code: row.report_code || '',
      report_type_id: row.report_type_id || '',
      name_ar: row.name_ar || '',
      description_ar: row.description_ar || '',
      note: row.note || '',
      status_id: row.status_id || '',
      adopted_by_account_id: row.adopted_by_account_id || '',
      government_id: row.government_id || '',
      government_name_ar: row.government_name_ar || '',
      district_id: row.district_id || '',
      district_name_ar: row.district_name_ar || '',
      area_id: row.area_id || '',
      area_name_ar: row.area_name_ar || '',
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
      government_id: form.government_id || undefined,
      district_id: form.district_id || undefined,
      area_id: form.area_id || undefined,
      location_id: form.location_id || undefined,
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

  // اعتماد البلاغ: على مستوى الـ backend يجب أن يغير الحالة إلى 2 (جديد)
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

  // =================== DataGrid columns ===================

  const columns = [
    { field: 'id', headerName: 'ID', width: 80 },
    { field: 'report_code', headerName: 'كود البلاغ', width: 160 },
    {
      field: 'report_type_id',
      headerName: 'نوع البلاغ',
      width: 180,
      renderCell: (params) => (
        <span>{reportTypeName(params.row?.report_type_id)}</span>
      ),
    },
    {
      field: 'name_ar',
      headerName: 'عنوان البلاغ',
      flex: 1,
      minWidth: 200,
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
      field: 'adopted_by_account_id',
      headerName: 'الحساب المتبني',
      width: 200,
      renderCell: (params) => (
        <span>{accountName(params.row?.adopted_by_account_id)}</span>
      ),
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
      width: 160,
      sortable: false,
      filterable: false,
      align: 'center',
      headerAlign: 'center',
      renderCell: (params) => {
        const statusId = params.row?.status_id;
        return (
          <Box display="flex" gap={0.5}>
            {statusId === 1 && (
              <Tooltip title="اعتماد البلاغ">
                <IconButton
                  size="small"
                  color="success"
                  onClick={() => handleApprove(params.row.id)}
                >
                  <CheckCircleIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
            <Tooltip title="تعديل">
              <IconButton
                size="small"
                color="primary"
                onClick={() => openEditDialog(params.row)}
              >
                <EditIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <Tooltip title="حذف">
              <IconButton
                size="small"
                color="error"
                onClick={() => handleDelete(params.row.id)}
              >
                <DeleteIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Box>
        );
      },
    },
  ];

  // =================== Render ===================

  return (
    <DashboardLayout>
      <Box mb={2}>
        <Typography variant="h5" gutterBottom>
          إدارة البلاغات
        </Typography>

        {/* فلاتر البحث */}
        <Paper
          elevation={0}
          sx={{
            p: 2,
            mb: 2,
            borderRadius: 3,
          }}
        >
          <Stack
            direction={{ xs: 'column', sm: 'row' }}
            spacing={2}
            alignItems={{ xs: 'stretch', sm: 'center' }}
          >
            <TextField
              label="بحث (كود / عنوان)"
              size="small"
              fullWidth
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
            <Button
              variant="contained"
              onClick={handleSearch}
              sx={{ minWidth: 140 }}
            >
              تطبيق البحث
            </Button>
            <Box flexGrow={1} />
          </Stack>
        </Paper>
      </Box>

      {/* جدول البلاغات */}
      <Paper
        sx={{
          height: 550,
          width: '100%',
          borderRadius: 3,
          overflow: 'hidden',
        }}
      >
        <DataGrid
          rows={rows}
          columns={columns}
          loading={loading}
          getRowId={(row) => row.id}
          pageSizeOptions={[10, 25, 50]}
          initialState={{
            pagination: {
              paginationModel: { pageSize: 10, page: 0 },
            },
          }}
          disableSelectionOnClick
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
            {/* ID + report_code (غير قابلة للتعديل) */}
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
              <TextField
                label="ID"
                value={form.id}
                fullWidth
                InputProps={{ readOnly: true }}
              />
              <TextField
                label="كود البلاغ"
                value={form.report_code}
                fullWidth
                InputProps={{ readOnly: true }}
              />
            </Stack>

            {/* نوع البلاغ */}
            <TextField
              label="نوع البلاغ"
              select
              value={form.report_type_id}
              onChange={(e) =>
                setForm({ ...form, report_type_id: e.target.value })
              }
            >
              {reportTypes.map((rt) => (
                <MenuItem key={rt.id} value={rt.id}>
                  {rt.name_ar}
                </MenuItem>
              ))}
            </TextField>

            {/* العنوان + الوصف */}
            <TextField
              label="عنوان البلاغ"
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

            {/* ملاحظات */}
            <TextField
              label="ملاحظات"
              multiline
              minRows={2}
              value={form.note}
              onChange={(e) => setForm({ ...form, note: e.target.value })}
            />

            {/* حالة البلاغ */}
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

            {/* الحساب المتبني */}
            <TextField
              label="الحساب المتبني"
              select
              value={form.adopted_by_account_id || ''}
              onChange={(e) =>
                setForm({
                  ...form,
                  adopted_by_account_id: e.target.value || '',
                })
              }
              helperText="يمكن تركه فارغاً لعدم وجود حساب متبنٍ"
            >
              <MenuItem value="">بدون</MenuItem>
              {accountOptions.map((acc) => (
                <MenuItem key={acc.id} value={acc.id}>
                  {acc.name_ar}
                </MenuItem>
              ))}
            </TextField>

            {/* الموقع الإداري (عرض فقط) */}
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
              <TextField
                label="المحافظة"
                value={form.government_name_ar}
                fullWidth
                InputProps={{ readOnly: true }}
              />
              <TextField
                label="اللواء / المنطقة"
                value={form.district_name_ar}
                fullWidth
                InputProps={{ readOnly: true }}
              />
              <TextField
                label="الحي"
                value={form.area_name_ar}
                fullWidth
                InputProps={{ readOnly: true }}
              />
            </Stack>

            {/* روابط الصور (عرض فقط) */}
            <TextField
              label="رابط الصورة قبل"
              value={form.image_before_url}
              InputProps={{ readOnly: true }}
            />
            <TextField
              label="رابط الصورة بعد"
              value={form.image_after_url}
              InputProps={{ readOnly: true }}
            />

            {/* اسم مقدم البلاغ */}
            <TextField
              label="اسم مقدم البلاغ (لو زائر)"
              value={form.reported_by_name}
              onChange={(e) =>
                setForm({ ...form, reported_by_name: e.target.value })
              }
            />

            {/* مفعل / غير مفعل */}
            <TextField
              label="حالة التفعيل"
              select
              value={form.is_active}
              onChange={(e) =>
                setForm({ ...form, is_active: Number(e.target.value) })
              }
            >
              <MenuItem value={1}>مفعل</MenuItem>
              <MenuItem value={0}>غير مفعل</MenuItem>
            </TextField>
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
