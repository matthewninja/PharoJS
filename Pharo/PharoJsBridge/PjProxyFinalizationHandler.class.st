"
I am the finilizer for temporary proxy values so they can be removed from the Javascript engine side when no longer referenced by the Pharo side
"
Class {
	#name : #PjProxyFinalizationHandler,
	#superclass : #Object,
	#instVars : [
		'weakBridgeArray',
		'proxyJsName'
	],
	#category : #'PharoJsBridge-Proxy'
}

{ #category : #'finalization support' }
PjProxyFinalizationHandler class >> finalizerForProxyNamed: aString onBridge: aBridge [
	| instance |
	instance := self jsName: aString onBridge: aBridge.
	^instance finalizer
]

{ #category : #'instance creation' }
PjProxyFinalizationHandler class >> jsName: aString onBridge: aBridge [
	^self new 
		proxyJsName: aString;
		bridge: aBridge;
		yourself
]

{ #category : #accessing }
PjProxyFinalizationHandler >> bridge [
	^weakBridgeArray at: 1
]

{ #category : #accessing }
PjProxyFinalizationHandler >> bridge: aBridge [
	weakBridgeArray at: 1 put: aBridge
]

{ #category : #finalization }
PjProxyFinalizationHandler >> cleanUpJsSide [
	self bridge ifNil: [ ^self ].
	self bridge isServerStopped ifTrue: [ ^self ].
	self bridge deleteJsValue: self proxyJsName
]

{ #category : #accessing }
PjProxyFinalizationHandler >> finalizer [
	^ObjectFinalizer new
			receiver: self;
			selector: #cleanUpJsSide
			yourself.

]

{ #category : #'initialize-release' }
PjProxyFinalizationHandler >> initialize [
	super initialize.
	weakBridgeArray := WeakArray new: 1.
]

{ #category : #accessing }
PjProxyFinalizationHandler >> proxyJsName [
	^ proxyJsName
]

{ #category : #accessing }
PjProxyFinalizationHandler >> proxyJsName: anObject [
	proxyJsName := anObject
]
