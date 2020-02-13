"
Node.js request module. Useful for making requests to external APIs

request node module required: $ npm install request
"
Class {
	#name : #PjRequestPolyfill,
	#superclass : #PjJavascriptGlobals,
	#classVars : [
		'Requestjs'
	],
	#category : #PharoJsExpress
}

{ #category : #polyfill }
PjRequestPolyfill class >> nodePackageName [
	<pharoJsSkip>
	^ 'request'
]
