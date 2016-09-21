FROM openshift/base-centos7

MAINTAINER Martin Rumanek <martin@rumanek.cz>
ENV MAVEN_VERSION=3.3.9 \
    TOMCAT_MAJOR=7 \
    TOMCAT_VERSION=7.0.72 \
    CATALINA_HOME=/usr/local/tomcat \
    JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8 
ENV TOMCAT_TGZ_URL=https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
    JDBC_DRIVER_DOWNLOAD_URL=https://jdbc.postgresql.org/download/postgresql-9.4.1208.jar

# Set the labels that are used for Openshift to describe the builder image.
LABEL io.k8s.description="Proarc" \
    io.k8s.display-name="Proarc" \
    io.openshift.expose-services="8080:http" \
    io.openshift.tags="builder,proarc" \
    io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"

RUN curl -sL --no-verbose http://ftp-devel.mzk.cz/jre/jdk-7u75-linux-x64.tar.gz -o /tmp/java.tar.gz
RUN mkdir -p /usr/local/java
ENV JAVA_HOME /usr/local/java/jdk1.7.0_75
RUN tar xzf /tmp/java.tar.gz --directory=/usr/local/java
ENV PATH $JAVA_HOME/bin:$PATH

RUN INSTALL_PKGS="tar" && \
    yum install -y --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y && \
     (curl -v https://www.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    ln -sf /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/local/bin/mvn

WORKDIR $CATALINA_HOME

RUN set -x \
        && curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
        && curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
        && tar -xvf tomcat.tar.gz --strip-components=1 \
        && rm bin/*.bat \
        && rm tomcat.tar.gz*

RUN curl -sL "$JDBC_DRIVER_DOWNLOAD_URL" -o $CATALINA_HOME/lib/postgresql-9.4.1208.jar
ADD proarc.xml $CATALINA_HOME/conf/Catalina/localhost/proarc.xml
ADD .proarc $CATALINA_HOME/.proarc
COPY  ["run", "assemble", "save-artifacts", "usage", "/usr/libexec/s2i/"]

ENV TOMCAT_USER tomcat
ENV TOMCAT_UID 8983
ENV PROARC_HOME=/usr/local/tomcat/.proarc
RUN groupadd -r $TOMCAT_USER && \
    useradd -r -u $TOMCAT_UID -g $TOMCAT_USER $TOMCAT_USER -d $HOME

RUN chown -R $TOMCAT_USER:$TOMCAT_USER $HOME $CATALINA_HOME

RUN chmod -R ugo+rwx $HOME $CATALINA_HOME

USER 8983
EXPOSE 8080

CMD ["/usr/libexec/s2i/usage"]




