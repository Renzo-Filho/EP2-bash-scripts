
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
# O parâmetro deverá ser o nome (ou caminho+nome) de um arquivo texto 
# contendo as URLs dos arquivos CSV a serem baixados para manipulaçã
NOME_ARQ=$1

DIR="./dados/"
CODIF="arquivocompleto.csv"


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

function pre_programa {

    # A gente chama essa função pra lidar com
    # as variações de input.

    # Tipo, printar erro se tiver algo de errado com o input, 
    # Baixar os arquivo se tiver input, os krl e tals.

    # A ideia é q dps de chamar essa função, a execução do programa 
    # é a mesma independentemente do input.

    echo "+++++++++++++++++++++++++++++++++++++++
Este programa mostra estatísticas do
Serviço 156 da Prefeitura de São Paulo
+++++++++++++++++++++++++++++++++++++++"

    # Se não passaram nenhum argumento e não tem dados baixados
    if [ -z $NOME_ARQ ] && [ ! -e $DIR ]; then
        echo "ERRO: Não há dados baixados.
Para baixar os dados antes de gerar as estatísticas, use:
    ./ep2_servico156.sh <nome do arquivo com URLs de dados do Serviço 156>"
    fi

    # Se passaram argumentos, mas o arquivo passado não existe
    if [ ! -z $NOME_ARQ ] && [ ! -e $NOME_ARQ ]; then
        echo "ERRO: O arquivo $NOME_ARQ não existe."
    fi

    # Se passaram argumentos e o arquivo existe
    if [ ! -z $NOME_ARQ ] && [ -e $NOME_ARQ ]; then

        mkdir -p $DIR # Cria o diretório

        # Lê o arquivo linha por linha e baixa o arquivo
        while IFS= read -r linha; do
            baixa_arquivo $linha
        done < $NOME_ARQ

    fi

}

pre_programa

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