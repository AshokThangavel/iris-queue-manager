Include %ZQueue

Class %ZQueue.Worker Extends %RegisteredObject
{

// Flight Strip (Dispatcher) Pattern

ClassMethod ProcessNext()
{
	For {
		If $Get($$$QueueControlStop) {
	    	Quit
		}

	    Set queueId = ##class(%ZQueue.QueueItem).GetNextQueueItem()
	    If (queueId="") {
		    $$$LogActivity(0,"queuid","no queueid",$ListBuild($Now()))
		    Quit
	    }
	    Try {
		    $$$LogActivity(queueId,"queuid","start",$ListBuild($Now()))
            Do ..RunQueue(queueId)
            $$$LogActivity(queueId,"queuid","end",$ListBuild($Now()))
            ; update the status
        }
        Catch ex {
            ; update failed status on the queueId
            $$$LogActivity(queueId,"ProcessNext","Err",$ListBuild(ex.%BinDisplayString()))
        }
	}
	Quit 1
}

ClassMethod RunQueue(QueueId As %Integer = 1)
{
	Set start = $$$CurrentIRISPosix
	Try {

		$$$LogActivity(QueueId,"RunQueue","Run",$ListBuild($Now()))

		Set queue = ##class(%ZQueue.QueueItem).%OpenId(QueueId,,.sc)
		If $$$ISERR(sc)||('$IsObject(queue)) {
			$$$LogActivity(QueueId,"Execute","Invalid QueueId",$ListBuild($Now()))
			$$$ThrowOnError(sc)
		}
		$$$LogActivity(QueueId,"RunQueue","ExecuteItem",$ListBuild($Now()))
		Do ..ExecuteItem(queue)
		Set status = ..LogHistory(queue, start)
		// If we got here, it succeeded!
		Kill queue
        Do ##class(%ZQueue.QueueItem).%DeleteId(QueueId) // Remove from active queue
	}
	Catch ex {
		Set ex = ex.AsStatus()
		Set error = $System.Status.GetErrorText(ex)
		$$$LogActivity(QueueId,"RunQueue","Error",$ListBuild(error))
		Kill queue
		Do ..ChangeQueueStatus(QueueId, error)

	}
	Return $$$OK
}

ClassMethod ChangeQueueStatus(QueueId As %Integer, ErrorMsg As %String = "")
{
	Set errQueue = ##class(%ZQueue.QueueItem).%OpenId(QueueId)
	If '$IsObject(errQueue) {
		Quit 0
	}

    Set errQueue.LastError = ErrorMsg
    Do errQueue.IncrementRetry()

    If 'errQueue.IsExceddedRetry() {
        Do ..SetToRetry(errQueue)
        Set sc = errQueue.%Save()
    }
    Else {
        $$$LogActivity(errQueue.%Id(),"Limit","Reaches Exceeded limit",$ListBuild($Now()))
        Set status = ..MoveToDeadLetter(errQueue, ErrorMsg)
        If $$$ISOK(status) {
            Set id = errQueue.%Id()
            Kill errQueue
            Do ##class(%ZQueue.QueueItem).%DeleteId(QueueId)
            $$$LogActivity(id,"DeadLetterQueue","Removed from QueueItem",$ListBuild($Now()))
        }
    }
}

