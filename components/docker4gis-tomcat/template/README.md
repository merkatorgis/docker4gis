# Project Setup

Create a new folder here in the root of this repo, containing a Maven project
with a `pom.xml` that builds a `.war` file.

## Netbeans

### Prerequisites

1. Install [Java JDK
   1.8](https://www.oracle.com/nl/java/technologies/downloads/#java8-windows).
1. Download the [zip
   file](https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.79/bin/apache-tomcat-9.0.79.zip)
   for [Apache Tomcat 9](https://tomcat.apache.org/download-90.cgi). Just unzip
   it somewhere.
1. Install [Netbeans 18](https://netbeans.apache.org/download/nb18/) (using the
   Windows Installer). Verify that your `jdk-1.8` is selected as the JDK for
   Netbeans; otherwise just Next, Next, Install, Finish.

### Sources

Note that Netbeans can't deal with sources in WSL (not on a UNC path, and also
not on a mapped drive, although at first it seems to work, you will get in
trouble when Maven starts assembling the `.war` file).

So what you can do is to clone the repo of your Java component not
only in WSL, but on a local disk in Windows as well. Then from Netbeans, you
would make your changes in the Windows clone, commit and push to your
development branch, and then in WSL, you would pull these changes, and `dg
build` etc. Just remember to work in the same branch in both clones.

You can even rename the clone's folder in Windows to give it a `-windows`
prefix, and then Add Folder To Workspace... in VSCode in WSL, so that you can
manage the Git stuff from one single place there. Use a `/mnt/c/...` path to
find your Windows folder.

### Initial setup

1. Start Netbeans.
1. File | New Project | Java with Maven | Web Application
   1. Project Name: why not this project's DOCKER_USER?
   1. Project Location: the root of the Windows clone of your Java component's
      repo - a new folder will be created there, named as the Project Name
   1. Group Id: e.g. com.merkator
   1. Next
   1. Server: Add... Apache Tomcat or TomEE
      1. Server Location: where you unzipped Tomcat
      1. Username: manager, Password: manager, Create user if it does not exist
   1. Java EE Version: Java EE 7 Web
   1. Finish
1. Right-click project name (might need to open manually first) | Properties
   1. Sources
      1. Source/binary format: 1.8
   1. Build | Compile
      1. JDK 1.8
   1. Run
      1. Server: Apache Tomcat or TomEE
      1. Java EE Version: Java EE 7 Web
      1. Context Path: make empty(!)
   1. OK
1. Right-click project name | Properties (yes; again)
   1. Build | Compile
      1. Compile on Save
      1. OK
   1. OK
1. Right-click Dependencies | Add Dependency...
   1. Group ID: `tomcat`, Artifact ID: `servlet-api`, Version: Arrow-Down key &
      choose newest 5.5.x version (or type `5.5.23`) | Add
   1. Query: `jersey-container-servlet`, Choose the org.glassfish one, newest
      2.x version | Add
   1. Query: `jersey-hk2`, Choose same version as jersey-container-servlet | Add
1. Right-click project name | New | Other...
   1. Web Services | RESTful Web Services from Patterns | Next
   1. Simple Root Resource | Next | Finish
1. Menu: Debug | Debug Project
   1. Provide `manager`/`manager` as Tomcat's uid/pwd, if requested.
   1. A browser window opens at localhost:8080
   1. Type url `localhost:8080/webresources/generic`
      1. Should get HTTP 500 w/ `UnsupportedOperationException` message
      1. Change method `getXml()` in `GenericResource.java` to: `return "<hello>world</hello>";`
      1. Ctrl-S to save the file
      1. Refresh the browser window, should get the xml text now
1. File `ApplicationConfig.java`: Change `@javax.ws.rs.ApplicationPath` from
   `"webresources"`to `"rest"`
   1. Ctrl-S to save the file
   1. Change browser url to `localhost:8080/rest/generic`

### Deploy

Once built and ran, on the Tomcat container, the address is:
`/project_name/rest/generic`.

When used with the Proxy container, the address is:
https://localhost.merkator.com:7443/api/project_name/rest/generic
