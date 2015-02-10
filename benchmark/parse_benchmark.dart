/*
import 'dart:io';
import 'dart:async';
import 'dart:convert';
 */

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:obj/obj.dart';

import 'mustang.dart';

String objURL;
String objString;
String mtlURL;
String mtlString;

class ParseObjBenchmark extends BenchmarkBase {
  const ParseObjBenchmark() : super("ParseObjBenchmark: Obj.fromString");

  static void main() {
    new ParseObjBenchmark().report();
  }

  void run() {
    Obj obj = new Obj.fromString(objURL, objString, defaultName: "noname");
  }
}

class ParseMtlBenchmark extends BenchmarkBase {
  const ParseMtlBenchmark() : super("ParseMtlBenchmark: mtllib_parse");

  static void main() {
    new ParseMtlBenchmark().report();
  }

  void run() {
    Map<String, Material> lib = mtllib_parse(mtlString, mtlURL, printUnknownFields: false);
  }
}

void fetchMtl(String URL) {
  void done(String response) {
    mtlURL = URL;
    mtlString = response;
    ParseMtlBenchmark.main(); // run benchmark
  }

  /*
  var file = new File(URL);
  Future<String> finishedReading = file.readAsString(encoding: ASCII);
  finishedReading.then(done);
   */
  done(MUSTANG_MTL_STR);
}

void fetchObj(String URL) {
  void done(String response) {
    objURL = URL;
    objString = response;
    ParseObjBenchmark.main(); // run benchmark

    /*
    fetchMtl(
        "C:/tmp/devel/negentropia/wwwroot/mtl/Colony Ship Ogame Fleet.mtl");
         */
    fetchMtl("mustang_impala.mtl");
  }

  /*
  var file = new File(URL);
  Future<String> finishedReading = file.readAsString(encoding: ASCII);
  finishedReading.then(done);
   */
  done(MUSTANG_OBJ_STR);
}

void main() { 
  //fetchObj("C:/tmp/devel/negentropia/wwwroot/obj/Colony Ship Ogame Fleet.obj");
  fetchObj("mustang_impala.obj");
}
