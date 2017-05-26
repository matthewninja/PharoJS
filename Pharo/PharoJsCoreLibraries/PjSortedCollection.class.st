Class {
	#name : #PjSortedCollection,
	#superclass : #PjArray,
	#category : #'PharoJsCoreLibraries-Kernel'
}

{ #category : #'pharoJs support' }
PjSortedCollection class >> jsTranspilationImportMethods [
	<pharoJsSkip>
	^{SortedCollection -> (SortedCollection selectors copyWithoutAll: #(collect: insert:before: indexForInserting:))}
]

{ #category : #enumerating }
PjSortedCollection >> collect: aBlock [ 
	"Evaluate aBlock with each of my elements as the argument. Collect the 
	resulting values into an OrderedCollection. Answer the new collection. 
	Override the superclass in order to produce an OrderedCollection instead
	of a SortedCollection."

	| newCollection | 
	newCollection := OrderedCollection new.
	self do: [:each | newCollection addLast: (aBlock value: each)].
	^ newCollection
]

{ #category : #private }
PjSortedCollection >> indexForInserting: newObject [
	self ifEmpty: [ ^1 ].
	self withIndexDo: [ : element : index | newObject < element ifTrue: [ ^index ] ].
	^self size + 1
]

{ #category : #'initialize-release' }
PjSortedCollection >> initialize [
	super initialize.
	self instVarNamed: #firstIndex put: 1.
	self instVarNamed: #lastIndex put: 0
]

{ #category : #accessing }
PjSortedCollection >> insert: newObject before: index [
	self splice: index - 1 remove: 0 element: newObject
]

{ #category : #accessing }
PjSortedCollection >> replaceFrom: start to: stop with: replacement startingAt: repStart [
	| repStop |
	repStop := repStart + stop - start.
	repStart to: repStop do: [ : otherIndex |
		self add: (replacement at: otherIndex)  ]

]