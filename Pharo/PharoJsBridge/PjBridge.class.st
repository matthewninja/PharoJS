"
A PjBridge is the facade that allows interacting (i.e. evaluting code) with a javascript interpreter. 

Example: 
""1) Start a bridge in a workspace""
bridge := PjBridge startOn: 12345.

""2) Open a web browser on http://localhost:12345""

""3) Perform in the workspace the following expressions one at a time. Use 'printIt' to display results. Watch the log on the web browser to see the  javascript code actually peformed.""
bridge eval: '1+2'.
bridge eval: 'x := 6 * 7'.
bridge eval: 'x - 5'.
bridge loadClass: PjCounter.
bridge eval: 'counter := PjCounter new.
counter increment.
counter increment.
counter increment.
counter count.'. 

""4) Once done, don't forget to stop the bridge""
bridge stop.

Instance Variables
	clientClassName:		<String>
	communicationTrialsCount:		<Integer>
	converter:		<PjSmalltalkToJavaScriptConverer>
	server:		<PjServer>

clientClassName
	- Name of the class of the socket wrapper running on the JavaScript client (e.g. PjEvaluatorWebSocketDelegate)

communicationTrialsCount
	- Number of attempts to send/receive data through the webSocket

converter
	- Smalltalk to JavaScript converter. Used to translate Smalltalk code to JavaScript before evaluating it on the client (see #eval: and #loadClass:)

server
	- Manages client connections including the websocket

"
Class {
	#name : #PjBridge,
	#superclass : #Object,
	#instVars : [
		'server',
		'communicationTrialsCount',
		'result',
		'timeout',
		'callbacks',
		'executingCallbacks',
		'proxies',
		'blockClosures',
		'client',
		'runOnPharo',
		'shouldStartJsInterpreter'
	],
	#category : #'PharoJsBridge-Kernel'
}

