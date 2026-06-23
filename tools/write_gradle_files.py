#!/usr/bin/env python3
"""Generate settings.gradle, gradle.properties, and per-package build.gradle
files for module-ballerinax-sap.businessone. Re-run after adding a connector."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GROUPS = [
    "administration", "financials", "fixedassets", "businesspartners", "crm",
    "sales", "purchasing", "banking", "inventory", "production", "projects",
    "service", "humanresources", "localization",
]
DESCRIPTIONS = {
    "administration": "Administration & Setup APIs",
    "financials": "Financials APIs",
    "fixedassets": "Fixed Assets APIs",
    "businesspartners": "Business Partners APIs",
    "crm": "CRM APIs",
    "sales": "Sales (A/R) APIs",
    "purchasing": "Purchasing (A/P) APIs",
    "banking": "Banking & Payments APIs",
    "inventory": "Inventory APIs",
    "production": "Production & MRP APIs",
    "projects": "Project Management APIs",
    "service": "Service APIs",
    "humanresources": "Human Resources APIs",
    "localization": "Localization & Electronic Documents APIs",
}
LICENSE_HEADER = """\
/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
"""

# ---------- settings.gradle ----------
includes = ["':checkstyle'", "':businessone-native'", "':businessone-ballerina'",
            "':businessone-ballerina:businessone'"] + [
            f"':businessone-ballerina:{g}'" for g in GROUPS] + ["':businessone-examples'"]
project_dirs = [
    'project(\':checkstyle\').projectDir = file("build-config${File.separator}checkstyle")',
    "project(':businessone-native').projectDir = file('native')",
    "project(':businessone-ballerina').projectDir = file('ballerina')",
    "project(':businessone-ballerina:businessone').projectDir = file('ballerina/businessone')",
] + [f"project(':businessone-ballerina:{g}').projectDir = file('ballerina/{g}')" for g in GROUPS] + [
    "project(':businessone-examples').projectDir = file('examples')",
]

(ROOT / "settings.gradle").write_text(LICENSE_HEADER + """
pluginManagement {
    plugins {
        id "com.github.spotbugs" version "${spotbugsPluginVersion}"
        id "com.github.spotbugs-base" version "${spotbugsPluginVersion}"
        id "de.undercouch.download" version "${downloadPluginVersion}"
        id "net.researchgate.release" version "${releasePluginVersion}"
        id "io.ballerina.plugin" version "${ballerinaGradlePluginVersion}"
    }

    repositories {
        gradlePluginPortal()
        maven {
            url = 'https://maven.pkg.github.com/ballerina-platform/*'
            credentials {
                username System.getenv("packageUser")
                password System.getenv("packagePAT")
            }
        }
    }
}

plugins {
    id "com.gradle.enterprise" version "3.2"
}

rootProject.name = 'module-ballerinax-sap.businessone'

""" + "\n".join(f"include {i}" for i in includes) + "\n\n"
  + "\n".join(project_dirs) + """

gradleEnterprise {
    buildScan {
        termsOfServiceUrl = 'https://gradle.com/terms-of-service'
        termsOfServiceAgree = 'yes'
    }
}
""")

# ---------- gradle.properties ----------
props = """org.gradle.caching=true
group=io.ballerina.lib

# Dummy value; the repo contains multiple packages, each versioned below.
version=1.0.0-SNAPSHOT
businessoneVersion=1.0.0-SNAPSHOT
""" + "".join(f"{g}Version=1.0.0-SNAPSHOT\n" for g in GROUPS) + """
checkstylePluginVersion=10.12.0
spotbugsPluginVersion=6.0.18
ballerinaGradlePluginVersion=3.0.0
downloadPluginVersion=5.4.0
releasePluginVersion=2.8.0

ballerinaLangVersion=2201.13.0
"""
(ROOT / "gradle.properties").write_text(props)

# ---------- root build.gradle ----------
(ROOT / "build.gradle").write_text(LICENSE_HEADER + """
description = 'Ballerina - SAP Business One Service Layer Connectors'

ext.ballerinaLangVersion = project.ballerinaLangVersion

allprojects {
    group = project.group
    version = project.version

    apply plugin: 'maven-publish'

    repositories {
        mavenLocal()
        maven {
            url = 'https://maven.wso2.org/nexus/content/repositories/releases/'
        }

        maven {
            url = 'https://maven.wso2.org/nexus/content/groups/wso2-public/'
        }

        maven {
            url = 'https://repo.maven.apache.org/maven2'
        }

        maven {
            url = 'https://maven.pkg.github.com/ballerina-platform/*'
            credentials {
                username System.getenv("packageUser")
                password System.getenv("packagePAT")
            }
        }
    }

    ext {
        snapshotVersion = '-SNAPSHOT'
        timestampedVersionRegex = '.*-\\\\d{8}-\\\\d{6}-\\\\w.*\\$'
    }
}

