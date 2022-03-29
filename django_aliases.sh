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
  python3 manage.py startapp $app_name
  mkdir -p $app_name/templates/$app_name
  mkdir -p $app_name/static/$app_name
  mkdir -p media/$app_name/images

  # For each app created you need to do three things:
  # 1. Add the app to the parent project's SETTINGS file
  # 2. Add the url for the app homepage into the parent project's URL file
  # 3. Tell the app's Views what to return for that particular view
  echo "\n\n# Django Create_App appending: \n\n" >> ${django_name}/settings.py
  echo "INSTALLED_APPS.append('${app_name}')\n"  >> ${django_name}/settings.py
  
  echo "\n# Django Create_App appending: \n"   >> ${django_name}/urls.py
  echo "import ${app_name}.urls\n" >> ${django_name}/urls.py
  echo "urlpatterns = urlpatterns + ${app_name}.urls.my_urls\n" >> ${django_name}/urls.py

my_app_urls=$(cat << EOF
from django.urls import path
from . import views\n
my_urls = [
    path('${app_name}/', views.${app_name}_home, name='${app_name}_home'),
]
EOF
)
  echo $my_app_urls > ${app_name}/urls.py
  
  echo "{% extends 'default_app/base.html' %}\n\n{% block content %}{% endblock %}" > ${app_name}/templates/${app_name}/base.html

my_app_home=$(cat << EOF
{% extends '${app_name}/base.html' %}
\n
{% block content %}
Welcome to ${app_name} home.
{% endblock %}
EOF
)
  echo $my_app_home > ${app_name}/templates/${app_name}/home.html

  echo "def ${app_name}_home(request):\n\treturn render(request, '${app_name}/home.html')" >> ${app_name}/views.py

  echo "${app_name}" >> default_app/create_navbar/list_apps.txt

my_navbar=$(cat << EOF
{% if user.is_authenticated %}
    <li class="nav-item">
      <a class="nav-link" href="{% url '${app_name}_home' %}">${app_name}</a>
    </li>
{% endif %}
EOF
)
  echo $my_navbar > $app_name/templates/$app_name/navbar.html
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
  python3 manage.py startapp $app_name
  mkdir -p media/$app_name/images

  rm -rf $app_name
  git clone https://github.com/paul-goodall/${app_name}.git
  rm ${app_name}/README.md
  rm -rf ${app_name}/.git
  
  if [ "$app_name" = "default_app" ]; then
      rm default_app/create_navbar/list_apps.txt
      touch default_app/create_navbar/list_apps.txt
  fi
  echo "${app_name}\n" >> default_app/create_navbar/list_apps.txt
  touch $app_name/templates/$app_name/navbar.html

  if [ "$app_name" = "default_app" ]; then
      bash default_app/create_navbar/create_navbar_base.sh
  fi


  # For each app created you need to do two things:
  # 1. Add the app to the parent project's SETTINGS file
  # 2. Add the url for the app homepage into the parent project's URL file
  echo "\n\n# Django Create_App appending: \n" >> ${django_name}/settings.py
  echo "INSTALLED_APPS.append('${app_name}')\n"  >> ${django_name}/settings.py
  if [ $app_name = "default_app" ]; then
    echo "INSTALLED_APPS.append('fontawesomefree')\n"  >> ${django_name}/settings.py
  fi
  echo "\n# Django Create_App appending:\nimport ${app_name}.urls\n" >> ${django_name}/urls.py
  echo "urlpatterns = urlpatterns + ${app_name}.urls.my_urls\n"      >> ${django_name}/urls.py

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

echo "\n\n# Django [django_init] appending:
LOGIN_URL = '/login'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'
" >> ${django_name}/settings.py

  touch .gitignore
  echo "secret_key.txt\nemail_address.txt"  >> .gitignore
  echo "secret_key.txt\nemail_app_password.txt" >> .gitignore
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

  if [ do_app = 1 ]; then
     django_add_existing_app default_app ${django_name}
  fi

  open -a Atom .
}
# =====================