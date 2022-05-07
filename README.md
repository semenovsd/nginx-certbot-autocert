# nginx-certbot-autocert
Simple implementation dockerized Nginx with certbot for auto generate ss certs for IP or trusted certificate for domain name.

<h3>For use:</h3>

1. Add the repositories files to your project (certbot and nginx).
2. Add in your docker-compouse.
3. Create .env file or add to your .env variables from example.env. 
4. Run Nginx and Certbot containers, e.g. docker-compouse up --build nginx certbot.
5. Restart Nginx container - docker restart nginx.

Done!

<h3>How it works:</h3>

1. When Nginx container start, run 00-ssl_conf.sh script. 
The script check existing valid certificates, if it does exist create self-singed cert. Because, Nginx can`t start without any certs.

2. When start Certbot container, run init.sh script and check for valid trusted certificate. 
If them does not exist, try test create trusted certificate. If test create success, create trusted certificate.

3. Then need restart Nginx for attach new certificate.
