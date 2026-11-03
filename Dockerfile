FROM registry.redhat.io/rhel9/php-82:latest

USER root
# 1. Dépendances système
RUN dnf install -y git unzip tar php-gd php-pdo php-mysqlnd php-pgsql php-xml php-mbstring php-opcache php-intl && dnf clean all

ARG GIT_REPO="https://github.com/drupal/recommended-project.git"

# 2. Clonage du socle Drupal (Vous pouvez remplacer par votre propre dépôt d'entreprise)
RUN mkdir -p /tmp/src \
    && git clone ${GIT_REPO} /tmp/src \
    && mkdir -p /tmp/src/.s2i \
    && echo "DOCUMENTROOT=web" > /tmp/src/.s2i/environment \
    && chown -R 1001:0 /tmp/src



# 3. Assemblage S2I (Installation via Composer)
USER 1001
RUN /usr/libexec/s2i/assemble

# 4. Préparation pour l'installation web par l'utilisateur final
RUN cp /opt/app-root/src/web/sites/default/default.settings.php /opt/app-root/src/web/sites/default/settings.php \
    && chmod 666 /opt/app-root/src/web/sites/default/settings.php \
    && chmod 777 /opt/app-root/src/web/sites/default

CMD ["/usr/libexec/s2i/run"]