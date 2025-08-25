ARG AIRFLOW_IMAGE_NAME=apache/airflow:3.0.2

FROM ${AIRFLOW_IMAGE_NAME}

# Add build args for pip configuration
ARG PIP_INDEX_URL=https://p-nexus-3.development.nl.eu.abnamro.com:8443/repository/python-group/simple
ARG PIP_TRUSTED_HOST=p-nexus-3.development.nl.eu.abnamro.com
ARG PIP_TIMEOUT=30

USER root

# Configure apt for better reliability without modifying sources
RUN mkdir -p /etc/apt/apt.conf.d && \
echo 'Acquire::https::Verify-Peer "false";' > /etc/apt/apt.conf.d/99verify-peer.conf && \
    echo 'Acquire::https::Verify-Host "false";' >> /etc/apt/apt.conf.d/99verify-peer.conf && \
    echo 'Acquire::ForceIPv4 "true";' >> /etc/apt/apt.conf.d/99force-ipv4 && \
    echo 'APT::Get::Assume-Yes "true";' >> /etc/apt/apt.conf.d/99assumeyes && \
    echo 'APT::Get::Fix-Missing "true";' >> /etc/apt/apt.conf.d/99fixmissing

# Install necessary tools and dependencies with explicit timeout and retries
RUN apt-get clean || true && \
    rm -rf /var/lib/apt/lists/* || true && \
apt-get update --option Acquire::Retries=5 || true && \
    apt-get install -y --no-install-recommends ca-certificates || true && \
    update-ca-certificates || true && \
    apt-get install -y --no-install-recommends python3-launchpadlib wget gnupg2 software-properties-common || true && \
    apt-get clean || true

# Install Java with error handling


RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends openjdk-17-jre-headless ca-certificates tini gosu;


# RUN apt-get update --option Acquire::Retries=5 || true && \
#     apt-get install -y --no-install-recommends default-jdk || true && \
#     apt-get clean || true && \
#     rm -rf /var/lib/apt/lists/* || true

# Configure pip to use internal Nexus repository
RUN set -eux; \
    mkdir -p /etc/pip.conf.d || true; \
    printf "[global]\n" > /etc/pip.conf; \
    printf "timeout = %s\n" "$PIP_TIMEOUT" >> /etc/pip.conf; \
    printf "trusted-host = %s\n" "$PIP_TRUSTED_HOST" >> /etc/pip.conf; \
    printf "index = %s\n" "${PIP_INDEX_URL%/simple}" >> /etc/pip.conf; \
    printf "index-url = %s\n" "$PIP_INDEX_URL" >> /etc/pip.conf; \
    cat /etc/pip.conf

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    PATH=$JAVA_HOME/bin:$PATH \
    PYSPARK_PYTHON=/usr/local/bin/python \
    PYSPARK_DRIVER_PYTHON=/usr/local/bin/python


# # Set JAVA_HOME environment variable (with fallback paths)
# RUN JAVA_PATH=$(find /usr/lib/jvm -name "java-*-openjdk-*" -type d 2>/dev/null | head -n 1) && \
#     if [ -n "$JAVA_PATH" ]; then \
#         echo "export JAVA_HOME=$JAVA_PATH" >> /etc/profile.d/java.sh && \
# echo "export PATH=$JAVA_PATH/bin:$PATH" >> /etc/profile.d/java.sh; \
#     else \
#         echo "No Java found, JAVA_HOME not set"; \
#     fi

# # Source profile script
# RUN echo "source /etc/profile.d/java.sh" >> /etc/bash.bashrc

USER airflow

# Install required Python packages for Airflow 3.0 with better reliability
RUN pip install --upgrade pip --timeout 120 --retries 5 --trusted-host pypi.org --trusted-host files.pythonhosted.org && \
pip install pyspark --timeout 120 --retries 5 --trusted-host pypi.org --trusted-host files.pythonhosted.org
