Class %ZQueue.Queue Extends %ZQueue.Utils
{

ClassMethod EnQueue(pPayload, Output QueueId) As %Status
{
	Set status = 1
    Try {
	    Do ..VerifyPayload(pPayload)
	    $$$ThrowOnError(##class(%ZQueue.QueueItem).EnQueue(pPayload, .QueueId))
        $$$SignalQueue
    }
    Catch ex {
        Set status = ex.AsStatus()
    }
    Return status
}

ClassMethod BulkEnqueue(pBulkQueue As %DynamicArray) As %Status
{
    If '$IsObject(pBulkQueue)||'pBulkQueue.%IsA("%DynamicArray") {
	    Return $$$ERROR($$$GeneralError, "Input is not a JSON Array")
    }

    Tstart
    Try {
        Set tIter = pBulkQueue.%GetIterator()
        While tIter.%GetNext(, .queue) {
            $$$ThrowOnError(##class(%ZQueue.QueueItem).EnQueue(queue))
        }
        Tcommit
        $$$SignalQueue
        Return $$$OK

    } Catch ex {
        $$$TR
        Return ex.AsStatus()
    }
}

ClassMethod Put(pPayload) [ CodeMode = expression ]
{
..EnQueue(pPayload)
}

ClassMethod BulkPut(pBulkQueue) [ CodeMode = expression ]
{
..BulkEnqueue(pBulkQueue)
}

/// {"QueueInfo":{"ClassName":"zaxk.NewClass1","MethodName":"d","Args":{"test":"111"}},
/// "Status":0,"QueueCreated":"2026-02-12T18:43:14Z","MaxRetry":3,"CurrentRetry":0,"Priority":1}1
ClassMethod VerifyPayload(pPayload As %DynamicObject)
{
	If '$IsObject(pPayload) {
		$$$ThrowOnError($$$ERROR($$$GeneralError,"Not an Json object"))
	}
	If pPayload.%IsDefined("Status") {
		Set status  = pPayload.Status
		If '$IsValidNum(status,,-2,2){
			Set pPayload.Status=0
		}
	}
	Else {
		Set pPayload.Status = 0
	}
}

ClassMethod PutBackToQueue(id As %Integer) As %Status
{
    Tstart
    Try {
        Set item = ##class(%ZQueue.QueueItem).%OpenId(id)
        Tcommit
    }
    Catch ex {
        $$$TR
        // Standard Retry Logic...
    }
    Return 1
}

ClassMethod PutBackFailedQueue()
{
	Set query = ##class(%ZQueue.QueueItem).GetFailedQueuesFunc()
	While query.%Next() {
		Do ..PutBackToQueue()
	}
}

ClassMethod PutBackDeadLetterQueues(pId As %String = "")
{
	If pId'="" {
		Return ..PutBackToQueue()
	}

	Set query = ##class(%ZQueue.QueueItem).GetFailedQueuesFunc()
	While query.%Next() {
		Do ..PutBackToQueue()
	}
}

ClassMethod GetFailedQueues()
{
	Return ##class(%ZQueue.QueueItem).GetFailedQueuesFunc()
}

}
