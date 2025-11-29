# ----------------------------
# Base Image
# ----------------------------
FROM php:8.0.2-apache

# Set working directory
WORKDIR /var/www/html

# Enable Apache rewrite module
RUN a2enmod rewrite

# ----------------------------
# Install system dependencies & PHP extensions
# ----------------------------

RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list \
    && sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list \
    && apt-get update -o Acquire::Check-Valid-Until=false \
    && apt-get install -y \
        git \
        curl \
        zip \
        unzip \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libonig-dev \
        libxml2-dev \
        libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring gd zip xml \
    && apt-get clean && rm -rf /var/lib/apt/lists/*



# ----------------------------
# Configure Git safe directory
# ----------------------------
RUN git config --global --add safe.directory /var/www/html

# ----------------------------
# Install Composer
# ----------------------------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ----------------------------
# Copy Laravel application code
# ----------------------------
COPY . .

# ----------------------------
# Install PHP dependencies
# ----------------------------
RUN composer install --no-dev --prefer-dist --optimize-autoloader

# ----------------------------
# Set permissions for Laravel
# ----------------------------
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# ----------------------------
# Set Apache document root to /public
# ----------------------------
RUN sed -i "s|/var/www/html|/var/www/html/public|g" /etc/apache2/sites-available/000-default.conf \
    && sed -i "s|/var/www/html|/var/www/html/public|g" /etc/apache2/apache2.conf

# Expose Apache port
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]

