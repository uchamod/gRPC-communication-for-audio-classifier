gcloud run deploy audio-classifier \
  --image gcr.io/safe-journey-app-597b3/audio-classifier \
  --memory 2Gi \
  --timeout 300 \
  --port 8080 \
  --allow-unauthenticated

  gcloud run deploy audio-classifier `
  --image gcr.io/safe-journey-app-597b3/audio-classifier `
  --memory 2Gi `
  --timeout 300 `
  --port 8080 `
  --allow-unauthenticated `
  --platform managed `
  --region asia-southeast1

  gcloud run deploy audio-classifier --image asia-southeast1-docker.pkg.dev/safe-journey-app-597b3/audio-classifier-repo/audio-classifier --memory 2Gi --cpu 2 --timeout 900 --concurrency 1 --max-instances 1 --port 8080 --allow-unauthenticated --platform managed --region asia-southeast1


  --build docker with cloud run--
  # Config
  gcloud auth configure-docker
  # build
  docker build -t gcr.io/safe-journey-app-597b3/yamnet-flask-app-v4 .
  # push
  docker push gcr.io/safe-journey-app-597b3/yamnet-flask-app-v4
  # verify
  gcloud container images list --repository=gcr.io/safe-journey-app-597b3
  # deploy
  gcloud run deploy yamnet-audio-classifier-v3 --image gcr.io/safe-journey-app-597b3/yamnet-flask-app-v4  --memory 4Gi --cpu 4 --timeout 900s --concurrency 4 --max-instances 10 --min-instances 1 --port 8080 --allow-unauthenticated --platform managed --region asia-southeast1 --cpu-boost

  # Build and push to Google Container Registry
  gcloud builds submit --tag gcr.io/safe-journey-app-597b3/yamnet-flask-app

  gcloud run deploy yamnet-audio-classifier-v2 
  --image gcr.io/safe-journey-app-597b3/yamnet-flask-app-v2 
  --platform managed 
  --region asia-southeast1 
  --allow-unauthenticated 
  --memory 4Gi 
  --cpu 2 
  --timeout 600s 
  --concurrency 4
  --min-instances 1
  --max-instances 10 
  --set-env-vars PORT=8080
  --set-env-vars="PYTHONUNBUFFERED=1


  # past requirments
absl-py==2.3.0
astunparse==1.6.3
audioread==3.0.1
blinker==1.9.0
certifi==2025.4.26
cffi==1.17.1
charset-normalizer==3.4.2
click==8.2.1
colorama==0.4.6
decorator==5.2.1
Flask==3.1.1
flask-cors==6.0.1
flatbuffers==25.2.10
gast==0.6.0
google-pasta==0.2.0
grpcio==1.72.1
h5py==3.13.0
idna==3.10
itsdangerous==2.2.0
Jinja2==3.1.6
joblib==1.5.1
keras==3.10.0
lazy_loader==0.4
libclang==18.1.1
librosa==0.11.0
llvmlite==0.42.0
Markdown==3.8
markdown-it-py==3.0.0
MarkupSafe==3.0.2
mdurl==0.1.2
ml_dtypes==0.5.1
msgpack==1.1.0
namex==0.1.0
numba==0.59.1
numpy
opt_einsum==3.4.0
optree==0.16.0
packaging==25.0
platformdirs==4.3.8
pooch==1.8.2
protobuf==5.29.5
pycparser==2.22
Pygments==2.19.1
requests==2.32.3
rich==14.0.0
scikit-learn==1.6.0
scipy==1.13.0
six==1.17.0
soundfile==0.13.1
soxr==0.5.0.post1
tensorboard==2.19.0
tensorboard-data-server==0.7.2
tensorflow==2.19.0
tensorflow-hub==0.16.1
tensorflow-io-gcs-filesystem==0.31.0
termcolor==3.1.0
tf_keras==2.19.0
threadpoolctl==3.6.0
typing_extensions==4.14.0
urllib3==2.4.0
Werkzeug==3.1.3
wrapt==1.17.2
gunicorn==21.2.0

# GCE deployment
gcloud compute ssh instance-20250628-135104 --zone=asia-southeast1-c

# # Create gunicorn config
bind = "0.0.0.0:8080"
workers = 2 
timeout = 600  
keepalive = 5
max_requests = 1000
max_requests_jitter = 100
threads = 4

# Allow HTTP traffic (run from your local machine, not the instance)
gcloud compute firewall-rules create allow-flask-app --allow tcp:80 --source-ranges 0.0.0.0/0 --description "Allow HTTP traffic for Flask app"


sudo netstat -tlnp | grep :8080