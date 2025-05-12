FROM apache/airflow:2.10.1


USER root


RUN apt-get update -y && \
    apt-get install -y python3-launchpadlib wget gnupg2 software-properties-common && \
    apt-get clean

# Install necessary tools and manually download Java 11 (ARM version)
RUN apt-get update && \
    apt-get install -y wget && \
    wget --no-check-certificate -O /tmp/openjdk-arm.tar.gz https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.19%2B7/OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.19_7.tar.gz && \
    mkdir -p /usr/lib/jvm/java-11-openjdk-arm64 && \
    tar -xzf /tmp/openjdk-arm.tar.gz -C /usr/lib/jvm/java-11-openjdk-arm64 --strip-components=1 && \
    rm -f /tmp/openjdk-arm.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable for ARM64
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Verify Java installation
RUN echo "JAVA_HOME is set to $JAVA_HOME" && java -version


USER airflow

RUN pip install pyspark --trusted-host pypi.org --trusted-host files.pythonhosted.org


# ENV SPARK_HOME=/path/to/spark

# COPY PROVISION_SUB_LEDGER /opt/airflow/utils/PROVISION_SUB_LEDGER