{ #category : #'bridge handling' }
PjBridge class >> bridge [
	^ PjProxyLocalBridge value
	" the following is a hack to make debugging workable if there is only 1 bridge in existence "
		ifNil: [ | instances |
			instances := self allInstances select: #isServerStarted.
			instances size = 1 ifTrue: [ instances first ] ifFalse: [ nil ]
		]
]

{ #category : #'bridge handling' }
PjBridge class >> bridge: aBridge [
	PjProxyLocalBridge value: aBridge
]

{ #category : #'instance creation' }
PjBridge class >> bridgeForAppClass: appClass [
	^ self bridgeForAppClass: appClass client: appClass newBridgeClient
]

{ #category : #'instance creation' }
PjBridge class >> bridgeForAppClass: appClass client: bridgeClient [
	^ self new
			client: bridgeClient;
			appClass: appClass;
			yourself
]

{ #category : #accessing }
PjBridge class >> debugClass [
	^ self
]

{ #category : #accessing }
PjBridge class >> defaultApp [
	^PjWebApplication
]

{ #category : #accessing }
PjBridge class >> defaultClientClass [
	^self defaultApp bridgeClientClass
]

{ #category : #'instance creation' }
PjBridge class >> openOn: portNumber title: title [
	^ self new
		openOn: portNumber title: title;
		yourself
]

{ #category : #'closure handling' }
PjBridge class >> pollFor: aTime orUntil: aBlock [
	^ self bridge pollFor: aTime orUntil: aBlock
]

{ #category : #'instance creation' }
PjBridge class >> startOn: portNumber title: title [
	^  (self bridgeForAppClass: self defaultApp)
		startOn: portNumber title: title;
		yourself
]

{ #category : #'bridge handling' }
PjBridge class >> stop [
	self bridge ifNotNil: [ self bridge stop . self bridge: nil.Smalltalk garbageCollect]
]

{ #category : #accessing }
PjBridge >> appClass: aPharoJsAppClass [
	self client appClass: aPharoJsAppClass.
	self client bridge: self.

]

{ #category : #public }
PjBridge >> asyncEval: smalltalkString withResultDo: singleArgBlock [
	| javaScriptString |
	javaScriptString := self convertToJs: smalltalkString.
	self asyncEvalJavascript: javaScriptString withResultDo: singleArgBlock
]

{ #category : #public }
PjBridge >> asyncEvalJavascript: javaScriptString withResultDo: singleArgBlock [
	self sendMessage: javaScriptString.
	[
	self 
		when: [self isSyncDataAvailable] 
		do: [self handOffResult: singleArgBlock] 
		onTimeOutDo: [ ^ PjJavascriptError signal: 'Time Out! No response received' ]
		timeOutDuration: self timeout.
	] fork.

]

{ #category : #'closure handling' }
PjBridge >> blockClosure: aBlockClosure [
	^ self blockClosures at: aBlockClosure ifAbsentPut: [
		| proxy thisArg |
		(aBlockClosure isKindOf: BlockClosure) ifFalse: [
				^ PjJavascriptError signal: 'Must be a BlockClosure' ].
		aBlockClosure hasMethodReturn ifTrue: [
				^ PjJavascriptError signal: 'Block cannot have return' ].
		thisArg := aBlockClosure argumentNames findFirst: [ : name | name='this' ].
		proxy := self evalJavascript: self websocketDelegateClassName,
			'.', PjTranspiler pharoJsSelectorPrefix, 'default().', PjTranspiler pharoJsSelectorPrefix, 'makeBlockClosureProxy_(',thisArg asString,')'.
		proxy closure: aBlockClosure.
		proxy
	]
]

{ #category : #'closure handling' }
PjBridge >> blockClosures [
	^ blockClosures ifNil: [blockClosures := IdentityDictionary new]
]

{ #category : #accessing }
PjBridge >> client [
	^ client
]

{ #category : #accessing }
PjBridge >> client: aClient [
	client := aClient.
	client bridge: self.
]

{ #category : #'initialize-release' }
PjBridge >> clientTitle [
	^self client title
]

{ #category : #public }
PjBridge >> convertToJs: anObject [
	^self exporter convertToJs: anObject
]

{ #category : #accessing }
PjBridge >> defaultClientClass [
	^self class defaultClientClass
]

{ #category : #'initialize-release' }
PjBridge >> defaultCommunicationTrialsCount [
	^100
]

{ #category : #'closure handling' }
PjBridge >> deleteBlockClosure: aBlockClosure [
	self blockClosures removeKey: aBlockClosure ifAbsent: [  ]
]

{ #category : #'bridge handling' }
PjBridge >> deleteJsValue: jsName [
	"Called by proxy finalizer see methode PjProxy>>jsName:onBridge:"
	self proxies removeKey: jsName ifAbsent: [ ].
	self isServerStopped ifTrue: [ ^self ].
	self sendMessage: ':-',jsName.
	^ proxies
]

{ #category : #evaluating }
PjBridge >> disableWriteDnuDuring: aBlockClosure [ 
	^self transpiler disableWriteDnuDuring: aBlockClosure 
]

{ #category : #evaluating }
PjBridge >> dnuJsString [
	^self transpiler dnuJsString
]

{ #category : #public }
PjBridge >> ensureServerProcessAlive [
	self server ensureProcessAlive
]

{ #category : #public }
PjBridge >> evalBlock: aBlock [
	^self evalJavascript: (self convertToJs: aBlock asValuedBlock)

]

{ #category : #evaluating }
PjBridge >> evalGetResult [
	self
		when: [
			self isConnected ifFalse: [ ^ self ].
			self isSyncDataAvailable] 
		do: [self handOffResult: [ : val | ^ val ]]
		onTimeOutDo: [ ^ PjJavascriptError signal: 'no response after ',self timeout printString ]	
		timeOutDuration: self timeout
]

{ #category : #public }
PjBridge >> evalJavascript: javaScriptString [
	self isConnected ifFalse: [ ^ nil ].
	self sendMessage: javaScriptString.
	^ self evalGetResult
]

{ #category : #public }
PjBridge >> evalJavascriptWithDnuFrom: aBlock [
	| jsBlockCode jsDnuCode |
	jsBlockCode := self disableWriteDnuDuring: aBlock.
	jsDnuCode := self dnuJsString.
	^self evalJavascript: jsDnuCode, jsBlockCode

]

{ #category : #public }
PjBridge >> evalMessage: jsMessage [
	^self evalJavascriptWithDnuFrom: [self convertToJs: jsMessage].

]

{ #category : #public }
PjBridge >> evalMessage: aMessage sentTo: receiverName [
	| jsMessage |
	jsMessage := PjJavascriptMessage receiverId: receiverName selector: aMessage selector arguments: aMessage arguments.
	^self evalMessage: jsMessage

]

{ #category : #evaluating }
PjBridge >> evalResult: aString [
	self server logSocketRead: aString.
	^ self evalResult: aString parsed: (PjSTONReader from: aString)
]

{ #category : #evaluating }
PjBridge >> evalResult: aString parsed: value [
	value isLiteral ifTrue: [ ^ value ].
	value isNumber ifTrue: [ ^ value ].
	value at: #remove ifPresent: [ 
		| proxy |
		proxy := PjProxy nilOrProxyNamed: (value at: #proxy) asSymbol onBridge: self.
		proxy closure: nil.
		^ true ].
	value at: #proxy ifPresent: [ : name | | proxy |
		proxy := PjProxy nilOrProxyNamed: name asSymbol onBridge: self.
		^ proxy ].
	value at: #inspect ifPresent: [ : val |
		| proxy |
		proxy := self evalResult: aString parsed: val.
		self scheduleCallback: [proxy inspect].
		^ self ].
	value at: #cb ifPresent: [ : array |
		| proxy args |
		proxy := PjProxy proxyNamed: array first onBridge: self.
		args := array allButFirst collect: [ : each | self evalResult: aString parsed: each ].
		self scheduleCallback: [ proxy runBlockClosure: args first with: args second ].
		^ self ].
	value at: #keys ifPresent: [ : map |
		^ map collect: [ : val | self evalResult: aString parsed: val ] ].
	value at: #exception ifPresent: [: message | ^ [ PjJavascriptError signal: message ] ].
	^ [ PjJavascriptError signal: 'unrecognized response from browser:' , aString ]
]

{ #category : #evaluating }
PjBridge >> executeAnyCallbacks [
	executingCallbacks ifFalse: [
		callbacks isEmpty ifFalse: [ | savedResult |
			executingCallbacks := true.
			savedResult := result.
			result := self.
			[callbacks isEmpty] whileFalse: [
				callbacks removeFirst value
			].
			result := savedResult.
			executingCallbacks := false
	]]
]

{ #category : #accessing }
PjBridge >> exporter [
	^self client exporter
]

{ #category : #activity }
PjBridge >> handOffResult: aBlock [
	result ~~ self ifTrue: [ | temp |
		temp := result.
		result := self.
		temp isClosure ifTrue: [
			aBlock value: temp value
		] ifFalse: [
			aBlock value: temp
		]
	]
]

{ #category : #'initialize-release' }
PjBridge >> initialize [
	super initialize.
	executingCallbacks := false.
	runOnPharo := false.
	shouldStartJsInterpreter := true.
	callbacks := OrderedCollection new.
	self server: self serverClass new.
	self finalizationRegistry add: self executor:
		(ObjectFinalizer new
			receiver: self server;
			selector: #stop;
			yourself).
	communicationTrialsCount := self defaultCommunicationTrialsCount.
	result := self.

]

{ #category : #public }
PjBridge >> isConnected [
	self webSocket ifNil: [ ^false ].
	^self webSocket isConnected
]

{ #category : #activity }
PjBridge >> isDataAvailable [
	self isConnected ifFalse: [ ^false ].
	^self webSocket stream isDataAvailable
]

{ #category : #public }
PjBridge >> isListening [
	^self server isListening
]

{ #category : #public }
PjBridge >> isServerStarted [
	^self server isRunning
]

{ #category : #public }
PjBridge >> isServerStopped [
	^self isServerStarted not
]

{ #category : #evaluating }
PjBridge >> isSyncDataAvailable [
	[result == self and: [self isDataAvailable]] whileTrue: [
		result := self evalResult: (self webSocket readMessage).
	].
	self executeAnyCallbacks.
	^ result ~~ self
]

{ #category : #public }
PjBridge >> loadAllClasses: classes [
	| javaScriptClassesDefinition |
	javaScriptClassesDefinition := self exporter convertAllClassesToJs: classes.
	self evalJavascript: javaScriptClassesDefinition.
	^classes

]

{ #category : #public }
PjBridge >> loadClass: aClass [
	self loadAllClasses: {aClass}.
	^aClass
	
]

{ #category : #activity }
PjBridge >> minimumStepDuration [
	^ 25 milliSeconds
]

{ #category : #activity }
PjBridge >> openOn: portNumber [
	self openOn: portNumber title: 'PharoJS'
]

{ #category : #activity }
PjBridge >> openOn: portNumber test: aTestCase [
	^self openOn: portNumber title: (self titleForTest: aTestCase)
]

{ #category : #activity }
PjBridge >> openOn: portNumber title: title [
	| clientGenerator |
	clientGenerator := self client codeGenerator.
	title ifNotNil: [ clientGenerator titleString: title ].
	self port: portNumber
]

{ #category : #public }
PjBridge >> pollFor: aTime orUntil: aBlock [
	self
		when: [ aBlock value ifNotNil: [ : value | ^ value ] ifNil: [self isSyncDataAvailable]] 
		do: [ self handOffResult: []]
		onTimeOutDo: [ ^ aBlock value ]	
		timeOutDuration: aTime
]

{ #category : #accessing }
PjBridge >> port [
	^self server port
]

{ #category : #'initialize-release' }
PjBridge >> port: portNumber [
	self server port: portNumber
]

{ #category : #accessing }
PjBridge >> proxies [
	^ proxies ifNil: [proxies := WeakValueDictionary new]
]

{ #category : #public }
PjBridge >> resetClient [
	| oldWebSocket |
	oldWebSocket := self webSocket.
	self sendMessage: self websocketDelegateClassName, '.', PjTranspiler pharoJsSelectorPrefix, 'reload_(true)'.
	self resetProxies.
	self client reset.
	self 
		when: [self webSocket ~~ oldWebSocket] 
		do: [
			oldWebSocket close.
		] 
		onTimeOutDo: [
			self error: 'Client did NOT reconnect!']
		timeOutDuration: self client startTimeout.

]

{ #category : #'initialize-release' }
PjBridge >> resetProxies [
	proxies := nil.
	"Ensure that proxies are actually suppressed which lead to releasing the objects on the JS side"
	"This is achieved by calling BjBridge>>#cleanUpJsSide"
	Smalltalk garbageCollect. 

]

{ #category : #public }
PjBridge >> restart [
	self stop.
	self start
]

{ #category : #evaluating }
PjBridge >> scheduleCallback: aBlock [
	callbacks ifNil: [ callbacks := OrderedCollection new ].
	callbacks add: aBlock
]

{ #category : #activity }
PjBridge >> sendMessage: aString [
	self 
		when: [self isConnected] 
		do: [
			self webSocket sendMessage: aString.
			self server logSocketWritten: aString] 
		onTimeOutDo: [ self inform: 'WebSocket is NOT avaialble' ]
		timeOutDuration: 100 milliSeconds
]

{ #category : #accessing }
PjBridge >> server [
	^server
]

{ #category : #accessing }
PjBridge >> server: anObject [
	server := anObject
]

{ #category : #accessing }
PjBridge >> serverAddress [
	self shouldBeImplemented.
]

{ #category : #'initialize-release' }
PjBridge >> serverClass [
	^PjServer
]

{ #category : #accessing }
PjBridge >> serverUrl [
	^ self server url
]

{ #category : #accessing }
PjBridge >> serverUrl: aString [
	^ self server serverUrl: aString
]

{ #category : #accessing }
PjBridge >> serverUrlString [
	^ self server urlString
]

{ #category : #public }
PjBridge >> setExtraBindings: aDictionary [
	^self exporter setExtraBindings: aDictionary
]

{ #category : #accessing }
PjBridge >> shouldStartJsInterpreter [
	^ shouldStartJsInterpreter
]

{ #category : #accessing }
PjBridge >> shouldStartJsInterpreter: aBoolean [
	shouldStartJsInterpreter := aBoolean
]

{ #category : #public }
PjBridge >> start [
	self startWithoutWaitingForClient.
	self waitForClientToStart.

]

{ #category : #public }
PjBridge >> startJsInterpreter [
	self client startJsInterpreter.
	self waitForClientToStart.
]

{ #category : #activity }
PjBridge >> startOn: portNumber title: title [
	self openOn: portNumber title: title.
	self start
]

{ #category : #public }
PjBridge >> startWithoutWaitingForClient [
	self isServerStarted
		ifTrue: [ ^ self ].
	self server start.
	self waitForServerToStart.
	self client start
]

{ #category : #public }
PjBridge >> stop [
	self client stop.
	self stopServer.

]

{ #category : #activity }
PjBridge >> stopServer [
	self isServerStopped ifTrue: [ ^self ].
	self server stop.
	self waitForServerToStop 
]

{ #category : #public }
PjBridge >> terminateClient [
	self isConnected ifFalse: [ ^self ].  
	self client stop.
	self webSocket close.

]

{ #category : #evaluating }
PjBridge >> timeout [
	^ timeout ifNil: [ 10 seconds ]
]

{ #category : #evaluating }
PjBridge >> timeout: aDuration [
	timeout := (aDuration isKindOf: Duration) ifTrue: [ aDuration ] ifFalse: [ aDuration seconds ].
]

{ #category : #'initialize-release' }
PjBridge >> titleForTest: aTest [
	^ aTest className , '>>#' , aTest selector
]

{ #category : #accessing }
PjBridge >> transpiler [
	^self exporter transpiler
]

{ #category : #activity }
PjBridge >> waitForClientToStart [
	self waitForClientToStartFor: self client startTimeout
]

{ #category : #activity }
PjBridge >> waitForClientToStartFor: time [
	self 
		when: [self isConnected] 
		do: [^self] 
		onTimeOutDo: [self error: 'Javascript interpreter NOT available']
		timeOutDuration: time
]

{ #category : #activity }
PjBridge >> waitForClientToStartFor: time doing: aBlock [
	self 
		when: [aBlock value. self isConnected] 
		do: [^self] 
		onTimeOutDo: [self error: 'Javascript interpreter NOT available']
		timeOutDuration: time
]

{ #category : #activity }
PjBridge >> waitForServerToStart [
	self 
		when: [self isServerStarted] 
		do: [^self] 
		onTimeOutDo: [ self error: 'Server not ready' ]

]

{ #category : #activity }
PjBridge >> waitForServerToStop [
	self 
		when: [self isServerStopped] 
		do: [^self] 
		onTimeOutDo: [ self error: 'Server not stopped yet' ]

]

{ #category : #accessing }
PjBridge >> webSocket [
	^self server webSocket
]

{ #category : #accessing }
PjBridge >> webSocketUrlTag [
	^self server webSocketUrlTag
]

{ #category : #'initialize-release' }
PjBridge >> websocketDelegateClassName [
	^self client websocketDelegateClassName
]

{ #category : #activity }
PjBridge >> when: conditionBlock do: actionBlock onTimeOutDo: failureBlock [
	^self when: conditionBlock do: actionBlock onTimeOutDo: failureBlock timeOutDuration: self timeout
]

{ #category : #activity }
PjBridge >> when: conditionBlock do: actionBlock onTimeOutDo: failureBlock timeOutDuration: maxWaitDuration [
	| waitTime |
	waitTime := maxWaitDuration / communicationTrialsCount.
	waitTime < self minimumStepDuration ifTrue: [waitTime := self minimumStepDuration].
	communicationTrialsCount timesRepeat: [
		conditionBlock value ifTrue: [ ^actionBlock value ].
		waitTime wait.
	].
	^failureBlock value.	

]

{ #category : #public }
PjBridge >> withClientLogging [
	self client: self client withClientLogging
]
