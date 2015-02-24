import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:obj/obj.dart';

import 'mustang.dart';

String objURL;
String objString;
String mtlURL;
String mtlString;

void log(String msg) {
  print("** $msg");
}

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
    
    log("mtl file loaded: $URL");
    
    log("parsing mtl file: $URL");
    
    ParseMtlBenchmark.main(); // run benchmark
  }

  log("loading mtl file: $URL");
  
  var file = new File(URL);
  Future<String> finishedReading = file.readAsString(encoding: ASCII);
  finishedReading.then(done);
}

void fetchObj(String oURL, String mURL) {
  void done(String response) {
    objURL = oURL;
    objString = response;

    log("obj file loaded: $oURL");

    fetchMtl(mURL);

    log("parsing obj file: $oURL");
    
    ParseObjBenchmark.main(); // run benchmark    
  }

  log("loading obj file: $oURL");
  
  var file = new File(oURL);
  Future<String> finishedReading = file.readAsString(encoding: ASCII);
  finishedReading.then(done);
}

void loadMtl(String URL) {
  void done(String response) {
    mtlURL = URL;
    mtlString = response;
    
    log("parsing mtl: $URL");
    
    ParseMtlBenchmark.main(); // run benchmark
  }

  done(MUSTANG_MTL_STR);
}

void loadObj(String URL) {
  void done(String response) {
    objURL = URL;
    objString = response;
    
    loadMtl("mustang_impala.mtl");
    
    log("parsing obj: $URL");
    
    ParseObjBenchmark.main(); // run benchmark    
  }

  done(MUSTANG_OBJ_STR);
}

void main() {
  log("current directory: ${Directory.current}");
  loadObj("mustang_impala.obj"); // loadObj: hard-coded obj
  fetchObj("benchmark/house.obj", "benchmark/house.mtl"); // fetchOBJ: grab obj from file
}
