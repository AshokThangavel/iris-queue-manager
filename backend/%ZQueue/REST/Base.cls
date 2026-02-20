Include %ZQueue

Class %ZQueue.REST.Base Extends %CSP.REST
{

Parameter UseSession As BOOLEAN = 1;

ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
	Do ##class(%REST.Impl).%SetContentType(..#CONTENTTYPEJSON)
    Quit $$$OK
}

ClassMethod SetStatusCode(pStatus = 200)
{
	Do ##class(%REST.Impl).%SetStatusCode(pStatus)
}

ClassMethod GetErrorText(pException As %Exception.AbstractException) As %String
{
    If pException = "" {
        Return ""
    }
    If pException.%IsA("%Exception.AbstractException") {
        Set pException = pException.AsStatus()
    }
    Return $System.Status.GetErrorText(pException)
}

ClassMethod GetErrorResponse(pErrorMsg) [ CodeMode = expression ]
{
{"status":"error","message":(pErrorMsg)}
}

ClassMethod GetStatusOk() [ CodeMode = expression ]
{
{"status":"ok"}
}

ClassMethod GetContent()
{
    #dim %request As %CSP.Request

    If %request.Content=..#CONTENTTYPEJSON {
        Set content = {}.%FromJSON(%request.Content)
    } Else  {
        Set content = %request.Content
    }
    Return content
}

ClassMethod WriteResponse(pResponse)
{
	Do ##class(%REST.Impl).%WriteResponse(pResponse)
}

ClassMethod SetResponseHeader(name As %String, value As %String)
{
	Do ##class(%REST.Impl).%SetHeader(name,value)
}

ClassMethod OnHandleCorsRequest(pUrl As %String) As %Status
{
	#dim %response As %CSP.Response
    Set origin=$Get(%request.CgiEnvs("HTTP_ORIGIN"))

    If origin = "" Set origin = "http://localhost:8080"
    ;Do ..SetResponseHeader("Access-Control-Allow-Origin",origin)
    Do ..SetResponseHeaderIfEmpty("Access-Control-Allow-Origin",origin)
    Do ..SetResponseHeader("Access-Control-Allow-Credentials","true")
    Do ..SetResponseHeader("Access-Control-Allow-Methods","GET, POST, PUT, DELETE, OPTIONS")
    Do ..SetResponseHeader("Access-Control-Allow-Headers","Origin, Content-Type, Accept, Authorization")
    If %request.Method = "OPTIONS" {
        Set %response.Status = "200"
        Quit $$$OK
    }

    Quit $$$OK
}

}
