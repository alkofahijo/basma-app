# app/ml/report_classifier.py

from __future__ import annotations

import os
import tempfile
from typing import Tuple, Dict, Any, Optional, List

from inference_sdk import InferenceHTTPClient


class ReportClassifierService:
    """
    خدمة تصنيف البلاغات باستخدام Roboflow Inference Server (workflow مخصص).

    واجهة الاستخدام:
        predict(image_bytes: bytes) -> (report_type_id: int, confidence: float, info: dict)

    حيث:
      - report_type_id: يطابق العمود id في جدول report_types (1..11, 12 لـ "OTHERS")
      - confidence: أعلى قيمة ثقة للكلاس المختار بعد تجميع كل الـ predictions.
      - info: dict يحتوي على:
            - "code": الكود الإنجليزي للكلاس (GRAFFITI, POTHOLES, ...)
            - "name_ar": التسمية بالعربي
            - "name_en": التسمية بالإنجليزي
            - "model_class_id": class_id القادم من الـ workflow (إن وجد)
    """

    def __init__(
        self,
        api_url: str,
        workspace_name: str,
        workflow_id: str,
        api_key: Optional[str] = None,
    ) -> None:
        """
        :param api_url: عنوان خادم الـ Inference (مثال: http://localhost:9001)
        :param workspace_name: اسم الـ workspace في Roboflow
        :param workflow_id: معرف الـ workflow الذي أنشأته
        :param api_key: مفتاح الـ API (اختياري؛ يمكن تركه فارغاً عند استخدام سيرفر محلي)
        """
        # عميل Roboflow Inference
        # لو api_key = None → نمرّر "" حتى لا يكون حقل إجباري
        self.client = InferenceHTTPClient(
            api_url=api_url,
            api_key=api_key or "",
        )
        self.workspace_name = workspace_name
        self.workflow_id = workflow_id

        # الأسماء العربية كما في جدولك
        self.class_name_ar: Dict[str, str] = {
            "GRAFFITI": "كتابة على الجدران",
            "FADED_SIGNAGE": "لافتة باهتة",
            "POTHOLES": "حفر",
            "GARBAGE": "نفايات",
            "CONSTRUCTION_ROAD": "طريق قيد الإنشاء",
            "BROKEN_SIGNAGE": "لافتة مكسورة",
            "BAD_STREETLIGHT": "إنارة طريق تالفة",
            "BAD_BILLBOARD": "لوحة إعلانات تالفة",
            "SAND_ON_ROAD": "أتربة على الطريق",
            "CLUTTER_SIDEWALK": "رصيف غير صالح للمشي",
            "UNKEPT_FACADE": "واجهة مبنى سيئة المظهر",
            "OTHERS": "أخرى",
        }

        # الأسماء الإنجليزية كما في جدولك
        self.class_name_en: Dict[str, str] = {
            "GRAFFITI": "Graffiti",
            "FADED_SIGNAGE": "Faded signage",
            "POTHOLES": "Potholes",
            "GARBAGE": "Garbage",
            "CONSTRUCTION_ROAD": "Road under construction",
            "BROKEN_SIGNAGE": "Broken signage",
            "BAD_STREETLIGHT": "Bad streetlight",
            "BAD_BILLBOARD": "Damaged billboard",
            "SAND_ON_ROAD": "Sand/dust on road",
            "CLUTTER_SIDEWALK": "Cluttered sidewalk",
            "UNKEPT_FACADE": "Unkept facade",
            "OTHERS": "Others",
        }

        # IDs من جدولك (1..11) + 12 لـ OTHERS
        self.report_type_ids: Dict[str, int] = {
            "GRAFFITI": 1,
            "FADED_SIGNAGE": 2,
            "POTHOLES": 3,
            "GARBAGE": 4,
            "CONSTRUCTION_ROAD": 5,
            "BROKEN_SIGNAGE": 6,
            "BAD_STREETLIGHT": 7,
            "BAD_BILLBOARD": 8,
            "SAND_ON_ROAD": 9,
            "CLUTTER_SIDEWALK": 10,
            "UNKEPT_FACADE": 11,
            "OTHERS": 12,
        }

    # -------------------------
    # Helpers
    # -------------------------

    def _run_workflow(self, image_bytes: bytes) -> Any:
        """
        حفظ الصورة مؤقتاً على القرص ثم إرسالها إلى الـ workflow.

        يستدعي:
            self.client.run_workflow(
                workspace_name=self.workspace_name,
                workflow_id=self.workflow_id,
                images={"image": tmp_path},
                use_cache=True,
            )
        """
        tmp_path = None
        try:
            with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
                tmp.write(image_bytes)
                tmp.flush()
                tmp_path = tmp.name

            result = self.client.run_workflow(
                workspace_name=self.workspace_name,
                workflow_id=self.workflow_id,
                images={"image": tmp_path},
                use_cache=True,
            )
            return result
        finally:
            if tmp_path and os.path.exists(tmp_path):
                try:
                    os.remove(tmp_path)
                except OSError:
                    # لا نريد كسر التنفيذ إذا فشل حذف الملف المؤقت
                    pass

    @staticmethod
    def _extract_predictions(result: Any) -> List[Dict[str, Any]]:
        """
        استخراج قائمة الـ predictions من رد الـ workflow.

        نتوقع شكلاً مشابهاً لـ:
        [
          {
            "predictions": {
              "image": {...},
              "predictions": [ {..}, {..}, ... ]
            }
          }
        ]
        """
        root = result
        if isinstance(root, list):
            if not root:
                return []
            root = root[0]

        if not isinstance(root, dict):
            return []

        preds_container = root.get("predictions") or root.get("result") or root
        if not isinstance(preds_container, dict):
            return []

        preds_list = preds_container.get("predictions")
        if not isinstance(preds_list, list):
            return []

        return preds_list

    @staticmethod
    def _aggregate_predictions(
        predictions: List[Dict[str, Any]],
    ) -> Tuple[str, float, Optional[int]]:
        """
        - لو توجد أكثر من prediction نختار الكلاس الأكثر تكراراً.
        - في حال التعادل في عدد التكرار نختار الكلاس ذو أعلى confidence.

        يرجع:
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
        تشغيل الـ workflow على صورة واحدة (bytes).

        يرجع:
          - report_type_id (int)  → يطابق جدولك (1..11, 12)
          - confidence (float)    → أعلى ثقة للكلاس المختار
          - info (dict)           → يحتوي على code, name_ar, name_en, model_class_id
        """
        result = self._run_workflow(image_bytes)
        predictions = self._extract_predictions(result)

        class_code, confidence, model_class_id = self._aggregate_predictions(
            predictions
        )

        # لو الكود غير معروف نعتبره OTHERS
        if class_code not in self.report_type_ids:
            class_code = "OTHERS"

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
