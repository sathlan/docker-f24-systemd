// -*- mode: groovy -*-
node ('docker') {
  def dockerOpt = "-v /sys/fs/cgroup:/sys/fs/cgroup:ro -t"
  def dockerBuildOpt = "."
  def docker_name = 'f24-systemd'
  def image_name = "sathlan/${docker_name}"
  def ruby_env = ["PATH=${pwd()}/bin:${env.PATH}", "GEM_HOME=${pwd()}/.bundled_gems"]
  def build_image = "${image_name}:${env.BUILD_ID}"
  def myEnv

  stage('Checkout') {
    checkout scm
  }

  ansiColor() {
    stage('Prepare env') {
      withEnv(ruby_env) {
        sh "[ ! -e Gemfile.lock ] || rm Gemfile.lock"
        sh "bundle install --binstubs"
      }
    }

    stage('build image') {
      myEnv = docker.build "${image_name}:${env.BUILD_ID}", "${dockerBuildOpt}"
    }

    stage('publish image') {
      myEnv.withRun(dockerOpt) {c ->
        sh "rm -rf artifacts && mkdir -p artifacts"
        sh "docker inspect ${c.id} > artifacts/inspect.txt"
        sh "docker history ${build_image} > artifacts/history.txt"
        archive 'artifacts/'
      }
    }

    stage('test image') {
      myEnv.withRun("${dockerOpt}") {c ->
        withEnv(ruby_env + ["${docker_name.replaceAll('-','_').toUpperCase()}_ID=${c.id}", "LOCALHOST_ID=${c.id}", "DOCKER_IMAGE=${build_image}"]) {
          sh "docker logs ${c.id}"
          sh "rake spec:${docker_name}"
          sh "rake spec:localhost"
        }
      }
    }

    stage('promote') {
      timeout(time: 1, unit: 'DAYS') {
        if (askForNextStep('Deploy to GitHub ?')) {
          lock("githubPush-docker-${docker_name}") {
            githubPush('jenkins', 'github')
            if (askForNextStep('Release to GitHub ?')) {
              withEnv(ruby_env) {
                githubRelease()
              }
            }
          }
        }
      }
    }
  }
}
