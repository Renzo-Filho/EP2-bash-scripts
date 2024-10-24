##################################################################
# MAC0216 - Técnicas de Programação I (2024)
# EP2 - Programação em Bash
#
# Nome do(a) aluno(a) 1: Renzo Real Machado Filho
# NUSP 1: 15486907
#
# Nome do(a) aluno(a) 2:
# NUSP 2:
##################################################################

#!/bin/bash


# Salva a 1° entrada da linha de comando
# O parâmetro deverá ser o nome (ou caminho+nome) de um arquivo texto contendo as URLs dos arquivos CSV a serem baixados para manipulaçã
NOME_ARQ=$1 

DIR="./dados/"
CODIF="arquivocompleto.csv"

# cria o diretório "./dados/"
mkdir -p $DIR

VETOR_URL=()

# Lê o arquivo linha por linha e adiciona a VETOR_URL
while IFS= read -r linha
    do
        VETOR_URL+=("$linha")
    done < "url.txt"

for url in "${VETOR_URL[@]}"
    do
        # baixa os arquivos CSV por meio das URLs recebidas e grava-os num diretório especialmente criado pelo programa para armazenar os dados
        wget -nv $url -P $DIR

        # converte a codificação dos arquivos CSV baixados de ISO-8859-1 para UTF8 (para não haver problemas na exibição dos caracteres acentuados)
        iconv -f ISO-8859-1 -t UTF8 "$DIR$url" -o "$DIR$CODIF" 

    done

# PROBLEMAS !!!
# Não está convertendo para UTF8 (aparentemente)
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