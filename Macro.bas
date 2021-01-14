Public Sub Schaltflaeche_Klicken()


Dim ws As Worksheet
Set ws = ActiveSheet

Dim mailTextVorlage As String
mailTextVorlage = Sheets("_Email").Shapes(1).TextFrame2.TextRange.Text
Dim mailBetreff As String
mailBetreff = ActiveWorkbook.Names("varBetreff").RefersToRange.Value2
Dim mailEmailAbsender As String
mailEmailAbsender = ActiveWorkbook.Names("varEmailAbsender").RefersToRange.Value2
Dim mailNameAbsender As String
mailNameAbsender = ActiveWorkbook.Names("varNameAbsender").RefersToRange.Value2
Dim zeitraum As String
zeitraum = ActiveWorkbook.Names("varZeitraum").RefersToRange.Value2
Dim kalenderwoche As String
kalenderwoche = ActiveWorkbook.Names("varKalenderwoche").RefersToRange.Value2
Dim ziel_ds As Double
ziel_ds = ActiveWorkbook.Names("varZielDS").RefersToRange.Value2
Dim ziel_otd As Double
ziel_otd = ActiveWorkbook.Names("varZielOTD").RefersToRange.Value2

'Setup
Dim tabelleDaten As ListObject
Set tabelleDaten = Sheets("Eingabe").ListObjects("DatenTabelle")

'Gehe jede Reihe der DatenTabelle durch
Dim iRow As Integer
For iRow = 2 To tabelleDaten.ListRows.Count + 1

    Dim mailText As String
    mailText = mailTextVorlage

    'Mailempfaenger der ersten 4 Spalten setzen
    Dim unternehmer As String
    unternehmer = tabelleDaten.Range(iRow, 1).Value
    Dim empfaenger As String
    empfaenger = tabelleDaten.Range(iRow, 2).Value
    Dim empfaengerMail As String
    empfaengerMail = tabelleDaten.Range(iRow, 3).Value
    Dim cc As String
    cc = tabelleDaten.Range(iRow, 4).Value
    
    Dim ds As Double
    ds = tabelleDaten.Range(iRow, 5).Value
    Dim otd As Double
    otd = tabelleDaten.Range(iRow, 6).Value
    Dim ds_vw As Double
    ds_vw = tabelleDaten.Range(iRow, 7).Value
    Dim otd_vw As Double
    otd_vw = tabelleDaten.Range(iRow, 8).Value
    Dim fahrerliste As String
    
    '--------------------------------------------------------------
    If Not (unternehmer = "" Or empfaenger = "" Or empfaengerMail = "" Or ds = 0 Or otd = 0) Then
        ds = Delta_Berechnen(ds, ziel_ds)
        otd = Delta_Berechnen(otd, ziel_otd)
        ds_vw = Delta_Berechnen(ds_vw, ziel_ds)
        otd_vw = Delta_Berechnen(otd_vw, ziel_otd)
        
        Dim verb As String
        verb = Verb_Ermitteln(ds, otd)
    
        mailText = Replace(mailText, "[@DS]", Zahlen_Faerben(ds), , , vbCompare)
        mailText = Replace(mailText, "[@DS_Vorwoche]", Zahlen_Faerben(ds_vw), , , vbCompare)
        mailText = Replace(mailText, "[@OTD]", Zahlen_Faerben(otd), , , vbCompare)
        mailText = Replace(mailText, "[@OTD_Vorwoche]", Zahlen_Faerben(otd_vw), , , vbCompare)
        mailText = Replace(mailText, "[@Empfaenger]", empfaenger, , , vbCompare)
        mailText = Replace(mailText, "[@Kalenderwoche]", kalenderwoche, , , vbCompare)
        mailText = Replace(mailText, "[@Zeitraum]", zeitraum, , , vbCompare)
        mailText = Replace(mailText, "[@Stationziel_DS]", ziel_ds, , , vbCompare)
        mailText = Replace(mailText, "[@Stationziel_OTD]", ziel_otd, , , vbCompare)
        mailText = Replace(mailText, "übertroffen/unterschritten", verb, , , vbCompare)
        
        fahrerliste = Fahrerliste_erstellen(unternehmer)
        mailText = Replace(mailText, "[@Fahrerliste]", fahrerliste, , , vbCompare)
        
        'mail senden
        Dim senden_Status As String
        senden_Status = sendMail(empfaengerMail, cc, mailBetreff, mailText, anhang)
    Else
        MsgBox ("Die Daten in Zeile " & iRow - 1 & " der Tabelle sind nicht Vollständig. Zum Versenden der Mail müssen 'Unternehmer', 'Empfänger', 'Email', 'DS' und 'OTD' ausgefüllt sein")
    End If
