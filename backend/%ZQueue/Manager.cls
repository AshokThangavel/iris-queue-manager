Include %ZQueue

Class %ZQueue.Manager Extends %RegisteredObject
{

ClassMethod Start() As %Integer
{
	$$$LogQueueActivity("Start", "Initiated",$ListBuild($ZDatetime($Horolog,3)))
    If ..CheckIsQueueAlreadyRunning() {
        $$$LogQueueActivity("Start", "Abort", $ListBuild("Already Running"))
        Return 0
    }
	Kill $$$QueueControlStop
    Job ##class(%ZQueue.Manager).StartListenQueue()::10
    Set tPID = $ZChild
    If '$Test {
        $$$LogQueueActivity("Start", "Error", $ListBuild("Job Command Failed"))
        Return 0
    }
    Tstart
    Set $$$MasterQueueId = $ListBuild(tPID, $ZDatetime($Now()), $Username)
    Tcommit
    $$$LogQueueActivity("Start", "JobCreated", $ListBuild(tPID, $ZDatetime($Now()), $Username))
    Return tPID
}

ClassMethod SetHistoryRetainDaysLimit(pNumberOfDays As %Integer = 30)
{

	Do ##class(%ZQueue.QueueHistory).SetHistoryRetainDaysLimit(pNumberOfDays)
}

ClassMethod Stop(PurgeEventLog As %Boolean = 0) As %Status
{
	Set status = $$$OK
	Try {

		If '..IsQueueRunning() {
			Set status = $$$ERROR($$$GeneralError,"No Active Master Queue is running")
			Quit
		}
		Tstart
		Set $$$QueueControlStop = 1
		$$$SignalQueue
		$$$LogQueueActivity("Stop","Initiated", $ListBuild($ZDatetime($Horolog,3)))
	    Hang 2
	    If $Data($$$MasterQueueId,data) {
	   		Set status =  ##class(%SYSTEM.Process).Terminate($ListGet(data))
	   		$$$LogQueueActivity("Stop","TerminateProcess",$ListBuild(data,status))
	    	If status {
	    		Kill $$$MasterQueueId
	    	}
	    }
	    Else {
		    Set status = $$$ERROR($$$GeneralError,"No Active Master Queue is running")
	        $$$LogQueueActivity("Stop","StopError", $ListBuild("ProcessNotFound", status))
	    }
	    Kill $$$QueueControlStop
	    If PurgeEventLog {
		    Do ##class(%ZQueue.Utils).ClearAllActivityLog()
		    $$$LogQueueActivity("Stop","Purge", $ListBuild("EventLog"))
	    }
	    Tcommit
	}
	Catch ex {
		$$$TR
	}
    Return status
}

/// 0 - No running queue
/// otherwise running process id
ClassMethod IsQueueRunning() As %Integer [ CodeMode = expression ]
{
+..CheckIsQueueAlreadyRunning()
}

ClassMethod StartIfNotRunning()
{
	If '..IsQueueRunning() {
		Return ..Start()
	}
	Return 0
}

ClassMethod SetState(state As %String)
{
	Set status = 1
	Set state = $$$lcase(state)
    If (state = "STOP") {
        Set status = ..Stop()
    }
    ElseIf (state = "START") {
       Set status = ..Start()
    }
    Return status
}

ClassMethod EnableQueueLog(pLogLevel = 1)
{
	Set $$$QueueLog = pLogLevel
}

ClassMethod DisableQueueLog()
{
	Set $$$QueueLog = 0
}

ClassMethod CheckIsQueueAlreadyRunning() As %Boolean
{
	If '$Data($$$MasterQueueId,data) {
		Quit 0
	}
    Set pid = $ListGet(data)
    If pid = "" {
	    Return 0
    }
    New $Namespace
    Set $Namespace = "%SYS"
    If '##Class(SYS.Process).%ExistsId(pid) {
		Set pid = 0
	    Kill $$$MasterQueueId
    }

    Return pid
}

/// {"MaxActiveWorkers":"0","DefaultWorkers":"0","MaxWorkers":"0","Category":"ZQueue"}
ClassMethod ManageWQMCategory(pWQMCategory As %DynamicObject)
{
	New $Namespace
	Set $Namespace = "%SYS"
	If '$IsObject(pWQMCategory){
		Return 0
	}
	If pWQMCategory.Category'="ZQueue" {
		Return 0
	}
	Set Properties("MaxActiveWorkers")=pWQMCategory.MaxActiveWorkers
	Set Properties("DefaultWorkers")=pWQMCategory.DefaultWorkers
	Set Properties("MaxWorkers")=pWQMCategory.MaxWorkers

	If '##class(Config.WorkQueues).%ExistsId(pWQMCategory.Category) {
		Set tSC = ##class(Config.WorkQueues).Create(pWQMCategory.Category,.Properties)
	}
	Else {
		Set tSC = ##class(Config.WorkQueues).Modify(pWQMCategory.Category,.Properties)
	}
	Return tSC
}

ClassMethod CreateWQMCategory()
{
	Set json = {"MaxActiveWorkers":0,"DefaultWorkers":0,"MaxWorkers":0,"Category":"ZQueue"}
	Return ..ManageWQMCategory(json)
}

ClassMethod StartListenQueue()
{
	Try{
		$$$EventCreate
		Set wqm = ##class(%SYSTEM.WorkMgr).%New(,,$$$QueueEvent)
		For {
			Set timeout = $$$DefaultTimeout
			If $Data($$$QueueControlStop,isStop) {
				If isStop {
					Return 1
				}
			}

			Do ##class(%ZQueue.Worker).ProcessRetries()
			Set count = ##class(%ZQueue.QueueItem).IsItemInQueue()
			If count {
				Set tNeededWorkers = $Select(count > 50: 56, 1: count)
	    		For i=1:1:tNeededWorkers {
	        		Do wqm.Queue("##class(%ZQueue.Worker).ProcessNext")
	    		}
			}
			Else {
				Set timeout=-1
			}
			Set tNextRetry = $Order($$$RetryQueue(""))

			If tNextRetry'="" {
				Set diffSeconds = (tNextRetry - $$$CurrentIRISPosix) \ 1e6
				If diffSeconds <= 0 {
		            Set timeout = 0
		        } Else {
		            Set timeout = diffSeconds
		        }
			}
	    	$$$EventWait(timeout)
		}
	}
	Catch ex {
		$$$LogQueueActivity("QueueListen", "Error", $ListBuild(ex.BinDisplayString()))
	}
}

}
