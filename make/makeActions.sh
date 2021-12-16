#!/bin/bash -eu



#
# Carrega todos os scripts base
TMP_THIS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TMP_PATH_TO_SCRIPTS="${TMP_THIS_DIR}/mseStandAlone/"
TMP_TARGET_SCRIPTS=(
  "functions/interface/"
  "functions/string/"
  "functions/tools/"
  "management/config_files/"
)


for tgtDir in "${TMP_TARGET_SCRIPTS[@]}"; do
  tgtPath="${TMP_PATH_TO_SCRIPTS}${tgtDir}"
  tgtFiles=$(find "$tgtPath" -name "*.sh");

  while read rawLine
  do
    source "$rawLine"
  done <<< ${tgtFiles}
done

unset tgtDir
unset tgtPath
unset tgtFiles
unset rawLine

TMP_ROOT_PATH=$(dirname "${TMP_THIS_DIR}")

unset TMP_THIS_DIR
unset TMP_PATH_TO_SCRIPTS
unset TMP_TARGET_SCRIPTS











#
# Reinicia o arquivo de variáveis de ambiente a partir do modelo
# padrão.
# Todos os valores definidos serão resetados.
#
restartEnvFile() {
  setIMessage "" 1;
  setIMessage "${LPURPLE}ATENÇÃO${NONE}";
  setIMessage "TODAS as configurações existentes no momento serão perdidas.";
  setIMessage "Você confirma esta ação?";
  promptUser;

  if [ "$MSE_GB_PROMPT_RESULT" != "1" ]; then
    setIMessage "" 1;
    setIMessage "Ação abortada pelo usuário.";
    alertUser;
  else
    cp "${TMP_ROOT_PATH}/make/.env" "${TMP_ROOT_PATH}/.env";
  fi;
}




#
# Configura as variáveis de ambiente para o container
# do servidor web
#
configEnvWebServer() {
  setIMessage "" 1;
  setIMessage "${LPURPLE}Iniciando configuração do WebServer${NONE}";
  setIMessage "Você confirma esta ação?";
  promptUser;

  if [ "$MSE_GB_PROMPT_RESULT" != "1" ]; then
    setIMessage "" 1;
    setIMessage "Ação abortada pelo usuário.";
    alertUser;
  else
    local userName=$(whoami);
    local userUID=$(id -u ${userName});
    local userGID=$(id -g ${userName});

    setIMessage "" 1;
    setIMessage "Web Server:";
    setIMessage "Configurando para rodar com o usuário: ${LPURPLE}${userName}${NONE}.";
    setIMessage "Você confirma esta ação?";
    promptUser

    if [ "$MSE_GB_PROMPT_RESULT" != "1" ]; then
      setIMessage "" 1;
      setIMessage "Ação abortada pelo usuário.";
      alertUser;
    else

      MSE_GB_PROMPT_LIST_OPTIONS_LABELS=("utest" "lcl" "dev" "hmg" "qa" "prd")
      MSE_GB_PROMPT_LIST_OPTIONS_VALUES=("UTEST" "LCL" "DEV" "HMG" "QA" "PRD")

      setIMessage "" 1;
      setIMessage "Web Server:";
      setIMessage "Informe o tipo de ambiente no qual o projeto está sendo configurado.";
      promptUser "list"


      if [ "$MSE_GB_PROMPT_RESULT" != "0" ]; then
        mcfSetVariable "ENVIRONMENT" "${MSE_GB_PROMPT_RESULT}" "${TMP_ROOT_PATH}/.env";
        mcfSetVariable "APACHE_RUN_USER" "${userUID}" "${TMP_ROOT_PATH}/.env";
        mcfSetVariable "APACHE_RUN_GROUP" "${userGID}" "${TMP_ROOT_PATH}/.env";
      fi;
    fi;
  fi;
}





