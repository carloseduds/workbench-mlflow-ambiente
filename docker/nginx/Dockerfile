FROM nginx

# Remove default Nginx config
RUN rm /etc/nginx/nginx.conf

# Copy the modified Nginx conf
COPY nginx.conf /etc/nginx

# Copy proxy config
COPY sites-enabled/ /etc/nginx/sites-enabled/
