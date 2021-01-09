#!/bin/bash
echo "Thanks for trying Remotely!"
echo

Args=( "$@" )
ArgLength=${#Args[@]}

for (( i=0; i<${ArgLength}; i+=2 ));
do
    if [ "${Args[$i]}" = "--hostname" ]; then
        HostName="${Args[$i+1]}"
    elif [ "${Args[$i]}" = "--approot" ]; then
        AppRoot="${Args[$i+1]}"
    fi
done

if [ -z "$AppRoot" ]; then
    read -p "Enter path where the Remotely server files should be installed (typically /var/www/remotely): " AppRoot
    if [ -z "$AppRoot" ]; then
        AppRoot="/var/www/rmmsos"
    fi
fi

if [ -z "$HostName" ]; then
    read -p "Enter server host (e.g. rmmsos.com): " HostName
fi

UbuntuVersion=$(lsb_release -r -s)


# Install .NET Core Runtime.
wget -q https://packages.microsoft.com/config/ubuntu/$UbuntuVersion/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
add-apt-repository universe
apt-get update
apt-get -y install apt-transport-https
apt-get -y install aspnetcore-runtime-5.0
rm packages-microsoft-prod.deb


 # Install other prerequisites.
apt-get -y install unzip
apt-get -y install acl
apt-get -y install libc6-dev
apt-get -y install libgdiplus


# Download and install Remotely files.
mkdir -p $AppRoot
wget "https://github.com/lucent-sea/Remotely/releases/latest/download/Remotely_Server_Linux-x64.zip"
unzip -o Remotely_Server_Linux-x64.zip -d $AppRoot
rm Remotely_Server_Linux-x64.zip
setfacl -R -m u:www-data:rwx $AppRoot
chown -R "$USER":www-data $AppRoot


# Install Nginx
apt-get update
apt-get -y install nginx

systemctl start nginx


# Configure Nginx
nginxConfig="

server {
    listen        80;
    server_name   $HostName *.$HostName;
    location / {
        proxy_pass         http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }

    location /BrowserHub {	
        proxy_pass http://localhost:5000;	
        proxy_http_version 1.1;	
        proxy_set_header Upgrade \$http_upgrade;	
        proxy_set_header Connection \"upgrade\";	
        proxy_set_header Host \$host;	
        proxy_cache_bypass \$http_upgrade;	
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;	
        proxy_set_header   X-Forwarded-Proto \$scheme;	
    }	
    location /AgentHub {	
        proxy_pass http://localhost:5000;	
        proxy_http_version 1.1;	
        proxy_set_header Upgrade \$http_upgrade;	
        proxy_set_header Connection \"upgrade\";	
        proxy_set_header Host \$host;	
        proxy_cache_bypass \$http_upgrade;	
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;	
        proxy_set_header   X-Forwarded-Proto \$scheme;	
    }	
    location /ViewerHub {	
        proxy_pass http://localhost:5000;	
        proxy_http_version 1.1;	
        proxy_set_header Upgrade \$http_upgrade;	
        proxy_set_header Connection \"upgrade\";	
        proxy_set_header Host \$host;	
        proxy_cache_bypass \$http_upgrade;	
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;	
        proxy_set_header   X-Forwarded-Proto \$scheme;	
    }	
    location /CasterHub {	
        proxy_pass http://localhost:5000;	
        proxy_http_version 1.1;	
        proxy_set_header Upgrade \$http_upgrade;	
        proxy_set_header Connection \"upgrade\";	
        proxy_set_header Host \$host;	
        proxy_cache_bypass \$http_upgrade;	
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;	
        proxy_set_header   X-Forwarded-Proto \$scheme;	
    }
}"

echo "$nginxConfig" > /etc/nginx/sites-available/remotely

ln -s /etc/nginx/sites-available/remotely /etc/nginx/sites-enabled/remotely

# Test config.
nginx -t

# Reload.
nginx -s reload




# Create service.

serviceConfig="[Unit]
Description=Rmmsos Server

[Service]
WorkingDirectory=$AppRoot
ExecStart=/usr/bin/dotnet $AppRoot/Remotely_Server.dll
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
SyslogIdentifier=rmmsos
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target"

echo "$serviceConfig" > /etc/systemd/system/rmmsos.service


# Enable service.
systemctl enable rmmsos.service
# Start service.
systemctl restart rmmsos.service


# Install Certbot and get SSL cert.
apt-get -y install certbot python3-certbot-nginx

certbot --nginx