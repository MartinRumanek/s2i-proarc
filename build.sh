docker build -t proarc-builder .
s2i build https://github.com/moravianlibrary/proarc.git proarc-builder moravianlibrary/proarc

