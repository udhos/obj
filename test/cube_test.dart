import 'dart:io';
//import 'dart:async';
//import 'dart:convert';

import 'package:unittest/unittest.dart';

import 'package:obj/obj.dart';

void main() {
  cube_test();
  relative_test();
}

void cube_test() {
  obj_test("test/cube.obj", 23, 36);
  mtl_test("test/cube.mtl");
}

void obj_test(String objPath, int vertices, int indices) {
  File objFile = new File(objPath);

  String objString = objFile.readAsStringSync();

  Obj obj = new Obj.fromString(objPath, objString,
      printStats: true, debugPrintParts: true, debugPrintTrace: true);

  test("Obj.fromString($objPath): non-null", () {
    expect(obj != null, isTrue);
  });

  int vertCoord = 3 * vertices;

  test("Obj.fromString($objPath): $vertCoord vertex coord", () {
    expect(obj.vertCoord.length, vertCoord);
  });

  int textCoord = 2 * vertices;

  test("Obj.fromString($objPath): $textCoord texture coord", () {
    expect(obj.textCoord.length, textCoord);
  });

  test("Obj.fromString($objPath): $indices indices", () {
    expect(obj.indices.length, indices);
  });

  int parts = 1;
  test("Obj.fromString($objPath): $parts parts", () {
    expect(obj.partList.length, parts);
  });

  String mtllib = "cube.mtl";
  test("Obj.fromString($objPath): mtllib=$mtllib", () {
    expect(obj.mtllib, mtllib);
  });

  String partName = "cube";
  test("Obj.fromString($objPath): partName=$partName", () {
    expect(obj.partList.first.name, partName);
  });

  String usemtl = "cube_material";
  test("Obj.fromString($objPath): usemtl=$usemtl", () {
    expect(obj.partList.first.usemtl, usemtl);
  });
}

void mtl_test(String materialPath) {
  File materialFile = new File(materialPath);

  String materialString = materialFile.readAsStringSync();

  Map<String, Material> materialTable =
      mtllib_parse(materialString, materialPath);

  test("mtllib_parse($materialPath): non-null", () {
    expect(materialTable != null, isTrue);
  });

  int materialCount = 1;
  test("mtllib_parse($materialPath): materials=$materialCount", () {
    expect(materialTable.length, materialCount);
  });

  String materialName = "cube_material";
  test("mtllib_parse($materialPath): materialName=$materialName", () {
    expect(materialTable.keys.first, materialName);
  });

  String materialTexture = "cube.png";
  test("mtllib_parse($materialPath): materialTexture=$materialTexture", () {
    expect(materialTable[materialTable.keys.first].map_Kd, materialTexture);
  });
}

void relative_test() {
  String objPath = "relative_test";
  String objString = """
o relative_test

v 1 1 1
v 2 2 2
v 3 3 3

f 1 2 3

# this line should affect indices, but not vertex array
f -3 -2 -1

v 4 4 4
v 5 5 5
v 6 6 6

f 4 5 6

# this line should affect indices, but not vertex array
f -3 -2 -1

# these lines should affect indices, but not vertex array
f 1 2 3
f -6 -5 -4

""";

  Obj obj = new Obj.fromString(objPath, objString,
      printStats: true, debugPrintParts: true, debugPrintTrace: true);

  test("Obj.fromString($objPath): non-null", () {
    expect(obj != null, isTrue);
  });

  test("Obj.fromString($objPath): indices", () {
    expect(obj.indices, [0, 1, 2, 0, 1, 2, 3, 4, 5, 3, 4, 5, 0, 1, 2, 0, 1, 2]);
  });

  test("Obj.fromString($objPath): vertCoord", () {
    expect(obj.vertCoord, [
      1.0,
      1.0,
      1.0,
      2.0,
      2.0,
      2.0,
      3.0,
      3.0,
      3.0,
      4.0,
      4.0,
      4.0,
      5.0,
      5.0,
      5.0,
      6.0,
      6.0,
      6.0
    ]);
  });
}
