# de_GWD_nginx

docker run -d --name=nginx --net=host --restart=always \
-v /etc/localtime:/etc/localtime \
-v /etc/nginx/nginx.conf:/etc/nginx/nginx.conf \
-v /etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf \
-v /var/www/html/:/var/www/html/ \
-v /var/www/ssl/:/var/www/ssl/ \
jacyl4/de_GWD_nginx:latest
