from deepface import DeepFace

ID_IMAGE_PATH = "uploads/id_photo.jpg"
SELFIE_IMAGE_PATH = "uploads/selfie.jpg"

models = ['VGG-Face', 'Facenet', 'OpenFace', 'ArcFace']
#'DeepFace',
# Use model-specific thresholds
thresholds = {
    'VGG-Face': 0.7,      # VGG-Face distances are usually higher
    'Facenet': 0.5,
    'OpenFace': 0.6,
    # 'DeepFace': 0.33,
    'ArcFace': 0.5
}

for model in models:
    result = DeepFace.verify(
        ID_IMAGE_PATH,
        SELFIE_IMAGE_PATH,
        model_name=model,
        enforce_detection=True
    )
    verified = result['distance'] <= thresholds[model]
    print(f"Model: {model} | Verified: {verified} | Distance: {result['distance']:.4f}")
