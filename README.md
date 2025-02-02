# Django Site

[Докеризированный сайт на Django](https://edu-mad-jang.sirius-k8s.dvmn.org) для экспериментов с Kubernetes.

Внутри контейнера Django приложение запускается с помощью Nginx Unit, не путать с Nginx. Сервер Nginx Unit выполняет сразу две функции: как веб-сервер он раздаёт файлы статики и медиа, а в роли сервера-приложений он запускает Python и Django. Таким образом Nginx Unit заменяет собой связку из двух сервисов Nginx и Gunicorn/uWSGI. [Подробнее про Nginx Unit](https://unit.nginx.org/).

## Как подготовить окружение к локальной разработке

Код в репозитории полностью докеризирован, поэтому для запуска приложения вам понадобится Docker. Инструкции по его установке ищите на официальных сайтах:

- [Get Started with Docker](https://www.docker.com/get-started/)

Вместе со свежей версией Docker к вам на компьютер автоматически будет установлен Docker Compose. Дальнейшие инструкции будут его активно использовать.

## Как запустить сайт для локальной разработки

Запустите базу данных и сайт:

```shell
$ docker compose up
```

В новом терминале, не выключая сайт, запустите несколько команд:

```shell
$ docker compose run --rm web ./manage.py migrate  # создаём/обновляем таблицы в БД
$ docker compose run --rm web ./manage.py createsuperuser  # создаём в БД учётку суперпользователя
```

Готово. Сайт будет доступен по адресу [http://127.0.0.1:8080](http://127.0.0.1:8080). Вход в админку находится по адресу [http://127.0.0.1:8000/admin/](http://127.0.0.1:8000/admin/).

## Как вести разработку

Все файлы с кодом django смонтированы внутрь докер-контейнера, чтобы Nginx Unit сразу видел изменения в коде и не требовал постоянно пересборки докер-образа -- достаточно перезапустить сервисы Docker Compose.

### Как обновить приложение из основного репозитория

Чтобы обновить приложение до последней версии подтяните код из центрального окружения и пересоберите докер-образы:

``` shell
$ git pull
$ docker compose build
```

После обновлении кода из репозитория стоит также обновить и схему БД. Вместе с коммитом могли прилететь новые миграции схемы БД, и без них код не запустится.

Чтобы не гадать заведётся код или нет — запускайте при каждом обновлении команду `migrate`. Если найдутся свежие миграции, то команда их применит:

```shell
$ docker compose run --rm web ./manage.py migrate
…
Running migrations:
  No migrations to apply.
```

### Как добавить библиотеку в зависимости

В качестве менеджера пакетов для образа с Django используется pip с файлом requirements.txt. Для установки новой библиотеки достаточно прописать её в файл requirements.txt и запустить сборку докер-образа:

```sh
$ docker compose build web
```

Аналогичным образом можно удалять библиотеки из зависимостей.

<a name="env-variables"></a>
## Переменные окружения

Образ с Django считывает настройки из переменных окружения:

`SECRET_KEY` -- обязательная секретная настройка Django. Это соль для генерации хэшей. Значение может быть любым, важно лишь, чтобы оно никому не было известно. [Документация Django](https://docs.djangoproject.com/en/3.2/ref/settings/#secret-key).

`DEBUG` -- настройка Django для включения отладочного режима. Принимает значения `TRUE` или `FALSE`. [Документация Django](https://docs.djangoproject.com/en/3.2/ref/settings/#std:setting-DEBUG).

`ALLOWED_HOSTS` -- настройка Django со списком разрешённых адресов. Если запрос прилетит на другой адрес, то сайт ответит ошибкой 400. Можно перечислить несколько адресов через запятую, например `127.0.0.1,192.168.0.1,site.test`. [Документация Django](https://docs.djangoproject.com/en/3.2/ref/settings/#allowed-hosts).

`DATABASE_URL` -- адрес для подключения к базе данных PostgreSQL. Другие СУБД сайт не поддерживает. [Формат записи](https://github.com/jacobian/dj-database-url#url-schema).

## Kubernates
Развертывание приложения с помощью kubernates

### Запустите Minikube
```bash
minikube start --driver=virtualbox --no-vtx-check
```

Установите [Helm](https://helm.sh/).

Разворачиваем [postgreSQL](https://habr.com/ru/companies/domclick/articles/649167/) в кластере:
```bash
source kubernetes/bitnami_psql.sh
```
или
```bash
source kubernetes/bitnami_psql.sh <USER> <PASSWORD> <DB_NAME>
```

### Создайте Secret
Сконвертить и заполнить поля в app-secret.yml значением формата base64:
- `SECRET_KEY`
- `DATABASE_URL`

```bash
echo SECRET_KEY | base64
```
Далее выполнить команду:
```bash
kubectl apply -f kubernetes/app-secret.yml
```

### Создайте Deployment
```bash
kubectl apply -f kubernetes/app-deployment.yml
```

### Создайте Service 
```bash
kubectl apply -f kubernetes/app-service.yml
```

### Создайте Ingress
```bash
kubectl apply -f kubernetes/app-ingress.yml
```

Включение Ingress в Minikube:
```bash
minikube addons enable ingress
```

### Создайте регулярное удаление сессии
```bash
kubectl apply -f kubernetes/app-clearsessions.yml
```

### Создайте миграцию
```bash
kubectl apply -f kubernetes/app-migrate.yml
```

## Yandex Cloud
- [Рабочая версия сайта](https://edu-mad-jang.sirius-k8s.dvmn.org)
- [Серверная инфраструктура](https://sirius-env-registry.website.yandexcloud.net/edu-mad-jang.html)

Настройте namespace:
```bash
kubectl config set-context --current --namespace=edu-mad-jang
```
### Создайте Secret
Сконвертить и заполнить поля в app-secret.yml значением формата base64:
- `SECRET_KEY`
- `DATABASE_URL`

```bash
echo SECRET_KEY | base64
```
Далее выполнить команду:
```bash
kubectl apply -f dev/app-secret.yml
```
### Создайте ConfigMap
```bash
kubectl apply -f dev/app-configmap.yml
```
### Создайте Deployment
```bash
kubectl apply -f dev/app-deployment.yml
```
### Создайте Service 
```bash
kubectl apply -f dev/app-service.yml
```
### Создайте регулярное удаление сессии
```bash
kubectl apply -f dev/app-clearsessions.yml
```
### Создайте миграцию
```bash
kubectl apply -f dev/app-migrate.yml
```
### Создайте учетную запись
```bash
kubectl get pods
```
Скопируйте любой активный Pod, название которого начинается на "django-app-deployment"
```bash
kubectl exec -it <POD> -- bash
```
```bash
python manage.py createsuperuser
```

## Docker Registry

### Сборка
```bash
docker build .\backend_main_django -t django_app
```
### Публикация
```bash
export TAG=<your tag>
```
```bash
docker tag django_app:latest shadowsking/django_app:$TAG
docker push shadowsking/django_app:$TAG

docker tag django_app:latest shadowsking/django_app:latest
docker push shadowsking/django_app:latest
```
