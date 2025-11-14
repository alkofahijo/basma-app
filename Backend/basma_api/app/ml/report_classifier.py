# app/ml/report_classifier.py
import io
from typing import List, Tuple, Dict

from PIL import Image
import torch
import torch.nn as nn
import torchvision.transforms as T
from torchvision import models

# عدد أنواع البلاغات
NUM_CLASSES = 6

# ترتيب الكلاسات مثل report_types
# تأكد أن ids تطابق جدول report_types عندك
CLASS_ID_TO_DB_ID = {
    0: 1,  # cleanliness
    1: 2,  # potholes
    2: 3,  # sidewalks
    3: 4,  # walls
    4: 5,  # planting
    5: 6,  # other
}

CLASS_ID_TO_NAME_AR = {
    0: "نظافة",
    1: "حُفر",
    2: "أرصفة",
    3: "جدران",
    4: "زراعة",
    5: "أخرى",
}

# نفس الترتيب بالإنجليزي (اختياري)
CLASS_ID_TO_CODE = {
    0: "cleanliness",
    1: "potholes",
    2: "sidewalks",
    3: "walls",
    4: "planting",
    5: "other",
}


def create_model(num_classes: int = NUM_CLASSES) -> nn.Module:
    """
    Model نفس فكرة EfficientNet أو ResNet مع آخر Layer بعدد الكلاسات.
    هنا مثال بـ ResNet18 للتبسيط.
    """
    model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
    in_features = model.fc.in_features
    model.fc = nn.Linear(in_features, num_classes)
    return model


# تحضير transform (نفسه في التدريب والـ inference)
IMAGE_TRANSFORM = T.Compose(
    [
        T.Resize((224, 224)),
        T.ToTensor(),
        T.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225],
        ),
    ]
)


class ReportClassifierService:
    """
    Service يتحمّل model واحد في الذاكرة ويستعمله في كل request.
    """

    def __init__(self, model_path: str):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = create_model()
        self.model.load_state_dict(torch.load(model_path, map_location=self.device))
        self.model.to(self.device)
        self.model.eval()

    def _prepare_image(self, image_bytes: bytes) -> torch.Tensor:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        tensor = IMAGE_TRANSFORM(img).unsqueeze(0)  # shape [1, C, H, W]
        return tensor.to(self.device)

    def predict(
        self, image_bytes: bytes
    ) -> Tuple[int, float, Dict[str, str]]:
        """
        يرجّع:
        - db_report_type_id
        - confidence
        - info dict فيها names
        """
        with torch.no_grad():
            x = self._prepare_image(image_bytes)
            logits = self.model(x)
            probs = torch.softmax(logits, dim=1)
            conf, pred_class = torch.max(probs, dim=1)
            class_id = int(pred_class.item())
            confidence = float(conf.item())

        db_id = CLASS_ID_TO_DB_ID[class_id]
        name_ar = CLASS_ID_TO_NAME_AR[class_id]
        code = CLASS_ID_TO_CODE[class_id]

        info = {"name_ar": name_ar, "code": code}
        return db_id, confidence, info
