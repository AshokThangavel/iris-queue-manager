Class %ZQueue.QueueInfo Extends (%SerialObject, %JSON.Adaptor)
{

Property ClassName As %String(MAXLEN = 500) [ SqlColumnNumber = 2 ];

Property MethodName As %String(MAXLEN = 500) [ SqlColumnNumber = 3 ];

Property Args As array Of %String;

Property RoutineName As %String [ SqlColumnNumber = 4 ];

Property InitialVariables As array Of %String;

Storage Default
{
<Data name="QueueInfoState">
<Value name="1">
<Value>ClassName</Value>
</Value>
<Value name="2">
<Value>MethodName</Value>
</Value>
<Value name="3">
<Value>Args</Value>
</Value>
<Value name="4">
<Value>RoutineName</Value>
</Value>
<Value name="5">
<Value>InitialVariables</Value>
</Value>
</Data>
<State>QueueInfoState</State>
<StreamLocation>^%ZQueue.QueueInfoS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
