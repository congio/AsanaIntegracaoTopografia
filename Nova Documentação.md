# 📐 Documentação Sistema de Integração Power BI + Asana

Esta documentação descreve em detalhe como funciona o processo de extração, transformação e visualização de dados no Power BI a partir do Asana. Inclui scripts Python, arquivos Excel e transformação via Power Query.

---

## 🔷 Nível 1 – Diagrama de Contexto

**Objetivo:** Mostrar os envolvidos e os sistemas que se comunicam.

**Participantes:**
- 👤 **Usuário Final (Analista de Projetos)** – Utiliza os dashboards do Power BI.
- 🧠 **Sistema de Extração (Python)** – Scripts que se conectam ao Asana e salvam os dados em Excel.
- 📁 **Sistema de Armazenamento (Rede Interna)** – Diretório compartilhado onde os arquivos `.xlsx` são salvos.
- 📊 **Sistema de Visualização (Power BI)** – Carrega os dados dos arquivos e aplica lógica de transformação via Power Query.

📌 **Fluxo geral:**
1. O analista agenda a execução (ou roda manualmente) o script `Asana.py`.
2. Este script chama executáveis como `GEO-INCRA.exe` (compilado de `GEO-INCRA.py`).
3. O script coleta os dados de tarefas no Asana e salva um arquivo Excel.
4. O Power BI lê esse Excel e aplica a lógica contida em `ProjetosTopografia.m`.

---

## 🔷 Nível 2 – Diagrama de Contêineres

**Contêineres principais:**

### 1. 🧠 `Asana.py`
- Executa todos os scripts `.exe` correspondentes a cada projeto (como `GEO-INCRA.exe`).
- Responsável por registrar logs e garantir que a coleta seja sequencial e confiável.

### 2. 🧠 `GEO-INCRA.py` (e similares)
- Conecta à API do Asana usando `ASANA_ACCESS_TOKEN`.
- Extrai tarefas, tags, seções, responsáveis, status etc.
- Salva os dados em `\SERVIDOR\Dashboard\Fonte de dados interna\GEO-INCRA_tarefas.xlsx`.

### 3. 📁 Arquivos Excel (por projeto)
- Servem como **fonte de dados bruta**.
- Nome da tabela no Power BI corresponde ao nome do arquivo (ex: `GEO-INCRA`).

### 4. 📊 Power BI / Power Query
- Transforma os dados.
- Aplica validações, extrai campos de texto estruturados (como “Imóvel” e “Matrícula”).
- Exibe resultados em dashboards.

---

## 🔷 Nível 3 – Diagrama de Componentes

### 🔹 Script Python `GEO-INCRA.py`
- 📦 **Asana SDK:** Conecta-se e consulta tarefas usando `asana.TasksApi`.
- 📦 **DotEnv:** Lê variáveis seguras do `.env` (como `GEO_GID`).
- 📦 **Pandas:** Constrói e salva DataFrame com os dados extraídos.
- 📦 **OpenPyXL:** Grava Excel.

### 🔹 Script Power Query `ProjetosTopografia.m`
Este script é o coração da transformação de dados no Power BI. Ele é responsável por consolidar as tabelas geradas pelos scripts Python e aplicar diversas transformações e validações para gerar uma base analítica padronizada e confiável.

**Componentes principais:**

- 📦 **Table.Combine:**
  - Une as tabelas de diferentes projetos (`GEO-INCRA`, `UNIFICACAO`, `USUCAPICAO`, `ESTREMACAO`) em uma única tabela chamada `TodosOsProjetos`.

- 📦 **Extração de dados de tags:**
  - `ExtrairNúmeroOS`: identifica valores como `OS 1234` dentro da coluna `Tags`.
  - `FormatarNúmeroOS`: adiciona prefixo "OS " ao número encontrado.
  - `ExtrairMeta`: transforma tags como `META 042025` em uma data correspondente ao último dia do mês (30/04/2025).

- 📦 **Tratamento da coluna `Tarefa`:**
  - `IncluirTagCliente`: extrai o nome do cliente até o primeiro delimitador encontrado (`-`, `|`, etc.).
  - `AdicionarTarefaTratada`: verifica se a tarefa segue os padrões definidos para estrutura textual (ex: `| Imóvel:`, `| Matrícula n°`).

- 📦 **Extração de campos estruturados:**
  - `AdicionarColunas`: cria colunas como `Imóvel`, `Lote`, `Gleba`, `Colônia`, `Matrícula`, `Município` a partir de padrões dentro da `Tarefa Tratada`.

- 📦 **Limpeza e Padronização:**
  - `TabelaTransformada`: remove prefixos indesejados como `nº`, `: ` e espaços extras.
  - `CorrigirMunicipioEUF`: separa a cidade e estado (UF) da coluna `Município` original e cria uma nova coluna `UF`.** remove textos desnecessários, espaços, prefixos e separa `Município` de `UF`.

---

## 🔷 Nível 4 – Código

### 🔹 GEO-INCRA.py (Resumo de implementação)
```python
ASANA_ACCESS_TOKEN = os.getenv("ASANA_ACCESS_TOKEN")
PROJECT_GID = os.getenv("GEO_GID")
api_client = asana.ApiClient(configuration)
tasks_api_instance = asana.TasksApi(api_client)
sections_response = sections_api_instance.get_sections_for_project(PROJECT_GID)
```
- Faz paginação da API para garantir coleta completa.
- Classifica tarefas com base na seção atual (A Realizar, Em Execução, Finalizado etc.).
- Gera `.xlsx` com campos úteis para o Power BI.

### 🔹 ProjetosTopografia.m (Power Query)
```powerquery
TodosOsProjetos = Table.Combine({
    #"GEO-INCRA",
    #"UNIFICACAO",
    #"USUCAPICAO",
    #"ESTREMACAO"
})
```
- Aplica transformações como:
  - `ExtrairNúmeroOS`
  - `FormatarNúmeroOS`
  - `ExtrairMeta`
  - `IncluirTagCliente`
  - `AdicionarTarefaTratada`
  - `AdicionarColunas`
  - `CorrigirMunicipioEUF`

---

## 📌 Observações para Novos Projetos
- Criar script Python similar ao `GEO-INCRA.py`.
- Adicionar o novo executável no `Asana.py`.
- Garantir que o Excel gerado seja salvo com nome idêntico à nova tabela do Power BI.
- Incluir a nova tabela no `Table.Combine` do Power Query.

---

## ✅ Resultado Esperado

Ao final do processo:
- Dados centralizados e padronizados no Power BI.
- Automação segura via scripts Python.
- Flexibilidade para integrar novos projetos no modelo existente com mínimo esforço.

---

