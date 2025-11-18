from __future__ import annotations

import io
from typing import Tuple, Dict, Any, Optional, List

from PIL import Image
from ultralytics import YOLO


class ReportClassifierService:
    """
    خدمة تصنيف البلاغات باستخدام نموذج YOLOv8 محلي (بدون الاعتماد على خادم خارجي).

    واجهة الاستخدام:
        predict(image_bytes: bytes) -> (report_type_id: int, confidence: float, info: dict)

    حيث:
      - report_type_id: يطابق العمود ID في جدول report_types (1..10، و 11 لفئة "OTHERS")
      - confidence: أعلى قيمة ثقة للكلاس المختار بعد تجميع جميع التنبؤات
      - info: dict يحتوي على:
            - "code": الكود الإنجليزي للتصنيف (مثل GRAFFITI, POTHOLES, ...)
            - "name_ar": التسمية باللغة العربية
            - "name_en": التسمية باللغة الإنجليزية
            - "model_class_id": معرف التصنيف داخل نموذج YOLO (إن وجد)
    """

    def __init__(self, model_path: str) -> None:
        """
        تهيئة خدمة التصنيف بتحميل نموذج YOLOv8 من الملف المحدد.
        :param model_path: المسار إلى ملف نموذج YOLOv8 (.pt)
        """
        # تحميل نموذج YOLOv8 المدرب
        self.model = YOLO(model_path)

        # أسماء التصنيفات باللغة العربية (مطابقة لجدول report_types في قاعدة البيانات)
        # IDs في قاعدة البيانات:
        # 1  GRAFFITI
        # 2  FADED_SIGNAGE
        # 3  POTHOLES
        # 4  GARBAGE
        # 5  CONSTRUCTION_ROAD
        # 6  BROKEN_SIGNAGE
        # 7  BAD_BILLBOARD
        # 8  SAND_ON_ROAD
        # 9  CLUTTER_SIDEWALK
        # 10 UNKEPT_FACADE
        # 11 OTHERS
        self.class_name_ar: Dict[str, str] = {
            "GRAFFITI": "كتابة على الجدران",
            "FADED_SIGNAGE": "لافتة باهتة",
            "POTHOLES": "حفر",
            "GARBAGE": "نفايات",
            "CONSTRUCTION_ROAD": "طريق قيد الإنشاء",
            "BROKEN_SIGNAGE": "لافتة مكسورة",
            "BAD_BILLBOARD": "لوحة إعلانات تالفة",
            "SAND_ON_ROAD": "أتربة على الطريق",
            "CLUTTER_SIDEWALK": "رصيف غير صالح للمشي",
            "UNKEPT_FACADE": "واجهة مبنى سيئة المظهر",
            "OTHERS": "أخرى",
        }

        # أسماء التصنيفات باللغة الإنجليزية
        self.class_name_en: Dict[str, str] = {
            "GRAFFITI": "Graffiti",
            "FADED_SIGNAGE": "Faded signage",
            "POTHOLES": "Potholes",
            "GARBAGE": "Garbage",
            "CONSTRUCTION_ROAD": "Road under construction",
            "BROKEN_SIGNAGE": "Broken signage",
            "BAD_BILLBOARD": "Damaged billboard",
            "SAND_ON_ROAD": "Sand/dust on road",
            "CLUTTER_SIDEWALK": "Cluttered sidewalk",
            "UNKEPT_FACADE": "Unkept facade",
            "OTHERS": "Others",
        }

        # المعرفات الرقمية لكل تصنيف كما هي في قاعدة البيانات
        self.report_type_ids: Dict[str, int] = {
            "GRAFFITI": 1,
            "FADED_SIGNAGE": 2,
            "POTHOLES": 3,
            "GARBAGE": 4,
            "CONSTRUCTION_ROAD": 5,
            "BROKEN_SIGNAGE": 6,
            "BAD_BILLBOARD": 7,
            "SAND_ON_ROAD": 8,
            "CLUTTER_SIDEWALK": 9,
            "UNKEPT_FACADE": 10,
            "OTHERS": 11,
        }

    # -------------------------
    # Helpers
    # -------------------------

    @staticmethod
    def _aggregate_predictions(
        predictions: List[Dict[str, Any]],
    ) -> Tuple[str, float, Optional[int]]:
        """
        تجميع نتائج النموذج المتعددة لصورة واحدة:
        - إذا وُجد أكثر من تنبؤ، نختار التصنيف الأكثر تكراراً بين المخرجات.
        - في حال تساوي التكرار، نختار التصنيف ذو أعلى نسبة ثقة.

        يعيد:
          (selected_class_code, best_confidence, model_class_id)
        """
        if not predictions:
            return "OTHERS", 0.0, None

        stats: Dict[str, Dict[str, Any]] = {}
        for p in predictions:
            label = p.get("class")
            if not label:
                continue

            try:
                conf = float(p.get("confidence", 0.0))
            except (TypeError, ValueError):
                conf = 0.0

            model_class_id = p.get("class_id")

            if label not in stats:
                stats[label] = {
                    "count": 0,
                    "best_conf": 0.0,
                    "best_class_id": None,
                }

            stats[label]["count"] += 1
            if conf > stats[label]["best_conf"]:
                stats[label]["best_conf"] = conf
                stats[label]["best_class_id"] = model_class_id

        if not stats:
            return "OTHERS", 0.0, None

        # اختيار التصنيف ذو أعلى تكرار (وفي حالة التساوي، أعلى ثقة)
        best_label: Optional[str] = None
        best_count = -1
        best_conf_at_tie = -1.0

        for label, s in stats.items():
            count = s["count"]
            conf = s["best_conf"]
            if count > best_count or (count == best_count and conf > best_conf_at_tie):
                best_label = label
                best_count = count
                best_conf_at_tie = conf

        if best_label is None:
            return "OTHERS", 0.0, None

        best_class_id = stats[best_label]["best_class_id"]
        return best_label, float(best_conf_at_tie), best_class_id

    # -------------------------
    # Public API
    # -------------------------

    def predict(self, image_bytes: bytes) -> Tuple[int, float, Dict[str, Any]]:
        """
        تصنيف صورة واحدة (على شكل بايتات) باستخدام نموذج YOLOv8 المحلي.

        يعيد:
          - report_type_id (int): معرّف نوع التشوه البصري في قاعدة البيانات (1..10 أو 11 لـ OTHERS)
          - confidence (float): درجة الثقة في التصنيف المختار
          - info (dict): معلومات إضافية تشمل code, name_ar, name_en, model_class_id
        """
        # تحويل البايتات إلى صورة باستخدام PIL
        image = Image.open(io.BytesIO(image_bytes))
        if image.mode != "RGB":
            image = image.convert("RGB")  # تحويل الصورة إلى RGB إذا لم تكن بالفعل

        # تنفيذ الاستدلال باستخدام نموذج YOLOv8
        results = self.model(image)
        predictions: List[Dict[str, Any]] = []

        # استخلاص جميع التنبؤات (المكتشفات) من نتيجة النموذج
        if len(results) > 0:
            result = results[0]  # نتيجة الصورة الوحيدة
            boxes = result.boxes  # الكائنات المكتشفة
            if boxes:
                # نمرّ على كل كائن مكتشف لاستخراج فئته وثقته
                for cls_idx, conf in zip(boxes.cls, boxes.conf):
                    label = self.model.names[int(cls_idx)]
                    predictions.append(
                        {
                            "class": label,
                            "confidence": float(conf),
                            "class_id": int(cls_idx),
                        }
                    )

        # تحديد التصنيف النهائي للصورة
        class_code, confidence, model_class_id = self._aggregate_predictions(
            predictions
        )

        # في حال كان التصنيف غير معروف (احتياطياً) نجعله "OTHERS"
        if class_code not in self.report_type_ids:
            class_code = "OTHERS"

        # جلب معرّف التصنيف من الجدول والأسماء باللغتين
        report_type_id = self.report_type_ids[class_code]
        name_ar = self.class_name_ar[class_code]
        name_en = self.class_name_en[class_code]

        info: Dict[str, Any] = {
            "code": class_code,
            "name_ar": name_ar,
            "name_en": name_en,
            "model_class_id": model_class_id,
        }
        return report_type_id, confidence, info
