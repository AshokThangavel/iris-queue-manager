Class %ZQueue.DeadLetter Extends (%Persistent, %JSON.Adaptor)
{

Parameter DEFAULTGLOBAL = "^ZQueue.DeadLetter";

Property QueueInfo As %ZQueue.QueueInfo [ SqlColumnNumber = 2 ];

Property Priority As %Integer [ SqlColumnNumber = 3 ];

Property GroupId As %String [ SqlColumnNumber = 4 ];

Property ErrorMsg As %String(MAXLEN = 1000) [ SqlColumnNumber = 5 ];

Property CreatedAt As %PosixTime [ InitialExpression = {##Class(%Library.PosixTime).CurrentTimeStamp()}, SqlColumnNumber = 6 ];

Index PriorityIdx On Priority;

ClassMethod InsertIntoDLQ(Queue As %ZQueue.QueueItem, PError As %String = "") As %Status
{
	Set deadLetterQueue  = ..%New()
	Set deadLetterQueue.QueueInfo = Queue.QueueInfo
	Set deadLetterQueue.GroupId = Queue.GroupId
	Set deadLetterQueue.Priority = Queue.Priority
	Set deadLetterQueue.ErrorMsg = PError
	Return deadLetterQueue.%Save()
}

ClassMethod MoveDLQToQueue(dlqId As %Integer)
{
	Set sc = $$$OK
    Set dlq = ##class(%ZQueue.DeadLetter).%OpenId(dlqId)
    If '$IsObject(dlq) {
	    Return 0
    }
    Do dlq.%JSONExportToString(.str)
    Set queuePayload = {}.%FromJSON(str)
    If queuePayload.%IsDefined("ErrorMsg") {
	    Do queuePayload.%Remove("ErrorMsg")
    }
    If queuePayload.%IsDefined("CreatedAt") {
	    Do queuePayload.%Remove("CreatedAt")
    }
    Tstart
    Set sc = ##class(%ZQueue.Queue).EnQueue(queuePayload)
    If $$$ISOK(sc) {
	    Kill dlq
        Do ##class(%ZQueue.DeadLetter).%DeleteId(dlqId)
        Tcommit
    } Else {
        Trollback
    }
    Return sc
}

ClassMethod DeleteById(pId) As %Status [ CodeMode = expression ]
{
..%DeleteId(pId)
}

ClassMethod MoveAllDLQToQueue() As %Status
{
	Set status = $$$OK
	Try {
		Set statement = ##class(%SQL.Statement).%ExecDirect(, "SELECT ID FROM %ZQueue.DeadLetter ORDER BY Priority ASC, ID DESC")
		While statement.%Next() {
			Do ..MoveDLQToQueue(statement.ID)
		}
	}
	Catch ex {
		Set status = ex.AsStatus()
	}
	Return status
}

Query GetAllDLQRecords() As %SQLQuery
{
	SELECT %NOLOCK ID,
	Priority,
	QueueInfo_ClassName As ClassName,
	QueueInfo_MethodName As MethodName,
	QueueInfo_RoutineName As exeRoutine,
	%ODBCOUT(CreatedAt) As CreatedAt,
	ErrorMsg FROM %ZQueue.DeadLetter ORDER BY Priority ASC, ID DESC
}

Storage Default
{
<Data name="DeadLetterDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>QueueInfo</Value>
</Value>
<Value name="3">
<Value>Priority</Value>
</Value>
<Value name="4">
<Value>GroupId</Value>
</Value>
<Value name="5">
<Value>ErrorMsg</Value>
</Value>
<Value name="6">
<Value>CreatedAt</Value>
</Value>
</Data>
<DataLocation>^ZQueue.DeadLetterD</DataLocation>
<DefaultData>DeadLetterDefaultData</DefaultData>
<IdLocation>^ZQueue.DeadLetterD</IdLocation>
<IndexLocation>^ZQueue.DeadLetterI</IndexLocation>
<StreamLocation>^ZQueue.DeadLetterS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
