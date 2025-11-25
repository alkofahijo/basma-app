# app/ml/report_classifier.py
from __future__ import annotations

import io
from typing import Tuple, Dict, Any, Optional, List

from PIL import Image
import yolov5

# ============================================================
# ثابتات تعريف أنواع البلاغ كما هي في قاعدة البيانات
# ============================================================

REPORT_TYPE_META: Dict[str, Dict[str, Any]] = {
    "CONSTRUCTION_ROAD": {
        "id": 1,
        "name_ar": "أعمال إنشاء الطرق",
        "name_en": "Road construction",
    },
    "BAD_BILLBOARD": {
        "id": 2,
        "name_ar": "لوحة إعلانية مخالِفة",
        "name_en": "Bad billboard",
    },
    "GARBAGE": {
        "id": 3,
        "name_ar": "نفايات",
        "name_en": "Garbage / litter",
    },
    "GRAFFITI": {
        "id": 4,
        "name_ar": "كتابات جدارية (غرافيتي)",
        "name_en": "Graffiti",
    },
    "CLUTTER_SIDEWALK": {
        "id": 5,
        "name_ar": "عوائق على الرصيف",
        "name_en": "Sidewalk clutter",
    },
    "POTHOLES": {
        "id": 6,
        "name_ar": "حفر في الطريق",
        "name_en": "Potholes",
    },
    "SAND_ON_ROAD": {
        "id": 7,
        "name_ar": "رمال على الطريق",
        "name_en": "Sand on road",
    },
    "UNKEPT_FACADE": {
        "id": 8,
        "name_ar": "واجهة مبنى مهملة",
        "name_en": "Unkempt facade",
    },
    "FADED_SIGNAGE": {
        "id": 9,
        "name_ar": "لافتات باهتة",
        "name_en": "Faded signage",
    },
    "BROKEN_SIGNAGE": {
        "id": 10,
        "name_ar": "لافتات مكسورة",
        "name_en": "Broken signage",
    },
    "OTHERS": {
        "id": 11,
        "name_ar": "أخرى",
        "name_en": "Others",
    },
}

GARBAGE_CLASS_CODE = "GARBAGE"
FADED_SIGNAGE_CLASS_CODE = "FADED_SIGNAGE"

# وزن مساحة الصندوق في حساب impact_score
DEFAULT_AREA_WEIGHT = 0.7
# تقليل تأثير حجم الصندوق لفئة القمامة حتى لا تسيطر لوحدها
GARBAGE_AREA_WEIGHT = 0.4

# أساس impact (حتى الأشياء الصغيرة يبقى لها وزن نسبي)
BASE_IMPACT_BIAS = 0.3

# عامل تفوق القمامة: إذا تجاوز تأثير القمامة هذا المضاعف مقارنة بأقرب فئة أخرى،
# يتم اختيار القمامة حتى بوجود فئات أخرى
GARBAGE_DOMINANCE_FACTOR = 1.5