#
# Efetua a configuração do banco de dados.
configEnvDataBaseServer() {
  setIMessage "" 1;
  setIMessage "${LPURPLE}Iniciando configuração do DataBaseServer${NONE}";
  setIMessage "Você confirma esta ação?";
  promptUser;

  if [ "$MSE_GB_PROMPT_RESULT" != "1" ]; then
    setIMessage "" 1;
    setIMessage "Ação abortada pelo usuário.";
    alertUser;
  else

    local ISOK="1";
    local EXPECTED_VAR_NAME=(
      "DATABASE_TYPE" "DATABASE_HOST" "DATABASE_PORT"
      "DATABASE_NAME" "DATABASE_USER" "DATABASE_PASS"
    );

    local PROMPT_CONTEXT_MESSAGE="Banco de Dados:";
    local PROMPT_MESSAGE="Informe o ${PURPLE}[[VAR_LABEL]]${NONE}";
    local PROMPT_ERROR_REQUIRED="${PURPLE}[[VAR_LABEL]]${NONE} é obrigatório. Ação abortada."
    local PROMPT_REQUEST_VAR_LABEL=(
      "TYPE" "HOST" "PORT" "DATABASE_NAME" "USER" "PASSWORD"
    );
    local PROMPT_REQUEST_VAR_REQUIRED=(
      "1", "1" "1" "1" "1" "1"
    )
    local PROMPT_RESPONSE_VALUES=();


    local index;
    for index in "${!PROMPT_REQUEST_VAR_LABEL[@]}"; do

      if [ "${ISOK}" == "1" ]; then
        local pLabel="${PROMPT_REQUEST_VAR_LABEL[$index]}";
        local pMessage=$(sed 's/\[\[VAR_LABEL\]\]/'"${pLabel}"'/' <<< "$PROMPT_MESSAGE");
        local pRequired="${PROMPT_REQUEST_VAR_REQUIRED[$index]}";


        local pType="value"
        if [ "$pLabel" == "TYPE" ]; then
          pType="list"
          MSE_GB_PROMPT_LIST_OPTIONS_LABELS=("mysql" "postgresql")
          MSE_GB_PROMPT_LIST_OPTIONS_VALUES=("mysql" "postgresql")
        fi


        setIMessage "" 1;
        setIMessage "$PROMPT_CONTEXT_MESSAGE";
        setIMessage "$pMessage";
        promptUser "$pType"

        if [ "${MSE_GB_PROMPT_RESULT}" == "" ] && [ "$pRequired" == "1" ]; then
          pMessage=$(sed 's/\[\[VAR_LABEL\]\]/'"${pLabel}"'/' <<< "$PROMPT_ERROR_REQUIRED");

          ISOK="0";
          setIMessage "" 1;
          setIMessage "$pMessage";
          alertUser;
        else
          PROMPT_RESPONSE_VALUES+=("${MSE_GB_PROMPT_RESULT}");
        fi;
      fi;
    done


    if [ "${ISOK}" == "1" ]; then
      local key;
      local value;
      for index in "${!PROMPT_RESPONSE_VALUES[@]}"; do
        key="${EXPECTED_VAR_NAME[$index]}";
        value="${PROMPT_RESPONSE_VALUES[$index]}";

        mcfSetVariable "$key" "$value" "${TMP_ROOT_PATH}/.env";
      done
    fi;
  fi;
}










#
# Gerencia as ações de controle de tags do git para o projeto.
# gitTagManagement() {
#   GIT_ACTIVE_BRANCH=$(git branch --show-current)



#   #
#   # Identifica se a branch atual refere-se ao 'main'
#   if [ "${GIT_ACTIVE_BRANCH}" != "main" ]; then
#     setIMessage "" 1;
#     setIMessage "Alterne para a branch principal ${PURPLE}main${NONE}.";
#     setIMessage ":: git checkout main";
#     alertUser;
#   else
#     #
#     # Identifica se existem alterações não comitadas
#     if [ $(git status --porcelain | wc -l) -gt "0" ]; then
#       setIMessage "" 1;
#       setIMessage "Foram encontradas alterações não comitadas.";
#       setIMessage "Efetue o commit das alterações para prosseguir.";
#       setIMessage ":: git add .";
#       setIMessage ":: git commit -m \"message\"";
#       setIMessage ":: git push origin main";
#       alertUser;
#     else
#       GIT_ATUAL_TAG=$(git describe --abbrev=0 --tags)
#       TAG_SPLIT=(${GIT_ATUAL_TAG//-/ })
#       TAG_RAW_VERSION=(${TAG_SPLIT[0]//[!0-9.]/ })


