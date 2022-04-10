# =====================
# Create a new Github repo of the current directory
# Default is private repo.

function github_init() {
  # This function works subject to having the Github CLI 'gh' installed
  # and having already authenticated using 'gh auth login'
  my_parent_dir=${PWD##*/}
  echo "Creating: ${my_parent_dir}\n"
  gh repo create $my_parent_dir --private
  echo "# ${my_parent_dir}" >> README.md
  git init
  git add -A
  git commit -m "My First Commit"
  git branch -M main
  git remote add origin https://github.com/paul-goodall/${my_parent_dir}.git
  git push -u origin main
}


# =====================

function django_create_new_app() {
  if [ -n "$1" ]; then
    app_name=$1
    echo "Creating Django app: ${app_name}\n"
  else
    echo "Django app name must be specified."
    return 1
  fi
  if [ -n "$2" ]; then
    django_name=$2
  else
    echo "Django name name must be specified."
    return 1
  fi

# Determine which BASE_APP is present already within the project:
base_app=""
[ -d "./default_app" ]          && base_app="default_app"
[ -d "./master_app" ] && base_app="master_app"
if [ "$base_app" = "" ]; then
  echo "No BASE_APP is present. Exiting."
  return 1
fi


# Create the app and the standard directories that you will need:
  python3 manage.py startapp $app_name
  mkdir -p $app_name/templates/$app_name
  mkdir -p $app_name/templates/navbar
  mkdir -p $app_name/static/$app_name
  mkdir -p media/$app_name/images

# Register your new in the Project Settings:
my_app_inc=$(cat << EOF
# Django Create_App appending:
INSTALLED_APPS.append('${app_name}')

EOF
)
  echo $my_app_inc >> ${django_name}/settings.py

# Setup your App URLs as a standalone app:
my_app_urls=$(cat << EOF
from django.urls import path, re_path
from . import views as ${app_name}_views
app_name = "${app_name}"
urlpatterns = [
    path('${app_name}/', ${app_name}_views.${app_name}_home, name='home'),
]
EOF
)
  echo $my_app_urls > ${app_name}/urls.py

# Register your App URLs in the Project URLs:
my_urls_inc=$(cat << EOF
from django.conf.urls import include
urlpatterns.append(path('', include(('${app_name}.urls', '${app_name}'), namespace='${app_name}')))

EOF
)
  echo $my_urls_inc >> ${django_name}/urls.py

# Create your App base template:
my_base_html=$(cat << EOF
{% extends '${base_app}/base.html' %}

{% block content %}{% endblock %}

EOF
)
  echo $my_base_html > ${app_name}/templates/${app_name}/base.html

# Create your App homepage placeholder:
my_app_home=$(cat << EOF
{% extends '${app_name}/base.html' %}
\n
{% block content %}
Welcome to ${app_name} home.
{% endblock %}
EOF
)
  echo $my_app_home > ${app_name}/templates/${app_name}/home.html

# Add the View function to deal with the home response:
my_app_home_def=$(cat << EOF
def home(request):
\treturn render(request, '${app_name}/home.html')
EOF
)
  echo $my_app_home_def >> ${app_name}/views.py

# Create the Navbar section so that your app is included in the NavBar:
my_navbar=$(cat << EOF
{% if user.is_authenticated %}
    <li class="nav-item">
      <a class="nav-link" href="{% url '${app_name}:home' %}">${app_name}</a>
    </li>
{% endif %}
EOF
)
  echo $my_navbar > $app_name/templates/$app_name/navbar.html

# Register the app with the NavBar script in the BASE_APP:
  echo "${app_name}" >> ${base_app}/create_navbar/list_apps.txt

  bash master_app/create_navbar/create_navbar_base.sh
  python3 manage.py makemigrations
  python3 manage.py migrate

}
# =====================
function django_add_existing_app() {
  if [ -n "$1" ]; then
    app_name=$1
    echo "Creating Django app: ${app_name}\n"
  else
    echo "Django app name must be specified."
    return 1
  fi
  if [ -n "$2" ]; then
    django_name=$2
  else
    echo "Django name name must be specified."
    return 1
  fi

# Create the app and the standard directories that you will need:
  python3 manage.py startapp $app_name

# Determine which BASE_APP is present already within the project:
  base_app=""
  [ -d "./default_app" ]          && base_app="default_app"
  [ -d "./master_app" ] && base_app="master_app"
  if [ "$base_app" = "" ]; then
    echo "No BASE_APP is present. Exiting."
    return 1
  fi

# Remove the created app and create a clone the existin app:
  rm -rf $app_name
  git clone https://github.com/paul-goodall/${app_name}.git
  rm ${app_name}/README.md
  rm -rf ${app_name}/.git
  mkdir -p $app_name/templates/$app_name
  mkdir -p $app_name/static/$app_name
  mkdir -p media/$app_name/images

  if [ "$app_name" = "default_app" ] || [ "$app_name" = "master_app" ]; then
      rm $app_name/create_navbar/list_apps.txt
      touch $app_name/create_navbar/list_apps.txt
  fi
  echo "${app_name}" >> ${base_app}/create_navbar/list_apps.txt
  touch $app_name/templates/$app_name/navbar.html

  if [ "$app_name" = "default_app" ] || [ "$app_name" = "master_app" ]; then
      bash ${base_app}/create_navbar/create_navbar_base.sh
  fi


  # Register your new in the Project Settings:
my_app_inc=$(cat << EOF
# Django Create_App appending:
INSTALLED_APPS.append('${app_name}')

EOF
)
   echo $my_app_inc >> ${django_name}/settings.py


auth_app_extras=$(cat << EOF
INSTALLED_APPS.append('fontawesomefree')
AUTH_USER_MODEL = '${app_name}.MyUser'

EOF
)

  if [ "$app_name" = "default_app" ] || [ "$app_name" = "master_app" ]; then
    echo $auth_app_extras >> ${django_name}/settings.py
  fi

my_url_settings=$(cat << EOF
# Django Create_App appending:
from django.conf.urls import include
urlpatterns.append(path('', include(('${app_name}.urls', '${app_name}'), namespace='${app_name}')))

EOF
)
   echo $my_url_settings >> ${django_name}/urls.py
   bash master_app/create_navbar/create_navbar_base.sh
   python3 manage.py makemigrations
   python3 manage.py migrate


}
# =====================
# Creating a new Django project with a repo:
function django_init() {
  if [ -n "$1" ]; then
    django_name=${1}
    project_name="${1}-project"
    echo "Creating Project: ${project_name} for Django name :${django_name}\n"
  else
    echo "Usage:\n"
    echo "django_init REQUIRED_PROJECT_NAME <clean>\n"
    return 1
  fi

  do_app=1
  if [ -n "$2" ]; then
    if [ "$2" = "clean" ]; then
      do_app=0
    fi
  fi

  django-admin startproject $django_name
  echo "django-admin startproject ${django_name}\n"

  # Django creates a child folder inside the parent folder of the same name.
  # Renaming the parent to avoid confusion.
  mv $django_name $project_name
  echo "mv ${django_name} ${project_name}"
  cd $project_name

app_path_settings=$(cat << EOF
# Django [django_init] appending:
LOGIN_URL = '/login'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'
EOF
)
   echo $app_path_settings >> ${django_name}/settings.py

gitignore_settings=$(cat << EOF
secret_key.txt
email_address.txt
email_app_password.txt
EOF
)
  echo $gitignore_settings > .gitignore

  cp ~/.email_address.txt ./email_address.txt
  cp ~/.email_app_password.txt ./email_app_password.txt

my_email_settings=$(cat << EOF
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_USE_TLS = True
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587

with open(BASE_DIR / 'email_address.txt', 'r') as file:
	EMAIL_HOST_USER = file.read().rstrip()

with open(BASE_DIR / 'email_app_password.txt', 'r') as file:
	EMAIL_HOST_PASSWORD = file.read().rstrip()
EOF
)
  echo $my_email_settings >> ${django_name}/settings.py

  grep "SECRET_KEY = " ${django_name}/settings.py > secret_key.txt
  sed -i "" "s/SECRET_KEY = //" secret_key.txt
  sed -i "" "s/'//g" secret_key.txt

  new_secret_line="with open(BASE_DIR \/ 'secret_key.txt', 'r') as file:\n\tSECRET_KEY = file.read().rstrip()"
  sed -i "" "s/SECRET_KEY.*/${new_secret_line}/" ${django_name}/settings.py

  echo "\nINSTALLED_APPS.append('crispy_forms')\n" >> ${django_name}/settings.py


  if [ "$do_app" -eq "1" ]; then
      echo "Downloading: master_app"
     django_add_existing_app master_app ${django_name}
  fi

  open -a Atom .
}
# =====================
