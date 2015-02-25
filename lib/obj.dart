library obj;

class Part {
  String name;
  bool smooth;
  String usemtl;
  int indexFirst;
  int indexListSize = 0;

  Part(this.name, this.indexFirst);
}

RegExp _BLANK = new RegExp(r"\s+");

class Obj {
  static final String prefix_mtllib = "mtllib ";
  static final String prefix_usemtl = "usemtl ";
  static final int prefix_mtllib_len = prefix_mtllib.length;
  static final int prefix_usemtl_len = prefix_usemtl.length;

  Map<String, Part> _partTable = new Map<String, Part>();

  Iterable<Part> get partList => _partTable.values;

  bool textCoordFound = true;
  List<double> vertCoord = new List<double>();
  List<double> textCoord = new List<double>();
  List<double> normCoord = new List<double>();
  List<int> indices = new List<int>();
  String mtllib;

  void trimTable(String url) {
    // remove empty objects from _partTable
    /*
    List<String> emptyList = new List<String>(); // create a copy to avoid concurrent modifications
    _partTable.keys.forEach((String name) { 
      if (_partTable[name].indexListSize < 1) {
        emptyList.add(name);
        print("OBJ: deleting empty object=$name loaded from url=$url");
      } 
    });
    emptyList.forEach((String name) => _partTable.remove(name)); // remove selected keys
    */

    _partTable.keys.where((name) {
      // where: filter keys
      bool empty = _partTable[name].indexListSize < 1;
      if (empty) {
        //print("OBJ: deleting empty object=$name loaded from url=$url");
      }
      return empty;
    }).toList() // create a copy to avoid concurrent modifications
        .forEach(_partTable.remove); // remove selected keys

    /*
    Iterable<String> keys = _partTable.keys;
    print("DEBUG got keys");
    Iterable<String> filtered = keys.where((name) { // where: filter keys
      bool empty = _partTable[name].indexListSize < 1;
      if (empty) {
        print("OBJ: deleting empty object=$name loaded from url=$url");
      }       
      return empty;
    });
    print("DEBUG got filtered");
    List<String> copy = filtered.toList();
    print("DEBUG got copy");
    copy.forEach(_partTable.remove);
    print("DEBUG got result");
    */
  }

