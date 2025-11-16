# app/ml/report_classifier.py

from __future__ import annotations

import io
from typing import Tuple, Dict, Any, Optional

import torch
from torch import nn
from torchvision import models, transforms
from PIL import Image


class ReportClassifierService:
    """
    خدمة تصنيف البلاغات باستخدام ResNet18 مدرَّب على 11 فئة:

      1  GRAFFITI            كتابة على الجدران
      2  FADED_SIGNAGE       لافتة باهتة
      3  POTHOLES            حفر
      4  GARBAGE             نفايات
      5  CONSTRUCTION_ROAD   طريق قيد الإنشاء
      6  BROKEN_SIGNAGE      لافتة مكسورة
      7  BAD_STREETLIGHT     إنارة طريق تالفة
      8  BAD_BILLBOARD       لوحة إعلانات تالفة
      9  SAND_ON_ROAD        أتربة على الطريق
      10 CLUTTER_SIDEWALK    رصيف غير صالح للمشي
      11 UNKEPT_FACADE       واجهة مبنى سيئة المظهر

    توقيع الدالة predict:
        predict(image_bytes: bytes) -> (report_type_id: int, confidence: float, info: dict)

    حيث:
      - report_type_id: يطابق العمود id في جدولك (1..11)
      - confidence: أعلى احتمال (softmax)
      - info: dict يحتوي على:
            - "code": الكود الإنجليزي للكلاس (GRAFFITI, POTHOLES, ...)
            - "name_ar": التسمية بالعربي
            - "name_en": التسمية بالإنجليزي
            - "pred_idx": رقم الفئة (0..10)
    """

    def __init__(self, model_path: str, device: Optional[str] = None) -> None:
        # -------------------------
        # 1. الجهاز (CPU / GPU)
        # -------------------------
        if device is not None:
            self.device = torch.device(device)
        else:
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        # -------------------------
        # 2. تعريف الكلاسات (نفس ترتيب التدريب)
        # -------------------------
        self.class_codes = [
            "GRAFFITI",
            "FADED_SIGNAGE",
            "POTHOLES",
            "GARBAGE",
            "CONSTRUCTION_ROAD",
            "BROKEN_SIGNAGE",
            "BAD_STREETLIGHT",
            "BAD_BILLBOARD",
            "SAND_ON_ROAD",
            "CLUTTER_SIDEWALK",
            "UNKEPT_FACADE",
        ]

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
        }

        # IDs من جدولك (1..11)
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
        }

        # -------------------------
        # 3. بناء الموديل (ResNet18)
        # -------------------------
        try:
            # torchvision >= 0.13 تقريبًا
            weights = models.ResNet18_Weights.IMAGENET1K_V1
            backbone = models.resnet18(weights=weights)
        except AttributeError:
            # لو نسخة قديمة
            backbone = models.resnet18(pretrained=True)

        num_features = backbone.fc.in_features

        # رأس تصنيف (output = 11 كلاس)
        backbone.fc = nn.Sequential(
            nn.Linear(num_features, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, len(self.class_codes)),
        )

        self.model = backbone.to(self.device)

        # تحميل الأوزان من الملف
        state_dict = torch.load(model_path, map_location=self.device)
        self.model.load_state_dict(state_dict)
        self.model.eval()

        # -------------------------
        # 4. الـ transforms (نفس التدريب)
        # -------------------------
        self.transform = transforms.Compose(
            [
                transforms.Resize((224, 224)),
                transforms.ToTensor(),
                transforms.Normalize(
                    mean=[0.485, 0.456, 0.406],
                    std=[0.229, 0.224, 0.225],
                ),
            ]
        )

    # -------------------------
    # Helpers
    # -------------------------

    def _preprocess(self, image_bytes: bytes) -> torch.Tensor:
        """
        يحوّل bytes إلى Tensor جاهز للموديل (1, 3, 224, 224)
        """
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        tensor = self.transform(image).unsqueeze(0).to(self.device)
        return tensor

    # -------------------------
    # Public API
    # -------------------------

    def predict(self, image_bytes: bytes) -> Tuple[int, float, Dict[str, Any]]:
        """
        تشغيل الموديل على صورة واحدة (bytes).

        يرجع:
          - report_type_id (int)  → يطابق جدولك (1..11)
          - confidence (float)    → أعلى احتمال (softmax)
          - info (dict)           → يحتوي على code, name_ar, name_en, pred_idx
        """
        x = self._preprocess(image_bytes)

        with torch.no_grad():
            logits = self.model(x)[0]  # (num_classes,)
            probs = torch.softmax(logits, dim=0)
            conf, pred_idx = torch.max(probs, dim=0)

        pred_idx_int = int(pred_idx.item())
        confidence = float(conf.item())

        # مأخوذ من نفس ترتيب التدريب
        class_code = self.class_codes[pred_idx_int]
        name_ar = self.class_name_ar[class_code]
        name_en = self.class_name_en[class_code]
        report_type_id = self.report_type_ids[class_code]

        info: Dict[str, Any] = {
            "code": class_code,
            "name_ar": name_ar,
            "name_en": name_en,
            "pred_idx": pred_idx_int,
        }

        return report_type_id, confidence, info