Next

End Sub


Public Function sendMail(ByVal addressTo As String, ByVal addressCC As String, ByVal betreff As String, ByVal htmlText As String)
    On Error Resume Next
    
    'check if recipient exists
    If addressTo Like "" Then
        MsgBox ("Failed to send mail. No recipient found.")
        Exit Function
    End If

    Dim appOutlook As Object
    Set appOutlook = CreateObject("Outlook.Application")
    Dim email As Object
    Set email = appOutlook.CreateItem(0)

    'adding recipient and CC
    email.To = addressTo
    If Not addressCC Like "" Then
         Dim addressCC_Array() As String
         addressCC_Array = Split(addressCC, ";")
         email.cc = addressCC_Array
    End If

    email.Subject = betreff
    email.BodyFormat = olFormatHTML
    email.GetInspector 'add signatur to end of mail
    email.HTMLBody = htmlText & email.HTMLBody
    
    'Show email if cell is true
     If ActiveWorkbook.Worksheets("_State").Cells(1, 2).Value = "true" Then
        email.Display True
    'Send mail right away if cell is false
    ElseIf ActiveWorkbook.Worksheets("_State").Cells(1, 2).Value = "false" Then
        email.Send
    Else
        MsgBox ("Failed check if mail should be displayed or not. Set Cell (1, 2) on Worksheet '_State' to true or false.")
    End If
        
    Set email = Nothing
    Set appOutlook = Nothing

End Function


'Private Function Verb_Ermitteln(ByVal ds As Double, ByVal otd As Double) As String
'    If ds >= 0 And otd >= 0 Then
'        Verb_Ermitteln = "übertroffen"
'        Exit Function
'    ElseIf ds < 0 And otd < 0 Then
'        Verb_Ermitteln = "unterschritten"
'        Exit Function
'    Else
'        Verb_Ermitteln = "übertroffen/unterschritten"
'        Exit Function
'    End If
'    
'    Verb_Ermitteln = "übertroffen/unterschritten"
'End Function

                                
'Private Function Zahlen_Faerben(ByVal wert As Double) As String
'    Dim ausgabe As String
'
'    If wert >= 0 Then
'        ausgabe = "<font color='00b803'>+" & wert & " %</font>"
'        Zahlen_Faerben = ausgabe
'        Exit Function
'    ElseIf wert < 0 Then
'        ausgabe = "<font color='de0707'>" & wert & " %</font>"
'        Zahlen_Faerben = ausgabe
'        Exit Function
'    End If
'    
'    Zahlen_Faerben = wert & " %"
'End Function


'Private Function Delta_Berechnen(ByVal wert As Double, ByVal vergleich As Double) As Double
'    Dim ergebnis As Double
'    ergebnis = wert - vergleich
'    ergebnis = Math.Round(ergebnis, 2)
'    
'    Delta_Berechnen = ergebnis
'End Function


Private Function Fahrerliste_erstellen(ByVal unternehmer As String) As String
    Dim tabelleFahrer As ListObject
    Set tabelleFahrer = Sheets("Eingabe").ListObjects("FahrerTabelle")
    
    Dim liste As String
    liste = "<table><tr><th>Fahrer</th><th>DS</th><th>OTD</th><th>Volumen</th></tr>"
        
    Dim result
    Dim iRow As Integer
    For iRow = 2 To (tabelleFahrer.ListRows.Count + 1)
        result = StrComp(unternehmer, tabelleFahrer.Range(iRow, 1).Value)
        If result < 1 And result > -1 Then
            liste = liste & "<tr><td>" & tabelleFahrer.Range(iRow, 2).Value & "</td><td>" & tabelleFahrer.Range(iRow, 3).Text & "</td><td>" & tabelleFahrer.Range(iRow, 4).Text & "</td><td>" & tabelleFahrer.Range(iRow, 5).Value & "</th></tr>"
        End If

    Next
    
    liste = liste & "</table><br>"
    Fahrerliste_erstellen = liste
End Function
