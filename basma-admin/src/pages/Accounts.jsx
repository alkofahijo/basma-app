// src/pages/Accounts.jsx
import React, { useEffect, useState } from "react";
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
} from "@mui/material";
import { DataGrid } from "@mui/x-data-grid";
import { useSnackbar } from "notistack";
import api from "../services/api";
import DashboardLayout from "./Dashboard";

const Accounts = () => {
  const { enqueueSnackbar } = useSnackbar();
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);

  const [accountTypes, setAccountTypes] = useState([]);
  const [governments, setGovernments] = useState([]);

  const [filterAccountTypeId, setFilterAccountTypeId] = useState("");
  const [filterSearch, setFilterSearch] = useState("");

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState(null);

  const emptyForm = {
    account_type_id: "",
    name_ar: "",
    name_en: "",
    mobile_number: "",
    government_id: "",
    logo_url: "",
    join_form_link: "",
    is_active: "1", // default نعم
    show_details: "1", // default نعم
    username: "",
    password: "",
  };

  const [form, setForm] = useState(emptyForm);

  // =================== Helpers ===================

  const accountTypeName = (id) => {
    const t = accountTypes.find((at) => at.id === id);
    return t ? t.name_ar : id;
  };

  const governmentName = (id) => {
    const g = governments.find((gov) => gov.id === id);
    return g ? g.name_ar : id;
  };

  const yesNoLabel = (value) => {
    const num = Number(value);
    return num === 1 ? "نعم" : "لا";
  };

  // =================== Load lookups & data ===================

  const loadAccountTypes = async () => {
    try {
      const res = await api.get("/account-types");
      setAccountTypes(res.data || []);
    } catch (err) {
      console.error(err);
      enqueueSnackbar("تعذر تحميل أنواع الحسابات", { variant: "error" });
    }
  };

  const loadGovernments = async () => {
    try {
      const res = await api.get("/governments");
      setGovernments(res.data || []);
    } catch (err) {
      console.error(err);
      enqueueSnackbar("تعذر تحميل المحافظات", { variant: "error" });
    }
  };

  const loadData = async () => {
    try {
      setLoading(true);
      const params = {};
      if (filterAccountTypeId) params.account_type_id = filterAccountTypeId;
      if (filterSearch) params.q = filterSearch;
      const res = await api.get("/admin/accounts", { params });
      setRows(res.data || []);
    } catch (err) {
      console.error(err);
      enqueueSnackbar("حدث خطأ أثناء تحميل الحسابات", { variant: "error" });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // تحميل اللوكاَب مرة واحدة
    loadAccountTypes();
    loadGovernments();
  }, []);

  useEffect(() => {
    loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterAccountTypeId]);

  const handleSearch = () => {
    loadData();
  };

  // =================== Dialog helpers ===================

  const resetForm = () => {
    setForm(emptyForm);
  };

  const openNewDialog = () => {
    setEditing(null);
    resetForm();
    setDialogOpen(true);
  };

  const openEditDialog = (row) => {
    setEditing(row);
    setForm({
      account_type_id: row.account_type_id || "",
      name_ar: row.name_ar || "",
      name_en: row.name_en || "",
      mobile_number: row.mobile_number || "",
      government_id: row.government_id ? String(row.government_id) : "",
      logo_url: row.logo_url || "",
      join_form_link: row.join_form_link || "",
      is_active:
        typeof row.is_active !== "undefined"
          ? String(row.is_active)
          : "1",
      show_details:
        typeof row.show_details !== "undefined"
          ? String(row.show_details)
          : "1",
      // لإنشاء الحساب فقط، لذلك نفصل بيانات المستخدم
      username: "",
      password: "",
    });
    setDialogOpen(true);
  };

  // =================== CRUD handlers ===================

  const handleSave = async () => {
    if (
      !form.name_ar ||
      !form.name_en ||
      !form.mobile_number ||
      !form.account_type_id ||
      !form.government_id
    ) {
      enqueueSnackbar(
        "الحقول الأساسية مطلوبة (الاسمين، رقم الجوال، نوع الحساب، المحافظة)",
        {
          variant: "warning",
        }
      );
      return;
    }

    const payload = {
      account_type_id: Number(form.account_type_id),
      name_ar: form.name_ar,
      name_en: form.name_en,
      mobile_number: form.mobile_number,
      government_id: Number(form.government_id),
      logo_url: form.logo_url || null,
      join_form_link: form.join_form_link || null,
      is_active: Number(form.is_active),
      show_details: Number(form.show_details),
    };

    if (!editing) {
      // فقط في حالة إنشاء حساب جديد، نسمح بإنشاء مستخدم
      payload.username = form.username || null;
      payload.password = form.password || null;
    }

    try {
      if (editing) {
        await api.put(`/admin/accounts/${editing.id}`, payload);
        enqueueSnackbar("تم تعديل الحساب بنجاح", { variant: "success" });
      } else {
        await api.post("/admin/accounts", payload);
        enqueueSnackbar("تم إنشاء الحساب بنجاح", { variant: "success" });
      }
      setDialogOpen(false);
      loadData();
    } catch (err) {
      console.error(err);
      enqueueSnackbar(
        err?.response?.data?.detail || "حدث خطأ أثناء حفظ الحساب",
        { variant: "error" }
      );
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("هل أنت متأكد من حذف هذا الحساب؟")) return;
    try {
      await api.delete(`/admin/accounts/${id}`);
      enqueueSnackbar("تم حذف الحساب", { variant: "success" });
      loadData();
    } catch (err) {
      console.error(err);
      enqueueSnackbar("حدث خطأ أثناء حذف الحساب", { variant: "error" });
    }
  };

  // =================== DataGrid columns ===================

  const columns = [
    { field: "id", headerName: "ID", width: 70 },
    {
      field: "name_ar",
      headerName: "اسم الحساب",
      flex: 1,
    },
    {
      field: "account_type_id",
      headerName: "نوع الحساب",
      width: 160,
      valueGetter: (params) => {
        const typeId =
          typeof params.value !== "undefined"
            ? params.value
            : params.row && typeof params.row.account_type_id !== "undefined"
            ? params.row.account_type_id
            : null;
        return accountTypeName(typeId);
      },
    },
    {
      field: "mobile_number",
      headerName: "رقم الجوال",
      width: 150,
    },
    {
      field: "government_id",
      headerName: "المحافظة",
      width: 160,
      valueGetter: (params) => {
        const govId =
          typeof params.value !== "undefined"
            ? params.value
            : params.row && typeof params.row.government_id !== "undefined"
            ? params.row.government_id
            : null;
        return governmentName(govId);
      },
    },
    {
      field: "is_active",
      headerName: "مفعل",
      width: 110,
      valueFormatter: (params) => yesNoLabel(params.value),
    },
    {
      field: "show_details",
      headerName: "إظهار في الواجهة",
      width: 150,
      valueFormatter: (params) => yesNoLabel(params.value),
    },
    {
      field: "actions",
      headerName: "إجراءات",
      width: 220,
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

  // =================== Render ===================

  return (
    <DashboardLayout>
      <Box mb={2}>
        <Typography variant="h5" gutterBottom>
          إدارة الحسابات
        </Typography>

        <Stack
          direction={{ xs: "column", sm: "row" }}
          spacing={2}
          alignItems="center"
          mb={2}
        >
          <TextField
            label="بحث بالاسم"
            size="small"
            value={filterSearch}
            onChange={(e) => setFilterSearch(e.target.value)}
          />
          <TextField
            label="نوع الحساب"
            select
            size="small"
            sx={{ minWidth: 200 }}
            value={filterAccountTypeId}
            onChange={(e) => setFilterAccountTypeId(e.target.value)}
          >
            <MenuItem value="">الكل</MenuItem>
            {accountTypes.map((t) => (
              <MenuItem key={t.id} value={t.id}>
                {t.name_ar}
              </MenuItem>
            ))}
          </TextField>
          <Button variant="outlined" onClick={handleSearch}>
            تطبيق البحث
          </Button>
          <Box flexGrow={1} />
          <Button variant="contained" onClick={openNewDialog}>
            حساب جديد
          </Button>
        </Stack>
      </Box>

      <Paper sx={{ height: 550, width: "100%" }}>
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

      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        fullWidth
        maxWidth="md"
      >
        <DialogTitle>{editing ? "تعديل حساب" : "حساب جديد"}</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2} mt={1}>
            <TextField
              label="نوع الحساب"
              select
              value={form.account_type_id}
              onChange={(e) =>
                setForm({ ...form, account_type_id: e.target.value })
              }
            >
              {accountTypes.map((t) => (
                <MenuItem key={t.id} value={t.id}>
                  {t.name_ar}
                </MenuItem>
              ))}
            </TextField>

            <TextField
              label="الاسم بالعربية"
              value={form.name_ar}
              onChange={(e) => setForm({ ...form, name_ar: e.target.value })}
            />
            <TextField
              label="الاسم بالإنجليزية"
              value={form.name_en}
              onChange={(e) => setForm({ ...form, name_en: e.target.value })}
            />

            <TextField
              label="رقم الجوال"
              value={form.mobile_number}
              onChange={(e) =>
                setForm({ ...form, mobile_number: e.target.value })
              }
            />

            <TextField
              label="المحافظة"
              select
              value={form.government_id}
              onChange={(e) =>
                setForm({ ...form, government_id: e.target.value })
              }
            >
              {governments.map((g) => (
                <MenuItem key={g.id} value={g.id}>
                  {g.name_ar}
                </MenuItem>
              ))}
            </TextField>

            <TextField
              label="رابط الشعار (logo_url)"
              value={form.logo_url}
              onChange={(e) => setForm({ ...form, logo_url: e.target.value })}
            />
            <TextField
              label="رابط نموذج الانضمام"
              value={form.join_form_link}
              onChange={(e) =>
                setForm({ ...form, join_form_link: e.target.value })
              }
            />

            <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
              <TextField
                label="مفعل"
                select
                value={form.is_active}
                onChange={(e) =>
                  setForm({ ...form, is_active: e.target.value })
                }
              >
                <MenuItem value="1">نعم</MenuItem>
                <MenuItem value="0">لا</MenuItem>
              </TextField>

              <TextField
                label="إظهار في الواجهة"
                select
                value={form.show_details}
                onChange={(e) =>
                  setForm({ ...form, show_details: e.target.value })
                }
              >
                <MenuItem value="1">نعم</MenuItem>
                <MenuItem value="0">لا</MenuItem>
              </TextField>
            </Stack>

            {!editing && (
              <>
                <Typography variant="subtitle2">
                  (اختياري) إنشاء مستخدم مرتبط بهذا الحساب
                </Typography>
                <TextField
                  label="اسم المستخدم"
                  value={form.username}
                  onChange={(e) =>
                    setForm({ ...form, username: e.target.value })
                  }
                />
                <TextField
                  label="كلمة المرور"
                  type="password"
                  value={form.password}
                  onChange={(e) =>
                    setForm({ ...form, password: e.target.value })
                  }
                  helperText="يمكن تركها فارغة إذا لا تريد إنشاء مستخدم"
                />
              </>
            )}
          </Stack>
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

export default Accounts;
