Include %ZQueue

Class %ZQueue.Utils [ Abstract ]
{

ClassMethod LogActivity(pAction As %String, pSubAction As %String, pDetails As %List = "")
{
    Set tNow = $ZDatetime($Horolog, 3)
    Set tCount = $Increment($$$QueueLog(pAction, pSubAction))
    Set $$$QueueLog(pAction, pSubAction, tCount) = $ListBuild(tNow, $Job, pDetails)
}

ClassMethod LogQueueItemActivity(pQueueId, pAction As %String, pSubAction As %String, pDetails As %List = "")
{
	Set tNow = $ZDatetime($Horolog, 3)
    Set tCount = $Increment($$$QueueLog(pQueueId,pAction, pSubAction))
    Set $$$QueueLog(pQueueId,pAction, pSubAction, tCount) = $ListBuild(tNow, $Job, pDetails)
}

ClassMethod ClearAllActivityLog()
{
	Kill $$$QueueLog
}

}
