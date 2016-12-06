"
strings in Javascript world
"
Class {
	#name : #PjString,
	#superclass : #PjObject,
	#traits : 'PjTExtensionClass',
	#classTraits : 'PjTExtensionClass classTrait',
	#pools : [
		'PjDomGlobals'
	],
	#category : #'PharoJsCoreLibraries-Kernel'
}

{ #category : #'instance creation' }
PjString class >> defaultSize [
	^10 
]

{ #category : #'instance creation' }
PjString class >> new [
	^ ''
]

{ #category : #'instance creation' }
PjString class >> new: size [
	^ ''
]

{ #category : #'instance creation' }
PjString class >> value: anInteger [
	^ String js_fromCharCode: anInteger
]

{ #category : #copying }
PjString >> , other [
	<javascript: 'return this+other'>
]

{ #category : #testing }
PjString >> < other [
	<javascript: 'return this<other'>
]

{ #category : #testing }
PjString >> <= other [
	<javascript: 'return this<=other'>
]

{ #category : #testing }
PjString >> = other [
	<javascript: 'return this==other'>
]

{ #category : #testing }
PjString >> > other [
	<javascript: 'return this>other'>
]

{ #category : #testing }
PjString >> >= other [
	<javascript: 'return this>=other'>
]

{ #category : #testing }
PjString >> allButFirst [
	^ self js_substring: 1
]

{ #category : #accessing }
PjString >> allButFirst: n [
	^ self js_substring: n
]

{ #category : #testing }
PjString >> allButLast [
	^ self js_substring: 0 to: self size - 1
]

{ #category : #testing }
PjString >> allButLast: n [
	^ self js_substring: 0 to: self size - n
]

{ #category : #converting }
PjString >> asCharacter [
	^ self js_charAt: 0
]

{ #category : #converting }
PjString >> asElementId [
	^ document getElementById: self
]

{ #category : #converting }
PjString >> asElementSelector [
	^ document querySelector: self
]

{ #category : #converting }
PjString >> asInteger [
	^ self js_charCodeAt: 0
]

{ #category : #converting }
PjString >> asLowercase [
	^ self js_toLowerCase
]

{ #category : #converting }
PjString >> asRegex [
	<javascript: 'return new RegExp(this)'>
]

{ #category : #converting }
PjString >> asString [
]

{ #category : #converting }
PjString >> asSymbol [
]

{ #category : #converting }
PjString >> asUppercase [
	^ self js_toUpperCase
]

{ #category : #accessing }
PjString >> asciiValue [
	^ self js_charCodeAt: 0
]

{ #category : #accessing }
PjString >> at: index [
	"JavaScript arrays first index is 0 "
	<javascript: 'return this[index - 1];'>
]

{ #category : #accessing }
PjString >> at: index put: anObject [
	<javascript: 'throw new Error("cannot mutate strings");'>
]

{ #category : #comparing }
PjString >> beginsWith: prefix [
	^ (self js_substring: 0 to: prefix size)=prefix
]

{ #category : #converting }
PjString >> capitalized [
	self isEmpty ifTrue: [ ^self ].
	^ (self js_charAt:0) js_toUpperCase,(self js_substring: 1)
]

{ #category : #accessing }
PjString >> charCode [
	^ self js_charCodeAt: 0
]

{ #category : #accessing }
PjString >> codePoint [
	^ self js_charCodeAt: 0
]

{ #category : #testing }
PjString >> collect: aBlock [
	| arr |
	arr := self js_split: ''.
	1 to: self size do: [: idx |
		arr at: idx put: (aBlock value: (arr at: idx))
	].
	^ arr js_join: ''
]

{ #category : #comparing }
PjString >> copyFrom: start [
	^ self js_substring: start-1
]

{ #category : #comparing }
PjString >> copyFrom: start to: stop [
	^ self js_substring: start-1 to: stop
]

{ #category : #comparing }
PjString >> endsWith: suffix [
	^ (self js_substring: self size - suffix size)=suffix
]

{ #category : #accessing }
PjString >> first [
	^self at: 1
]

{ #category : #accessing }
PjString >> first: n [
	^ self js_substring: 0 to: n
]

{ #category : #testing }
PjString >> ifEmpty: aBlock [
	self isEmpty ifTrue: [^aBlock value].
	^self
]

{ #category : #testing }
PjString >> isEmpty [
	^self = ''
]

{ #category : #testing }
PjString >> isLetter [
	| first |
	first := ((self js_charAt: 0) js_toUpperCase) js_charCodeAt: 0.
	first < 65 ifTrue: [ ^false ].
	^ first <= 90
]

{ #category : #testing }
PjString >> isString [
	^ true
]

{ #category : #testing }
PjString >> join: anArray [
	^ anArray js_join: self
]

{ #category : #accessing }
PjString >> last [
	^self at: self size
]

{ #category : #testing }
PjString >> notEmpty [
	^self ~= ''
]

{ #category : #proxy }
PjString >> proxyResponse [
	<javascript: 'return ""+this'>
]

{ #category : #accessing }
PjString >> size [
	^self js_at:#length
]

{ #category : #converting }
PjString >> to: other [
	^ (self asciiValue to: other asciiValue) collect:
				[:ascii | ascii asCharacter]
]

{ #category : #testing }
PjString >> ~= other [
	<javascript: 'return this!=other'>
]