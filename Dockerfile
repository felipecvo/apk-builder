FROM eclipse-temurin:17 AS android_builder

ENV ANDROID_HOME=/opt/android-sdk

RUN mkdir -p ${ANDROID_HOME}

RUN apt-get update && apt-get install -y unzip wget \
  build-essential \
  cmake \
  ninja-build \
  node \
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

