Extension { #name : #PjNodeApplication }

{ #category : #'*PharoJsExporter' }
PjNodeApplication class >> polyfill: aPolyfillClass onStream: aStream unlessIn: aSet [
	<pharoJsSkip>
	^ (super polyfill: aPolyfillClass onStream: aStream unlessIn: aSet) and: [
		aPolyfillClass nodePolyfill: aStream.
		true
	]
]
