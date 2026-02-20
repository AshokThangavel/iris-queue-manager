Include %ZQueue

Class %ZQueue.QueueItem Extends (%Persistent, %JSON.Adaptor)
{

Parameter DEFAULTGLOBAL = "^ZQueue.Queue";

Parameter %JSONIGNOREINVALIDFIELD As BOOLEAN = 1;

Parameter %JSONNULL As BOOLEAN = 1;

Property QueueInfo As %ZQueue.QueueInfo [ SqlColumnNumber = 2 ];

Property Status As %Integer(DISPLAYLIST = ",DeadLetter,Completed,Pending,InProgress,Retrying", VALUELIST = ",-2,-1,0,1,2") [ InitialExpression = 0, SqlColumnNumber = 3 ];

Property QueueCreated As %PosixTime(%JSONINCLUDE = "NONE") [ InitialExpression = {##Class(%Library.PosixTime).CurrentTimeStamp()}, SqlColumnNumber = 4 ];

Property MaxRetry As %Integer(%JSONINCLUDE = "NONE") [ InitialExpression = 8 ];

Property CurrentRetry As %Integer(%JSONINCLUDE = "NONE") [ InitialExpression = 0 ];

Property LastError As %String(%JSONINCLUDE = "OUTPUTONLY", MAXLEN = 500);

Property Priority As %Integer [ InitialExpression = 1, SqlColumnNumber = 5 ];

Property Error As %String(%JSONINCLUDE = "OUTPUTONLY", MAXLEN = "");

Property NextRunTime As %PosixTime(%JSONINCLUDE = "NONE") [ SqlColumnNumber = 6 ];

Property GroupId As %String(MAXLEN = 100);

Index GroupIndex On GroupId;

Index PriorityIdx On Priority;

Index NextRunIndex On NextRunTime;

ClassMethod EnQueue(pPayload As %DynamicObject, Output pQueueId) As %Status
{
	Set tSC = $$$OK
    Try {
        Set queueObj = ..%New()
        Set sc = queueObj.%JSONImport(pPayload)
        $$$ThrowOnError(queueObj.%Save())
        Set queueId = queueObj.%Id()

        // Write to the "Reading List" (The Flight Strip)
        Tstart
        Set seq = $Increment($$$DispatchQueue)
        Set $$$DispatchQueue(queueObj.Priority, seq) = $ListBuild(queueId, queueObj.GroupId)
        Set pQueueId = queueId
        Tcommit
    }
    Catch ex {
        Set tSC = ex.AsStatus()
    }
    Return tSC
}

Method SetNextExecTime()
{
	Set ..NextRunTime = ..FetchNextRunTime()
}

/// Returns the next retry timestamp for Failed queues
Method FetchNextRunTime() As %TimeStamp
{
    If ..CurrentRetry >= ..MaxRetry {
        Return ""
    }
    Set delayInMSeconds = (..GetNextRetryDelay() * 60) * 1e6
    Set nextRunTime = $$$CurrentIRISPosix+delayInMSeconds
   	Return nextRunTime
}

Method GetNextRetryDelay() [ Final, Private ]
{
	#; Defined buckets (in minutes)
	Set delays = $ListBuild($ListBuild(2,3),$ListBuild(5,10),$ListBuild(15,30),$ListBuild(45,60),$ListBuild(60,180),$ListBuild(180,300),$ListBuild(300,600),$ListBuild(600,1440))
	Set currentRetry = ..CurrentRetry
	If (currentRetry < 1) Set currentRetry = 1

	Set time = $ListGet(delays,currentRetry)
	Set min = $ListGet(time)
	Set max = $ListGet(time,2)
	Set minTime = $Random(min)

	Set diff = max - min + 1
    Set finalDelay = min + $Random(diff)

    Return finalDelay
}

Method IncrementRetry()
{
	Set ..CurrentRetry = ..CurrentRetry+1
}

Method IsExceddedRetry() [ CodeMode = expression ]
{
..CurrentRetry >= ..MaxRetry
}

ClassMethod IsItemInQueue() As %Integer
{
	&SQL(SELECT COUNT(*) INTO :count FROM (SELECT TOP 56 ID FROM %ZQueue.QueueItem WHERE Status = 0))
	Return $Get(count,0)
}

ClassMethod MoveToDispatch(queueId As %Integer, priority As %Integer, GroupId As %String)
{
	Set seq = $Increment($$$DispatchQueue)
    Set $$$DispatchQueue(priority, seq) = $ListBuild(queueId, GroupId)
    &sql(UPDATE %ZQueue.QueueItem SET Status = 0 WHERE ID = :queueId)
    Return 'SQLCODE
}

ClassMethod GetNextQueueItem()
{
	Set queueDispath = $Name($$$DispatchQueue)
	Set priority = ""
	For {
		Set priority = $Order(@queueDispath@(priority)) Quit:priority=""

		Set seq = ""
		For {
		    Set seq = $Order(@queueDispath@(priority, seq), 1, tData) Quit:seq=""
		    Lock +@queueDispath@(priority, seq):0
		    Continue:'$Test

		    Set tQueueId = $ListGet(tData, 1)
		    Set tGroupId = $ListGet(tData, 2)

		    // need to handle group


		    // No gorup items
		    Continue:'$Data(@queueDispath@(priority, seq))
		    Tstart
	        Kill @queueDispath@(priority, seq)
	        Lock -@queueDispath@(priority, seq)
	        Tcommit
	        &SQL(UPDATE %ZQUEUE.QUEUEITEM SET Status=1 WHERE ID=:tQueueId)
	        Return tQueueId

		}
	}
	Return ""
}

Query GetAllQueueItems() As %SQLQuery
{
	SELECT %NOLOCK
		ID As queueId,
		Priority,CurrentRetry,
		QueueInfo_ClassName As ClassName,
		QueueInfo_MethodName As MethodName,
		QueueInfo_RoutineName As exeRoutine,
		%ODBCOUT(NextRunTime) As NextRunTime,
		Status,
		LastError
	FROM %ZQueue.QueueItem
}

Storage Default
{
<Data name="QueueItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>QueueInfo</Value>
</Value>
<Value name="3">
<Value>Status</Value>
</Value>
<Value name="4">
<Value>QueueCreated</Value>
</Value>
<Value name="5">
<Value>MaxRetry</Value>
</Value>
<Value name="6">
<Value>CurrentRetry</Value>
</Value>
<Value name="7">
<Value>LastError</Value>
</Value>
<Value name="8">
<Value>Priority</Value>
</Value>
<Value name="9">
<Value>Error</Value>
</Value>
<Value name="10">
<Value>NextRunTime</Value>
</Value>
<Value name="11">
<Value>GroupId</Value>
</Value>
</Data>
<DataLocation>^ZQueue.QueueD</DataLocation>
<DefaultData>QueueItemDefaultData</DefaultData>
<IdLocation>^ZQueue.QueueD</IdLocation>
<IndexLocation>^ZQueue.QueueI</IndexLocation>
<StreamLocation>^ZQueue.QueueS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
