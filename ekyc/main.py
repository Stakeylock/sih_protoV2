# main.py
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from deepface import DeepFace
import uvicorn
import tempfile
import os
import json
from typing import Optional, List, Dict

app = FastAPI(title="KYC Verification API", version="1.0.0")  # [1]

# CORS for development; tighten for production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # change to trusted domains for prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)  # [1]

DEFAULT_MODELS: List[str] = ["VGG-Face", "Facenet", "OpenFace", "ArcFace"]  # [3]
DEFAULT_THRESHOLDS: Dict[str, float] = {"VGG-Face": 0.7, "Facenet": 0.5, "OpenFace": 0.6, "ArcFace": 0.5}  # [3]

@app.post("/verify")
async def verify(
    id_image: UploadFile = File(...),
    selfie_image: UploadFile = File(...),
    doc_type: Optional[str] = Form(None),
    models: Optional[str] = Form(None),       # JSON array string or comma-separated
    thresholds: Optional[str] = Form(None),   # JSON object string
):
    id_path = selfie_path = None
    try:
        # Save incoming files to temp paths
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(id_image.filename or "")[-1]) as f1:
            f1.write(await id_image.read())
            id_path = f1.name  # [1]
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(selfie_image.filename or "")[-1]) as f2:
            f2.write(await selfie_image.read())
            selfie_path = f2.name  # [1]

        # Parse models
        model_list = DEFAULT_MODELS[:]
        if models:
            m = models.strip()
            if m.startswith("["):
                model_list = json.loads(m)
            else:
                model_list = [s.strip() for s in m.split(",") if s.strip()]  # [1]

        # Parse thresholds
        thr = DEFAULT_THRESHOLDS.copy()
        if thresholds:
            thr.update(json.loads(thresholds))  # [1]

        # OR aggregation: pass if any model passes
        results = []
        any_verified = False
        for m in model_list:
            res = DeepFace.verify(id_path, selfie_path, model_name=m, enforce_detection=True)  # [3]
            distance = float(res["distance"])
            passed = distance <= thr.get(m, 0.5)
            any_verified = any_verified or passed
            results.append({"model": m, "verified": passed, "distance": distance})  # [3]

        return {
            "ok": True,
            "doc_type": doc_type,
            "results": results,
            "verified_any": any_verified,
        }  # [1]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))  # [1]
    finally:
        for p in [id_path, selfie_path]:
            if p and os.path.exists(p):
                try:
                    os.remove(p)
                except:
                    pass  # [1]

if __name__ == "__main__":
    # Dev command: uvicorn main:app --reload --host 0.0.0.0 --port 5005
    uvicorn.run("main:app", host="0.0.0.0", port=5005)  # [1]
