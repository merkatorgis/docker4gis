#!/bin/bash

# create a default workspace
workspace=$GEOSERVER_DATA_DIR/workspaces/$DOCKER_USER
if ! [ -d "$workspace" ]; then
  mkdir -p "$workspace"
  echo "<workspace>
  <id>WorkspaceInfoImpl--60123e77:176192ba3b5:-7ffd</id>
  <name>$DOCKER_USER</name>
  <isolated>false</isolated>
</workspace>" >"$workspace"/workspace.xml
  echo "<namespace>
  <id>NamespaceInfoImpl--60123e77:176192ba3b5:-7ffc</id>
  <prefix>$DOCKER_USER</prefix>
  <uri>$DOCKER_USER</uri>
  <isolated>false</isolated>
</namespace>" >"$workspace"/namespace.xml
  echo "<settings>
  <id>SettingsInfoImpl--6bf80400:176198d7ba7:-7fff</id>
  <workspace>
    <id>WorkspaceInfoImpl--60123e77:176192ba3b5:-7ffd</id>
    <name>geowep</name>
    <isolated>false</isolated>
  </workspace>
  <contact>
    <id>contact</id>
    <addressCity>Alexandria</addressCity>
    <addressCountry>Egypt</addressCountry>
    <addressType>Work</addressType>
    <contactEmail>claudius.ptolomaeus@gmail.com</contactEmail>
    <contactOrganization>The Ancient Geographers</contactOrganization>
    <contactPerson>Claudius Ptolomaeus</contactPerson>
    <contactPosition>Chief Geographer</contactPosition>
  </contact>
  <charset>UTF-8</charset>
  <numDecimals>8</numDecimals>
  <onlineResource>http://geoserver.org</onlineResource>
  <verbose>false</verbose>
  <verboseExceptions>false</verboseExceptions>
  <metadata>
    <map>
      <entry>
        <string>quietOnNotFound</string>
        <boolean>false</boolean>
      </entry>
    </map>
  </metadata>
  <localWorkspaceIncludesPrefix>false</localWorkspaceIncludesPrefix>
</settings>" >"$workspace"/settings.xml
fi
