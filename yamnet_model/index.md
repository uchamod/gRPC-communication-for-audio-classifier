# flask backend deployment in GCE

# SSH into your instance
gcloud compute ssh YOUR_INSTANCE_NAME --zone=YOUR_ZONE

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Python, pip, and essential tools
sudo apt install python3 python3-pip python3-venv git nginx -y

# Install system dependencies for audio processing
sudo apt install ffmpeg libsndfile1 -y

# Navigate to your preferred directory
cd /home/$USER

# Clone your repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install your requirements
pip install -r requirements.txt

# If you don't have a requirements.txt, install common dependencies:
pip install flask tensorflow tensorflow-hub librosa numpy pandas gunicorn

# Test run your Flask app
python app.py  # or whatever your main file is called

# Test in another terminal (open new SSH session)
curl http://localhost:5000  # or your app's port

# Create gunicorn config
nano gunicorn_config.py

bind = "0.0.0.0:8000"
workers = 2  # Adjust based on your instance specs
timeout = 300  # Increase for YAMNet processing
keepalive = 2
max_requests = 1000
max_requests_jitter = 100

# Create service file
sudo nano /etc/systemd/system/flask-app.service

[Unit]
Description=Flask App with YAMNet
After=network.target

[Service]
User=YOUR_USERNAME
Group=www-data
WorkingDirectory=/home/YOUR_USERNAME/YOUR_REPO_NAME
Environment="PATH=/home/YOUR_USERNAME/YOUR_REPO_NAME/venv/bin"
ExecStart=/home/YOUR_USERNAME/YOUR_REPO_NAME/venv/bin/gunicorn -c gunicorn_config.py app:app
Restart=always

[Install]
WantedBy=multi-user.target

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/flask-app

server {
    listen 80;
    server_name YOUR_EXTERNAL_IP;  # Use your instance's external IP

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Increase timeout for YAMNet processing
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    # Increase client max body size for audio uploads
    client_max_body_size 50M;
}

# Enable the site
sudo ln -s /etc/nginx/sites-available/flask-app /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Allow HTTP traffic (run from your local machine, not the instance)
# also can create from gcp end
gcloud compute firewall-rules create allow-flask-app \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTP traffic for Flask app"

# Start and enable your Flask app service
sudo systemctl start flask-app
sudo systemctl enable flask-app

# Check status
sudo systemctl status flask-app

# Check Nginx status
sudo systemctl status nginx

# test deployment using postman or relevant tool

### trouble shooting

# Check Flask app logs
sudo journalctl -u flask-app -f

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Restart services
sudo systemctl restart flask-app
sudo systemctl restart nginx

# Check if ports are listening
sudo netstat -tlnp | grep :8000
sudo netstat -tlnp | grep :80



###  additional consideration and troubleshooting tips

# Make sure you're in your home directory
cd ~

# Check current directory
pwd  # Should show /home/your_username

# Clone the repository
git clone https://github.com/YOUR_USERNAME/YAMNet-audio-classfication-with-flask.git

# Create  directory 
mkdir ~/YAMNet-audio-classfication-with-flask

# Create directory with proper ownership
sudo mkdir -p /var/www/YAMNet-audio-classfication-with-flask

# Change ownership to your user
sudo chown $USER:$USER /var/www/YAMNet-audio-classfication-with-flask

# Check where you are
pwd

# Check permissions of current directory
ls -la

# If you're in a restricted directory, go to home
cd ~

# Check your current username
whoami

# Check if the user exists in the system
id $USER

# use above username for service file

# Check if your project directory exists
ls -la /home/$USER/YAMNet-audio-classfication-with-flask

# Check if virtual environment exists
ls -la /home/$USER/YAMNet-audio-classfication-with-flask/venv

# Check if gunicorn is installed in venv
ls -la /home/$USER/YAMNet-audio-classfication-with-flask/venv/bin/gunicorn

# Navigate to your project
cd /home/$USER/YAMNet-audio-classfication-with-flask

# Activate virtual environment
source venv/bin/activate

# Test gunicorn manually
gunicorn -c gunicorn_config.py app:app

# Reload systemd
sudo systemctl daemon-reload

# Start the service
sudo systemctl start flask-app

# Check status
sudo systemctl status flask-app

# If it fails, check detailed logs
sudo journalctl -u flask-app -n 50

### trobleshoooting dependencies issue

# Update package list
sudo apt update

# Install FFmpeg
sudo apt install ffmpeg -y

# Verify installation
ffmpeg -version
which ffmpeg

# Navigate to your project
cd /home/$USER/YAMNet-audio-classfication-with-flask

# Activate virtual environment
source venv/bin/activate

# Install/update audio processing libraries
pip install librosa soundfile pydub --upgrade

# Restart the Flask service
sudo systemctl restart flask-app

# Check status
sudo systemctl status flask-app

# Monitor logs
sudo journalctl -u flask-app -f

