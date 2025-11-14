# app/scripts/train_report_classifier.py

import os
from pathlib import Path
from typing import List, Tuple

import mysql.connector
from PIL import Image
from tqdm import tqdm

import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader

from app.ml.report_classifier import (
    create_model,
    IMAGE_TRANSFORM,
    CLASS_ID_TO_DB_ID,
)
from app.db import (
    MYSQL_HOST,
    MYSQL_PORT,
    MYSQL_USER,
    MYSQL_PASSWORD,
    MYSQL_DB,
)

# =========================
# إعدادات الاتصال بقاعدة البيانات
# =========================

DB_CONFIG = {
    "host": MYSQL_HOST,
    "port": MYSQL_PORT,
    "user": MYSQL_USER,
    "password": MYSQL_PASSWORD,
    "database": MYSQL_DB,
}

# =========================
# مسارات المشروع والصور
# =========================
# نفترض structure زي:
#   <project_root>/app/...
#   <project_root>/static/...
#   أو:
#   <project_root>/app/static/...
#
# وقيمة image_before_url في DB تكون مثل:
#   /static/uploads/file.jpg
# أو:
#   static/uploads/file.jpg

PROJECT_ROOT = Path(__file__).resolve().parents[2]  # .../basma_api

# جذور محتملة للـ static
STATIC_ROOTS = [
    PROJECT_ROOT / "static",        # basma_api/static
    PROJECT_ROOT / "app" / "static" # basma_api/app/static
]


class ReportsImageDataset(Dataset):
    """
    Dataset بسيط يقرأ:
      - مسار الصورة (image_before_url) من قاعدة البيانات
      - نوع البلاغ (report_type_id)
    ثم يحوّل report_type_id إلى class_id (0..NUM_CLASSES-1)
    باستخدام CLASS_ID_TO_DB_ID من app.ml.report_classifier
    """

    def __init__(self, records: List[Tuple[str, int]]):
        self.records = records

    def __len__(self):
        return len(self.records)

    def _resolve_image_path(self, url: str) -> str:
        """
        يحوّل قيمة image_before_url القادمة من DB إلى مسار فعلي على القرص.
        أمثلة مدعومة:
          /static/uploads/file.jpg
          static/uploads/file.jpg
          uploads/file.jpg
          file.jpg
        ويحاول يبحث في:
          <project_root>/static/...
          <project_root>/app/static/...
        """
        if not url:
            raise ValueError("Empty image url from DB")

        original_url = url

        # شيل أي باراميتر بعد ؟ لو فيه
        url = url.split("?", 1)[0]
        # توحيد السلاشات
        url = url.replace("\\", "/")

        # URL كامل (HTTP) مش مدعوم في هذا السكربت
        if url.startswith("http://") or url.startswith("https://"):
            raise ValueError(f"HTTP image URLs are not supported in training: {url}")

        # شيل السلاش الأول لو موجود
        if url.startswith("/"):
            url = url[1:]  # "static/uploads/..."

        # الآن نبني مسار نسبي تحت static
        # لو url يبدأ بـ static/ نستخدمه كما هو، غير هيك نحاول نبنيه
        if url.startswith("static/"):
            rel_under_static = url[len("static/"):]  # "uploads/file.jpg" أو غيره
        else:
            # لو يبدأ بـ uploads/ نخليه كما هو، غير هيك نخلي بس اسم الملف
            if url.startswith("uploads/"):
                rel_under_static = url  # "uploads/file.jpg"
            else:
                # مجرد اسم ملف أو مسار غريب -> نأخذ فقط اسم الملف
                filename = os.path.basename(url)
                rel_under_static = os.path.join("uploads", filename)  # "uploads/file.jpg"

        tried_paths = []

        for root in STATIC_ROOTS:
            candidate = root / rel_under_static  # مثل: <root>/uploads/file.jpg
            tried_paths.append(str(candidate))
            if candidate.is_file():
                return str(candidate)

        # لو ولا واحد من المسارات موجود -> نرمي خطأ واضح
        msg = (
            f"Image file not found for image_before_url='{original_url}'.\n"
            f"  Tried paths:\n    - " + "\n    - ".join(tried_paths)
        )
        raise FileNotFoundError(msg)

    def __getitem__(self, idx):
        url, report_type_id = self.records[idx]

        img_path = self._resolve_image_path(url)

        img = Image.open(img_path).convert("RGB")
        x = IMAGE_TRANSFORM(img)

        # map report_type_id في DB إلى class_id (0..5)
        class_id = None
        for k, v in CLASS_ID_TO_DB_ID.items():
            if v == report_type_id:
                class_id = k
                break

        if class_id is None:
            raise ValueError(f"Unknown report_type_id: {report_type_id}")

        y = class_id
        return x, y


def load_training_records() -> List[Tuple[str, int]]:
    """
    يقرأ بيانات التدريب من جدول reports:
      - image_before_url: مسار / اسم ملف الصورة
      - report_type_id: نوع البلاغ (يرتبط بـ CLASS_ID_TO_DB_ID)
    """
    conn = mysql.connector.connect(**DB_CONFIG)
    cur = conn.cursor()

    cur.execute(
        """
        SELECT image_before_url, report_type_id
        FROM reports
        WHERE image_before_url IS NOT NULL
          AND report_type_id IS NOT NULL
        """
    )
    rows = cur.fetchall()

    cur.close()
    conn.close()

    return rows


def train(
    batch_size: int = 32,
    epochs: int = 5,
    learning_rate: float = 1e-4,
):
    # 1) تحميل البيانات من الـ DB
    records = load_training_records()
    print(f"Loaded {len(records)} labeled images from DB")

    if not records:
        print("No training data found. Make sure reports table has images + report_type_id.")
        return

    # 2) تجهيز الـ Dataset / DataLoader
    dataset = ReportsImageDataset(records)
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)

    # 3) تجهيز الموديل
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")

    model = create_model()  # من app.ml.report_classifier
    model.to(device)

    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)

    # 4) حلقة التدريب
    for epoch in range(epochs):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0

        print(f"\nEpoch {epoch + 1}/{epochs}")
        for inputs, labels in tqdm(dataloader, desc=f"Epoch {epoch + 1}/{epochs}"):
            inputs = inputs.to(device)
            labels = labels.to(device)

            optimizer.zero_grad()

            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item() * inputs.size(0)

            _, preds = torch.max(outputs, 1)
            total += labels.size(0)
            correct += (preds == labels).sum().item()

        epoch_loss = running_loss / total
        epoch_acc = correct / total
        print(f"Loss: {epoch_loss:.4f}  Acc: {epoch_acc:.4f}")

    # 5) حفظ الموديل
    models_dir = PROJECT_ROOT / "app" / "models"
    os.makedirs(models_dir, exist_ok=True)

    model_path = models_dir / "report_classifier.pt"
    torch.save(model.state_dict(), str(model_path))

    print(f"\nModel saved to {model_path}")


if __name__ == "__main__":
    train()
