//Código padrão para incluir Projetos do Asana
//Esse código foi pensado para projetos da MONTEC dentro do Asana
let
    // Define o GID do projeto do Asana a ser consultado
    IdProjeto = "GID do Projeto",

    // Define o token de acesso para autenticação na API do Asana
    AccessToken = "Token de Acesso gerado pelo Asana",

    // Campos a serem retornados na busca de tarefas
    CamposRelevantes =         
        "
            created_at,
            completed_at,
            due_on,
            completed_by.name,
            created_by.name,
            name,projects.name,
            assignee.name,
            permalink_url,
            tags.name,
            memberships.section.name,
            memberships.project
        ",

    // Faz a requisição para a API do Asana e converte o JSON de resposta em um documento
    Fonte = Json.Document(Web.Contents(
        //Endpoint do Asana que busca tarefas filtrada por projeto
        "https://app.asana.com/api/1.0/tasks?project="
        & IdProjeto &
        "&opt_fields="
        & CamposRelevantes &
        "&access_token=" & AccessToken)),

    // Converte o documento JSON em uma tabela
    ConverterParaTabela = Table.FromRecords({Fonte}),

    // Expande a coluna 'data' que contém a lista de tarefas
    ExpandirColunasLista = Table.ExpandListColumn(ConverterParaTabela, "data"),

    // Expande e redefine os campos relevantes dentro da coluna 'data'
    ExpandirColunasRecord = Table.ExpandRecordColumn(ExpandirColunasLista, "data", {
        "created_at",
        "completed_at",
        "due_on",
        "completed_by",
        "created_by",
        "name",
        "assignee",
        "permalink_url",
        "projects",
        "tags",
        "memberships"
    }),

    // Expande o campo 'assignee' para exibir o nome do responsável
    ExpandirResponsável = Table.ExpandRecordColumn(ExpandirColunasRecord, "assignee", {"name"}, {"Responsável"}),

    // Expande o campo 'completed_by' para exibir o nome de quem concluiu a tarefa
    ExpandirConcluidoPor = Table.ExpandRecordColumn(ExpandirResponsável, "completed_by", {"name"}, {"Concluído Por"}),

    // Expande o campo 'created_by' para exibir o nome de quem criou a tarefa
    ExpandirCriadoPor = Table.ExpandRecordColumn(ExpandirConcluidoPor, "created_by", {"name"}, {"Criado Por"}),

    // Expande a lista de memberships (associações a projetos e seções)
    ExpandirMemberships = Table.ExpandListColumn(ExpandirCriadoPor, "memberships"),

    // Expande os campos 'section' e 'project' dentro de 'memberships'
    ExpandirMembershipsRecord = Table.ExpandRecordColumn(ExpandirMemberships, "memberships", {"section", "project"}, {"memberships.section", "memberships.project"}),

    // Expande o campo 'section' para exibir o nome da seção
    ExpandirSection = Table.ExpandRecordColumn(ExpandirMembershipsRecord, "memberships.section", {"name"}, {"Seção"}),

    // Expande o campo 'project' para exibir o identificador do projeto
    ExpandirProjectMembership = Table.ExpandRecordColumn(ExpandirSection, "memberships.project", {"gid"}, {"memberships.project.gid"}),

    // Filtra somente as tarefas do projeto especificado
    FiltrarSeçõesPorProjeto = Table.SelectRows(ExpandirProjectMembership, each [memberships.project.gid] = IdProjeto),

    // Remove a coluna do identificador do projeto após o filtro
    RemoverColunaProjectMembership = Table.RemoveColumns(FiltrarSeçõesPorProjeto, {"memberships.project.gid"}),

    // Filtra os dados do projeto pelo ID fornecido
    FiltrarProjetoPorId = Table.TransformColumns(RemoverColunaProjectMembership, {
        {"projects", each List.Select(_, each Record.Field(_, "gid") = IdProjeto)}
    }),

    // Expande a lista de projetos para exibir as informações detalhadas
    ExpandirNomeProjetoLista = Table.ExpandListColumn(FiltrarProjetoPorId, "projects"),

    // Expande o campo 'name' para exibir o nome do projeto
    ExpandirNomeProjeto = Table.ExpandRecordColumn(ExpandirNomeProjetoLista, "projects", {"name"}, {"Projeto"}),

    // Renomeia as colunas para nomes mais descritivos e legíveis
    RenomearColunas = Table.RenameColumns(ExpandirNomeProjeto, {
        {"permalink_url", "Link da Tarefa"},
        {"name", "Tarefa"},
        {"completed_at", "Data de Conclusão"},
        {"due_on", "Previsão de Conclusão"},
        {"created_at", "Data de Criação"}
    }),

    // Altera os tipos de dados das colunas para os formatos corretos
    TiposColunasDatas = Table.TransformColumnTypes(RenomearColunas, {
        {"Data de Conclusão", type datetime},
        {"Data de Criação", type datetime},
        {"Previsão de Conclusão", type date}
    }),

    // Adiciona uma coluna de status com base na conclusão da tarefa
    AddColunaStatus = Table.AddColumn(TiposColunasDatas, "Status", each 
        if [Data de Conclusão] <> null then "Concluído" else "Em Andamento"
    ),

    // Expande a lista de tags associadas às tarefas
    ExpandirColunaListaTag = Table.ExpandListColumn(AddColunaStatus, "tags"),

    // Expande os registros da lista de tags para exibir os nomes
    ExpandirColunaRecordTag = Table.ExpandRecordColumn(ExpandirColunaListaTag, "tags", {"name"}, {"tag.name"}),

    // Agrupa as tags em uma única string separada por vírgulas para cada tarefa
    TagsAgrupadas = Table.Group(
        ExpandirColunaRecordTag,
        {"Data de Criação", "Data de Conclusão", "Previsão de Conclusão", "Concluído Por", "Criado Por", "Tarefa", "Responsável", "Link da Tarefa", "Projeto", "Status", "Seção"},
        {{"Tags", each Text.Combine(List.Transform(Table.ToRecords(_), each Text.From(_[tag.name])), ", "), type text}}
    ),

    // Função para substituir valores específicos nas tags
    SubstituirValores = (inputTable as table) as table =>
    let
        replacements = {
            {"Nº ", ""}, {"N° ", ""}, {"nº ", ""}, {"N º ", ""}, {"N ° ", ""}, {"OS N°", "OS "}
        },
        ValoresSubstituidos = List.Accumulate(replacements, inputTable, (state, current) => 
            Table.ReplaceValue(state, current{0}, current{1}, Replacer.ReplaceText, {"Tags"})
        )
    in
        ValoresSubstituidos,

    // Aplica a função de substituição de valores às tags
    SubstituirValores1 = SubstituirValores(TagsAgrupadas),

    // Altera os tipos de dados das colunas finais para texto
    AlterarDados = Table.TransformColumnTypes(SubstituirValores1, {{"Tarefa", type text}, {"Tags", type text}}),

    // Adiciona uma coluna que extrai o número da OS da tag
    AddColunaNumOs = Table.AddColumn(AlterarDados, "Número OS", each 
        let
            tag = [Tags]
        in
            if tag <> null and tag <> "" and Text.Contains(tag, "OS ") then 
                let
                    extracted = Text.Middle(tag, Text.PositionOf(tag, "OS ") + 3, Text.Length(tag)),
                    numbers = Text.BeforeDelimiter(extracted, ",")
                in
                    if Text.Length(numbers) > 0 and Text.Select(numbers, {"0".."9"}) <> "" then "OS " & numbers else null
            else 
                null
    ),

    // Reordena as colunas para a apresentação final dos dados
    ReordenarColunas = Table.ReorderColumns(AddColunaNumOs,
        {
            "Data de Criação",
            "Data de Conclusão",
            "Previsão de Conclusão",
            "Concluído Por",
            "Criado Por",
            "Responsável",
            "Tarefa",
            "Projeto",
            "Seção",
            "Número OS",
            "Tags",
            "Status",
            "Link da Tarefa"
        }
    )
in
    ReordenarColunas
