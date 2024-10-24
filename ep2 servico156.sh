
##################################################################
# MAC0216 - Técnicas de Programação I (2024)
# EP2 - Programação em Bash
#
# Nome do(a) aluno(a) 1: Renzo Real Machado Filho
# NUSP 1: 15486907
#
# Nome do(a) aluno(a) 2: Gabriel Freire Ushijima
# NUSP 2: 15453282
##################################################################

#!/bin/bash

# Só funciona em sistemas Unix, fds windows

# Salva a 1° entrada da linha de comando
# O parâmetro deverá ser o nome (ou caminho+nome) de um arquivo texto contendo as URLs dos arquivos CSV a serem baixados para manipulaçã
NOME_ARQ=$1

DIR="./dados/"
CODIF="arquivocompleto.csv"

# cria o diretório "./dados/"
mkdir -p $DIR

VETOR_URL=()

function le_input {

    # Lê o arquivo linha por linha e adiciona a VETOR_URL
    while IFS= read -r linha; do
        VETOR_URL+=("$linha")
    done < "url.txt"

}

function baixa_arquivo {
    
    # $1 -> url do arquivo a ser baixado.
    # Converte para UTF-8 e salva com o nome final do url.

    local nome_arquivo=$(basename $1) # nome do arquivo baixado e.g., "arquivofinal2tri2024.csv"
    local path_output="$DIR/$nome_arquivo" # path do output

    # Se o arquivo já existe, ent retorna cedo
    if [ -e $path_output ]; then
        return
    fi

    wget -nv $1 -P $DIR # baixa o arquivo
    iconv -f ISO-8859-1 -t UTF8 "$path_output" > "$DIR/temp.txt" # converte para UTF-8 e salva em um arquivo temporário
    mv "$DIR/temp.txt" "$DIR/$nome_arquivo" # renomeia do nome temporário para o nome final
}

function baixa_arquivos {
    
    # $@ -> urls de arquivos a serem baixados
    # Tem q passar os urls como argumentos separados, ent vc faz "${vetor[@]}" pra passar os args.
    # Usa a função `baixa_arquivo`

    for url in "$@"; do
        baixa_arquivo $url
    done
}


le_input
baixa_arquivos ${VETOR_URL[@]}

# PROBLEMAS !!!
# Os arquivo estão sendo baixados de forma muito lenta, MUITO LENTA!


<<COMENT
selecionar_arquivo
Mostra ao usuário uma listagem dos arquivos CSV disponíveis no diretório de dados e
permite a seleção de um arquivo para manipular.
Todas as demais operações são aplicadas sobre o último arquivo selecionado pelo
usuário. No início da execução, considere que o arquivo selecionado é o CSV completo
(“arquivocompleto.csv”).


function selecionar_arquivo {

}
COMENT