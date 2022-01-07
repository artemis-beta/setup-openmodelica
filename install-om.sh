#!/usr/bin/bash
set -e

echo "::group::Setup"

echo "::notice title=Update Sources List"
echo "deb https://build.openmodelica.org/apt `lsb_release -cs` release" | sudo tee /etc/apt/sources.list.d/openmodelica.list

echo "::notice title=Add GPG Key"
wget -q http://build.openmodelica.org/apt/openmodelica.asc -O- | sudo apt-key add -

echo "::notice title=Update Package List"
sudo apt update

echo "::endgroup::"

echo "::group::Install OpenModelica Compiler"
sudo apt install omc -y
echo "::endgroup::"

if [ "${INSTALL_OMC_CPP_LIBS}" != "false" ]; then
    sudo apt install -y libomccpp
fi

if [ "$#" -ne 0 ]; then
    echo "::group::Install Modelica Libraries"
    for library in "$@"
    do
        if [[ "$library" == *"@"* ]]; then
            LIBRARY_NAME=$(echo ${library} | cut -d '@' -f 1)
            LIBRARY_VERSION=$(echo ${library} | cut -d '@' -f 2)
            sudo apt install -y omlib-$LIBRARY_NAME-$LIBRARY_VERSION
        else
            LIBRARY_VER=$(sudo apt-cache search "omlib-${library}" | cut -d ' ' -f 1 | grep -oE "^omlib-${library}-([[:digit:]]|\.)+$")
            LIBRARY_NOVER=$(sudo apt-cache search "omlib-${library}" | cut -d ' ' -f 1 | grep -oE "^omlib-${library}$")
            if [ -n "$LIBRARY_VER" ]; then
                echo "::notice title=Install::Installing package '${LIBRARY_VER}'"
                sudo apt install -y $LIBRARY_VER
            elif [ -n "$LIBRARY_NOVER" ]; then
                echo "::notice title=Install::Installing package '${LIBRARY_NOVER}'"
                sudo apt install -y $LIBRART_NOVER
            else
                echo "::error title=Unknown Library::Cannot find installation candidate for '${library}'"
                exit 1
            fi
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
    echo "::group::Compile Modelica Model"
    OMC_ARGS="-s ${MODEL_SOURCE_PATH}"

    if [ "${BUILD_DEBUG}" != "false" ]; then
        OMC_ARGS="${OMC_ARGS} -d"
    fi

    if [ "${MODEL_NAME}" != "false" ]; then
        OMC_ARGS="${OMC_ARGS} +i=${MODEL_NAME}"
    fi

    echo "::notice title=Model Run::Creating model sources and Makefile"
    omc $OMC_ARGS Modelica

    if [ -z "$(ls *.makefile | head -n 1)" ]; then
        echo "::error title=Configuration Failure::Failed to create GNU Makefile"
        exit 1
    fi

    MAKEFILE=$(ls *.makefile | head -n 1)

    echo "::notice title=Model Run::Compiling Model"
    make -f $MAKEFILE
    echo "::endgroup::"

    echo "::group::Run Model"
    echo "::notice title=Model Run::Executing binary $BINARY_FILE"
    BINARY_FILE=$(ls -tr | tail -n 1)
    ./$BINARY_FILE
    exit 0
fi
