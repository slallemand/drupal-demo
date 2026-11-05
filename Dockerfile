FROM registry.access.redhat.com/ubi9/php-83:latest

USER root
# 1. Dépendances système
RUN dnf install -y git unzip tar php-gd php-pdo php-mysqlnd php-pgsql php-xml php-mbstring php-opcache php-intl && dnf clean all

ARG GIT_REPO="https://github.com/drupal/recommended-project.git"
ARG GIT_REF="11.x"

# 2. Clonage du socle Drupal (Vous pouvez remplacer par votre propre dépôt d'entreprise)
# 11.x exige PHP 8.3. La branche par défaut peut passer à Drupal 12 (PHP 8.5).
RUN mkdir -p /tmp/src \
    && git clone --branch ${GIT_REF} --depth 1 ${GIT_REPO} /tmp/src \
    && mkdir -p /tmp/src/.s2i \
    && echo "DOCUMENTROOT=web" > /tmp/src/.s2i/environment \
    && chown -R 1001:0 /tmp/src



# 3. Assemblage S2I (Installation via Composer)
USER 1001
ENV COMPOSER_MEMORY_LIMIT="-1" \
    COMPOSER_ARGS="--no-blocking"
RUN /usr/libexec/s2i/assemble

# 4. Préparation pour l'installation web par l'utilisateur final.
# PHP-FPM masque les variables du conteneur si PHP_CLEAR_ENV reste à ON.
ENV PHP_CLEAR_ENV=OFF
COPY --chown=1001:0 docker/settings.database.php /opt/app-root/src/web/sites/default/settings.database.php
RUN settings=/opt/app-root/src/web/sites/default/settings.php \
    && cp /opt/app-root/src/web/sites/default/default.settings.php "$settings" \
    && printf "%s\n" "include __DIR__ . '/settings.database.php';" >> "$settings" \
    && mkdir -p /opt/app-root/src/config/sync \
    && chmod 644 /opt/app-root/src/web/sites/default/settings.database.php \
    && chmod 666 "$settings" \
    && chmod 777 /opt/app-root/src/web/sites/default \
    && chmod 775 /opt/app-root/src/config/sync

CMD ["/usr/libexec/s2i/run"]