  Obj.fromString(String url, String str, {bool printStats: false,
      bool debugPrintParts: false, String defaultName: null,
      bool debugPrintTrace: false, bool fillMissingTextCoord: false}) {
    Map<String, int> indexTable = new Map<String, int>();
    List<double> _vertCoord = new List<double>();
    List<double> _textCoord = new List<double>();
    List<double> _normCoord = new List<double>();
    int indexCounter = 0;
    int lineNum = 0;
    Part currObj;
    String curr_usemtl;
    bool withinComment = false;

    bool _isForcedCommentBegin(String line) {
      return line.startsWith("## comment-begin ##");
    }

    bool _isForcedCommentEnd(String line) {
      return line.startsWith("## comment-end ##");
    }

    bool _isForcedEof(String line, int num) {
      bool eof = line.startsWith("## end-of-file ##");
      if (eof) print(
          "Obj.fromString: URL=$url forced EOF at line=$num: [$line]");
      return eof;
    }

    bool parseLine(String rawLine) {
      ++lineNum;

      //print("line: $lineNum url=$url [$rawLine]");

      String line = rawLine.trim();

      if (_isForcedCommentEnd(line)) {
        withinComment = false;
        return false;
      }

      if (_isForcedEof(line, lineNum)) {
        return true;
      }

      if (withinComment) {
        return false;
      }

      if (_isForcedCommentBegin(line)) {
        withinComment = true;
        return false;
      }

      if (_trimmedLineIsComment(line)) return false;

      if (line.startsWith(prefix_mtllib)) {
        String new_mtllib = line.substring(prefix_mtllib_len);
        if (mtllib != null) {
          print(
              "OBJ: mtllib redefinition: from mtllib=$mtllib to mtllib=$new_mtllib");
        }
        mtllib = new_mtllib;
        return false;
      }

      if (line.startsWith(prefix_usemtl)) {
        String new_usemtl = line.substring(prefix_usemtl_len);
        if (currObj != null) {
          currObj.usemtl = new_usemtl;
        }
        curr_usemtl = new_usemtl;
        if (debugPrintTrace) {
          print("Obj.fromString: url=$url usemtl=$curr_usemtl");
        }
        return false;
      }

      void _setCurrentObject(String name, int num, String u, String ln) {
        currObj = _partTable[name];
        if (currObj == null) {
          currObj = new Part(name, indices.length);
          _partTable[name] = currObj;
        } else {
          print("OBJ: redefining object $name at line=$num from url=$u: [$ln]");
        }
        if (curr_usemtl != null) {
          currObj.usemtl = curr_usemtl;
        }
      }

      if (line.startsWith('o ') || line.startsWith('g ')) {
        String objName = line.substring(2);
        _setCurrentObject(objName, lineNum, url, line);
        return false;
      }

      if (currObj == null) {
        if (defaultName != null) {
          _setCurrentObject(defaultName, lineNum, url, line);
        } else {
          print(
              "OBJ: non-object pattern at line=$lineNum from url=$url: [$line]");
        }
        return false;
      }

      if (line.startsWith('s ')) {
        String smooth = line.substring(2);
        if (smooth == "0" || smooth.toLowerCase().startsWith("f")) {
          currObj.smooth = false;
        } else {
          currObj.smooth = true;
        }
        return false;
      }

      /*
      if (line.startsWith("v ")) {
        // vertex coord
        List<String> v = line.split(_BLANK);
        if (v.length == 4) {
          _vertCoord.add(double.parse(v[1])); // x
          _vertCoord.add(double.parse(v[2])); // y
          _vertCoord.add(double.parse(v[3])); // z
          return;
        }
        if (v.length == 5) {
          double w = double.parse(v[4]);
          _vertCoord.add(double.parse(v[1]) / w); // x
          _vertCoord.add(double.parse(v[2]) / w); // y
          _vertCoord.add(double.parse(v[3]) / w); // z
          return;
        }

        print("OBJ: wrong number of vertex coordinates: ${v.length - 1} at line=$lineNum from url=$url: [$line]");
        return;
      }
       */
      if (line.startsWith("v ")) {
        // vertex coord
        return false;
      }

      if (line.startsWith("vt ")) {
        // texture coord
        List<String> t = line.split(_BLANK);
        if (t.length == 3) {
          _textCoord.add(double.parse(t[1])); // u
          _textCoord.add(double.parse(t[2])); // v
          return false;
        }
        if (t.length == 4) {
          double u = double.parse(t[1]);
          double v = double.parse(t[2]);
          double w = double.parse(t[3]);

          if (w != 0.0) {
            print(
                "OBJ: non-zero third texture coordinate: $w at line=$lineNum from url=$url: [$line]");
            return false;
          }

          _textCoord.add(u); // u
          _textCoord.add(v); // v
          return false;
        }
        print(
            "OBJ: wrong number of texture coordinates: ${t.length - 1} at line=$lineNum from url=$url: [$line]");
        return false;
      }

      if (line.startsWith("vn ")) {
        // normal
        List<String> n = line.split(_BLANK);
        if (n.length != 4) {
          print(
              "OBJ: wrong number of normal coordinates (${n.length - 1} != 3) at line=$lineNum from url=$url: [$line]");
          return false;
        }
        _normCoord.add(double.parse(n[1])); // x
        _normCoord.add(double.parse(n[2])); // y
        _normCoord.add(double.parse(n[3])); // z
        return false;
      }

      if (line.startsWith("f ")) {
        // face

        void addVertex(String ind) {

          // known unified index?
          int index = indexTable[ind];
          if (index != null) {
            indices.add(index);
            currObj.indexListSize++;
            return;
          }

          List<String> v = ind.split('/');

          int solveRelativeIndex(int index, int tupleSize, int arraySize) {
            int offset;

            if (index > 0) {
              // positive index
              offset = tupleSize * (index - 1);
            } else {
              // negative index (starts from end)
              offset = arraySize + tupleSize * index;
            }

            return offset;
          }

          // coord index
          String vi = v[0];
          int vIndex = int.parse(vi);
          int vOffset = solveRelativeIndex(vIndex, 3, _vertCoord.length);

          //print("addVertex: ind=[$ind] vOffset=$vOffset\n");

          vertCoord.add(_vertCoord[vOffset + 0]); // x
          vertCoord.add(_vertCoord[vOffset + 1]); // y
          vertCoord.add(_vertCoord[vOffset + 2]); // z

          if (v.length > 1) {
            // texture index?
            String ti = v[1];
            if (ti != null && !ti.isEmpty) {
              int tIndex = int.parse(ti);
              int tOffset = solveRelativeIndex(tIndex, 2, _textCoord.length);
              textCoord.add(_textCoord[tOffset + 0]); // u
              textCoord.add(_textCoord[tOffset + 1]); // v
            }
          }

          if (v.length > 2) {
            // normal index?
            String ni = v[2];
            if (ni != null && !ni.isEmpty) {
              int nIndex = int.parse(ni);
              int nOffset = solveRelativeIndex(nIndex, 3, _normCoord.length);
              normCoord.add(_normCoord[nOffset + 0]); // x
              normCoord.add(_normCoord[nOffset + 1]); // y
              normCoord.add(_normCoord[nOffset + 2]); // z
            }
          }

          // add unified index
          indices.add(indexCounter);
          currObj.indexListSize++;
          indexTable[ind] = indexCounter;
          ++indexCounter;
        }

        List<String> f = line.split(_BLANK);

        if (f.length == 4) {
          // triangle face: v0 v1 v2
          for (int i = 1; i < f.length; ++i) {
            addVertex(f[i]);
          }
          return false;
        }

        if (f.length == 5) {
          // quad face:
          // v0 v1 v2 v3 =>
          // v0 v1 v2
          // v2 v3 v0
          for (int i = 1; i < 4; ++i) {
            addVertex(f[i]);
          }
          addVertex(f[3]);
          addVertex(f[4]);
          addVertex(f[1]);
          return false;
        }

        print(
            "OBJ: wrong number of face indices ${f.length - 1} at line=$lineNum from url=$url: [$line]");

        return false;
      }

      /*
      if (line.startsWith(prefix_usemtl)) {
        String new_usemtl = line.substring(prefix_usemtl_len);
        if (currObj.usemtl != null) {
          print("OBJ: object=${currObj.name} usemtl redefinition: from usemtl=${currObj.usemtl} to usemtl=$new_usemtl");          
        }
        currObj.usemtl = new_usemtl;
        return;
      }
      */

      print("OBJ: unknown pattern at line=$lineNum from url=$url: [$line]");

      return false;
    }

    bool parseOnlyVertexLine(String rawLine) {
      ++lineNum;

      //print("line: $lineNum url=$url [$rawLine]");

      String line = rawLine.trim();

      if (_trimmedLineIsComment(line)) return false;

      if (line.startsWith("v ")) {
        // vertex coord
        List<String> v = line.split(_BLANK);
        if (v.length == 4) {
          _vertCoord.add(double.parse(v[1])); // x
          _vertCoord.add(double.parse(v[2])); // y
          _vertCoord.add(double.parse(v[3])); // z
          return false;
        }
        if (v.length == 5) {
          double w = double.parse(v[4]);
          _vertCoord.add(double.parse(v[1]) / w); // x
          _vertCoord.add(double.parse(v[2]) / w); // y
          _vertCoord.add(double.parse(v[3]) / w); // z
          return false;
        }

        print(
            "OBJ: wrong number of vertex coordinates: ${v.length - 1} at line=$lineNum from url=$url: [$line]");
        return false;
      }

      return false;
    }

    void _scanLines(List<String> lines) {

      //lines.forEach((line) => parseOnlyVertexLine(line));
      for (final line in lines) {
        bool eof = parseOnlyVertexLine(line);
        if (eof) return;
      }

      lineNum = 0;
      currObj = null;
      curr_usemtl = null;

      //lines.forEach((line) => parseLine(line));
      for (final line in lines) {
        bool eof = parseLine(line);
        if (eof) return;
      }
    }

    List<String> lines = str.split('\n');

    _scanLines(lines);

    //print("Obj.fromString: url=$url: lines=${lines.length}");

    trimTable(url); // remove empty objects from _partTable

    // FIXME
    int textCoordNeeded = indexCounter * 2;
    if (textCoord.length < textCoordNeeded) {
      textCoordFound = false; // mark real texture coordinates as missing
      if (fillMissingTextCoord) {
        print(
            "OBJ: FIXME: url=$url adding ${textCoordNeeded - textCoord.length} virtual texture coordinates");
        while (textCoord.length < textCoordNeeded) {
          textCoord.add(0.0); // u
          textCoord.add(0.0); // v
        }
      }
    }

    if (printStats) {
      print("Obj.fromString: URL=$url vertices = $indexCounter");
      print("Obj.fromString: URL=$url indices.length = ${indices.length}");
      print("Obj.fromString: URL=$url textCoordFound = $textCoordFound");
      print(
          "Obj.fromString: URL=$url textCoord.length = ${textCoord.length} (2 * $indexCounter)");
      print(
          "Obj.fromString: URL=$url normCoord.length = ${normCoord.length} (3 * $indexCounter)");

      int maxIndices = 100;

      print(
          "Obj.fromString: URL=$url printing arrays only for objects with less than $maxIndices indices");

      if (indices.length < maxIndices) {
        print("Obj.fromString: URL=$url indices = ${indices}");
        print("Obj.fromString: URL=$url vertCoord = ${vertCoord}");
        print("Obj.fromString: URL=$url textCoord = ${textCoord}");
        print("Obj.fromString: URL=$url normCoord = ${normCoord}");
      }

      print("Obj.fromString: URL=$url parts = ${_partTable.length}");
    }

    if (debugPrintParts) {
      _partTable.values.forEach((Part pa) {
        print(
            "Obj.fromString: URL=$url part=${pa.name} offset=${pa.indexFirst} size=${pa.indexListSize}");
      });
    }
  }
}