class ReportClassifierService:
    """
    خدمة تصنيف البلاغات باستخدام نموذج YOLOv5 (ملف vp.pt) عبر حزمة yolov5.

    واجهة الاستخدام:
        predict(image_bytes: bytes) -> (report_type_id: int, confidence: float, info: dict)

    حيث:
      - report_type_id: يطابق العمود ID في جدول report_types (من 1 إلى 11)
      - confidence: أعلى قيمة ثقة للكلاس النهائي المختار
      - info: dict يحتوي على:
            - "code": الكود الإنجليزي للتصنيف (مثل GRAFFITI, POTHOLES, ...)
            - "name_ar": التسمية بالعربية
            - "name_en": التسمية بالإنجليزية
            - "model_class_id": رقم الكلاس داخل نموذج YOLOv5
    """

    OTHERS_CODE = "OTHERS"

    def __init__(self, model_path: str, model_conf_threshold: float = 0.1) -> None:
        """
        :param model_path: مسار ملف YOLOv5 .pt (مثل app/models/vp.pt)
        :param model_conf_threshold: أقل قيمة ثقة يحتفظ بها YOLO لكل كائن مكتشف
        """
        # ✅ تحميل النموذج من ملف .pt باستخدام حزمة yolov5
        self.model = yolov5.load(model_path)

        # إعداد عتبة الثقة داخل النموذج (إن وُجدت الخاصية)
        try:
            self.model.conf = float(model_conf_threshold)
        except Exception:
            pass

        self.model_conf_threshold = float(model_conf_threshold)

        # خرائط من الكود إلى ID والأسماء
        self.report_type_ids: Dict[str, int] = {
            code: meta["id"] for code, meta in REPORT_TYPE_META.items()
        }
        self.class_name_ar: Dict[str, str] = {
            code: meta["name_ar"] for code, meta in REPORT_TYPE_META.items()
        }
        self.class_name_en: Dict[str, str] = {
            code: meta["name_en"] for code, meta in REPORT_TYPE_META.items()
        }

    # -------------------------
    # Helpers
    # -------------------------

    def _normalize_label_to_code(self, label: str) -> str:
        """
        نحاول تحويل اسم الكلاس القادم من YOLO إلى كود موحّد
        يطابق مفاتيح REPORT_TYPE_META (بغض النظر عن حالة الأحرف).
        """
        if not label:
            return label
        candidate = label.strip().upper()
        if candidate in REPORT_TYPE_META:
            return candidate
        return label

    def _extract_predictions(
        self,
        results: Any,
        image_width: int,
        image_height: int,
    ) -> List[Dict[str, Any]]:
        """
        تحويل مخرجات YOLOv5 إلى قائمة بسيطة من التنبؤات:

        يمثل كل عنصر في القائمة:
        {
          "class": str,         # كود التصنيف الموحّد إن أمكن (مثل CONSTRUCTION_ROAD, GARBAGE, ...)
          "raw_class": str,     # اسم الكلاس كما أخرجه YOLO مباشرةً
          "class_id": int,
          "confidence": float,
          "area_ratio": float,
          "impact_score": float
        }
        """
        predictions: List[Dict[str, Any]] = []
        if results is None:
            return predictions

        try:
            # النتائج كـ Tensor (N,6): [x1, y1, x2, y2, conf, cls]
            det = results.xyxy[0]
        except Exception:
            return predictions

        if det is None or len(det) == 0:
            return predictions

        image_area = float(max(1, image_width * image_height))
        names = getattr(results, "names", None)

        for row in det.tolist():
            if len(row) < 6:
                continue

            x1, y1, x2, y2, conf, cls_idx = row
            conf = float(conf)
            cls_idx = int(cls_idx)

            if conf < 1e-3:
                continue

            w = max(0.0, x2 - x1)
            h = max(0.0, y2 - y1)
            box_area = max(0.0, w * h)
            area_ratio = 0.0
            if image_area > 0:
                area_ratio = max(0.0, min(1.0, box_area / image_area))

            # اسم الكلاس كما هو في النموذج
            if isinstance(names, dict) and cls_idx in names:
                raw_label = str(names[cls_idx])
            else:
                raw_label = str(cls_idx)

            # تحويل الاسم الخام إلى كود تصنيف موحّد إن أمكن
            label_code = self._normalize_label_to_code(raw_label)

            # حساب impact_score مع تقليل تأثير الحجم لفئة القمامة
            if label_code == GARBAGE_CLASS_CODE:
                area_weight = GARBAGE_AREA_WEIGHT
            else:
                area_weight = DEFAULT_AREA_WEIGHT

            impact_score = conf * (BASE_IMPACT_BIAS + area_weight * area_ratio)

            predictions.append(
                {
                    "class": label_code,
                    "raw_class": raw_label,
                    "class_id": cls_idx,
                    "confidence": conf,
                    "area_ratio": area_ratio,
                    "impact_score": impact_score,
                }
            )

        return predictions

    @staticmethod
    def _aggregate_predictions(
        predictions: List[Dict[str, Any]],
    ) -> Tuple[str, float, Optional[int]]:
        """
        اختيار النوع "الأكثر تأثيراً" (Dominant Type) من بين التنبؤات.

        منطق الاختيار:
        - إذا وُجدت فئة "القمامة" مع فئات أخرى:
            1) إذا كانت FADED_SIGNAGE موجودة أيضاً → نختار FADED_SIGNAGE مباشرةً.
            2) غير ذلك:
               - نعطي أولوية للفئات الأخرى بشكل عام.
               - لكن إذا كان تأثير القمامة أكبر بكثير من أقرب فئة أخرى
                 (garbage_impact > GARBAGE_DOMINANCE_FACTOR * best_non_impact)
                 → نختار القمامة.
        - إذا لم توجد إلا فئة واحدة (سواء كانت القمامة أو غيرها):
            → نختار هذه الفئة بشكل طبيعي بناءً على قيمة التأثير.
        """
        if not predictions:
            return "OTHERS", 0.0, None

        stats: Dict[str, Dict[str, Any]] = {}

        # تجميع الإحصائيات لكل كلاس متوقع
        for p in predictions:
            label = p.get("class")
            if not label:
                continue

            conf = float(p.get("confidence", 0.0))
            impact = float(p.get("impact_score", 0.0))
            model_class_id = p.get("class_id")

            if label not in stats:
                stats[label] = {
                    "count": 0,
                    "best_conf": 0.0,
                    "best_class_id": None,
                    "total_impact": 0.0,
                }

            s = stats[label]
            s["count"] += 1
            s["total_impact"] += impact
            if conf > s["best_conf"]:
                s["best_conf"] = conf
                s["best_class_id"] = model_class_id

        if not stats:
            return "OTHERS", 0.0, None

        has_garbage = GARBAGE_CLASS_CODE in stats
        non_garbage_labels = [lbl for lbl in stats.keys() if lbl != GARBAGE_CLASS_CODE]

        # ✅ حالة وجود القمامة + فئات أخرى
        if has_garbage and non_garbage_labels:
            # 1) قاعدة خاصة: إذا كانت FADED_SIGNAGE موجودة مع GARBAGE → اختر FADED_SIGNAGE فوراً
            if FADED_SIGNAGE_CLASS_CODE in stats:
                chosen_stats = stats[FADED_SIGNAGE_CLASS_CODE]
                return (
                    FADED_SIGNAGE_CLASS_CODE,
                    float(chosen_stats["best_conf"]),
                    chosen_stats["best_class_id"],
                )

            # 2) اختيار أفضل فئة غير القمامة حسب التأثير الكلي
            best_label: Optional[str] = None
            best_tuple = (-1.0, -1.0, -1)  # (total_impact, best_conf, count)

            for label in non_garbage_labels:
                s = stats[label]
                candidate = (s["total_impact"], s["best_conf"], s["count"])
                if candidate > best_tuple:
                    best_tuple = candidate
                    best_label = label

            if best_label is None:
                # احتياطاً لو حدث شيء غير متوقع
                best_label = GARBAGE_CLASS_CODE

            # مقارنة تأثير القمامة بأفضل فئة أخرى
            garbage_impact = stats[GARBAGE_CLASS_CODE]["total_impact"]
            best_non_impact = stats.get(best_label, {}).get("total_impact", 0.0)

            if garbage_impact > GARBAGE_DOMINANCE_FACTOR * best_non_impact:
                # إذا كان تأثير القمامة أعلى بكثير → نختار القمامة
                best_label = GARBAGE_CLASS_CODE

            chosen_stats = stats[best_label]
            return (
                best_label,
                float(chosen_stats["best_conf"]),
                chosen_stats["best_class_id"],
            )

        # ⬅️ لا توجد إلا فئة واحدة (أو لا يوجد GARBAGE + فئات أخرى)
        best_label: Optional[str] = None
        best_tuple = (-1.0, -1.0, -1)

        for label, s in stats.items():
            candidate = (s["total_impact"], s["best_conf"], s["count"])
            if candidate > best_tuple:
                best_tuple = candidate
                best_label = label

        if best_label is None:
            return "OTHERS", 0.0, None

        best_conf = float(stats[best_label]["best_conf"])
        best_class_id = stats[best_label]["best_class_id"]
        return best_label, best_conf, best_class_id

    # -------------------------
    # Public API
    # -------------------------

    def predict(self, image_bytes: bytes) -> Tuple[int, float, Dict[str, Any]]:
        """
        تصنيف صورة واحدة باستخدام نموذج YOLOv5 (vp.pt).

        يعيد:
          - report_type_id: رقم نوع التشوه البصري (من 1 إلى 11)
          - confidence: أعلى درجة ثقة للتصنيف النهائي
          - info: يحتوي على التفاصيل (code, name_ar, name_en, model_class_id)
        """
        image = Image.open(io.BytesIO(image_bytes))
        if image.mode != "RGB":
            image = image.convert("RGB")

        width, height = image.size

        # استدلال YOLOv5 – بحسب الإعدادات (حجم الإدخال 640)
        results = self.model(image, size=640)

        raw_predictions = self._extract_predictions(results, width, height)
        class_code, confidence, model_class_id = self._aggregate_predictions(
            raw_predictions
        )

        # لو الكود غير معروف ضمن قاعدة البيانات → نصنفه كـ OTHERS (أخرى)
        if class_code not in REPORT_TYPE_META:
            class_code = "OTHERS"

        meta = REPORT_TYPE_META[class_code]
        report_type_id = meta["id"]
        name_ar = meta["name_ar"]
        name_en = meta["name_en"]

        info: Dict[str, Any] = {
            "code": class_code,
            "name_ar": name_ar,
            "name_en": name_en,
            "model_class_id": model_class_id,
        }

        return report_type_id, float(confidence), info
