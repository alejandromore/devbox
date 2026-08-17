@Library('shared-lib') _

pipeline {
    //agent { label 'agent-huawei' }
    agent any

    options {
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['deploy', 'destroy'],
            description: 'Acción sobre el ambiente'
        )
        booleanParam(
            name: 'RUN_TERRAFORM',
            defaultValue: false,
            description: 'Construir infraestructura con Terraform (VPC + ECS + EIP)'
        )
        booleanParam(
            name: 'RUN_ANSIBLE',
            defaultValue: false,
            description: 'Instalar el escritorio devbox (XFCE + KasmVNC + Caddy)'
        )
        string(
            name: 'ECS_PUBLIC_IP',
            defaultValue: '',
            description: 'IP pública del ECS. Sale del build #1 (output ecs_public_ip)'
        )
        string(
            name: 'DEVBOX_DOMAIN',
            defaultValue: 'devbox.alejandromore.lat',
            description: 'Dominio del escritorio. Debe resolver a ECS_PUBLIC_IP antes de correr Ansible'
        )
    }

    environment {
        TF_IN_AUTOMATION = "true"
        TF_CLI_ARGS = "-no-color"
        TF_DIR   = 'terraform'
        ANS_DIR  = 'ansible'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Deploy') {
            when {
                expression { params.RUN_TERRAFORM }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'hwc-access-key', variable: 'HW_ACCESS_KEY'),
                    string(credentialsId: 'hwc-secret-key', variable: 'HW_SECRET_KEY'),
                    string(credentialsId: 'hwc-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'hwc-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    script {

                        terraformDeploy(
                            dir: env.TF_DIR,
                            varsFile: 'local.tfvars',
                            action: params.ACTION,
                            outputs: ['ecs_public_ip', 'ecs_private_key']
                        )

                        if (params.ACTION == 'deploy') {
                            echo "IP pública del ECS: ${env.ecs_public_ip}"
                            echo "Registrá el A record ${params.DEVBOX_DOMAIN} -> ${env.ecs_public_ip} antes del build con RUN_ANSIBLE=true"
                        }
                    }
                }
            }
        }

        stage('Deploy Desktop with Ansible') {

            when {
                allOf {
                    expression { params.ACTION == 'deploy' }
                    expression { params.RUN_ANSIBLE }
                }
            }

            steps {
                script {

                    env.ecs_public_ip = params.ECS_PUBLIC_IP
                    env.ecs_private_key = "${WORKSPACE}/ecs_private_key.txt"

                    //writeFile(
                    //    file: env.ecs_private_key,
                    //    text: new String(params.ECS_PRIVATE_KEY.decodeBase64())
                    //)
                }
                // Ejecutar el playbook de instalacion
                dir(env.ANS_DIR) {

                    withCredentials([
                        usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN'),
                        string(credentialsId: 'hwc-access-key', variable: 'HWC_ACCESS_KEY'),
                        string(credentialsId: 'hwc-secret-key', variable: 'HWC_SECRET_KEY'),
                        string(credentialsId: 'devbox-web-pass', variable: 'DEVBOX_WEB_PASS')
                    ]) {

                        sh """
                            set -e
                            chmod 600 ${env.ecs_private_key}

                            # Deshabilitar host key checking
                            export ANSIBLE_HOST_KEY_CHECKING=False

                            # Ejecutar playbook con todas las credenciales
                            ansible-playbook -i inventory/hosts playbook/deploy.yml \\
                                --private-key ${env.ecs_private_key} \\
                                --extra-vars "ansible_host=${env.ecs_public_ip} \\
                                            devbox_domain=${params.DEVBOX_DOMAIN} \\
                                            devbox_web_pass=${DEVBOX_WEB_PASS} \\
                                            github_user=${GITHUB_USER} \\
                                            github_token=${GITHUB_TOKEN} \\
                                            hwc_access_key=${HWC_ACCESS_KEY} \\
                                            hwc_secret_key=${HWC_SECRET_KEY}"

                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline ejecutado correctamente (${params.ACTION})"
            script {
                if (params.ACTION == 'deploy' && params.RUN_ANSIBLE) {
                    echo "Escritorio disponible en https://${params.DEVBOX_DOMAIN} (usuario: devbox)"
                }
            }
        }
        failure {
            echo "Error en el pipeline"
        }
        //always {
        //    deleteDir()
        //}
    }
}
