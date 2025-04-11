# Extrator de Tarefas do Asana

Automatize a extração, classificação e geração de relatórios das tarefas de um projeto Asana, diretamente para Excel.

Ideal para times de gestão, planejamento e acompanhamento de entregas sem precisar mexer no Asana manualmente.

---

## Funcionalidades

- Conecta automaticamente à API do Asana
- Busca todas as tarefas de um projeto
- Lê seções, status, responsáveis, datas e mais
- Classifica tarefas por situação de execução
- Gera relatório Excel personalizado para o projeto
- Pronto para ser empacotado como `.exe`

---

## Requisitos

- Python 3.8+
- Biblioteca `asana`, `pandas`, `python-dotenv`, `openpyxl`
- Criar um arquivo `.env` na raiz com:
  ```env
  ASANA_ACCESS_TOKEN=seu_token_aqui
  PROJETO_GID=gid_do_projeto
  ```

Instale as dependências com:

```bash
pip install -r requirements.txt
```

---

## Uso Rápido

1. Configure `.env` com as credenciais do seu projeto
2. Execute o script:
   ```bash
   python extrator.py
   ```
3. O arquivo `.xlsx` será salvo automaticamente em:
   ```
   Z:\Fonte de dados interna\NOME_DO_PROJETO_tarefas.xlsx
   ```

---

## Lógica Personalizável

Fora as variáveis ambienteis e o nome/local do arquivo final, essa parte do código é a única que precisa ser alterada para cada projeto, a função de **classificação de situação** da tarefa, conforme a posição da seção e o status de conclusão.

Exemplo:

```python
# Determina a situação baseada na posição da seção e status de conclusão
situacao = "Realizado"  # Valor padrão

if section_info['position'] == 1:
    situacao = "A Realizar"
elif 2 <= section_info['position'] <= 14 or (section_info['position'] == 16):
    situacao = "Em Execução"
elif section_info['position'] in [20, 22] and is_completed:
    situacao = "Finalizado"
elif section_info['position'] in [20, 22] and not is_completed:
    situacao = "Finalizado sem ser Concluído"
```
Essa função leva em consideração a posição de cada seção dentro do projeto, quem determinou a situação para as seções foi a equipe que trabalha no projeto. 

---

## Estrutura do Relatório Excel

O arquivo `.xlsx` final conterá as colunas:

- Responsável  
- Status  
- Data de Conclusão  
- Concluído por  
- Data de Criação  
- Criado por  
- Previsão de Conclusão  
- Última Modificação  
- GID  
- Tarefa  
- Seção  
- Ordem da Seção  
- Projeto  
- Tipo de Recurso  
- Tags  
- Link  
- Situação  

---

## Módulo: Obter Dados do Asana

Este módulo realiza todo o processo de:

- Conectar com a API
- Carregar .env de forma segura (compatível com `.exe`)
- Buscar tarefas com filtros e campos relevantes
- Verificar seções e posições
- Classificar situação
- Gerar Excel com todas as colunas prontas

**Modifique apenas a lógica de situação, as variaveis ambientais, o nome do arquivo e o local de salvamento para adaptar entre projetos**.

---

## Empacotamento como executável

Use o PyInstaller para transformar em `.exe`:

```bash
pyinstaller --onefile `
     --collect-all asana`
     --hidden-import asana `
     --hidden-import asana.rest `
     --hidden-import pandas._libs.tslibs `
     --hidden-import python-dotenv `
     --hidden-import numpy `
     --hidden-import openpyxl `
     --hidden-import datetime `
     --add-data ".env;." `
     --add-data "$(python -c 'import os, asana; print(os.path.dirname(asana.__file__))');asana" `
     NOME_DO_PROJETO.py
```

Isso garante compatibilidade com máquinas Windows, sem depender do Python instalado.

---

## Documentação do Asana

- [Asana API Docs](https://developers.asana.com/docs)

---

## Autor

Feito por:
Eduardo de L. Congio