task clean {
}

task build {
    dependsOn(':businessone-native:build')
    dependsOn(':businessone-ballerina:build')
    dependsOn(':businessone-examples:build')
}
""")

# ---------- ballerina/build.gradle (container) ----------
(ROOT / "ballerina" / "build.gradle").write_text(LICENSE_HEADER + """
import groovy.json.JsonSlurper

description = 'Ballerina - SAP Business One Packages'

subprojects {
    ext {
        packageOrg = "ballerinax"
        connectorTomlPlaceHolder = new File("${project.rootDir}/build-config/resources/BallerinaConnector.toml")
        wrapperTomlPlaceHolder = new File("${project.rootDir}/build-config/resources/BallerinaWrapper.toml")
    }
}

task build {
    dependsOn subprojects.collect { ":businessone-ballerina:${it.name}:build" }
}

task clean {
    dependsOn subprojects.collect { ":businessone-ballerina:${it.name}:clean" }
}

def readmeMdPlaceholder = new File("${project.rootDir}/build-config/resources/README.md")

task updateDocumentationFiles {
    doLast {
        def files = []
        new File("${project.rootDir}/ballerina").eachDir { files << it.name }

        for (String dir in files) {

            if (dir == "businessone") {
                continue
            }

            def packageProperties = new File("${project.rootDir}/ballerina/${dir}/docs.json")
            def parsedJson = new JsonSlurper().parseText(packageProperties.text)

            def readmeMdFile = new File("${project.rootDir}/ballerina/${dir}/README.md")

            def newReadmeMdFile = readmeMdPlaceholder.text
            newReadmeMdFile = newReadmeMdFile.replace("@package-name@", "sap.businessone.${dir}")
            newReadmeMdFile = newReadmeMdFile.replace("@description@", parsedJson.description)
            newReadmeMdFile = newReadmeMdFile.replace("@key-features@", parsedJson."key-features".collect { "- ${it}" }.join("\\n"))
            newReadmeMdFile = newReadmeMdFile.replace("@import-statement@", parsedJson."import-statement")
            newReadmeMdFile = newReadmeMdFile.replace("@client-init@", parsedJson."client-init")
            newReadmeMdFile = newReadmeMdFile.replace("@api-invocation@", parsedJson."api-invocation")

            readmeMdFile.text = newReadmeMdFile
        }
    }
}
""")

# ---------- per-package build.gradle ----------
CONNECTOR_TEMPLATE = LICENSE_HEADER + """
import org.apache.tools.ant.taskdefs.condition.Os

plugins {{
    id 'net.researchgate.release'
    id 'io.ballerina.plugin'
}}

description = 'Ballerina - SAP Business One {description}'

def packageName = "sap.businessone.{group}"
def moduleVersion = project.{group}Version.replace("-SNAPSHOT", "")
def ballerinaTomlFile = file("${{project.projectDir}}/Ballerina.toml")

ballerina {{
    packageOrganization = project.ext.packageOrg
    module = packageName
    isConnector = true
    platform = "any"
    testCoverageParam = '--code-coverage --coverage-format=xml --includes=ballerinax.* --excludes=modules/**/**'
}}

task updateTomlFiles {{
    doLast {{
        def newBallerinaToml = connectorTomlPlaceHolder.text.replace("@package.name@", packageName)
        newBallerinaToml = newBallerinaToml.replace("@toml.version@", moduleVersion)
        ballerinaTomlFile.text = newBallerinaToml
    }}
}}

task commitTomlFiles {{
    doLast {{
        project.exec {{
            ignoreExitValue true
            if (Os.isFamily(Os.FAMILY_WINDOWS)) {{
                commandLine 'cmd', '/c', "git commit -m \\"[Automated] Update the toml files\\" Ballerina.toml Dependencies.toml"
            }} else {{
                commandLine 'sh', '-c', "git commit -m '[Automated] Update the toml files' Ballerina.toml Dependencies.toml"
            }}
        }}
    }}
}}

release {{
    buildTasks = ['build']
    failOnSnapshotDependencies = true
    versionPropertyFile = '../../gradle.properties'
    versionProperties = ['{group}Version']
    tagTemplate = '{group}-v${{version}}'
    git {{
        requireBranch = "release-{group}-${{moduleVersion}}"
        pushToRemote = 'origin'
    }}
}}

// Until the wrapper is on Ballerina Central, builds resolve it from the
// local repository; make sure it is packed and pushed there first.
build.dependsOn ':businessone-ballerina:businessone:pushToLocalRepo'
test.dependsOn ':businessone-ballerina:businessone:pushToLocalRepo'

