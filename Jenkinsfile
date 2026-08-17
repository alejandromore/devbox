@Library('shared-lib') _

pipeline {
    // El controlador solo tiene git y python3. terraform y ansible viven en el
    // agente que provisiona el Docker cloud con esta etiqueta
    // (swr-jenkins-alejandro/jenkins-agent-huawei).
    agent { label 'agent-huawei' }

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
                sh 'git config --global http.version HTTP/1.1 || true'
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
                            def ip = readFile("${WORKSPACE}/ecs_public_ip.txt").trim()
                            echo "============================================================"
                            echo "INFRAESTRUCTURA LISTA"
                            echo "ECS: ${ip}"
                            echo "Registrar el A record ${params.DEVBOX_DOMAIN} -> ${ip}"
                            echo "Recien cuando el dominio resuelva, relanzar con"
                            echo "RUN_TERRAFORM=false y RUN_ANSIBLE=true."
                            echo "============================================================"
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
                    def ecsPublicIpInput = params.ECS_PUBLIC_IP?.trim()
                    def ecsPublicIp = ecsPublicIpInput ? ecsPublicIpInput : readFile("${WORKSPACE}/ecs_public_ip.txt").trim()

                    // Permite pegar solo la IP o una URL completa; Ansible necesita solo el host/IP.
                    ecsPublicIp = ecsPublicIp.replaceFirst('^https?://', '').replaceFirst('/.*$', '').trim()

                    env.ECS_PUBLIC_IP_VALUE  = ecsPublicIp
                    env.ECS_PRIVATE_KEY_FILE = "${WORKSPACE}/ecs_private_key.txt"
                    env.DEVBOX_DOMAIN_VALUE  = params.DEVBOX_DOMAIN.trim()

                    if (!fileExists(env.ECS_PRIVATE_KEY_FILE)) {
                        error("Falta ecs_private_key.txt en el workspace: correr antes el paso 1 (RUN_TERRAFORM=true).")
                    }
                }

                // Ejecutar el playbook de instalacion
                dir(env.ANS_DIR) {
                    withCredentials([
                        string(credentialsId: 'devbox-web-pass', variable: 'DEVBOX_WEB_PASS')
                    ]) {
                        sh '''
                            set -e
                            chmod 600 "$ECS_PRIVATE_KEY_FILE"
                            export ANSIBLE_HOST_KEY_CHECKING=False

                            # La contrasena del escritorio va en un archivo 600, no en
                            # --extra-vars: la linea de comandos es visible en `ps` para
                            # cualquier proceso del agente.
                            VARS_FILE=$(mktemp)
                            chmod 600 "$VARS_FILE"
                            trap 'rm -f "$VARS_FILE"' EXIT

                            cat > "$VARS_FILE" <<EOF
ansible_host: "$ECS_PUBLIC_IP_VALUE"
devbox_domain: "$DEVBOX_DOMAIN_VALUE"
devbox_web_pass: "$DEVBOX_WEB_PASS"
EOF

                            ansible-playbook -i inventory/hosts playbook/deploy.yml \
                                --private-key "$ECS_PRIVATE_KEY_FILE" \
                                --extra-vars "@$VARS_FILE"
                        '''
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
