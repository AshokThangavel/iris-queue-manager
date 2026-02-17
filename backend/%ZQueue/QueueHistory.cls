Include %ZQueue

Class %ZQueue.QueueHistory Extends (%Persistent, %JSON.Adaptor)
{

Parameter DEFAULTGLOBAL = "^ZQueue.QueueHistory";

Property OriginalID As %Integer [ SqlColumnNumber = 2 ];

Property QueueInfo As %ZQueue.QueueInfo;

Property CompletionTime As %PosixTime [ InitialExpression = {##Class(%Library.PosixTime).CurrentTimeStamp()}, SqlColumnNumber = 3 ];

Property ExecutionTime As %Integer;

ClassMethod StoreIntoHistory(Queue As %ZQueue.QueueItem, QueueStartTime)
{
	Set queuehistObj = ..%New()
	Set queuehistObj.OriginalID = Queue.%Id()
	Set queuehistObj.QueueInfo = Queue.QueueInfo
	Set queuehistObj.ExecutionTime = (queuehistObj.CompletionTime - QueueStartTime)/1e6
	Return queuehistObj.%Save()
}

ClassMethod DeleteById(pId As %Integer) [ CodeMode = expression ]
{
..%DeleteId(pId)
}

/// Beaware before executing this method
/// Not recommended to run
ClassMethod DeleteAllRecords(pId As %Integer) [ Internal ]
{
	&SQL(TRUNCATE TABLE %ZQueue.QueueHistory)
	Return 'SQLCODE
}

ClassMethod PurgeOldEntires()
{
	;&SQL(DELETE %ZQueue.QueueHistory WHERE CompletionTime=1)
}

ClassMethod SetHistoryRetainDaysLimit(pNumberOfDays As %Integer = 30)
{
	Set $$$QueueHistory=pNumberOfDays
}

ClassMethod GetHistoryRetainDaysLimit() [ CodeMode = expression ]
{
$$$QueueHistory
}

Storage Default
{
<Data name="QueueHistoryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>OriginalID</Value>
</Value>
<Value name="3">
<Value>QueueInfo</Value>
</Value>
<Value name="4">
<Value>CompletionTime</Value>
</Value>
<Value name="5">
<Value>ExecutionTime</Value>
</Value>
</Data>
<DataLocation>^ZQueue.QueueHistoryD</DataLocation>
<DefaultData>QueueHistoryDefaultData</DefaultData>
<IdLocation>^ZQueue.QueueHistoryD</IdLocation>
<IndexLocation>^ZQueue.QueueHistoryI</IndexLocation>
<StreamLocation>^ZQueue.QueueHistoryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