publishToMavenLocal.dependsOn build
publish.dependsOn build
"""

for g in GROUPS:
    (ROOT / "ballerina" / g / "build.gradle").write_text(
        CONNECTOR_TEMPLATE.format(group=g, description=DESCRIPTIONS[g]))

WRAPPER_GRADLE = LICENSE_HEADER + """
import org.apache.tools.ant.taskdefs.condition.Os

plugins {
    id 'net.researchgate.release'
    id 'io.ballerina.plugin'
}

description = 'Ballerina - SAP Business One Service Layer Client'

def packageName = "sap.businessone"
def moduleVersion = project.businessoneVersion.replace("-SNAPSHOT", "")
def ballerinaTomlFile = file("${project.projectDir}/Ballerina.toml")

ballerina {
    packageOrganization = project.ext.packageOrg
    module = packageName
    isConnector = true
    testCoverageParam = '--code-coverage --coverage-format=xml --includes=ballerinax.*'
}

task updateTomlFiles {
    doLast {
        def newBallerinaToml = wrapperTomlPlaceHolder.text.replace("@toml.version@", moduleVersion)
        ballerinaTomlFile.text = newBallerinaToml
    }
}

task commitTomlFiles {
    doLast {
        project.exec {
            ignoreExitValue true
            if (Os.isFamily(Os.FAMILY_WINDOWS)) {
                commandLine 'cmd', '/c', "git commit -m \\"[Automated] Update the toml files\\" Ballerina.toml Dependencies.toml"
            } else {
                commandLine 'sh', '-c', "git commit -m '[Automated] Update the toml files' Ballerina.toml Dependencies.toml"
            }
        }
    }
}

release {
    buildTasks = ['build']
    failOnSnapshotDependencies = true
    versionPropertyFile = '../../gradle.properties'
    versionProperties = ['businessoneVersion']
    tagTemplate = 'businessone-v${version}'
    git {
        requireBranch = "release-businessone-${moduleVersion}"
        pushToRemote = 'origin'
    }
}

build.dependsOn ':businessone-native:build'
test.dependsOn ':businessone-native:build'

// Push the packed wrapper to the local Ballerina repository so that the
// connector packages in this repo can resolve it before it is published to
// Ballerina Central (their Ballerina.toml pins `repository = "local"`).
task pushToLocalRepo {
    dependsOn build
    doLast {
        def bala = "build/bal_build_target/bala/ballerinax-sap.businessone-java21-${moduleVersion}.bala"
        project.delete("${System.getProperty('user.home')}/.ballerina/repositories/local/bala/ballerinax/sap.businessone/${moduleVersion}")
        project.exec {
            workingDir project.projectDir
            if (Os.isFamily(Os.FAMILY_WINDOWS)) {
                commandLine 'cmd', '/c', "bal.bat push --repository=local ${bala} && exit %%ERRORLEVEL%%"
            } else {
                commandLine 'sh', '-c', "bal push --repository=local ${bala}"
            }
        }
    }
}

publishToMavenLocal.dependsOn build
publish.dependsOn build
"""
(ROOT / "ballerina" / "businessone" / "build.gradle").write_text(WRAPPER_GRADLE)

# ---------- build-config/resources templates ----------
res = ROOT / "build-config" / "resources"
res.mkdir(parents=True, exist_ok=True)
(res / "BallerinaConnector.toml").write_text("""[package]
org = "ballerinax"
name = "@package.name@"
version = "@toml.version@"
distribution = "2201.13.0"
authors = ["Ballerina"]
keywords = ["Business Management/ERP", "Cost/Paid", "Vendor/SAP", "Area/ERP & Business Operations", "Type/Connector"]
repository = "https://github.com/ballerina-platform/module-ballerinax-sap.businessone"
icon = "../icon.png"
license = ["Apache-2.0"]

[build-options]
observabilityIncluded = true

# TODO: drop `repository = "local"` once ballerinax/sap.businessone is
# published to Ballerina Central. Until then the wrapper is resolved from the
# local repository; the gradle build pushes it there automatically.
[[dependency]]
org = "ballerinax"
name = "sap.businessone"
version = "1.0.0"
repository = "local"
""")
(res / "BallerinaWrapper.toml").write_text("""[package]
org = "ballerinax"
name = "sap.businessone"
version = "@toml.version@"
distribution = "2201.13.0"
authors = ["Ballerina"]
keywords = ["Business Management/ERP", "Cost/Paid", "Vendor/SAP", "Area/ERP & Business Operations", "Type/Connector"]
repository = "https://github.com/ballerina-platform/module-ballerinax-sap.businessone"
icon = "../icon.png"
license = ["Apache-2.0"]

[build-options]
observabilityIncluded = true

[platform.java21]
graalvmCompatible = true

[[platform.java21.dependency]]
groupId = "io.ballerina.lib"
artifactId = "sap.businessone-native"
version = "@toml.version@"
path = "../../native/build/libs/sap.businessone-native-@toml.version@.jar"
""")

print("gradle files written")
