ROUTINE %ZQueue [Type=INC]
#;
#Define MasterQueueId									^ZQueue.Queue("MasterPID")
#Define QueueControlStop								^ZQueue.Control("Stop")
#Define QueueHistory									^ZQueue.Control("History")
#Define QueueLog										^ZQueue.EventLog
#Define DispatchQueue									^ZQueue.Dispatch
#Define RetryQueue										^ZQueue.Retry
#Define QueueEvent										"ZQueue"

#Define SecondsDiff(%now)								$SYSTEM.SQL.Functions.DATEDIFF("ss", $NOW(), %now)
 // both returns same
#Define PosixTime										$ZDateTime($now(), -2)
#Define EpochTime										##class(%UTC).SecondsSinceUnixEpoch()
#Define CurrentIRISPosix								##Class(%Library.PosixTime).CurrentTimeStamp()
#Define IRISPosixToH(%irisposix)						##Class(%Library.PosixTime).LogicalToOdbc(%irisposix)

#Define PosixToH(%posix)								$ZDateTimeH(%posix,-2)
#Define PosixToDT(%posix)								$ZDateTime($ZDateTimeH(%posix,-2))
#Define PosixToODBC(%posix)								$ZDateTime($ZDateTimeH(%posix,-2),3)
#Define PosixToZULU(%posix)								$ZDateTime($ZDateTimeH(%posix,-2),3,7)

#Define SecDiff(%from,%to)								$SYSTEM.SQL.Functions.DATEDIFF("ss",%from,%to)

#Define SignalQueue										Do $System.Event.Signal($$$QueueEvent)
#Define	LogActivity(%queueid,%action,%subaction,%details)	Do ##class(%ZQueue.Utils).LogQueueItemActivity(%queueid,%action,%subaction,%details)
#Define	LogQueueActivity(%action,%subaction,%details)	Do ##class(%ZQueue.Utils).LogActivity(%action,%subaction,%details)

#Define TR1												TRollback 1
#Define TR												TRollback

#Define EventCreate										Do $System.Event.Create($$$QueueEvent)
#Define EventWait(%timeout)								Do $System.Event.Wait($$$QueueEvent, %timeout)
#Define	DefaultTimeout									-1
