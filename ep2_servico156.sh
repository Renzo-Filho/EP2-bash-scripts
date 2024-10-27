
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

NOMES_OPERACOES=(
    "selecionar_arquivo"
    "adicionar_filtro_coluna"
    "limpar_filtros_colunas"
    "mostrar_duracao_media_reclamação"
    "mostrar_ranking_reclamacoes"
    "mostrar_reclamacoes"
    "sair"
)

arquivo_atual="$DIR/$CODIF"
arquivo_filtrado="linhas_validas.csv"

# Array de filtros, mapeia colunas para o respectivo filtro
# filtros[0] -> filtro da data, filtros[1] -> filtro do canal, ...
filtros=()

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

    echo "${resultado}${segundos}s"
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

    tempo=$(formata_tempo $tempo_decorrido)
    echo "Tempo total decorrido: ${tempo}"

    tempo=$(formata_tempo $tempo_pra_baixar)

    local total_baixado=$(( total_baixado / 1048576 )) # Converte para MB

    # Calcula a velocidade de download
    # O `+0.01` é pra n dar erro de divisão por `0` em certos casos.
    local velocidade_download=$(bc <<< "scale=2; ${total_baixado}/(${tempo_pra_baixar} + 0.001)")

    echo "Baixados: ${num_arquivos} arquivos, ${total_baixado}M em ${tempo} (${velocidade_download} MB/s)"
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

function enumera {

    # Recebe uma quantidade qualquer de argumentos, 
    # printa eles enumerando a partir de 1, separados em linhas.
    # Fica tipo: "1) $1\n 2) $2\n ..."

    local index=1

    for item in "$@"; do
        echo "$index) $item"
        ((index++))
    done

}

function junta_strings {

    # Junta strings usando um delimitador especificado
    # $1 -> delimitador
    # $2, ... -> strings
    # ex: junta_strings "," "a" "b" -> "a,b"

    local delimitador=${1-} 
    local partes=${2-}

    if shift 2; then
        printf %s "$partes" "${@/#/$delimitador}"
    fi
}

function filtra_linhas {

    # Salva em um arquivo as linhas filtradas de acordo com os filtros

    # Array com colunas, usa da primeira linha do arquivo
    IFS=';'; local colunas=($(head -n 1 $arquivo_atual)) 

    local assertions=("NR>1")

    for index in ${!filtros[@]}; do
        assertions+=("\$$((index + 1)) == \"${filtros[$index]}\"")
    done

    string=$(junta_strings " && " "${assertions[@]}")
    string="$string {print}"

    awk -F';' $string $arquivo_atual > $arquivo_filtrado

    # awk -F',' 'NR>1 && $2 == "Active" && $3 == "Completed" {print}' example.csv
    # awk -F';' 'NR>1 && $2 == "Active" && $3 == "Completed" {count++} END {print count}' $arquivo_atual

}

