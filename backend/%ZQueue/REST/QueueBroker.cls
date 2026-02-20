Class %ZQueue.REST.QueueBroker Extends %ZQueue.REST.Base
{

Parameter HandleCorsRequest = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/item" Method="POST" Call="CreateItem" Cors="true"/>
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
<Route Url="/queue/status" Method="GET" Call="GetQueueStatus"/>
<Route Url="/queue/start" Method="POST" Call="StartQueue"/>
<Route Url="/queue/stop" Method="POST" Call="StopQueue"/>

</Routes>
}

ClassMethod GetDLQItems()
{
	Try{
	    Set rset = ##class(%ZQueue.DeadLetter).GetAllDLQRecordsFunc()
	    Set response = []
	    While rset.%Next() {
			If rset.%Get("ClassName")="" {
				Set exectionInfo = rset.%Get("exeRoutine")
			}
			Else {
				Set exectionInfo = rset.%Get("MethodName")_"^"_rset.%Get("ClassName")
			}
	        Do response.%Push({
	            "id": (rset.%Get("ID")),
	            "executionInfo": (exectionInfo),
	            "lastError": (rset.%Get("ErrorMsg")),
	            "failedAt":(rset.%Get("CreatedAt"))
	        })
	    }
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
    Do ..WriteResponse(response)
    Return $$$OK
}

ClassMethod GetHistoryItems()
{
	Try {
    	Set rset = ##class(%ZQueue.QueueHistory).GetAllHistoryRecordsFunc()
	    Set response = []
	    While rset.%Next() {
			If rset.%Get("ClassName")="" {
				Set exectionInfo = rset.%Get("exeRoutine")
			}
			Else {
		    	Set exectionInfo =rset.%Get("MethodName")_"^"_ rset.%Get("ClassName")
			}
	        Do response.%Push({
	            "id": (rset.%Get("queueId")),
	            "executionInfo": (exectionInfo),
	            "completedTime": (rset.%Get("CompletionTime")),
	            "duration": (rset.%Get("ExecutionTime"))
	        })
	    }
    }
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod GetItems(status As %String = "") As %Status
{
	Set status=""
	Try {
	    Set rset = ##class(%ZQueue.QueueItem).GetAllQueueItemsFunc()
	    Set response = []
	    While rset.%Next() {
		     Set qstatus = $Case(rset.Status,0:"Pending",1:"InProgress",2:"Retry",-1:"Completed",-2:"DeadLetter",:"Unknown")
	        If qstatus="Retry" {
				Set qstatus=qstatus_" (Attempt: "_rset.CurrentRetry_")"
			}
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
		Set response = ..GetErrorResponse(..GetErrorText(ex))
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
			Set response = ..GetStatusOk()
		}
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex.AsStatus()))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod DeleteHistoryItem(pId As %Integer)
{
	Try {
		Set status = ##Class(%ZQueue.QueueHistory).DeleteById(pId)
		If $$$ISERR(status) {
			Set response= ..GetErrorResponse(..GetErrorText(status))
		}
		Else {
			Set response = ..GetStatusOk()
		}
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod DeleteHistoryItems()
{
	#define ThrowGeneral(%msg) Throw ##class(%Exception.General).%New(%msg)
	Try{
		Set payload = ..GetContent()
		If '$IsObject(payload) {
			$$$ThrowGeneral("payload is empty")
		}
		If 'payload.%IsDefined("ids") {
			$$$ThrowGeneral("ids not found")
		}
		Set iter = payload.ids.%GetIterator()
		While iter.%GetNext(,.id) {
			Do ##Class(%ZQueue.QueueHistory).DeleteByQueueId(id)
		}
		Set response = ..GetStatusOk()
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod DeleteDeadLetterItem(pId As %Integer)
{
	Try {
		Set status = ##Class(%ZQueue.DeadLetter).DeleteById(pId)
		$$$ThrowOnError(status)
		Set response = ..GetStatusOk()

	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod DeleteDeadLetterItems(pId As %Integer)
{
	Try {
		Set payload = ..GetContent()
		If '$IsObject(payload) {
			$$$ThrowGeneral("payload is empty")
		}
		If 'payload.%IsDefined("ids") {
			$$$ThrowGeneral("ids not found")
		}
		Set iter = payload.ids.%GetIterator()
		While iter.%GetNext(,.id) {
			Do ##Class(%ZQueue.DeadLetter).DeleteById(id)
		}
		Set response = ..GetStatusOk()
	;
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod CreateItem() As %Status
{
	Try {
		Set Queue = {}.%FromJSON(%request.Content)
		If '$IsObject(Queue) {
			$$$ThrowGeneral("payload is empty")
		}
		If '$IsObject(Queue) {
			$$$ThrowGeneral("Not a valid Json")
		}
		Set className = Queue.QueueInfo.ClassName
		If className'="" {
			If '##class(%Dictionary.ClassDefinition).%ExistsId(className) {
				Do ..SetStatusCode(..#HTTP422UNPROCESSABLEENTITY)
				Set response = ..GetErrorResponse("Class Not exist")
				Quit
			}
			Set methodName = Queue.QueueInfo.MethodName
			If '##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName) {
				Do ..SetStatusCode(..#HTTP422UNPROCESSABLEENTITY)
				Set response = ..GetErrorResponse("Method Not exist")
				Quit
			}
		}
		Else {
			Set routine = Queue.QueueInfo.RoutineName
			If '##class(%Routine).%ExistsId($Translate(routine,"^")) {
				Do ..SetStatusCode(..#HTTP422UNPROCESSABLEENTITY)
				Set response = ..GetErrorResponse("Routine Not exist")
				Quit
			}
		}
		Set status = ##class(%ZQueue.Queue).EnQueue(Queue, .QueueId)
		$$$ThrowOnError(status)
		Do ..SetStatusCode(200)
		Set response = {"status":"ok","message":("QueueId "_QueueId)}
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod StartQueue()
{
	Try {
		Do ##class(%ZQueue.Manager).Start()
		Set response = ..GetStatusOk()
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod StopQueue()
{
	Try {
		Do ##class(%ZQueue.Manager).Stop()
		Set response = ..GetStatusOk()
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

ClassMethod GetQueueStatus()
{
	Try {
		Set status = ##class(%ZQueue.Manager).IsQueueRunning()
		Set response = {"running":($Select(status:1,1:0))}
		 If status {
			Set response.pid = status
		 }
	}
	Catch ex {
		Set response = ..GetErrorResponse(..GetErrorText(ex))
		Do ..SetStatusCode(..#HTTP500INTERNALSERVERERROR)
	}
	Do ..WriteResponse(response)
	Return $$$OK
}

}