class Material {
  static final String prefix_newmtl = "newmtl ";
  static final String prefix_map_Kd = "map_Kd ";
  static final int prefix_newmtl_len = prefix_newmtl.length;
  static final int prefix_map_Kd_len = prefix_map_Kd.length;

  String name;
  String map_Kd;
  List<double> Kd = new List<double>(3);
  Material(this.name);
}

typedef void field_parser(
    String field, String param, String line, int lineNum, String url);

Map<String, Material> mtllib_parse(String str, String url,
    {printUnknownFields: true, bool debugPrintTrace: false}) {
  Map<String, Material> lib = new Map<String, Material>();
  Material currMaterial;

  void _parse_newmtl(
      String field, String param, String line, int lineNum, String url) {
    String mtl = param;
    currMaterial = lib[mtl];
    if (currMaterial == null) {
      currMaterial = new Material(mtl);
      lib[mtl] = currMaterial;
    }
    if (debugPrintTrace) {
      print("mtllib_parse: url=$url: newmtl=$mtl");
    }
  }

  void _parse_map_Kd(
      String field, String param, String line, int lineNum, String url) {
    String map_Kd = param;
    if (currMaterial == null) {
      print(
          "mtllib_parse: url=$url: line=$lineNum: map_Kd=$map_Kd found for undefined material: [$line]");
      return;
    }
    currMaterial.map_Kd = map_Kd;
  }

  void _parse_Kd(
      String field, String param, String line, int lineNum, String url) {
    String Kd = param;
    if (currMaterial == null) {
      print(
          "mtllib_parse: url=$url: line=$lineNum: Kd=$Kd found for undefined material: [$line]");
      return;
    }
    List<String> rgb = Kd.split(_BLANK);
    currMaterial.Kd[0] = double.parse(rgb[0]);
    currMaterial.Kd[1] = double.parse(rgb[1]);
    currMaterial.Kd[2] = double.parse(rgb[2]);
  }

  void _parse_noop(
      String field, String param, String line, int lineNum, String url) {}

  final Map<String, field_parser> parserTable = {
    "newmtl": _parse_newmtl,
    "map_Kd": _parse_map_Kd,
    "Kd": _parse_Kd,
    "map_Bump": _parse_noop,
    "Ns": _parse_noop,
    "Ka": _parse_noop,
    "Ks": _parse_noop,
    "Ni": _parse_noop,
    "d": _parse_noop,
    "illum": _parse_noop
  };

  int lineNum = 0;

  void parseLine(String rawLine) {
    ++lineNum;

    String line = rawLine.trim();

    if (_trimmedLineIsComment(line)) {
      return;
    }

    int paramIndex = line.indexOf(' ');
    if (paramIndex < 1) {
      print(
          "mtllib_parse: space separator not found on line=$lineNum from url=$url: [$line]");
      return;
    }

    String field = line.substring(0, paramIndex);
    String param = line.substring(paramIndex).trim();
    field_parser parser = parserTable[field];
    if (parser == null) {
      if (printUnknownFields) {
        print(
            "mtllib_parse: unknown field=[$field] on line=$lineNum from url=$url: [$line]");
      }
      return;
    }

    parser(field, param, line, lineNum, url);
  }

  List<String> lines = str.split('\n');
  lines.forEach((line) => parseLine(line));

  //print("mtllib_parse: url=$url: materials: ${lib.length}");

  //lib.forEach((name, material) { print("mtllib_parse: url=$url material=$name: Kd=${material.Kd} map_Kd=${material.map_Kd}"); });

  return lib;
}

bool _trimmedLineIsComment(String line) {
  assert(!line.startsWith(_BLANK));
  return line.isEmpty || line[0] == '#';
}
