# KYC Verification API (FastAPI + DeepFace)

A lightweight HTTP service that verifies whether a selfie matches an ID photo using multiple DeepFace models with **OR aggregation**. Accepts two images via `multipart/form-data` and returns per-model distances plus an overall `verified_any` flag.

---

## Features

* **FastAPI endpoint:** `POST /verify`
* **Models:** VGG-Face, Facenet, OpenFace, ArcFace
* **OR aggregation:** verification passes if **any** selected model passes
* **CORS enabled** for development
* **Safe temp-file handling** and clean-up

---

## Requirements

Create a Python virtual environment and install the dependencies below.

**requirements.txt**

```
fastapi==0.110.0
uvicorn[standard]==0.27.1
python-multipart==0.0.9
deepface==0.0.89
tensorflow==2.15.0
tf-keras==2.15.0
opencv-python==4.9.0.80
numpy==1.23.5
Pillow==10.2.0
```

**Notes**

* CPU default is fine. For GPU, replace `tensorflow==2.15.0` with a CUDA-matched build according to official guidance.
* The first run may take longer while model weights are downloaded to the DeepFace cache.

---

## Project Structure

```
main.py              # FastAPI app with /verify endpoint
requirements.txt     # pinned package versions compatible with DeepFace and TF
```

---

## Setup

### Clone and create a virtual environment

**Windows (PowerShell)**

```powershell
python -m venv .venv
.venv\Scripts\activate
```

**macOS/Linux**

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### Install dependencies

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### Environment variables (optional)

To customize DeepFace model cache directory:

**Windows**

```powershell
set DEEPFACE_HOME=C:\path\to\cache
```

**macOS/Linux**

```bash
export DEEPFACE_HOME=/path/to/cache
```

---

## Running the Server

**Development run**

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 5005
```

**Access**

* Root path `/` is not defined and will return 404 (expected).
* Only `POST /verify` is implemented.

**Local access matrix**

| Client           | URL                                                                |
| ---------------- | ------------------------------------------------------------------ |
| Same machine     | [http://localhost:5005](http://localhost:5005)                     |
| Android emulator | [http://10.0.2.2:5005](http://10.0.2.2:5005)                       |
| iOS simulator    | [http://localhost:5005](http://localhost:5005)                     |
| Physical device  | http\://<PC-LAN-IP>:5005 (ensure firewall allows inbound TCP 5005) |

---

## API Reference

### POST /verify

**Description:** Verifies a selfie against an ID image using multiple DeepFace models. Uses OR logic (passes if any model passes threshold).

**Content-Type:** `multipart/form-data`

**Form fields**

* `id_image`: file, required
* `selfie_image`: file, required
* `doc_type`: string, optional (e.g., "Aadhar", "Driving License")
* `models`: string, optional

  * JSON array string: `["VGG-Face","Facenet"]`
  * Or comma-separated: `VGG-Face,Facenet`
  * Default: `["VGG-Face","Facenet","OpenFace","ArcFace"]`
* `thresholds`: string, optional

  * JSON object string: `{ "VGG-Face":0.7,"Facenet":0.5 }`
  * Defaults:

    * VGG-Face: 0.7
    * Facenet: 0.5
    * OpenFace: 0.6
    * ArcFace: 0.5

**Response 200 application/json**

```json
{
  "ok": true,
  "doc_type": "Aadhar",
  "results": [
    {"model": "VGG-Face", "verified": true, "distance": 0.6980},
    {"model": "Facenet", "verified": true, "distance": 0.4831},
    {"model": "OpenFace", "verified": true, "distance": 0.5594},
    {"model": "ArcFace", "verified": false, "distance": 0.6809}
  ],
  "verified_any": true
}
```

**Errors**

* `400–422`: Validation issues with form fields
* `500`: Verification or internal server error (message in detail)

---

## Curl Examples

**Basic test**

```bash
curl -F "id_image=@C:/path/id.jpg" -F "selfie_image=@C:/path/selfie.jpg" -F "doc_type=Aadhar" http://localhost:5005/verify
```

**Specify models and thresholds**

```bash
curl -F "id_image=@/path/id.jpg" -F "selfie_image=@/path/selfie.jpg" -F 'models=["ArcFace","Facenet"]' -F 'thresholds={"ArcFace":0.5,"Facenet":0.5}' http://localhost:5005/verify
```

**Windows CMD quoting**

* Use forward slashes or wrap the entire `@C:/...` path in double quotes.

---

## Integration Notes

**Frontend (Flutter)**

* Upload both images and `doc_type` via multipart to `POST /verify`.
* Treat `verified_any` as the decision flag for KYC pass (OR aggregation).
* On success, update application database (e.g., `profiles.is_verified` and `kyc_info`).
* Ensure correct base URL per runtime:

  * Web/desktop: [http://localhost:5005](http://localhost:5005)
  * Android emulator: [http://10.0.2.2:5005](http://10.0.2.2:5005)
  * Physical device: http\://<PC-LAN-IP>:5005

**CORS**

* Development uses `allow_origins=["*"]`.
* For production, restrict to known origins and tighten `allow_methods`/`headers` as needed.

**Performance**

* First call may be slower due to model downloads/initialization.
* Subsequent calls are faster as models are cached in memory and on disk.
* Consider starting the server once and keeping it resident for best latency.

**Security**

* This server accepts arbitrary images; deploy behind trusted networks or gateways.
* For production, add authentication/authorization and rate limiting at the edge.
* Sanitize and log `doc_type` and request metadata for auditability.

---

## Troubleshooting

* “Not Found” on `/`: expected, since only `/verify` exists.
* No server logs for `POST /verify`: check client base URL, firewall, and CORS errors in browser console.
* Import or version errors: recreate venv and `pip install -r requirements.txt`; ensure compatible TensorFlow and Keras versions.
* If GPU: verify CUDA/cuDNN versions match the TensorFlow build matrix.

---

## License

This integration wraps DeepFace; follow its license and model licenses where applicable.
