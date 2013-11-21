library obj;

class Part {
  String    name;
  bool      smooth;
  String    usemtl;
  int       indexFirst;
  int       indexListSize = 0;
  
  Part(this.name, this.indexFirst);
}

class Obj {
    
  static final String prefix_mtllib = "mtllib ";
  static final String prefix_usemtl = "usemtl ";
  static final int prefix_mtllib_len = prefix_mtllib.length;
  static final int prefix_usemtl_len = prefix_usemtl.length;
  
  Map<String,Part> _partTable = new Map<String,Part>();
  
  Iterable<Part> get partList => _partTable.values;
  
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
    
    _partTable.keys
      .where((name) { // where: filter keys
        bool empty = _partTable[name].indexListSize < 1;
        if (empty) {
          //print("OBJ: deleting empty object=$name loaded from url=$url");
        }       
        return empty;
      })
      .toList() // create a copy to avoid concurrent modifications
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
  
  Obj.fromString(String url, String str) {
    
    Map<String,int> indexTable = new Map<String,int>();
    List<double> _vertCoord = new List<double>();
    List<double> _textCoord = new List<double>();
    List<double> _normCoord = new List<double>();
    int indexCounter = 0;
    int lineNum = 0;
    Part currObj;
    
    void parseLine(String rawLine) {
      ++lineNum;
      
      //print("line: $lineNum [$rawLine]");
      
      String line = rawLine.trim();

      if (line.isEmpty) {
        return;
      }
      
      if (line[0] == '#') {
        return;
      }
      
      if (line.startsWith(prefix_mtllib)) {
        String new_mtllib = line.substring(prefix_mtllib_len);
        if (mtllib != null) {
          print("OBJ: mtllib redefinition: from mtllib=$mtllib to mtllib=$new_mtllib");
        }
        mtllib = new_mtllib;
        return;
      }      
      
      if (line.startsWith('o ')) {
        String objName = line.substring(2);
        currObj = _partTable[objName];
        if (currObj == null) {
          currObj = new Part(objName, indices.length);
          _partTable[objName] = currObj;
        }
        else {
          print("OBJ: redefining object $objName at line=$lineNum from url=$url: [$line]");          
        }
        return;
      }
      
      if (currObj == null) {
        print("OBJ: non-object pattern at line=$lineNum from url=$url: [$line]");
        return;
      }

      if (line.startsWith('s ')) {
        String smooth = line.substring(2);
        if (smooth == "0" || smooth.toLowerCase().startsWith("f")) {
          currObj.smooth = false;
        }
        else {
          currObj.smooth = true;
        }
        return;
      }
      
      if (line.startsWith("v ")) {
        // vertex coord
        List<String> v = line.split(' ');
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

      if (line.startsWith("vt ")) {
        // texture coord
        List<String> t = line.split(' ');
        if (t.length != 3) {
          print("OBJ: wrong number of texture coordinates (${t.length - 1} != 2) at line=$lineNum from url=$url: [$line]");
          return;
        }
        _textCoord.add(double.parse(t[1])); // u
        _textCoord.add(double.parse(t[2])); // v
        return;
      }

      if (line.startsWith("vn ")) {
        // normal
        List<String> n = line.split(' ');
        if (n.length != 4) {
          print("OBJ: wrong number of normal coordinates (${n.length - 1} != 3) at line=$lineNum from url=$url: [$line]");
          return;
        }
        _normCoord.add(double.parse(n[1])); // x
        _normCoord.add(double.parse(n[2])); // y
        _normCoord.add(double.parse(n[3])); // z
        return;
      }
      
      if (line.startsWith("f ")) {
        // face
        List<String> f = line.split(' ');
        if (f.length != 4) {
          print("OBJ: wrong number of face indices (${f.length - 1} != 3) at line=$lineNum from url=$url: [$line]");
          return;
        }
        for (int i = 1; i < f.length; ++i) {
          String ind = f[i];
          
          // known unified index?
          int index = indexTable[ind];
          if (index != null) {
            indices.add(index);
            currObj.indexListSize++;
            continue;
          }
          
          List<String> v = ind.split('/');
          
          // coord index
          String vi = v[0];
          int vIndex = int.parse(vi) - 1;
          int vOffset = 3 * vIndex; 
          vertCoord.add(_vertCoord[vOffset + 0]); // x
          vertCoord.add(_vertCoord[vOffset + 1]); // y
          vertCoord.add(_vertCoord[vOffset + 2]); // z
          
          if (v.length > 1) {
            // texture index?
            String ti = v[1];
            if (ti != null && !ti.isEmpty) {
              int tIndex = int.parse(ti) - 1;
              int tOffset = 2 * tIndex;
              textCoord.add(_textCoord[tOffset + 0]); // u
              textCoord.add(_textCoord[tOffset + 1]); // v
            }
          }

          if (v.length > 2) {
            // normal index?
            String ni = v[2];
            if (ni != null && !ni.isEmpty) {
              int nIndex = int.parse(ni) - 1;
              int nOffset = 3 * nIndex; 
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
        return;
      }
      
      if (line.startsWith(prefix_usemtl)) {
        String new_usemtl = line.substring(prefix_usemtl_len);
        if (currObj.usemtl != null) {
          print("OBJ: object=${currObj.name} usemtl redefinition: from usemtl=${currObj.usemtl} to usemtl=$new_usemtl");          
        }
        currObj.usemtl = new_usemtl;
        return;
      }

      if (line.startsWith("g ")) {
        // ignore
        return;
      }
      
      print("OBJ: unknown pattern at line=$lineNum from url=$url: [$line]");
    }
    
    List<String> lines = str.split('\n');
    
    lines.forEach((line) => parseLine(line));
    
    //print("Obj.fromString: url=$url: lines=${lines.length}");
    
    trimTable(url); // remove empty objects from _partTable
    
    // FIXME
    if (textCoord.length == 0) {
      print("OBJ: FIXME: adding ${indices.length} virtual texture coordinates");
      for (int i = 0; i < indices.length; ++i) {
        textCoord.add(0.0); // u
        textCoord.add(0.0); // v        
      }
    }

    /*
    print("Obj.fromString: objects = ${_partTable.length}");
    print("Obj.fromString: vertCoord.length = ${vertCoord.length}");
    print("Obj.fromString: textCoord.length = ${textCoord.length}");
    print("Obj.fromString: normCoord.length = ${normCoord.length}");
    print("Obj.fromString: mtllib = $mtllib");
    */
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

typedef void field_parser(String field, String param, String line, int lineNum, String url);

Map<String,Material> mtllib_parse(String str, String url) {

  Map<String,Material> lib = new Map<String,Material>();
  Material currMaterial;

  void _parse_newmtl(String field, String param, String line, int lineNum, String url) {
    String mtl = param;
    currMaterial = lib[mtl];
    if (currMaterial == null) {
      currMaterial = new Material(mtl);
      lib[mtl] = currMaterial;
    }
  }

  void _parse_map_Kd(String field, String param, String line, int lineNum, String url) {
    String map_Kd = param;
    if (currMaterial == null) {
      print("mtllib_parse: url=$url: line=$lineNum: map_Kd=$map_Kd found for undefined material: [$line]");
      return;
    }
    currMaterial.map_Kd = map_Kd;
  }

  void _parse_Kd(String field, String param, String line, int lineNum, String url) { 
    String Kd = param;
    if (currMaterial == null) {
      print("mtllib_parse: url=$url: line=$lineNum: Kd=$Kd found for undefined material: [$line]");
      return;
    }
    List<String> rgb = Kd.split(' ');
    currMaterial.Kd[0] = double.parse(rgb[0]);
    currMaterial.Kd[1] = double.parse(rgb[1]);
    currMaterial.Kd[2] = double.parse(rgb[2]);
  }

  void _parse_noop(String field, String param, String line, int lineNum, String url) {
  }

  final Map<String,field_parser> parserTable = {
    "newmtl": _parse_newmtl,
    "map_Kd": _parse_map_Kd,
    "Kd":     _parse_Kd,
    "map_Bump": _parse_noop,
    "Ns":     _parse_noop,
    "Ka":     _parse_noop,
    "Ks":     _parse_noop,
    "Ni":     _parse_noop,
    "d":      _parse_noop,
    "illum":  _parse_noop
  };

  int lineNum = 0;
  
  void parseLine(String rawLine) {
    ++lineNum;
    
    String line = rawLine.trim();

    if (line.isEmpty) {
      return;
    }
    
    if (line[0] == '#') {
      return;
    }
    
    int paramIndex = line.indexOf(' ');
    if (paramIndex < 1) {
      print("mtllib_parse: space separator not found on line=$lineNum from url=$url: [$line]");
      return;
    }

    String field = line.substring(0, paramIndex);
    String param = line.substring(paramIndex).trim();
    field_parser parser = parserTable[field];
    if (parser == null) {
      print("mtllib_parse: unknown field=[$field] on line=$lineNum from url=$url: [$line]");
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