function mostra_info {

    local nome_arquivo=$(basename $arquivo_atual)

    echo "+++ Arquivo atual: $nome_arquivo"

    # Esse if printa os filtros caso existam
    # Ele também separa os filtros com ` | `
    # Verifica se existem filtros
    if [ ${#filtros[@]} -ne 0 ]; then
        
        echo "+++ Filtros atuais:"

        # Array com colunas, usa da primeira linha do arquivo
        IFS=';'; local colunas=($(head -n 1 $arquivo_atual)) 

        local pares=()
        
        for index in ${!filtros[@]}; do
            pares+=("${colunas[$index]} = ${filtros[$index]}")
        done
        
        junta_strings " | " "${pares[@]}"
        echo ""

    fi

    filtra_linhas

    local num_reclamacoes=$(wc -l < $arquivo_filtrado | tr -d ' ')

    # Tem q calcular essa porra ainda
    echo "+++ Número de reclamações: $num_reclamacoes"

    echo "+++++++++++++++++++++++++++++++++++++++"
    echo "" # Acho q tem q ter essa '\n' tbm
}

function selecionar_arquivo {

    echo "Escolha uma opção de arquivo:"
        
    local arquivos_paths=("$DIR"/*) # vetor com todos os paths dos arquivos em "./dados/"
    local arquivos_nomes=($(basename -a ${arquivos_paths[@]})) # vetor com os nomes dos arquivos em "./dados/"

    enumera "${arquivos_nomes[@]}"

    read -p "" escolha

    local novo_arquivo=${arquivos_nomes[((escolha - 1))]}
    arquivo_atual="$DIR/$novo_arquivo"

    mostra_info
}

function adicionar_filtro_coluna {

    echo "Escolha uma opção de coluna para o filtro:"

    IFS=';'; 
    local colunas=($(head -n 1 $arquivo_atual)) # Array com colunas, usa da primeira linha do arquivo

    enumera ${colunas[@]} # Printa as opções

    read -p "" coluna # Lê a escolha
    echo "" # Linha de espaço

    local valores=()

    # Pega os valores da coluna especificada, ordena e descarta valores repetidos
    # Então tranforma em um array
    while IFS= read -r line; do
        valores+=("$line")
    done < <(head -n 1000 $arquivo_atual | tail -n +2 | awk -F "\"*;\"*" "{print \$$coluna}" | sort | uniq) 
    # done < <(head -n 100 $arquivo_atual | tail -n +2 | awk -F "\"*;\"*" "{print \$$coluna}" | sort | uniq) 
    # done < <(tail -n +2 $arquivo_atual | awk -F "\"*;\"*" "{print \$$coluna}" | sort | uniq) 

    echo "Escolha uma opção de valor para Status da solicitação:"
    enumera ${valores[@]}

    read -p "" valor
    echo ""

    local valor_coluna=${colunas[(( coluna - 1 ))]}
    local filtro=${valores[((valor - 1))]}

    filtros[((coluna - 1))]=$filtro

    echo "+++ Adicionado filtro: $valor_coluna = $filtro"
    mostra_info

}

function limpar_filtros_colunas {

    filtros=()

    echo "+++ Filtros removidos"
    mostra_info
}

function mostrar_duracao_media_reclamacao {

<<COMENT
    Não funcional (esboço)... Ainda não tenho ideia de como consertar
COMENT

    # Mostra o tempo de duração médio de uma reclamação em dias, calculado a partir da
    # diferença entre os valores das colunas "Data do Parecer" e "Data de abertura" das linhas de
    # reclamações selecionadas no momento.

    local arquivo="$arquivo_atual" # Caminho para o arquivo de reclamações
    local total_dias=0             # Soma total de dias de duração
    local contagem=0               # Contador de linhas válidas

    # Itera sobre cada linha das reclamações selecionadas
    while IFS=';' read -r col1 _ _ _ _ _ _ _ _ _ _ _ col13 _; do
        # Verifica se ambas as colunas de datas estão presentes
        if [[ -n "$col1" && -n "$col13" ]]; then
            # Converte as datas para segundos desde "Epoch" para realizar cálculo de dias
            data_inicial=$(date -d "$col1" +%s)
            data_final=$(date -d "$col13" +%s)

            # Verifica se a conversão foi bem-sucedida
            if [[ -n "$data_inicial" && -n "$data_final" ]]; then
                # Calcula a diferença em dias
                diferenca_dias=$(( (data_final - data_inicial) / 86400 ))

                # Soma a diferença de dias ao total e incrementa o contador
                total_dias=$((total_dias + diferenca_dias))
                ((contagem++))
            fi
        fi
    done < <(tail -n +2 "$arquivo") # Pula o cabeçalho do arquivo

    # Calcula a média, se houver reclamações válidas
    if (( contagem > 0 )); then
        media=$((total_dias / contagem))
        echo "Duração média das reclamações: $media dias"
    else
        echo "Nenhuma reclamação válida encontrada para cálculo."
    fi
    
}

function mostrar_ranking_reclamacoes {
<<COMENT
    Mostra ao usuário uma listagem dos nomes das colunas do arquivo selecionado e
    permite a seleção de uma coluna para análise. Depois de selecionada a coluna pelo usuário,
    para cada valor distinto existente na coluna o programa deverá obter o número de linhas de
    reclamações que contêm aquele valor dentro delas (em qualquer posição). A partir dessa
    contagem, ele deverá exibir até 5 valores com as maiores contagens (ou seja, os valores
    campeões de reclamações).
COMENT

    IFS=';'; 
    local colunas=($(head -n 1 $arquivo_atual)) # Array com colunas, usa da primeira linha do arquivo

    enumera ${colunas[@]} # Printa as opções
    echo ""

    read -p "" coluna # Lê a escolha
    echo "" # Linha de espaço

    local valores=()

    # Pega os valores da coluna especificada, ordena e descarta valores repetidos
    # Então tranforma em um array
    while IFS= read -r line; do
        valores+=("$line")
    done < <(head -n 1000 $arquivo_atual | tail -n +2 | awk -F "\"*;\"*" "{print \$$coluna}") 

    
    echo "+++ ${colunas[coluna-1]} com mais reclamações:"

    #for item in "${valores[@]}"; do
    #echo "$item"
    #done | sort | uniq -c | sort -nr | head -n 5 | awk '{print $1, $2}'
    
    printf "%s\n" "${valores[@]}" | sort | uniq -c | sort -nr | head -n 5 | awk '{print $1, $2}'
    
    echo "+++++++++++++++++++++++++++++++++++++++"

    # !!!!!!!!!!!!!!!!!!!!!!!!!
    # Tá printando um número antes do filtro, não sei se é a quantidade de elementos da coluna ou outra coisa
}

function mostrar_reclamacoes {

    cat $arquivo_filtrado
    mostra_info

}

function loop_principal {

    local opcao="0"

    while [ $opcao != "7" ]; do

        echo "Escolha uma opção de operação:"
        enumera "${NOMES_OPERACOES[@]}"

        read -p "" opcao # Lê a escolha
        echo "" # Acho q tem q ter uma linha entre o input e o resto, pelo menos parece pelo pdf dela

        if [ $opcao == "1" ]; then
            selecionar_arquivo        
        elif [ $opcao == "2" ]; then
            adicionar_filtro_coluna
        elif [ $opcao == "3" ]; then
            limpar_filtros_colunas
        elif [ $opcao == "4" ]; then
            mostrar_duracao_media_reclamacao
        elif [ $opcao == "5" ]; then
            mostrar_ranking_reclamacoes
        elif [ $opcao == "6" ]; then
            mostrar_reclamacoes    
        fi

    done

    rm $arquivo_filtrado

    echo -e $MENSAGEM_FINAL
    exit 0
}


# Inicializa o programa, lidando com o input.
pre_programa

# Exibe as opções e funcionalidades
loop_principal


# PROBLEMAS !!!
# Os arquivo estão sendo baixados de forma muito lenta, MUITO LENTA!
# Ta lento pra porra mesmo, pqp, ta uns 3 min por arquivo, 0.5MB/s
# Ta rapidão agora, ta em 8.89MB/s, o site do governo tava zuado
# A parte de adicionar filtros ta meio lenta, 
# ta levando uns 10 segundos pra computar os valores
# Eu deixei ele pra olhar soh as primeiras 1000 linhas pra ir mais rápido, tem q tirar dps

# Opcoes 1, 2, 3 e 6 tão prontas, falta soh 4 e 5

