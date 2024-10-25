
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
# contendo as URLs dos arquivos CSV a serem baixados para manipulação
NOME_ARQ=$1

DIR="./dados"
CODIF="arquivocompleto.csv"

MENSAGEM_INICIAL="+++++++++++++++++++++++++++++++++++++++\nEste programa mostra estatísticas do\nServiço 156 da Prefeitura de São Paulo\n+++++++++++++++++++++++++++++++++++++++"
MENSAGEM_FINAL="Fim do programa\n+++++++++++++++++++++++++++++++++++++++"
MENSAGEM_ERRO="ERRO: Não há dados baixados.\nPara baixar os dados antes de gerar as estatísticas, use:\n./ep2_servico156.sh <nome do arquivo com URLs de dados do Serviço 156>"

MENSAGEM_OPERACOES="1) selecionar_arquivo\n2) adicionar_filtro_coluna\n3) limpar_filtros_colunas\n4) mostrar_duracao_media_reclamação\n5) mostrar_ranking_reclamacoes\n6) mostrar_reclamacoes\n7) sair"

# Ent, o bash é uma bosta e não tem valor de retorno nas funções.
# Isso é paia pra krl, mas eu ainda assim quero usar funções com valor de retorno.
# Por esse motivo, vou usar essa variável global como uma forma de retornar valores.
# É tipo o `rax` em assembly `x86-64`.
retorno=""

arquivo_atual="$DIR/$CODIF"

function formata_tempo {

    # $1 -> Tempo em segundos
    # Retorna o tempo formatado em horas, minutos e segundos
    # Fica tipo 1h 30m 10s
    # Se o tempo for menos que 1 hora, ou 1 minuto
    # ele formata certinho ainda assim, fica 1m 3s ou 10s.

    local resultado=""

    local segundos=$(( $1 % 60 ))
    local minutos=$(( ($1 / 60) % 60 ))
    local horas=$(( ($1 / 3600) % 60 ))

    if [ $minutos -ne 0 ]; then

        if [ $horas -ne 0 ]; then
            resultado="${horas}h "
        fi

        resultado="${resultado}${minutos}m "
    fi

    retorno="${resultado}${segundos}s"
}

function baixa_arquivos {

    # Le o arquivo de entrada e salva os urls em `urls`
    IFS=$'\n' read -d '' -r -a urls < $NOME_ARQ

    # Cria o diretório e baixa os arquivos no
    # arquivo passado como argumento
    mkdir -p $DIR # Cria o diretório

    # Salva o tempo de início de baixar os arquivos em segundos
    local tempo_inicio=$(date +%s)

    # Tempo gasto baixando os arquivos em segundos.
    # Isso n conta o tempo pra converter os arquivos.
    # A diferença é de segundos, mas acho q tem q ter aq.
    local tempo_pra_baixar=0

    # Total em bytes baixados
    local total_baixado=0

    # numero de arquivos baixados
    local num_arquivos=0

    # Printa a data inicial
    echo $(date '+%Y-%m-%d %H:%M:%S')

    # Lê o arquivo linha por linha e baixa o arquivo
    for url in ${urls[@]}; do

        local nome_arquivo=$(basename $url) # nome do arquivo final e.g., "arquivofinal2tri2024.csv"
        local path_output="$DIR/$nome_arquivo" # path do output, arquivo temporário, será convertido dps

        # Se o arquivo já existe, ent n faz nada
        # Isso é mais pra ajudar a testar, n deveria afetar o usuário.
        # Se pah eu removo dps.
        if [ -e "$DIR/$nome_arquivo" ]; then 
            continue
        fi

        local tempo_pra_baixar_inicio=$(date +%s)
        wget -nv -O $path_output $url # baixa o arquivo
        local tempo_pra_baixar_fim=$(date +%s)

        local tempo_pra_baixar=$(( tempo_pra_baixar + tempo_pra_baixar_fim - tempo_pra_baixar_inicio ))

        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            local tamanho_arquivo=$(stat -c%s "$path_output") # Funciona em Linux
        else
            local tamanho_arquivo=$(stat -f%z $path_output) # Funciona em macOS
        fi

        local num_arquivos=$((num_arquivos + 1))
        local total_baixado=$(( total_baixado + tamanho_arquivo ))

    done

    # Salva os paths dos arquivos baixados
    local nomes=$(
        for url in ${urls[@]}; do
            echo "$DIR/$(basename $url)"
        done
    )

    # Cria um único `.csv` com a info dos outros baixados
    # se foi baixado mais de um arquivo novo
    if [ $num_arquivos -ne 0 ]; then
        awk "NR==1||FNR>1" ${nomes[0]} > "$DIR/$CODIF"
    fi

    # Salva o tempo final de baixar e tratar os arquivos
    local tempo_fim=$(date +%s)

    # Printa a data final
    echo "FINALIZADO $(date '+%Y-%m-%d %H:%M:%S')"

    # tempo decorrido total em segundos
    local tempo_decorrido=$(( tempo_fim - tempo_inicio ))

    formata_tempo $tempo_decorrido
    echo "Tempo total decorrido: ${retorno}"

    formata_tempo $tempo_pra_baixar

    local total_baixado=$(( total_baixado / 1048576 )) # Converte para MB

    # Calcula a velocidade de download
    # O `+0.01` é pra n dar erro de divisão por `0` em certos casos.
    local velocidade_download=$(bc <<< "scale=2; ${total_baixado}/(${tempo_pra_baixar} + 0.001)")

    echo "Baixados: ${num_arquivos} arquivos, ${total_baixado}M em ${retorno} (${velocidade_download} MB/s)"
}

