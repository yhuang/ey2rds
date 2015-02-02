FROM debian:jessie

MAINTAINER Jimmy Y. Huang <jimmy.huang@duragility.com>

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

RUN set -x \
  && apt-get update && apt-get install -y --no-install-recommends \
    bind9-host \
    ca-certificates \
    groff \
    jq \
    less \
    libsqlite3-0 \
    libssl1.0.0 \
    libyaml-dev \
    openssh-client \
  && rm -rf /var/lib/apt/lists/*

ENV PYTHON_VERSION 2.7.8

RUN set -x \
  && pythonDeps='curl gcc libc6-dev libsqlite3-dev libssl-dev make xz-utils zlib1g-dev' \
  && apt-get update && apt-get install -y --no-install-recommends $pythonDeps \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /usr/src/python \
  && curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" \
  | tar -xJC /usr/src/python --strip-components=1 \
  && cd /usr/src/python \
  && ./configure --enable-shared \
  && make -j$(nproc) \
  && make install \
  && ldconfig \
  && curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
  && find /usr/local \
    \( -type d -a -name test -o -name tests \) \
    -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
    -exec rm -rf '{}' + \
  && rm -rf /usr/src/python \
  && apt-get purge -y --auto-remove $pythonDeps

RUN pip install awscli
RUN easy_install cfn-pyplates

ENV RUBY_MAJOR 2.2
ENV RUBY_VERSION 2.2.0

ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH

RUN set -x \
  && rubyDeps='autoconf bison build-essential curl libbz2-dev libffi-dev libglib2.0-dev libreadline-dev libssl-dev libxml2-dev libxslt-dev ruby' \
  && apt-get update && apt-get install -y --no-install-recommends $rubyDeps \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /usr/src/ruby \
  && curl -SL "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.bz2" \
    | tar -xjC /usr/src/ruby --strip-components=1 \
  && cd /usr/src/ruby \
  && autoconf \
  && ./configure --disable-install-doc \
  && make -j"$(nproc)" \
  && make install \
  && echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc" \
  && gem install bundler \
  && bundle config --global path "$GEM_HOME" \
  && bundle config --global bin "$GEM_HOME/bin" \
  && gem install sparkle_formation \
  && rm -r /usr/src/ruby \
  && apt-get purge -y --auto-remove $rubyDeps

ENV BUNDLE_APP_CONFIG $GEM_HOME

RUN set -x \
  && apt-get update && apt-get install -y --no-install-recommends percona-toolkit \
  && rm -rf /var/lib/apt/lists/*

RUN set -x \
  && useradd docker -u 1000 -s /bin/bash --create-home

USER docker

WORKDIR /app

RUN echo 'complete -C /usr/local/bin/aws_completer aws' >> $HOME/.bashrc

CMD ["/bin/bash"]