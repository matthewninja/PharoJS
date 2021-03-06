"
This trait makes a test case run the app under test on the Pharo VM. Only third party JS code and DOM objects are run on the JS interpreter

"
Trait {
	#name : #PjTAppRunsInPharo,
	#category : #'PharoJsTestFramework-Kernel'
}

{ #category : #testing }
PjTAppRunsInPharo >> appClassToExport [
	^PjAppWrapperForRunningInPharo on: self appClass
]

{ #category : #testing }
PjTAppRunsInPharo >> currentApp [
	^self appClass
		start; 
		currentInstance.

]