ClassMethod ExecuteItem(Queue As %ZQueue.QueueItem)
{
	Set clsName = Queue.QueueInfo.ClassName
	Set routine = Queue.QueueInfo.RoutineName
	If clsName=""&&(routine="") {
		$$$LogActivity(Queue.%Id(),"Execute","Exection details not there",$ListBuild($Now()))
		$$$ThrowStatus($$$ERROR($$$ClassNameRequired))
	}

	If clsName'="" {
		Set methodName = Queue.QueueInfo.MethodName
		If methodName="" {
			$$$ThrowStatus($$$ERROR($$$MethodNameRequired))
		}

		Set argList=""
		While 1 {
	        Do Queue.QueueInfo.Args.GetNext(.key)
	        Quit:key=""
	        Set @key = Queue.QueueInfo.Args.GetAt(key)
	        Set argList = argList _ $Select(argList="":"", 1:",") _ key
    	}
		;Merge args = Queue.QueueInfo.Args
		$$$LogActivity(Queue.%Id(),"Start","Class",$ListBuild(clsName,methodName))
		Set cmd = $$$FormatText("Do ##class(%1).%2(%3)",clsName,methodName,argList)
		Xecute cmd
	}
	Else {
		$$$LogActivity(Queue.%Id(),"Start","Routine",$ListBuild(routine))

		//Variable setup
		While 1 {
	        Do Queue.QueueInfo.InitialVariables.GetNext(.key)
	        Quit:key=""
	        Set @key = Queue.QueueInfo.InitialVariables.GetAt(key)
    	}

		Set argList=""
		While 1 {
	        Do Queue.QueueInfo.Args.GetNext(.key)
	        Quit:key=""
	        Set @key = Queue.QueueInfo.Args.GetAt(key)

	        Set argList = argList _ $Select(argList="":"", 1:",") _ key
    	}
		If routine["$$" {
			If argList'=""{
				Set cmd = "s sc="_routine_"("_argList_")"
			}
			Else {
				Set cmd = "s sc="_routine_"()"
			}
		}
		ElseIf routine["^" {
			If argList'=""{
				Set cmd = "d "_routine_"("_argList_")"
			}
			Else {
				Set cmd = "d "_routine_"()"
			}
		}
		Else {
			Set cmd = "do ^"_routine
		}
		If cmd'="" {
			Xecute cmd
		}
	}
}

ClassMethod ProcessRetries() [ Internal ]
{
    Try {
    	Set time=""
        For {
            Set time = $Order($$$RetryQueue(time)) Quit:(time = "")||(time > $$$CurrentIRISPosix)
            Set priority = ""
            For {
                Set priority = $Order($$$RetryQueue(time, priority)) Quit:priority=""
                Set queueId = ""
                For {
                    Set queueId = $Order($$$RetryQueue(time, priority, queueId),1,tData) Quit:queueId=""
                    Set tGroupId = $ListGet(tData, 1)
                    Try {
	                    Tstart
                    	If ##class(%ZQueue.QueueItem).MoveToDispatch(queueId,priority,tGroupId) {
	                   	 	Kill $$$RetryQueue(time, priority,queueId)
                   	 	}
                   	 	Tcommit
                    }
                    Catch ex {
	                    $$$TR
                    }
                }
            }
        }
    } Catch ex{
        $$$LogActivity(0,"ProcessRetries", "Anchor", "ProcessRetries Failed")
    }
}

ClassMethod SetToRetry(Queue As %ZQueue.QueueItem)
{
	$$$LogActivity(Queue.%Id(),"Retry","Schedule retry",$ListBuild($Now()))
	Do Queue.SetNextExecTime()
	Set Queue.Status = 2
	Set $$$RetryQueue(Queue.NextRunTime, Queue.Priority,Queue.%Id())=$ListBuild(Queue.GroupId)
}

ClassMethod MoveToDeadLetter(Queue As %ZQueue.QueueItem, Exception As %Exception.StatusException) As %Status
{
	$$$LogActivity(Queue.%Id(),"DeadLetter","Moved to DeadLetter",$ListBuild($Now()))
	Return ##class(%ZQueue.DeadLetter).InsertIntoDLQ(Queue,Exception)
}

ClassMethod LogHistory(Queue As %ZQueue.QueueItem, QueryStartTime)
{
	$$$LogActivity(Queue.%Id(),"History","LogHistory",$ListBuild($Now()))
	Do Queue.SetNextExecTime()
	Set Queue.Status = 2
	Return ##class(%ZQueue.QueueHistory).StoreIntoHistory(Queue, QueryStartTime)
}

}
