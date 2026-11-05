# Drupal demo

Image Drupal 11 (PHP 8.3, S2I) et déploiement OpenShift : MariaDB 11.8 plus Drupal, exposé par une route TLS.

L'image ne contient pas les identifiants. Au démarrage, Drupal lit la base depuis l'environnement du conteneur (`docker/settings.database.php`).

| Variable | Rôle | Défaut |
| --- | --- | --- |
| `DB_NAME` | Nom de la base. Absente, l'installeur web reste disponible. | |
| `DB_USER` | Utilisateur | |
| `DB_PASSWORD` | Mot de passe | |
| `DB_HOST` | Hôte | `localhost` |
| `DB_PORT` | Port | `3306` |
| `DB_DRIVER` | `mysql` ou `pgsql` | `mysql` |
| `HASH_SALT` | Sel Drupal. À définir par déploiement. | `drupal-demo-change-me` |
| `PHP_CLEAR_ENV` | `OFF` pour que PHP-FPM voie ces variables | `OFF` dans l'image |

## Construire l'image sur OpenShift

Le pipeline Tekton clone ce dépôt, construit le `Dockerfile` avec Buildah et pousse l'image dans le registre interne du projet :

`image-registry.openshift-image-registry.svc:5000/<projet>/drupal-demo:latest`

Le compte `pipeline` doit pouvoir y pousser.

```bash
oc policy add-role-to-user system:image-builder \
  system:serviceaccount:$(oc project -q):pipeline \
  -n $(oc project -q)

oc apply -f tekton/pipeline.yaml
```

Adapte `GIT_URL` dans `tekton/pipelinerun.yaml`, puis lance un run :

```bash
oc create -f tekton/pipelinerun.yaml
```

## Déployer la stack

Le chart `charts/drupal` dépend de `charts/mariadb`. Une installation crée le secret, MariaDB, Drupal et la route.

```bash
helm install stack charts/drupal
```

Le service MariaDB et le secret portent le nom `<release>-mariadb`. Drupal s'y connecte tout seul. Les mots de passe sont générés au premier install et conservés aux mises à jour.

Récupérer l'URL :

```bash
oc get route stack-drupal -o jsonpath='{.spec.host}{"\n"}'
```

La première visite ouvre l'installeur Drupal. Le chart pose un `HASH_SALT` et le répertoire de configuration : l'écran du mot de passe de base est alors sauté. Derrière la route TLS, Drupal est informé du protocole HTTPS pour que les requêtes AJAX de l'installeur ne soient pas redirigées.

Données MariaDB éphémères par défaut, comme le déploiement manuel. Pour un volume :

```bash
helm install stack charts/drupal --set mariadb.persistence.enabled=true
```

Image Drupal par défaut : `image-registry.openshift-image-registry.svc:5000/rh-ee-slallema-dev/drupal-demo:latest`. Ajuste `image.repository` dans `charts/drupal/values.yaml` pour un autre projet.

### Base déjà en place

```bash
helm install drupal charts/drupal \
  --set mariadb.enabled=false \
  --set db.host=mariadb-118 \
  --set db.existingSecret=drupal-demo-db
```

Le secret existant doit contenir les clés `database-name`, `database-user` et `database-password`. MariaDB utilise en plus `database-root-password`.

### MariaDB seule

```bash
helm install mariadb charts/mariadb
```

## GitHub Actions

`.github/workflows/docker-publish.yml` construit la même image et la pousse vers `ghcr.io` lors d'un push sur `main` ou `master`. Le `Dockerfile` tire `registry.access.redhat.com`, donc ce workflow n'a pas besoin d'identifiants Red Hat. Le chemin utilisé sur le cluster reste le pipeline Tekton.
