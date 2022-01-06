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
    sudo apt install -y libomcpp
fi

if [ $# -neq 0 ]; then
    echo "::group::Install Modelica Libraries"
    for library in "$@"
    do
        if [[ "$library" == *"@"* ]]; then
            LIBRARY_NAME=$(echo ${library} | cut -d '@' -f 1)
            LIBRARY_VERSION=$(echo ${library} | cut -d '@' -f 2)
            sudo apt install -y omlib-$LIBRARY_NAME-$LIBRARY_VERSION
        else
            LIBRARY_VER=$(sudo apt-cache search "omlib-${library}" | cut -d ' ' -f 1 | grep -oE "^omlib-${library}-([[:digit:]]|\.)+$")
            LIBRART_NOVER=$(sudo apt-cache search "omlib-${library}" | cut -d ' ' -f 1 | grep -oE "^omlib-${library}$")
            if [ -n "$LIBRARY_VER" ]; then
                echo "::error title=Install::Installing package '${LIBRARY_VER}'"
                sudo apt install -y $LIBRARY_VER
            elif [ -n "$LIBRARY_NOVER" ]; then
                echo "::error title=Install::Installing package '${LIBRARY_NOVER}'"
                sudo apt install -y $LIBRART_NOVER
            else
                echo "::error title=Unknown Library::Cannot find installation candidate for '${library}'"
            fi
        fi
    done
fi
