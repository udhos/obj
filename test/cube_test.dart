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
}
