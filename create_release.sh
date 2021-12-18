#!/usr/bin/env bash

# The releases file must be defined in this way: 
#
# repository_path    snapshot_version
# /home/root/example x.y.z-SNAPSHOT
repositories_file=$1

if [ -z "${repositories_file}" ]
then
  echo -e "\nReleases definition file must be defined by argument comandline"
  exit 0
fi

while read line
do
  splitted_line=($line)
  repository=${splitted_line[0]}
  snapshot_version=${splitted_line[1]}

  # Check if repository path is a directory
  if [[ -d ${repository} ]]
  then
    echo -e "\nRelease process for $repository"
    cd ${repository}
    echo -e "\nUpdating local develop branch"
    git checkout -f develop --quiet
    git pull origin develop --quiet
    version=$(cat pom.xml | grep -Po '<version>(.*)-SNAPSHOT</version>' pom.xml | grep -Po '[0-9]*\.[0-9]*\.[0-9]*')

    echo -e "\nIt will create new release with next data:"
    echo -e "\n Repository path: $repository"
    echo -e "\n RC version: $version"
    echo -e "\n New SNAPSHOT version: $snapshot_version"
    echo -e "\nContinue? [y/n]"
    read -n 1 confirmation_answer <&1

    if [[ $confirmation_answer == 'y' ]]
    then

      echo -e "\nCreating release"
      git checkout -b release/${version}
      # Replace SNAPSHOT keyword for RC1
      sed -i 's/-SNAPSHOT/-RC1/g' pom.xml
      git add pom.xml
      git commit -m "[RELEASE]updating poms for $version branch with release candidate versions"
      git push --set-upstream origin release/${version}

      echo -e "\nSetting new version for development"
      git checkout develop
      # Replace old version for new snapshot version
      sed -i "s/$version-SNAPSHOT/$snapshot_version/g" pom.xml
      git add pom.xml
      git commit -m "[RELEASE]updating poms for ${snapshot_version} development"
      git push

      echo -e "\nRelease for $repository finished"
    else
      echo -e "\nCancelling release process"
    fi
  else
    echo -e "\nRepository not exists: $repository"
  fi
  cd ..
  echo -e "\n\n#################################################################"
done < ${repositories_file}
