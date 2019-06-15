FROM dirichlet/netbeans AS BUILD_IMAGE

RUN apt-get update; \
	apt-get install -y ant

COPY __src /src
WORKDIR /src
RUN rm -rf build dist; \
	ant \
	-Dnb.internal.action.name=build \
	-DforceRedeploy=false \
	-Dbrowser.context=/src \
	-Dlibs.CopyLibs.classpath=/usr/local/netbeans/java/ant/extra/org-netbeans-modules-java-j2seproject-copylibstask.jar \
	dist

FROM docker4gis/tomcat

COPY --from=BUILD_IMAGE /src/dist /tmp/conf/webapps
