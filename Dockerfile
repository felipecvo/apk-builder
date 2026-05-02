FROM eclipse-temurin:17-jdk AS binary-source

# Stage 2: Final Debian-based image
FROM debian:trixie-slim
ENV JAVA_HOME=/opt/java/openjdk
COPY --from=binary-source $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

ENV ANDROID_HOME=/opt/android-sdk

RUN mkdir -p ${ANDROID_HOME}

RUN rm -rf /var/lib/apt/lists/* \
  && apt-get clean \
  && apt-get update \
  && apt-get install -y unzip wget \
    build-essential \
    cmake \
    ninja-build \
    nodejs npm \
    python3

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip -O sdk.zip \
        && unzip sdk.zip \
        && rm sdk.zip

RUN mkdir -p $ANDROID_HOME/cmdline-tools/latest
RUN mv ./cmdline-tools/* $ANDROID_HOME/cmdline-tools/latest/

ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

RUN yes | sdkmanager --licenses

RUN sdkmanager \
    "platform-tools" \
    "platforms;android-36" \
    "build-tools;36.1.0"

WORKDIR /app

COPY package* ./

RUN npm i

COPY . ./

RUN npx expo prebuild:android

RUN cd android && ./gradlew dependencies --no-daemon --stacktrace

RUN cd android && ./gradlew assembleRelease --no-daemon --stacktrace

