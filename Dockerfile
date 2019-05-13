FROM python:3.6

# Install Required environment 
RUN apt-get update && apt-get -y install \
	apt-utils \
	git \
	python3-pip
# 	elasticsearch probably taken care of with requirements.txt
RUN pip install --upgrade pip


#file organization
RUN mkdir /www
WORKDIR /www

COPY ./files/readthedocs.org-master.zip ./readthedocs.org-master.zip
RUN unzip readthedocs.org-master.zip
RUN mv ./readthedocs.org-master ./readthedocs.org

WORKDIR /www/readthedocs.org

# Install the required Python packages
RUN pip install -r requirements.txt

## Install a higher version of requests to fix an SSL issue
#RUN pip install requests==2.6.0

# Override the default settings
COPY ./files/local_settings.py ./readthedocs/settings/local_settings.py

# Deploy the database
RUN python ./manage.py migrate

# Create a super user
RUN echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@localhost', 'admin')" | python ./manage.py shell

# Load test data
RUN python ./manage.py loaddata test_data

# Copy static files
RUN python ./manage.py collectstatic --noinput

# Install supervisord
RUN pip install supervisor
ADD files/supervisord.conf /etc/supervisord.conf

VOLUME /www/readthedocs.org

ENV RTD_PRODUCTION_DOMAIN 'localhost:8000'

# Clean Up Apt

RUN apt-get autoremove -y

CMD ["supervisord"]