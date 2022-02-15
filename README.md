# OpenModelica Install & Run Action
Downloads and installs the [OpenModelica](https://openmodelica.org/) compiler along with any specified Modelica libraries. Can execute existing `.mo` model files or a Modelica script `.mos` file. The `omc` location is added to `PATH` making the executable accessible to future actions.

## Using
```yaml
jobs:
    example:
    runs-on: ubuntu-latest
    steps:
    -   name: Test Modelica Model
        uses: artemis-beta/setup-modelica@v2
        with:
            libraries: |
                PowerGrids
                SystemDynamics@2.1.1
            cpp-runtime-library: install
            model-source-path: testing/SineCurrent.mo
            model-name: SineCurrentModel
            msl-version: '3.2.3'
            script: |
                loadLibrary(Modelica);
                simulate(Modelica.Fluid.Examples.HeatSystem);
                printErrorString();
```

## Options
|**Option**|**Description**|**Default**|
|---|---|---|
|`libraries`|List of Modelica libraries to install (each on new line). Spelling and capitalisation must be exact, uses the `installPackage` OM scripting function. Exact versions can be specified using `@x.y.z` version suffix. |None|
|`cpp-runtime-library`|Install the C++ runtime|false|
|`model-source-path`|Path to a model source `.mo` file to compile and run.|None|
|`model-name`|Name of model to run.|Result of grepping for `model` in script.|
|`msl-version`|Version of Modelica Standard Library.|Defaults to latest stable version.|
|`script-path`|A Modelica script (`.mos`) file to execute.|None|
|`script`|OMShell script to execute.|None|
