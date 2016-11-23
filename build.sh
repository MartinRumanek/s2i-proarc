docker build -t proarc-builder .
s2i build https://github.com/proarc/proarc.git proarc-builder moravianlibrary/proarc -r master


