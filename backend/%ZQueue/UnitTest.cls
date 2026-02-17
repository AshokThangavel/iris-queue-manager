Class %ZQueue.UnitTest Extends %RegisteredObject
{

ClassMethod TestSingleQueue() [ Internal ]
{
	Set payload = {"QueueInfo":{ "ClassName":"zaxk.NewClass1","MethodName":"d","Args":{"test":"111"}},"Priority":4}
	Set status = ##class(%ZQueue.Queue).EnQueue(payload)
}

ClassMethod TestParameterValues(p1, args...) [ Internal ]
{
	Set ^IRIS.Temp("p1") =p1
    Merge ^IRIS.Temp("args")=args
    Return 1
}

ClassMethod TestBulkEnqueue() [ Internal ]
{
	Set bulkQueue=[]
	For i=1:1:5 {
		Do bulkQueue.%Push({"QueueInfo":{ "ClassName":"Sample.NewClass1","MethodName":"TestMethod","Args":{"test":"111"}},"Priority":1})
        Do bulkQueue.%Push({"QueueInfo":{ "ClassName":"%ZQueue.UnitTest","MethodName":"TestSingleQueue"},"Priority":5})
	}

	Return ##class(%ZQueue.Queue).BulkEnqueue(bulkQueue)
}

}
