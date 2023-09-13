# To Build Docker

# 1. Build Web
# flutter build web

# 2a. Build Normal
# docker build -t smart-file-sync .

# 2b. Build Multi Arc
# docker buildx create --name mybuilder
# docker buildx use mybuilder
# docker buildx ls
# docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t smart-file-sync --push .

# 3. To Run Docker
# docker run -t smart-file-sync -d --restart unless-stopped -p 8003:80 smart-file-sync

FROM httpd
COPY ./build/web/ /usr/local/apache2/htdocs/