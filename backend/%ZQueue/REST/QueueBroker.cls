Class %ZQueue.REST.QueueBroker Extends %ZQueue.REST.Base
{

Parameter HandleCorsRequest = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<Route Url="/items/dlq" Method="GET" Call="GetDLQItems" Cors="true"/>
<Route Url="/items/dlq/bulk-delete" Method="POST" Call="DeleteDeadLetterItems" Cors="true"/>
<Route Url="/items/history/bulk-delete" Method="POST" Call="DeleteHistoryItems" Cors="true"/>
<Route Url="/items/dlq/:id" Method="DELETE" Call="DeleteDeadLetterItem" Cors="true"/>
<Route Url="/items/dlq/:id/retry" Method="POST" Call="RetryDLQItem" Cors="true"/>
<Route Url="/items/history" Method="GET" Call="GetHistoryItems" Cors="true"/>
<Route Url="/items/history/:id" Method="DELETE" Call="DeleteHistoryItem" Cors="true"/>

<Route Url="/items/:status" Method="GET" Call="GetItems"/>
<Route Url="/items" Method="GET" Call="GetItems" Cors="true"/>
<Route Url="/item/:id" Method="DELETE" Call="DeleteItem"/>
<Route Url="/items/bulk-delete" Method="POST" Call="BulkDelete"/>
<Route Url="/item" Method="POST" Call="CreateItem"/>

</Routes>
}

