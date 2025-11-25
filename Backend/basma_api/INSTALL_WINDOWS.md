Windows install / setup (project: basma_api)

1) Create and activate virtualenv (PowerShell):

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2) Upgrade pip and install runtime requirements:

```powershell
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

3) (Optional) If you need the developer/test packages (inference SDK, CLI), install dev requirements:

```powershell
python -m pip install -r requirements-dev.txt
```

4) Optional: CPU-only PyTorch (recommended on machines without CUDA). Use the official PyTorch index to get the matching wheel:

```powershell
python -m pip install --index-url https://download.pytorch.org/whl/cpu torch==2.9.1 torchvision==0.24.1
```

5) Run the app:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Troubleshooting
- If `pip install -r requirements.txt` fails due to dependency conflicts, consider:
  - Installing core runtime deps only (remove dev-only packages): `pip install -r requirements.txt`
  - Installing dev deps separately: `pip install -r requirements-dev.txt`
- For large ML packages (torch, torchvision, yolov5), installation may take several minutes and significant disk space.
- If you see conflicts related to `pydantic`, `click`, or `Pillow`, check whether `requirements-dev.txt` packages are installed globally or in the venv; prefer keeping dev packages separate.

Notes
- `requirements.txt` is for runtime dependencies used by the FastAPI app.
- `requirements-dev.txt` contains test/dev tools and large inference SDKs that are not required in production.
