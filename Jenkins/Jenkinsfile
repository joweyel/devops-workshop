def registry = 'https://joweyel01.jfrog.io'  // for jfrog

pipeline {
    agent 
    {
        node 
        {
            label 'maven'
        }
    }
    environment 
    {
        PATH = "/opt/apache-maven-3.9.9/bin:$PATH"
    }

    stages 
    {
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

        // stage('SonarQube analysis') 
        // {
        //     environment 
        //     {
        //         // configured in Dashboard -> Manage Jenkins -> Tools
        //         scannerHome = tool 'jw-sonar-scanner'
        //     }
        //     steps 
        //     {
        //         // configured in Dashboard -> Manage Jenkins -> System
        //         withSonarQubeEnv('jw-sonarqube-server') 
        //         {
        //             sh "${scannerHome}/bin/sonar-scanner"
        //         }
        //     }
        // }

        // stage("Quality Gate") 
        // {
        //     steps 
        //     {
        //         script 
        //         {
        //             timeout(time: 1, unit: 'HOURS') 
        //             {  // Just in case something goes wrong (pipeline will be kiled after timeout)
        //                 def qg = waitForQualityGate()  // Reuse `taskId` prev. colected by `withSonarQubeEnv`
        //                 if (qg.status != 'OK') 
        //                 {
        //                     error "Pipeline aborted due to quality gate failure: ${qg.status}"
        //                 }
        //             }
        //         }
        //     }
        // }

        // Saving Artifacts to JFrog
        stage("Jar Publish") 
        {
            steps 
            {
                script 
                {
                    echo '<--------------- Jar Publish Started --------------->'
                    def server = Artifactory.newServer url:registry+"/artifactory" ,  credentialsId:"artifact-cred"
                    def properties = "buildid=${env.BUILD_ID},commitid=${GIT_COMMIT}";
                    def uploadSpec = """{
                    "files": [
                        {
                            "pattern": "jarstaging/(*)",
                            "target": "jweyel01-libs-release-local/{1}",
                            "flat": "false",
                            "props" : "${properties}",
                            "exclusions": [ "*.sha1", "*.md5"]
                        }
                    ]
                    }"""
                    def buildInfo = server.upload(uploadSpec)
                    buildInfo.env.collect()
                    server.publishBuildInfo(buildInfo)
                    echo '<--------------- Jar Publish Ended --------------->'  
                }
            }   
        }   
    }
}