#       VERSION_SPLIT=(${TAG_RAW_VERSION//\./ })

#       PROJECT_VERSION_MAJOR=${VERSION_SPLIT[0]}
#       PROJECT_VERSION_MINOR=${VERSION_SPLIT[1]}
#       PROJECT_VERSION_PATCH=${VERSION_SPLIT[2]}
#       PROJECT_VERSION_STABILITY=("-"${TAG_SPLIT[1]})

#       PROJECT_ATUAL_VERSION="${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}"

#       ISOK=1;


#       if [ "$1" == "remark" ]; then
#         git tag -d "${GIT_ATUAL_TAG}"
#         git push --delete origin "${GIT_ATUAL_TAG}"
#         git tag "${GIT_ATUAL_TAG}"
#         git push --tags origin
#       else
#         if [ "$1" == "version" ]; then
#           if [ "$2" == "patch" ]; then
#             PROJECT_VERSION_PATCH=$((PROJECT_VERSION_PATCH+1))
#           else
#             if [ "$2" == "minor" ]; then
#               PROJECT_VERSION_MINOR=$((PROJECT_VERSION_MINOR+1))
#               PROJECT_VERSION_PATCH=0
#             else
#               if [ "$2" == "major" ]; then
#                 PROJECT_VERSION_MAJOR=$((PROJECT_VERSION_MAJOR+1))
#                 PROJECT_VERSION_MINOR=0
#                 PROJECT_VERSION_PATCH=0
#               else
#                 ISOK=0
#               fi
#             fi
#           fi
#         elif [ "$1" == "stability" ]; then
#           if [ "$2" == "alpha" ] || [ "$2" == "beta" ] || [ "$2" == "cr" ] || [ "$2" == "r" ]; then
#             if [ "$2" == "r" ]; then
#               PROJECT_VERSION_STABILITY=""
#             else
#               PROJECT_VERSION_STABILITY="-$2"
#             fi
#           else
#             ISOK=0
#           fi
#         else
#           ISOK=0
#         fi



#         if [ "${ISOK}" == "0" ]; then
#           setIMessage "" 1;
#           setIMessage "Parametros incorretos: [ ${1}; ${2} ].";
#           setIMessage "Nenhuma ação foi realizada.";
#           alertUser;
#         else
#           USE_VERSION="${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}"
#           NEW_VERSION="v${USE_VERSION}${PROJECT_VERSION_STABILITY}"

#           #
#           # Verifica se é necessário atualizar o versionamento da documentação exportada
#           CONF="docs/conf.py"
#           if [ -f "${CONF}" ]; then
#             OLD_SHORT_VERSION="project_short_version = '.*'"
#             NEW_SHORT_VERSION="project_short_version = '${USE_VERSION}'"
#             sed -i "s/${OLD_SHORT_VERSION}/${NEW_SHORT_VERSION}/" "${CONF}"

#             OLD_FULL_VERSION="project_full_version = '.*'"
#             NEW_FULL_VERSION="project_full_version = '${NEW_VERSION}'"
#             sed -i "s/${OLD_FULL_VERSION}/${NEW_FULL_VERSION}/" "${CONF}"

#             if [ $(git status --porcelain | wc -l) -gt "0" ]; then
#               git add .
#               git commit -m "Atualizado para a versão ${NEW_VERSION}"
#               git push origin main
#             fi
#           fi

#           git tag ${NEW_VERSION}
#           git push --tags origin
#         fi
#       fi
#     fi
#   fi
# }





#
# Permite evocar uma função deste script a partir de um argumento passado ao chamá-lo.
$*
