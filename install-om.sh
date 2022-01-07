#!/usr/bin/bash
set -e

echo "::group::Setup"

echo "::notice title=Update Sources List"
echo "deb https://build.openmodelica.org/apt `lsb_release -cs` release" | sudo tee /etc/apt/sources.list.d/openmodelica.list

echo "::notice title=Add GPG Key"
APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 wget -q http://build.openmodelica.org/apt/openmodelica.asc -O- | sudo apt-key add -

echo "::notice title=Update Package List"
sudo apt update

echo "::endgroup::"

echo "::group::Install OpenModelica Compiler"
sudo apt install omc -y
echo "::endgroup::"

if [ "${INSTALL_OMC_CPP_LIBS}" != "false" ]; then
    sudo apt install -y libomccpp
fi

INSTALL_SCRIPT=$PWD/installLibraries.mos
LIBRARIES=""

if [ "$#" -ne 0 ]; then
    echo "::group::Install Modelica Libraries"
    for library in "$@"
    do
        echo "::notice title=Install::Installing package '$library'"
        if [[ "$library" == *"@"* ]]; then
            LIBRARY_NAME=$(echo ${library} | cut -d '@' -f 1)
            LIBRARY_VERSION=$(echo ${library} | cut -d '@' -f 2)
            LIBRARIES="$LIBRARIES $LIBRARY_NAME"
            OMSHELL_CMD="installPackage(${LIBRARY_NAME}, \"$LIBRARY_VERSION\")" > $INSTALL_SCRIPT
        else
            OMSHELL_CMD="installPackage(${LIBRARY_NAME})" > $INSTALL_SCRIPT
        fi
        echo $OMSHELL_CMD > $INSTALL_SCRIPT
        INSTALL_SUCCESS=$(omc $INSTALL_SCRIPT)
        if [ "$INSTALL_SUCCESS" != "true" ]; then
            echo "::error title=Install Library Failure::OMShell command '$OMSHELL_CMD' failed"
            exit 1
        fi
    done
    echo "::endgroup::"
fi

if [ "${MODEL_SOURCE_PATH}" == "false" ]; then
    if [ -n "$(ls *.mo | head -n 1)" ]; then
        MODEL_SOURCE_PATH=$(ls *.mo | head -n 1)
    fi
fi

if [ -n "${MODEL_SOURCE_PATH}" ]; then
    echo "::group::Compile & Run Modelica Model"
    MODEL_BUILD_SCRIPT=$PWD/modelBuild.mos

    echo "::notice title=Model Run::Creating model sources and Makefile"
    echo "loadFile(\"${MODEL_SOURCE_PATH}\");" > $MODEL_BUILD_SCRIPT
    
    for library in "$LIBRARIES"
    do
        echo "loadModel($library);" >> $MODEL_BUILD_SCRIPT
    done

    if [ "${MODEL_NAME}" == "false" ]; then
        MODEL_NAME=$(cat ${MODEL_SOURCE_PATH} | grep -E "model" | head -n 1 | cut -d ' ' -f 2)
    fi

    echo "simulate(${MODEL_NAME});" >> $MODEL_BUILD_SCRIPT
    echo "printErrorString();" >> $MODEL_BUILD_SCRIPT

    echo "::notice title=Model Run::Created script '$MODEL_BUILD_SCRIPT':"
    cat $MODEL_BUILD_SCRIPT

    echo "::notice title=Model Run::Compiling Model '${MODEL_NAME}' with OMC and Running"
    omc $MODEL_BUILD_SCRIPT
    echo "::endgroup::"
fi

echo "::group::OMC Export"
echo "::notice title=Updating PATH::Adding 'omc' to \$PATH in \$GITHUB_ENV"
echo "PATH=\"$PATH\"" >> $GITHUB_ENV
