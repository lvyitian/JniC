#!/bin/sh

# Program by Adrian Gjerstad of CodeDojo.
# Copyright (c) 2018 Adrian Gjerstad. All right's reserved.
# This project is licensed under the GNU General Public License 3.0.
# If you have any questions, go to https://github.com/CodeDojoOfficial/JniC/issues/new

# FUNCTION
#
# Name: jnic
# Argument Count: 1..*
# Description: This method will take the names of your classes and compile it so that
# all you have to do is run it. This method has something special in it, however. In this
# method, it will generate native method source files, and you get to define their
# functionality!
#
# Version: 1.0.0
function jnic() {
  ext=""

  echo "Input: $@"

  echo "What would you like the name of this library to be? Don't include the lib prefix or .so suffix."

  read name

  echo "Ok. The resulting file name will be lib${name}.so and your static block should contain \`System.loadLibrary(\"${name}\");'."

  sleep 3
  
  echo "Starting initialization progress..."
  
  echo "Compiling code..."

  comp=""

  for value in $@; do
    comp="$comp $value.java"
  done
  
  javac -h . $comp
  
  ext="$?"

  if [[ "$ext" -ne "0" ]]; then
    echo "Something went wrong while trying to create the class files. Exit code: $ext."
    return $ext
  fi
  
  echo "Code compilation successful."
  
  sleep 2

  echo "Generating header files..."

  javah $@
  
  ext="$?"
  
  if [[ "$ext" -ne "0" ]]; then
    echo "Something went wrong while trying to create the header files. Exit code: $ext."
    return $ext
  fi

  echo "Header code generation successful."

  echo "Generating implementation C++ files..."

  for value in $@; do
    if [[ -f ${value}Impl.cpp ]]; then
      echo "File ${value}Impl.cpp already exists. Overwrite? (y/n)"
      read ans
      if [ "$ans" != "y" ] && [ "$ans" = "n" ]; then
        echo "Ok. ${value}Impl.cpp is staying as is."
        sleep 1
        continue
      elif [ "$ans" != "y" ] && [ "$ans" != "n" ]; then
        echo "That answer was not understood. ${value}Impl.cpp will not be overwritten."
        sleep 1
        continue # Escape overwriting
      else
        rm ${value}Impl.cpp
      fi
    fi
    touch ${value}Impl.cpp
    echo "/* Class: ${value} */" >> ${value}Impl.cpp
    echo "#include <jni.h>" >> ${value}Impl.cpp
    echo "#include <stdio.h>" >> ${value}Impl.cpp
    echo "#include \"${value}.h\"" >> ${value}Impl.cpp
    echo "" >> ${value}Impl.cpp
    echo "// This file was generated by JniC. An open source tool for java developers curious about native methods." >> ${value}Impl.cpp
    echo "// Enter your methods below." >> ${value}Impl.cpp
    echo "" >> ${value}Impl.cpp
    echo "" >> ${value}Impl.cpp
    sleep 1
  done

  echo "C++ implementation file generation successful."
  
  sleep 1

  echo "Launching VI Improved editor for each file. Write and quit using :wq in normal mode (Get to normal mode by using ESC), and the writing will continue to the last file."

  sleep 5

  for value in $@; do
    vim ${value}Impl.cpp
  done

  echo "Editing complete."

  echo "Compiling C++ code..."
  
  cpp=""

  for value in $@; do
    cpp="$cpp ${value}Impl.cpp"
  done

  g++ -fPIC -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/darwin" -shared -o lib${name}.so${cpp}
  
  ext="$?"

  if [[ "$ext" -ne "0" ]]; then
    echo "Something went wrong when trying to compile C++ code. Exit code: $ext"
    echo "hint: Try checking if your JAVA_HOME environment variable is pointed correctly."
    return $ext
  fi

  echo "C++ compilation successful!"

  export LD_LIBRARY_PATH="."

  echo "Be careful. The LD_LIBRARY_PATH environment variable is now loaded. If you wish to add on, just enter the following:"
  echo "export LD_LIBRARY_PATH=\"yourdir:\$LD_LIBRARY_PATH\""

  echo "Ok! You're done! Just enter \`java <MyClass>', and you will run the native code along side your java code!"
}
