# app/scripts/test_report_classifier.py

import mysql.connector

from app.ml.report_classifier import ReportClassifierService
from app.scripts.train_report_classifier import (
    PROJECT_ROOT,
    ReportsImageDataset,
    DB_CONFIG,
)


def load_one_training_record():
    """
    نجيب سجل واحد من جدول reports
    فيه:
      - image_before_url
      - report_type_id
    نفس ما استخدمناه في التدريب.
    """
    conn = mysql.connector.connect(**DB_CONFIG)
    cur = conn.cursor()

    cur.execute(
        """
        SELECT image_before_url, report_type_id
        FROM reports
        WHERE image_before_url IS NOT NULL
          AND report_type_id IS NOT NULL
        LIMIT 1
        """
    )
    row = cur.fetchone()

    cur.close()
    conn.close()

    return row


def main():
    # 1) نحمّل سجل واحد من DB
    row = load_one_training_record()
    if not row:
        print("لا يوجد أي بيانات تدريب في جدول reports (image_before_url + report_type_id).")
        return

    image_url, report_type_id = row
    print(f"Using DB record:")
    print(f"  image_before_url = {image_url}")
    print(f"  report_type_id   = {report_type_id}")

    # 2) نستخدم نفس ReportsImageDataset من سكربت التدريب
    # فقط عشان نستفيد من _resolve_image_path ونفس منطق المسارات
    dummy_dataset = ReportsImageDataset([row])

    # نستعمل الدالة الداخلية _resolve_image_path
    # اللي كتبناها في train_report_classifier.py
    img_path = dummy_dataset._resolve_image_path(image_url)

    print(f"Resolved image path on disk:")
    print(f"  {img_path}")

    # 3) نحمّل الموديل
    model_path = PROJECT_ROOT / "app" / "models" / "report_classifier.pt"
    print(f"\nLoading model from: {model_path}")

    service = ReportClassifierService(model_path=str(model_path))

    # 4) نقرأ الصورة كبايت ونجرب التنبؤ
    with open(img_path, "rb") as f:
        img_bytes = f.read()

    db_id, confidence, info = service.predict(img_bytes)

    print("\n=== Prediction Result ===")
    print(f"Predicted report_type_id (DB id): {db_id}")
    print(f"Class name_ar: {info.get('name_ar')}")
    print(f"Class code:    {info.get('code')}")
    print(f"Confidence:    {confidence:.4f}")


if __name__ == "__main__":
    main()
