
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

# L I N K   D O   G I T H U B
# https://github.com/Renzo-Filho/EP2-bash-scripts

##################################################################

#!/bin/bash

# Funciona em sistemas Unix. Há poucas diferenças em sistemas MacOS.

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

# Input da função 'verifica_arquivo'
CRIA_ARQUIVO=0
REMOVE_ARQUIVO=1

arquivo_atual="$DIR/$CODIF"
arquivo_filtrado="linhas_validas.csv"

# Coleção de filtros. Será aplicado na função 'filtra_linhas'
filtros=()
filtros_string=""

############################## F U N Ç Õ E S ##############################

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

        # conversão para UTF8
        iconv -f ISO-8859-1 -t UTF8 "$path_output" > "temp.csv"

        # Remove o último caractere de cada linha do arquivo baixado. Inibe problemas quando tentamos imprimir os valores da última coluna.
        tr -d '\r' < "temp.csv" > "$path_output"
        rm temp.csv

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

    # Tipo, printar erro se tiver algo de errado com o input ou baixar os arquivos se tiver inputs.

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

function filtra_linhas {

    # Salva em um arquivo as linhas filtradas de acordo com os filtros

    # Se o arquivo não existe, cria uma cópia do atual
    if [ ! -e $arquivo_filtrado ]; then
        # Copia o arquivo escolhido, pulando a primeira linha
        sed 1,1d $arquivo_atual > $arquivo_filtrado
    fi

    # Se não tem filtros, não faz nada
    if [ ${#filtros[@]} -eq 0 ]; then
        return
    fi

    # Para cada filtro, salvamos as linhas que contém o filtro buscado
    for filtro in ${filtros[@]}; do
        grep "$filtro" "$arquivo_filtrado" > temp.txt
        mv temp.txt "$arquivo_filtrado"
    done
}

function mostra_info {

    local nome_arquivo=$(basename $arquivo_atual)

    echo "+++ Arquivo atual: $nome_arquivo"

    # Esse if printa os filtros caso existam
    # Ele também separa os filtros com ` | `
    # Verifica se existem filtros
    if [ ${#filtros[@]} -ne 0 ]; then
        echo "+++ Filtros atuais:"
        echo "$filtros_string"
    fi

    filtra_linhas

    local num_reclamacoes=$(wc -l < $arquivo_filtrado | tr -d ' ')

    echo "+++ Número de reclamações: $num_reclamacoes"

    echo "+++++++++++++++++++++++++++++++++++++++"
    echo "" 
}

function verifica_arquivo {

    # Verifica se o arquivo $arquivo_filtrado existe e:
    # $1 == 0: cria o arquivo se não existe
    # $1 == 1: remove o arquivo se existe

    if [ $1 -eq $CRIA_ARQUIVO ] && [ ! -e $arquivo_filtrado ]; then
        filtra_linhas
    fi

    if [ $1 -eq $REMOVE_ARQUIVO ] && [ -e $arquivo_filtrado ]; then
        rm $arquivo_filtrado
    fi

}

################# F U N Ç Õ E S   P R I N C I P A I S #################

function selecionar_arquivo {

    # Remove filtros e o arquivo filtrado.
    if [ ${#filtros[@]} -ne 0 ]; then
    
        filtros=()
        filtros_string=""

        if [ -e $arquivo_filtrado ]; then
            rm $arquivo_filtrado
        fi
    fi

    echo ""
    echo "Escolha uma opção de arquivo:"
    
    local arquivos_nomes=()

    for arquivo in $DIR/*.csv; do
        arquivos_nomes+=($(basename -a "$DIR/$arquivo"))
    done

    enumera "${arquivos_nomes[@]}"

    read -p "#? " escolha

    local novo_arquivo=${arquivos_nomes[((escolha - 1))]}
    arquivo_atual="$DIR/$novo_arquivo"

    # Tem q remover o atual pra ele computar corretamente dps
    if [ -e $arquivo_filtrado ]; then
        rm $arquivo_filtrado
    fi

    mostra_info
}

function adicionar_filtro_coluna {

    verifica_arquivo $CRIA_ARQUIVO

    echo ""
    echo "Escolha uma opção de coluna para o filtro:"

    IFS=';'
    local colunas=($(head -n 1 $arquivo_atual)) # Array com colunas, usa da primeira linha do arquivo

    enumera ${colunas[@]} # Printa as opções

    read -p "#? " coluna # Lê a escolha
    echo "" # Linha de espaço

    local valores=()

    # Pega os valores da coluna especificada, ordena e descarta valores repetidos
    # Então tranforma em um array
    while IFS= read -r valor; do
        if [ ! -z $valor ]; then # Verifica se o valor não é vazio
            valores+=("$valor")
        fi
    
    done < <(cut -d';' -f${coluna} $arquivo_filtrado | sort | uniq)

    # Se n tem nenhum valor possível
    # para ser usado como filtro
    if [ ${#valores[@]} -eq 0 ]; then
        echo "Não é possível adicionar um filtro para essa coluna com os filtros atuais."
        mostra_info
        return
    fi

    echo "Escolha uma opção de valor para ${colunas[$coluna - 1]}:"
    enumera ${valores[@]}

    read -p "#? " valor

    local valor_coluna=${colunas[(( coluna - 1 ))]}
    local filtro=${valores[((valor - 1))]}

    local par="$valor_coluna = $filtro"

    filtros+=($filtro)

    if [ ${#filtros_string} -ne 0 ]; then
        filtros_string+=" | "
    fi

    filtros_string+="$par"

    echo "+++ Adicionado filtro: $par"
    mostra_info

}

function limpar_filtros_colunas {

    # Remove todos os filtros aplicados

    filtros=()
    filtros_string=""

    verifica_arquivo $REMOVE_ARQUIVO

    echo "+++ Filtros removidos"
    mostra_info
}

function mostrar_duracao_media_reclamacao {

    verifica_arquivo $CRIA_ARQUIVO

    # Mostra o tempo de duração médio de uma reclamação em dias, calculado a partir da
    # diferença entre os valores das colunas "Data do Parecer" e "Data de abertura" das linhas de
    # reclamações selecionadas no momento.

    local total_segundos=0
    local contagem=0               # Contador de linhas válidas

    # Itera sobre cada linha das reclamações selecionadas
    while IFS=';' read -r col1 _ _ _ _ _ _ _ _ _ _ _ col13 _; do

        # Verifica se ambas as colunas de datas estão presentes
        if [[ ! -n "$col1" ||  ! -n "$col13" ]]; then
            continue
        fi

        # Converte as datas para segundos desde "Epoch" para realizar cálculo de dias
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            local data_inicial=$(date -d "$col1" +%s)
            local data_final=$(date -d "$col13" +%s)
        else
            local data_inicial=$(date -j -f "%Y-%m-%d %H:%M:%S" "$col1" "+%s")
            local data_final=$(date -j -f "%Y-%m-%d %H:%M:%S" "$col13" "+%s")
        fi

        # Verifica se a conversão foi bem-sucedida
        if [[ ! -n "$data_inicial" || ! -n "$data_final" ]]; then
            continue  
        fi

        # Calcula a diferença em segundos
        local diff_segundos=$(( data_final - data_inicial ))

        # Soma a diferença de segundos ao total e incrementa o contador
        local total_segundos=$(( total_segundos + diff_segundos ))
        ((contagem++))

    done < $arquivo_filtrado

    # Calcula a média, se houver reclamações válidas
    if (( contagem > 0 )); then
        local media=$((total_segundos / 86400 / contagem))
        echo "Duração média das reclamações: $media dias"
    else
        echo "Nenhuma reclamação válida encontrada."
    fi
    
    echo "+++++++++++++++++++++++++++++++++++++++"
    echo ""
}

function mostrar_ranking_reclamacoes {

    verifica_arquivo $CRIA_ARQUIVO

    echo ""
    echo "Escolha uma opção de coluna para análise:"

    IFS=';'
    local colunas=($(head -n 1 $arquivo_atual)) # Array com colunas, usa da primeira linha do arquivo

    enumera ${colunas[@]} # Printa as opções

    read -p "#? " coluna # Lê a escolha
    echo "" # Linha de espaço

    echo "+++ ${colunas[coluna - 1]} com mais reclamações:"

    # Separa as linhas pelas colunas, ordena-as numericamente e imprime os 5 maiores valores com um "espaço" na frente.
    cut -d';' -f${coluna} $arquivo_filtrado | sort | uniq -c | sort -nr | head -n 5 | sed 's/^/   /'

    echo "+++++++++++++++++++++++++++++++++++++++"
    echo ""
}

function mostrar_reclamacoes {

    # Mostra as reclamações ;)

    verifica_arquivo $CRIA_ARQUIVO

    cat $arquivo_filtrado
    mostra_info
}

function loop_principal {

    # Executa o programa, fornecendo um menu ao usuário

    verifica_arquivo $REMOVE_ARQUIVO

    local opcao="0"

    while [ $opcao != "7" ]; do

        echo "Escolha uma opção de operação:"
        enumera "${NOMES_OPERACOES[@]}"

        read -p "#? " opcao # Lê a escolha

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

    verifica_arquivo $REMOVE_ARQUIVO

    echo -e $MENSAGEM_FINAL
    exit 0
}


# Inicializa o programa, lidando com o input.
pre_programa    

# Exibe as opções e funcionalidades
loop_principal
