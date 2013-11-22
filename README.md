# obj #

## Introduction ##

A parser for .OBJ format in Dart.

## Getting Started ##

1\. Add the following to your project's **pubspec.yaml** and run ```pub get```.

```
dependencies:
  obj:
    git: https://github.com/udhos/obj
```

2\. Add the correct import for your project. 

```
import 'package:obj/obj.dart';
```


## Examples ##

1\. Parsing an OBJ string

```
	// objURL is an optional URL for issuing the obj location on error messages
	// objString is a string containing the OBJ text

	String objURL = "http://some.example.com/path/to/model.obj";
	
	void handleObj(String objString) {
		Obj obj = new Obj.fromString(objURL, objString);
	}
	
    HttpRequest.getString(objURL)
		.then(handleObj)
		.catchError((err) { print("failure fetching OBJ from URL: $objURL: $err"); });    
``` 

2\. Parsing an MTLLIB string

```
	// libURL is an optional URL for issuing the lib location on error messages
	// materialString is a string containing the MTLLIB text
	
	String libURL = "http://some.example.com/path/to/lib.mtl";
	
    void handleLib(String libString) {
		Map<String,Material> lib = mtllib_parse(libString, libURL);
	}
	
    HttpRequest.getString(libURL)
		.then(handleLib)
		.catchError((err) { print("failure fetching mtllib: $libURL: $err"); });    
``` 

3\. Scanning the OBJ's part list

```
	obj.partList.forEach((pa) {

        String usemtl = pa.usemtl;      
        Material mtl = lib[usemtl];
        if (mtl == null) {
          print("material usemtl=$usemtl NOT FOUND on mtllib=$libURL");
          return;
        }
		
		// Handle Part "pa" with Material "mtl"
		// ...
	}
```
