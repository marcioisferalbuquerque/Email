Attribute VB_Name = "RemoverEmailsDuplicados"
Option Explicit

' =====================================================================
'  RemoverEmailsDuplicados - Macro VBA para Outlook (Windows)
'
'  O que faz:
'    Percorre a pasta escolhida (ex.: Caixa de Entrada) e move para a
'    lixeira ("Itens Excluidos") todos os e-mails duplicados, mantendo
'    sempre 1 copia de cada. Um e-mail e considerado duplicado quando
'    tem o MESMO remetente + assunto + data/hora de envio + tamanho.
'
'  Como instalar:
'    1. Abra o Outlook e pressione ALT + F11 (abre o editor VBA)
'    2. Menu Arquivo > Importar Arquivo... e escolha este arquivo .bas
'       (ou: botao direito em "Projeto1" > Inserir > Modulo e cole o codigo)
'    3. Feche o editor VBA
'
'  Como usar:
'    1. No Outlook, pressione ALT + F8
'    2. Escolha "LimparDuplicados" e clique em Executar
'    3. Escolha a pasta que quer limpar e confirme
'
'  Seguranca:
'    - NADA e apagado em definitivo: os duplicados vao para a pasta
'      "Itens Excluidos". Se algo der errado, e so recuperar de la.
'    - Antes de mover qualquer coisa, a macro mostra quantos duplicados
'      encontrou e pede confirmacao.
'
'  Obs.: Se o Outlook bloquear macros, va em:
'    Arquivo > Opcoes > Central de Confiabilidade > Configuracoes da
'    Central de Confiabilidade > Configuracoes de Macro > e marque
'    "Notificacoes para todas as macros".
' =====================================================================

Public Sub LimparDuplicados()

    Dim pasta As Outlook.Folder
    Dim itens As Outlook.Items
    Dim item As Object
    Dim email As Outlook.MailItem
    Dim jaVistos As Object          ' Scripting.Dictionary
    Dim duplicados As Collection
    Dim chave As String
    Dim i As Long
    Dim resposta As VbMsgBoxResult

    ' ---- 1. Usuario escolhe a pasta a limpar (ex.: Caixa de Entrada) ----
    Set pasta = Application.Session.PickFolder
    If pasta Is Nothing Then
        MsgBox "Nenhuma pasta selecionada. Operacao cancelada.", vbInformation, "Remover Duplicados"
        Exit Sub
    End If

    Set jaVistos = CreateObject("Scripting.Dictionary")
    Set duplicados = New Collection

    ' ---- 2. Ordena por data para manter sempre a copia mais antiga ----
    Set itens = pasta.Items
    itens.Sort "[ReceivedTime]", False   ' False = ordem crescente (mais antigo primeiro)

    ' ---- 3. Identifica os duplicados ----
    For i = 1 To itens.Count
        Set item = itens(i)

        ' Considera apenas e-mails (ignora convites, tarefas, etc.)
        If TypeName(item) = "MailItem" Then
            Set email = item

            ' Chave de comparacao: remetente + assunto + data de envio + tamanho
            On Error Resume Next
            chave = email.SenderEmailAddress & "||" & _
                    email.Subject & "||" & _
                    Format(email.SentOn, "yyyy-mm-dd hh:nn:ss") & "||" & _
                    email.Size
            On Error GoTo 0

            If jaVistos.Exists(chave) Then
                duplicados.Add email      ' ja existe uma copia -> este e duplicado
            Else
                jaVistos.Add chave, True  ' primeira vez que aparece -> mantem
            End If
        End If
    Next i

    ' ---- 4. Nada encontrado? ----
    If duplicados.Count = 0 Then
        MsgBox "Nenhum e-mail duplicado encontrado na pasta """ & pasta.Name & """.", _
               vbInformation, "Remover Duplicados"
        Exit Sub
    End If

    ' ---- 5. Pede confirmacao antes de mover ----
    resposta = MsgBox("Foram encontrados " & duplicados.Count & " e-mails duplicados na pasta """ & _
                      pasta.Name & """." & vbCrLf & vbCrLf & _
                      "Deseja mover todos para a pasta 'Itens Excluidos'?" & vbCrLf & _
                      "(Sera mantida 1 copia de cada e-mail)", _
                      vbYesNo + vbQuestion, "Remover Duplicados")

    If resposta <> vbYes Then
        MsgBox "Operacao cancelada. Nenhum e-mail foi movido.", vbInformation, "Remover Duplicados"
        Exit Sub
    End If

    ' ---- 6. Move os duplicados para Itens Excluidos ----
    Dim lixeira As Outlook.Folder
    Dim movidos As Long
    Set lixeira = Application.Session.GetDefaultFolder(olFolderDeletedItems)

    movidos = 0
    For i = duplicados.Count To 1 Step -1   ' de tras pra frente para nao bagunçar os indices
        On Error Resume Next
        duplicados(i).Move lixeira
        If Err.Number = 0 Then movidos = movidos + 1
        Err.Clear
        On Error GoTo 0
    Next i

    ' ---- 7. Resumo final ----
    MsgBox "Pronto!" & vbCrLf & vbCrLf & _
           movidos & " e-mails duplicados foram movidos para 'Itens Excluidos'." & vbCrLf & _
           "Se precisar recuperar algum, e so procurar la.", _
           vbInformation, "Remover Duplicados"

End Sub
