# Section 6 - SonarQube Integation with Jenkins

SonarQube is an open-source tool for continuous code quality inspection. It helps detect bugs, vulnerabilities, and maintain code quality in various programming languages. 


## Introduction
- Create account at https://sonarcloud.io
- Generate authentication token on SonarQube
- Create credentials for token in Jenkins
- Download and install the plugin `SonarQube scanner` in Jenkins
- Configure SonarQube server
- Add SonarQube server to jenkins
- Create SonarQube properties-file
- Add SonarQube stage in the Jenkinsfile

## Setup SonarQube

- **Create account**
    - Go to https://sonarcloud.io
    - Select `[Try out]` to create new account
      - You can create new account
      - You can use 1-click login with github
- **Generate token**
    - Go to https://sonarcloud.io/account/security
    - Provide a token-name and click `[Generate token]` and save the token

- **Add credentials to Jenkins**
  - Go to `[Dashboard]` -> `[Manage Jenkins]` -> `[Credentials]` -> `[System]` -> `[Global credentials (unrestricted)]`
  - Click `[Add credentials]` and add the following:
    - Kind: Secret text
    - Scope: Global
    - Secret <the_sonarqube_token>
    - ID: sonarqube-key
  - Click `[Create]`

## Integrate SonarQube with Jenkins
- Installing SonarQube plugin
    - Go to `[Dashboard]` -> `[Manage Jenkins]` -> `[Plugins]`
    - Search for `SonarQube Scanner`
  
- Creating sonarcube server
  - Go to `[Dashboard]` -> `[Manage Jenkins]` -> `[System]`
  - Search for SonarQube and click `[Add SonarQube]`
    - Name: sonarqube-server
    - Server URL: https://sonarcloud.io
    - Server authentication token: sonarqube-key
  - Click `[Save]`

- Creating SonarQube scanner
  - Go to `[Dashboard]` -> `[Manage Jenkins]` -> `[Tools]`
  - Click `Add SonarQube Scanner` in the `SonarQube Scanner` section
    - Name: sonar-scanner
    - Check `[Install automatically]` and let it be the default version
  - Click apply and save

## Writing a sonar properties file

### Creating an organization
- Documentation: [SonarScanner](https://docs.sonarsource.com/sonarqube/9.9/analyzing-source-code/scanners/sonarscanner/)

- Create Organization manually here: https://sonarcloud.io/account/organizations
- Set `Name` and `Key` as you like and insert them in to `sonar-project.properties`
- Select *Free Plan*
- Click `[Create Organization]`

### Creating project in organization
- Click `[Analyze new project]`
- Give an appropriate project name and click `[Set Up]`
- Go to `[Information]`, get the project key and put it into the `properties`-file

```bash
# Exemplary file `sonar-project.properties`
sonar.verbose=true
sonar.organization=jw01-key
sonar.projectKey=jw01-key_twittertrend
sonar.projectName=twittertrend
sonar.language=java
sonar.sourceEncoding=UTF-8
sonar.sources=.
sonar.java.binaries=target/classes
sonar.coverage.jacoco.xmlReportsPaths=target/site/jacoco/jacoco.xml
```

- Put the file in your source-code directory an push it to github.
- Add another stage to the jenkins file to apply sonar analysis

### Adding SonarQube-Stage to the Jenkinsfile

- Documentation: https://docs.sonarsource.com/sonarqube/9.9/analyzing-source-code/scanners/jenkins-extension-sonarqube/

- relevant section `stage('SonarQube analysis')`

```groovy
stage('SonarQube analysis') {
    def scannerHome = tool 'SonarScanner 4.0';
    withSonarQubeEnv('My SonarQube Server') { // If you have configured more than one global server connection, you can specify its name
      sh "${scannerHome}/bin/sonar-scanner"
    }
  }
```

After successfully running the multi-branch pipeline, you will be able to see the results on sonarcloud.io

## Adding Unit-tests stage in Jenkinsfile
Below are the changes to the `Jenkinsfile` that are required:

```groovy
stage('Clone-code') 
{
    steps 
    {
        echo "-------------- BUILD STARTED --------------"
        sh 'mvn clean deploy -Dmaven.test.skip=true'  // disable unit tests in build stage
        echo "-------------- BUILD COMPLETED  --------------"
    }
}
stage("test") 
{
    steps 
    {
        echo "-------------- UNIT TEST STARTED --------------"
        sh 'mvn surefire-report:report'                    // only run unit-tests in "test" stage
        echo "-------------- UNIT TEST COMPLETED  --------------"
    }
}
```

### Adding Qulity-Gate stage in Jenkinsfile
```groovy
stage("Quality Gate") 
{
    steps 
    {
        script 
        {
            timeout(time: 1, unit: 'HOURS') 
            {  // Just in case something goes wrong (pipeline will be kiled after timeout)
                def qg = waitForQualityGate()  // Reuse `taskId` prev. colected by `withSonarQubeEnv`
                if (qg.status != 'OK') 
                {
                    error "Pipeline aborted due to quality gate failure: ${qg.status}"
                }
            }
        }
    }
}
```