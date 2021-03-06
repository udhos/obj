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

1\. Parsing OBJ string

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

2\. Parsing MTLLIB string

```
// libURL is an optional URL for issuing the lib location on error messages
// libString is a string containing the MTLLIB text
	
String libURL = "http://some.example.com/path/to/lib.mtl";
	
void handleLib(String libString) {
  Map<String,Material> lib = mtllib_parse(libString, libURL);
}
	
HttpRequest.getString(libURL)
  .then(handleLib)
  .catchError((err) { print("failure fetching mtllib: $libURL: $err"); });    
```

3\. Creating WebGL buffers from OBJ data

```
  Buffer vertexIndexBuffer = gl.createBuffer();
  gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, vertexIndexBuffer);
  gl.bufferDataTyped(RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(obj.indices), RenderingContext.STATIC_DRAW);

  Buffer vertexPositionBuffer = gl.createBuffer();
  gl.bindBuffer(RenderingContext.ARRAY_BUFFER, vertexPositionBuffer);
  gl.bufferDataTyped(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(obj.vertCoord), RenderingContext.STATIC_DRAW);   

  Buffer textureCoordBuffer = gl.createBuffer();
  gl.bindBuffer(RenderingContext.ARRAY_BUFFER, textureCoordBuffer);
  gl.bufferDataTyped(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(obj.textCoord), RenderingContext.STATIC_DRAW);
```

4\. Scanning OBJ's Part list

```
obj.partList.forEach((pa) {

  String usemtl = pa.usemtl;      
  Material mtl = lib[usemtl];
  if (mtl == null) {
    print("material usemtl=$usemtl NOT FOUND on mtllib=$libURL");
    return;
  }

  // Handle Part "pa" with Material "mtl"

  // Example for solid color
  int r = (mtl.Kd[0] * 255.0).round();
  int g = (mtl.Kd[1] * 255.0).round();
  int b = (mtl.Kd[2] * 255.0).round();
  List<int> solidColor = [r, g, b, 255];

  // Example for diffuse map
  String textureDiffuseURL = mtl.map_Kd;

  // The index range for the part
  int indexOffset = pa.indexFirst;
  int indexLength = pa.indexListSize;
  
  // ...
}
```
