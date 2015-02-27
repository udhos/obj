import 'dart:io';
//import 'dart:async';
//import 'dart:convert';

import 'package:unittest/unittest.dart';

import 'package:obj/obj.dart';

void main() {
  cube_test();
}

void cube_test() {
  obj_test("test/cube.obj", 8, 12);
}

void obj_test(String objPath, int vertices, int indices) {
    File f = new File(objPath);
    
    f.readAsString().then((String objString) {
      Obj obj = new Obj.fromString(objPath, objString, printStats: true);
      
      test("Obj.fromString($objPath): non-null", () {
        expect(obj != null, isTrue);
      });
      
      int vertCoord = 3 * vertices;
      
      test("Obj.fromString($objPath): $vertCoord vertex coord", () {
        expect(obj.vertCoord.length, vertCoord);
      });

      test("Obj.fromString($objPath): $indices indices", () {
        expect(obj.indices.length, indices);
      });
      
  }); 
 
}