function pre_programa {

    # A gente chama essa função pra lidar com
    # as variações de input.

    # Tipo, printar erro se tiver algo de errado com o input, 
    # Baixar os arquivo se tiver input, os krl e tals.

    # A ideia é q dps de chamar essa função, a execução do programa 
    # é a mesma independentemente do input.

    # Printa a mensagem inicial
    echo -e $MENSAGEM_INICIAL

    # Se não passaram nenhum argumento
    if [ -z $NOME_ARQ ]; then

        # Se não tem dados baixados
        if [ ! -e $DIR ]; then
            echo -e $MENSAGEM_ERRO
            exit 1
        fi

        return
    fi

    # Se passaram argumentos, mas o arquivo não existe
    if [ ! -e $NOME_ARQ ]; then
        echo -e "ERRO: O arquivo $NOME_ARQ não existe."
        exit 1
    fi

    # Essa parte só é executada se 
    # tem argumentos e o arquivo existe.

    baixa_arquivos
}

function selecionar_arquivo {

    echo "Escolha uma opção de arquivo:"
        
    local arquivos_dados=("$DIR"/*) # vetor com todos os arquivos em "./dados/"
    local i=1 # contador

    # Printa as opções de arquivos na pasta "./dados/" 
    for arquivo in "${arquivos_dados[@]}"
        do
        nome_arquivo=$(basename "$arquivo")
        echo "$i) $nome_arquivo"
        ((i++))
        done
}

function menu_principal {
    
    echo "Escolha uma opção de operação:"
    echo -e $MENSAGEM_OPERACOES
    
    read -p "" opcao
    echo "" # Acho q tem q ter uma linha entre o input e o resto, pelo menos parece pelo pdf dela

    if [[ "$opcao" == "7" ]]; then
        echo -e $MENSAGEM_FINAL
        exit 0

    # Obviamente temporário ...
    elif [[ "$opcao" == "1" ]]; then
        selecionar_arquivo        
    fi
}


# Inicializa o programa, lidando com o input.
pre_programa

# Exibe as opções e funcionalidades
menu_principal


# PROBLEMAS !!!
# Os arquivo estão sendo baixados de forma muito lenta, MUITO LENTA!
# Ta lento pra porra mesmo, pqp, ta uns 3 min por arquivo, 0.5MB/s
# Ta rapidão agora, ta em 8.89MB/s, o site do governo tava zuado


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