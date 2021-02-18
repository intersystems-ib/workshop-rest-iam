/// Simple REST API to log IAM requests
Class Webinar.API.Audit Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/log" Method="POST" Call="LogRequest"/>
</Routes>
}

/// Simple method to log a request into a JSON file
ClassMethod LogRequest() As %Status
{
    set ret = $$$OK
    
    try {
        set content = %request.Content

        set formatter = ##class(%JSON.Formatter).%New()
        do formatter.FormatToStream(content, .formatted)
    
        set file = ##class(%Stream.FileCharacter).%New()
        set file.Filename = "/shared/audit.json"
        do file.MoveToEnd()
        do file.WriteLine()
        do file.CopyFrom(formatted)
        do file.%Save()

    } catch ex {
        set ret = ex.AsStatus()
    }

    quit ret
}

}
