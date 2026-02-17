Class %ZQueue.REST.Base Extends %CSP.REST
{

ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
	Do ##class(%REST.Impl).%SetContentType(..#CONTENTTYPEJSON)
    Quit $$$OK
}

ClassMethod SetStatusCode(pStatus = 200)
{
	Do ##class(%REST.Impl).%SetStatusCode(pStatus)
}

ClassMethod WriteResponse(pResponse)
{
	Do ##class(%REST.Impl).%WriteResponse(pResponse)
}

ClassMethod SetResponseHeader(name As %String, value As %String)
{
	Do ##class(%REST.Impl).%SetHeader(name,value)
}

}