ClassMethod GetDLQItems()
{
	Try{
		Set sql = "SELECT %NOLOCK ID, Priority, QueueInfo_ClassName As ClassName,QueueInfo_MethodName As MethodName, "_
		 	"QueueInfo_RoutineName As exeRoutine,  %ODBCOUT(CreatedAt) As CreatedAt,  ErrorMsg FROM %ZQueue.DeadLetter ORDER BY Priority ASC, ID DESC"
	    Set rset = ##class(%SQL.Statement).%ExecDirect(, sql)

	     Set response = []
	    While rset.%Next() {
		    Set exectionInfo = rset.%Get("MethodName")_"^"_rset.%Get("ClassName")
	        Do response.%Push({
	            "id": (rset.%Get("ID")),
	            "executionInfo": (exectionInfo),
	            "lastError": (rset.%Get("ErrorMsg")),
	            "failedAt":(rset.%Get("CreatedAt"))
	        })
	    }
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
    Do ..WriteResponse(response)
    Return $$$OK
}

ClassMethod GetHistoryItems()
{

	Try {
		Set sql = "SELECT %NOLOCK ID As queueId, QueueInfo_ClassName As ClassName,QueueInfo_MethodName As MethodName, QueueInfo_RoutineName As exeRoutine,"_
    		"%ODBCOUT(CompletionTime) As CompletionTime, ExecutionTime FROM %ZQueue.QueueHistory"
    	Set rset = ##class(%SQL.Statement).%ExecDirect(, sql)
	    Set response = []
	    While rset.%Next() {
		    Set exectionInfo =rset.%Get("MethodName")_"^"_ rset.%Get("ClassName")
	        Do response.%Push({
	            "id": (rset.%Get("queueId")),
	            "executionInfo": (exectionInfo),
	            "completedTime": (rset.%Get("CompletionTime")),
	            "duration": (rset.%Get("ExecutionTime"))
	        })
	    }
    }
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod GetItems(status As %String = "") As %Status
{
	Set status=""
	Try {
	    Set %response.ContentType = "application/json"
	    Set sql = "SELECT %NOLOCK ID As queueId, Priority,CurrentRetry, QueueInfo_ClassName As ClassName,QueueInfo_MethodName As MethodName, QueueInfo_RoutineName As exeRoutine,  %ODBCOUT(NextRunTime) As NextRunTime, Status, LastError FROM %ZQueue.QueueItem "

	    Set statement = ##class(%SQL.Statement).%New()
	    Set sc = statement.%Prepare(sql)
	    Set rset = $Select(sc:statement.%Execute(), 1:statement.%Execute(status))

	    If rset.%sqlcode {
		    $$$ThrowSQLCODE(rset.%sqlcode,rset.%message)
	    }

	    Set response = []
	    While rset.%Next() {
		     Set qstatus = $Case(rset.Status,0:"Pending",1:"InProgress",2:"Retry",-1:"Completed",-2:"DeadLetter",:"Unknown")
	        If qstatus="Retry" Set qstatus=qstatus_" (Attempt: "_rset.CurrentRetry_")"
	        Set executionInfo=""
	        If rset.ClassName'="" {
	            Set executionInfo = rset.MethodName_"^"_rset.ClassName
	        }
	        Else {
	            Set executionInfo = rset.exeRoutine
	        }
	        Do response.%Push({
	            "id": (rset.%Get("queueId")),
	            "priority": (rset.%Get("Priority")),
	            "executionInfo":(executionInfo),
	            "nextRun": (rset.%Get("NextRunTime")),
	            "status": (qstatus),
	            "error": (rset.%Get("LastError"))
	        })
	    }
    }
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
   	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod RetryDLQItem(dlqId)
{
	Try {
		Set status = ##Class(%ZQueue.DeadLetter).MoveDLQToQueue(dlqId)
		If $$$ISERR(status) {
			Set response = ..GetErrorResponse($System.Status.GetErrorText(status))
		}
		Else {
			Set response = {"status":"ok"}
		}
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod GetErrorResponse(pErrorMsg) [ CodeMode = expression ]
{
{"status":"error","message":(pErrorMsg)}
}

ClassMethod DeleteHistoryItem(pId As %Integer)
{
	Try {
		Set status = ##Class(%ZQueue.QueueHistory).DeleteById(pId)
		Set response = {}
		If $$$ISERR(status) {
			Set response= ..GetErrorResponse(..GetErrorText(status))
		}
		Else {
			Set response.status="ok"
		}
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod DeleteHistoryItems()
{
	Try{
	#dim %request As %CSP.Request
	Set payload = {}.%FromJSON(%request.Content)
		If '$IsObject(payload) {
			Throw ##class(%Exception.General).%New("payload is empty")
		}
		If 'payload.%IsDefined("ids") {
			Throw ##class(%Exception.General).%New("ids not found")
		}
		Set iter = payload.ids.%GetIterator()
		While iter.%GetNext(,.id) {
			Do ##Class(%ZQueue.QueueHistory).DeleteById(id)
		}
		Set response ={"status":"ok"}
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	;
Exit
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod DeleteDeadLetterItem(pId As %Integer)
{
	Try {
		Set status = ##Class(%ZQueue.DeadLetter).DeleteById(pId)
		$$$ThrowOnError(status)
		Set response = {"status":"ok"}

	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod DeleteDeadLetterItems(pId As %Integer)
{
	#dim %request As %CSP.Request
	Try {
		Set payload = {}.%FromJSON(%request.Content)
		If '$IsObject(payload) {
			Throw ##class(%Exception.General).%New("payload is empty")
		}
		If 'payload.%IsDefined("ids") {
			Throw ##class(%Exception.General).%New("ids not found")
		}
		Set iter = payload.ids.%GetIterator()
		While iter.%GetNext(,.id) {
			Do ##Class(%ZQueue.DeadLetter).DeleteById(id)
		}
		Set response = {"status":"ok"}
	;
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod GetErrorText(pStatus) [ CodeMode = expression ]
{
$System.Status.GetErrorText(pStatus)
}

ClassMethod CreateItem() As %Status
{
	#dim %request As %CSP.Request
	Try{
		Set Queue = {}.%FromJSON(%request.Content)
		If '$IsObject(Queue) {
			Throw ##class(%Exception.General).%New("payload is empty")
		}
		If '$IsObject(Queue) {
			Throw ##class(%Exception.General).%New("Not a valid Json")
		}
		Set className = Queue.QueueInfo.ClassName
		If className'="" {
			If '##class(%Dictionary.ClassDefinition).%ExistsId(className) {
				Do ..SetStatusCode(..#HTTP422UNPROCESSABLEENTITY)
				Throw ##class(%Exception.General).%New("Class Not exist")
			}
			Set methodName = Queue.QueueInfo.MethodName
			If '##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName) {
				Do ..SetStatusCode(..#HTTP422UNPROCESSABLEENTITY)
				Throw ##class(%Exception.General).%New("Method Not exist")
			}
		}
		Else {
			Set routine = Queue.QueueInfo.RoutineName
			If '##class(%Routine).%ExistsId($Translate(routine,"^")) {
				Do ..SetStatusCode(..#HTTP422UNPROCESSABLEENTITY)
				Throw ##class(%Exception.General).%New("Routine Not exist")
			}
		}
		Set status = ##class(%ZQueue.Queue).EnQueue(Queue, .QueueId)
		$$$ThrowOnError(status)
		Do ..SetStatusCode(200)
		Set response = {"status":"ok","message":("QueueId "_QueueId)}
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod OnHandleCorsRequest(pUrl As %String) As %Status
{
	#dim %response As %CSP.Response
    // 1. Get the Origin from the request
    Set origin = %request.Get("HTTP_ORIGIN")
    If origin = "" Set origin = "http://localhost:8080"
    Do ..SetResponseHeader("Access-Control-Allow-Origin",origin)
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
